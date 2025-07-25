/*
---------------------------------------------------------------
File name:          plugin_command.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件管理主命令 (Plugin management main command)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 实现ming plugin命令系统;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/commands/plugin_batch_command.dart';
import 'package:ming_status_cli/src/commands/plugin_build_command.dart';
import 'package:ming_status_cli/src/commands/plugin_deps_command.dart';
import 'package:ming_status_cli/src/commands/plugin_install_command.dart';
import 'package:ming_status_cli/src/commands/plugin_list_command.dart';
import 'package:ming_status_cli/src/commands/plugin_publish_command.dart';
import 'package:ming_status_cli/src/commands/plugin_sync_command.dart';
import 'package:ming_status_cli/src/commands/plugin_validate_command.dart';

/// 插件管理主命令
///
/// 实现 `ming plugin` 命令及其所有子命令，提供完整的插件开发和管理功能。
///
/// ## 功能特性
/// - 插件验证和质量检查
/// - 插件构建和打包
/// - 插件发布和分发
/// - 本地插件管理
/// - Pet App V3集成支持
///
/// ## 子命令
/// - `validate` - 验证插件结构和清单
/// - `build` - 构建插件包
/// - `publish` - 发布插件到注册表
/// - `list` - 列出已安装插件
/// - `install` - 安装插件
///
/// ## 使用示例
/// ```bash
/// # 验证插件
/// ming plugin validate
///
/// # 构建插件
/// ming plugin build
///
/// # 发布插件
/// ming plugin publish --registry=local
///
/// # 列出插件
/// ming plugin list
/// ```
class PluginCommand extends Command<int> {
  /// 创建插件命令实例
  PluginCommand() {
    // 添加子命令
    addSubcommand(PluginValidateCommand());
    addSubcommand(PluginBuildCommand());
    addSubcommand(PluginPublishCommand());
    addSubcommand(PluginListCommand());
    addSubcommand(PluginInstallCommand());
    addSubcommand(PluginSyncCommand());
    addSubcommand(PluginDepsCommand());
    addSubcommand(PluginBatchCommand());
  }

  @override
  String get name => 'plugin';

  @override
  String get description => '插件开发和管理工具';

  @override
  String get invocation => 'ming plugin <子命令> [选项]';

  @override
  String get usage => '''
插件开发和管理工具

使用方法:
  ming plugin <子命令> [选项]

子命令:
  validate       验证插件结构和清单文件
  build          构建插件包
  publish        发布插件到注册表
  list           列出已安装的插件
  install        安装插件
  sync           同步插件到Pet App V3或从Pet App V3导入
  deps           分析和管理插件依赖关系
  batch          批量执行插件操作

选项:
  -h, --help     显示帮助信息
  -v, --verbose  显示详细输出

示例:
  # 验证当前目录的插件
  ming plugin validate

  # 构建插件包
  ming plugin build --output=./dist

  # 发布到本地注册表
  ming plugin publish --registry=local

  # 列出所有已安装插件
  ming plugin list

  # 安装插件
  ming plugin install my_plugin

  # 同步插件到Pet App V3
  ming plugin sync my_plugin

  # 从Pet App V3导入插件
  ming plugin sync my_plugin --direction=from-pet-app

  # 分析插件依赖
  ming plugin deps my_plugin

  # 批量验证插件
  ming plugin batch --operation=validate --plugins=plugin1,plugin2

更多信息:
  使用 'ming help plugin <子命令>' 查看详细文档
''';

  @override
  Future<int> run() async {
    // 如果没有提供子命令，显示帮助信息
    if (argResults?.arguments.isEmpty ?? true) {
      printUsage();
      return 0;
    }

    // 执行子命令
    return await super.run() ?? 0;
  }
}
