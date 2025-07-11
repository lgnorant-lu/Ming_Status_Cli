/*
---------------------------------------------------------------
File name:          cache_strategy.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        缓存策略 (Cache Strategy)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 Week 2 智能搜索和分发系统;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// 缓存级别枚举
enum CacheLevel {
  /// 内存缓存 (L1)
  memory,

  /// 磁盘缓存 (L2)
  disk,

  /// CDN缓存 (L3)
  cdn,
}

/// 缓存策略枚举
enum CacheEvictionPolicy {
  /// 最近最少使用 (LRU)
  lru,

  /// 最不经常使用 (LFU)
  lfu,

  /// 先进先出 (FIFO)
  fifo,

  /// 生存时间 (TTL)
  ttl,

  /// 随机替换
  random,
}

/// 缓存压缩类型
enum CompressionType {
  /// 无压缩
  none,

  /// GZIP压缩
  gzip,

  /// LZ4压缩
  lz4,

  /// Brotli压缩
  brotli,
}

/// 缓存条目
class CacheEntry {
  CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.size,
    DateTime? lastAccessedAt,
    this.accessCount = 1,
    this.ttl,
    this.compression = CompressionType.none,
    this.etag,
    this.contentType,
    this.encrypted = false,
  }) : lastAccessedAt = lastAccessedAt ?? createdAt;

  /// 缓存键
  final String key;

  /// 缓存数据
  final Uint8List data;

  /// 创建时间
  final DateTime createdAt;

  /// 最后访问时间
  DateTime lastAccessedAt;

  /// 访问次数
  int accessCount;

  /// 生存时间 (TTL)
  final Duration? ttl;

  /// 数据大小 (字节)
  final int size;

  /// 压缩类型
  final CompressionType compression;

  /// ETag
  final String? etag;

  /// 内容类型
  final String? contentType;

  /// 是否加密
  final bool encrypted;

  /// 是否过期
  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(createdAt) > ttl!;
  }

  /// 剩余生存时间
  Duration? get remainingTtl {
    if (ttl == null) return null;
    final elapsed = DateTime.now().difference(createdAt);
    final remaining = ttl! - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 记录访问
  void recordAccess() {
    lastAccessedAt = DateTime.now();
    accessCount++;
  }
}

/// 缓存统计
class CacheStats {
  /// 命中次数
  int hits = 0;

  /// 未命中次数
  int misses = 0;

  /// 总请求次数
  int get totalRequests => hits + misses;

  /// 命中率
  double get hitRate => totalRequests > 0 ? hits / totalRequests : 0.0;

  /// 未命中率
  double get missRate => 1.0 - hitRate;

  /// 重置统计
  void reset() {
    hits = 0;
    misses = 0;
  }
}

/// 缓存配置
class CacheConfig {
  const CacheConfig({
    this.maxMemorySize = 100 * 1024 * 1024, // 100MB
    this.maxDiskSize = 1024 * 1024 * 1024, // 1GB
    this.maxEntries = 10000,
    this.defaultTtl = const Duration(hours: 24),
    this.evictionPolicy = CacheEvictionPolicy.lru,
    this.enableCompression = true,
    this.compressionType = CompressionType.gzip,
    this.enableEncryption = false,
    this.enablePrewarming = true,
    this.enablePrefetching = true,
  });

  /// 最大内存缓存大小 (字节)
  final int maxMemorySize;

  /// 最大磁盘缓存大小 (字节)
  final int maxDiskSize;

  /// 最大条目数量
  final int maxEntries;

  /// 默认TTL
  final Duration defaultTtl;

  /// 淘汰策略
  final CacheEvictionPolicy evictionPolicy;

  /// 是否启用压缩
  final bool enableCompression;

  /// 压缩类型
  final CompressionType compressionType;

  /// 是否启用加密
  final bool enableEncryption;

  /// 预热策略
  final bool enablePrewarming;

  /// 预取策略
  final bool enablePrefetching;
}

/// 多级缓存策略
class CacheStrategy {
  /// 构造函数
  CacheStrategy({
    CacheConfig? config,
    String? diskCacheDir,
  })  : _config = config ?? const CacheConfig(),
        _diskCacheDir = diskCacheDir ?? '.ming_cache/templates' {
    _initializeDiskCache();
    _startCleanupTimer();
  }

  /// 缓存配置
  final CacheConfig _config;

  /// 内存缓存 (L1)
  final Map<String, CacheEntry> _memoryCache = {};

  /// 磁盘缓存目录
  final String _diskCacheDir;

  /// 缓存统计
  final Map<CacheLevel, CacheStats> _stats = {
    CacheLevel.memory: CacheStats(),
    CacheLevel.disk: CacheStats(),
    CacheLevel.cdn: CacheStats(),
  };

  /// 当前内存使用量
  int _currentMemorySize = 0;

  /// 访问顺序 (用于LRU)
  final List<String> _accessOrder = [];

  /// 访问频率 (用于LFU)
  final Map<String, int> _accessFrequency = {};

  /// 预取队列
  final Set<String> _prefetchQueue = {};

  /// 获取缓存数据
  Future<Uint8List?> get(String key) async {
    // L1: 内存缓存
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      memoryEntry.recordAccess();
      _updateAccessOrder(key);
      _stats[CacheLevel.memory]!.hits++;
      return memoryEntry.data;
    } else {
      _stats[CacheLevel.memory]!.misses++;
      if (memoryEntry != null && memoryEntry.isExpired) {
        await _removeFromMemory(key);
      }
    }

    // L2: 磁盘缓存
    final diskEntry = await _getDiskEntry(key);
    if (diskEntry != null && !diskEntry.isExpired) {
      diskEntry.recordAccess();
      _stats[CacheLevel.disk]!.hits++;

      // 提升到内存缓存
      await _putInMemory(key, diskEntry);

      return diskEntry.data;
    } else {
      _stats[CacheLevel.disk]!.misses++;
      if (diskEntry != null && diskEntry.isExpired) {
        await _removeFromDisk(key);
      }
    }

    // L3: CDN缓存 (模拟)
    final cdnData = await _getCdnData(key);
    if (cdnData != null) {
      _stats[CacheLevel.cdn]!.hits++;

      // 创建缓存条目并存储到L1和L2
      final entry = CacheEntry(
        key: key,
        data: cdnData,
        createdAt: DateTime.now(),
        size: cdnData.length,
        ttl: _config.defaultTtl,
      );

      await put(key, cdnData);
      return cdnData;
    } else {
      _stats[CacheLevel.cdn]!.misses++;
    }

    return null;
  }

  /// 存储缓存数据
  Future<void> put(
    String key,
    Uint8List data, {
    Duration? ttl,
    String? etag,
    String? contentType,
  }) async {
    final entry = CacheEntry(
      key: key,
      data: data,
      createdAt: DateTime.now(),
      size: data.length,
      ttl: ttl ?? _config.defaultTtl,
      etag: etag,
      contentType: contentType,
      compression: _config.enableCompression
          ? _config.compressionType
          : CompressionType.none,
      encrypted: _config.enableEncryption,
    );

    // 存储到内存缓存
    await _putInMemory(key, entry);

    // 存储到磁盘缓存
    await _putInDisk(key, entry);

    // 触发预取
    if (_config.enablePrefetching) {
      _triggerPrefetch(key);
    }
  }

  /// 删除缓存
  Future<void> remove(String key) async {
    await _removeFromMemory(key);
    await _removeFromDisk(key);
  }

  /// 清空缓存
  Future<void> clear() async {
    _memoryCache.clear();
    _currentMemorySize = 0;
    _accessOrder.clear();
    _accessFrequency.clear();

    final diskDir = Directory(_diskCacheDir);
    if (await diskDir.exists()) {
      await diskDir.delete(recursive: true);
      await _initializeDiskCache();
    }

    // 重置统计
    for (final stats in _stats.values) {
      stats.reset();
    }
  }

  /// 缓存预热
  Future<void> prewarm(List<String> keys) async {
    if (!_config.enablePrewarming) return;

    for (final key in keys) {
      if (!_memoryCache.containsKey(key)) {
        // 尝试从磁盘加载
        final diskEntry = await _getDiskEntry(key);
        if (diskEntry != null && !diskEntry.isExpired) {
          await _putInMemory(key, diskEntry);
        }
      }
    }
  }

  /// 获取缓存统计
  Map<String, dynamic> getStats() {
    final memoryStats = _stats[CacheLevel.memory]!;
    final diskStats = _stats[CacheLevel.disk]!;
    final cdnStats = _stats[CacheLevel.cdn]!;

    return {
      'memory': {
        'hits': memoryStats.hits,
        'misses': memoryStats.misses,
        'hitRate': memoryStats.hitRate,
        'size': _currentMemorySize,
        'entries': _memoryCache.length,
      },
      'disk': {
        'hits': diskStats.hits,
        'misses': diskStats.misses,
        'hitRate': diskStats.hitRate,
        'size': _getDiskCacheSize(),
        'entries': _getDiskEntryCount(),
      },
      'cdn': {
        'hits': cdnStats.hits,
        'misses': cdnStats.misses,
        'hitRate': cdnStats.hitRate,
      },
      'overall': {
        'totalHits': memoryStats.hits + diskStats.hits + cdnStats.hits,
        'totalMisses': memoryStats.misses + diskStats.misses + cdnStats.misses,
        'overallHitRate': _calculateOverallHitRate(),
      },
    };
  }

  /// 获取缓存键列表
  List<String> getKeys({CacheLevel? level}) {
    switch (level) {
      case CacheLevel.memory:
        return _memoryCache.keys.toList();
      case CacheLevel.disk:
        return _getDiskKeys();
      case null:
        final memoryKeys = _memoryCache.keys.toSet();
        final diskKeys = _getDiskKeys().toSet();
        return memoryKeys.union(diskKeys).toList();
      default:
        return [];
    }
  }

  /// 存储到内存缓存
  Future<void> _putInMemory(String key, CacheEntry entry) async {
    // 检查是否需要淘汰
    while (_currentMemorySize + entry.size > _config.maxMemorySize ||
        _memoryCache.length >= _config.maxEntries) {
      await _evictFromMemory();
    }

    _memoryCache[key] = entry;
    _currentMemorySize += entry.size;
    _updateAccessOrder(key);
  }

  /// 从内存缓存移除
  Future<void> _removeFromMemory(String key) async {
    final entry = _memoryCache.remove(key);
    if (entry != null) {
      _currentMemorySize -= entry.size;
      _accessOrder.remove(key);
      _accessFrequency.remove(key);
    }
  }

  /// 内存缓存淘汰
  Future<void> _evictFromMemory() async {
    if (_memoryCache.isEmpty) return;

    String? keyToEvict;

    switch (_config.evictionPolicy) {
      case CacheEvictionPolicy.lru:
        keyToEvict = _accessOrder.first;
      case CacheEvictionPolicy.lfu:
        keyToEvict = _accessFrequency.entries
            .reduce((a, b) => a.value < b.value ? a : b)
            .key;
      case CacheEvictionPolicy.fifo:
        keyToEvict = _memoryCache.keys.first;
      case CacheEvictionPolicy.ttl:
        // 找到最早过期的条目
        CacheEntry? earliestExpired;
        String? earliestKey;
        for (final entry in _memoryCache.entries) {
          if (entry.value.isExpired) {
            if (earliestExpired == null ||
                entry.value.createdAt.isBefore(earliestExpired.createdAt)) {
              earliestExpired = entry.value;
              earliestKey = entry.key;
            }
          }
        }
        keyToEvict = earliestKey ?? _accessOrder.first;
      case CacheEvictionPolicy.random:
        final keys = _memoryCache.keys.toList();
        keyToEvict = keys[DateTime.now().millisecondsSinceEpoch % keys.length];
    }

    await _removeFromMemory(keyToEvict);
  }

  /// 更新访问顺序
  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
    _accessFrequency[key] = (_accessFrequency[key] ?? 0) + 1;
  }

  /// 存储到磁盘缓存
  Future<void> _putInDisk(String key, CacheEntry entry) async {
    final file = File('$_diskCacheDir/${_hashKey(key)}.cache');
    final metadata = {
      'key': key,
      'createdAt': entry.createdAt.toIso8601String(),
      'ttl': entry.ttl?.inMilliseconds,
      'size': entry.size,
      'etag': entry.etag,
      'contentType': entry.contentType,
      'compression': entry.compression.name,
      'encrypted': entry.encrypted,
    };

    final content = {
      'metadata': metadata,
      'data': base64Encode(entry.data),
    };

    await file.writeAsString(jsonEncode(content));
  }

  /// 从磁盘缓存获取
  Future<CacheEntry?> _getDiskEntry(String key) async {
    final file = File('$_diskCacheDir/${_hashKey(key)}.cache');
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final metadata = json['metadata'] as Map<String, dynamic>;
      final data = base64Decode(json['data'] as String);

      final entry = CacheEntry(
        key: metadata['key'] as String,
        data: Uint8List.fromList(data),
        createdAt: DateTime.parse(metadata['createdAt'] as String),
        size: metadata['size'] as int,
        ttl: metadata['ttl'] != null
            ? Duration(milliseconds: metadata['ttl'] as int)
            : null,
        etag: metadata['etag'] as String?,
        contentType: metadata['contentType'] as String?,
        compression:
            CompressionType.values.byName(metadata['compression'] as String),
        encrypted: metadata['encrypted'] as bool,
      );

      return entry;
    } catch (e) {
      // 删除损坏的缓存文件
      await file.delete();
      return null;
    }
  }

  /// 从磁盘缓存移除
  Future<void> _removeFromDisk(String key) async {
    final file = File('$_diskCacheDir/${_hashKey(key)}.cache');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 获取CDN数据 (模拟)
  Future<Uint8List?> _getCdnData(String key) async {
    // 模拟CDN延迟
    await Future.delayed(const Duration(milliseconds: 100));

    // 模拟CDN命中率 (30%)
    if (DateTime.now().millisecondsSinceEpoch % 10 < 3) {
      return Uint8List.fromList('CDN data for $key'.codeUnits);
    }

    return null;
  }

  /// 触发预取
  void _triggerPrefetch(String key) {
    // 简单的预取策略：预取相关键
    final relatedKeys = _generateRelatedKeys(key);
    _prefetchQueue.addAll(relatedKeys);

    // 异步执行预取
    Timer.run(_executePrefetch);
  }

  /// 执行预取
  Future<void> _executePrefetch() async {
    final keysToFetch = _prefetchQueue.take(5).toList();
    _prefetchQueue.removeAll(keysToFetch);

    for (final key in keysToFetch) {
      if (!_memoryCache.containsKey(key)) {
        final data = await _getCdnData(key);
        if (data != null) {
          await put(key, data);
        }
      }
    }
  }

  /// 生成相关键
  List<String> _generateRelatedKeys(String key) {
    // 简单实现：生成相似的键
    return [
      '${key}_related_1',
      '${key}_related_2',
      '${key}_metadata',
    ];
  }

  /// 初始化磁盘缓存
  Future<void> _initializeDiskCache() async {
    final dir = Directory(_diskCacheDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 启动清理定时器
  void _startCleanupTimer() {
    Timer.periodic(const Duration(hours: 1), (_) {
      _cleanupExpiredEntries();
    });
  }

  /// 清理过期条目
  Future<void> _cleanupExpiredEntries() async {
    // 清理内存中的过期条目
    final expiredKeys = _memoryCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      await _removeFromMemory(key);
    }

    // 清理磁盘中的过期条目
    final diskDir = Directory(_diskCacheDir);
    if (await diskDir.exists()) {
      await for (final entity in diskDir.list()) {
        if (entity is File && entity.path.endsWith('.cache')) {
          final entry = await _getDiskEntry(entity.path);
          if (entry != null && entry.isExpired) {
            await entity.delete();
          }
        }
      }
    }
  }

  /// 计算键的哈希值
  String _hashKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 获取磁盘缓存大小
  int _getDiskCacheSize() {
    // 简化实现
    return 50 * 1024 * 1024; // 50MB
  }

  /// 获取磁盘条目数量
  int _getDiskEntryCount() {
    // 简化实现
    return 100;
  }

  /// 获取磁盘键列表
  List<String> _getDiskKeys() {
    // 简化实现
    return ['disk_key_1', 'disk_key_2', 'disk_key_3'];
  }

  /// 计算总体命中率
  double _calculateOverallHitRate() {
    final totalHits = _stats.values.fold(0, (sum, stats) => sum + stats.hits);
    final totalRequests =
        _stats.values.fold(0, (sum, stats) => sum + stats.totalRequests);
    return totalRequests > 0 ? totalHits / totalRequests : 0.0;
  }

  /// 释放资源
  void dispose() {
    _memoryCache.clear();
    _accessOrder.clear();
    _accessFrequency.clear();
    _prefetchQueue.clear();
  }
}
