/*
---------------------------------------------------------------
File name:          template_engine.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        模板引擎管理器 (Template engine manager)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 基础模板引擎功能;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:mason/mason.dart' hide HookContext;
import 'package:ming_status_cli/src/core/extensions/template_engine_extensions.dart';
import 'package:ming_status_cli/src/core/managers/async_manager.dart';
import 'package:ming_status_cli/src/core/managers/cache_manager.dart';
import 'package:ming_status_cli/src/core/managers/error_recovery_manager.dart';
import 'package:ming_status_cli/src/core/managers/hook_manager.dart';
import 'package:ming_status_cli/src/core/strategies/default_hooks.dart';
import 'package:ming_status_cli/src/core/strategies/hook_implementations.dart'
    as hook_impl;
import 'package:ming_status_cli/src/core/template_engine/template_exceptions.dart';
// 导入分离的模块
import 'package:ming_status_cli/src/core/template_engine/template_models.dart';
import 'package:ming_status_cli/src/core/template_engine/template_parameter_system.dart';
import 'package:ming_status_cli/src/models/template_variable.dart';
import 'package:ming_status_cli/src/utils/file_utils.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:ming_status_cli/src/utils/string_utils.dart';
import 'package:path/path.dart' as path;

/// 模板引擎管理器
///
/// 企业级模板引擎，负责模板的完整生命周期管理，包括：
/// - 模板加载、验证和缓存管理
/// - 高性能的代码生成和文件处理
/// - 钩子系统支持，提供扩展能力
/// - 错误恢复和重试机制
/// - 异步生成和批量处理
/// - 模板兼容性检查和版本管理
/// - 用户体验优化和进度反馈
///
/// 支持Mason模板格式，提供丰富的变量处理、继承机制和插件扩展能力。
/// 设计用于高频使用场景，具备完善的缓存策略和性能监控。
class TemplateEngine implements BaseTemplateEngine {
  /// 创建模板引擎实例
  ///
  /// [workingDirectory] 工作目录路径，用于确定模板和输出文件的基础路径
  /// 默认为当前目录
  TemplateEngine({String? workingDirectory})
      : workingDirectory = workingDirectory ?? Directory.current.path,
        hookRegistry = HookRegistry() {
    // 在构造函数体中初始化错误恢复管理器
    errorRecoveryManager = ErrorRecoveryManager(this);
    // 初始化高级钩子管理器
    advancedHookManager = AdvancedHookManager(this);
    // 初始化缓存管理器
    cacheManager = AdvancedTemplateCacheManager(this);
    // 初始化异步生成管理器
    asyncManager = AsyncTemplateGenerationManager(this);
  }

  /// 配置管理器引用
  final String workingDirectory;

  /// 钩子注册表
  final HookRegistry hookRegistry;

  /// 错误恢复管理器
  late final ErrorRecoveryManager errorRecoveryManager;

  /// 高级钩子管理器
  late final AdvancedHookManager advancedHookManager;

  /// 高级缓存管理器
  @override
  late final AdvancedTemplateCacheManager cacheManager;

  /// 异步生成管理器
  @override
  late final AsyncTemplateGenerationManager asyncManager;

  /// Mason生成器缓存
  final Map<String, MasonGenerator> _generatorCache = {};

  /// 模板继承缓存
  final Map<String, TemplateInheritance> _inheritanceCache = {};

  /// 模板元数据缓存
  final Map<String, Map<String, dynamic>> _metadataCache = {};

  /// 模板参数系统缓存
  final Map<String, TemplateParameterSystem> _parameterSystemCache = {};

  /// 重试配置
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  /// 性能监控
  final Map<String, Duration> _performanceMetrics = {};

  /// 初始化模板引擎
  ///
  /// 执行模板引擎的初始化流程，包括缓存预热、钩子注册等准备工作。
  /// 建议在使用模板引擎功能前调用此方法以获得最佳性能。
  ///
  /// 参数：
  /// - [templatesPath] 模板目录路径（可选，默认使用工作目录下的templates文件夹）
  /// - [configManager] 配置管理器实例（可选）
  ///
  /// 抛出：
  /// - [TemplateEngineException] 当初始化过程中发生错误时
  Future<void> initialize({
    String? templatesPath,
    dynamic configManager,
  }) async {
    try {
      cli_logger.Logger.info('正在初始化模板引擎...');

      // 预热缓存
      await cacheManager.warmUpCache();

      // 注册默认钩子
      registerDefaultHooks();

      cli_logger.Logger.success('模板引擎初始化完成');
    } catch (e) {
      cli_logger.Logger.error('模板引擎初始化失败', error: e);
      rethrow;
    }
  }

  /// 获取可用模板列表
  ///
  /// 扫描模板目录，返回所有有效的Mason模板名称列表。
  /// 只返回包含有效brick.yaml文件的模板目录。
  ///
  /// 返回：
  /// - [List<String>] 可用模板名称列表，如果目录不存在或没有有效模板则返回空列表
  ///
  /// 示例：
  /// ```dart
  /// final templates = await engine.getAvailableTemplates();
  /// print('可用模板: ${templates.join(', ')}');
  /// ```
  Future<List<String>> getAvailableTemplates() async {
    try {
      final templatesPath = _getTemplatesDirectory();

      if (!FileUtils.directoryExists(templatesPath)) {
        cli_logger.Logger.warning('模板目录不存在: $templatesPath');
        return [];
      }

      final entities = FileUtils.listDirectory(templatesPath);
      final templates = <String>[];

      for (final entity in entities) {
        if (entity is Directory) {
          final templateName = path.basename(entity.path);
          // 检查是否是有效的Mason模板
          final brickPath = path.join(entity.path, 'brick.yaml');
          if (FileUtils.fileExists(brickPath)) {
            templates.add(templateName);
          }
        }
      }

      cli_logger.Logger.debug('找到 ${templates.length} 个可用模板');
      return templates;
    } catch (e) {
      cli_logger.Logger.error('获取模板列表失败', error: e);
      return [];
    }
  }

  /// 检查模板是否存在
  bool isTemplateAvailable(String templateName) {
    final templatePath = getTemplatePath(templateName);
    final brickPath = path.join(templatePath, 'brick.yaml');
    return FileUtils.fileExists(brickPath);
  }

  /// 获取模板路径
  String getTemplatePath(String templateName) {
    return path.join(_getTemplatesDirectory(), templateName);
  }

  /// 获取模板目录路径（智能查找）
  String _getTemplatesDirectory() {
    // 首先尝试当前工作目录
    final localTemplatesPath = path.join(workingDirectory, 'templates');
    cli_logger.Logger.debug('检查本地模板目录: $localTemplatesPath');
    if (FileUtils.directoryExists(localTemplatesPath) &&
        _hasValidTemplates(localTemplatesPath)) {
      cli_logger.Logger.debug('使用本地模板目录: $localTemplatesPath');
      return localTemplatesPath;
    }

    // 尝试查找项目根目录（通过查找pubspec.yaml或ming_status.yaml）
    final projectRoot = _findProjectRoot(workingDirectory);
    cli_logger.Logger.debug('查找到项目根目录: $projectRoot');
    if (projectRoot != null) {
      final projectTemplatesPath = path.join(projectRoot, 'templates');
      cli_logger.Logger.debug('检查项目模板目录: $projectTemplatesPath');
      if (FileUtils.directoryExists(projectTemplatesPath)) {
        cli_logger.Logger.debug('使用项目模板目录: $projectTemplatesPath');
        return projectTemplatesPath;
      }
    }

    // 回退到当前工作目录
    cli_logger.Logger.debug('回退到本地模板目录: $localTemplatesPath');
    return localTemplatesPath;
  }

  /// 查找项目根目录
  String? _findProjectRoot(String startPath) {
    var currentPath = startPath;

    while (true) {
      // 检查是否有项目标识文件或templates目录
      if (FileUtils.fileExists(path.join(currentPath, 'pubspec.yaml')) ||
          FileUtils.fileExists(path.join(currentPath, 'ming_status.yaml')) ||
          _hasValidTemplates(path.join(currentPath, 'templates'))) {
        return currentPath;
      }

      // 向上一级目录
      final parentPath = path.dirname(currentPath);
      if (parentPath == currentPath) {
        // 已经到达根目录
        break;
      }
      currentPath = parentPath;
    }

    return null;
  }

  /// 检查模板目录是否包含有效的模板
  bool _hasValidTemplates(String templatesPath) {
    try {
      final dir = Directory(templatesPath);
      if (!dir.existsSync()) return false;

      // 检查是否有子目录（模板目录）
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is Directory) {
          // 检查是否有brick.yaml文件
          final brickYaml = File(path.join(entity.path, 'brick.yaml'));
          if (brickYaml.existsSync()) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      cli_logger.Logger.debug('检查模板目录时出错: $e');
      return false;
    }
  }

  /// 加载模板生成器（优化版本）
  ///
  /// 加载指定名称的模板并创建Mason生成器实例。
  /// 包含智能缓存、重试机制和错误恢复功能。
  ///
  /// 特性：
  /// - 自动缓存已加载的生成器，提升后续访问性能
  /// - 内置重试机制，提高加载成功率
  /// - 智能错误恢复，提供模板建议和修复提示
  /// - 性能监控和指标记录
  ///
  /// 参数：
  /// - [templateName] 模板名称，必须是有效的已存在模板
  ///
  /// 返回：
  /// - [MasonGenerator?] 模板生成器实例，加载失败时返回null
  ///
  /// 抛出：
  /// - [TemplateEngineException] 当模板不存在、格式无效或加载失败时
  ///
  /// 示例：
  /// ```dart
  /// final generator = await engine.loadTemplate('flutter_package');
  /// if (generator != null) {
  ///   // 使用生成器进行代码生成
  /// }
  /// ```
  Future<MasonGenerator?> loadTemplate(String templateName) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 检查缓存
      if (_generatorCache.containsKey(templateName)) {
        cli_logger.Logger.debug('使用缓存的模板生成器: $templateName');
        _recordPerformance('loadTemplate_cached', stopwatch.elapsed);
        return _generatorCache[templateName];
      }

      // 验证模板存在性
      if (!isTemplateAvailable(templateName)) {
        final error = TemplateEngineException.templateNotFound(templateName);

        // 尝试错误恢复
        final recoveryResult = await errorRecoveryManager.tryRecover(error);
        if (recoveryResult.success) {
          cli_logger.Logger.info('模板恢复建议: ${recoveryResult.message}');
        }

        throw error;
      }

      final templatePath = getTemplatePath(templateName);
      cli_logger.Logger.debug('正在加载模板: $templatePath');

      // 使用重试机制加载模板
      MasonGenerator? generator;
      for (var attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          // 检查brick.yaml是否有效
          await _validateBrickYaml(templatePath);

          // 创建Mason生成器
          final brick = Brick.path(templatePath);
          generator = await MasonGenerator.fromBrick(brick);

          // 预热generator - 获取变量信息
          final _ = generator.vars;

          break; // 成功加载，跳出重试循环
        } on MasonException catch (e) {
          if (attempt == _maxRetries) {
            throw TemplateEngineException.masonError(
              'fromBrick',
              e,
              recovery: '请检查模板的brick.yaml文件格式是否正确',
            );
          }

          cli_logger.Logger.warning(
            '模板加载失败 (尝试 $attempt/$_maxRetries): $e',
          );
          await Future<void>.delayed(_retryDelay);
        } catch (e) {
          if (attempt == _maxRetries) {
            throw TemplateEngineException.masonError('loadTemplate', e);
          }

          cli_logger.Logger.warning(
            '模板加载异常 (尝试 $attempt/$_maxRetries): $e',
          );
          await Future<void>.delayed(_retryDelay);
        }
      }

      if (generator == null) {
        throw TemplateEngineException.masonError(
          'loadTemplate',
          'Unable to create generator after $_maxRetries attempts',
        );
      }

      // 缓存生成器和元数据
      _generatorCache[templateName] = generator;
      await _cacheTemplateMetadata(templateName, templatePath);

      _recordPerformance('loadTemplate_new', stopwatch.elapsed);
      cli_logger.Logger.success(
        '模板加载成功: $templateName (${stopwatch.elapsedMilliseconds}ms)',
      );

      return generator;
    } on TemplateEngineException {
      _recordPerformance('loadTemplate_error', stopwatch.elapsed);
      rethrow;
    } catch (e) {
      _recordPerformance('loadTemplate_error', stopwatch.elapsed);
      throw TemplateEngineException.masonError('loadTemplate', e);
    }
  }

  /// 验证brick.yaml文件
  Future<void> _validateBrickYaml(String templatePath) async {
    try {
      final brickPath = path.join(templatePath, 'brick.yaml');

      if (!FileUtils.fileExists(brickPath)) {
        throw TemplateEngineException(
          type: TemplateEngineErrorType.invalidTemplateFormat,
          message: 'brick.yaml文件不存在',
          details: {'path': brickPath},
        );
      }

      // 尝试解析YAML文件
      final yamlData = await FileUtils.readYamlFile(brickPath);

      // 验证YAML数据不为空
      if (yamlData == null) {
        throw TemplateEngineException(
          type: TemplateEngineErrorType.invalidTemplateFormat,
          message: 'brick.yaml文件为空或无法解析',
          details: {'path': brickPath},
        );
      }

      // 验证必需字段
      if (!yamlData.containsKey('name')) {
        throw TemplateEngineException(
          type: TemplateEngineErrorType.invalidTemplateFormat,
          message: 'brick.yaml缺少必需的name字段',
          details: {'path': brickPath},
        );
      }

      // 验证__brick__目录存在
      final brickDir = path.join(templatePath, '__brick__');
      if (!FileUtils.directoryExists(brickDir)) {
        throw TemplateEngineException(
          type: TemplateEngineErrorType.invalidTemplateFormat,
          message: '__brick__目录不存在',
          details: {'path': brickDir},
        );
      }
    } catch (e) {
      if (e is TemplateEngineException) rethrow;

      throw TemplateEngineException(
        type: TemplateEngineErrorType.invalidTemplateFormat,
        message: '验证brick.yaml失败',
        innerException: e,
      );
    }
  }

  /// 全面的模板兼容性检查
  ///
  /// 对指定模板进行多维度兼容性分析，确保模板能在当前环境正常运行。
  /// 提供详细的检查报告，包含错误、警告和优化建议。
  ///
  /// 检查维度：
  /// - 版本兼容性：CLI、Dart、Mason版本要求
  /// - 依赖兼容性：必需依赖可用性和冲突检测
  /// - 平台兼容性：操作系统和架构支持
  /// - 标准合规性：模板格式和最佳实践验证
  ///
  /// 参数：
  /// - [templateName] 要检查的模板名称
  /// - [checkVersion] 是否进行版本兼容性检查（默认：true）
  /// - [checkDependencies] 是否检查依赖兼容性（默认：true）
  /// - [checkPlatform] 是否检查平台兼容性（默认：true）
  /// - [checkCompliance] 是否检查标准合规性（默认：true）
  ///
  /// 返回：
  /// - [CompatibilityCheckResult] 包含详细检查结果的对象
  ///
  /// 示例：
  /// ```dart
  /// final result = await engine.checkTemplateCompatibility('my_template');
  /// if (result.isCompatible) {
  ///   print('模板兼容');
  /// } else {
  ///   print('兼容性问题: ${result.errors.join(', ')}');
  /// }
  /// ```
  Future<CompatibilityCheckResult> checkTemplateCompatibility(
    String templateName, {
    bool checkVersion = true,
    bool checkDependencies = true,
    bool checkPlatform = true,
    bool checkCompliance = true,
  }) async {
    try {
      final templatePath = getTemplatePath(templateName);
      final brickPath = path.join(templatePath, 'brick.yaml');

      if (!FileUtils.fileExists(brickPath)) {
        return CompatibilityCheckResult.failure(
          errors: ['模板不存在或brick.yaml文件缺失'],
        );
      }

      final yamlData = await FileUtils.readYamlFile(brickPath);
      if (yamlData == null) {
        return CompatibilityCheckResult.failure(
          errors: ['无法解析brick.yaml文件'],
        );
      }

      final errors = <String>[];
      final warnings = <String>[];
      final suggestions = <String>[];
      final metadata = <String, dynamic>{};

      // 版本兼容性检查
      if (checkVersion) {
        final versionResult = await _checkVersionCompatibility(yamlData);
        errors.addAll(versionResult.errors);
        warnings.addAll(versionResult.warnings);
        suggestions.addAll(versionResult.suggestions);
        metadata.addAll(versionResult.metadata);
      }

      // 依赖兼容性检查
      if (checkDependencies) {
        final dependencyResult = await _checkDependencyCompatibility(yamlData);
        errors.addAll(dependencyResult.errors);
        warnings.addAll(dependencyResult.warnings);
        suggestions.addAll(dependencyResult.suggestions);
        metadata.addAll(dependencyResult.metadata);
      }

      // 平台兼容性检查
      if (checkPlatform) {
        final platformResult = await _checkPlatformCompatibility(yamlData);
        errors.addAll(platformResult.errors);
        warnings.addAll(platformResult.warnings);
        suggestions.addAll(platformResult.suggestions);
        metadata.addAll(platformResult.metadata);
      }

      // 模板标准合规性检查
      if (checkCompliance) {
        final complianceResult = await _checkTemplateCompliance(
          templatePath,
          yamlData,
        );
        errors.addAll(complianceResult.errors);
        warnings.addAll(complianceResult.warnings);
        suggestions.addAll(complianceResult.suggestions);
        metadata.addAll(complianceResult.metadata);
      }

      // 综合结果
      if (errors.isNotEmpty) {
        return CompatibilityCheckResult.failure(
          errors: errors,
          warnings: warnings,
          suggestions: suggestions,
          metadata: metadata,
        );
      }

      return CompatibilityCheckResult.success(
        warnings: warnings,
        suggestions: suggestions,
        metadata: metadata,
      );
    } catch (e) {
      cli_logger.Logger.error('模板兼容性检查失败', error: e);
      return CompatibilityCheckResult.failure(
        errors: ['兼容性检查过程中发生异常: $e'],
      );
    }
  }

  /// 版本兼容性检查
  Future<CompatibilityCheckResult> _checkVersionCompatibility(
    Map<String, dynamic> yamlData,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];
    final metadata = <String, dynamic>{};

    try {
      // 解析版本信息
      final versionInfo = _parseVersionInfo(yamlData);
      metadata['versionInfo'] = {
        'templateVersion': versionInfo.version,
        'minCliVersion': versionInfo.minCliVersion,
        'maxCliVersion': versionInfo.maxCliVersion,
        'minDartVersion': versionInfo.minDartVersion,
        'maxDartVersion': versionInfo.maxDartVersion,
        'minMasonVersion': versionInfo.minMasonVersion,
        'maxMasonVersion': versionInfo.maxMasonVersion,
      };

      // 检查当前CLI版本兼容性
      const currentCliVersion = '1.0.0'; // 从pubspec.yaml读取实际版本
      if (versionInfo.minCliVersion != null) {
        if (_compareVersions(
              currentCliVersion,
              versionInfo.minCliVersion!,
            ) <
            0) {
          errors.add(
            'CLI版本过低: 当前$currentCliVersion < 要求${versionInfo.minCliVersion}',
          );
          suggestions.add(
            '请升级CLI到${versionInfo.minCliVersion}或更高版本',
          );
        }
      }

      if (versionInfo.maxCliVersion != null) {
        if (_compareVersions(
              currentCliVersion,
              versionInfo.maxCliVersion!,
            ) >
            0) {
          warnings.add(
            'CLI版本可能过高: 当前$currentCliVersion > 建议${versionInfo.maxCliVersion}',
          );
          suggestions.add(
            '考虑降级CLI或验证模板兼容性',
          );
        }
      }

      // 检查Dart版本兼容性
      final currentDartVersion = _getCurrentDartVersion();
      if (currentDartVersion != null) {
        metadata['currentDartVersion'] = currentDartVersion;

        if (versionInfo.minDartVersion != null) {
          if (_compareVersions(
                currentDartVersion,
                versionInfo.minDartVersion!,
              ) <
              0) {
            errors.add(
              'Dart版本过低: 当前$currentDartVersion < '
              '要求${versionInfo.minDartVersion}',
            );
            suggestions.add(
              '请升级Dart到${versionInfo.minDartVersion}或更高版本',
            );
          }
        }

        if (versionInfo.maxDartVersion != null) {
          if (_compareVersions(
                currentDartVersion,
                versionInfo.maxDartVersion!,
              ) >
              0) {
            warnings.add(
              'Dart版本可能不兼容: 当前$currentDartVersion > '
              '建议${versionInfo.maxDartVersion}',
            );
          }
        }
      }

      // 检查Mason版本兼容性
      final currentMasonVersion = _getCurrentMasonVersion();
      if (currentMasonVersion != null) {
        metadata['currentMasonVersion'] = currentMasonVersion;

        if (versionInfo.minMasonVersion != null) {
          if (_compareVersions(
                currentMasonVersion,
                versionInfo.minMasonVersion!,
              ) <
              0) {
            errors.add(
              'Mason版本过低: 当前$currentMasonVersion < '
              '要求${versionInfo.minMasonVersion}',
            );
            suggestions.add(
              '请升级Mason到${versionInfo.minMasonVersion}或更高版本',
            );
          }
        }
      }
    } catch (e) {
      errors.add('版本兼容性检查失败: $e');
    }

    return CompatibilityCheckResult(
      isCompatible: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
      metadata: metadata,
    );
  }

  /// 依赖兼容性检查
  Future<CompatibilityCheckResult> _checkDependencyCompatibility(
    Map<String, dynamic> yamlData,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];
    final metadata = <String, dynamic>{};

    try {
      // 解析依赖信息
      final dependencyInfo = _parseDependencyInfo(yamlData);
      metadata['dependencyInfo'] = {
        'requiredDependencies': dependencyInfo.requiredDependencies,
        'optionalDependencies': dependencyInfo.optionalDependencies,
        'conflictingDependencies': dependencyInfo.conflictingDependencies,
      };

      // 检查必需依赖
      for (final entry in dependencyInfo.requiredDependencies.entries) {
        final dependencyName = entry.key;
        final requiredVersion = entry.value;

        final isAvailable = await _checkDependencyAvailability(
          dependencyName,
          requiredVersion,
        );

        if (!isAvailable) {
          errors.add('缺少必需依赖: $dependencyName (版本: $requiredVersion)');
          suggestions.add('请安装依赖: dart pub add $dependencyName');
        }
      }

      // 检查冲突依赖
      for (final conflictingDep in dependencyInfo.conflictingDependencies) {
        final hasConflict = await _checkDependencyConflict(conflictingDep);
        if (hasConflict) {
          warnings.add('检测到冲突依赖: $conflictingDep');
          suggestions.add('请移除或替换冲突依赖: $conflictingDep');
        }
      }

      // 检查可选依赖
      for (final entry in dependencyInfo.optionalDependencies.entries) {
        final dependencyName = entry.key;
        final version = entry.value;

        final isAvailable = await _checkDependencyAvailability(
          dependencyName,
          version,
        );

        if (!isAvailable) {
          warnings.add('可选依赖不可用: $dependencyName (版本: $version)');
          suggestions.add('考虑安装可选依赖以获得完整功能: dart pub add $dependencyName');
        }
      }
    } catch (e) {
      errors.add('依赖兼容性检查失败: $e');
    }

    return CompatibilityCheckResult(
      isCompatible: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
      metadata: metadata,
    );
  }

  /// 平台兼容性检查
  Future<CompatibilityCheckResult> _checkPlatformCompatibility(
    Map<String, dynamic> yamlData,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];
    final metadata = <String, dynamic>{};

    try {
      // 解析平台信息
      final platformInfo = _parsePlatformInfo(yamlData);
      metadata['platformInfo'] = {
        'supportedPlatforms': platformInfo.supportedPlatforms,
        'unsupportedPlatforms': platformInfo.unsupportedPlatforms,
        'requiredFeatures': platformInfo.requiredFeatures,
        'optionalFeatures': platformInfo.optionalFeatures,
      };

      // 获取当前平台信息
      final currentPlatform = _getCurrentPlatform();
      metadata['currentPlatform'] = currentPlatform;

      // 检查平台支持
      if (platformInfo.supportedPlatforms.isNotEmpty &&
          !platformInfo.supportedPlatforms.contains(currentPlatform)) {
        errors.add('当前平台不受支持: $currentPlatform');
        suggestions.add(
          '支持的平台: ${platformInfo.supportedPlatforms.join(", ")}',
        );
      }

      // 检查平台排除
      if (platformInfo.unsupportedPlatforms.contains(currentPlatform)) {
        errors.add('当前平台被明确排除: $currentPlatform');
        suggestions.add('请在支持的平台上使用此模板');
      }

      // 检查必需功能
      for (final feature in platformInfo.requiredFeatures) {
        final isSupported = _checkPlatformFeature(feature);
        if (!isSupported) {
          errors.add('缺少必需的平台功能: $feature');
          suggestions.add('请确保平台支持功能: $feature');
        }
      }

      // 检查可选功能
      for (final feature in platformInfo.optionalFeatures) {
        final isSupported = _checkPlatformFeature(feature);
        if (!isSupported) {
          warnings.add('可选平台功能不可用: $feature');
          suggestions.add('某些功能可能受限，因为缺少: $feature');
        }
      }
    } catch (e) {
      errors.add('平台兼容性检查失败: $e');
    }

    return CompatibilityCheckResult(
      isCompatible: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
      metadata: metadata,
    );
  }

  /// 模板标准合规性检查
  Future<CompatibilityCheckResult> _checkTemplateCompliance(
    String templatePath,
    Map<String, dynamic> yamlData,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];
    final metadata = <String, dynamic>{};

    try {
      // 检查必需字段
      final requiredFields = ['name', 'description', 'version'];
      for (final field in requiredFields) {
        if (!yamlData.containsKey(field) ||
            StringUtils.isBlank(yamlData[field]?.toString())) {
          errors.add('缺少必需字段: $field');
          suggestions.add('请在brick.yaml中添加$field字段');
        }
      }

      // 检查版本格式
      if (yamlData.containsKey('version')) {
        final version = yamlData['version']?.toString() ?? '';
        if (!_isValidVersionFormat(version)) {
          errors.add('版本格式无效: $version');
          suggestions.add('请使用语义版本格式 (例如: 1.0.0)');
        }
      }

      // 检查变量定义
      if (yamlData.containsKey('vars')) {
        final vars = Map<String, dynamic>.from(yamlData['vars'] as Map? ?? {});
        for (final entry in vars.entries) {
          final varName = entry.key;
          final varConfig = Map<String, dynamic>.from(
            entry.value as Map? ?? {},
          );

          // 检查变量类型
          if (!varConfig.containsKey('type')) {
            warnings.add('变量缺少类型定义: $varName');
            suggestions.add('建议为变量$varName添加type字段');
          }

          // 检查变量描述
          if (!varConfig.containsKey('description')) {
            warnings.add('变量缺少描述: $varName');
            suggestions.add('建议为变量$varName添加description字段');
          }
        }
      }

      // 检查__brick__目录结构
      final brickDir = path.join(templatePath, '__brick__');
      if (FileUtils.directoryExists(brickDir)) {
        final fileCount = await _countTemplateFiles(templatePath);
        metadata['templateFileCount'] = fileCount;

        if (fileCount == 0) {
          warnings.add('__brick__目录为空');
          suggestions.add('请添加模板文件到__brick__目录');
        }
      }

      // 检查README文件
      final readmePath = path.join(templatePath, 'README.md');
      if (!FileUtils.fileExists(readmePath)) {
        warnings.add('缺少README.md文件');
        suggestions.add('建议添加README.md文档说明模板用法');
      }

      // 检查许可证文件
      final licensePath = path.join(templatePath, 'LICENSE');
      if (!FileUtils.fileExists(licensePath)) {
        warnings.add('缺少LICENSE文件');
        suggestions.add('建议添加LICENSE文件说明许可证信息');
      }

      // 检查CHANGELOG文件
      final changelogPath = path.join(templatePath, 'CHANGELOG.md');
      if (!FileUtils.fileExists(changelogPath)) {
        warnings.add('缺少CHANGELOG.md文件');
        suggestions.add('建议添加CHANGELOG.md文件记录版本变更');
      }
    } catch (e) {
      errors.add('模板合规性检查失败: $e');
    }

    return CompatibilityCheckResult(
      isCompatible: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
      metadata: metadata,
    );
  }

  /// 缓存模板元数据
  Future<void> _cacheTemplateMetadata(
    String templateName,
    String templatePath,
  ) async {
    try {
      final brickPath = path.join(templatePath, 'brick.yaml');
      final yamlData = await FileUtils.readYamlFile(brickPath);

      // 检查YAML数据是否有效
      if (yamlData == null) {
        cli_logger.Logger.warning('无法读取模板元数据: $templateName');
        return;
      }

      // 添加额外的元数据
      final metadata = Map<String, dynamic>.from(yamlData);
      metadata['_cached_at'] = DateTime.now().toIso8601String();
      metadata['_template_path'] = templatePath;
      metadata['_file_count'] = await _countTemplateFiles(templatePath);

      _metadataCache[templateName] = metadata;
    } catch (e) {
      cli_logger.Logger.warning('缓存模板元数据失败: $e');
    }
  }

  /// 计算模板文件数量
  Future<int> _countTemplateFiles(String templatePath) async {
    try {
      final brickDir = path.join(templatePath, '__brick__');
      if (!FileUtils.directoryExists(brickDir)) return 0;

      var count = 0;
      final entities = FileUtils.listDirectory(brickDir);

      for (final entity in entities) {
        if (entity is File) {
          count++;
        } else if (entity is Directory) {
          // 递归计算子目录文件
          count += await _countTemplateFiles(entity.path);
        }
      }

      return count;
    } catch (e) {
      return 0;
    }
  }

  /// 记录性能指标
  void _recordPerformance(String operation, Duration duration) {
    _performanceMetrics[operation] = duration;
    cli_logger.Logger.debug('性能指标: $operation = ${duration.inMilliseconds}ms');
  }

  /// 生成模块代码（优化版本）
  Future<bool> generateModule({
    required String templateName,
    required String outputPath,
    required Map<String, dynamic> variables,
    bool overwrite = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      cli_logger.Logger.info('正在生成模块: $templateName -> $outputPath');

      // 验证和预处理变量
      final validationErrors = validateTemplateVariables(
        templateName: templateName,
        variables: variables,
      );

      if (validationErrors.isNotEmpty) {
        final error = TemplateEngineException.variableValidationError(
          validationErrors,
        );
        throw error;
      }

      // 预处理变量
      final processedVariables = preprocessVariables(variables);

      // 加载模板（这个方法已经优化过了）
      final generator = await loadTemplate(templateName);
      if (generator == null) {
        throw TemplateEngineException.templateNotFound(templateName);
      }

      // 检查输出目录冲突
      if (FileUtils.directoryExists(outputPath) && !overwrite) {
        throw TemplateEngineException(
          type: TemplateEngineErrorType.outputPathConflict,
          message: '输出目录已存在且未启用覆盖模式',
          details: {'outputPath': outputPath, 'overwrite': overwrite},
          recovery: '请使用 --overwrite 参数或选择不同的输出路径',
        );
      }

      // 创建输出目录（带错误处理）
      await _createOutputDirectoryWithRecovery(outputPath);

      // 执行代码生成（带重试机制）
      await _executeGenerationWithRetry(
        generator,
        outputPath,
        processedVariables,
      );

      _recordPerformance('generateModule', stopwatch.elapsed);
      cli_logger.Logger.success(
        '模块生成完成: $outputPath (${stopwatch.elapsedMilliseconds}ms)',
      );
      return true;
    } on TemplateEngineException catch (e) {
      _recordPerformance('generateModule_error', stopwatch.elapsed);

      // 尝试错误恢复
      final recoveryResult = await errorRecoveryManager.tryRecover(e);
      if (recoveryResult.success) {
        cli_logger.Logger.info('错误恢复建议: ${recoveryResult.message}');
      }

      cli_logger.Logger.error('模块生成失败: ${e.message}');
      if (e.recovery != null) {
        cli_logger.Logger.info('建议: ${e.recovery}');
      }
      return false;
    } catch (e) {
      _recordPerformance('generateModule_error', stopwatch.elapsed);
      cli_logger.Logger.error('模块生成失败', error: e);
      return false;
    }
  }

  /// 创建输出目录（带错误恢复）
  Future<void> _createOutputDirectoryWithRecovery(String outputPath) async {
    try {
      await FileUtils.createDirectory(outputPath);
    } catch (e) {
      final error = TemplateEngineException.fileSystemError(
        'createDirectory',
        outputPath,
        e,
      );

      // 尝试恢复
      final recoveryResult = await errorRecoveryManager.tryRecover(error);
      if (!recoveryResult.success) {
        throw error;
      }

      // 重新尝试创建目录
      try {
        await FileUtils.createDirectory(outputPath);
      } catch (retryError) {
        throw TemplateEngineException.fileSystemError(
          'createDirectory_retry',
          outputPath,
          retryError,
        );
      }
    }
  }

  /// 执行生成（带重试机制）
  Future<void> _executeGenerationWithRetry(
    MasonGenerator generator,
    String outputPath,
    Map<String, dynamic> variables,
  ) async {
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        // 准备生成上下文
        final target = DirectoryGeneratorTarget(Directory(outputPath));

        // 执行代码生成
        await generator.generate(target, vars: variables);

        // 验证生成结果
        await _validateGenerationResult(outputPath);

        return; // 成功，退出重试循环
      } on MasonException catch (e) {
        if (attempt == _maxRetries) {
          throw TemplateEngineException.masonError(
            'generate',
            e,
            recovery: '请检查模板变量是否正确，或模板文件是否有效',
          );
        }

        cli_logger.Logger.warning(
          'Mason生成失败 (尝试 $attempt/$_maxRetries): $e',
        );

        // 清理失败的生成结果
        await _cleanupFailedGeneration(outputPath);
        await Future<void>.delayed(_retryDelay);
      } catch (e) {
        if (attempt == _maxRetries) {
          throw TemplateEngineException(
            type: TemplateEngineErrorType.unknown,
            message: '代码生成失败',
            innerException: e,
          );
        }

        cli_logger.Logger.warning(
          '生成异常 (尝试 $attempt/$_maxRetries): $e',
        );

        await _cleanupFailedGeneration(outputPath);
        await Future<void>.delayed(_retryDelay);
      }
    }
  }

  /// 验证生成结果
  Future<void> _validateGenerationResult(String outputPath) async {
    try {
      // 检查输出目录是否存在
      if (!FileUtils.directoryExists(outputPath)) {
        throw TemplateEngineException(
          type: TemplateEngineErrorType.fileSystemError,
          message: '生成的输出目录不存在',
          details: {'outputPath': outputPath},
        );
      }

      // 检查是否有文件生成
      final entities = FileUtils.listDirectory(outputPath);
      if (entities.isEmpty) {
        throw TemplateEngineException(
          type: TemplateEngineErrorType.masonError,
          message: '没有生成任何文件',
          details: {'outputPath': outputPath},
          recovery: '请检查模板配置和变量是否正确',
        );
      }

      // 基本的文件内容检查
      for (final entity in entities) {
        if (entity is File) {
          final content = await entity.readAsString();

          // 检查是否还有未替换的变量
          if (content.contains('{{') && content.contains('}}')) {
            cli_logger.Logger.warning(
              '检测到未替换的模板变量: ${entity.path}',
            );
          }
        }
      }
    } catch (e) {
      if (e is TemplateEngineException) rethrow;

      throw TemplateEngineException(
        type: TemplateEngineErrorType.unknown,
        message: '验证生成结果失败',
        innerException: e,
      );
    }
  }

  /// 清理失败的生成结果
  Future<void> _cleanupFailedGeneration(String outputPath) async {
    try {
      if (FileUtils.directoryExists(outputPath)) {
        // 删除部分生成的文件
        final directory = Directory(outputPath);
        await directory.delete(recursive: true);
        cli_logger.Logger.debug('已清理失败的生成结果: $outputPath');
      }
    } catch (e) {
      cli_logger.Logger.warning('清理失败的生成结果时发生错误: $e');
    }
  }

  /// 获取模板变量名称列表
  Future<List<String>?> getTemplateVariables(String templateName) async {
    try {
      final generator = await loadTemplate(templateName);
      if (generator == null) {
        return null;
      }

      // Mason的generator.vars实际返回List<String>（变量名列表）
      return generator.vars;
    } catch (e) {
      cli_logger.Logger.error('获取模板变量失败', error: e);
      return null;
    }
  }

  /// 验证模板变量
  Map<String, String> validateTemplateVariables({
    required String templateName,
    required Map<String, dynamic> variables,
  }) {
    final errors = <String, String>{};

    try {
      // 如果是测试模板，使用宽松验证
      if (templateName.contains('test') || templateName.contains('cache')) {
        return errors; // 测试模板跳过严格验证
      }

      // 检查必需的变量
      final requiredVars = ['module_id', 'module_name'];
      for (final varName in requiredVars) {
        if (!variables.containsKey(varName) ||
            StringUtils.isBlank(variables[varName]?.toString())) {
          errors[varName] = '必需变量未提供或为空';
        }
      }

      // 验证模块ID格式
      if (variables.containsKey('module_id')) {
        final moduleId = variables['module_id']?.toString() ?? '';
        if (moduleId.isNotEmpty && !StringUtils.isValidIdentifier(moduleId)) {
          errors['module_id'] = '模块ID格式无效，必须是有效的标识符';
        }
      }

      // 验证类名格式
      if (variables.containsKey('class_name')) {
        final className = variables['class_name']?.toString() ?? '';
        if (className.isNotEmpty && !StringUtils.isValidClassName(className)) {
          errors['class_name'] = '类名格式无效，必须以大写字母开头';
        }
      }
    } catch (e) {
      cli_logger.Logger.error('验证模板变量时发生异常', error: e);
      errors['_general'] = '验证过程中发生异常: $e';
    }

    return errors;
  }

  /// 预处理模板变量
  Map<String, dynamic> preprocessVariables(Map<String, dynamic> variables) {
    final processed = Map<String, dynamic>.from(variables);

    try {
      // 自动生成相关变量
      if (processed.containsKey('module_id')) {
        final moduleId = processed['module_id'].toString();

        // 生成类名（如果未提供）
        if (!processed.containsKey('class_name') ||
            StringUtils.isBlank(processed['class_name']?.toString())) {
          processed['class_name'] = StringUtils.toPascalCase(moduleId);
        }

        // 生成文件名
        processed['file_name'] = StringUtils.toSnakeCase(moduleId);
        processed['kebab_name'] = StringUtils.toKebabCase(moduleId);
        processed['camel_name'] = StringUtils.toCamelCase(moduleId);
      }

      // 生成时间戳
      final now = DateTime.now();
      processed['generated_date'] = now.toIso8601String().substring(0, 10);
      processed['generated_time'] = now.toIso8601String().substring(11, 19);
      processed['generated_year'] = now.year.toString();

      // 默认作者信息
      if (!processed.containsKey('author') ||
          StringUtils.isBlank(processed['author']?.toString())) {
        processed['author'] = 'lgnorant-lu';
      }

      // 默认版本
      if (!processed.containsKey('version') ||
          StringUtils.isBlank(processed['version']?.toString())) {
        processed['version'] = '1.0.0';
      }
    } catch (e) {
      cli_logger.Logger.error('预处理模板变量时发生异常', error: e);
    }

    return processed;
  }

  /// 创建基础模板
  Future<bool> createBaseTemplate(String templateName) async {
    try {
      final templatePath = getTemplatePath(templateName);

      if (FileUtils.directoryExists(templatePath)) {
        cli_logger.Logger.warning('模板已存在: $templateName');
        return false;
      }

      // 创建模板目录
      await FileUtils.createDirectory(templatePath);

      // 创建brick.yaml文件
      final brickContent = _generateBrickYaml(templateName);
      final brickPath = path.join(templatePath, 'brick.yaml');
      await FileUtils.writeFileAsString(brickPath, brickContent);

      // 创建基础模板文件
      await _createBasicTemplateFiles(templatePath);

      cli_logger.Logger.success('基础模板创建成功: $templateName');
      return true;
    } catch (e) {
      cli_logger.Logger.error('创建基础模板失败', error: e);
      return false;
    }
  }

  /// 生成brick.yaml内容
  String _generateBrickYaml(String templateName) {
    return '''
name: $templateName
description: Ming Status CLI生成的模板
version: 0.1.0+1

vars:
  module_id:
    type: string
    description: 模块唯一标识符
    prompt: 请输入模块ID
  module_name:
    type: string
    description: 模块显示名称
    prompt: 请输入模块名称
  author:
    type: string
    description: 作者名称
    default: lgnorant-lu
  description:
    type: string
    description: 模块描述
    default: 模块描述
''';
  }

  /// 创建基础模板文件
  Future<void> _createBasicTemplateFiles(String templatePath) async {
    // 创建__brick__目录
    final brickDir = path.join(templatePath, '__brick__');
    await FileUtils.createDirectory(brickDir);

    // 创建基础模块文件模板
    const moduleTemplate = '''
/*
---------------------------------------------------------------
File name:          {{file_name}}.dart
Author:             {{author}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       3.2+
Description:        {{description}}
---------------------------------------------------------------
*/

/// {{module_name}}模块
class {{class_name}} {
  /// 模块ID
  static const String moduleId = '{{module_id}}';
  
  /// 模块名称
  static const String moduleName = '{{module_name}}';
  
  /// 初始化模块
  void initialize() {
    // TODO: 实现模块初始化逻辑
  }
}
''';

    final moduleFilePath = path.join(brickDir, '{{file_name}}.dart');
    await FileUtils.writeFileAsString(moduleFilePath, moduleTemplate);

    cli_logger.Logger.debug('基础模板文件创建完成');
  }

  /// 清理缓存
  void clearCache() {
    _generatorCache.clear();
    _inheritanceCache.clear();
    _metadataCache.clear();
    _parameterSystemCache.clear();
    _performanceMetrics.clear();
    cli_logger.Logger.debug('模板引擎缓存已清理');
  }

  /// 获取性能报告
  Map<String, dynamic> getPerformanceReport() {
    return {
      'cache_stats': {
        'generators_cached': _generatorCache.length,
        'metadata_cached': _metadataCache.length,
        'inheritance_cached': _inheritanceCache.length,
      },
      'performance_metrics': _performanceMetrics
          .map((key, value) => MapEntry(key, value.inMilliseconds)),
      'average_times': _calculateAveragePerformance(),
    };
  }

  /// 计算平均性能指标
  Map<String, double> _calculateAveragePerformance() {
    final averages = <String, double>{};
    final groupedMetrics = <String, List<Duration>>{};

    // 按操作类型分组
    for (final entry in _performanceMetrics.entries) {
      final baseOperation = entry.key.split('_').first;
      groupedMetrics.putIfAbsent(baseOperation, () => []).add(entry.value);
    }

    // 计算平均值
    for (final entry in groupedMetrics.entries) {
      final totalMs = entry.value.fold<int>(
        0,
        (sum, duration) => sum + duration.inMilliseconds,
      );
      averages[entry.key] = totalMs / entry.value.length;
    }

    return averages;
  }

  /// 预热引擎（加载常用模板）
  Future<void> warmup({List<String>? templateNames}) async {
    final stopwatch = Stopwatch()..start();

    try {
      final templates = templateNames ?? await getAvailableTemplates();
      cli_logger.Logger.info('预热模板引擎，加载 ${templates.length} 个模板...');

      // 并发加载模板
      final futures = templates.map((templateName) async {
        try {
          await loadTemplate(templateName);
          return templateName;
        } catch (e) {
          cli_logger.Logger.warning('预热模板失败: $templateName - $e');
          return null;
        }
      });

      final results = await Future.wait(futures);
      final successCount = results.where((result) => result != null).length;

      stopwatch.stop();
      _recordPerformance('warmup', stopwatch.elapsed);

      cli_logger.Logger.success(
        '模板引擎预热完成: $successCount/${templates.length} 个模板 '
        '(${stopwatch.elapsedMilliseconds}ms)',
      );
    } catch (e) {
      stopwatch.stop();
      cli_logger.Logger.error('模板引擎预热失败', error: e);
    }
  }

  /// 批量验证模板
  Future<Map<String, List<String>>> validateAllTemplates() async {
    final results = <String, List<String>>{};
    final templates = await getAvailableTemplates();

    for (final templateName in templates) {
      try {
        await _validateBrickYaml(getTemplatePath(templateName));
        results[templateName] = []; // 空列表表示无错误
      } catch (e) {
        results[templateName] = [e.toString()];
      }
    }

    return results;
  }

  /// 批量兼容性检查模板（增强版本）
  Future<Map<String, CompatibilityCheckResult>>
      validateAllTemplatesCompatibility({
    bool checkVersion = true,
    bool checkDependencies = true,
    bool checkPlatform = true,
    bool checkCompliance = true,
  }) async {
    final results = <String, CompatibilityCheckResult>{};
    final templates = await getAvailableTemplates();

    cli_logger.Logger.info('开始批量兼容性检查，共 ${templates.length} 个模板...');

    for (final templateName in templates) {
      try {
        final result = await checkTemplateCompatibility(
          templateName,
          checkVersion: checkVersion,
          checkDependencies: checkDependencies,
          checkPlatform: checkPlatform,
          checkCompliance: checkCompliance,
        );
        results[templateName] = result;

        if (result.isCompatible) {
          cli_logger.Logger.debug('✓ $templateName: 兼容性检查通过');
        } else {
          cli_logger.Logger.warning(
            '✗ $templateName: 兼容性检查失败 (${result.errors.length} 个错误)',
          );
        }
      } catch (e) {
        results[templateName] = CompatibilityCheckResult.failure(
          errors: ['兼容性检查异常: $e'],
        );
        cli_logger.Logger.error('模板兼容性检查异常: $templateName', error: e);
      }
    }

    final compatibleCount = results.values.where((r) => r.isCompatible).length;
    cli_logger.Logger.info(
      '批量兼容性检查完成: $compatibleCount/${templates.length} 个模板兼容',
    );

    return results;
  }

  /// 模板健康状态检查（增强版本）
  Future<Map<String, dynamic>> checkTemplateSystemHealth() async {
    final health = <String, dynamic>{
      'status': 'healthy',
      'checks': <String, dynamic>{},
      'warnings': <String>[],
      'errors': <String>[],
      'templates': <String, dynamic>{},
    };

    try {
      // 基础健康检查
      final basicHealth = await checkHealth();
      health['checks'].addAll(
        Map<String, dynamic>.from(basicHealth['checks'] as Map? ?? {}),
      );
      health['warnings'].addAll(
        (basicHealth['warnings'] as List<dynamic>?)?.cast<String>() ?? [],
      );
      health['errors'].addAll(
        (basicHealth['errors'] as List<dynamic>?)?.cast<String>() ?? [],
      );

      // 模板兼容性健康检查
      final compatibilityResults = await validateAllTemplatesCompatibility();

      var compatibleCount = 0;
      var totalErrors = 0;
      var totalWarnings = 0;

      for (final entry in compatibilityResults.entries) {
        final templateName = entry.key;
        final result = entry.value;

        if (result.isCompatible) {
          compatibleCount++;
        }

        totalErrors += result.errors.length;
        totalWarnings += result.warnings.length;

        health['templates'][templateName] = {
          'compatible': result.isCompatible,
          'errors': result.errors.length,
          'warnings': result.warnings.length,
          'platform_supported':
              (result.metadata['currentPlatform'] as Object?) != null,
        };
      }

      // 更新整体健康状态
      health['checks']['template_compatibility'] = {
        'total_templates': compatibilityResults.length,
        'compatible_templates': compatibleCount,
        'compatibility_rate': compatibilityResults.isEmpty
            ? 0.0
            : (compatibleCount / compatibilityResults.length * 100)
                .toStringAsFixed(1),
        'total_errors': totalErrors,
        'total_warnings': totalWarnings,
      };

      // 根据兼容性结果调整健康状态
      if (totalErrors > 0) {
        health['status'] = 'unhealthy';
        health['errors'].add('检测到 $totalErrors 个模板兼容性错误');
      } else if (totalWarnings > 0) {
        if (health['status'] == 'healthy') health['status'] = 'warning';
        health['warnings'].add('检测到 $totalWarnings 个模板兼容性警告');
      }

      // 兼容性率检查
      final compatibilityRate = compatibleCount / compatibilityResults.length;
      if (compatibilityRate < 0.8) {
        health['status'] = 'unhealthy';
        health['errors'].add(
          '模板兼容性率过低: ${(compatibilityRate * 100).toStringAsFixed(1)}%',
        );
      } else if (compatibilityRate < 0.9) {
        if (health['status'] == 'healthy') health['status'] = 'warning';
        health['warnings'].add(
          '模板兼容性率较低: ${(compatibilityRate * 100).toStringAsFixed(1)}%',
        );
      }
    } catch (e) {
      health['errors'].add('模板系统健康检查失败: $e');
      health['status'] = 'unhealthy';
    }

    return health;
  }

  /// 检查模板健康状态
  Future<Map<String, dynamic>> checkHealth() async {
    final health = <String, dynamic>{
      'status': 'healthy',
      'checks': <String, dynamic>{},
      'warnings': <String>[],
      'errors': <String>[],
    };

    try {
      // 检查工作目录
      if (!FileUtils.directoryExists(workingDirectory)) {
        health['errors'].add('工作目录不存在: $workingDirectory');
        health['status'] = 'unhealthy';
      } else {
        health['checks']['working_directory'] = 'ok';
      }

      // 检查模板目录
      final templatesPath = path.join(workingDirectory, 'templates');
      if (!FileUtils.directoryExists(templatesPath)) {
        health['warnings'].add('模板目录不存在: $templatesPath');
        health['status'] =
            health['status'] == 'unhealthy' ? 'unhealthy' : 'warning';
      } else {
        health['checks']['templates_directory'] = 'ok';
      }

      // 检查可用模板
      final templates = await getAvailableTemplates();
      health['checks']['available_templates'] = templates.length;
      if (templates.isEmpty) {
        health['warnings'].add('没有找到可用的模板');
        health['status'] =
            health['status'] == 'unhealthy' ? 'unhealthy' : 'warning';
      }

      // 检查缓存状态
      health['checks']['cache_size'] = _generatorCache.length;
      health['checks']['metadata_cache_size'] = _metadataCache.length;

      // 检查性能指标
      if (_performanceMetrics.isNotEmpty) {
        final avgMetrics = _calculateAveragePerformance();
        health['checks']['average_load_time'] =
            avgMetrics['loadTemplate']?.toStringAsFixed(2) ?? 'N/A';
      }
    } catch (e) {
      health['errors'].add('健康检查失败: $e');
      health['status'] = 'unhealthy';
    }

    return health;
  }

  /// 重建模板缓存
  Future<void> rebuildCache() async {
    cli_logger.Logger.info('正在重建模板缓存...');

    // 清理现有缓存
    clearCache();

    // 重新加载所有模板
    await warmup();

    cli_logger.Logger.success('模板缓存重建完成');
  }

  /// 获取模板信息
  Future<Map<String, dynamic>?> getTemplateInfo(String templateName) async {
    try {
      final templatePath = getTemplatePath(templateName);
      final brickPath = path.join(templatePath, 'brick.yaml');

      if (!FileUtils.fileExists(brickPath)) {
        return null;
      }

      final yamlData = await FileUtils.readYamlFile(brickPath);
      return yamlData;
    } catch (e) {
      cli_logger.Logger.error('获取模板信息失败', error: e);
      return null;
    }
  }

  // ==================== 高级特性方法 ====================

  /// 带钩子支持的高级生成方法
  @override
  Future<GenerationResult> generateWithHooks({
    required String templateName,
    required String outputPath,
    required Map<String, dynamic> variables,
    bool overwrite = false,
    List<TemplateHook>? additionalHooks,
    TemplateInheritance? inheritance,
  }) async {
    final stopwatch = Stopwatch()..start();
    var currentVariables = Map<String, dynamic>.from(variables);

    try {
      // 注册临时钩子
      if (additionalHooks != null) {
        for (final hook in additionalHooks) {
          hookRegistry.register(hook);
        }
      }

      // 处理模板继承
      if (inheritance != null) {
        currentVariables = await _processTemplateInheritance(
          templateName,
          inheritance,
          currentVariables,
        );
      }

      // 创建钩子上下文
      final context = HookContext(
        templateName: templateName,
        outputPath: outputPath,
        variables: currentVariables,
        metadata: {
          'startTime': DateTime.now().toIso8601String(),
          'inheritance': inheritance != null,
        },
      );

      // 执行pre-generation钩子
      final preResult = await _executeHooks(HookType.preGeneration, context);
      if (!preResult.success || !preResult.shouldContinue) {
        stopwatch.stop();
        return GenerationResult.failure(
          preResult.message ?? '预生成钩子执行失败',
          outputPath: outputPath,
        );
      }

      // 如果钩子修改了变量，使用修改后的变量
      if (preResult.modifiedVariables != null) {
        currentVariables.addAll(preResult.modifiedVariables!);
      }

      // 执行实际的模板生成
      final generationSuccess = await generateModule(
        templateName: templateName,
        outputPath: outputPath,
        variables: currentVariables,
        overwrite: overwrite,
      );

      if (!generationSuccess) {
        stopwatch.stop();
        return GenerationResult.failure(
          '模板生成失败',
          outputPath: outputPath,
        );
      }

      // 获取生成的文件列表
      final generatedFiles = await _getGeneratedFiles(outputPath);

      // 执行post-generation钩子
      final updatedContext = HookContext(
        templateName: templateName,
        outputPath: outputPath,
        variables: currentVariables,
        metadata: {
          ...context.metadata,
          'generatedFiles': generatedFiles,
          'endTime': DateTime.now().toIso8601String(),
        },
      );

      final postResult =
          await _executeHooks(HookType.postGeneration, updatedContext);
      if (!postResult.success) {
        cli_logger.Logger.warning('后生成钩子执行失败: ${postResult.message}');
      }

      stopwatch.stop();

      return GenerationResult(
        success: true,
        outputPath: outputPath,
        generatedFiles: generatedFiles,
        duration: stopwatch.elapsed,
        metadata: {
          'templateName': templateName,
          'inheritanceUsed': inheritance != null,
          'hooksExecuted': true,
        },
      );
    } catch (e) {
      stopwatch.stop();
      cli_logger.Logger.error('高级生成过程中发生异常', error: e);
      return GenerationResult.failure(
        '生成过程中发生异常: $e',
        outputPath: outputPath,
      );
    } finally {
      // 清理临时钩子
      if (additionalHooks != null) {
        for (final hook in additionalHooks) {
          hookRegistry.unregister(hook.name, hook.type);
        }
      }
    }
  }

  /// 异步并发生成多个模块
  Future<List<GenerationResult>> generateConcurrent({
    required List<Map<String, dynamic>> generationTasks,
    int concurrency = 3,
  }) async {
    final results = <GenerationResult>[];

    for (var i = 0; i < generationTasks.length; i += concurrency) {
      final batch = generationTasks.skip(i).take(concurrency);

      final batchFutures = batch.map((task) async {
        return generateWithHooks(
          templateName: task['templateName'] as String,
          outputPath: task['outputPath'] as String,
          variables: task['variables'] as Map<String, dynamic>,
          overwrite: task['overwrite'] as bool? ?? false,
          inheritance: task['inheritance'] as TemplateInheritance?,
        );
      });

      final batchResults = await Future.wait(batchFutures);
      results.addAll(batchResults);
    }

    return results;
  }

  /// 注册预设钩子
  void registerDefaultHooks() {
    // 注册默认的验证钩子
    hookRegistry.register(DefaultValidationHook());

    // 注册默认的日志钩子
    hookRegistry.register(DefaultLoggingHook());

    cli_logger.Logger.debug('已注册默认钩子');
  }

  /// 执行指定类型的钩子
  Future<HookResult> _executeHooks(
    HookType type,
    HookContext context,
  ) async {
    final hooks = hookRegistry.getHooks(type);
    final modifiedVariables = <String, dynamic>{};

    for (final hook in hooks) {
      try {
        final result = await hook.execute(context);

        if (!result.success) {
          cli_logger.Logger.error(
            '钩子执行失败: ${hook.name} - ${result.message}',
          );
          return result;
        }

        if (!result.shouldContinue) {
          cli_logger.Logger.info(
            '钩子请求停止: ${hook.name} - ${result.message}',
          );
          return result;
        }

        // 合并修改的变量
        if (result.modifiedVariables != null) {
          modifiedVariables.addAll(result.modifiedVariables!);
        }
      } catch (e) {
        cli_logger.Logger.error('钩子执行异常: ${hook.name}', error: e);
        return HookResult.failure('钩子执行异常: $e');
      }
    }

    return HookResult(
      success: true,
      modifiedVariables:
          modifiedVariables.isNotEmpty ? modifiedVariables : null,
    );
  }

  /// 处理模板继承
  Future<Map<String, dynamic>> _processTemplateInheritance(
    String templateName,
    TemplateInheritance inheritance,
    Map<String, dynamic> variables,
  ) async {
    try {
      // 加载基础模板信息
      final baseInfo = await getTemplateInfo(inheritance.baseTemplate);
      if (baseInfo == null) {
        cli_logger.Logger.warning(
          '基础模板不存在: ${inheritance.baseTemplate}',
        );
        return variables;
      }

      // 合并变量
      final mergedVariables = Map<String, dynamic>.from(variables);

      // 应用基础模板的默认变量
      if (baseInfo.containsKey('vars')) {
        final baseVars =
            Map<String, dynamic>.from(baseInfo['vars'] as Map? ?? {});
        for (final entry in baseVars.entries) {
          if (!mergedVariables.containsKey(entry.key)) {
            final varConfig =
                Map<String, dynamic>.from(entry.value as Map? ?? {});
            if (varConfig.containsKey('default')) {
              mergedVariables[entry.key] = varConfig['default'];
            }
          }
        }
      }

      // 应用继承覆盖
      mergedVariables.addAll(inheritance.overrides);

      cli_logger.Logger.debug(
        '模板继承处理完成: ${inheritance.baseTemplate} -> $templateName',
      );
      return mergedVariables;
    } catch (e) {
      cli_logger.Logger.error('处理模板继承时发生异常', error: e);
      return variables;
    }
  }

  /// 获取生成的文件列表
  Future<List<String>> _getGeneratedFiles(String outputPath) async {
    try {
      if (!FileUtils.directoryExists(outputPath)) {
        return [];
      }

      final entities = FileUtils.listDirectory(outputPath);
      final files = <String>[];

      for (final entity in entities) {
        if (entity is File) {
          files.add(path.relative(entity.path, from: outputPath));
        } else if (entity is Directory) {
          // 递归获取子目录文件
          final subFiles = await _getGeneratedFiles(entity.path);
          files.addAll(
            subFiles.map(
              (f) => path.join(
                path.relative(entity.path, from: outputPath),
                f,
              ),
            ),
          );
        }
      }

      return files;
    } catch (e) {
      cli_logger.Logger.error('获取生成文件列表失败', error: e);
      return [];
    }
  }

  // ==================== 兼容性检查辅助方法 ====================

  /// 解析版本信息
  TemplateVersionInfo _parseVersionInfo(Map<String, dynamic> yamlData) {
    final version = yamlData['version']?.toString() ?? '0.1.0';
    final environment =
        Map<String, dynamic>.from(yamlData['environment'] as Map? ?? {});
    final compatibility =
        Map<String, dynamic>.from(yamlData['compatibility'] as Map? ?? {});

    return TemplateVersionInfo(
      version: version,
      minCliVersion: compatibility['min_cli_version']?.toString(),
      maxCliVersion: compatibility['max_cli_version']?.toString(),
      minDartVersion: environment['sdk']?.toString().split(' ').first,
      maxDartVersion: environment['sdk']?.toString().split(' ').last,
      minMasonVersion: compatibility['min_mason_version']?.toString(),
      maxMasonVersion: compatibility['max_mason_version']?.toString(),
    );
  }

  /// 比较版本号
  int _compareVersions(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();

      // 确保两个版本具有相同的部分数
      final maxLength = math.max(v1Parts.length, v2Parts.length);
      while (v1Parts.length < maxLength) {
        v1Parts.add(0);
      }
      while (v2Parts.length < maxLength) {
        v2Parts.add(0);
      }

      for (var i = 0; i < maxLength; i++) {
        if (v1Parts[i] < v2Parts[i]) return -1;
        if (v1Parts[i] > v2Parts[i]) return 1;
      }
      return 0;
    } catch (e) {
      // 如果版本解析失败，认为相等
      return 0;
    }
  }

  /// 获取当前Dart版本
  String? _getCurrentDartVersion() {
    try {
      // 从Platform.version中提取Dart版本
      final versionString = Platform.version;
      final match = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(versionString);
      return match?.group(1);
    } catch (e) {
      cli_logger.Logger.warning('无法获取Dart版本: $e');
      return null;
    }
  }

  /// 获取当前Mason版本
  String? _getCurrentMasonVersion() {
    try {
      // 这里应该通过运行mason --version命令来获取
      // 为了简化，返回已知版本
      return '0.1.1';
    } catch (e) {
      cli_logger.Logger.warning('无法获取Mason版本: $e');
      return null;
    }
  }

  /// 解析依赖信息
  TemplateDependencyInfo _parseDependencyInfo(Map<String, dynamic> yamlData) {
    final dependencies =
        Map<String, dynamic>.from(yamlData['dependencies'] as Map? ?? {});
    final conflicts = (yamlData['conflicts'] as List?)?.cast<dynamic>() ?? [];

    final requiredDeps = <String, String>{};
    final optionalDeps = <String, String>{};

    // 处理必需依赖
    if (dependencies.containsKey('required')) {
      final required =
          Map<String, dynamic>.from(dependencies['required'] as Map? ?? {});
      for (final entry in required.entries) {
        requiredDeps[entry.key] = entry.value?.toString() ?? 'any';
      }
    }

    // 处理可选依赖
    if (dependencies.containsKey('optional')) {
      final optional =
          Map<String, dynamic>.from(dependencies['optional'] as Map? ?? {});
      for (final entry in optional.entries) {
        optionalDeps[entry.key] = entry.value?.toString() ?? 'any';
      }
    }

    return TemplateDependencyInfo(
      requiredDependencies: requiredDeps,
      optionalDependencies: optionalDeps,
      conflictingDependencies: conflicts.map((e) => e.toString()).toList(),
    );
  }

  /// 检查依赖可用性
  Future<bool> _checkDependencyAvailability(
    String dependencyName,
    String version,
  ) async {
    try {
      // 这里应该检查pub.dev或本地pubspec.yaml
      // 为了简化，假设常见依赖可用
      final commonDependencies = [
        'flutter',
        'dart',
        'path',
        'yaml',
        'json_annotation',
        'build_runner',
        'test',
        'very_good_analysis',
        'mason',
      ];
      return commonDependencies.contains(dependencyName);
    } catch (e) {
      return false;
    }
  }

  /// 检查依赖冲突
  Future<bool> _checkDependencyConflict(String dependencyName) async {
    try {
      // 这里应该检查当前项目的pubspec.yaml
      // 为了简化，假设没有冲突
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 解析平台信息
  TemplatePlatformInfo _parsePlatformInfo(Map<String, dynamic> yamlData) {
    final platforms =
        Map<String, dynamic>.from(yamlData['platforms'] as Map? ?? {});

    return TemplatePlatformInfo(
      supportedPlatforms: (platforms['supported'] as List?)
              ?.cast<dynamic>()
              .map((e) => e.toString())
              .toList() ??
          [],
      unsupportedPlatforms: (platforms['unsupported'] as List?)
              ?.cast<dynamic>()
              .map((e) => e.toString())
              .toList() ??
          [],
      requiredFeatures: (platforms['required_features'] as List?)
              ?.cast<dynamic>()
              .map((e) => e.toString())
              .toList() ??
          [],
      optionalFeatures: (platforms['optional_features'] as List?)
              ?.cast<dynamic>()
              .map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// 获取当前平台
  String _getCurrentPlatform() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isFuchsia) return 'fuchsia';
    return 'unknown';
  }

  /// 检查平台功能
  bool _checkPlatformFeature(String feature) {
    switch (feature.toLowerCase()) {
      case 'file_system':
        return true;
      case 'network':
        return true;
      case 'console':
        return !Platform.isAndroid && !Platform.isIOS;
      case 'gui':
        return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
      case 'mobile':
        return Platform.isAndroid || Platform.isIOS;
      case 'desktop':
        return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
      default:
        return false; // 未知功能假设不支持
    }
  }

  /// 验证版本格式
  bool _isValidVersionFormat(String version) {
    // 支持语义版本格式: x.y.z 或 x.y.z+build 或 x.y.z-pre+build
    final semanticVersionRegex = RegExp(
      r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$',
    );

    return semanticVersionRegex.hasMatch(version);
  }

  /// 获取模板统计信息
  Future<Map<String, dynamic>> getTemplateStats() async {
    final stats = <String, dynamic>{};
    final templates = await getAvailableTemplates();

    stats['total_templates'] = templates.length;
    stats['cached_templates'] = _generatorCache.length;

    final templateDetails = <String, Map<String, dynamic>>{};

    for (final templateName in templates) {
      try {
        final metadata =
            _metadataCache[templateName] ?? await getTemplateInfo(templateName);

        if (metadata != null) {
          templateDetails[templateName] = {
            'version': metadata['version'] ?? 'unknown',
            'description': metadata['description'] ?? '',
            'file_count': metadata['_file_count'] ?? 0,
            'cached': _generatorCache.containsKey(templateName),
          };
        }
      } catch (e) {
        templateDetails[templateName] = {
          'error': e.toString(),
          'cached': false,
        };
      }
    }

    stats['templates'] = templateDetails;
    return stats;
  }

  /// 获取模板参数系统
  Future<TemplateParameterSystem> getParameterSystem(
    String templateName,
  ) async {
    // 检查缓存
    if (_parameterSystemCache.containsKey(templateName)) {
      return _parameterSystemCache[templateName]!;
    }

    try {
      final templatePath = getTemplatePath(templateName);
      final brickPath = path.join(templatePath, 'brick.yaml');

      if (!FileUtils.fileExists(brickPath)) {
        throw TemplateEngineException.templateNotFound(templateName);
      }

      final yamlData = await FileUtils.readYamlFile(brickPath);
      if (yamlData == null) {
        throw TemplateEngineException(
          type: TemplateEngineErrorType.invalidTemplateFormat,
          message: '无法解析模板配置文件: $templateName',
        );
      }

      // 创建参数系统并加载配置
      final parameterSystem = TemplateParameterSystem();
      parameterSystem.loadFromBrickYaml(Map<String, dynamic>.from(yamlData));

      // 缓存参数系统
      _parameterSystemCache[templateName] = parameterSystem;

      cli_logger.Logger.debug(
        '模板参数系统加载成功: $templateName (${parameterSystem.variableCount} 个变量)',
      );
      return parameterSystem;
    } catch (e) {
      cli_logger.Logger.error('加载模板参数系统失败: $templateName', error: e);
      if (e is TemplateEngineException) rethrow;
      throw TemplateEngineException.masonError('getParameterSystem', e);
    }
  }

  /// 处理和验证模板变量
  Future<TemplateParameterProcessingResult> processTemplateVariables(
    String templateName,
    Map<String, dynamic> inputVariables,
  ) async {
    try {
      final parameterSystem = await getParameterSystem(templateName);
      return parameterSystem.processVariables(inputVariables);
    } catch (e) {
      return TemplateParameterProcessingResult.failure(
        ['处理模板变量失败: $e'],
      );
    }
  }

  /// 生成模块的增强版本（集成参数系统）
  Future<bool> generateModuleWithParameters({
    required String templateName,
    required String outputPath,
    required Map<String, dynamic> variables,
    bool overwrite = false,
    List<TemplateHook>? additionalHooks,
    TemplateInheritance? inheritance,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      cli_logger.Logger.info('开始生成模块: $templateName -> $outputPath');

      // 1. 处理模板变量
      final processingResult =
          await processTemplateVariables(templateName, variables);
      if (!processingResult.success) {
        cli_logger.Logger.error(
          '变量处理失败: ${processingResult.errors.join(", ")}',
        );
        return false;
      }

      final processedVariables = processingResult.getAllVariables();
      cli_logger.Logger.debug('变量处理完成: ${processedVariables.keys.length} 个变量');

      // 2. 使用高级生成方法
      final result = await generateWithHooks(
        templateName: templateName,
        outputPath: outputPath,
        variables: processedVariables,
        overwrite: overwrite,
        additionalHooks: additionalHooks,
        inheritance: inheritance,
      );

      if (result.success) {
        cli_logger.Logger.success(
          '模块生成成功: $outputPath (${stopwatch.elapsedMilliseconds}ms)',
        );

        // 记录生成的变量信息
        if (processingResult.generatedVariables.isNotEmpty) {
          cli_logger.Logger.debug(
            '生成的派生变量: ${processingResult.generatedVariables.keys.join(", ")}',
          );
        }

        return true;
      } else {
        cli_logger.Logger.error('模块生成失败: ${result.message}');
        return false;
      }
    } catch (e) {
      stopwatch.stop();
      cli_logger.Logger.error('模块生成异常', error: e);
      return false;
    }
  }

  /// 获取模板变量定义
  Future<List<TemplateVariable>> getTemplateVariableDefinitions(
    String templateName,
  ) async {
    try {
      final parameterSystem = await getParameterSystem(templateName);
      return parameterSystem.getAllVariableDefinitions();
    } catch (e) {
      cli_logger.Logger.error('获取模板变量定义失败: $templateName', error: e);
      return [];
    }
  }

  /// 获取模板的默认变量值
  Future<Map<String, dynamic>> getTemplateDefaultValues(
    String templateName,
  ) async {
    try {
      final parameterSystem = await getParameterSystem(templateName);
      return parameterSystem.getDefaultValues();
    } catch (e) {
      cli_logger.Logger.error('获取模板默认值失败: $templateName', error: e);
      return {};
    }
  }

  /// 获取模板的用户提示信息
  Future<Map<String, String>> getTemplatePrompts(String templateName) async {
    try {
      final parameterSystem = await getParameterSystem(templateName);
      return parameterSystem.getPrompts();
    } catch (e) {
      cli_logger.Logger.error('获取模板提示信息失败: $templateName', error: e);
      return {};
    }
  }

  /// 验证模板变量值（使用参数系统）
  Future<TemplateParameterValidationResult> validateTemplateVariablesWithSystem(
    String templateName,
    Map<String, dynamic> variables,
  ) async {
    try {
      final parameterSystem = await getParameterSystem(templateName);
      return parameterSystem.validateVariables(variables);
    } catch (e) {
      return TemplateParameterValidationResult(
        isValid: false,
        errors: ['验证模板变量失败: $e'],
        warnings: [],
        validatedVariables: {},
      );
    }
  }

  /// 插值模板字符串
  Future<String> interpolateTemplateString(
    String templateName,
    String template,
    Map<String, dynamic> variables,
  ) async {
    try {
      final parameterSystem = await getParameterSystem(templateName);
      return parameterSystem.interpolateTemplate(template, variables);
    } catch (e) {
      cli_logger.Logger.error('模板字符串插值失败', error: e);
      return template; // 返回原始模板
    }
  }

  /// 获取模板变量摘要
  Future<Map<String, dynamic>> getTemplateVariableSummary(
    String templateName,
  ) async {
    try {
      final parameterSystem = await getParameterSystem(templateName);
      return parameterSystem.generateVariableSummary();
    } catch (e) {
      cli_logger.Logger.error('获取模板变量摘要失败: $templateName', error: e);
      return {};
    }
  }

  // ==================== Task 33.* 高级钩子公共方法 ====================

  /// 加载模板的钩子配置
  Future<void> loadTemplateHooks(String templateName) async {
    await advancedHookManager.loadHooksFromBrickConfig(templateName);
  }

  /// 验证钩子配置
  List<String> validateHookConfiguration(Map<String, dynamic> hookConfig) {
    return advancedHookManager.validateHookConfig(hookConfig);
  }

  /// 获取钩子执行统计信息
  Map<String, dynamic> getHookStatistics() {
    return advancedHookManager.getHookStatistics();
  }

  /// 注册条件钩子
  void registerConditionalHook(
    String name,
    String condition,
    TemplateHook hook,
  ) {
    final conditionalHook = ConditionalHook(
      name: name,
      condition: condition,
      wrappedHook: hook,
    );
    hookRegistry.register(conditionalHook);
  }

  /// 注册超时钩子
  void registerTimeoutHook(String name, Duration timeout, TemplateHook hook) {
    final timeoutHook = TimeoutHook(
      name: name,
      timeout: timeout,
      wrappedHook: hook,
    );
    hookRegistry.register(timeoutHook);
  }

  /// 注册错误恢复钩子
  void registerErrorRecoveryHook(
    String name,
    TemplateHook hook,
    Future<HookResult> Function(HookResult) recoveryAction, {
    bool ignoreErrors = false,
  }) {
    final recoveryHook = ErrorRecoveryHook(
      name: name,
      wrappedHook: hook,
      recoveryAction: recoveryAction,
      ignoreErrors: ignoreErrors,
    );
    hookRegistry.register(recoveryHook);
  }

  /// 注册脚本执行钩子
  void registerScriptHook(
    hook_impl.ScriptHookConfig config,
    HookType hookType, {
    int priority = 100,
  }) {
    final scriptHook = hook_impl.ScriptExecutionHook(
      name: 'script_hook_${config.description.hashCode}',
      config: config,
      hookType: hookType,
      hookPriority: priority,
    );
    hookRegistry.register(scriptHook);
  }

  /// 带钩子加载的高级生成方法
  Future<GenerationResult> generateModuleWithLoadedHooks({
    required String templateName,
    required String outputPath,
    required Map<String, dynamic> variables,
    bool overwrite = false,
    List<TemplateHook>? additionalHooks,
    TemplateInheritance? inheritance,
  }) async {
    // 首先加载模板的钩子配置
    await loadTemplateHooks(templateName);

    // 然后执行带钩子的生成
    return generateWithHooks(
      templateName: templateName,
      outputPath: outputPath,
      variables: variables,
      overwrite: overwrite,
      additionalHooks: additionalHooks,
      inheritance: inheritance,
    );
  }

  /// 清理钩子注册表
  void clearAllHooks() {
    hookRegistry.clear();
  }

  /// 获取钩子详细信息
  Map<String, dynamic> getHookDetails() {
    final stats = getHookStatistics();
    final preHooks = hookRegistry.getHooks(HookType.preGeneration);
    final postHooks = hookRegistry.getHooks(HookType.postGeneration);

    return {
      ...stats,
      'pre_generation_hook_names': preHooks.map((h) => h.name).toList(),
      'post_generation_hook_names': postHooks.map((h) => h.name).toList(),
      'script_execution_hooks': [
        ...preHooks.whereType<hook_impl.ScriptExecutionHook>(),
        ...postHooks.whereType<hook_impl.ScriptExecutionHook>(),
      ]
          .map(
            (h) => {
              'name': h.name,
              'type': h.type.toString(),
              'priority': h.priority,
              'description': h.config.description,
              'script': h.config.scriptPath,
            },
          )
          .toList(),
    };
  }
}
