/*
---------------------------------------------------------------
File name:          plugin_list_command.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件列表命令 (Plugin list command)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 实现插件列表功能;
---------------------------------------------------------------
*/

import 'dart:convert';

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/plugin_system/local_registry.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 插件列表命令
///
/// 列出已安装的插件。
class PluginListCommand extends BaseCommand {
  /// 创建插件列表命令实例
  PluginListCommand() {
    argParser
      ..addFlag(
        'all',
        abbr: 'a',
        help: '显示所有插件（包括禁用的）',
        defaultsTo: false,
      )
      ..addOption(
        'format',
        abbr: 'f',
        help: '输出格式',
        defaultsTo: 'table',
        allowed: ['table', 'json', 'yaml'],
      );
  }

  @override
  String get name => 'list';

  @override
  String get description => '列出已安装的插件';

  @override
  String get usage => '''
列出已安装的插件

使用方法:
  ming plugin list [选项]

选项:
  -a, --all              显示所有插件（包括禁用的）
  -f, --format=<格式>    输出格式 (默认: table, 允许: table, json, yaml)
  -v, --verbose          显示详细插件信息
  -h, --help             显示帮助信息

示例:
  # 列出已启用的插件
  ming plugin list

  # 列出所有插件
  ming plugin list --all

  # JSON格式输出
  ming plugin list --format=json

更多信息:
  使用 'ming help plugin list' 查看详细文档
''';

  @override
  Future<int> execute() async {
    final showAll = argResults!['all'] as bool;
    final format = argResults!['format'] as String;

    Logger.info('📋 列出已安装的插件...');
    Logger.debug('显示所有: $showAll');
    Logger.debug('输出格式: $format');

    try {
      // 创建本地注册表
      final localRegistry = LocalRegistry();

      // 获取插件列表
      final plugins = await localRegistry.listPlugins(
        installedOnly: !showAll,
      );

      if (plugins.isEmpty) {
        if (showAll) {
          Logger.info('本地注册表中没有任何插件');
        } else {
          Logger.info('没有已安装的插件');
        }
        Logger.info('使用 "ming plugin install <插件名>" 安装插件');
        return 0;
      }

      // 根据格式输出
      switch (format) {
        case 'json':
          _outputJson(plugins);
          break;
        case 'yaml':
          _outputYaml(plugins);
          break;
        case 'table':
        default:
          _outputTable(plugins, showAll);
          break;
      }

      // 显示统计信息
      if (verbose) {
        await _showStatistics(localRegistry);
      }

      return 0;
    } catch (e) {
      Logger.error('获取插件列表失败: $e');
      return 1;
    }
  }

  /// 表格格式输出
  void _outputTable(List<Map<String, dynamic>> plugins, bool showAll) {
    Logger.info('\n📦 插件列表:');
    Logger.info('');

    // 表头
    final header = showAll
        ? '名称                版本      状态    类别      描述'
        : '名称                版本      类别      描述';
    Logger.info(header);
    Logger.info('─' * header.length);

    // 插件行
    for (final plugin in plugins) {
      final name = _truncate(
          plugin['name'] as String? ?? plugin['id'] as String? ?? '未知', 18);
      final version = _truncate(plugin['latest_version'] as String? ?? '未知', 8);
      final category = _truncate(plugin['category'] as String? ?? '未知', 8);
      final description =
          _truncate(plugin['description'] as String? ?? '无描述', 30);

      if (showAll) {
        final status = (plugin['installed'] as bool? ?? false) ? '已安装' : '未安装';
        Logger.info('$name $version $status $category $description');
      } else {
        Logger.info('$name $version $category $description');
      }
    }

    Logger.info('');
    Logger.info('总计: ${plugins.length} 个插件');
  }

  /// JSON格式输出
  void _outputJson(List<Map<String, dynamic>> plugins) {
    final output = {
      'plugins': plugins,
      'total': plugins.length,
      'timestamp': DateTime.now().toIso8601String(),
    };

    print(jsonEncode(output));
  }

  /// YAML格式输出
  void _outputYaml(List<Map<String, dynamic>> plugins) {
    Logger.info('plugins:');
    for (final plugin in plugins) {
      Logger.info('  - id: ${plugin['id']}');
      Logger.info('    name: ${plugin['name']}');
      Logger.info('    version: ${plugin['latest_version']}');
      Logger.info('    category: ${plugin['category']}');
      Logger.info('    installed: ${plugin['installed']}');
      Logger.info('    description: ${plugin['description']}');
      Logger.info('');
    }
    Logger.info('total: ${plugins.length}');
  }

  /// 显示统计信息
  Future<void> _showStatistics(LocalRegistry localRegistry) async {
    try {
      final stats = await localRegistry.getStatistics();

      Logger.info('\n📊 注册表统计:');
      Logger.info('  总插件数: ${stats['total_plugins']}');
      Logger.info('  已安装: ${stats['installed_plugins']}');
      Logger.info('  总版本数: ${stats['total_versions']}');

      final categories = stats['categories'] as Map<String, dynamic>;
      if (categories.isNotEmpty) {
        Logger.info('  分类分布:');
        for (final entry in categories.entries) {
          Logger.info('    ${entry.key}: ${entry.value}');
        }
      }

      Logger.info('  注册表路径: ${stats['registry_path']}');
      Logger.info('  最后更新: ${stats['last_updated']}');
    } catch (e) {
      Logger.warning('获取统计信息失败: $e');
    }
  }

  /// 截断字符串
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text.padRight(maxLength);
    }
    return '${text.substring(0, maxLength - 3)}...';
  }
}
