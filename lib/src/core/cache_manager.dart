/*
---------------------------------------------------------------
File name:          cache_manager.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.3 - 缓存管理系统
                    实现多级缓存、LRU策略和缓存优化
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 缓存管理系统;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:path/path.dart' as path;

/// 缓存策略
enum CacheStrategy {
  lru, // 最近最少使用
  lfu, // 最少使用频率
  fifo, // 先进先出
  ttl, // 基于时间
}

/// 缓存项
class CacheItem<T> {

  CacheItem({
    required this.key,
    required this.value,
    required this.size,
    DateTime? createdAt,
    DateTime? expiresAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastAccessedAt = DateTime.now(),
        accessCount = 1,
        expiresAt = expiresAt;
  /// 缓存键
  final String key;

  /// 缓存值
  final T value;

  /// 创建时间
  final DateTime createdAt;

  /// 最后访问时间
  DateTime lastAccessedAt;

  /// 访问次数
  int accessCount;

  /// 过期时间
  final DateTime? expiresAt;

  /// 数据大小（字节）
  final int size;

  /// 是否已过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 访问缓存项
  void access() {
    lastAccessedAt = DateTime.now();
    accessCount++;
  }

  /// 获取年龄（秒）
  int get ageInSeconds {
    return DateTime.now().difference(createdAt).inSeconds;
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'createdAt': createdAt.toIso8601String(),
        'lastAccessedAt': lastAccessedAt.toIso8601String(),
        'accessCount': accessCount,
        'expiresAt': expiresAt?.toIso8601String(),
        'size': size,
        'ageInSeconds': ageInSeconds,
      };
}

/// 缓存统计
class CacheStats {
  /// 总请求数
  int totalRequests = 0;

  /// 命中次数
  int hits = 0;

  /// 未命中次数
  int misses = 0;

  /// 驱逐次数
  int evictions = 0;

  /// 过期清理次数
  int expirations = 0;

  /// 命中率
  double get hitRate {
    if (totalRequests == 0) return 0;
    return hits / totalRequests;
  }

  /// 未命中率
  double get missRate {
    if (totalRequests == 0) return 0;
    return misses / totalRequests;
  }

  Map<String, dynamic> toJson() => {
        'totalRequests': totalRequests,
        'hits': hits,
        'misses': misses,
        'evictions': evictions,
        'expirations': expirations,
        'hitRate': hitRate,
        'missRate': missRate,
      };
}

/// 内存缓存
class MemoryCache<T> {

  MemoryCache({
    this.strategy = CacheStrategy.lru,
    this.maxItems = 1000,
    this.maxMemoryBytes = 100 * 1024 * 1024, // 100MB
    this.defaultTtlSeconds,
  }) {
    // 启动定期清理
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanup();
    });
  }
  /// 缓存策略
  final CacheStrategy strategy;

  /// 最大缓存项数
  final int maxItems;

  /// 最大内存使用（字节）
  final int maxMemoryBytes;

  /// 默认TTL（秒）
  final int? defaultTtlSeconds;

  /// 缓存数据
  final Map<String, CacheItem<T>> _cache = {};

  /// 访问顺序（用于LRU）
  final List<String> _accessOrder = [];

  /// 缓存统计
  final CacheStats _stats = CacheStats();

  /// 清理定时器
  Timer? _cleanupTimer;

  /// 获取缓存项
  T? get(String key) {
    _stats.totalRequests++;

    final item = _cache[key];
    if (item == null) {
      _stats.misses++;
      return null;
    }

    // 检查是否过期
    if (item.isExpired) {
      _cache.remove(key);
      _accessOrder.remove(key);
      _stats.misses++;
      _stats.expirations++;
      return null;
    }

    // 更新访问信息
    item.access();
    _updateAccessOrder(key);
    _stats.hits++;

    return item.value;
  }

  /// 设置缓存项
  void set(String key, T value, {Duration? ttl}) {
    final size = _calculateSize(value);
    final expiresAt = ttl != null
        ? DateTime.now().add(ttl)
        : (defaultTtlSeconds != null
            ? DateTime.now().add(Duration(seconds: defaultTtlSeconds!))
            : null);

    final item = CacheItem<T>(
      key: key,
      value: value,
      size: size,
      expiresAt: expiresAt,
    );

    // 如果键已存在，先移除
    if (_cache.containsKey(key)) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }

    _cache[key] = item;
    _accessOrder.add(key);

    // 检查是否需要驱逐
    _evictIfNecessary();
  }

  /// 删除缓存项
  bool remove(String key) {
    final removed = _cache.remove(key) != null;
    _accessOrder.remove(key);
    return removed;
  }

  /// 清空缓存
  void clear() {
    _cache.clear();
    _accessOrder.clear();
    Logger.info('内存缓存已清空');
  }

  /// 检查是否包含键
  bool containsKey(String key) {
    final item = _cache[key];
    if (item == null) return false;
    if (item.isExpired) {
      remove(key);
      return false;
    }
    return true;
  }

  /// 获取所有键
  List<String> get keys => _cache.keys.toList();

  /// 获取缓存大小
  int get length => _cache.length;

  /// 获取内存使用量
  int get memoryUsage {
    return _cache.values.fold(0, (sum, item) => sum + item.size);
  }

  /// 获取缓存统计
  CacheStats get stats => _stats;

  /// 更新访问顺序
  void _updateAccessOrder(String key) {
    if (strategy == CacheStrategy.lru) {
      _accessOrder.remove(key);
      _accessOrder.add(key);
    }
  }

  /// 驱逐缓存项
  void _evictIfNecessary() {
    // 检查数量限制
    while (_cache.length > maxItems) {
      _evictOne();
    }

    // 检查内存限制
    while (memoryUsage > maxMemoryBytes && _cache.isNotEmpty) {
      _evictOne();
    }
  }

  /// 驱逐一个缓存项
  void _evictOne() {
    if (_cache.isEmpty) return;

    String keyToEvict;

    switch (strategy) {
      case CacheStrategy.lru:
        keyToEvict = _accessOrder.first;
      case CacheStrategy.lfu:
        keyToEvict = _cache.entries
            .reduce((a, b) => a.value.accessCount < b.value.accessCount ? a : b)
            .key;
      case CacheStrategy.fifo:
        keyToEvict = _cache.entries
            .reduce(
                (a, b) => a.value.createdAt.isBefore(b.value.createdAt) ? a : b,)
            .key;
      case CacheStrategy.ttl:
        keyToEvict = _cache.entries
                .where((e) => e.value.expiresAt != null)
                .fold<MapEntry<String, CacheItem<T>>?>(null, (prev, curr) {
              if (prev == null) return curr;
              return curr.value.expiresAt!.isBefore(prev.value.expiresAt!)
                  ? curr
                  : prev;
            })?.key ??
            _accessOrder.first;
    }

    _cache.remove(keyToEvict);
    _accessOrder.remove(keyToEvict);
    _stats.evictions++;
  }

  /// 清理过期项
  void _cleanup() {
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _accessOrder.remove(key);
      _stats.expirations++;
    }

    if (expiredKeys.isNotEmpty) {
      Logger.debug('清理了 ${expiredKeys.length} 个过期缓存项');
    }
  }

  /// 计算值的大小
  int _calculateSize(T value) {
    if (value is String) {
      return value.length * 2; // UTF-16编码
    } else if (value is List<int>) {
      return value.length;
    } else if (value is Uint8List) {
      return value.length;
    } else {
      // 估算对象大小
      try {
        final json = jsonEncode(value);
        return json.length * 2;
      } catch (e) {
        return 1024; // 默认1KB
      }
    }
  }

  /// 销毁缓存
  void dispose() {
    _cleanupTimer?.cancel();
    clear();
  }
}

/// 磁盘缓存
class DiskCache {

  DiskCache({
    required this.cacheDirectory,
    this.maxSizeBytes = 500 * 1024 * 1024, // 500MB
  });
  /// 缓存目录
  final String cacheDirectory;

  /// 最大缓存大小（字节）
  final int maxSizeBytes;

  /// 缓存统计
  final CacheStats _stats = CacheStats();

  /// 初始化缓存目录
  Future<void> initialize() async {
    final dir = Directory(cacheDirectory);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
  }

  /// 获取缓存文件路径
  String _getCacheFilePath(String key) {
    final hash = sha256.convert(utf8.encode(key)).toString();
    return path.join(cacheDirectory, '$hash.cache');
  }

  /// 获取缓存项
  Future<Uint8List?> get(String key) async {
    _stats.totalRequests++;

    try {
      final filePath = _getCacheFilePath(key);
      final file = File(filePath);

      if (!file.existsSync()) {
        _stats.misses++;
        return null;
      }

      final data = await file.readAsBytes();
      _stats.hits++;

      // 更新访问时间
      await file.setLastAccessed(DateTime.now());

      return data;
    } catch (e) {
      _stats.misses++;
      Logger.warning('磁盘缓存读取失败: $key - $e');
      return null;
    }
  }

  /// 设置缓存项
  Future<void> set(String key, Uint8List data) async {
    try {
      await initialize();

      final filePath = _getCacheFilePath(key);
      final file = File(filePath);

      await file.writeAsBytes(data);

      // 检查缓存大小限制
      await _cleanupIfNecessary();
    } catch (e) {
      Logger.error('磁盘缓存写入失败: $key - $e');
      rethrow;
    }
  }

  /// 删除缓存项
  Future<bool> remove(String key) async {
    try {
      final filePath = _getCacheFilePath(key);
      final file = File(filePath);

      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      Logger.warning('磁盘缓存删除失败: $key - $e');
      return false;
    }
  }

  /// 清空缓存
  Future<void> clear() async {
    try {
      final dir = Directory(cacheDirectory);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
      Logger.info('磁盘缓存已清空');
    } catch (e) {
      Logger.error('清空磁盘缓存失败: $e');
    }
  }

  /// 获取缓存大小
  Future<int> getCacheSize() async {
    try {
      final dir = Directory(cacheDirectory);
      if (!dir.existsSync()) return 0;

      var totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      return totalSize;
    } catch (e) {
      Logger.warning('获取磁盘缓存大小失败: $e');
      return 0;
    }
  }

  /// 清理缓存
  Future<void> _cleanupIfNecessary() async {
    final currentSize = await getCacheSize();
    if (currentSize <= maxSizeBytes) return;

    try {
      final dir = Directory(cacheDirectory);
      final files = <File>[];

      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.cache')) {
          files.add(entity);
        }
      }

      // 按访问时间排序，删除最旧的文件
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return aStat.accessed.compareTo(bStat.accessed);
      });

      var deletedSize = 0;
      final targetSize = (maxSizeBytes * 0.8).toInt(); // 清理到80%

      for (final file in files) {
        if (currentSize - deletedSize <= targetSize) break;

        final stat = file.statSync();
        await file.delete();
        deletedSize += stat.size;
        _stats.evictions++;
      }

      if (deletedSize > 0) {
        Logger.info('磁盘缓存清理完成: 删除 ${_formatBytes(deletedSize)}');
      }
    } catch (e) {
      Logger.error('磁盘缓存清理失败: $e');
    }
  }

  /// 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 获取缓存统计
  CacheStats get stats => _stats;
}

/// 多级缓存管理器
class CacheManager {
  factory CacheManager() => _instance;
  CacheManager._internal();
  static final CacheManager _instance = CacheManager._internal();

  /// 内存缓存
  MemoryCache<dynamic>? _memoryCache;

  /// 磁盘缓存
  DiskCache? _diskCache;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化缓存管理器
  Future<void> initialize({
    String? cacheDirectory,
    int maxMemoryItems = 1000,
    int maxMemoryBytes = 100 * 1024 * 1024,
    int maxDiskBytes = 500 * 1024 * 1024,
    CacheStrategy strategy = CacheStrategy.lru,
  }) async {
    if (_isInitialized) return;

    final cacheDir = cacheDirectory ??
        path.join(Directory.systemTemp.path, 'ming_cli_cache');

    _memoryCache = MemoryCache<dynamic>(
      strategy: strategy,
      maxItems: maxMemoryItems,
      maxMemoryBytes: maxMemoryBytes,
    );

    _diskCache = DiskCache(
      cacheDirectory: cacheDir,
      maxSizeBytes: maxDiskBytes,
    );

    await _diskCache!.initialize();
    _isInitialized = true;

    Logger.info('缓存管理器已初始化: $cacheDir');
  }

  /// 获取缓存项
  Future<T?> get<T>(String key) async {
    if (!_isInitialized) await initialize();

    // 先尝试内存缓存
    final memoryResult = _memoryCache?.get(key);
    if (memoryResult != null) {
      return memoryResult as T?;
    }

    // 再尝试磁盘缓存
    final diskResult = await _diskCache?.get(key);
    if (diskResult != null) {
      // 将磁盘缓存的数据加载到内存缓存
      try {
        final decoded = jsonDecode(utf8.decode(diskResult));
        _memoryCache?.set(key, decoded);
        return decoded as T?;
      } catch (e) {
        Logger.warning('磁盘缓存数据解码失败: $key - $e');
      }
    }

    return null;
  }

  /// 设置缓存项
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    if (!_isInitialized) await initialize();

    // 设置内存缓存
    _memoryCache?.set(key, value, ttl: ttl);

    // 设置磁盘缓存
    try {
      final encoded = utf8.encode(jsonEncode(value));
      await _diskCache?.set(key, Uint8List.fromList(encoded));
    } catch (e) {
      Logger.warning('磁盘缓存设置失败: $key - $e');
    }
  }

  /// 删除缓存项
  Future<bool> remove(String key) async {
    if (!_isInitialized) await initialize();

    final memoryRemoved = _memoryCache?.remove(key) ?? false;
    final diskRemoved = await _diskCache?.remove(key) ?? false;

    return memoryRemoved || diskRemoved;
  }

  /// 清空所有缓存
  Future<void> clear() async {
    if (!_isInitialized) await initialize();

    _memoryCache?.clear();
    await _diskCache?.clear();
  }

  /// 获取缓存统计
  Map<String, dynamic> getStats() {
    if (!_isInitialized) return {};

    return {
      'memory': _memoryCache?.stats.toJson() ?? {},
      'disk': _diskCache?.stats.toJson() ?? {},
      'memory_usage': _memoryCache?.memoryUsage ?? 0,
      'memory_items': _memoryCache?.length ?? 0,
    };
  }

  /// 销毁缓存管理器
  void dispose() {
    if (_isInitialized) {
      _memoryCache?.dispose();
      _memoryCache = null;
      _diskCache = null;
      _isInitialized = false;
    }
  }
}
