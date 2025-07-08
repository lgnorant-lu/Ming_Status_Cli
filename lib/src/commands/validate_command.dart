/*
---------------------------------------------------------------
File name:          validate_command.dart
Author:             Ignorant-lu
Date created:       2025/07/03
Last modified:      2025/07/08
Dart Version:       3.32.4
Description:        验证命令 - 模块验证功能实现
---------------------------------------------------------------
Change History:
    2025/07/03: Initial creation - 验证命令实现;
    2025/07/08: Feature enhancement - 添加监控模式和自动修复功能;
    2025/07/10: Feature enhancement - 添加CI/CD集成和报告生成功能;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:io';

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/auto_fix_manager.dart';
import 'package:ming_status_cli/src/core/ci_cd_integration.dart';
import 'package:ming_status_cli/src/core/validation_report_generator.dart';
import 'package:ming_status_cli/src/core/validator_service.dart';
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:ming_status_cli/src/validators/dependency_validator.dart';
import 'package:ming_status_cli/src/validators/platform_compliance_validator.dart';
import 'package:ming_status_cli/src/validators/quality_validator.dart';
import 'package:ming_status_cli/src/validators/structure_validator.dart';
import 'package:path/path.dart' as path;

/// 验证命令
/// 提供完整的模块验证功能
class ValidateCommand extends BaseCommand {
  /// 创建验证命令实例
  ValidateCommand() {
    _setupValidateOptions();
  }

  /// 验证服务（延迟初始化）
  ValidatorService? _validatorService;

  @override
  String get name => 'validate';

  @override
  String get description => '验证模块的结构、质量、依赖关系和平台规范';

  @override
  List<String> get aliases => ['v', 'val', 'check'];

  /// 获取验证服务（延迟初始化）
  ValidatorService get validatorService {
    if (_validatorService == null) {
      final config = _createValidationConfig();
      _validatorService = ValidatorService(config: config);
      _registerDefaultValidators();
    }
    return _validatorService!;
  }

  /// 设置验证命令选项
  void _setupValidateOptions() {
    argParser
      ..addOption(
        'level',
        abbr: 'l',
        help: '验证级别',
        allowed: ['basic', 'standard', 'strict', 'enterprise'],
        defaultsTo: 'standard',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '输出格式',
        allowed: ['console', 'json', 'junit', 'compact'],
        defaultsTo: 'console',
      )
      ..addMultiOption(
        'validator',
        help: '启用的验证器类型',
        allowed: ['structure', 'quality', 'dependency', 'platform'],
        defaultsTo: [],
      )
      ..addFlag(
        'strict',
        abbr: 's',
        help: '严格模式（警告视为错误）',
      )
      ..addFlag(
        'fix',
        abbr: 'f',
        help: '自动修复可修复的问题',
      )
      ..addFlag(
        'watch',
        abbr: 'w',
        help: '监控模式（文件变化时自动验证）',
      )
      ..addFlag(
        'cache',
        help: '启用验证缓存',
        defaultsTo: true,
      )
      ..addFlag(
        'parallel',
        help: '并行执行验证器',
        defaultsTo: true,
      )
      ..addOption(
        'timeout',
        help: '验证超时时间（秒）',
        defaultsTo: '300',
      )
      ..addFlag(
        'stats',
        help: '显示详细统计信息',
      )
      ..addFlag(
        'health-check',
        help: '执行验证器健康检查',
      )
      ..addOption(
        'output-file',
        help: '输出文件路径（用于JUnit XML或JSON报告）',
      )
      ..addFlag(
        'continue-on-error',
        help: '遇到错误时继续执行其他验证器',
      )
      ..addMultiOption(
        'exclude',
        help: '排除的文件或目录模式',
        defaultsTo: [],
      )
      ..addFlag(
        'ci-mode',
        help: '启用CI/CD模式（非交互式，优化的输出格式）',
      )
      ..addOption(
        'junit-output',
        help: 'JUnit XML输出文件路径',
      )
      ..addMultiOption(
        'report-format',
        help: '生成报告格式 (html, json, junit, markdown, csv)',
        allowed: ['html', 'json', 'junit', 'markdown', 'csv'],
        defaultsTo: [],
      )
      ..addOption(
        'report-output',
        help: '报告输出目录',
        defaultsTo: 'reports',
      )
      ..addFlag(
        'generate-ci-config',
        help: '生成CI/CD配置文件',
      )
      ..addOption(
        'ci-platform',
        help: 'CI/CD平台类型',
        allowed: ['github', 'gitlab', 'jenkins', 'azure'],
      );

    // 初始化验证服务，注册实际验证器
    _validatorService = ValidatorService()
      ..registerValidator(StructureValidator())
      ..registerValidator(QualityValidator())
      ..registerValidator(DependencyValidator())
      ..registerValidator(PlatformComplianceValidator());
  }

  /// 创建验证配置
  ValidationConfig _createValidationConfig() {
    final levelStr = argResults!['level'] as String;
    final level = ValidationLevel.values.firstWhere(
      (l) => l.name == levelStr,
      orElse: () => ValidationLevel.standard,
    );

    final outputStr = argResults!['output'] as String;
    final outputFormat = OutputFormat.values.firstWhere(
      (f) => f.name == outputStr,
      orElse: () => OutputFormat.console,
    );

    final enabledValidators = (argResults!['validator'] as List<String>)
        .map(
          (v) => ValidationType.values.firstWhere(
            (t) => t.name == v,
            orElse: () => ValidationType.general,
          ),
        )
        .toList();

    final timeoutStr = argResults!['timeout'] as String;
    final timeout = int.tryParse(timeoutStr) ?? 300;

    return ValidationConfig(
      level: level,
      enabledValidators: enabledValidators,
      outputFormat: outputFormat,
      enableCache: argResults!['cache'] as bool,
      parallelExecution: argResults!['parallel'] as bool,
      timeoutSeconds: timeout,
    );
  }

  /// 注册默认验证器
  void _registerDefaultValidators() {
    // 验证器已在构造函数中注册，这里不需要重复注册
  }

  @override
  Future<int> execute() async {
    try {
      // CI/CD配置生成
      if (argResults!['generate-ci-config'] as bool) {
        return await _generateCiCdConfig();
      }

      // 健康检查选项
      if (argResults!['health-check'] as bool) {
        return await _performHealthCheck();
      }

      // 获取要验证的路径
      final targetPath = _getTargetPath();

      // 验证路径
      if (!await _validateTargetPath(targetPath)) {
        return 1;
      }

      // 监控模式
      if (argResults!['watch'] as bool) {
        return await _runWatchMode(targetPath);
      }

      // 执行验证
      return await _runValidation(targetPath);
    } catch (e) {
      Logger.error('验证过程发生异常: $e');
      return 1;
    }
  }

  /// 获取目标路径
  String _getTargetPath() {
    final rest = argResults!.rest;
    if (rest.isNotEmpty) {
      return rest.first;
    }
    return workingDirectory;
  }

  /// 验证目标路径
  Future<bool> _validateTargetPath(String path) async {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      Logger.error('路径不存在: $path');
      return false;
    }

    // 检查是否为有效的模块路径
    if (!await validateModulePath(path, showDetails: true)) {
      return false;
    }

    return true;
  }

  /// 执行验证
  Future<int> _runValidation(String targetPath) async {
    final startTime = DateTime.now();

    Logger.info('🔍 开始验证: $targetPath');

    // 创建验证上下文
    final context = ValidationContext(
      projectPath: targetPath,
      strictMode: argResults!['strict'] as bool,
      outputFormat: OutputFormat.values.firstWhere(
        (f) => f.name == argResults!['output'],
        orElse: () => OutputFormat.console,
      ),
      enabledValidators: (argResults!['validator'] as List<String>)
          .map(
            (v) => ValidationType.values.firstWhere(
              (t) => t.name == v,
              orElse: () => ValidationType.general,
            ),
          )
          .toList(),
    );

    // 执行验证
    final result = await validatorService.validateModule(
      targetPath,
      context: context,
      useCache: argResults!['cache'] as bool,
    );

    // 自动修复
    if (argResults!['fix'] as bool) {
      await _performAutoFix(result, targetPath);
    }

    // 输出结果
    await _outputResult(result, context.outputFormat);

    // 显示统计信息
    if (argResults!['stats'] as bool) {
      _showStatistics(result, startTime);
    }

    // 生成报告
    await _generateReports(result, targetPath);

    // 返回退出码
    return result.isValid ? 0 : 1;
  }

  /// 执行自动修复
  Future<void> _performAutoFix(
    ValidationResult result,
    String targetPath,
  ) async {
    // 使用AutoFixManager执行自动修复
    final autoFixManager = AutoFixManager(
      workingDirectory: targetPath,
      continueOnError: argResults!['continue-on-error'] as bool,
      excludePatterns: argResults!['exclude'] as List<String>,
    );

    final statistics = await autoFixManager.performAutoFix(result, targetPath);

    // 详细统计信息已在AutoFixManager中记录，这里只做简要总结
    if (statistics.totalIssues > 0) {
      Logger.info(
        '📈 修复统计: ${statistics.successCount}/${statistics.totalIssues} 成功',
      );
    }
  }

  /// 输出验证结果
  Future<void> _outputResult(
    ValidationResult result,
    OutputFormat format,
  ) async {
    switch (format) {
      case OutputFormat.console:
        _outputConsoleResult(result);
      case OutputFormat.json:
        await _outputJsonResult(result);
      case OutputFormat.junit:
        await _outputJUnitResult(result);
      case OutputFormat.compact:
        _outputCompactResult(result);
    }
  }

  /// 控制台输出
  void _outputConsoleResult(ValidationResult result) {
    Logger.info(
      result.formatOutput(
        includeSuccesses: verbose,
      ),
    );
  }

  /// JSON输出
  Future<void> _outputJsonResult(ValidationResult result) async {
    final jsonOutput = result.formatOutput(format: OutputFormat.json);

    // 如果指定了输出文件，写入文件
    final outputFile = argResults!['output-file'] as String?;
    if (outputFile != null) {
      await _writeOutputToFile(outputFile, jsonOutput, 'JSON');
    } else {
      Logger.info(jsonOutput);
    }
  }

  /// JUnit XML输出
  Future<void> _outputJUnitResult(ValidationResult result) async {
    final junitOutput = result.formatOutput(format: OutputFormat.junit);

    // 如果指定了输出文件，写入文件
    final outputFile = argResults!['output-file'] as String?;
    if (outputFile != null) {
      await _writeOutputToFile(outputFile, junitOutput, 'JUnit XML');
    } else {
      Logger.info(junitOutput);
    }
  }

  /// 写入输出到文件
  Future<void> _writeOutputToFile(
    String filePath,
    String content,
    String formatName,
  ) async {
    try {
      final file = File(filePath);

      // 确保目录存在
      final directory = file.parent;
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }

      // 写入文件
      await file.writeAsString(content);
      Logger.success('$formatName报告已保存到: $filePath');
    } catch (e) {
      Logger.error('保存报告文件失败: $e');
    }
  }

  /// 紧凑输出
  void _outputCompactResult(ValidationResult result) {
    Logger.info(result.formatOutput(format: OutputFormat.compact));
  }

  /// 显示统计信息
  void _showStatistics(ValidationResult result, DateTime startTime) {
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    final stats = validatorService.lastValidationStats;

    Logger.info('\n📊 验证统计信息:');
    Logger.info('  总耗时: ${duration.inMilliseconds}ms');
    Logger.info(
      '  验证器: ${stats?.executedValidators ?? 0}/${stats?.totalValidators ?? 0} 已执行',
    );
    Logger.info('  跳过验证器: ${stats?.skippedValidators ?? 0}');
    Logger.info('  失败验证器: ${stats?.failedValidators ?? 0}');

    if (stats != null && stats.cacheHits + stats.cacheMisses > 0) {
      Logger.info('  缓存命中率: ${(stats.cacheHitRate * 100).toStringAsFixed(1)}%');
    }

    final cacheStats = validatorService.getCacheStats();
    Logger.info('  缓存条目: ${cacheStats['totalEntries']}');
  }

  /// 执行健康检查
  Future<int> _performHealthCheck() async {
    Logger.info('🏥 执行验证器健康检查...');

    final healthStatus = await validatorService.checkValidatorsHealth();
    var allHealthy = true;

    for (final entry in healthStatus.entries) {
      final status = entry.value ? '✅ 健康' : '❌ 异常';
      Logger.info('  ${entry.key}: $status');
      if (!entry.value) allHealthy = false;
    }

    if (allHealthy) {
      Logger.success('所有验证器运行正常');
      return 0;
    } else {
      Logger.warning('部分验证器存在问题');
      return 1;
    }
  }

  /// 监控模式
  Future<int> _runWatchMode(String targetPath) async {
    Logger.info('👀 进入监控模式，监视文件变化...');
    Logger.info('按 Ctrl+C 退出监控');

    // 初始验证
    Logger.info('🔍 执行初始验证...');
    await _runValidation(targetPath);

    // 设置文件监控
    final watcher = Directory(targetPath).watch(recursive: true);
    final debouncer = _Debouncer(delay: const Duration(seconds: 2));

    Logger.info('👀 监视文件变化中...');
    Logger.info('📁 监控目录: $targetPath');
    Logger.info('⏱️  防抖延迟: 2秒');

    var changeCount = 0;
    var lastValidationTime = DateTime.now();

    try {
      await for (final event in watcher) {
        if (_shouldProcessFileEvent(event)) {
          changeCount++;
          final now = DateTime.now();
          final timeSinceLastValidation = now.difference(lastValidationTime);

          debouncer.run(() async {
            Logger.info('📁 检测到文件变化 #$changeCount: ${event.path}');
            Logger.info(
              '🔄 重新执行验证... (距上次验证: ${timeSinceLastValidation.inSeconds}秒)',
            );

            final validationStart = DateTime.now();
            await _runValidation(targetPath);
            final validationDuration =
                DateTime.now().difference(validationStart);

            lastValidationTime = DateTime.now();
            Logger.info('✅ 验证完成，耗时: ${validationDuration.inMilliseconds}ms');
          });
        }
      }
    } catch (e) {
      Logger.error('监控过程发生错误: $e');
      return 1;
    }

    return 0;
  }

  /// 判断是否应该处理文件事件
  bool _shouldProcessFileEvent(FileSystemEvent event) {
    final fileName = path.basename(event.path);
    final fileExtension = path.extension(event.path);
    final filePath = event.path;

    // 忽略隐藏文件和临时文件
    if (fileName.startsWith('.') ||
        fileName.startsWith('#') ||
        fileName.endsWith('~')) {
      return false;
    }

    // 忽略备份文件和交换文件
    if (fileName.endsWith('.bak') ||
        fileName.endsWith('.swp') ||
        fileName.endsWith('.tmp')) {
      return false;
    }

    // 只监控相关文件类型
    const monitoredExtensions = [
      '.dart',
      '.yaml',
      '.yml',
      '.json',
      '.md',
      '.lock',
    ];
    if (!monitoredExtensions.contains(fileExtension)) {
      return false;
    }

    // 忽略构建产物和缓存目录
    const ignoredDirectories = [
      'build',
      '.dart_tool',
      '.pub-cache',
      'node_modules',
      '.git',
      '.vscode',
      '.idea',
      'coverage',
      '.nyc_output',
    ];
    for (final ignoredDir in ignoredDirectories) {
      if (filePath.contains('${path.separator}$ignoredDir${path.separator}') ||
          filePath.endsWith('${path.separator}$ignoredDir')) {
        return false;
      }
    }

    // 只处理修改和创建事件，忽略删除事件
    if (event.type == FileSystemEvent.delete) {
      return false;
    }

    // 检查排除模式
    final excludePatterns = argResults!['exclude'] as List<String>;
    for (final pattern in excludePatterns) {
      if (filePath.contains(pattern)) {
        return false;
      }
    }

    return true;
  }

  /// 生成CI/CD配置文件
  Future<int> _generateCiCdConfig() async {
    const ciCdIntegration = CiCdIntegration();
    final platformName = argResults!['ci-platform'] as String?;

    if (platformName == null) {
      Logger.error('请指定CI/CD平台类型 (--ci-platform)');
      Logger.info('支持的平台: github, gitlab, jenkins, azure');
      return 1;
    }

    CiCdEnvironment environment;
    switch (platformName) {
      case 'github':
        environment = CiCdEnvironment.githubActions;
      case 'gitlab':
        environment = CiCdEnvironment.gitlabCi;
      case 'jenkins':
        environment = CiCdEnvironment.jenkins;
      case 'azure':
        environment = CiCdEnvironment.azureDevOps;
      default:
        Logger.error('不支持的CI/CD平台: $platformName');
        return 1;
    }

    try {
      final projectPath = Directory.current.path;
      await ciCdIntegration.generateCiCdConfig(environment, projectPath);
      Logger.info('🎉 CI/CD配置文件生成完成！');
      return 0;
    } catch (e) {
      Logger.error('生成CI/CD配置文件失败: $e');
      return 1;
    }
  }

  /// 生成验证报告
  Future<void> _generateReports(
    ValidationResult result,
    String targetPath,
  ) async {
    final reportFormats = argResults!['report-format'] as List<String>;
    final junitOutput = argResults!['junit-output'] as String?;
    final outputFile = argResults!['output-file'] as String?;
    final reportOutput = argResults!['report-output'] as String;

    if (reportFormats.isEmpty && junitOutput == null && outputFile == null) {
      return; // 没有指定报告格式
    }

    const reportGenerator = ValidationReportGenerator();
    const ciCdIntegration = CiCdIntegration();
    final ciCdInfo = ciCdIntegration.getCiCdInfo();

    // 准备报告元数据
    final metadata = {
      'project_path': targetPath,
      'command_line':
          '${Platform.executable} ${Platform.executableArguments.join(' ')}',
      'ci_cd_environment': ciCdInfo['environment'],
      'is_ci': ciCdInfo['is_ci'],
      ...ciCdInfo,
    };

    try {
      // 生成指定格式的报告
      if (reportFormats.isNotEmpty) {
        final formats = reportFormats.map((format) {
          switch (format) {
            case 'html':
              return ReportFormat.html;
            case 'json':
              return ReportFormat.json;
            case 'junit':
              return ReportFormat.junit;
            case 'markdown':
              return ReportFormat.markdown;
            case 'csv':
              return ReportFormat.csv;
            default:
              throw ArgumentError('不支持的报告格式: $format');
          }
        }).toSet();

        await reportGenerator.generateReport(
          result: result,
          outputPath: reportOutput,
          formats: formats,
          metadata: metadata,
        );
      }

      // 生成JUnit XML报告
      if (junitOutput != null) {
        await reportGenerator.generateReport(
          result: result,
          outputPath: path.dirname(junitOutput),
          formats: {ReportFormat.junit},
          metadata: metadata,
        );

        // 移动到指定位置
        final generatedFile =
            path.join(path.dirname(junitOutput), 'test-results.xml');
        if (await File(generatedFile).exists()) {
          await File(generatedFile).rename(junitOutput);
          Logger.info('✅ JUnit XML报告已生成: $junitOutput');
        }
      }

      // 生成JSON输出文件
      if (outputFile != null && outputFile.endsWith('.json')) {
        await reportGenerator.generateReport(
          result: result,
          outputPath: path.dirname(outputFile),
          formats: {ReportFormat.json},
          metadata: metadata,
        );

        // 移动到指定位置
        final generatedFile =
            path.join(path.dirname(outputFile), 'validation-report.json');
        if (await File(generatedFile).exists()) {
          await File(generatedFile).rename(outputFile);
          Logger.info('✅ JSON报告已生成: $outputFile');
        }
      }
    } catch (e) {
      Logger.error('生成报告失败: $e');
    }
  }
}

/// 防抖器辅助类
/// 用于监控模式中延迟执行验证，避免频繁触发
class _Debouncer {
  /// 创建防抖器实例
  _Debouncer({required this.delay});

  /// 延迟时间
  final Duration delay;

  /// 当前定时器
  Timer? _timer;

  /// 执行函数（防抖）
  void run(void Function() action) {
    // 取消之前的定时器
    _timer?.cancel();

    // 创建新的定时器
    _timer = Timer(delay, action);
  }

  /// 销毁防抖器
  void dispose() {
    _timer?.cancel();
  }
}
