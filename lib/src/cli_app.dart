/*
---------------------------------------------------------------
File name:          cli_app.dart
Author:             lgnorant-lu
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
import 'package:ming_status_cli/src/commands/create_command.dart';
import 'package:ming_status_cli/src/commands/doctor_command.dart';
import 'package:ming_status_cli/src/commands/help_command.dart';
import 'package:ming_status_cli/src/commands/init_command.dart';
import 'package:ming_status_cli/src/commands/optimize_command.dart';
import 'package:ming_status_cli/src/commands/registry_command.dart';
import 'package:ming_status_cli/src/commands/template_command.dart';
import 'package:ming_status_cli/src/commands/validate_command.dart';
import 'package:ming_status_cli/src/commands/version_command.dart';
import 'package:ming_status_cli/src/utils/error_handler.dart';
import 'package:ming_status_cli/src/utils/help_formatter.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// CLI应用主类
/// 负责注册命令、处理全局选项和应用程序生命周期
class MingStatusCliApp {
  /// 构造函数，初始化命令运行器。
  MingStatusCliApp() {
    _initializeRunner();
    // 不再立即注册命令，延迟到实际需要时
  }

  /// 命令运行器实例
  late final CommandRunner<int> _runner;

  /// 标志位，指示命令是否已注册
  bool _commandsRegistered = false;

  /// 应用名称
  static const String appName = 'ming';

  /// 应用描述
  static const String appDescription = '''
Ming Status CLI - 企业级项目管理和模板生态系统

一个功能完整的企业级命令行工具，支持项目状态管理、高级模板系统和远程模板生态。

🎯 核心功能:
• 项目初始化和配置管理
• 企业级模板系统 (10个template子命令)
• 远程模板注册表管理 (4个registry子命令)
• 项目状态检查和验证
• 性能优化和监控分析

📚 高级模板系统 (Phase 2.1):
• template list/search/info - 模板发现和管理
• template create/generate - 模板创建工具
• template inherit/conditional - 高级模板功能
• template params/library - 参数化和库管理
• template benchmark - 性能测试

🌐 远程模板生态 (Phase 2.2):
• registry add/list - 注册表管理
• registry sync/stats - 同步和统计

使用 'ming help <command>' 获取特定命令的详细帮助信息。
''';

  /// 应用品牌信息
  static const String appBrand = '''
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    ███╗   ███╗██╗███╗   ██╗ ██████╗     ███████╗████████╗ █████╗ ████████╗  ║
║    ████╗ ████║██║████╗  ██║██╔════╝     ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝  ║
║    ██╔████╔██║██║██╔██╗ ██║██║  ███╗    ███████╗   ██║   ███████║   ██║     ║
║    ██║╚██╔╝██║██║██║╚██╗██║██║   ██║    ╚════██║   ██║   ██╔══██║   ██║     ║
║    ██║ ╚═╝ ██║██║██║ ╚████║╚██████╔╝    ███████║   ██║   ██║  ██║   ██║     ║
║    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝     ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝     ║
║                                                                              ║
║                    🚀 企业级项目管理和模板生态系统                              ║
║                                                                              ║
║                        Created by lgnorant-lu                               ║
║                     https://github.com/lgnorant-lu                          ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
''';

  /// 简化版品牌信息
  static const String appBrandSimple = '''
┌─────────────────────────────────────────────────────────────────────────────┐
│  🌟 MING STATUS CLI - 企业级项目管理和模板生态系统                              │
│                                                                             │
│  ⚡ 让代码组织更简单，让开发更高效                                              │
│  🎯 专为现代化企业级开发而设计                                                  │
│                                                                             │
│  👨‍💻 Created by lgnorant-lu                                                  │
│  🔗 https://github.com/lgnorant-lu/Ming_Status_Cli                         │
└─────────────────────────────────────────────────────────────────────────────┘
''';

  /// 初始化命令运行器
  void _initializeRunner() {
    _runner = CommandRunner<int>(appName, appDescription);

    // 添加全局选项
    _runner.argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: '显示详细输出信息',
        negatable: false,
      )
      ..addFlag(
        'quiet',
        abbr: 'q',
        help: '静默模式，仅显示错误信息',
        negatable: false,
      )
      ..addFlag(
        'version',
        help: '显示版本信息',
        negatable: false,
      );
  }

  /// 延迟注册所有命令（仅在需要时）
  void _ensureCommandsRegistered() {
    if (_commandsRegistered) return;

    // 核心命令
    _runner
      ..addCommand(InitCommand())
      ..addCommand(CreateCommand())
      ..addCommand(ConfigCommand())
      ..addCommand(VersionCommand())
      ..addCommand(DoctorCommand())
      ..addCommand(ValidateCommand()) // Phase 1 Week 5: 验证系统命令
      ..addCommand(OptimizeCommand()); // 性能优化命令

    // Phase 2.1: 高级模板系统命令
    _runner.addCommand(TemplateCommand());

    // Phase 2.2: 远程模板生态系统命令
    _runner.addCommand(RegistryCommand());

    // 注意：使用自定义帮助处理而不是添加help命令
    // 因为CommandRunner已经有内置的help命令

    // TODO(future): 在后续阶段添加更多命令
    // _runner.addCommand(TemplateCommand());
    // _runner.addCommand(GenerateCommand());
    // _runner.addCommand(StatusCommand());
    // _runner.addCommand(CleanCommand());

    _commandsRegistered = true;
  }

  /// 运行CLI应用
  ///
  /// [arguments] 命令行参数列表
  /// 返回CLI应用的退出码
  Future<int> run(List<String> arguments) async {
    try {
      // 预处理参数
      final processedArguments = _preprocessArguments(arguments);

      // 设置全局日志级别
      _setupGlobalLogging(processedArguments);

      // 优先处理快速命令，避免注册所有命令
      final quickResult = await _handleQuickCommands(processedArguments);
      if (quickResult != null) return quickResult;

      // 处理自定义帮助显示
      if (_shouldShowCustomHelp(processedArguments)) {
        return await _handleCustomHelp(processedArguments);
      }

      // 只有在真正需要运行命令时才注册所有命令
      _ensureCommandsRegistered();

      // 运行命令
      final result = await _runner.run(processedArguments);
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
  ///
  /// [arguments] 命令行参数列表
  /// 返回快速命令的退出码，如果不是快速命令则返回null
  Future<int?> _handleQuickCommands(List<String> arguments) async {
    // 处理 --version 全局参数
    if (_shouldShowVersion(arguments)) {
      _showQuickVersion();
      return 0;
    }

    // 处理直接的 version 命令
    if (arguments.isNotEmpty && arguments.first == 'version') {
      _showQuickVersion();
      return 0;
    }

    // 处理简单帮助请求
    if (arguments.isEmpty ||
        (arguments.length == 1 &&
            (arguments.contains('--help') || arguments.contains('-h')))) {
      _showQuickHelp();
      return 0;
    }

    // 处理help命令
    if (arguments.isNotEmpty &&
        arguments.first == 'help' &&
        arguments.length == 1) {
      _showQuickHelp();
      return 0;
    }

    return null; // 需要完整处理
  }

  /// 显示快速版本信息（无需加载VersionCommand）
  void _showQuickVersion() {
    Logger.info('ming_status_cli 1.0.0');
  }

  /// 显示快速帮助信息（无需加载HelpFormatter）
  void _showQuickHelp() {
    print('''
┌─────────────────────────────────────────────────────────────────────────────┐
│  🌟 MING STATUS CLI - 企业级项目管理和模板生态系统                              │
│                                                                             │
│  ⚡ 让代码组织更简单，让开发更高效                                              │
│  🎯 专为现代化企业级开发而设计                                                  │
│                                                                             │
│  👨‍💻 Created by lgnorant-lu                                                  │
│  🔗 https://github.com/lgnorant-lu/Ming_Status_Cli                         │
└─────────────────────────────────────────────────────────────────────────────┘

📋 🚀 快速开始
  ming doctor                    # 检查开发环境
  ming init my-project           # 创建新项目
  ming template list             # 浏览模板

📋 📖 基本用法
  ming <command> [arguments]     # 基本格式
  ming help <command>            # 查看命令帮助

📋 🏗️  核心命令
  init     - 🚀 初始化工作空间
  create   - 📦 创建模块或项目
  config   - ⚙️  配置管理
  doctor   - 🔍 环境检查
  validate - ✅ 验证项目
  optimize - ⚡ 性能优化
  version  - ℹ️  版本信息

📋 📚 高级功能
  template - 🎨 模板管理系统
  registry - 🗄️  注册表管理

📋 💡 获取详细帮助
  ming help <command>            # 命令详细帮助
  ming <command> --help          # 子命令帮助

✨ 感谢使用 Ming Status CLI！
''');
  }

  /// 预处理命令行参数
  ///
  /// [arguments] 原始命令行参数列表
  /// 返回处理后的参数列表
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
  ///
  /// [arguments] 命令行参数列表
  void _setupGlobalLogging(List<String> arguments) {
    if (arguments.contains('--verbose') || arguments.contains('-v')) {
      Logger.verbose = true;
      Logger.minLevel = LogLevel.debug;
    } else if (arguments.contains('--quiet') || arguments.contains('-q')) {
      Logger.minLevel = LogLevel.error;
    }
  }

  /// 检查是否应该显示版本信息
  ///
  /// [arguments] 命令行参数列表
  /// 返回是否显示版本信息
  bool _shouldShowVersion(List<String> arguments) {
    return arguments.contains('--version');
  }

  /// 检查是否应该显示自定义帮助
  ///
  /// [arguments] 命令行参数列表
  /// 返回是否显示自定义帮助
  bool _shouldShowCustomHelp(List<String> arguments) {
    if (arguments.isEmpty) return false;

    // 如果第一个参数是已知命令，且包含--help，则不拦截，让命令自己处理
    if (arguments.isNotEmpty && !arguments[0].startsWith('-')) {
      final firstArg = arguments[0];
      final knownCommands = [
        'template',
        'registry',
        'init',
        'create',
        'config',
        'doctor',
        'validate',
        'optimize',
        'version',
      ];
      if (knownCommands.contains(firstArg) &&
          (arguments.contains('--help') || arguments.contains('-h'))) {
        return false; // 让命令自己处理--help
      }
    }

    return arguments.contains('help') ||
        (arguments.length == 1 &&
            (arguments.contains('--help') || arguments.contains('-h')));
  }

  /// 处理自定义帮助显示
  ///
  /// [arguments] 命令行参数列表
  /// 返回帮助命令的退出码
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
  ///
  /// [verbose] 是否显示详细信息
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
    Logger.listItem('✅ 企业级验证系统 - 结构/质量/依赖/平台规范验证');
    Logger.listItem('✅ 智能自动修复 - 代码格式化/导入排序/配置修正');
    Logger.listItem('✅ 多格式输出 - console/json/junit/compact');
    Logger.listItem('✅ 监控模式 - 文件变化实时验证');
    Logger.listItem('🚧 模板系统（开发中）');
    Logger.listItem('🚧 代码生成工具（计划中）');
    Logger.newLine();

    Logger.subtitle('🔍 验证系统特性');
    Logger.listItem('• StructureValidator - 模块结构和命名规范验证');
    Logger.listItem('• QualityValidator - 代码质量和最佳实践检查（含dart analyze集成）');
    Logger.listItem('• DependencyValidator - 依赖安全和版本兼容性管理');
    Logger.listItem('• PlatformComplianceValidator - Pet App平台规范验证');
    Logger.listItem('• AutoFixManager - 智能问题识别和自动修复');
    Logger.newLine();
  }

  /// 显示特定命令的帮助
  ///
  /// [commandName] 命令名称
  /// [verbose] 是否显示详细信息
  /// 返回命令帮助的退出码
  Future<int> _showCommandHelp(String commandName, bool verbose) async {
    // 确保命令已注册
    _ensureCommandsRegistered();

    final helpCommand = HelpCommand(_runner);
    return helpCommand.showSpecificCommandHelp(commandName, verbose: verbose);
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
