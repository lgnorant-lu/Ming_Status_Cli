/*
---------------------------------------------------------------
File name:          memory_optimizer.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        内存优化器 (Memory Optimizer)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - 内存使用优化;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 内存使用类型
enum MemoryType {
  /// 堆内存
  heap,

  /// 栈内存
  stack,

  /// 缓存内存
  cache,

  /// 临时内存
  temporary,

  /// 持久内存
  persistent,
}

/// 内存使用信息
class MemoryUsage {
  /// 创建内存使用信息实例
  const MemoryUsage({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
    required this.timestamp,
    this.breakdown = const {},
  });

  /// 总内存 (字节)
  final int totalBytes;

  /// 已使用内存 (字节)
  final int usedBytes;

  /// 空闲内存 (字节)
  final int freeBytes;

  /// 时间戳
  final DateTime timestamp;

  /// 内存分解
  final Map<MemoryType, int> breakdown;

  /// 使用率
  double get usagePercentage =>
      totalBytes > 0 ? (usedBytes / totalBytes) * 100 : 0.0;

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'total_bytes': totalBytes,
      'used_bytes': usedBytes,
      'free_bytes': freeBytes,
      'usage_percentage': usagePercentage,
      'timestamp': timestamp.toIso8601String(),
      'breakdown': breakdown.map((type, bytes) => MapEntry(type.name, bytes)),
    };
  }
}

/// 内存优化结果
class MemoryOptimizationResult {
  /// 创建内存优化结果实例
  const MemoryOptimizationResult({
    required this.success,
    required this.beforeUsage,
    required this.afterUsage,
    required this.freedBytes,
    this.optimizations = const [],
    this.recommendations = const [],
  });

  /// 是否成功
  final bool success;

  /// 优化前内存使用
  final MemoryUsage beforeUsage;

  /// 优化后内存使用
  final MemoryUsage afterUsage;

  /// 释放的内存 (字节)
  final int freedBytes;

  /// 应用的优化
  final List<String> optimizations;

  /// 建议
  final List<String> recommendations;

  /// 优化效果百分比
  double get improvementPercentage {
    if (beforeUsage.usedBytes == 0) return 0;
    return (freedBytes / beforeUsage.usedBytes) * 100;
  }
}

/// 内存池
class MemoryPool<T> {
  /// 创建内存池实例
  MemoryPool({
    required this.factory,
    this.maxSize = 100,
    this.resetFunction,
  });

  /// 对象工厂
  final T Function() factory;

  /// 最大池大小
  final int maxSize;

  /// 重置函数
  final void Function(T)? resetFunction;

  /// 对象池
  final Queue<T> _pool = Queue<T>();

  /// 已分配对象数
  int _allocatedCount = 0;

  /// 获取对象
  T acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeFirst();
    }

    _allocatedCount++;
    return factory();
  }

  /// 释放对象
  void release(T object) {
    if (_pool.length < maxSize) {
      resetFunction?.call(object);
      _pool.add(object);
    }
  }

  /// 清空池
  void clear() {
    _pool.clear();
    _allocatedCount = 0;
  }

  /// 获取统计信息
  Map<String, int> getStats() {
    return {
      'pool_size': _pool.length,
      'allocated_count': _allocatedCount,
      'max_size': maxSize,
    };
  }
}

/// 内存优化器
class MemoryOptimizer {
  /// 创建内存优化器实例
  MemoryOptimizer({
    this.maxMemoryUsage = 500 * 1024 * 1024, // 500MB
    this.gcThreshold = 0.8, // 80%
    this.monitoringInterval = const Duration(minutes: 5),
    this.enableAutoOptimization = true,
  });

  /// 最大内存使用 (字节)
  final int maxMemoryUsage;

  /// GC触发阈值
  final double gcThreshold;

  /// 监控间隔
  final Duration monitoringInterval;

  /// 是否启用自动优化
  final bool enableAutoOptimization;

  /// 内存使用历史
  final List<MemoryUsage> _usageHistory = [];

  /// 内存池映射
  final Map<Type, MemoryPool> _memoryPools = {};

  /// 缓存映射
  final Map<String, dynamic> _cacheMap = {};

  /// 监控定时器
  Timer? _monitoringTimer;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化内存优化器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      cli_logger.Logger.debug('初始化内存优化器');

      // 开始内存监控
      if (enableAutoOptimization) {
        _startMemoryMonitoring();
      }

      _isInitialized = true;
      cli_logger.Logger.info('内存优化器初始化完成');
    } catch (e) {
      cli_logger.Logger.error('内存优化器初始化失败', error: e);
      rethrow;
    }
  }

  /// 执行内存优化
  Future<MemoryOptimizationResult> optimize() async {
    try {
      cli_logger.Logger.debug('开始内存优化');

      final beforeUsage = await _getCurrentMemoryUsage();
      final optimizations = <String>[];

      // 清理缓存
      final cacheFreed = _clearExpiredCache();
      if (cacheFreed > 0) {
        optimizations.add('清理过期缓存: ${_formatBytes(cacheFreed)}');
      }

      // 清理内存池
      final poolFreed = _clearMemoryPools();
      if (poolFreed > 0) {
        optimizations.add('清理内存池: ${_formatBytes(poolFreed)}');
      }

      // 强制垃圾回收
      await _forceGarbageCollection();
      optimizations.add('执行垃圾回收');

      // 等待GC完成
      await Future.delayed(const Duration(milliseconds: 500));

      final afterUsage = await _getCurrentMemoryUsage();
      final freedBytes = beforeUsage.usedBytes - afterUsage.usedBytes;

      final result = MemoryOptimizationResult(
        success: freedBytes > 0,
        beforeUsage: beforeUsage,
        afterUsage: afterUsage,
        freedBytes: freedBytes,
        optimizations: optimizations,
        recommendations: _generateRecommendations(afterUsage),
      );

      cli_logger.Logger.info(
        '内存优化完成: 释放${_formatBytes(freedBytes)} '
        '(${result.improvementPercentage.toStringAsFixed(1)}%)',
      );

      return result;
    } catch (e) {
      cli_logger.Logger.error('内存优化失败', error: e);
      rethrow;
    }
  }

  /// 注册内存池
  void registerMemoryPool<T>(MemoryPool<T> pool) {
    _memoryPools[T] = pool;
    cli_logger.Logger.debug('注册内存池: $T');
  }

  /// 获取内存池
  MemoryPool<T>? getMemoryPool<T>() {
    return _memoryPools[T] as MemoryPool<T>?;
  }

  /// 设置缓存
  void setCache(String key, dynamic value, {Duration? ttl}) {
    _cacheMap[key] = {
      'value': value,
      'timestamp': DateTime.now(),
      'ttl': ttl,
    };
  }

  /// 获取缓存
  T? getCache<T>(String key) {
    final entry = _cacheMap[key];
    if (entry == null) return null;

    final timestamp = entry['timestamp'] as DateTime;
    final ttl = entry['ttl'] as Duration?;

    if (ttl != null && DateTime.now().difference(timestamp) > ttl) {
      _cacheMap.remove(key);
      return null;
    }

    return entry['value'] as T?;
  }

  /// 获取当前内存使用
  Future<MemoryUsage> getCurrentMemoryUsage() async {
    return _getCurrentMemoryUsage();
  }

  /// 获取内存使用历史
  List<MemoryUsage> getMemoryUsageHistory() {
    return List.unmodifiable(_usageHistory);
  }

  /// 生成内存报告
  Map<String, dynamic> generateMemoryReport() {
    final currentUsage = _usageHistory.isNotEmpty ? _usageHistory.last : null;

    return {
      'summary': {
        'current_usage_bytes': currentUsage?.usedBytes ?? 0,
        'current_usage_percentage': currentUsage?.usagePercentage ?? 0.0,
        'max_usage_bytes': maxMemoryUsage,
        'gc_threshold': gcThreshold,
        'monitoring_enabled': _monitoringTimer != null,
      },
      'current_usage': currentUsage?.toMap(),
      'usage_trend': _usageHistory.map((usage) => usage.toMap()).toList(),
      'memory_pools': _memoryPools.map(
        (type, pool) => MapEntry(type.toString(), pool.getStats()),
      ),
      'cache_stats': {
        'total_entries': _cacheMap.length,
        'estimated_size_bytes': _estimateCacheSize(),
      },
      'recommendations':
          currentUsage != null ? _generateRecommendations(currentUsage) : [],
    };
  }

  /// 获取当前内存使用（内部方法）
  Future<MemoryUsage> _getCurrentMemoryUsage() async {
    final processInfo = ProcessInfo.currentRss;
    final timestamp = DateTime.now();

    // 估算内存分解
    final breakdown = <MemoryType, int>{
      MemoryType.heap: (processInfo * 0.6).round(),
      MemoryType.cache: _estimateCacheSize(),
      MemoryType.temporary: (processInfo * 0.1).round(),
      MemoryType.persistent: (processInfo * 0.3).round(),
    };

    final usage = MemoryUsage(
      totalBytes: maxMemoryUsage,
      usedBytes: processInfo,
      freeBytes: maxMemoryUsage - processInfo,
      timestamp: timestamp,
      breakdown: breakdown,
    );

    _usageHistory.add(usage);

    // 保持历史记录在合理范围内
    if (_usageHistory.length > 100) {
      _usageHistory.removeAt(0);
    }

    return usage;
  }

  /// 清理过期缓存
  int _clearExpiredCache() {
    var freedBytes = 0;
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cacheMap.entries) {
      final data = entry.value as Map<String, dynamic>;
      final timestamp = data['timestamp'] as DateTime;
      final ttl = data['ttl'] as Duration?;

      if (ttl != null && now.difference(timestamp) > ttl) {
        keysToRemove.add(entry.key);
        freedBytes += _estimateObjectSize(data['value']);
      }
    }

    for (final key in keysToRemove) {
      _cacheMap.remove(key);
    }

    return freedBytes;
  }

  /// 清理内存池
  int _clearMemoryPools() {
    var freedBytes = 0;

    for (final pool in _memoryPools.values) {
      final stats = pool.getStats();
      freedBytes += stats['pool_size']! * 1024; // 估算每个对象1KB
      pool.clear();
    }

    return freedBytes;
  }

  /// 强制垃圾回收
  Future<void> _forceGarbageCollection() async {
    // 创建大量临时对象来触发GC
    final tempObjects = <Object>[];
    for (var i = 0; i < 10000; i++) {
      tempObjects.add(Object());
    }
    tempObjects.clear();

    // 等待GC有机会运行
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 估算缓存大小
  int _estimateCacheSize() {
    var totalSize = 0;
    for (final entry in _cacheMap.values) {
      totalSize += _estimateObjectSize(entry['value']);
    }
    return totalSize;
  }

  /// 估算对象大小
  int _estimateObjectSize(dynamic object) {
    if (object == null) return 0;
    if (object is String) return object.length * 2; // UTF-16
    if (object is List) return object.length * 8; // 指针大小
    if (object is Map) return object.length * 16; // 键值对
    return 64; // 默认对象大小
  }

  /// 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// 生成建议
  List<String> _generateRecommendations(MemoryUsage usage) {
    final recommendations = <String>[];

    if (usage.usagePercentage > 90) {
      recommendations.add('内存使用率过高，建议立即优化');
    } else if (usage.usagePercentage > 80) {
      recommendations.add('内存使用率较高，建议定期清理');
    }

    if (_cacheMap.length > 1000) {
      recommendations.add('缓存条目过多，建议设置TTL或清理策略');
    }

    if (_memoryPools.isEmpty) {
      recommendations.add('建议使用内存池来减少对象分配');
    }

    final cacheSize = _estimateCacheSize();
    if (cacheSize > 50 * 1024 * 1024) {
      // 50MB
      recommendations.add('缓存占用内存过多，建议优化缓存策略');
    }

    return recommendations;
  }

  /// 开始内存监控
  void _startMemoryMonitoring() {
    _monitoringTimer = Timer.periodic(monitoringInterval, (timer) async {
      try {
        final usage = await _getCurrentMemoryUsage();

        if (usage.usagePercentage > gcThreshold * 100) {
          cli_logger.Logger.warning('内存使用率过高，触发自动优化');
          await optimize();
        }
      } catch (e) {
        cli_logger.Logger.error('内存监控失败', error: e);
      }
    });
  }

  /// 停止内存监控
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// 清理资源
  void dispose() {
    stopMonitoring();
    _clearMemoryPools();
    _cacheMap.clear();
    _usageHistory.clear();
  }
}
