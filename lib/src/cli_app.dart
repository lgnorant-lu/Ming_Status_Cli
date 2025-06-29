/*
---------------------------------------------------------------
File name:          cli_app.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        CLI应用主类 (Main CLI application class)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - CLI应用程序主入口;
    2025/06/29: Performance optimization - 延迟命令注册，提升启动性能;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/commands/config_command.dart';
import 'package:ming_status_cli/src/commands/doctor_command.dart';
import 'package:ming_status_cli/src/commands/help_command.dart';
import 'package:ming_status_cli/src/commands/init_command.dart';
import 'package:ming_status_cli/src/commands/version_command.dart';
import 'package:ming_status_cli/src/utils/error_handler.dart';
import 'package:ming_status_cli/src/utils/help_formatter.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// CLI应用主类
/// 负责注册命令、处理全局选项和应用程序生命周期
class MingStatusCliApp {
  MingStatusCliApp() {
    _initializeRunner();
    // 不再立即注册命令，延迟到实际需要时
  }
  late final CommandRunner<int> _runner;
  bool _commandsRegistered = false;

  /// 应用名称
  static const String appName = 'ming';

  /// 应用描述
  static const String appDescription = 'Ming Status CLI - 强大的模块化开发工具\n'
      '用于创建、管理和验证模块化应用的代码结构';

  /// 初始化命令运行器
  void _initializeRunner() {
    _runner = CommandRunner<int>(appName, appDescription);

    // 添加全局选项
    _runner.argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: '显示详细输出信息',
      negatable: false,
    );

    _runner.argParser.addFlag(
      'quiet',
      abbr: 'q',
      help: '静默模式，仅显示错误信息',
      negatable: false,
    );

    _runner.argParser.addFlag(
      'version',
      help: '显示版本信息',
      negatable: false,
    );
  }

  /// 延迟注册所有命令（仅在需要时）
  void _ensureCommandsRegistered() {
    if (_commandsRegistered) return;

    // 核心命令
    _runner.addCommand(InitCommand());
    _runner.addCommand(ConfigCommand());
    _runner.addCommand(VersionCommand());
    _runner.addCommand(DoctorCommand());

    // 注意：使用自定义帮助处理而不是添加help命令
    // 因为CommandRunner已经有内置的help命令

    // TODO: 在后续阶段添加更多命令
    // _runner.addCommand(TemplateCommand());
    // _runner.addCommand(GenerateCommand());
    // _runner.addCommand(ValidateCommand());
    // _runner.addCommand(StatusCommand());
    // _runner.addCommand(CleanCommand());

    _commandsRegistered = true;
  }

  /// 运行CLI应用
  Future<int> run(List<String> arguments) async {
    try {
      // 预处理参数
      arguments = _preprocessArguments(arguments);

      // 设置全局日志级别
      _setupGlobalLogging(arguments);

      // 优先处理快速命令，避免注册所有命令
      final quickResult = await _handleQuickCommands(arguments);
      if (quickResult != null) return quickResult;

      // 处理自定义帮助显示
      if (_shouldShowCustomHelp(arguments)) {
        return await _handleCustomHelp(arguments);
      }

      // 只有在真正需要运行命令时才注册所有命令
      _ensureCommandsRegistered();

      // 运行命令
      final result = await _runner.run(arguments);
      return result ?? 0;
    } on UsageException catch (e) {
      // 使用增强的错误处理器
      ErrorHandler.handleException(e, context: '命令行参数解析');
      ErrorHandler.showCommonCommands();
      return 64; // EX_USAGE
    } catch (e) {
      // 使用增强的错误处理器
      ErrorHandler.handleException(e, context: '应用程序运行');
      ErrorHandler.showQuickFixes();
      return 1;
    }
  }

  /// 处理快速命令（避免完整初始化）
  Future<int?> _handleQuickCommands(List<String> arguments) async {
    // 处理 --version 全局参数
    if (_shouldShowVersion(arguments)) {
      await VersionCommand().run();
      return 0;
    }

    // 处理直接的 version 命令
    if (arguments.isNotEmpty && arguments.first == 'version') {
      // 创建临时的CommandRunner来处理version命令
      final tempRunner = CommandRunner<int>('temp', 'temp');
      final versionCmd = VersionCommand();
      tempRunner.addCommand(versionCmd);
      await tempRunner.run(arguments);
      return 0;
    }

    return null; // 需要完整处理
  }

  /// 预处理命令行参数
  List<String> _preprocessArguments(List<String> arguments) {
    final processed = <String>[];

    for (var i = 0; i < arguments.length; i++) {
      final arg = arguments[i];

      // 处理简写的帮助参数
      if (arg == '-h') {
        processed.add('--help');
      }
      // 处理合并的短选项（如 -vq）
      else if (arg.startsWith('-') && !arg.startsWith('--') && arg.length > 2) {
        for (var j = 1; j < arg.length; j++) {
          processed.add('-${arg[j]}');
        }
      } else {
        processed.add(arg);
      }
    }

    return processed;
  }

  /// 设置全局日志配置
  void _setupGlobalLogging(List<String> arguments) {
    if (arguments.contains('--verbose') || arguments.contains('-v')) {
      Logger.verbose = true;
      Logger.minLevel = LogLevel.debug;
    } else if (arguments.contains('--quiet') || arguments.contains('-q')) {
      Logger.minLevel = LogLevel.error;
    }
  }

  /// 检查是否应该显示版本信息
  bool _shouldShowVersion(List<String> arguments) {
    return arguments.contains('--version');
  }

  /// 检查是否应该显示自定义帮助
  bool _shouldShowCustomHelp(List<String> arguments) {
    if (arguments.isEmpty) return false;

    return arguments.contains('help') ||
        arguments.contains('--help') ||
        arguments.contains('-h');
  }

  /// 处理自定义帮助显示
  Future<int> _handleCustomHelp(List<String> arguments) async {
    // 提取help命令的参数
    String? commandName;
    var verbose = false;

    // 查找help参数的位置和后续参数
    for (var i = 0; i < arguments.length; i++) {
      if (arguments[i] == 'help') {
        // 检查是否有命令名称参数
        if (i + 1 < arguments.length && !arguments[i + 1].startsWith('-')) {
          commandName = arguments[i + 1];
        }
        break;
      }
    }

    // 检查verbose标志
    verbose = arguments.contains('--verbose') || arguments.contains('-v');

    // 直接调用帮助显示逻辑
    if (commandName != null) {
      return _showCommandHelp(commandName, verbose);
    } else {
      _showMainHelp(verbose);
      return 0;
    }
  }

  /// 显示主帮助信息
  void _showMainHelp(bool verbose) {
    // 确保命令已注册，这样才能在帮助中显示它们
    _ensureCommandsRegistered();
    
    HelpFormatter.showMainHelp(_runner);

    if (verbose) {
      _showVerboseMainHelp();
    }
  }

  /// 显示详细的主帮助信息
  void _showVerboseMainHelp() {
    Logger.subtitle('🔧 开发者信息');
    Logger.keyValue('项目状态', 'Phase 1 - 核心功能开发中');
    Logger.keyValue('支持平台', 'Windows, macOS, Linux');
    Logger.keyValue('Dart版本要求', '>=3.0.0');
    Logger.newLine();

    Logger.subtitle('📊 当前功能');
    Logger.listItem('✅ 工作空间初始化和配置管理');
    Logger.listItem('✅ 环境检查和诊断工具');
    Logger.listItem('✅ 模块化项目结构创建');
    Logger.listItem('🚧 模板系统（开发中）');
    Logger.listItem('🚧 代码生成工具（计划中）');
    Logger.newLine();
  }

  /// 显示特定命令的帮助
  Future<int> _showCommandHelp(String commandName, bool verbose) async {
    // 确保命令已注册
    _ensureCommandsRegistered();
    
    final helpCommand = HelpCommand(_runner);
    return helpCommand.showSpecificCommandHelp(commandName, verbose);
  }

  /// 显示欢迎信息（可选）
  void showWelcome() {
    if (Logger.minLevel != LogLevel.error) {
      Logger.title('欢迎使用 Ming Status CLI');
      Logger.info('模块化开发工具 - 让代码组织更简单');
      Logger.info('使用 "ming help" 查看可用命令');
      Logger.newLine();
    }
  }

  /// 获取可用命令列表
  List<String> get availableCommands {
    _ensureCommandsRegistered(); // 确保命令已注册
    return _runner.commands.keys.toList()..sort();
  }

  /// 获取应用使用信息
  String get usage => _runner.usage;
}
