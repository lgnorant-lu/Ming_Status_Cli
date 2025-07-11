/*
---------------------------------------------------------------
File name:          help_command.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        帮助命令 (Help command)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - CLI帮助命令;
    2025/06/29: Performance optimization - 轻量级实现，避免重度依赖;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 增强的帮助命令
/// 提供更友好和详细的帮助信息显示（轻量级实现）
class HelpCommand {
  /// 创建帮助命令实例，需要命令运行器实例来获取命令信息
  HelpCommand(this._runner);
  final CommandRunner<int> _runner;

  /// 显示特定命令的帮助信息
  Future<int> showSpecificCommandHelp(
    String commandName, {
    bool verbose = false,
  }) async {
    final command = _runner.commands[commandName];

    if (command == null) {
      Logger.error('未找到命令: $commandName');
      Logger.newLine();
      Logger.info('可用命令:');
      for (final name in _runner.commands.keys) {
        Logger.listItem(name);
      }
      return 1;
    }

    _showCommandDetailedHelp(command, verbose);
    return 0;
  }

  /// 显示命令的详细帮助信息
  void _showCommandDetailedHelp(Command<int> command, bool verbose) {
    // 检查是否有自定义usage，如果有则直接显示
    if (command.usage.isNotEmpty && command.usage.contains('使用方法:')) {
      Logger.title('📖 ${command.name} 命令帮助');
      Logger.newLine();
      print(command.usage);
      return;
    }

    // 否则使用通用格式
    Logger.title('📖 ${command.name} 命令帮助');
    Logger.newLine();

    // 基本信息
    Logger.subtitle('📋 基本信息');
    Logger.keyValue('命令名称', command.name);
    Logger.keyValue('描述', command.description);

    if (command.aliases.isNotEmpty) {
      Logger.keyValue('别名', command.aliases.join(', '));
    }

    Logger.newLine();

    // 用法示例
    Logger.subtitle('🚀 用法');
    if (command.invocation.isNotEmpty) {
      Logger.info('  ${command.invocation}');
    } else {
      Logger.info('  ming ${command.name} [选项]');
    }
    Logger.newLine();

    // 参数和选项
    if (command.argParser.options.isNotEmpty) {
      Logger.subtitle('⚙️  选项');
      for (final option in command.argParser.options.values) {
        final abbr = option.abbr != null ? '-${option.abbr}, ' : '';
        final name = '--${option.name}';
        final help = option.help ?? '无描述';

        if (option.isFlag) {
          Logger.listItem('$abbr$name: $help');
        } else {
          final defaultValue =
              option.defaultsTo != null ? ' (默认: ${option.defaultsTo})' : '';
          Logger.listItem('$abbr$name <值>: $help$defaultValue');
        }
      }
      Logger.newLine();
    }

    // 具体命令的示例
    Logger.subtitle('💡 示例');
    _showCommandExamples(command.name);
    Logger.newLine();

    if (verbose) {
      _showCommandVerboseHelp(command.name);
    }

    // 获取更多帮助的信息
    Logger.subtitle('📚 获取更多帮助');
    Logger.listItem('查看所有命令: ming help');
    Logger.listItem('项目主页: https://github.com/lgnorant-lu/Ming_Status_Cli');
    Logger.listItem(
      '问题反馈: https://github.com/lgnorant-lu/Ming_Status_Cli/issues',
    );
  }

  /// 显示命令示例
  void _showCommandExamples(String commandName) {
    switch (commandName) {
      case 'init':
        Logger.listItem('基本初始化: ming init');
        Logger.listItem('指定名称: ming init my-project');
        Logger.listItem(
          '完整配置: ming init --name "我的项目" --author "开发者" '
          '--description "项目描述"',
        );
        Logger.listItem('强制重新初始化: ming init --force');

      case 'doctor':
        Logger.listItem('基本检查: ming doctor');
        Logger.listItem('详细检查: ming doctor --detailed');
        Logger.listItem('自动修复: ming doctor --fix');

      case 'version':
        Logger.listItem('显示版本: ming version');
        Logger.listItem('详细信息: ming version --detailed');

      default:
        Logger.listItem('基本用法: ming $commandName');
        Logger.listItem('查看帮助: ming help $commandName');
    }
  }

  /// 显示命令的详细信息
  void _showCommandVerboseHelp(String commandName) {
    Logger.subtitle('🔧 详细信息');

    switch (commandName) {
      case 'init':
        Logger.info('init 命令用于初始化Ming Status工作空间：');
        Logger.listItem('创建配置文件 (ming_status.yaml)');
        Logger.listItem('建立标准目录结构 (src/, tests/, docs/)');
        Logger.listItem('生成示例文件和文档');
        Logger.listItem('配置默认设置和模板');
        Logger.newLine();
        Logger.info('⚠️  注意事项:');
        Logger.listItem('确保当前目录有写权限');
        Logger.listItem('工作空间名称应符合包命名规范');
        Logger.listItem('使用 --force 会覆盖现有配置');

      case 'doctor':
        Logger.info('doctor 命令检查开发环境状态：');
        Logger.listItem('验证 Dart SDK 版本和配置');
        Logger.listItem('检查工作空间配置完整性');
        Logger.listItem('验证依赖包状态');
        Logger.listItem('检查文件系统权限');
        Logger.newLine();
        Logger.info('🔧 自动修复功能:');
        Logger.listItem('创建缺失的配置文件');
        Logger.listItem('修复权限问题');
        Logger.listItem('清理无效缓存');

      case 'version':
        Logger.info('version 命令显示工具版本信息：');
        Logger.listItem('CLI 工具版本号');
        Logger.listItem('Dart SDK 版本');
        Logger.listItem('运行环境信息');
        Logger.listItem('性能和系统状态');

      default:
        Logger.info('这是一个标准的Ming Status CLI命令。');
        Logger.listItem('使用 --help 获取命令特定帮助');
        Logger.listItem('使用 --verbose 获取详细输出');
    }

    Logger.newLine();
  }
}
