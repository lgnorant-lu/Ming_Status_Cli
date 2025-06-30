/*
---------------------------------------------------------------
File name:          create_command.dart
Author:             lgnorant-lu
Date created:       2025/06/30
Last modified:      2025/06/30
Dart Version:       3.2+
Description:        Create命令实现 (Create command implementation)
---------------------------------------------------------------
Change History:
    2025/06/30: Initial creation - Task 30.1-30.4 批量实现;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:args/args.dart';
import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/config_manager.dart';
import 'package:ming_status_cli/src/core/template_engine.dart';
import 'package:ming_status_cli/src/models/template_variable.dart';
import 'package:ming_status_cli/src/models/user_config.dart';
import 'package:ming_status_cli/src/utils/color_output.dart';
import 'package:ming_status_cli/src/utils/error_handler.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:path/path.dart' as path;

/// Create命令 - 基于模板创建新的模块或项目
/// 
/// 支持的功能：
/// - 模板选择和生成
/// - 命令行参数解析
/// - 用户配置集成
/// - 交互式变量收集
/// - 输出目录管理
/// 
/// Task 30.1-30.4 集成实现
class CreateCommand extends BaseCommand {
  CreateCommand({
    ConfigManager? configManager,
    TemplateEngine? templateEngine,
  }) : _configManager = configManager ?? ConfigManager(),
       _templateEngine = templateEngine ?? TemplateEngine();

  final ConfigManager _configManager;
  final TemplateEngine _templateEngine;

  @override
  String get name => 'create';

  @override
  String get description => '基于模板创建新的模块或项目';

  @override
  String get invocation => 'ming create [options] <project_name>';

  /// 实现基类要求的execute方法
  @override
  Future<int> execute() async {
    try {
      cli_logger.Logger.title('🚀 Ming Status CLI - Create命令');
      
      // 获取项目名称
      final projectName = _getProjectName();
      if (projectName == null) {
        cli_logger.Logger.error('错误: 必须提供项目名称');
        cli_logger.Logger.info('示例: ming create my_project');
        return 1;
      }

      // 获取命令行参数
      final templateName = argResults!['template'] as String;
      final outputPath = argResults!['output'] as String?;
      final force = argResults!['force'] as bool;
      final interactive = argResults!['interactive'] as bool;
      final dryRun = argResults!['dry-run'] as bool;
      final verbose = argResults!['verbose'] as bool;

      // 设置详细输出
      if (verbose) {
        cli_logger.Logger.info('🔧 详细模式已启用');
      }

      // 准备变量
      Map<String, dynamic> variables;
      
      if (interactive) {
        // Task 32.2: 使用增强的交互式变量收集
        variables = await _collectVariablesInteractively(templateName);
      } else {
        // 使用基础变量准备
        variables = await _prepareVariables(projectName);
      }

      // 确定输出目录
      final targetDirectory = _determineOutputDirectory(
        projectName: projectName,
        outputPath: outputPath,
      );

      cli_logger.Logger.info('📁 输出目录: $targetDirectory');

      // 干运行模式
      if (dryRun) {
        return await _performDryRun(templateName, variables, targetDirectory);
      }

      // Task 32.1: 使用增强的进度显示模板生成
      final result = await _generateTemplateWithProgress(
        templateName: templateName,
        targetDirectory: targetDirectory,
        variables: variables,
        force: force,
      );

      if (result.success) {
        _showPostCreationInstructions(projectName, targetDirectory);
        return 0;
      } else {
        // 错误已在_generateTemplateWithProgress中处理
        return 1;
      }

    } catch (e) {
      cli_logger.Logger.error('Create命令执行失败: $e');
      return 1;
    }
  }

  /// Task 30.2: 命令行参数解析配置
  ArgParser? _argParser;
  
  @override
  ArgParser get argParser {
    if (_argParser != null) return _argParser!;
    
    final parser = super.argParser;
    
    // 模板相关参数
    parser.addOption(
      'template',
      abbr: 't',
      help: '要使用的模板名称',
      defaultsTo: 'basic',
    );
    
    // 输出目录参数
    parser.addOption(
      'output',
      abbr: 'o',
      help: '输出目录路径',
      valueHelp: 'path',
    );
    
    // 强制覆盖参数
    parser.addFlag(
      'force',
      abbr: 'f',
      help: '强制覆盖已存在的文件',
      negatable: false,
    );
    
    // 交互模式参数
    parser.addFlag(
      'interactive',
      abbr: 'i',
      help: '启用交互式模式，逐步收集变量值',
      defaultsTo: true,
    );
    
    // 变量传递参数
    parser.addMultiOption(
      'var',
      help: '设置模板变量 (格式: key=value)',
      valueHelp: 'key=value',
    );
    
    // 作者信息参数
    parser.addOption(
      'author',
      help: '设置作者名称（覆盖配置文件设置）',
      valueHelp: 'name',
    );
    
    // 描述信息参数
    parser.addOption(
      'description',
      abbr: 'd',
      help: '项目描述信息',
      valueHelp: 'description',
    );
    
    // 干运行模式
    parser.addFlag(
      'dry-run',
      help: '干运行模式，只显示会生成的文件而不实际创建',
      negatable: false,
    );
    
    // 详细输出模式
    parser.addFlag(
      'verbose',
      abbr: 'v',
      help: '启用详细输出模式',
      negatable: false,
    );

    _argParser = parser;
    return _argParser!;
  }

  /// Task 30.3 & 30.4: 主要执行逻辑
  @override
  Future<int> run() async {
    try {
      // 参数验证
      final results = argResults!;
      final args = results.rest;
      
      if (args.isEmpty) {
        cli_logger.Logger.error('错误: 必须指定项目名称');
        cli_logger.Logger.info('用法: ming create [options] <project_name>');
        return 1;
      }

      final projectName = args.first;
      final templateName = results['template'] as String;
      final outputPath = results['output'] as String?;
      final force = results['force'] as bool;
      final interactive = results['interactive'] as bool;
      final dryRun = results['dry-run'] as bool;
      final verbose = results['verbose'] as bool;

      // 设置日志级别
      if (verbose) {
        cli_logger.Logger.minLevel = cli_logger.LogLevel.debug;
      }

      cli_logger.Logger.info('🚀 开始创建项目: $projectName');
      cli_logger.Logger.debug('使用模板: $templateName');

      // Task 30.4: 集成ConfigManager获取用户偏好
      final userConfig = await _loadUserConfiguration();
      cli_logger.Logger.debug('已加载用户配置');

      // Task 30.3: 验证模板是否存在
      final availableTemplates = await _templateEngine.getAvailableTemplates();
      if (!availableTemplates.contains(templateName)) {
        cli_logger.Logger.error('错误: 模板 "$templateName" 不存在');
        cli_logger.Logger.info('可用模板: ${availableTemplates.join(', ')}');
        return 1;
      }

      // 准备模板变量
      final variables = await _prepareTemplateVariables(
        templateName: templateName,
        projectName: projectName,
        results: results,
        userConfig: userConfig,
        interactive: interactive,
      );

      // 确定输出目录
      final targetDirectory = _determineOutputDirectory(
        projectName: projectName,
        outputPath: outputPath,
      );

      // 检查目录冲突
      if (!force && Directory(targetDirectory).existsSync()) {
        cli_logger.Logger.error('错误: 目录 "$targetDirectory" 已存在');
        cli_logger.Logger.info('使用 --force 参数强制覆盖');
        return 1;
      }

      // 干运行模式
      if (dryRun) {
        return await _performDryRun(templateName, variables, targetDirectory);
      }

      // Task 30.3: 执行模板生成
      final result = await _executeTemplateGeneration(
        templateName: templateName,
        variables: variables,
        targetDirectory: targetDirectory,
        force: force,
      );

      if (result.success) {
        cli_logger.Logger.success('✅ 项目创建成功!');
        cli_logger.Logger.info('📁 项目位置: $targetDirectory');
        
        // 显示后续步骤提示
        _showPostCreationInstructions(projectName, targetDirectory);
        
        return 0;
      } else {
        cli_logger.Logger.error('❌ 项目创建失败: ${result.error}');
        return 1;
      }

    } catch (e) {
      ErrorHandler.handleException(e, context: 'Create命令执行');
      return 1;
    }
  }

  /// Task 30.4: 加载用户配置
  Future<UserConfig> _loadUserConfiguration() async {
    try {
      // 检查工作空间是否初始化
      if (!_configManager.isWorkspaceInitialized()) {
        cli_logger.Logger.warning('工作空间未初始化，使用默认用户配置');
        return UserConfig.defaultConfig();
      }
      
      // 从工作空间配置获取用户信息（简化实现）
      final workspaceConfig = await _configManager.loadWorkspaceConfig();
      if (workspaceConfig != null) {
        return UserConfig(
          user: UserInfo(name: workspaceConfig.defaults.author),
          preferences: const UserPreferences(),
          defaults: UserDefaults(
            author: workspaceConfig.defaults.author,
            license: workspaceConfig.defaults.license,
            dartVersion: workspaceConfig.defaults.dartVersion,
          ),
        );
      }
      
      return UserConfig.defaultConfig();
    } catch (e) {
      cli_logger.Logger.warning('警告: 无法加载用户配置，使用默认值: $e');
      return UserConfig.defaultConfig();
    }
  }

  /// Task 30.2 & 30.4: 准备模板变量
  Future<Map<String, dynamic>> _prepareTemplateVariables({
    required String templateName,
    required String projectName,
    required ArgResults results,
    required UserConfig userConfig,
    required bool interactive,
  }) async {
    final variables = <String, dynamic>{};

    // 基础变量
    variables['module_name'] = projectName;
    variables['generated_date'] = DateTime.now().toIso8601String().substring(0, 10);
    
    // Task 30.4: 从用户配置获取默认值
    variables['author'] = results['author'] ?? userConfig.defaults.author;
    variables['description'] = results['description'] ?? 
        'A new Flutter project created with Ming Status CLI';

    // Task 30.2: 处理命令行变量参数
    final varOptions = results['var'] as List<String>;
    for (final varOption in varOptions) {
      final parts = varOption.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        
        // 尝试解析为适当的类型
        if (value.toLowerCase() == 'true') {
          variables[key] = true;
        } else if (value.toLowerCase() == 'false') {
          variables[key] = false;
        } else if (int.tryParse(value) != null) {
          variables[key] = int.parse(value);
        } else if (double.tryParse(value) != null) {
          variables[key] = double.parse(value);
        } else {
          variables[key] = value;
        }
      }
    }

    // Task 30.3: 简化的交互式变量收集
    if (interactive) {
      try {
        // 基础交互式收集（简化版本）
        cli_logger.Logger.info('📝 收集模板变量信息:');
        
        // 收集一些基础的可选变量
        final commonVars = {
          'use_provider': '是否使用Provider状态管理? (y/n)',
          'use_http': '是否包含HTTP网络功能? (y/n)',
          'has_assets': '是否包含资源文件? (y/n)',
        };
        
        for (final entry in commonVars.entries) {
          if (!variables.containsKey(entry.key)) {
            stdout.write('${entry.value}: ');
            final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
            variables[entry.key] = input == 'y' || input == 'yes' || input == 'true';
          }
        }
      } catch (e) {
        cli_logger.Logger.warning('警告: 交互式变量收集失败: $e');
      }
    }

    cli_logger.Logger.debug('准备的变量: ${variables.keys.join(', ')}');
    return variables;
  }

  /// 交互式变量收集（简化版本）
  Future<dynamic> _promptForVariable(TemplateVariable variable) async {
    final prompt = variable.prompt ?? '请输入 ${variable.name}';
    
    stdout.write(prompt);
    if (variable.defaultValue != null) {
      stdout.write(' (默认: ${variable.defaultValue})');
    }
    stdout.write(': ');
    
    final input = stdin.readLineSync()?.trim() ?? '';
    
    if (input.isEmpty && variable.defaultValue != null) {
      return variable.defaultValue;
    }
    
    if (input.isEmpty && !variable.optional) {
      cli_logger.Logger.error('错误: ${variable.name} 是必需的');
      return _promptForVariable(variable);
    }
    
    // 根据变量类型转换值
    switch (variable.type) {
      case TemplateVariableType.boolean:
        return input.toLowerCase() == 'true' || input.toLowerCase() == 'yes' || input == '1';
      case TemplateVariableType.number:
        return double.tryParse(input) ?? int.tryParse(input);
      case TemplateVariableType.list:
        return input.split(',').map((e) => e.trim()).toList();
      default:
        return input;
    }
  }

  /// 确定输出目录
  String _determineOutputDirectory({
    required String projectName,
    String? outputPath,
  }) {
    if (outputPath != null) {
      return path.isAbsolute(outputPath) 
          ? outputPath 
          : path.join(Directory.current.path, outputPath);
    }
    
    return path.join(Directory.current.path, projectName);
  }

  /// 干运行模式实现
  Future<int> _performDryRun(
    String templateName,
    Map<String, dynamic> variables,
    String targetDirectory,
  ) async {
    try {
      cli_logger.Logger.info('🔍 干运行模式 - 预览将要生成的文件:');
      
      cli_logger.Logger.info('📁 目标目录: $targetDirectory');
      cli_logger.Logger.info('📝 模板变量:');
      
      variables.forEach((key, value) {
        cli_logger.Logger.info('   $key: $value');
      });
      
      cli_logger.Logger.info('');
      cli_logger.Logger.info('💡 使用 --no-dry-run 执行实际生成');
      
      return 0;
    } catch (e) {
      cli_logger.Logger.error('干运行失败: $e');
      return 1;
    }
  }

  /// Task 30.3: 执行模板生成
  Future<TemplateGenerationResult> _executeTemplateGeneration({
    required String templateName,
    required Map<String, dynamic> variables,
    required String targetDirectory,
    required bool force,
  }) async {
    try {
      cli_logger.Logger.info('📦 正在生成项目...');
      
      // 创建目标目录
      final targetDir = Directory(targetDirectory);
      if (force && targetDir.existsSync()) {
        cli_logger.Logger.debug('清理现有目录: $targetDirectory');
        targetDir.deleteSync(recursive: true);
      }
      
      // 使用TemplateEngine生成项目
      final success = await _templateEngine.generateModuleWithParameters(
        templateName: templateName,
        outputPath: targetDirectory,
        variables: variables,
        overwrite: force,
      );
      
      if (success) {
        // 尝试获取生成的文件列表
        final generatedFiles = <String>[];
        try {
          final outputDir = Directory(targetDirectory);
          if (outputDir.existsSync()) {
            await for (final entity in outputDir.list(recursive: true)) {
              if (entity is File) {
                generatedFiles.add(entity.path);
              }
            }
          }
        } catch (e) {
          cli_logger.Logger.debug('无法获取生成文件列表: $e');
        }
        
        return TemplateGenerationResult(
          success: true,
          generatedFiles: generatedFiles,
        );
      } else {
        return const TemplateGenerationResult(
          success: false,
          error: '模板生成失败',
          generatedFiles: [],
        );
      }
      
    } catch (e) {
      return TemplateGenerationResult(
        success: false,
        error: '模板生成失败: $e',
        generatedFiles: [],
      );
    }
  }

  /// 显示创建后的说明
  void _showPostCreationInstructions(String projectName, String targetDirectory) {
    cli_logger.Logger.info('');
    cli_logger.Logger.info('🎉 项目 "${ColorOutput.highlight(projectName)}" 创建完成!');
    cli_logger.Logger.info('');
    cli_logger.Logger.info('📋 下一步操作:');
    cli_logger.Logger.info('   1. ${ColorOutput.command('cd ${path.basename(targetDirectory)}')}');
    cli_logger.Logger.info('   2. ${ColorOutput.command('flutter pub get')}');
    cli_logger.Logger.info('   3. ${ColorOutput.command('flutter run')}');
    cli_logger.Logger.info('');
    cli_logger.Logger.info('📚 更多信息请查看项目的 ${ColorOutput.filePath('README.md')} 文件');
  }

  /// Task 32.1: 实现生成进度条和状态提示
  void _showProgress(String message, {double? progress}) {
    if (argResults!['verbose'] as bool) {
      if (progress != null) {
        final progressBar = ColorOutput.progressBar((progress * 100).toInt(), 100, width: 30);
        cli_logger.Logger.info('🔄 $message $progressBar');
      } else {
        cli_logger.Logger.info('🔄 $message');
      }
    }
  }

  /// Task 32.2: 添加用户确认和选项输入
  bool _confirmAction(String message, {bool defaultValue = false}) {
    final defaultStr = defaultValue ? 'Y/n' : 'y/N';
    final coloredMessage = ColorOutput.warning(message);
    print('$coloredMessage [${ColorOutput.highlight(defaultStr)}]: ');
    
    final input = stdin.readLineSync()?.trim().toLowerCase();
    
    if (input == null || input.isEmpty) {
      return defaultValue;
    }
    
    return input == 'y' || input == 'yes' || input == '是';
  }

  /// Task 32.2: 获取用户输入
  String? _getUserInput(String message, {String? defaultValue, bool required = false}) {
    final defaultStr = defaultValue != null ? ' [${ColorOutput.highlight(defaultValue)}]' : '';
    final coloredMessage = ColorOutput.info(message);
    print('$coloredMessage$defaultStr: ');
    
    final input = stdin.readLineSync()?.trim();
    
    if (input == null || input.isEmpty) {
      if (required && defaultValue == null) {
        cli_logger.Logger.error('❌ 此字段为必需项');
        return _getUserInput(message, defaultValue: defaultValue, required: required);
      }
      return defaultValue;
    }
    
    return input;
  }

  /// Task 32.3: 错误处理和回滚机制
  Future<void> _handleGenerationError(
    String error,
    String targetDirectory, {
    List<String>? generatedFiles,
  }) async {
    cli_logger.Logger.error('❌ 模板生成失败: ${ColorOutput.error(error)}');
    
    if (generatedFiles != null && generatedFiles.isNotEmpty) {
      cli_logger.Logger.info('');
      cli_logger.Logger.info('📋 已生成的文件:');
      for (final file in generatedFiles.take(10)) {
        cli_logger.Logger.info('  • ${ColorOutput.filePath(file)}');
      }
      
      if (generatedFiles.length > 10) {
        cli_logger.Logger.info('  ... 还有 ${ColorOutput.highlight('${generatedFiles.length - 10}')} 个文件');
      }
      
      cli_logger.Logger.info('');
      
      final shouldRollback = _confirmAction(
        '🔄 是否清理已生成的文件？',
        defaultValue: true,
      );
      
      if (shouldRollback) {
        await _rollbackGeneration(targetDirectory, generatedFiles);
      }
    }
    
    _suggestRecoveryOptions(error);
  }

  /// Task 32.3: 执行回滚操作
  Future<void> _rollbackGeneration(String targetDirectory, List<String> generatedFiles) async {
    try {
      _showProgress('正在清理生成的文件...');
      
      // 删除生成的文件
      for (final filePath in generatedFiles) {
        try {
          final file = File(filePath);
          if (file.existsSync()) {
            await file.delete();
          }
        } catch (e) {
          cli_logger.Logger.warning('清理文件失败: $filePath - $e');
        }
      }
      
      // 如果目标目录为空，尝试删除目录
      try {
        final targetDir = Directory(targetDirectory);
        if (targetDir.existsSync()) {
          final entities = targetDir.listSync();
          if (entities.isEmpty) {
            await targetDir.delete();
          }
        }
      } catch (e) {
        cli_logger.Logger.debug('清理目录失败: $targetDirectory - $e');
      }
      
      cli_logger.Logger.success('✅ 文件清理完成');
      
    } catch (e) {
      cli_logger.Logger.error('回滚操作失败: $e');
    }
  }

  /// Task 32.3: 建议恢复选项
  void _suggestRecoveryOptions(String error) {
    cli_logger.Logger.info('');
    cli_logger.Logger.info('💡 建议的解决方案:');
    
    if (error.contains('模板不存在')) {
      cli_logger.Logger.info('  • 检查模板名称是否正确');
      cli_logger.Logger.info('  • 运行 ${ColorOutput.command('"ming create --help"')} 查看可用模板');
      cli_logger.Logger.info('  • 确保模板文件存在于 ${ColorOutput.filePath('templates/')} 目录中');
    } else if (error.contains('目录已存在')) {
      cli_logger.Logger.info('  • 使用 ${ColorOutput.command('--force')} 参数强制覆盖');
      cli_logger.Logger.info('  • 选择不同的输出目录');
      cli_logger.Logger.info('  • 手动删除现有目录');
    } else if (error.contains('权限')) {
      cli_logger.Logger.info('  • 检查目录写入权限');
      cli_logger.Logger.info('  • 尝试使用管理员权限运行');
      cli_logger.Logger.info('  • 选择不同的输出目录');
    } else if (error.contains('变量')) {
      cli_logger.Logger.info('  • 检查提供的变量值是否正确');
      cli_logger.Logger.info('  • 使用 ${ColorOutput.command('--interactive')} 模式逐步输入变量');
      cli_logger.Logger.info('  • 查看模板文档了解必需变量');
    } else {
      cli_logger.Logger.info('  • 检查网络连接');
      cli_logger.Logger.info('  • 确保有足够的磁盘空间');
      cli_logger.Logger.info('  • 尝试重新运行命令');
      cli_logger.Logger.info('  • 如果问题持续，请查看详细日志');
    }
  }

  /// Task 32.1: 显示生成进度的增强版本
  Future<TemplateGenerationResult> _generateTemplateWithProgress({
    required String templateName,
    required String targetDirectory,
    required Map<String, dynamic> variables,
    required bool force,
  }) async {
    final generatedFiles = <String>[];
    
    try {
      _showProgress('正在验证模板...', progress: 0.1);
      
      // 验证模板是否存在
      final generator = await _templateEngine.loadTemplate(templateName);
      if (generator == null) {
        return TemplateGenerationResult(
          success: false,
          error: '模板不存在: $templateName',
          generatedFiles: [],
        );
      }
      
      _showProgress('正在准备输出目录...', progress: 0.2);
      
      // 检查目标目录冲突
      final targetDir = Directory(targetDirectory);
      if (targetDir.existsSync() && !force) {
        if (!_confirmAction('目标目录已存在，是否覆盖？')) {
          return const TemplateGenerationResult(
            success: false,
            error: '用户取消操作',
            generatedFiles: [],
          );
        }
      }
      
      _showProgress('正在处理模板变量...', progress: 0.3);
      
      // 清理现有目录（如果force=true）
      if (force && targetDir.existsSync()) {
        cli_logger.Logger.debug('清理现有目录: $targetDirectory');
        await targetDir.delete(recursive: true);
      }
      
      _showProgress('正在生成项目文件...', progress: 0.5);
      
      // 执行模板生成
      final success = await _templateEngine.generateModuleWithParameters(
        templateName: templateName,
        outputPath: targetDirectory,
        variables: variables,
        overwrite: force,
      );
      
      if (success) {
        _showProgress('正在收集生成的文件列表...', progress: 0.8);
        
        // 获取生成的文件列表
        try {
          final outputDir = Directory(targetDirectory);
          if (outputDir.existsSync()) {
            await for (final entity in outputDir.list(recursive: true)) {
              if (entity is File) {
                generatedFiles.add(entity.path);
              }
            }
          }
        } catch (e) {
          cli_logger.Logger.debug('无法获取生成文件列表: $e');
        }
        
        _showProgress('项目生成完成！', progress: 1);
        
        return TemplateGenerationResult(
          success: true,
          generatedFiles: generatedFiles,
        );
      } else {
        await _handleGenerationError(
          '模板生成过程失败',
          targetDirectory,
          generatedFiles: generatedFiles,
        );
        
        return TemplateGenerationResult(
          success: false,
          error: '模板生成失败',
          generatedFiles: generatedFiles,
        );
      }
      
    } catch (e) {
      await _handleGenerationError(
        e.toString(),
        targetDirectory,
        generatedFiles: generatedFiles,
      );
      
      return TemplateGenerationResult(
        success: false,
        error: '模板生成失败: $e',
        generatedFiles: generatedFiles,
      );
    }
  }

  /// Task 32.2: 交互式变量收集增强版本
  Future<Map<String, dynamic>> _collectVariablesInteractively(
    String templateName,
  ) async {
    cli_logger.Logger.info('');
    cli_logger.Logger.info('📝 交互式变量收集');
    cli_logger.Logger.info('请为模板 "$templateName" 提供必要的变量:');
    cli_logger.Logger.info('');

    final variables = <String, dynamic>{};
    
    try {
      // 从模板引擎获取变量定义
      final templateVariables = await _templateEngine.getTemplateVariableDefinitions(templateName);
      
      for (final variable in templateVariables) {
        final prompt = variable.prompt ?? '请输入 ${variable.name}';
        final defaultValue = variable.defaultValue?.toString();
        
        String? value;
        
        switch (variable.type) {
          case TemplateVariableType.boolean:
            value = _confirmAction(prompt, defaultValue: defaultValue == 'true').toString();
          case TemplateVariableType.enumeration:
            if (variable.values != null && variable.values!.isNotEmpty) {
              cli_logger.Logger.info(prompt);
              for (var i = 0; i < variable.values!.length; i++) {
                cli_logger.Logger.info('  ${i + 1}. ${variable.values![i]}');
              }
              
              final choice = _getUserInput('请选择 (1-${variable.values!.length})', defaultValue: '1');
              final index = int.tryParse(choice ?? '1');
              if (index != null && index >= 1 && index <= variable.values!.length) {
                value = variable.values![index - 1].toString();
              } else {
                value = variable.values!.first.toString();
              }
            } else {
              value = _getUserInput(prompt, defaultValue: defaultValue, required: !variable.optional);
            }
          default:
            value = _getUserInput(prompt, defaultValue: defaultValue, required: !variable.optional);
        }
        
        if (value != null) {
          variables[variable.name] = value;
        }
      }
      
    } catch (e) {
      cli_logger.Logger.debug('获取模板变量定义失败: $e，使用基本变量收集');
      
      // 基本变量收集
      final projectName = _getUserInput('项目名称', required: true);
      if (projectName != null) {
        variables['name'] = projectName;
        variables['project_name'] = projectName;
      }
      
      final description = _getUserInput('项目描述', defaultValue: '一个新的Flutter项目');
      if (description != null) {
        variables['description'] = description;
      }
      
      final author = _getUserInput('作者', defaultValue: 'lgnorant-lu');
      if (author != null) {
        variables['author'] = author;
      }
    }
    
    cli_logger.Logger.info('');
    cli_logger.Logger.info('📋 收集到的变量:');
    for (final entry in variables.entries) {
      cli_logger.Logger.info('  • ${entry.key}: ${entry.value}');
    }
    cli_logger.Logger.info('');
    
    final confirmed = _confirmAction('确认使用以上变量继续？', defaultValue: true);
    if (!confirmed) {
      throw Exception('用户取消操作');
    }
    
    return variables;
  }

  /// 获取项目名称
  String? _getProjectName() {
    if (argResults!.rest.isNotEmpty) {
      return argResults!.rest.first;
    }
    return null;
  }

  /// 准备模板变量
  Future<Map<String, dynamic>> _prepareVariables(String projectName) async {
    final variables = <String, dynamic>{};
    
    // 基本变量
    variables['name'] = projectName;
    variables['project_name'] = projectName;
    variables['module_name'] = projectName;
    variables['generated_date'] = DateTime.now().toIso8601String().substring(0, 10);
    
    // 从命令行参数获取额外变量
    final varOptions = argResults!.multiOption('var');
    for (final varOption in varOptions) {
      final parts = varOption.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        variables[key] = value;
      }
    }
    
    // 从用户配置获取默认值
    try {
      final userConfig = await _loadUserConfiguration();
      variables['author'] = userConfig.defaults.author;
      variables['description'] = variables['description'] ?? '一个新的Flutter项目';
    } catch (e) {
      cli_logger.Logger.debug('获取用户配置失败，使用默认值: $e');
      variables['author'] = 'lgnorant-lu';
      variables['description'] = variables['description'] ?? '一个新的Flutter项目';
    }
    
    return variables;
  }
}

/// 模板生成结果
class TemplateGenerationResult {
  const TemplateGenerationResult({
    required this.success,
    required this.generatedFiles, this.error,
  });

  final bool success;
  final String? error;
  final List<String> generatedFiles;
}
