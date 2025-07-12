/*
---------------------------------------------------------------
File name:          registry_command.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        注册表管理命令 (Registry Management Command)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 远程模板生态建设;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/commands/registry_add_command.dart';
import 'package:ming_status_cli/src/commands/registry_list_command.dart';
import 'package:ming_status_cli/src/commands/registry_stats_command.dart';
import 'package:ming_status_cli/src/commands/registry_sync_command.dart';

/// 注册表管理命令
///
/// 实现 `ming registry` 命令，支持模板注册表管理功能
class RegistryCommand extends Command<int> {
  /// 创建注册表管理命令实例
  RegistryCommand() {
    // 添加子命令
    addSubcommand(RegistryAddCommand());
    addSubcommand(RegistryListCommand());
    addSubcommand(RegistrySyncCommand());
    addSubcommand(RegistryStatsCommand());
  }

  @override
  String get name => 'registry';

  @override
  String get description => '管理模板注册表';

  @override
  String get usage => '''
管理模板注册表

使用方法:
  ming registry <子命令> [选项]

子命令:
  add                    添加新的模板注册表
  list                   列出所有注册表
  sync                   同步注册表数据
  stats                  显示注册表统计信息

支持的注册表类型:
  • official   - 官方注册表
  • community  - 社区注册表
  • enterprise - 企业注册表
  • private    - 私有注册表

示例:
  # 添加不同类型的注册表
  ming registry add official https://templates.ming.dev --type=official
  ming registry add company https://templates.company.com --type=enterprise --auth-type=token --auth-token=xxx

  # 列出和过滤注册表
  ming registry list --type=official --health --performance
  ming registry list --enabled-only --detailed

  # 同步注册表数据
  ming registry sync --registry=official --incremental --verbose
  ming registry sync --parallel --force

  # 查看统计信息
  ming registry stats --registry=official --detailed --performance --usage
  ming registry stats --json

  # 查看子命令帮助
  ming registry <子命令> --help

更多信息:
  使用 'ming help registry' 查看详细文档
''';
}
