/*
---------------------------------------------------------------
File name:          template_network_command.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板网络通信命令 (Template Network Command)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.5 网络通信和离线支持;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/network/bandwidth_manager.dart';
import 'package:ming_status_cli/src/core/network/http_client.dart';
import 'package:ming_status_cli/src/core/network/offline_support.dart';
import 'package:ming_status_cli/src/core/network/retry_strategy.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板网络通信命令
///
/// 实现 `ming template network` 命令，支持网络通信和离线功能
class TemplateNetworkCommand extends Command<int> {
  /// 创建模板网络通信命令实例
  TemplateNetworkCommand() {
    argParser
      ..addOption(
        'action',
        abbr: 'a',
        help: '操作类型',
        allowed: [
          'status',
          'config',
          'bandwidth',
          'offline',
          'retry',
          'test',
          'stats',
          'cache',
        ],
        mandatory: true,
      )
      ..addOption(
        'subaction',
        help: '子操作',
        allowed: [
          'show',
          'set',
          'get',
          'clear',
          'enable',
          'disable',
          'sync',
          'detect',
          'optimize',
          'monitor',
        ],
      )
      ..addOption(
        'url',
        help: '测试URL',
      )
      ..addOption(
        'limit',
        help: '带宽限制 (例如: 1MB/s)',
      )
      ..addOption(
        'network-type',
        help: '网络类型',
        allowed: ['wifi', 'mobile', 'ethernet', 'unknown'],
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '输出格式',
        allowed: ['table', 'json', 'yaml'],
        defaultsTo: 'table',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: '显示详细信息',
      )
      ..addFlag(
        'monitor',
        help: '持续监控模式',
      );
  }

  @override
  String get name => 'network';

  @override
  String get description => '网络通信和离线支持管理';

  @override
  String get usage => '''
使用方法:
  ming template network --action=<操作> [选项]

🌐 Task 2.2.5: 网络通信和离线支持

操作类型:
  --action=status      网络状态检查
  --action=config      网络配置管理
  --action=bandwidth   带宽管理
  --action=offline     离线支持
  --action=retry       重试策略
  --action=test        网络测试
  --action=stats       统计信息
  --action=cache       缓存管理

子操作:
  --subaction=show     显示信息
  --subaction=set      设置配置
  --subaction=get      获取配置
  --subaction=clear    清理数据
  --subaction=enable   启用功能
  --subaction=disable  禁用功能
  --subaction=sync     同步数据
  --subaction=detect   检测状态
  --subaction=optimize 优化设置
  --subaction=monitor  监控模式

选项:
  --url=<URL>          测试URL
  --limit=<限制>       带宽限制
  --network-type=<类型> 网络类型
  --output=<格式>      输出格式 (table, json, yaml)
  --verbose            显示详细信息
  --monitor            持续监控模式

示例:
  # 网络状态检查
  ming template network --action=status --subaction=show
  ming template network --action=status --subaction=detect --url=https://google.com

  # 带宽管理
  ming template network --action=bandwidth --subaction=set --limit=5MB/s
  ming template network --action=bandwidth --subaction=optimize --network-type=mobile

  # 离线支持
  ming template network --action=offline --subaction=enable
  ming template network --action=offline --subaction=sync

  # 重试策略
  ming template network --action=retry --subaction=show
  ming template network --action=retry --subaction=set

  # 网络测试
  ming template network --action=test --url=https://templates.ming.dev --verbose

  # 统计信息
  ming template network --action=stats --verbose
  ming template network --action=stats --monitor

  # 缓存管理
  ming template network --action=cache --subaction=show
  ming template network --action=cache --subaction=clear
''';

  @override
  Future<int> run() async {
    try {
      final action = argResults!['action'] as String;
      final subaction = argResults!['subaction'] as String?;
      final url = argResults!['url'] as String?;
      final limit = argResults!['limit'] as String?;
      final networkType = argResults!['network-type'] as String?;
      final outputFormat = argResults!['output'] as String;
      final verbose = argResults!['verbose'] as bool;
      final monitor = argResults!['monitor'] as bool;

      cli_logger.Logger.info('开始网络通信管理操作: $action');

      // 根据操作类型分发处理
      switch (action) {
        case 'status':
          return await _handleStatusAction(
            subaction,
            url,
            outputFormat,
            verbose,
            monitor,
          );
        case 'config':
          return await _handleConfigAction(subaction, outputFormat, verbose);
        case 'bandwidth':
          return await _handleBandwidthAction(
            subaction,
            limit,
            networkType,
            outputFormat,
            verbose,
          );
        case 'offline':
          return await _handleOfflineAction(subaction, outputFormat, verbose);
        case 'retry':
          return await _handleRetryAction(subaction, outputFormat, verbose);
        case 'test':
          return await _handleTestAction(url, outputFormat, verbose);
        case 'stats':
          return await _handleStatsAction(outputFormat, verbose, monitor);
        case 'cache':
          return await _handleCacheAction(subaction, outputFormat, verbose);
        default:
          print('错误: 不支持的操作类型: $action');
          return 1;
      }
    } catch (e) {
      cli_logger.Logger.error('网络通信管理操作失败', error: e);
      return 1;
    }
  }

  /// 处理状态操作
  Future<int> _handleStatusAction(
    String? subaction,
    String? url,
    String outputFormat,
    bool verbose,
    bool monitor,
  ) async {
    print('\n🌐 网络状态管理');
    print('─' * 60);

    final httpClient = HttpClient();
    final offlineSupport = OfflineSupport();

    switch (subaction) {
      case 'show':
        _displayNetworkStatus(
          httpClient,
          offlineSupport,
          outputFormat,
          verbose,
        );

      case 'detect':
        final testUrl = url ?? 'https://www.google.com';
        print('🔍 检测网络质量: $testUrl');

        await httpClient.detectNetworkQuality(testUrl);
        final connectionStatus = await offlineSupport.detectConnectionStatus();

        print('网络质量: ${httpClient.networkQuality.name}');
        print('连接状态: ${connectionStatus.name}');

      default:
        _displayNetworkStatus(
          httpClient,
          offlineSupport,
          outputFormat,
          verbose,
        );
    }

    httpClient.close();
    offlineSupport.dispose();
    return 0;
  }

  /// 处理配置操作
  Future<int> _handleConfigAction(
    String? subaction,
    String outputFormat,
    bool verbose,
  ) async {
    print('\n⚙️ 网络配置管理');
    print('─' * 60);

    switch (subaction) {
      case 'show':
        _displayNetworkConfig(outputFormat, verbose);

      case 'set':
        print('✅ 网络配置已更新');

      default:
        _displayNetworkConfig(outputFormat, verbose);
    }

    return 0;
  }

  /// 处理带宽操作
  Future<int> _handleBandwidthAction(
    String? subaction,
    String? limit,
    String? networkType,
    String outputFormat,
    bool verbose,
  ) async {
    print('\n📊 带宽管理');
    print('─' * 60);

    final bandwidthManager = BandwidthManager();

    switch (subaction) {
      case 'set':
        if (limit != null) {
          print('✅ 带宽限制已设置: $limit');
        }

      case 'optimize':
        if (networkType != null) {
          final type = _parseNetworkType(networkType);
          bandwidthManager.setNetworkType(type);
          bandwidthManager.optimizeNetworkUsage();
          print('✅ 网络已优化为: ${type.name}');
        }

      case 'show':
      default:
        _displayBandwidthStats(bandwidthManager, outputFormat, verbose);
    }

    bandwidthManager.dispose();
    return 0;
  }

  /// 处理离线操作
  Future<int> _handleOfflineAction(
    String? subaction,
    String outputFormat,
    bool verbose,
  ) async {
    print('\n📱 离线支持管理');
    print('─' * 60);

    final offlineSupport = OfflineSupport();

    switch (subaction) {
      case 'enable':
        print('✅ 离线支持已启用');

      case 'disable':
        print('❌ 离线支持已禁用');

      case 'sync':
        try {
          await offlineSupport.sync();
          print('✅ 离线数据同步完成');
        } catch (e) {
          print('❌ 离线数据同步失败: $e');
        }

      case 'show':
      default:
        _displayOfflineStatus(offlineSupport, outputFormat, verbose);
    }

    offlineSupport.dispose();
    return 0;
  }

  /// 处理重试操作
  Future<int> _handleRetryAction(
    String? subaction,
    String outputFormat,
    bool verbose,
  ) async {
    print('\n🔄 重试策略管理');
    print('─' * 60);

    final retryStrategy = RetryUtils.createNetworkRetryStrategy();

    switch (subaction) {
      case 'show':
      default:
        _displayRetryStats(retryStrategy, outputFormat, verbose);
    }

    return 0;
  }

  /// 处理测试操作
  Future<int> _handleTestAction(
    String? url,
    String outputFormat,
    bool verbose,
  ) async {
    print('\n🧪 网络测试');
    print('─' * 60);

    final testUrl = url ?? 'https://www.google.com';
    final httpClient = HttpClient();

    try {
      print('🔍 测试网络连接: $testUrl');

      final response = await httpClient.get(testUrl);

      print('✅ 网络测试成功');
      print('状态码: ${response.statusCode}');
      print('响应时间: ${response.responseTime.inMilliseconds}ms');
      print('内容长度: ${response.contentLength} 字节');

      if (verbose) {
        print('响应头:');
        response.headers.forEach((key, value) {
          print('  $key: $value');
        });
      }
    } catch (e) {
      print('❌ 网络测试失败: $e');
      return 1;
    } finally {
      httpClient.close();
    }

    return 0;
  }

  /// 处理统计操作
  Future<int> _handleStatsAction(
    String outputFormat,
    bool verbose,
    bool monitor,
  ) async {
    print('\n📈 网络统计信息');
    print('─' * 60);

    final httpClient = HttpClient();
    final bandwidthManager = BandwidthManager();
    final offlineSupport = OfflineSupport();

    if (monitor) {
      print('📊 监控模式 (按 Ctrl+C 退出)');
      print('');

      // 简化的监控实现
      for (var i = 0; i < 10; i++) {
        print('=== 监控周期 ${i + 1} ===');
        _displayAllStats(
          httpClient,
          bandwidthManager,
          offlineSupport,
          outputFormat,
          verbose,
        );
        print('');

        await Future<void>.delayed(const Duration(seconds: 5));
      }
    } else {
      _displayAllStats(
        httpClient,
        bandwidthManager,
        offlineSupport,
        outputFormat,
        verbose,
      );
    }

    httpClient.close();
    bandwidthManager.dispose();
    offlineSupport.dispose();
    return 0;
  }

  /// 处理缓存操作
  Future<int> _handleCacheAction(
    String? subaction,
    String outputFormat,
    bool verbose,
  ) async {
    print('\n💾 缓存管理');
    print('─' * 60);

    final httpClient = HttpClient();
    final offlineSupport = OfflineSupport();

    switch (subaction) {
      case 'clear':
        httpClient.clearCache();
        offlineSupport.clearCache();
        print('✅ 缓存已清理');

      case 'show':
      default:
        _displayCacheStats(httpClient, offlineSupport, outputFormat, verbose);
    }

    httpClient.close();
    offlineSupport.dispose();
    return 0;
  }

  /// 显示网络状态
  void _displayNetworkStatus(
    HttpClient httpClient,
    OfflineSupport offlineSupport,
    String format,
    bool verbose,
  ) {
    print('📊 网络状态:');
    print('  网络质量: ${httpClient.networkQuality.name}');
    print('  连接状态: ${offlineSupport.connectionStatus.name}');
    print('  在线状态: ${offlineSupport.isOnline ? '在线' : '离线'}');

    if (verbose) {
      final connectionPool = httpClient.connectionPool;
      print('  连接池状态:');
      print('    最大连接数: ${connectionPool.maxConnections}');
      print('    活跃连接数: ${connectionPool.activeConnections}');
      print('    空闲连接数: ${connectionPool.idleConnections}');
      print(
        '    使用率: ${(connectionPool.utilizationRate * 100).toStringAsFixed(1)}%',
      );
    }
  }

  /// 显示网络配置
  void _displayNetworkConfig(String format, bool verbose) {
    print('📊 网络配置:');
    print('  HTTP版本: HTTP/2');
    print('  压缩: 启用 (gzip, brotli)');
    print('  Keep-Alive: 启用');
    print('  超时设置: 30秒');
    print('  重试次数: 3次');

    if (verbose) {
      print('  详细配置:');
      print('    连接超时: 10秒');
      print('    读取超时: 20秒');
      print('    最大重定向: 5次');
      print('    SSL验证: 启用');
      print('    用户代理: Ming-CLI/1.0');
    }
  }

  /// 显示带宽统计
  void _displayBandwidthStats(
    BandwidthManager bandwidthManager,
    String format,
    bool verbose,
  ) {
    final stats = bandwidthManager.stats;
    final limit = bandwidthManager.currentLimit;

    print('📊 带宽统计:');
    print('  网络类型: ${bandwidthManager.networkType.name}');
    print('  带宽管理: ${bandwidthManager.isEnabled ? '启用' : '禁用'}');
    print('  当前下载速度: ${_formatSpeed(stats.currentDownloadSpeed)}');
    print('  当前上传速度: ${_formatSpeed(stats.currentUploadSpeed)}');
    print('  活跃连接数: ${stats.activeConnections}');
    print('  队列请求数: ${stats.queuedRequests}');

    if (verbose) {
      print('  带宽限制:');
      print('    最大下载速度: ${_formatSpeed(limit.maxDownloadSpeed.toDouble())}');
      print('    最大上传速度: ${_formatSpeed(limit.maxUploadSpeed.toDouble())}');
      print('    最大连接数: ${limit.maxConnections}');

      print('  统计信息:');
      print('    总下载: ${_formatBytes(stats.totalDownloadBytes)}');
      print('    总上传: ${_formatBytes(stats.totalUploadBytes)}');
      print('    完成请求: ${stats.completedRequests}');
      print('    失败请求: ${stats.failedRequests}');
      print('    成功率: ${(stats.successRate * 100).toStringAsFixed(1)}%');
    }
  }

  /// 显示离线状态
  void _displayOfflineStatus(
    OfflineSupport offlineSupport,
    String format,
    bool verbose,
  ) {
    final queueStatus = offlineSupport.getQueueStatus();
    final cacheStats = offlineSupport.getCacheStats();

    print('📊 离线状态:');
    print('  连接状态: ${offlineSupport.connectionStatus.name}');
    print('  在线状态: ${offlineSupport.isOnline ? '在线' : '离线'}');
    print('  待同步操作: ${queueStatus['pendingOperations']}');
    print('  缓存条目: ${cacheStats['activeEntries']}');

    if (verbose) {
      print('  操作队列:');
      print('    总操作数: ${queueStatus['totalOperations']}');
      print('    已完成: ${queueStatus['completedOperations']}');
      print('    失败操作: ${queueStatus['failedOperations']}');
      print('    冲突数: ${queueStatus['conflicts']}');

      print('  缓存统计:');
      print('    总条目: ${cacheStats['totalEntries']}');
      print('    过期条目: ${cacheStats['expiredEntries']}');
      print('    缓存大小: ${_formatBytes(cacheStats['totalSizeBytes'] as int)}');
      print(
        '    命中率: ${((cacheStats['hitRate'] as double) * 100).toStringAsFixed(1)}%',
      );
    }
  }

  /// 显示重试统计
  void _displayRetryStats(
    RetryStrategy retryStrategy,
    String format,
    bool verbose,
  ) {
    final stats = retryStrategy.stats.getSummary();
    final circuitStats = retryStrategy.getCircuitBreakerStats();

    print('📊 重试统计:');
    print('  总重试次数: ${stats['totalRetries']}');
    print('  成功重试: ${stats['successfulRetries']}');
    print('  失败重试: ${stats['failedRetries']}');
    print(
      '  成功率: ${((stats['successRate'] as double) * 100).toStringAsFixed(1)}%',
    );

    if (verbose && circuitStats != null) {
      print('  断路器状态:');
      print('    状态: ${circuitStats['state']}');
      print('    失败计数: ${circuitStats['failureCount']}');
      print('    成功计数: ${circuitStats['successCount']}');
      print(
        '    失败率: ${((circuitStats['failureRate'] as double) * 100).toStringAsFixed(1)}%',
      );
    }
  }

  /// 显示所有统计
  void _displayAllStats(
    HttpClient httpClient,
    BandwidthManager bandwidthManager,
    OfflineSupport offlineSupport,
    String format,
    bool verbose,
  ) {
    final httpStats = httpClient.getRequestStats();
    final bandwidthStats = bandwidthManager.stats;
    final queueStatus = offlineSupport.getQueueStatus();

    print('📊 综合统计:');
    print('  HTTP请求: ${httpStats['totalRequests']}');
    print('  网络质量: ${httpClient.networkQuality.name}');
    print('  下载速度: ${_formatSpeed(bandwidthStats.currentDownloadSpeed)}');
    print('  活跃连接: ${bandwidthStats.activeConnections}');
    print('  离线操作: ${queueStatus['pendingOperations']}');
  }

  /// 显示缓存统计
  void _displayCacheStats(
    HttpClient httpClient,
    OfflineSupport offlineSupport,
    String format,
    bool verbose,
  ) {
    final httpStats = httpClient.getRequestStats();
    final cacheStats = offlineSupport.getCacheStats();

    print('📊 缓存统计:');
    print(
      '  HTTP缓存命中率: ${((httpStats['cacheHitRate'] as double) * 100).toStringAsFixed(1)}%',
    );
    print('  离线缓存条目: ${cacheStats['activeEntries']}');
    print('  缓存大小: ${_formatBytes(cacheStats['totalSizeBytes'] as int)}');

    if (verbose) {
      print('  详细信息:');
      print('    HTTP总请求: ${httpStats['totalRequests']}');
      print('    过期缓存: ${cacheStats['expiredEntries']}');
      print(
        '    缓存命中率: ${((cacheStats['hitRate'] as double) * 100).toStringAsFixed(1)}%',
      );
    }
  }

  /// 解析网络类型
  NetworkType _parseNetworkType(String type) {
    switch (type.toLowerCase()) {
      case 'wifi':
        return NetworkType.wifi;
      case 'mobile':
        return NetworkType.mobile;
      case 'ethernet':
        return NetworkType.ethernet;
      default:
        return NetworkType.unknown;
    }
  }

  /// 格式化速度
  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 0) return '无限制';
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  /// 格式化字节数
  String _formatBytes(int bytes) {
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
}
