/*
---------------------------------------------------------------
File name:          template_update_command.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板更新命令 (Template Update Command)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 Week 2 智能搜索和分发系统;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/distribution/dependency_resolver.dart';
import 'package:ming_status_cli/src/core/distribution/update_manager.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板更新命令
///
/// 实现 `ming template update` 命令，支持模板更新管理
class TemplateUpdateCommand extends Command<int> {
  /// 创建模板更新命令实例
  TemplateUpdateCommand() {
    argParser
      ..addOption(
        'template',
        abbr: 't',
        help: '指定要更新的模板名称',
      )
      ..addOption(
        'version',
        abbr: 'v',
        help: '指定目标版本',
      )
      ..addOption(
        'strategy',
        abbr: 's',
        help: '更新策略',
        allowed: [
          'automatic',
          'security-only',
          'manual',
          'conservative',
          'aggressive',
        ],
        defaultsTo: 'manual',
      )
      ..addFlag(
        'check-only',
        abbr: 'c',
        help: '仅检查可用更新，不执行更新',
      )
      ..addFlag(
        'include-prerelease',
        help: '包含预发布版本',
      )
      ..addFlag(
        'create-snapshot',
        help: '更新前创建快照',
        defaultsTo: true,
      )
      ..addFlag(
        'batch',
        abbr: 'b',
        help: '批量更新所有模板',
      )
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help: '仅显示更新计划，不执行实际更新',
      )
      ..addFlag(
        'verbose',
        help: '显示详细更新过程',
      );
  }

  @override
  String get name => 'update';

  @override
  String get description => '更新模板';

  @override
  String get usage => '''
使用方法:
  ming template update [模板名称] [选项]

🔄 Phase 2.2 Week 2: 更新管理和缓存策略

更新选项:
  --template=<名称>     指定要更新的模板
  --version=<版本>      指定目标版本 (默认: 最新版本)
  --strategy=<策略>     更新策略 (automatic, security-only, manual, conservative, aggressive)

更新控制:
  --check-only         仅检查可用更新，不执行更新
  --include-prerelease 包含预发布版本
  --create-snapshot    更新前创建快照 (默认: 启用)
  --batch              批量更新所有模板
  --dry-run            仅显示更新计划，不执行实际更新
  --verbose            显示详细更新过程

示例:
  # 检查所有可用更新
  ming template update --check-only

  # 更新指定模板
  ming template update --template=flutter_clean_app

  # 更新到指定版本
  ming template update --template=react_dashboard --version=2.1.0

  # 批量更新所有模板
  ming template update --batch --strategy=conservative

  # 包含预发布版本的更新检查
  ming template update --check-only --include-prerelease

  # 安全更新策略
  ming template update --batch --strategy=security-only --verbose

  # 预览更新计划
  ming template update --template=vue_component --dry-run --verbose
''';

  @override
  Future<int> run() async {
    try {
      final templateName = argResults!['template'] as String?;
      final targetVersion = argResults!['version'] as String?;
      final strategy = argResults!['strategy'] as String;
      final checkOnly = argResults!['check-only'] as bool;
      final includePrerelease = argResults!['include-prerelease'] as bool;
      final createSnapshot = argResults!['create-snapshot'] as bool;
      final batch = argResults!['batch'] as bool;
      final dryRun = argResults!['dry-run'] as bool;
      final verbose = argResults!['verbose'] as bool;

      cli_logger.Logger.info('开始模板更新操作');

      // 创建更新管理器
      final updateManager = UpdateManager(
        config: UpdateConfig(
          strategy: UpdateStrategy.values.byName(strategy.replaceAll('-', '_')),
          createSnapshot: createSnapshot,
        ),
      );

      if (checkOnly) {
        // 仅检查更新
        await _checkForUpdates(
            updateManager, templateName, includePrerelease, verbose,);
      } else if (batch) {
        // 批量更新
        await _performBatchUpdate(updateManager, dryRun, verbose);
      } else if (templateName != null) {
        // 单个模板更新
        await _performSingleUpdate(
          updateManager,
          templateName,
          targetVersion,
          dryRun,
          verbose,
        );
      } else {
        print('错误: 需要指定模板名称或使用 --batch 选项');
        print(
            '使用方法: ming template update --template=<名称> 或 ming template update --batch',);
        return 1;
      }

      cli_logger.Logger.success('模板更新操作完成');
      return 0;
    } catch (e) {
      cli_logger.Logger.error('模板更新失败', error: e);
      return 1;
    }
  }

  /// 检查可用更新
  Future<void> _checkForUpdates(
    UpdateManager updateManager,
    String? templateName,
    bool includePrerelease,
    bool verbose,
  ) async {
    print('\n🔍 检查可用更新...');

    final updates = await updateManager.checkForUpdates(
      templateNames: templateName != null ? [templateName] : null,
      includePrerelease: includePrerelease,
    );

    if (updates.isEmpty) {
      print('✅ 所有模板都是最新版本');
      return;
    }

    print('\n📋 发现 ${updates.length} 个可用更新:');
    print('─' * 80);

    for (final update in updates) {
      _displayUpdateInfo(update, verbose);
    }

    // 显示更新统计
    _displayUpdateSummary(updates);
  }

  /// 执行单个模板更新
  Future<void> _performSingleUpdate(
    UpdateManager updateManager,
    String templateName,
    String? targetVersion,
    bool dryRun,
    bool verbose,
  ) async {
    print('\n🔄 更新模板: $templateName');

    if (dryRun) {
      print('📋 更新计划 (预览模式):');
      print('  模板: $templateName');
      print('  目标版本: ${targetVersion ?? '最新版本'}');
      print('  创建快照: 是');
      print('  验证签名: 是');
      print('');
      print('✅ 预览完成，未执行实际更新操作');
      return;
    }

    // 执行更新
    await updateManager.performUpdate(
      templateName,
      targetVersion:
          targetVersion != null ? Version.parse(targetVersion) : null,
      dryRun: dryRun,
      onProgress: (progress) {
        _displayUpdateProgress(progress, verbose);
      },
    );

    print('\n✅ 模板更新完成: $templateName');
  }

  /// 执行批量更新
  Future<void> _performBatchUpdate(
    UpdateManager updateManager,
    bool dryRun,
    bool verbose,
  ) async {
    print('\n🔄 批量更新所有模板...');

    // 检查可用更新
    final updates = await updateManager.checkForUpdates();

    if (updates.isEmpty) {
      print('✅ 所有模板都是最新版本');
      return;
    }

    final templateNames = updates.map((u) => u.templateName).toList();

    if (dryRun) {
      print('📋 批量更新计划 (预览模式):');
      for (final update in updates) {
        print(
            '  • ${update.templateName}: ${update.currentVersion} → ${update.availableVersion}',);
      }
      print('');
      print('✅ 预览完成，未执行实际更新操作');
      return;
    }

    // 执行批量更新
    await updateManager.performBatchUpdate(
      templateNames,
      dryRun: dryRun,
      onProgress: (templateName, progress) {
        print('[$templateName] ${progress.currentStep}');
        if (verbose) {
          _displayUpdateProgress(progress, false);
        }
      },
    );

    print('\n✅ 批量更新完成，共更新 ${templateNames.length} 个模板');
  }

  /// 显示更新信息
  void _displayUpdateInfo(UpdateInfo update, bool verbose) {
    final updateTypeIcon = _getUpdateTypeIcon(update.updateType);
    final securityIcon = update.isSecurityUpdate ? '🔒' : '';

    print('$updateTypeIcon $securityIcon ${update.templateName}');
    print('  当前版本: ${update.currentVersion}');
    print('  可用版本: ${update.availableVersion}');
    print('  更新类型: ${_getUpdateTypeDescription(update.updateType)}');
    print('  更新大小: ${_formatFileSize(update.updateSize)}');
    print('  发布时间: ${_formatDate(update.releaseDate)}');

    if (verbose) {
      print('  描述: ${update.description}');
      if (update.changelog.isNotEmpty) {
        print('  变更日志:');
        for (final change in update.changelog) {
          print('    • $change');
        }
      }
      if (update.compatibility.isNotEmpty) {
        print('  兼容性:');
        update.compatibility.forEach((platform, compatible) {
          final icon = compatible ? '✅' : '❌';
          print('    $icon $platform');
        });
      }
    }

    print('');
  }

  /// 显示更新进度
  void _displayUpdateProgress(UpdateProgress progress, bool verbose) {
    final statusIcon = _getStatusIcon(progress.status);

    if (verbose) {
      print(
          '$statusIcon [${progress.percentage.toStringAsFixed(1)}%] ${progress.currentStep}',);
      if (progress.estimatedRemainingTime != null) {
        print(
            '  剩余时间: ${_formatDuration(Duration(seconds: progress.estimatedRemainingTime!))}',);
      }
      if (progress.error != null) {
        print('  错误: ${progress.error}');
      }
    } else {
      _showProgressBar(progress.percentage, progress.currentStep);
    }
  }

  /// 显示更新统计
  void _displayUpdateSummary(List<UpdateInfo> updates) {
    print('\n📊 更新统计:');
    print('─' * 40);

    final majorUpdates =
        updates.where((u) => u.updateType == UpdateType.major).length;
    final minorUpdates =
        updates.where((u) => u.updateType == UpdateType.minor).length;
    final patchUpdates =
        updates.where((u) => u.updateType == UpdateType.patch).length;
    final securityUpdates = updates.where((u) => u.isSecurityUpdate).length;

    print('总更新数: ${updates.length}');
    print('主版本更新: $majorUpdates');
    print('次版本更新: $minorUpdates');
    print('修订版本更新: $patchUpdates');
    print('安全更新: $securityUpdates');

    final totalSize = updates.fold(0, (sum, update) => sum + update.updateSize);
    print('总下载大小: ${_formatFileSize(totalSize)}');
  }

  /// 获取更新类型图标
  String _getUpdateTypeIcon(UpdateType type) {
    switch (type) {
      case UpdateType.major:
        return '🔴'; // 主版本更新 (破坏性)
      case UpdateType.minor:
        return '🟡'; // 次版本更新 (新功能)
      case UpdateType.patch:
        return '🟢'; // 修订版本更新 (bug修复)
      case UpdateType.prerelease:
        return '🔵'; // 预发布版本
    }
  }

  /// 获取更新类型描述
  String _getUpdateTypeDescription(UpdateType type) {
    switch (type) {
      case UpdateType.major:
        return '主版本更新 (可能包含破坏性变更)';
      case UpdateType.minor:
        return '次版本更新 (新功能)';
      case UpdateType.patch:
        return '修订版本更新 (bug修复)';
      case UpdateType.prerelease:
        return '预发布版本';
    }
  }

  /// 获取状态图标
  String _getStatusIcon(UpdateStatus status) {
    switch (status) {
      case UpdateStatus.checking:
        return '🔍';
      case UpdateStatus.downloading:
        return '📥';
      case UpdateStatus.installing:
        return '⚙️';
      case UpdateStatus.completed:
        return '✅';
      case UpdateStatus.failed:
        return '❌';
      case UpdateStatus.rolling_back:
        return '↩️';
      case UpdateStatus.rolled_back:
        return '🔄';
      default:
        return '⏳';
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).round()}周前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}秒';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}分钟';
    } else {
      return '${duration.inHours}小时${duration.inMinutes % 60}分钟';
    }
  }

  /// 显示进度条
  void _showProgressBar(double percentage, String step) {
    const barLength = 30;
    final filledLength = (barLength * percentage / 100).round();
    final bar = '█' * filledLength + '░' * (barLength - filledLength);
    print('\r[$bar] ${percentage.toStringAsFixed(1)}% - $step');
  }
}
