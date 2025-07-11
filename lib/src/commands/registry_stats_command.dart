/*
---------------------------------------------------------------
File name:          registry_stats_command.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        注册表统计命令 (Registry Stats Command)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 远程模板生态建设;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/registry/registry_data_service.dart';
import 'package:ming_status_cli/src/core/registry/template_registry.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 注册表统计命令
///
/// 实现 `ming registry stats` 命令，显示注册表统计信息
class RegistryStatsCommand extends Command<int> {
  /// 创建注册表统计命令实例
  RegistryStatsCommand() {
    argParser
      ..addOption(
        'registry',
        abbr: 'r',
        help: '指定注册表ID',
      )
      ..addFlag(
        'detailed',
        abbr: 'd',
        help: '显示详细统计信息',
      )
      ..addFlag(
        'performance',
        abbr: 'p',
        help: '显示性能统计',
      )
      ..addFlag(
        'usage',
        abbr: 'u',
        help: '显示使用统计',
      );
  }

  @override
  String get name => 'stats';

  @override
  String get description => '显示注册表统计信息';

  @override
  String get usage => '''
使用方法:
  ming registry stats [选项]

示例:
  # 显示所有注册表统计
  ming registry stats

  # 显示指定注册表统计
  ming registry stats --registry=official

  # 显示详细统计信息
  ming registry stats --detailed

  # 显示性能和使用统计
  ming registry stats --performance --usage
''';

  @override
  Future<int> run() async {
    try {
      final registryId = argResults!['registry'] as String?;
      final detailed = argResults!['detailed'] as bool;
      final performance = argResults!['performance'] as bool;
      final usage = argResults!['usage'] as bool;

      cli_logger.Logger.info('获取注册表统计信息');

      // 初始化数据服务
      final dataService = RegistryDataService();
      await dataService.initialize();

      if (registryId != null) {
        await _displayRegistryStats(
            dataService, registryId, detailed, performance, usage,);
      } else {
        await _displayAllStats(dataService, detailed, performance, usage);
      }

      cli_logger.Logger.success('统计信息获取完成');
      return 0;
    } catch (e) {
      cli_logger.Logger.error('获取统计信息失败', error: e);
      return 1;
    }
  }

  /// 显示单个注册表统计
  Future<void> _displayRegistryStats(
    RegistryDataService dataService,
    String registryId,
    bool detailed,
    bool performance,
    bool usage,
  ) async {
    try {
      final detailedStats = dataService.getRegistryDetailedStats(registryId);

      print('\n📊 注册表统计: $registryId');
      print('─' * 60);

      // 基础统计
      print('📋 基础信息:');
      print('  • 模板总数: ${detailedStats.totalTemplates}');
      print('  • 活跃模板: ${detailedStats.activeTemplates}');
      print('  • 已弃用: ${detailedStats.deprecatedTemplates}');
      print('  • 索引大小: ${dataService.formatFileSize(detailedStats.indexSize)}');
      print(
          '  • 最后同步: ${dataService.formatTimeDifference(detailedStats.lastSync)}',);
      print('');
    } catch (e) {
      print('\n❌ 无法获取注册表统计信息: $registryId');
      print('错误: $e');
      return;
    }

    // 详细统计
    if (detailed) {
      final detailedStats = dataService.getRegistryDetailedStats(registryId);

      print('📈 详细统计:');
      print('  • 按复杂度分布:');
      detailedStats.complexityDistribution.forEach((key, value) {
        final percentage =
            (value / detailedStats.totalTemplates * 100).toStringAsFixed(1);
        print('    - ${_getComplexityName(key)}: $value ($percentage%)');
      });

      print('  • 按成熟度分布:');
      detailedStats.maturityDistribution.forEach((key, value) {
        final percentage =
            (value / detailedStats.totalTemplates * 100).toStringAsFixed(1);
        print('    - ${_getMaturityName(key)}: $value ($percentage%)');
      });

      print('  • 按平台分布:');
      detailedStats.platformDistribution.forEach((key, value) {
        final percentage =
            (value / detailedStats.totalTemplates * 100).toStringAsFixed(1);
        print('    - ${_getPlatformName(key)}: $value ($percentage%)');
      });
      print('');
    }

    // 性能统计
    if (performance) {
      final perfStats = dataService.getRegistryPerformanceStats(registryId);

      print('⚡ 性能统计:');
      print('  • 平均响应时间: ${perfStats.avgResponseTime}ms');
      print('  • 可用性: ${dataService.formatPercentage(perfStats.availability)}');
      print('  • 错误率: ${dataService.formatPercentage(perfStats.errorRate)}');
      print('  • 带宽使用: ${perfStats.dailyBandwidth.toStringAsFixed(1)}MB/天');
      print(
          '  • 缓存命中率: ${dataService.formatPercentage(perfStats.cacheHitRate)}',);
      print('');
    }

    // 使用统计
    if (usage) {
      final usageStats = dataService.getRegistryUsageStats(registryId);

      print('📈 使用统计:');
      print('  • 今日搜索: ${usageStats.todaySearches}次');
      print('  • 今日下载: ${usageStats.todayDownloads}次');
      print(
          '  • 热门模板: ${usageStats.popularTemplate} (${usageStats.popularTemplateDownloads}次)',);
      print('  • 活跃用户: ${usageStats.activeUsers}人');
      print('  • 峰值时段: ${usageStats.peakHours}');
      print('');
    }
  }

  /// 显示所有注册表统计
  Future<void> _displayAllStats(
    RegistryDataService dataService,
    bool detailed,
    bool performance,
    bool usage,
  ) async {
    final allStats = dataService.getAllRegistriesStats();

    print('\n📊 所有注册表统计');
    print('─' * 60);

    // 总体统计
    print('🌐 总体统计:');
    print('  • 注册表总数: ${allStats['totalRegistries']}');
    print('  • 模板总数: ${allStats['totalTemplates']}');
    print('  • 活跃注册表: ${allStats['activeRegistries']}');
    print(
      '  • 总索引大小: ${dataService.formatFileSize(allStats['totalIndexSize'] as double)}',
    );
    print('');

    // 各注册表概览
    final registries = dataService.getAllRegistries();

    print('📚 注册表概览:');
    for (final registry in registries) {
      if (registry.enabled) {
        final health = dataService.getRegistryHealth(registry.id);
        final statusIcon = health.status == RegistryStatus.healthy ? '✅' : '⚠️';
        final typeName = _getRegistryTypeName(registry.type);
        print('  $statusIcon $typeName: ${health.templateCount} 模板');
      }
    }
    print('');

    if (detailed || performance || usage) {
      print('💡 提示: 使用 --registry=<ID> 查看特定注册表的详细统计');
    }
  }

  /// 获取复杂度中文名称
  String _getComplexityName(String key) {
    switch (key) {
      case 'simple':
        return '简单';
      case 'medium':
        return '中等';
      case 'complex':
        return '复杂';
      case 'advanced':
        return '高级';
      default:
        return key;
    }
  }

  /// 获取成熟度中文名称
  String _getMaturityName(String key) {
    switch (key) {
      case 'stable':
        return '稳定';
      case 'beta':
        return 'Beta';
      case 'alpha':
        return 'Alpha';
      case 'experimental':
        return '实验性';
      default:
        return key;
    }
  }

  /// 获取平台中文名称
  String _getPlatformName(String key) {
    switch (key) {
      case 'mobile':
        return 'Mobile';
      case 'web':
        return 'Web';
      case 'desktop':
        return 'Desktop';
      case 'server':
        return 'Server';
      default:
        return key;
    }
  }

  /// 获取注册表类型中文名称
  String _getRegistryTypeName(RegistryType type) {
    switch (type) {
      case RegistryType.official:
        return '官方注册表';
      case RegistryType.community:
        return '社区注册表';
      case RegistryType.enterprise:
        return '企业注册表';
      case RegistryType.private:
        return '私有注册表';
    }
  }
}
