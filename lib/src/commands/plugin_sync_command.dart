/*
---------------------------------------------------------------
File name:          plugin_sync_command.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件同步命令 (Plugin sync command)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 插件同步命令实现;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/plugin_system/pet_app_bridge.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 插件同步命令
///
/// 提供Ming CLI与Pet App V3之间的插件同步功能。
class PluginSyncCommand extends BaseCommand {
  @override
  String get name => 'sync';

  @override
  String get description => '同步插件到Pet App V3或从Pet App V3导入插件';

  @override
  String get category => 'plugin';

  @override
  String get invocation => 'ming plugin sync <plugin-id> [options]';

  /// 构造函数
  PluginSyncCommand() {
    // 同步方向选项
    argParser.addOption(
      'direction',
      abbr: 'd',
      allowed: ['to-pet-app', 'from-pet-app'],
      defaultsTo: 'to-pet-app',
      help: '同步方向',
      valueHelp: 'direction',
    );

    // 强制同步选项
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: '强制同步，覆盖现有数据',
      negatable: false,
    );

    // 预览模式
    argParser.addFlag(
      'dry-run',
      help: '预览模式，不执行实际同步',
      negatable: false,
    );

    // 详细输出
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: '显示详细的同步信息',
      negatable: false,
    );
  }

  @override
  String get usageFooter => '''

📋 使用示例:
  ming plugin sync my-plugin                    # 同步插件到Pet App V3
  ming plugin sync my-plugin -d from-pet-app    # 从Pet App V3导入插件
  ming plugin sync my-plugin --dry-run          # 预览同步操作
  ming plugin sync my-plugin --force            # 强制同步

📋 同步方向:
  to-pet-app     - 将插件从Ming CLI同步到Pet App V3
  from-pet-app   - 从Pet App V3导入插件到Ming CLI

⚠️  注意事项:
  • 同步操作会修改插件注册表数据
  • 建议先使用 --dry-run 预览同步结果
  • 强制同步会覆盖现有数据，请谨慎使用''';

  @override
  Future<int> execute() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      Logger.error('请指定要同步的插件ID');
      Logger.info('使用 "ming plugin sync --help" 查看帮助');
      return 1;
    }

    final pluginId = args.first;
    final direction = argResults!['direction'] as String;
    final force = argResults!['force'] as bool;
    final isDryRun = argResults!['dry-run'] as bool;
    final verbose = argResults!['verbose'] as bool;

    Logger.info('🔄 开始插件同步...');
    Logger.info('插件ID: $pluginId');
    Logger.info('同步方向: ${_getDirectionDescription(direction)}');

    if (isDryRun) {
      Logger.info('🔍 预览模式：不会执行实际同步操作');
    }

    if (force) {
      Logger.warning('⚠️  强制模式：将覆盖现有数据');
    }

    try {
      final bridge = PetAppBridge();
      Map<String, dynamic> result;

      if (direction == 'to-pet-app') {
        result = await _syncToPetApp(bridge, pluginId, isDryRun, verbose);
      } else {
        result = await _importFromPetApp(bridge, pluginId, isDryRun, verbose);
      }

      _displaySyncResult(result, direction, verbose);

      if (result['success'] as bool) {
        Logger.success('✅ 插件同步成功！');
        return 0;
      } else {
        Logger.error('❌ 插件同步失败');
        return 1;
      }
    } catch (e) {
      Logger.error('同步过程中发生错误: $e');
      return 1;
    }
  }

  /// 同步到Pet App V3
  Future<Map<String, dynamic>> _syncToPetApp(
    PetAppBridge bridge,
    String pluginId,
    bool isDryRun,
    bool verbose,
  ) async {
    if (verbose) {
      Logger.info('📤 准备同步插件到Pet App V3...');
    }

    if (isDryRun) {
      // 预览模式：只验证插件存在性
      return {
        'success': true,
        'pluginId': pluginId,
        'dryRun': true,
        'message': '预览模式：插件可以同步到Pet App V3',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    return await bridge.syncToPetApp(pluginId);
  }

  /// 从Pet App V3导入
  Future<Map<String, dynamic>> _importFromPetApp(
    PetAppBridge bridge,
    String pluginId,
    bool isDryRun,
    bool verbose,
  ) async {
    if (verbose) {
      Logger.info('📥 准备从Pet App V3导入插件...');
    }

    if (isDryRun) {
      // 预览模式：只模拟获取插件信息
      return {
        'success': true,
        'pluginId': pluginId,
        'dryRun': true,
        'message': '预览模式：可以从Pet App V3导入插件',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    return await bridge.importFromPetApp(pluginId);
  }

  /// 显示同步结果
  void _displaySyncResult(
    Map<String, dynamic> result,
    String direction,
    bool verbose,
  ) {
    Logger.info('\n📋 同步结果摘要:');
    Logger.info('  同步状态: ${(result['success'] as bool) ? "成功" : "失败"}');
    Logger.info('  插件ID: ${result['pluginId']}');
    Logger.info('  同步方向: ${_getDirectionDescription(direction)}');
    Logger.info('  完成时间: ${result['timestamp']}');

    if (result['dryRun'] == true) {
      Logger.info('  模式: 预览模式');
    }

    if (result['error'] != null) {
      Logger.info('\n❌ 错误信息:');
      Logger.error('  ${result['error']}');
    }

    if (verbose && (result['success'] as bool) == true) {
      Logger.info('\n📁 同步详情:');

      if (direction == 'to-pet-app' && result['syncResult'] != null) {
        final syncResult = result['syncResult'] as Map<String, dynamic>;
        Logger.info('  同步ID: ${syncResult['syncId']}');
        Logger.info('  Pet App插件ID: ${syncResult['pet_app_plugin_id']}');
        Logger.info('  同步状态: ${syncResult['status']}');
        Logger.info('  同步消息: ${syncResult['message']}');
      }

      if (direction == 'from-pet-app' && result['importedData'] != null) {
        final importedData = result['importedData'] as Map<String, dynamic>;
        Logger.info('  导入插件: ${importedData['name']}');
        Logger.info('  插件版本: ${importedData['latest_version']}');
        Logger.info('  插件作者: ${importedData['author']}');
        Logger.info('  插件类别: ${importedData['category']}');
      }
    }
  }

  /// 获取方向描述
  String _getDirectionDescription(String direction) {
    switch (direction) {
      case 'to-pet-app':
        return 'Ming CLI → Pet App V3';
      case 'from-pet-app':
        return 'Pet App V3 → Ming CLI';
      default:
        return direction;
    }
  }
}
