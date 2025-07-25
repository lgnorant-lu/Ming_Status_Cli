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
  static void showMainHelp(CommandRunner<int> runner) {
    // 显示品牌化标题
    _showBrandHeader();

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

  /// 显示品牌化标题
  static void _showBrandHeader() {
    // 检查终端宽度，决定显示完整版还是简化版
    const brandSimple = '''
┌─────────────────────────────────────────────────────────────────────────────┐
│  🌟 MING STATUS CLI - 企业级项目管理和模板生态系统                              │
│                                                                             │
│  ⚡ 让代码组织更简单，让开发更高效                                              │
│  🎯 专为现代化企业级开发而设计                                                  │
│                                                                             │
│  👨‍💻 Created by lgnorant-lu                                                  │
│  🔗 https://github.com/lgnorant-lu/Ming_Status_Cli                         │
└─────────────────────────────────────────────────────────────────────────────┘''';

    print(brandSimple);
    Logger.newLine();
  }

  /// 显示快速开始指南
  static void _showQuickStart() {
    Logger.subtitle('🚀 快速开始 - 4步上手Ming Status CLI');
    Logger.info('┌─ 第1步：环境检查');
    Logger.listItem('ming doctor                    # 检查开发环境是否就绪', indent: 1);
    Logger.info('├─ 第2步：项目初始化');
    Logger.listItem('ming init my-awesome-project   # 创建你的第一个项目', indent: 1);
    Logger.info('├─ 第3步：探索功能');
    Logger.listItem('ming template list             # 浏览可用模板', indent: 1);
    Logger.listItem('ming plugin list               # 查看已安装插件', indent: 1);
    Logger.info('└─ 第4步：深入学习');
    Logger.listItem('ming help                      # 查看完整功能列表', indent: 1);
    Logger.newLine();
    Logger.info('💡 新手提示：运行 "ming version --detailed" 查看详细系统信息');
    Logger.info('🔌 插件开发：运行 "ming create my-plugin --template=plugin" 创建插件');
    Logger.newLine();
  }

  /// 显示用法信息
  static void _showUsage(CommandRunner<int> runner) {
    Logger.subtitle('📖 用法');
    Logger.keyValue('基本格式', 'ming <command> [arguments]');
    Logger.keyValue('查看命令帮助', 'ming help <command>');
    Logger.newLine();
  }

  /// 显示全局选项
  static void _showGlobalOptions(CommandRunner<int> runner) {
    Logger.subtitle('🌐 全局选项');
    Logger.keyValue('-h, --help', '显示帮助信息');
    Logger.keyValue('-v, --verbose', '显示详细输出信息');
    Logger.keyValue('-q, --quiet', '静默模式，仅显示错误信息');
    Logger.keyValue('--version', '显示版本信息');
    Logger.newLine();
  }

  /// 显示可用命令
  static void _showAvailableCommands(CommandRunner<int> runner) {
    Logger.subtitle('📋 命令总览 - 功能分类导航');

    // 按类别组织命令
    final commands = runner.commands;

    // 核心命令 - 基础功能
    Logger.info('🏗️  基础工具 (项目管理核心)');
    Logger.info(
      '   ┌─────────────────────────────────────────────────────────────┐',
    );
    if (commands.containsKey('init')) {
      Logger.info('   │ init     - 🚀 初始化Ming Status模块工作空间                │');
    }
    if (commands.containsKey('create')) {
      Logger.info('   │ create   - 📦 基于模板创建新的模块或项目                   │');
    }
    if (commands.containsKey('config')) {
      Logger.info('   │ config   - ⚙️  管理全局和工作空间配置                      │');
    }
    if (commands.containsKey('doctor')) {
      Logger.info('   │ doctor   - 🔍 检查开发环境和工作空间状态                   │');
    }
    if (commands.containsKey('validate')) {
      Logger.info('   │ validate - ✅ 验证模块的结构、质量、依赖关系和平台规范     │');
    }
    if (commands.containsKey('optimize')) {
      Logger.info('   │ optimize - ⚡ 执行性能优化和分析                           │');
    }
    if (commands.containsKey('version')) {
      Logger.info(
        '   │ version  - ℹ️  显示版本信息                                │',
      );
    }
    Logger.info(
      '   └─────────────────────────────────────────────────────────────┘',
    );
    Logger.newLine();

    // Phase 2.1: 高级模板系统命令
    if (commands.containsKey('template')) {
      Logger.info('📚 高级模板系统 (企业级模板生态)');
      Logger.info(
        '   ┌─────────────────────────────────────────────────────────────┐',
      );
      Logger.info('   │ template - 🎨 企业级模板管理系统 (15个子命令)              │');
      Logger.info(
        '   │                                                             │',
      );
      Logger.info(
        '   │ 🔍 发现管理: list, search, info                            │',
      );
      Logger.info(
        '   │ 🛠️  创建工具: create, generate                              │',
      );
      Logger.info(
        '   │ 🏗️  高级功能: inherit, conditional                          │',
      );
      Logger.info(
        '   │ ⚙️  参数化: params, library                                 │',
      );
      Logger.info(
        '   │ 📊 性能测试: benchmark                                      │',
      );
      Logger.info(
        '   │ 📦 分发管理: install, update                               │',
      );
      Logger.info(
        '   │ 🔒 安全验证: security                                       │',
      );
      Logger.info(
        '   │ 🏢 企业管理: enterprise                                     │',
      );
      Logger.info(
        '   │ 🌐 网络支持: network                                        │',
      );
      Logger.info(
        '   └─────────────────────────────────────────────────────────────┘',
      );
      Logger.newLine();
    }

    // Phase 2.2: 远程模板生态系统命令
    if (commands.containsKey('registry')) {
      Logger.info('🌐 远程模板生态 (分布式注册表系统)');
      Logger.info(
        '   ┌─────────────────────────────────────────────────────────────┐',
      );
      Logger.info('   │ registry - 🗄️  模板注册表管理系统 (4个子命令)              │');
      Logger.info(
        '   │                                                             │',
      );
      Logger.info(
        '   │ 📝 注册表管理: add, list                                   │',
      );
      Logger.info(
        '   │ 🔄 数据同步: sync, stats                                   │',
      );
      Logger.info(
        '   └─────────────────────────────────────────────────────────────┘',
      );
      Logger.newLine();
    }

    // Phase A: 插件管理系统命令
    if (commands.containsKey('plugin')) {
      Logger.info('🔌 插件管理系统 (Pet App V3插件生态)');
      Logger.info(
        '   ┌─────────────────────────────────────────────────────────────┐',
      );
      Logger.info('   │ plugin   - 🧩 插件开发和管理工具 (5个子命令)               │');
      Logger.info(
        '   │                                                             │',
      );
      Logger.info(
        '   │ 🔍 质量管理: validate                                      │',
      );
      Logger.info(
        '   │ 🛠️  构建发布: build, publish                                │',
      );
      Logger.info(
        '   │ 📦 生命周期: list, install                                 │',
      );
      Logger.info(
        '   └─────────────────────────────────────────────────────────────┘',
      );
      Logger.newLine();
    }

    // 获取命令详细帮助的提示
    Logger.info(
      '┌─────────────────────────────────────────────────────────────────┐',
    );
    Logger.info(
      '│ 💡 快速导航                                                    │',
    );
    Logger.info(
      '│                                                                 │',
    );
    Logger.info('│ 📖 查看命令帮助: ming help <command>                           │');
    Logger.info('│ 🔍 查看子命令帮助: ming <command> <subcommand> --help          │');
    Logger.info('│ 📊 查看详细信息: ming <command> --help                         │');
    Logger.info(
      '└─────────────────────────────────────────────────────────────────┘',
    );
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

    Logger.info('🔍 模块验证：');
    Logger.listItem('ming validate                  # 验证当前模块或项目', indent: 1);
    Logger.listItem('ming validate --health-check   # 检查验证器健康状态', indent: 1);
    Logger.listItem('ming validate --fix            # 自动修复可修复的问题', indent: 1);
    Logger.listItem(
      'ming validate --watch          # 监控模式，文件变化时自动验证',
      indent: 1,
    );
    Logger.listItem(
      'ming validate --output json    # 以JSON格式输出验证结果',
      indent: 1,
    );
    Logger.newLine();

    Logger.info('ℹ️  版本信息：');
    Logger.listItem('ming version                   # 显示基本版本', indent: 1);
    Logger.listItem('ming version --detailed        # 显示详细系统信息', indent: 1);
    Logger.newLine();
  }

  /// 显示获取更多帮助的信息
  static void _showMoreHelp() {
    Logger.subtitle('📚 社区与支持');
    Logger.info(
      '┌─────────────────────────────────────────────────────────────────┐',
    );
    Logger.info(
      '│ 🌟 项目主页: https://github.com/lgnorant-lu/Ming_Status_Cli    │',
    );
    Logger.info(
      '│ 📖 完整文档: https://github.com/lgnorant-lu/Ming_Status_Cli/wiki│',
    );
    Logger.info(
      '│ 🐛 问题反馈: https://github.com/lgnorant-lu/Ming_Status_Cli/issues│',
    );
    Logger.info(
      '│ 💬 讨论交流: https://github.com/lgnorant-lu/Ming_Status_Cli/discussions│',
    );
    Logger.info(
      '└─────────────────────────────────────────────────────────────────┘',
    );
    Logger.newLine();

    Logger.info('🎯 专业提示');
    Logger.info(
      '┌─────────────────────────────────────────────────────────────────┐',
    );
    Logger.info('│ • 使用 --verbose 获取详细执行信息                               │');
    Logger.info('│ • 使用 --help 查看任何命令的详细帮助                            │');
    Logger.info('│ • 首次使用建议运行 "ming doctor" 检查环境                       │');
    Logger.info('│ • 遇到问题？试试 "ming doctor --fix" 自动修复                   │');
    Logger.info(
      '└─────────────────────────────────────────────────────────────────┘',
    );
    Logger.newLine();

    Logger.info('✨ 感谢使用 Ming Status CLI - 让代码组织更简单！');
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
  static void formatOption(
    String option,
    String description, {
    String? defaultValue,
  }) {
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
