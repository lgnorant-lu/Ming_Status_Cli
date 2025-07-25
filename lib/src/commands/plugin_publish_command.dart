/*
---------------------------------------------------------------
File name:          plugin_publish_command.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件发布命令 (Plugin publish command)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 实现插件发布功能;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/plugin_system/plugin_publisher.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 插件发布命令
///
/// 发布插件到注册表。
class PluginPublishCommand extends BaseCommand {
  /// 创建插件发布命令实例
  PluginPublishCommand() {
    argParser
      ..addOption(
        'registry',
        abbr: 'r',
        help: '目标注册表',
        defaultsTo: 'local',
        allowed: ['local', 'pub.dev', 'private'],
      )
      ..addFlag(
        'dry-run',
        help: '预览模式，不实际发布',
        defaultsTo: false,
      );
  }

  @override
  String get name => 'publish';

  @override
  String get description => '发布插件到注册表';

  @override
  String get usage => '''
发布插件到注册表

使用方法:
  ming plugin publish [选项]

选项:
  -r, --registry=<类型>  目标注册表 (默认: local, 允许: local, pub.dev, private)
      --dry-run          预览模式，不实际发布
  -v, --verbose          显示详细发布信息
  -h, --help             显示帮助信息

示例:
  # 发布到本地注册表
  ming plugin publish

  # 发布到pub.dev
  ming plugin publish --registry=pub.dev

  # 预览发布
  ming plugin publish --dry-run

更多信息:
  使用 'ming help plugin publish' 查看详细文档
''';

  @override
  Future<int> execute() async {
    final registry = argResults!['registry'] as String;
    final isDryRun = argResults!['dry-run'] as bool;

    Logger.info('📦 开始发布插件...');
    Logger.debug('目标注册表: $registry');
    Logger.debug('预览模式: $isDryRun');

    // 检查当前目录是否为插件项目
    final currentDir = Directory.current.path;
    final pluginYamlFile = File('$currentDir/plugin.yaml');
    final pubspecYamlFile = File('$currentDir/pubspec.yaml');

    if (!pluginYamlFile.existsSync() || !pubspecYamlFile.existsSync()) {
      Logger.error('当前目录不是有效的插件项目');
      Logger.info('请确保当前目录包含 plugin.yaml 和 pubspec.yaml 文件');
      return 1;
    }

    try {
      // 创建插件发布器
      final publisher = PluginPublisher();

      // 执行发布
      final result = await publisher.publishPlugin(
        currentDir,
        registry: registry,
        isDryRun: isDryRun,
      );

      // 显示发布结果
      _displayPublishResult(result);

      if (result.isSuccess) {
        if (isDryRun) {
          Logger.success('✅ 插件发布预览完成！');
        } else {
          Logger.success('✅ 插件发布成功！');
          Logger.info('📦 插件ID: ${result.pluginId}');
          Logger.info('🏷️  版本: ${result.version}');
          Logger.info('📍 注册表: ${result.registry}');
        }
        return 0;
      } else {
        Logger.error('❌ 插件发布失败');
        return 1;
      }
    } catch (e) {
      Logger.error('发布过程中发生错误: $e');
      return 1;
    }
  }

  /// 显示发布结果
  void _displayPublishResult(PluginPublishResult result) {
    Logger.info('\n📋 发布结果摘要:');
    Logger.info('  发布状态: ${result.isSuccess ? "成功" : "失败"}');
    Logger.info('  插件ID: ${result.pluginId ?? "未知"}');
    Logger.info('  版本: ${result.version ?? "未知"}');
    Logger.info('  注册表: ${result.registry}');

    if (result.errors.isNotEmpty) {
      Logger.info('\n❌ 错误:');
      for (final error in result.errors) {
        Logger.error('  • $error');
      }
    }

    if (result.warnings.isNotEmpty) {
      Logger.info('\n⚠️  警告:');
      for (final warning in result.warnings) {
        Logger.warning('  • $warning');
      }
    }

    if (verbose && result.details.isNotEmpty) {
      Logger.info('\n📁 发布详情:');
      final details = result.details;
      if (details.containsKey('packagePath')) {
        Logger.info('  • 插件包: ${details['packagePath']}');
      }
      if (details.containsKey('dryRun') && details['dryRun'] == true) {
        Logger.info('  • 预览模式: 未实际发布');
      }
    }
  }
}
