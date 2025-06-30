/*
---------------------------------------------------------------
File name:          help_formatter.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/30
Dart Version:       3.32.4
Description:        帮助文本格式化器 (Help text formatter)
---------------------------------------------------------------
Change History:
    2025/06/30: Add create command - 添加create命令;
    2025/06/29: Initial creation - 增强帮助系统的显示格式;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 帮助文本格式化器
/// 提供美化的CLI帮助文本显示
class HelpFormatter {
  /// 格式化主帮助信息
  static void showMainHelp(CommandRunner runner) {
    // 标题和欢迎信息
    Logger.title('Ming Status CLI');
    Logger.subtitle('强大的模块化开发工具');
    Logger.info('用于创建、管理和验证模块化应用的代码结构');
    Logger.newLine();

    // 快速开始指南
    _showQuickStart();

    // 用法信息
    _showUsage(runner);

    // 全局选项
    _showGlobalOptions(runner);

    // 可用命令
    _showAvailableCommands(runner);

    // 示例
    _showExamples();

    // 获取更多帮助
    _showMoreHelp();
  }

  /// 显示快速开始指南
  static void _showQuickStart() {
    Logger.subtitle('🚀 快速开始');
    Logger.listItem('首次使用？运行 "ming doctor" 检查环境');
    Logger.listItem('创建新项目：运行 "ming init my-project"');
    Logger.listItem('查看版本信息：运行 "ming version --detailed"');
    Logger.newLine();
  }

  /// 显示用法信息
  static void _showUsage(CommandRunner runner) {
    Logger.subtitle('📖 用法');
    Logger.keyValue('基本格式', 'ming <command> [arguments]');
    Logger.keyValue('查看命令帮助', 'ming help <command>');
    Logger.newLine();
  }

  /// 显示全局选项
  static void _showGlobalOptions(CommandRunner runner) {
    Logger.subtitle('🌐 全局选项');
    Logger.keyValue('-h, --help', '显示帮助信息');
    Logger.keyValue('-v, --verbose', '显示详细输出信息');
    Logger.keyValue('-q, --quiet', '静默模式，仅显示错误信息');
    Logger.keyValue('--version', '显示版本信息');
    Logger.newLine();
  }

  /// 显示可用命令
  static void _showAvailableCommands(CommandRunner runner) {
    Logger.subtitle('📋 可用命令');

    // 按类别组织命令
    final commands = runner.commands;

    // 核心命令
    Logger.info('💼 核心命令：');
    if (commands.containsKey('init')) {
      Logger.listItem('init     - 初始化Ming Status模块工作空间', indent: 1);
    }
    if (commands.containsKey('create')) {
      Logger.listItem('create   - 基于模板创建新的模块或项目', indent: 1);
    }
    if (commands.containsKey('config')) {
      Logger.listItem('config   - 管理全局和工作空间配置', indent: 1);
    }
    if (commands.containsKey('doctor')) {
      Logger.listItem('doctor   - 检查开发环境和工作空间状态', indent: 1);
    }
    if (commands.containsKey('version')) {
      Logger.listItem('version  - 显示版本信息', indent: 1);
    }

    Logger.newLine();

    // 获取命令详细帮助的提示
    Logger.info('💡 使用 "ming help <command>" 查看特定命令的详细帮助');
    Logger.newLine();
  }

  /// 显示示例
  static void _showExamples() {
    Logger.subtitle('💡 常用示例');

    Logger.info('🔧 环境检查：');
    Logger.listItem('ming doctor                    # 基本环境检查', indent: 1);
    Logger.listItem('ming doctor --detailed         # 详细环境检查', indent: 1);
    Logger.listItem('ming doctor --config           # 配置深度检查', indent: 1);
    Logger.listItem('ming doctor --fix              # 自动修复问题', indent: 1);
    Logger.newLine();

    Logger.info('🏗️  项目初始化：');
    Logger.listItem('ming init                      # 在当前目录初始化', indent: 1);
    Logger.listItem('ming init my-project           # 创建并初始化新项目', indent: 1);
    Logger.listItem('ming init --name "My App"      # 指定项目名称', indent: 1);
    Logger.newLine();

    Logger.info('⚙️  配置管理：');
    Logger.listItem('ming config --list             # 查看所有配置', indent: 1);
    Logger.listItem('ming config --get user.name    # 获取配置值', indent: 1);
    Logger.listItem('ming config --set user.name=值 # 设置配置值', indent: 1);
    Logger.listItem('ming config --global --set key=value # 设置全局配置', indent: 1);
    Logger.newLine();

    Logger.info('ℹ️  版本信息：');
    Logger.listItem('ming version                   # 显示基本版本', indent: 1);
    Logger.listItem('ming version --detailed        # 显示详细系统信息', indent: 1);
    Logger.newLine();
  }

  /// 显示获取更多帮助的信息
  static void _showMoreHelp() {
    Logger.subtitle('📚 获取更多帮助');
    Logger.keyValue('项目主页', 'https://github.com/lgnorant-lu/Ming_Status_Cli');
    Logger.keyValue('文档', 'https://github.com/lgnorant-lu/Ming_Status_Cli/wiki');
    Logger.keyValue('问题反馈', 'https://github.com/lgnorant-lu/Ming_Status_Cli/issues');
    Logger.newLine();

    Logger.info('💬 提示：使用 --verbose 选项获取更详细的执行信息');
  }

  /// 格式化命令特定帮助
  static void showCommandHelp(
    String commandName,
    String usage, {
    String? description,
    List<String>? examples,
    List<String>? notes,
    String? docLink,
  }) {
    // 命令标题
    Logger.title('$commandName 命令帮助');

    if (description != null) {
      Logger.info(description);
      Logger.newLine();
    }

    // 用法
    Logger.subtitle('📖 用法');
    Logger.info(usage);
    Logger.newLine();

    // 示例
    if (examples != null && examples.isNotEmpty) {
      Logger.subtitle('💡 示例');
      for (var i = 0; i < examples.length; i++) {
        Logger.listItem('${i + 1}. ${examples[i]}');
      }
      Logger.newLine();
    }

    // 注意事项
    if (notes != null && notes.isNotEmpty) {
      Logger.subtitle('⚠️  注意事项');
      for (final note in notes) {
        Logger.listItem(note);
      }
      Logger.newLine();
    }

    // 文档链接
    if (docLink != null) {
      Logger.subtitle('📚 相关文档');
      Logger.info(docLink);
      Logger.newLine();
    }

    // 返回主帮助的提示
    Logger.info('💬 使用 "ming help" 查看所有可用命令');
  }

  /// 格式化选项帮助
  static void formatOption(String option, String description,
      {String? defaultValue,}) {
    if (defaultValue != null) {
      Logger.keyValue(option, '$description (默认: $defaultValue)');
    } else {
      Logger.keyValue(option, description);
    }
  }

  /// 显示命令类别
  static void showCommandCategory(String category, List<String> commands) {
    Logger.info('$category:');
    for (final command in commands) {
      Logger.listItem(command, indent: 1);
    }
    Logger.newLine();
  }

  /// 显示提示信息
  static void showTip(String message) {
    Logger.usageTip('💡 提示', message);
  }

  /// 显示警告信息
  static void showWarning(String message) {
    Logger.structuredWarning(
      title: '注意',
      description: message,
    );
  }
}
