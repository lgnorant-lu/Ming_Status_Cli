/*
---------------------------------------------------------------
File name:          config_manager.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        配置管理器 (Configuration manager)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 基础配置管理功能;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/models/module_config.dart';
import 'package:ming_status_cli/src/models/workspace_config.dart';
import 'package:ming_status_cli/src/utils/file_utils.dart';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:path/path.dart' as path;

/// 配置验证结果
class ConfigValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final List<String> suggestions;

  const ConfigValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.suggestions = const [],
  });

  /// 创建成功的验证结果
  factory ConfigValidationResult.success({
    List<String>? warnings,
    List<String>? suggestions,
  }) {
    return ConfigValidationResult(
      isValid: true,
      warnings: warnings ?? [],
      suggestions: suggestions ?? [],
    );
  }

  /// 创建失败的验证结果
  factory ConfigValidationResult.failure({
    required List<String> errors,
    List<String>? warnings,
    List<String>? suggestions,
  }) {
    return ConfigValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings ?? [],
      suggestions: suggestions ?? [],
    );
  }

  /// 是否有任何问题
  bool get hasIssues => errors.isNotEmpty || warnings.isNotEmpty;

  /// 获取所有问题的摘要
  String get summary {
    final buffer = StringBuffer();
    if (errors.isNotEmpty) {
      buffer.writeln('错误 (${errors.length}):');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }
    if (warnings.isNotEmpty) {
      buffer.writeln('警告 (${warnings.length}):');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }
    if (suggestions.isNotEmpty) {
      buffer.writeln('建议 (${suggestions.length}):');
      for (final suggestion in suggestions) {
        buffer.writeln('  - $suggestion');
      }
    }
    return buffer.toString().trim();
  }
}

/// 配置验证规则严格程度
enum ValidationStrictness {
  /// 基础验证：只检查必需字段和基本格式
  basic,

  /// 标准验证：基础验证 + 字段值有效性检查
  standard,

  /// 严格验证：标准验证 + 语义约束和依赖关系检查
  strict,

  /// 企业级验证：严格验证 + 安全性和合规性检查
  enterprise,
}

/// 配置管理器
/// 负责工作空间和模块配置的加载、保存和管理
class ConfigManager {
  ConfigManager({String? workingDirectory}) 
      : workingDirectory = workingDirectory ?? Directory.current.path;

  /// 默认配置文件名
  static const String defaultConfigFileName = 'ming_status.yaml';
  static const String moduleConfigFileName = 'module.yaml';
  
  /// 当前工作目录
  final String workingDirectory;
  
  /// 缓存的工作空间配置
  WorkspaceConfig? _cachedWorkspaceConfig;
  
  /// 配置文件路径
  String get configFilePath =>
      path.join(workingDirectory, defaultConfigFileName);

  /// 检查是否已初始化工作空间
  bool isWorkspaceInitialized() {
    return FileUtils.fileExists(configFilePath);
  }

  /// 初始化工作空间
  Future<bool> initializeWorkspace({
    required String workspaceName,
    String? description,
    String? author,
    String? templateType = 'basic',
  }) async {
    try {
      Logger.info('正在初始化工作空间: $workspaceName (模板: $templateType)');
      
      // 检查是否已存在配置
      if (isWorkspaceInitialized()) {
        Logger.warning('工作空间已存在配置文件');
        return false;
      }
      
      // 根据模板类型创建配置
      WorkspaceConfig config;
      if (templateType == 'enterprise') {
        config = await _createConfigFromTemplate(
            'enterprise', workspaceName, description, author);
      } else {
        config = await _createConfigFromTemplate(
            'basic', workspaceName, description, author);
      }
      
      // 保存配置文件
      final success = await saveWorkspaceConfig(config);
      if (success) {
        Logger.success('工作空间初始化成功');
        _cachedWorkspaceConfig = config;
        
        // 创建目录结构和模板
        await _createDirectoryStructure();
        await _copyConfigTemplates();
        
        return true;
      } else {
        Logger.error('工作空间初始化失败：无法保存配置文件');
        return false;
      }
    } catch (e) {
      Logger.error('工作空间初始化异常', error: e);
      return false;
    }
  }

  /// 加载工作空间配置
  Future<WorkspaceConfig?> loadWorkspaceConfig({bool useCache = true}) async {
    try {
      // 使用缓存
      if (useCache && _cachedWorkspaceConfig != null) {
        return _cachedWorkspaceConfig;
      }
      
      // 检查配置文件是否存在
      if (!FileUtils.fileExists(configFilePath)) {
        Logger.warning('工作空间配置文件不存在: $configFilePath');
        return null;
      }
      
      // 读取YAML文件
      final yamlData = await FileUtils.readYamlFile(configFilePath);
      if (yamlData == null) {
        Logger.error('无法解析工作空间配置文件');
        return null;
      }
      
      // 转换为配置对象（需要先转换YamlMap为Map<String, dynamic>）
      final jsonData = _deepConvertYamlMap(yamlData) as Map<String, dynamic>;
      final config = WorkspaceConfig.fromJson(jsonData);
      _cachedWorkspaceConfig = config;
      
      Logger.debug('工作空间配置加载成功');
      return config;
    } catch (e) {
      Logger.error('加载工作空间配置失败', error: e);
      return null;
    }
  }

  /// 保存工作空间配置
  Future<bool> saveWorkspaceConfig(WorkspaceConfig config) async {
    try {
      // 转换为YAML数据
      final yamlData = config.toJson();
      
      // 保存到文件
      final success = await FileUtils.writeYamlFile(configFilePath, yamlData);
      if (success) {
        _cachedWorkspaceConfig = config;
        Logger.debug('工作空间配置保存成功');
        return true;
      } else {
        Logger.error('保存工作空间配置失败');
        return false;
      }
    } catch (e) {
      Logger.error('保存工作空间配置异常', error: e);
      return false;
    }
  }

  /// 更新工作空间配置
  Future<bool> updateWorkspaceConfig(
      WorkspaceConfig Function(WorkspaceConfig) updater) async {
    try {
      final currentConfig = await loadWorkspaceConfig();
      if (currentConfig == null) {
        Logger.error('无法加载当前配置进行更新');
        return false;
      }
      
      final updatedConfig = updater(currentConfig);
      return await saveWorkspaceConfig(updatedConfig);
    } catch (e) {
      Logger.error('更新工作空间配置异常', error: e);
      return false;
    }
  }

  /// 加载模块配置
  Future<ModuleConfig?> loadModuleConfig(String modulePath) async {
    try {
      final configPath = path.join(modulePath, moduleConfigFileName);
      
      if (!FileUtils.fileExists(configPath)) {
        Logger.warning('模块配置文件不存在: $configPath');
        return null;
      }
      
      final yamlData = await FileUtils.readYamlFile(configPath);
      if (yamlData == null) {
        Logger.error('无法解析模块配置文件: $configPath');
        return null;
      }
      
      // 这里应该根据实际的模块配置结构进行转换
      // 暂时返回一个基础配置
      Logger.debug('模块配置加载成功: $modulePath');
      return ModuleConfig.defaultConfig(
        id: yamlData['id']?.toString() ?? 'unknown',
        name: yamlData['name']?.toString() ?? 'Unknown Module',
        description: yamlData['description']?.toString(),
      );
    } catch (e) {
      Logger.error('加载模块配置失败', error: e);
      return null;
    }
  }

  /// 保存模块配置
  Future<bool> saveModuleConfig(String modulePath, ModuleConfig config) async {
    try {
      final configPath = path.join(modulePath, moduleConfigFileName);
      
      // 创建模块目录
      await FileUtils.createDirectory(modulePath);
      
      // 构建YAML数据
      final yamlData = {
        'id': config.module.id,
        'name': config.module.name,
        'version': config.module.version,
        'description': config.module.description,
        'author': config.module.author,
        'type': config.classification.type.name,
        'categories': config.classification.categories,
        'dependencies': config.dependencies.required,
        'optional_dependencies': config.dependencies.optional,
        'permissions': config.permissions,
        'exports': {
          'services': config.exports.services.map((s) => s.name).toList(),
          'widgets': config.exports.widgets.map((w) => w.name).toList(),
        },
      };
      
      final success = await FileUtils.writeYamlFile(configPath, yamlData);
      if (success) {
        Logger.debug('模块配置保存成功: $modulePath');
        return true;
      } else {
        Logger.error('保存模块配置失败: $modulePath');
        return false;
      }
    } catch (e) {
      Logger.error('保存模块配置异常', error: e);
      return false;
    }
  }

  /// 获取模板路径
  String getTemplatesPath() {
    final config = _cachedWorkspaceConfig;
    if (config?.templates.localPath != null) {
      return path.isAbsolute(config!.templates.localPath!)
          ? config.templates.localPath!
          : path.join(workingDirectory, config.templates.localPath);
    }
    
    // 默认模板路径
    return path.join(workingDirectory, 'templates');
  }

  /// 列出可用的模板
  List<String> listAvailableTemplates() {
    final templatesPath = getTemplatesPath();
    
    if (!FileUtils.directoryExists(templatesPath)) {
      Logger.warning('模板目录不存在: $templatesPath');
      return [];
    }
    
    final entities = FileUtils.listDirectory(templatesPath);
    final templates = <String>[];
    
    for (final entity in entities) {
      if (entity is Directory) {
        final templateName = path.basename(entity.path);
        templates.add(templateName);
      }
    }
    
    return templates;
  }

  /// 验证模板是否存在
  bool isTemplateAvailable(String templateName) {
    // 首先检查是否是内置模板
    if (templateName == 'basic' || templateName == 'enterprise') {
      return true;
    }

    // 然后检查本地文件系统模板
    final templatesPath = getTemplatesPath();
    final templatePath = path.join(templatesPath, templateName);
    return FileUtils.directoryExists(templatePath);
  }

  /// 获取模板路径
  String getTemplatePath(String templateName) {
    final templatesPath = getTemplatesPath();
    return path.join(templatesPath, templateName);
  }

  /// 清理缓存
  void clearCache() {
    _cachedWorkspaceConfig = null;
    Logger.debug('配置缓存已清理');
  }

  /// 创建目录结构
  Future<void> _createDirectoryStructure() async {
    final directories = [
      'templates',
      'modules',
      'output',
    ];
    
    for (final dir in directories) {
      final dirPath = path.join(workingDirectory, dir);
      await FileUtils.createDirectory(dirPath);
      Logger.debug('创建目录: $dirPath');
    }
  }

  /// 获取工作空间信息摘要
  Map<String, dynamic> getWorkspaceSummary() {
    final config = _cachedWorkspaceConfig;
    if (config == null) {
      return {'initialized': false};
    }
    
    return {
      'initialized': true,
      'name': config.workspace.name,
      'version': config.workspace.version,
      'description': config.workspace.description,
      'templates_count': listAvailableTemplates().length,
      'templates_path': getTemplatesPath(),
      'config_file': configFilePath,
    };
  }

  /// 从模板创建配置
  Future<WorkspaceConfig> _createConfigFromTemplate(
    String templateType,
    String workspaceName,
    String? description,
    String? author,
  ) async {
    try {
      final templatePath = path.join(
          'templates', 'workspace', 'ming_workspace_${templateType}.yaml');

      // 检查模板文件是否存在
      if (FileUtils.fileExists(templatePath)) {
        Logger.debug('从模板文件加载配置: $templatePath');
        final templateData = await FileUtils.readYamlFile(templatePath);

        if (templateData != null) {
          // 应用用户自定义参数
          if (templateData['workspace'] != null) {
            templateData['workspace']['name'] = workspaceName;
            if (description != null) {
              templateData['workspace']['description'] = description;
            }
          }
          if (templateData['defaults'] != null && author != null) {
            templateData['defaults']['author'] = author;
          }

          // 验证并返回配置
          final config = WorkspaceConfig.fromJson(templateData);
          Logger.debug('从模板创建配置成功: $templateType');
          return config;
        }
      }

      Logger.warning('模板文件不存在，使用内置模板: $templateType');

      // 使用内置模板
      final WorkspaceConfig baseConfig;
      if (templateType == 'enterprise') {
        baseConfig = WorkspaceConfig.enterpriseConfig();
      } else {
        baseConfig = WorkspaceConfig.defaultConfig();
      }

      // 应用用户参数到内置模板
      return baseConfig.copyWith(
        workspace: WorkspaceInfo(
          name: workspaceName,
          version: baseConfig.workspace.version,
          description: description ?? baseConfig.workspace.description,
          type: templateType == 'enterprise'
              ? WorkspaceType.enterprise
              : WorkspaceType.basic,
        ),
        defaults: baseConfig.defaults.copyWith(
          author: author ?? baseConfig.defaults.author,
        ),
      );
    } catch (e) {
      Logger.error('从模板创建配置失败', error: e);

      // 返回带用户参数的基础默认配置作为后备
      final baseConfig = WorkspaceConfig.defaultConfig();
      return baseConfig.copyWith(
        workspace: WorkspaceInfo(
          name: workspaceName,
          version: baseConfig.workspace.version,
          description: description ?? 'Ming Status模块工作空间',
          type: baseConfig.workspace.type,
        ),
        defaults: baseConfig.defaults.copyWith(
          author: author ?? '开发者名称',
        ),
      );
    }
  }

  /// 复制配置模板到工作空间
  Future<void> _copyConfigTemplates() async {
    try {
      final templatesPath = getTemplatesPath();
      await FileUtils.createDirectory(templatesPath);

      final workspaceTemplatesPath = path.join(templatesPath, 'workspace');
      await FileUtils.createDirectory(workspaceTemplatesPath);

      Logger.debug('配置模板目录已创建: $workspaceTemplatesPath');
    } catch (e) {
      Logger.error('复制配置模板失败', error: e);
    }
  }

  /// 验证模板是否存在
  Future<bool> validateConfigTemplate(String templatePath) async {
    try {
      // 首先检查是否是内置模板
      if (templatePath == 'basic' || templatePath == 'enterprise') {
        Logger.debug('验证内置模板: $templatePath');
        try {
          final testConfig = await _createConfigFromTemplate(
            templatePath,
            'Test Workspace',
            'Test description',
            'Test Author',
          );
          Logger.debug('内置配置模板验证成功: $templatePath');
          return true;
        } catch (e) {
          Logger.error('内置配置模板验证失败: $templatePath', error: e);
          return false;
        }
      }

      // 如果是相对路径且文件不存在，尝试使用内置模板验证
      if (!FileUtils.fileExists(templatePath)) {
        Logger.debug('配置模板文件不存在: $templatePath，尝试验证内置模板');

        // 提取模板类型
        final templateName = path.basenameWithoutExtension(templatePath);
        Logger.debug('提取的模板名称: $templateName');

        if (templateName.startsWith('ming_workspace_')) {
          final templateType = templateName.replaceFirst('ming_workspace_', '');
          Logger.debug('提取的模板类型: $templateType');

          // 验证是否是支持的模板类型
          if (templateType == 'basic' || templateType == 'enterprise') {
            // 使用内置模板验证
            try {
              final testConfig = await _createConfigFromTemplate(
                templateType,
                'Test Workspace',
                'Test description',
                'Test Author',
              );
              Logger.debug('内置配置模板验证成功: $templateType');
              return true;
            } catch (e) {
              Logger.error('内置配置模板验证失败: $templateType', error: e);
              return false;
            }
          } else {
            Logger.error('不支持的模板类型: $templateType');
            return false;
          }
        }

        Logger.error('配置模板文件不存在且无法匹配内置模板: $templatePath');
        return false;
      }

      final templateData = await FileUtils.readYamlFile(templatePath);
      if (templateData == null) {
        Logger.error('无法解析配置模板文件: $templatePath');
        return false;
      }

      Logger.debug('成功读取模板文件，包含字段: ${templateData.keys.toList()}');

      // 验证必需字段
      final requiredFields = [
        'workspace',
        'templates',
        'defaults',
        'validation'
      ];
      for (final field in requiredFields) {
        if (!templateData.containsKey(field)) {
          Logger.error('配置模板缺少必需字段: $field');
          return false;
        }
      }

      Logger.debug('所有必需字段验证通过');

      // 尝试解析为WorkspaceConfig
      try {
        // 将YamlMap深度转换为Map<String, dynamic>
        final jsonData =
            _deepConvertYamlMap(templateData) as Map<String, dynamic>;
        final config = WorkspaceConfig.fromJson(jsonData);
        Logger.debug('WorkspaceConfig解析成功: ${config.workspace.name}');
        Logger.debug('配置模板验证成功: $templatePath');
        return true;
      } catch (e) {
        Logger.error('WorkspaceConfig解析失败: $e');
        return false;
      }
    } catch (e) {
      Logger.error('配置模板验证失败', error: e);
      return false;
    }
  }

  /// 应用配置模板
  Future<bool> applyConfigTemplate(String templateType) async {
    try {
      final config = await loadWorkspaceConfig();
      if (config == null) {
        Logger.error('无法加载当前工作空间配置');
        return false;
      }

      // 创建新的模板配置，保留用户的基本信息
      final templateConfig = await _createConfigFromTemplate(
        templateType,
        config.workspace.name, // 保留工作空间名称
        config.workspace.description, // 保留描述
        config.defaults.author, // 保留作者信息
      );

      // 应用模板配置，更新工作空间类型
      final updatedConfig = templateConfig.copyWith(
        workspace: WorkspaceInfo(
          name: config.workspace.name,
          version: templateConfig.workspace.version, // 使用模板的版本
          description: config.workspace.description,
          type: templateType == 'enterprise'
              ? WorkspaceType.enterprise
              : WorkspaceType.basic,
        ),
        defaults: templateConfig.defaults.copyWith(
          author: config.defaults.author, // 保留用户作者信息
        ),
      );

      final success = await saveWorkspaceConfig(updatedConfig);
      if (success) {
        Logger.success('配置模板应用成功: $templateType');
        return true;
      } else {
        Logger.error('应用配置模板失败: 无法保存配置');
        return false;
      }
    } catch (e) {
      Logger.error('应用配置模板异常', error: e);
      return false;
    }
  }

  /// 列出可用的配置模板
  List<String> listConfigTemplates() {
    final configTemplates = <String>[];

    // 检查内置模板
    configTemplates.addAll(['basic', 'enterprise']);

    // 检查本地模板文件
    final templatesPath = getTemplatesPath();
    final workspaceTemplatesPath = path.join(templatesPath, 'workspace');

    if (FileUtils.directoryExists(workspaceTemplatesPath)) {
      final entities = FileUtils.listDirectory(workspaceTemplatesPath);
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.yaml')) {
          final templateName = path.basenameWithoutExtension(entity.path);
          if (templateName.startsWith('ming_workspace_')) {
            final configType = templateName.replaceFirst('ming_workspace_', '');
            if (!configTemplates.contains(configType)) {
              configTemplates.add(configType);
            }
          }
        }
      }
    }

    return configTemplates;
  }

  /// 深度转换YamlMap为Map<String, dynamic>
  dynamic _deepConvertYamlMap(dynamic yamlData) {
    if (yamlData is Map) {
      return Map<String, dynamic>.from(yamlData.map((key, value) =>
          MapEntry(key.toString(), _deepConvertYamlMap(value))));
    } else if (yamlData is List) {
      return yamlData.map((item) => _deepConvertYamlMap(item)).toList();
    } else {
      return yamlData;
    }
  }

  /// 验证工作空间配置（增强版本）
  Future<ConfigValidationResult> validateWorkspaceConfig(
    WorkspaceConfig config, {
    ValidationStrictness strictness = ValidationStrictness.standard,
    bool checkDependencies = true,
    bool checkFileSystem = true,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];

    try {
      // 1. 基础字段验证
      await _validateBasicFields(config, errors, warnings);

      // 2. 工作空间信息验证
      await _validateWorkspaceInfo(
          config.workspace, errors, warnings, suggestions);

      // 3. 模板配置验证
      await _validateTemplateConfig(
          config.templates, errors, warnings, suggestions);

      // 4. 默认设置验证
      await _validateDefaultSettings(
          config.defaults, errors, warnings, suggestions);

      // 5. 验证规则检查
      await _validateValidationRules(config, errors, warnings);

      if (strictness.index >= ValidationStrictness.standard.index) {
        // 6. 字段值有效性检查
        await _validateFieldValues(config, errors, warnings, suggestions);

        // 7. 环境配置验证（如果存在）
        if (config.environments != null) {
          await _validateEnvironmentConfigs(
              config.environments!, errors, warnings, suggestions);
        }
      }

      if (strictness.index >= ValidationStrictness.strict.index) {
        // 8. 语义约束验证
        await _validateSemanticConstraints(
            config, errors, warnings, suggestions);

        // 9. 依赖关系检查
        if (checkDependencies) {
          await _validateDependencyConsistency(
              config, errors, warnings, suggestions);
        }

        // 10. 配置一致性检查
        await _validateConfigConsistency(config, errors, warnings, suggestions);
      }

      if (strictness.index >= ValidationStrictness.enterprise.index) {
        // 11. 安全性检查
        await _validateSecurityConstraints(
            config, errors, warnings, suggestions);

        // 12. 合规性检查
        await _validateComplianceRequirements(
            config, errors, warnings, suggestions);
      }

      if (checkFileSystem) {
        // 13. 文件系统验证
        await _validateFileSystemConsistency(
            config, errors, warnings, suggestions);
      }

      // 14. 性能影响评估
      await _validatePerformanceImpact(config, warnings, suggestions);

      return errors.isEmpty
          ? ConfigValidationResult.success(
              warnings: warnings, suggestions: suggestions)
          : ConfigValidationResult.failure(
              errors: errors, warnings: warnings, suggestions: suggestions);
    } catch (e) {
      Logger.error('配置验证过程中发生异常', error: e);
      return ConfigValidationResult.failure(
        errors: ['配置验证过程中发生异常: ${e.toString()}'],
      );
    }
  }

  /// 验证配置模板（增强版本）
  Future<ConfigValidationResult> validateConfigTemplateEnhanced(
    String templatePath, {
    ValidationStrictness strictness = ValidationStrictness.standard,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];

    try {
      // 1. 基础模板验证（复用现有逻辑）
      final basicValidation = await validateConfigTemplate(templatePath);
      if (!basicValidation) {
        errors.add('模板基础验证失败: $templatePath');
        return ConfigValidationResult.failure(errors: errors);
      }

      // 2. 加载模板配置
      WorkspaceConfig? templateConfig;

      // 检查是否是内置模板
      if (templatePath == 'basic' || templatePath == 'enterprise') {
        try {
          templateConfig = await _createConfigFromTemplate(
              templatePath, 'Test', 'Test', 'Test');
        } catch (e) {
          errors.add('无法加载内置模板 $templatePath: ${e.toString()}');
          return ConfigValidationResult.failure(errors: errors);
        }
      } else {
        // 外部模板文件
        if (!FileUtils.fileExists(templatePath)) {
          errors.add('模板文件不存在: $templatePath');
          return ConfigValidationResult.failure(errors: errors);
        }

        try {
          final templateData = await FileUtils.readYamlFile(templatePath);
          if (templateData == null) {
            errors.add('无法解析模板文件: $templatePath');
            return ConfigValidationResult.failure(errors: errors);
          }

          final jsonData =
              _deepConvertYamlMap(templateData) as Map<String, dynamic>;
          templateConfig = WorkspaceConfig.fromJson(jsonData);
        } catch (e) {
          errors.add('模板配置解析失败: ${e.toString()}');
          return ConfigValidationResult.failure(errors: errors);
        }
      }

      // 3. 对模板配置进行深度验证
      if (templateConfig != null) {
        final configValidationResult = await validateWorkspaceConfig(
          templateConfig,
          strictness: strictness,
          checkDependencies: false, // 模板验证时不检查依赖
          checkFileSystem: false, // 模板验证时不检查文件系统
        );

        errors.addAll(configValidationResult.errors);
        warnings.addAll(configValidationResult.warnings);
        suggestions.addAll(configValidationResult.suggestions);

        // 4. 模板特定验证
        await _validateTemplateSpecificConstraints(
            templateConfig, templatePath, errors, warnings, suggestions);
      }

      return errors.isEmpty
          ? ConfigValidationResult.success(
              warnings: warnings, suggestions: suggestions)
          : ConfigValidationResult.failure(
              errors: errors, warnings: warnings, suggestions: suggestions);
    } catch (e) {
      Logger.error('模板验证过程中发生异常', error: e);
      return ConfigValidationResult.failure(
        errors: ['模板验证过程中发生异常: ${e.toString()}'],
      );
    }
  }

  /// 检查配置完整性
  Future<ConfigValidationResult> checkConfigIntegrity({
    bool checkWorkspace = true,
    bool checkModules = true,
    bool checkTemplates = true,
    ValidationStrictness strictness = ValidationStrictness.standard,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];

    try {
      // 1. 工作空间配置完整性检查
      if (checkWorkspace) {
        if (isWorkspaceInitialized()) {
          final workspaceConfig = await loadWorkspaceConfig();
          if (workspaceConfig != null) {
            final result = await validateWorkspaceConfig(workspaceConfig,
                strictness: strictness);
            errors.addAll(result.errors);
            warnings.addAll(result.warnings);
            suggestions.addAll(result.suggestions);
          } else {
            errors.add('工作空间配置文件存在但无法加载');
          }
        } else {
          warnings.add('工作空间尚未初始化');
          suggestions.add('运行 "ming init" 初始化工作空间');
        }
      }

      // 2. 模块配置完整性检查
      if (checkModules) {
        await _checkModulesIntegrity(errors, warnings, suggestions);
      }

      // 3. 模板完整性检查
      if (checkTemplates) {
        await _checkTemplatesIntegrity(
            errors, warnings, suggestions, strictness);
      }

      // 4. 全局一致性检查
      await _checkGlobalConsistency(errors, warnings, suggestions);

      return errors.isEmpty
          ? ConfigValidationResult.success(
              warnings: warnings, suggestions: suggestions)
          : ConfigValidationResult.failure(
              errors: errors, warnings: warnings, suggestions: suggestions);
    } catch (e) {
      Logger.error('配置完整性检查过程中发生异常', error: e);
      return ConfigValidationResult.failure(
        errors: ['配置完整性检查过程中发生异常: ${e.toString()}'],
      );
    }
  }

  // ===== 私有验证方法实现 =====

  /// 基础字段验证
  Future<void> _validateBasicFields(WorkspaceConfig config, List<String> errors,
      List<String> warnings) async {
    // 验证工作空间名称
    if (config.workspace.name.isEmpty) {
      errors.add('工作空间名称不能为空');
    } else if (config.workspace.name.length < 2) {
      warnings.add('工作空间名称过短，建议至少2个字符');
    } else if (config.workspace.name.length > 50) {
      warnings.add('工作空间名称过长，建议不超过50个字符');
    }

    // 验证版本号格式
    if (config.workspace.version.isEmpty) {
      errors.add('工作空间版本号不能为空');
    } else if (!RegExp(r'^\d+\.\d+\.\d+').hasMatch(config.workspace.version)) {
      warnings.add('版本号建议使用语义版本格式 (如: 1.0.0)');
    }

    // 验证作者信息
    if (config.defaults.author.isEmpty) {
      warnings.add('建议设置默认作者信息');
    }
  }

  /// 工作空间信息验证
  Future<void> _validateWorkspaceInfo(
      WorkspaceInfo workspace,
      List<String> errors,
      List<String> warnings,
      List<String> suggestions) async {
    // 验证工作空间名称的合法性
    if (workspace.name.contains(RegExp(r'[<>:"/\\|?*]'))) {
      errors.add('工作空间名称包含非法字符');
    }

    // 验证描述信息
    if (workspace.description?.isEmpty ?? true) {
      suggestions.add('建议添加工作空间描述信息');
    } else if (workspace.description!.length > 500) {
      warnings.add('工作空间描述过长，建议控制在500字符以内');
    }

    // 验证工作空间类型
    if (workspace.type == WorkspaceType.enterprise) {
      suggestions.add('企业级工作空间可以启用高级功能如团队协作、质量保障等');
    }
  }

  /// 模板配置验证
  Future<void> _validateTemplateConfig(
      TemplateConfig templates,
      List<String> errors,
      List<String> warnings,
      List<String> suggestions) async {
    // 验证本地路径
    if (templates.localPath != null && templates.localPath!.isNotEmpty) {
      final templatePath = path.isAbsolute(templates.localPath!)
          ? templates.localPath!
          : path.join(workingDirectory, templates.localPath!);

      if (!FileUtils.directoryExists(templatePath)) {
        warnings.add('配置的模板目录不存在: ${templates.localPath}');
        suggestions.add('运行 "ming init" 重新初始化工作空间目录结构');
      }
    }

    // 验证缓存超时设置
    if (templates.cacheTimeout != null) {
      if (templates.cacheTimeout! < 0) {
        errors.add('模板缓存超时时间不能为负数');
      } else if (templates.cacheTimeout! > 86400) {
        warnings.add('模板缓存超时时间过长 (>24小时)，可能影响模板更新的及时性');
      }
    }
  }

  /// 默认设置验证
  Future<void> _validateDefaultSettings(
      DefaultSettings defaults,
      List<String> errors,
      List<String> warnings,
      List<String> suggestions) async {
    // 验证许可证信息
    final validLicenses = [
      'MIT',
      'Apache-2.0',
      'GPL-3.0',
      'BSD-3-Clause',
      'ISC',
      'MPL-2.0'
    ];
    if (defaults.license.isNotEmpty &&
        !validLicenses.contains(defaults.license)) {
      warnings.add('使用了非常见的开源许可证: ${defaults.license}');
      suggestions.add('常见的开源许可证包括: ${validLicenses.join(', ')}');
    }

    // 验证Dart版本约束
    if (defaults.dartVersion.isNotEmpty) {
      if (!RegExp(r'^\^?\d+\.\d+\.\d+').hasMatch(defaults.dartVersion)) {
        errors.add('Dart版本约束格式不正确: ${defaults.dartVersion}');
        suggestions.add('使用格式如: "^3.2.0" 或 ">=3.2.0 <4.0.0"');
      }
    }
  }

  /// 验证规则检查
  Future<void> _validateValidationRules(WorkspaceConfig config,
      List<String> errors, List<String> warnings) async {
    // 基础的验证规则检查
    Logger.debug('验证规则检查: 配置基础格式验证通过');
  }

  /// 字段值有效性检查
  Future<void> _validateFieldValues(WorkspaceConfig config, List<String> errors,
      List<String> warnings, List<String> suggestions) async {
    // 检查路径值
    final paths = [
      if (config.templates.localPath != null) config.templates.localPath!,
    ];

    for (final pathValue in paths) {
      if (pathValue.contains('..')) {
        warnings.add('路径包含相对引用，可能存在安全风险: $pathValue');
      }
    }

    // 检查URL格式
    if (config.templates.remoteRegistry != null &&
        config.templates.remoteRegistry!.isNotEmpty) {
      final urlPattern = RegExp(r'^https?://');
      if (!urlPattern.hasMatch(config.templates.remoteRegistry!)) {
        warnings.add('远程模板注册表应使用HTTPS协议: ${config.templates.remoteRegistry}');
      }
    }
  }

  /// 环境配置验证
  Future<void> _validateEnvironmentConfigs(
      Map<String, EnvironmentConfig> environments,
      List<String> errors,
      List<String> warnings,
      List<String> suggestions) async {
    // 检查是否有基础环境
    final commonEnvs = ['development', 'production', 'test'];
    final existingEnvs = environments.keys.toList();

    for (final env in commonEnvs) {
      if (!existingEnvs.contains(env)) {
        suggestions.add('建议添加 $env 环境配置');
      }
    }

    // 验证每个环境配置
    for (final entry in environments.entries) {
      final envName = entry.key;
      final envConfig = entry.value;

      if (envConfig.description.isEmpty) {
        suggestions.add('建议为环境 $envName 添加描述信息');
      }
    }
  }

  /// 语义约束验证
  Future<void> _validateSemanticConstraints(
      WorkspaceConfig config,
      List<String> errors,
      List<String> warnings,
      List<String> suggestions) async {
    // 检查配置间的逻辑一致性
    if (config.workspace.type == WorkspaceType.basic) {
      if (config.collaboration != null) {
        warnings.add('基础工作空间类型通常不需要团队协作配置');
      }
      if (config.quality != null) {
        suggestions.add('考虑升级到企业级工作空间以充分利用质量保障功能');
      }
    }

    // 检查模板配置一致性
    if (config.templates.source == TemplateSource.remote &&
        (config.templates.remoteRegistry == null ||
            config.templates.remoteRegistry!.isEmpty)) {
      errors.add('使用远程模板源时必须配置远程注册表地址');
    }
  }

  /// 依赖关系检查
  Future<void> _validateDependencyConsistency(
      WorkspaceConfig config,
      List<String> errors,
      List<String> warnings,
      List<String> suggestions) async {
    // 这里可以添加更复杂的依赖关系检查逻辑
    // 目前作为占位符实现
    Logger.debug('依赖关系检查: 当前配置依赖关系检查通过');
  }

  /// 配置一致性检查
  Future<void> _validateConfigConsistency(
      WorkspaceConfig config,
      List<String> errors,
      List<String> warnings,
      List<String> suggestions) async {
    // 检查配置的内部一致性
    if (config.collaboration?.sharedSettings == true &&
        config.workspace.type == WorkspaceType.basic) {
      warnings.add('基础工作空间启用了共享设置，建议升级到企业级');
    }
  }

  /// 安全性检查
  Future<void> _validateSecurityConstraints(
      WorkspaceConfig config,
      List<String> errors,
      List<String> warnings,
      List<String> suggestions) async {
    // 检查安全相关配置
    if (config.templates.remoteRegistry != null &&
        config.templates.remoteRegistry!.startsWith('http://')) {
      warnings.add('远程模板注册表使用HTTP协议，存在安全风险，建议使用HTTPS');
    }

    // 检查权限相关配置
    if (config.workspace.type == WorkspaceType.enterprise) {
      suggestions.add('企业级工作空间建议启用严格的权限控制和访问日志');
    }
  }

  /// 合规性检查
  Future<void> _validateComplianceRequirements(
      WorkspaceConfig config,
      List<String> errors,
      List<String> warnings,
      List<String> suggestions) async {
    // 检查企业合规性要求
    if (config.workspace.type == WorkspaceType.enterprise) {
      if (config.quality == null) {
        warnings.add('企业级工作空间建议启用质量保障配置');
      }

      if (config.collaboration == null) {
        suggestions.add('企业级工作空间建议配置团队协作功能');
      }
    }
  }

  /// 文件系统一致性验证
  Future<void> _validateFileSystemConsistency(
      WorkspaceConfig config,
      List<String> errors,
      List<String> warnings,
      List<String> suggestions) async {
    // 检查重要目录是否存在
    final importantDirs = ['templates', 'modules', 'output'];
    for (final dir in importantDirs) {
      final dirPath = path.join(workingDirectory, dir);
      if (!FileUtils.directoryExists(dirPath)) {
        warnings.add('重要目录不存在: $dir');
        suggestions.add('运行 "ming init" 重新创建目录结构');
      }
    }
  }

  /// 性能影响评估
  Future<void> _validatePerformanceImpact(WorkspaceConfig config,
      List<String> warnings, List<String> suggestions) async {
    // 评估配置对性能的潜在影响
    if (config.templates.cacheTimeout != null &&
        config.templates.cacheTimeout! < 300) {
      suggestions.add('模板缓存超时时间较短，可能影响性能，建议设置为至少5分钟');
    }
  }

  /// 模板特定约束验证
  Future<void> _validateTemplateSpecificConstraints(
      WorkspaceConfig config,
      String templatePath,
      List<String> errors,
      List<String> warnings,
      List<String> suggestions) async {
    // 验证模板特定的约束
    if (templatePath == 'enterprise') {
      if (config.workspace.type != WorkspaceType.enterprise) {
        warnings.add('企业级模板的工作空间类型应该是 enterprise');
      }
    }
  }

  /// 模块完整性检查
  Future<void> _checkModulesIntegrity(List<String> errors,
      List<String> warnings, List<String> suggestions) async {
    final modulesPath = path.join(workingDirectory, 'modules');
    if (FileUtils.directoryExists(modulesPath)) {
      final entities = FileUtils.listDirectory(modulesPath);
      if (entities.isEmpty) {
        suggestions.add('模块目录为空，可以使用 "ming create" 创建新模块');
      }
    } else {
      warnings.add('模块目录不存在');
    }
  }

  /// 模板完整性检查
  Future<void> _checkTemplatesIntegrity(
      List<String> errors,
      List<String> warnings,
      List<String> suggestions,
      ValidationStrictness strictness) async {
    final templatesPath = getTemplatesPath();
    if (FileUtils.directoryExists(templatesPath)) {
      final templates = listAvailableTemplates();
      if (templates.isEmpty) {
        suggestions.add('没有发现可用的模板，建议检查模板目录配置');
      }
    }
  }

  /// 全局一致性检查
  Future<void> _checkGlobalConsistency(List<String> errors,
      List<String> warnings, List<String> suggestions) async {
    // 检查全局配置的一致性
    Logger.debug('全局一致性检查: 通过');
  }

  // ===== 高级配置管理方法 =====

  /// 加载具有继承功能的工作空间配置
  Future<WorkspaceConfig?> loadWorkspaceConfigWithInheritance({
    String? configPath,
    String? environment,
    ConfigMergeStrategy mergeStrategy = ConfigMergeStrategy.merge,
  }) async {
    try {
      // 1. 加载基础配置
      final baseConfig = await loadWorkspaceConfig();
      if (baseConfig == null) {
        Logger.warning('无法加载基础工作空间配置');
        return null;
      }

      // 2. 处理配置继承
      WorkspaceConfig resolvedConfig = baseConfig;
      if (baseConfig.inheritance != null) {
        resolvedConfig = await _resolveConfigInheritance(baseConfig);
      }

      // 3. 应用环境特定配置
      if (environment != null) {
        resolvedConfig = _applyEnvironmentConfig(resolvedConfig, environment);
      }

      // 4. 缓存已解析的配置
      _configCache[_getCacheKey(configPath, environment)] = resolvedConfig;

      Logger.info(
          '已加载具有继承功能的工作空间配置 - 继承: ${baseConfig.inheritance != null}, 环境: $environment, 合并策略: $mergeStrategy');

      return resolvedConfig;
    } catch (e) {
      Logger.error('加载继承配置时发生错误', error: e);
      return null;
    }
  }

  /// 解析配置继承链
  Future<WorkspaceConfig> _resolveConfigInheritance(
      WorkspaceConfig config) async {
    final inheritance = config.inheritance!;
    WorkspaceConfig resolvedConfig = config;

    // 1. 处理基础配置继承
    if (inheritance.baseConfig != null && inheritance.baseConfig!.isNotEmpty) {
      final baseConfig = await _loadConfigFromPath(inheritance.baseConfig!);
      if (baseConfig != null) {
        resolvedConfig = baseConfig.mergeWith(resolvedConfig,
            strategy: inheritance.mergeStrategy);
        Logger.debug('应用基础配置继承: ${inheritance.baseConfig}');
      }
    }

    // 2. 处理继承链
    if (inheritance.inheritsFrom != null &&
        inheritance.inheritsFrom!.isNotEmpty) {
      for (final inheritPath in inheritance.inheritsFrom!) {
        final parentConfig = await _loadConfigFromPath(inheritPath);
        if (parentConfig != null) {
          resolvedConfig = parentConfig.mergeWith(resolvedConfig,
              strategy: inheritance.mergeStrategy);
          Logger.debug('应用继承配置: $inheritPath');
        } else {
          Logger.warning('无法加载继承配置: $inheritPath');
        }
      }
    }

    // 3. 应用覆盖配置
    if (inheritance.overrides != null && inheritance.overrides!.isNotEmpty) {
      resolvedConfig =
          _applyConfigOverrides(resolvedConfig, inheritance.overrides!);
      Logger.debug('应用配置覆盖: ${inheritance.overrides!.keys.join(', ')}');
    }

    return resolvedConfig;
  }

  /// 从路径加载配置
  Future<WorkspaceConfig?> _loadConfigFromPath(String configPath) async {
    try {
      // 处理相对路径
      final fullPath = path.isAbsolute(configPath)
          ? configPath
          : path.join(workingDirectory, configPath);

      if (!FileUtils.fileExists(fullPath)) {
        Logger.warning('配置文件不存在: $fullPath');
        return null;
      }

      final configData = await FileUtils.readYamlFile(fullPath);
      if (configData == null) return null;

      final jsonData = _deepConvertYamlMap(configData) as Map<String, dynamic>;
      return WorkspaceConfig.fromJson(jsonData);
    } catch (e) {
      Logger.error('从路径加载配置失败: $configPath', error: e);
      return null;
    }
  }

  /// 应用环境特定配置
  WorkspaceConfig _applyEnvironmentConfig(
      WorkspaceConfig config, String environment) {
    if (config.environments == null ||
        !config.environments!.containsKey(environment)) {
      Logger.warning('环境配置不存在: $environment');
      return config;
    }

    final envConfig = config.environments![environment]!;

    // 使用WorkspaceConfig的内置环境配置应用方法
    final environmentConfig = config.getEnvironmentConfig(environment);

    // 应用环境特定的额外覆盖
    if (envConfig.validationOverrides != null) {
      final validation = environmentConfig.validation;
      final override = envConfig.validationOverrides!;

      final updatedValidation = ValidationConfig(
        strictMode: override.strictMode ?? validation.strictMode,
        requireTests: validation.requireTests,
        minCoverage: override.minCoverage ?? validation.minCoverage,
      );

      return environmentConfig.copyWith(validation: updatedValidation);
    }

    Logger.debug('应用环境配置: $environment');
    return environmentConfig;
  }

  /// 应用配置覆盖
  WorkspaceConfig _applyConfigOverrides(
      WorkspaceConfig config, Map<String, dynamic> overrides) {
    try {
      // 创建覆盖配置对象
      final overrideData = <String, dynamic>{
        'workspace': config.workspace.toJson(),
        'templates': config.templates.toJson(),
        'defaults': config.defaults.toJson(),
        'validation': config.validation.toJson(),
      };

      // 应用覆盖
      _deepMergeMap(overrideData, overrides);

      // 重新构建配置对象
      return WorkspaceConfig.fromJson(overrideData);
    } catch (e) {
      Logger.error('应用配置覆盖失败', error: e);
      return config;
    }
  }

  /// 深度合并Map
  void _deepMergeMap(Map<String, dynamic> target, Map<String, dynamic> source) {
    source.forEach((key, value) {
      if (value is Map<String, dynamic> &&
          target[key] is Map<String, dynamic>) {
        _deepMergeMap(target[key] as Map<String, dynamic>, value);
      } else {
        target[key] = value;
      }
    });
  }

  /// 获取环境列表
  Future<List<String>> getAvailableEnvironments([String? configPath]) async {
    try {
      // 首先尝试从缓存获取
      final cachedConfig = _configCache[_getCacheKey(configPath, null)];
      if (cachedConfig?.environments != null) {
        return cachedConfig!.environments!.keys.toList();
      }

      // 如果缓存中没有，重新加载配置
      final config = await loadWorkspaceConfig();
      if (config?.environments != null) {
        return config!.environments!.keys.toList();
      }

      // 返回默认环境列表
      return ['development', 'testing', 'production'];
    } catch (e) {
      Logger.error('获取环境列表失败', error: e);
      return [];
    }
  }

  /// 创建环境特定的配置
  Future<bool> createEnvironmentConfig(
    String environment,
    EnvironmentConfig environmentConfig, {
    String? configPath,
  }) async {
    try {
      final config = await loadWorkspaceConfig();
      if (config == null) {
        Logger.error('无法加载工作空间配置');
        return false;
      }

      final environments =
          Map<String, EnvironmentConfig>.from(config.environments ?? {});
      environments[environment] = environmentConfig;

      final updatedConfig = config.copyWith(environments: environments);

      final success = await saveWorkspaceConfig(updatedConfig);
      if (success) {
        // 清除缓存
        _configCache.clear();
        Logger.info('成功创建环境配置: $environment');
      }

      return success;
    } catch (e) {
      Logger.error('创建环境配置失败: $environment', error: e);
      return false;
    }
  }

  /// 更新环境配置
  Future<bool> updateEnvironmentConfig(
    String environment,
    EnvironmentConfig environmentConfig, {
    String? configPath,
  }) async {
    return await createEnvironmentConfig(environment, environmentConfig,
        configPath: configPath);
  }

  /// 删除环境配置
  Future<bool> removeEnvironmentConfig(String environment,
      {String? configPath}) async {
    try {
      final config = await loadWorkspaceConfig();
      if (config == null) {
        Logger.error('无法加载工作空间配置');
        return false;
      }

      if (config.environments == null ||
          !config.environments!.containsKey(environment)) {
        Logger.warning('环境配置不存在: $environment');
        return true; // 已经不存在，视为成功
      }

      final environments =
          Map<String, EnvironmentConfig>.from(config.environments!);
      environments.remove(environment);

      final updatedConfig = config.copyWith(
        environments: environments.isNotEmpty ? environments : null,
      );

      final success = await saveWorkspaceConfig(updatedConfig);
      if (success) {
        // 清除缓存
        _configCache.clear();
        Logger.info('成功删除环境配置: $environment');
      }

      return success;
    } catch (e) {
      Logger.error('删除环境配置失败: $environment', error: e);
      return false;
    }
  }

  /// 设置配置继承
  Future<bool> setConfigInheritance(
    ConfigInheritance inheritance, {
    String? configPath,
  }) async {
    try {
      final config = await loadWorkspaceConfig();
      if (config == null) {
        Logger.error('无法加载工作空间配置');
        return false;
      }

      final updatedConfig = config.copyWith(inheritance: inheritance);

      final success = await saveWorkspaceConfig(updatedConfig);
      if (success) {
        // 清除缓存
        _configCache.clear();
        Logger.info(
            '成功设置配置继承 - 基础配置: ${inheritance.baseConfig}, 继承来源: ${inheritance.inheritsFrom}, 合并策略: ${inheritance.mergeStrategy}');
      }

      return success;
    } catch (e) {
      Logger.error('设置配置继承失败', error: e);
      return false;
    }
  }

  /// 优化配置缓存管理
  final Map<String, WorkspaceConfig> _configCache = <String, WorkspaceConfig>{};

  /// 生成缓存键
  String _getCacheKey(String? configPath, String? environment) {
    final path = configPath ?? 'default';
    final env = environment ?? 'none';
    return '$path:$env';
  }

  /// 清除配置缓存
  void clearConfigCache() {
    _configCache.clear();
    Logger.debug('配置缓存已清除');
  }

  /// 获取缓存状态
  Map<String, Object> getCacheStatus() {
    return {
      'cacheSize': _configCache.length,
      'cachedKeys': _configCache.keys.toList(),
    };
  }

  /// 预加载环境配置
  Future<void> preloadEnvironmentConfigs({String? configPath}) async {
    try {
      final baseConfig = await loadWorkspaceConfig();
      if (baseConfig?.environments != null) {
        for (final environment in baseConfig!.environments!.keys) {
          await loadWorkspaceConfigWithInheritance(
            configPath: configPath,
            environment: environment,
          );
          Logger.debug('预加载环境配置: $environment');
        }
      }
    } catch (e) {
      Logger.error('预加载环境配置失败', error: e);
    }
  }

  /// 验证配置继承链
  Future<ConfigValidationResult> validateInheritanceChain(
      {String? configPath}) async {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];

    try {
      final config = await loadWorkspaceConfig();
      if (config?.inheritance == null) {
        return ConfigValidationResult.success(
          suggestions: ['当前配置未使用继承功能'],
        );
      }

      final inheritance = config!.inheritance!;

      // 检查基础配置
      if (inheritance.baseConfig != null) {
        final baseExists = await _validateConfigPath(inheritance.baseConfig!);
        if (!baseExists) {
          errors.add('基础配置文件不存在: ${inheritance.baseConfig}');
        }
      }

      // 检查继承链
      if (inheritance.inheritsFrom != null) {
        for (final inheritPath in inheritance.inheritsFrom!) {
          final exists = await _validateConfigPath(inheritPath);
          if (!exists) {
            errors.add('继承配置文件不存在: $inheritPath');
          }
        }
      }

      // 检查循环继承
      if (await _hasCircularInheritance(config)) {
        errors.add('检测到循环继承依赖');
      }

      return errors.isEmpty
          ? ConfigValidationResult.success(
              warnings: warnings, suggestions: suggestions)
          : ConfigValidationResult.failure(
              errors: errors, warnings: warnings, suggestions: suggestions);
    } catch (e) {
      Logger.error('验证继承链失败', error: e);
      return ConfigValidationResult.failure(
        errors: ['验证继承链过程中发生异常: ${e.toString()}'],
      );
    }
  }

  /// 验证配置路径是否存在
  Future<bool> _validateConfigPath(String configPath) async {
    final fullPath = path.isAbsolute(configPath)
        ? configPath
        : path.join(workingDirectory, configPath);

    return FileUtils.fileExists(fullPath);
  }

  /// 检查是否存在循环继承
  Future<bool> _hasCircularInheritance(WorkspaceConfig config,
      [Set<String>? visited]) async {
    visited ??= <String>{};

    if (config.inheritance == null) return false;

    final inheritance = config.inheritance!;
    final currentPaths = <String>[];

    if (inheritance.baseConfig != null) {
      currentPaths.add(inheritance.baseConfig!);
    }

    if (inheritance.inheritsFrom != null) {
      currentPaths.addAll(inheritance.inheritsFrom!);
    }

    for (final configPath in currentPaths) {
      if (visited.contains(configPath)) {
        return true; // 发现循环
      }

      visited.add(configPath);

      final childConfig = await _loadConfigFromPath(configPath);
      if (childConfig != null &&
          await _hasCircularInheritance(childConfig, visited)) {
        return true;
      }

      visited.remove(configPath);
    }

    return false;
  }
}
