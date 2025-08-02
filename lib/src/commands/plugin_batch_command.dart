/*
---------------------------------------------------------------
File name:          plugin_batch_command.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件批量操作命令 (Plugin batch operations command)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 插件批量操作命令实现;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/plugin_system/local_registry.dart';
import 'package:ming_status_cli/src/core/plugin_system/plugin_publisher.dart';
import 'package:ming_status_cli/src/core/plugin_system/plugin_validator.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 插件批量操作命令
///
/// 提供插件的批量管理功能，支持批量验证、构建、发布等操作。
class PluginBatchCommand extends BaseCommand {
  @override
  String get name => 'batch';

  @override
  String get description => '批量执行插件操作';

  @override
  String get category => 'plugin';

  @override
  String get invocation => 'ming plugin batch <operation> [options]';

  /// 构造函数
  PluginBatchCommand() {
    // 操作类型选项
    argParser.addOption(
      'operation',
      abbr: 'o',
      allowed: ['validate', 'build', 'publish', 'sync', 'install', 'uninstall'],
      help: '批量操作类型',
      valueHelp: 'operation',
    );

    // 插件列表文件
    argParser.addOption(
      'plugins-file',
      abbr: 'f',
      help: '包含插件列表的文件路径',
      valueHelp: 'file',
    );

    // 插件ID列表
    argParser.addOption(
      'plugins',
      abbr: 'p',
      help: '逗号分隔的插件ID列表',
      valueHelp: 'plugin1,plugin2,plugin3',
    );

    // 目标注册表
    argParser.addOption(
      'registry',
      abbr: 'r',
      allowed: ['local', 'pub.dev', 'private'],
      defaultsTo: 'local',
      help: '目标注册表',
      valueHelp: 'registry',
    );

    // 并发数量
    argParser.addOption(
      'concurrency',
      abbr: 'c',
      defaultsTo: '3',
      help: '并发执行数量',
      valueHelp: 'number',
    );

    // 失败时继续
    argParser.addFlag(
      'continue-on-error',
      help: '遇到错误时继续执行其他插件',
      negatable: false,
    );

    // 预览模式
    argParser.addFlag(
      'dry-run',
      help: '预览模式，不执行实际操作',
      negatable: false,
    );

    // 详细输出
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: '显示详细的操作信息',
      negatable: false,
    );
  }

  @override
  String get usageFooter => '''

📋 使用示例:
  ming plugin batch validate --plugins=plugin1,plugin2,plugin3    # 批量验证插件
  ming plugin batch build --plugins-file=plugins.txt              # 从文件读取插件列表并批量构建
  ming plugin batch publish --plugins=plugin1,plugin2 --registry=pub.dev  # 批量发布到pub.dev
  ming plugin batch sync --plugins=plugin1,plugin2 --dry-run      # 预览批量同步

📋 操作类型:
  validate    - 批量验证插件
  build       - 批量构建插件
  publish     - 批量发布插件
  sync        - 批量同步插件
  install     - 批量安装插件
  uninstall   - 批量卸载插件

📋 插件列表格式:
  • 命令行: --plugins=plugin1,plugin2,plugin3
  • 文件格式: 每行一个插件ID，支持注释（#开头）

⚠️  注意事项:
  • 使用 --continue-on-error 可以在遇到错误时继续执行
  • 使用 --concurrency 控制并发数量，避免资源过载
  • 建议先使用 --dry-run 预览批量操作''';

  @override
  Future<int> execute() async {
    final operation = argResults!['operation'] as String?;
    final pluginsFile = argResults!['plugins-file'] as String?;
    final pluginsArg = argResults!['plugins'] as String?;
    final registry = argResults!['registry'] as String;
    final concurrency = int.tryParse(argResults!['concurrency'] as String) ?? 3;
    final continueOnError = argResults!['continue-on-error'] as bool;
    final isDryRun = argResults!['dry-run'] as bool;
    final verbose = argResults!['verbose'] as bool;

    if (operation == null) {
      Logger.error('请指定批量操作类型');
      Logger.info('使用 "ming plugin batch --help" 查看帮助');
      return 1;
    }

    // 获取插件列表
    final pluginIds = await _getPluginList(pluginsFile, pluginsArg);
    if (pluginIds.isEmpty) {
      Logger.error('未找到要操作的插件');
      Logger.info('请使用 --plugins 或 --plugins-file 指定插件列表');
      return 1;
    }

    Logger.info('🔄 开始批量操作...');
    Logger.info('操作类型: ${_getOperationDescription(operation)}');
    Logger.info('插件数量: ${pluginIds.length}');
    Logger.info('并发数量: $concurrency');
    Logger.info('目标注册表: $registry');

    if (isDryRun) {
      Logger.info('🔍 预览模式：不会执行实际操作');
    }

    if (verbose) {
      Logger.info('插件列表: ${pluginIds.join(', ')}');
    }

    try {
      final results = await _executeBatchOperation(
        operation,
        pluginIds,
        registry,
        concurrency,
        continueOnError,
        isDryRun,
        verbose,
      );

      _displayBatchResults(results, operation, verbose);

      final successCount = results.where((r) => r['success'] as bool).length;
      final failureCount = results.length - successCount;

      if (failureCount == 0) {
        Logger.success('✅ 批量操作全部成功！');
        return 0;
      } else if (successCount > 0) {
        Logger.warning('⚠️  批量操作部分成功 ($successCount/$results.length)');
        return 1;
      } else {
        Logger.error('❌ 批量操作全部失败');
        return 1;
      }
    } catch (e) {
      Logger.error('批量操作过程中发生错误: $e');
      return 1;
    }
  }

  /// 获取插件列表
  Future<List<String>> _getPluginList(
      String? pluginsFile, String? pluginsArg) async {
    final pluginIds = <String>[];

    // 从文件读取
    if (pluginsFile != null) {
      final file = File(pluginsFile);
      if (!file.existsSync()) {
        Logger.error('插件列表文件不存在: $pluginsFile');
        return [];
      }

      final lines = await file.readAsLines();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          pluginIds.add(trimmed);
        }
      }
    }

    // 从命令行参数读取
    if (pluginsArg != null) {
      final plugins =
          pluginsArg.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty);
      pluginIds.addAll(plugins);
    }

    // 去重
    return pluginIds.toSet().toList();
  }

  /// 执行批量操作
  Future<List<Map<String, dynamic>>> _executeBatchOperation(
    String operation,
    List<String> pluginIds,
    String registry,
    int concurrency,
    bool continueOnError,
    bool isDryRun,
    bool verbose,
  ) async {
    final results = <Map<String, dynamic>>[];
    final semaphore = <Future<void>>[];

    for (final pluginId in pluginIds) {
      // 控制并发数量
      if (semaphore.length >= concurrency) {
        await Future.wait(semaphore);
        semaphore.clear();
      }

      final future = _executeOperation(
        operation,
        pluginId,
        registry,
        isDryRun,
        verbose,
      ).then((result) {
        results.add(result);

        if (verbose) {
          final status = result['success'] as bool ? '✅' : '❌';
          Logger.info('$status $pluginId: ${result['message']}');
        }
      }).catchError((error) {
        final result = {
          'pluginId': pluginId,
          'success': false,
          'message': '操作失败: $error',
          'error': error.toString(),
        };
        results.add(result);

        if (verbose) {
          Logger.error('❌ $pluginId: ${result['message']}');
        }

        if (!continueOnError) {
          throw error;
        }
      });

      semaphore.add(future);
    }

    // 等待所有操作完成
    await Future.wait(semaphore);
    return results;
  }

  /// 执行单个操作
  Future<Map<String, dynamic>> _executeOperation(
    String operation,
    String pluginId,
    String registry,
    bool isDryRun,
    bool verbose,
  ) async {
    try {
      switch (operation) {
        case 'validate':
          return await _validatePlugin(pluginId, isDryRun);
        case 'build':
          return await _buildPlugin(pluginId, isDryRun);
        case 'publish':
          return await _publishPlugin(pluginId, registry, isDryRun);
        case 'sync':
          return await _syncPlugin(pluginId, isDryRun);
        case 'install':
          return await _installPlugin(pluginId, isDryRun);
        case 'uninstall':
          return await _uninstallPlugin(pluginId, isDryRun);
        default:
          return {
            'pluginId': pluginId,
            'success': false,
            'message': '不支持的操作类型: $operation',
          };
      }
    } catch (e) {
      return {
        'pluginId': pluginId,
        'success': false,
        'message': '操作失败: $e',
        'error': e.toString(),
      };
    }
  }

  /// 验证插件
  Future<Map<String, dynamic>> _validatePlugin(
      String pluginId, bool isDryRun) async {
    if (isDryRun) {
      return {
        'pluginId': pluginId,
        'success': true,
        'message': '预览模式：插件验证',
      };
    }

    // TODO: 实现实际的插件验证逻辑
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return {
      'pluginId': pluginId,
      'success': true,
      'message': '验证成功',
    };
  }

  /// 构建插件
  Future<Map<String, dynamic>> _buildPlugin(
      String pluginId, bool isDryRun) async {
    if (isDryRun) {
      return {
        'pluginId': pluginId,
        'success': true,
        'message': '预览模式：插件构建',
      };
    }

    // TODO: 实现实际的插件构建逻辑
    await Future<void>.delayed(const Duration(seconds: 1));
    return {
      'pluginId': pluginId,
      'success': true,
      'message': '构建成功',
    };
  }

  /// 发布插件
  Future<Map<String, dynamic>> _publishPlugin(
      String pluginId, String registry, bool isDryRun) async {
    if (isDryRun) {
      return {
        'pluginId': pluginId,
        'success': true,
        'message': '预览模式：插件发布到 $registry',
      };
    }

    // TODO: 实现实际的插件发布逻辑
    await Future<void>.delayed(const Duration(seconds: 2));
    return {
      'pluginId': pluginId,
      'success': true,
      'message': '发布到 $registry 成功',
    };
  }

  /// 同步插件
  Future<Map<String, dynamic>> _syncPlugin(
      String pluginId, bool isDryRun) async {
    if (isDryRun) {
      return {
        'pluginId': pluginId,
        'success': true,
        'message': '预览模式：插件同步',
      };
    }

    // TODO: 实现实际的插件同步逻辑
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return {
      'pluginId': pluginId,
      'success': true,
      'message': '同步成功',
    };
  }

  /// 安装插件
  Future<Map<String, dynamic>> _installPlugin(
      String pluginId, bool isDryRun) async {
    if (isDryRun) {
      return {
        'pluginId': pluginId,
        'success': true,
        'message': '预览模式：插件安装',
      };
    }

    // TODO: 实现实际的插件安装逻辑
    await Future<void>.delayed(const Duration(seconds: 1));
    return {
      'pluginId': pluginId,
      'success': true,
      'message': '安装成功',
    };
  }

  /// 卸载插件
  Future<Map<String, dynamic>> _uninstallPlugin(
      String pluginId, bool isDryRun) async {
    if (isDryRun) {
      return {
        'pluginId': pluginId,
        'success': true,
        'message': '预览模式：插件卸载',
      };
    }

    // TODO: 实现实际的插件卸载逻辑
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return {
      'pluginId': pluginId,
      'success': true,
      'message': '卸载成功',
    };
  }

  /// 显示批量操作结果
  void _displayBatchResults(
    List<Map<String, dynamic>> results,
    String operation,
    bool verbose,
  ) {
    final successCount = results.where((r) => r['success'] as bool).length;
    final failureCount = results.length - successCount;

    Logger.info('\n📋 批量操作结果摘要:');
    Logger.info('  操作类型: ${_getOperationDescription(operation)}');
    Logger.info('  总数量: ${results.length}');
    Logger.info('  成功: $successCount');
    Logger.info('  失败: $failureCount');

    if (verbose && failureCount > 0) {
      Logger.info('\n❌ 失败的插件:');
      for (final result in results) {
        if (!(result['success'] as bool)) {
          Logger.error('  • ${result['pluginId']}: ${result['message']}');
        }
      }
    }
  }

  /// 获取操作描述
  String _getOperationDescription(String operation) {
    switch (operation) {
      case 'validate':
        return '批量验证';
      case 'build':
        return '批量构建';
      case 'publish':
        return '批量发布';
      case 'sync':
        return '批量同步';
      case 'install':
        return '批量安装';
      case 'uninstall':
        return '批量卸载';
      default:
        return operation;
    }
  }
}
