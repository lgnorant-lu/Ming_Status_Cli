/*
---------------------------------------------------------------
File name:          plugin_install_command.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件安装命令 (Plugin install command)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 实现插件安装功能;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/plugin_system/local_registry.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 插件安装命令
///
/// 安装插件。
class PluginInstallCommand extends BaseCommand {
  /// 创建插件安装命令实例
  PluginInstallCommand() {
    argParser
      ..addOption(
        'version',
        abbr: 'v',
        help: '指定插件版本',
      )
      ..addOption(
        'registry',
        abbr: 'r',
        help: '源注册表',
        defaultsTo: 'local',
        allowed: ['local', 'pub.dev', 'private'],
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: '强制安装（覆盖已存在的插件）',
        defaultsTo: false,
      );
  }

  @override
  String get name => 'install';

  @override
  String get description => '安装插件';

  @override
  String get usage => '''
安装插件

使用方法:
  ming plugin install <插件名称> [选项]

参数:
  <插件名称>             要安装的插件名称

选项:
  -v, --version=<版本>   指定插件版本
  -r, --registry=<类型>  源注册表 (默认: local, 允许: local, pub.dev, private)
  -f, --force            强制安装（覆盖已存在的插件）
      --verbose          显示详细安装信息
  -h, --help             显示帮助信息

示例:
  # 安装插件
  ming plugin install my_plugin

  # 安装指定版本
  ming plugin install my_plugin --version=1.0.0

  # 从pub.dev安装
  ming plugin install my_plugin --registry=pub.dev

  # 强制安装
  ming plugin install my_plugin --force

更多信息:
  使用 'ming help plugin install' 查看详细文档
''';

  @override
  Future<int> execute() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      Logger.error('请指定要安装的插件名称');
      Logger.info('使用 "ming plugin install --help" 查看帮助');
      return 1;
    }

    final pluginName = args.first;
    final version = argResults!['version'] as String?;
    final registry = argResults!['registry'] as String;
    final force = argResults!['force'] as bool;

    Logger.info('📦 开始安装插件: $pluginName');
    Logger.debug('版本: ${version ?? "最新"}');
    Logger.debug('注册表: $registry');
    Logger.debug('强制安装: $force');

    try {
      // 创建本地注册表
      final localRegistry = LocalRegistry();

      // 检查插件是否存在
      final pluginInfo = await localRegistry.getPlugin(pluginName);
      if (pluginInfo == null) {
        Logger.error('插件 "$pluginName" 不存在于本地注册表中');
        Logger.info('使用 "ming plugin list --all" 查看可用插件');
        Logger.info('或使用 "ming plugin publish" 先发布插件到本地注册表');
        return 1;
      }

      // 检查是否已安装
      final isInstalled = pluginInfo['installed'] as bool? ?? false;
      if (isInstalled && !force) {
        Logger.warning('插件 "$pluginName" 已安装');
        Logger.info('使用 --force 强制重新安装');
        return 0;
      }

      // 执行安装
      await localRegistry.installPlugin(pluginName, version: version);

      // 显示安装结果
      final installedVersion =
          version ?? pluginInfo['latest_version'] as String;
      Logger.success('✅ 插件安装成功！');
      Logger.info('📦 插件名称: $pluginName');
      Logger.info('🏷️  安装版本: $installedVersion');
      Logger.info('📍 注册表: $registry');

      if (verbose) {
        _showPluginDetails(pluginInfo);
      }

      return 0;
    } catch (e) {
      Logger.error('插件安装失败: $e');
      return 1;
    }
  }

  /// 显示插件详细信息
  void _showPluginDetails(Map<String, dynamic> pluginInfo) {
    Logger.info('\n📋 插件详情:');
    Logger.info('  ID: ${pluginInfo['id']}');
    Logger.info('  名称: ${pluginInfo['name']}');
    Logger.info('  描述: ${pluginInfo['description']}');
    Logger.info('  作者: ${pluginInfo['author']}');
    Logger.info('  类别: ${pluginInfo['category']}');

    final versions = pluginInfo['versions'] as Map<String, dynamic>;
    Logger.info('  可用版本: ${versions.keys.join(', ')}');
    Logger.info('  最新版本: ${pluginInfo['latest_version']}');
    Logger.info('  创建时间: ${pluginInfo['created']}');
  }
}
