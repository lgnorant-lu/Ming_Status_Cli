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
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';

import 'commands/init_command.dart';
import 'commands/version_command.dart';
import 'utils/logger.dart';

/// CLI应用主类
/// 负责注册命令、处理全局选项和应用程序生命周期
class MingStatusCliApp {
  late final CommandRunner<int> _runner;
  
  /// 应用名称
  static const String appName = 'ming';
  
  /// 应用描述
  static const String appDescription = 
      'Ming Status CLI - 强大的模块化开发工具\n'
      '用于创建、管理和验证模块化应用的代码结构';

  MingStatusCliApp() {
    _initializeRunner();
    _registerCommands();
  }

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

  /// 注册所有命令
  void _registerCommands() {
    // 核心命令
    _runner.addCommand(InitCommand());
    // 注意：CommandRunner已经有内置的help命令，不需要重复添加
    _runner.addCommand(VersionCommand());
    
    // TODO: 在后续阶段添加更多命令
    // _runner.addCommand(TemplateCommand());
    // _runner.addCommand(GenerateCommand());
    // _runner.addCommand(ValidateCommand());
    // _runner.addCommand(StatusCommand());
    // _runner.addCommand(CleanCommand());
  }

  /// 运行CLI应用
  Future<int> run(List<String> arguments) async {
    try {
      // 预处理参数
      arguments = _preprocessArguments(arguments);
      
      // 设置全局日志级别
      _setupGlobalLogging(arguments);
      
      // 处理特殊的全局参数
      if (_shouldShowVersion(arguments)) {
        await VersionCommand().execute();
        return 0;
      }
      
      // 运行命令
      final result = await _runner.run(arguments);
      return result ?? 0;
      
    } on UsageException catch (e) {
      // 处理用法错误
      _handleUsageError(e);
      return 64; // EX_USAGE
      
    } catch (e) {
      // 处理其他错误
      _handleUnexpectedError(e);
      return 1;
    }
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
      }
      else {
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

  /// 处理用法错误
  void _handleUsageError(UsageException e) {
    Logger.error(e.message);
    
    if (e.usage.isNotEmpty) {
      print('\n${e.usage}');
    }
    
    Logger.info('使用 "ming help" 获取更多帮助信息');
  }

  /// 处理意外错误
  void _handleUnexpectedError(Object error) {
    Logger.error('意外错误: $error');
    Logger.debug('如果问题持续存在，请报告此问题');
    Logger.info('GitHub: https://github.com/ignorant-lu/ming-status-cli/issues');
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
    return _runner.commands.keys.toList()..sort();
  }

  /// 获取应用使用信息
  String get usage => _runner.usage;
} 