/*
---------------------------------------------------------------
File name:          offline_support.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        离线支持 (Offline Support)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.5 网络通信和离线支持;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

/// 连接状态枚举
enum ConnectionStatus {
  /// 在线
  online,

  /// 离线
  offline,

  /// 连接中
  connecting,

  /// 连接不稳定
  unstable,
}

/// 同步状态枚举
enum SyncStatus {
  /// 已同步
  synced,

  /// 同步中
  syncing,

  /// 需要同步
  needsSync,

  /// 同步失败
  syncFailed,

  /// 冲突
  conflict,
}

/// 操作类型枚举
enum OperationType {
  /// 创建
  create,

  /// 更新
  update,

  /// 删除
  delete,

  /// 读取
  read,
}

/// 冲突解决策略枚举
enum ConflictResolution {
  /// 客户端优先
  clientWins,

  /// 服务器优先
  serverWins,

  /// 最新时间优先
  latestWins,

  /// 手动解决
  manual,
}

/// 离线操作
class OfflineOperation {
  /// 操作ID
  final String id;

  /// 操作类型
  final OperationType type;

  /// 资源类型
  final String resourceType;

  /// 资源ID
  final String resourceId;

  /// 操作数据
  final Map<String, dynamic> data;

  /// 创建时间
  final DateTime createdAt;

  /// 重试次数
  int retryCount = 0;

  /// 最大重试次数
  final int maxRetries;

  /// 是否已完成
  bool isCompleted = false;

  /// 错误信息
  String? error;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.resourceType,
    required this.resourceId,
    required this.data,
    DateTime? createdAt,
    this.maxRetries = 3,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'isCompleted': isCompleted,
      'error': error,
    };
  }

  /// 从JSON创建
  static OfflineOperation fromJson(Map<String, dynamic> json) {
    final operation = OfflineOperation(
      id: json['id'] as String,
      type: OperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OperationType.read,
      ),
      resourceType: json['resourceType'] as String,
      resourceId: json['resourceId'] as String,
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      maxRetries: json['maxRetries'] as int? ?? 3,
    );

    operation.retryCount = json['retryCount'] as int? ?? 0;
    operation.isCompleted = json['isCompleted'] as bool? ?? false;
    operation.error = json['error'] as String?;

    return operation;
  }
}

/// 缓存条目
class CacheEntry {
  /// 键
  final String key;

  /// 值
  final dynamic value;

  /// 创建时间
  final DateTime createdAt;

  /// 过期时间
  final DateTime? expiresAt;

  /// 访问次数
  int accessCount = 0;

  /// 最后访问时间
  DateTime lastAccessedAt;

  CacheEntry({
    required this.key,
    required this.value,
    DateTime? createdAt,
    this.expiresAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastAccessedAt = createdAt ?? DateTime.now();

  /// 是否过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 访问缓存
  void access() {
    accessCount++;
    lastAccessedAt = DateTime.now();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'accessCount': accessCount,
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
    };
  }

  /// 从JSON创建
  static CacheEntry fromJson(Map<String, dynamic> json) {
    final entry = CacheEntry(
      key: json['key'] as String,
      value: json['value'],
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );

    entry.accessCount = json['accessCount'] as int? ?? 0;
    entry.lastAccessedAt = DateTime.parse(
        json['lastAccessedAt'] as String? ?? entry.createdAt.toIso8601String());

    return entry;
  }
}

/// 同步冲突
class SyncConflict {
  /// 冲突ID
  final String id;

  /// 资源类型
  final String resourceType;

  /// 资源ID
  final String resourceId;

  /// 客户端数据
  final Map<String, dynamic> clientData;

  /// 服务器数据
  final Map<String, dynamic> serverData;

  /// 冲突时间
  final DateTime conflictTime;

  /// 解决策略
  ConflictResolution? resolution;

  /// 解决时间
  DateTime? resolvedAt;

  /// 解决数据
  Map<String, dynamic>? resolvedData;

  SyncConflict({
    required this.id,
    required this.resourceType,
    required this.resourceId,
    required this.clientData,
    required this.serverData,
    DateTime? conflictTime,
  }) : conflictTime = conflictTime ?? DateTime.now();

  /// 是否已解决
  bool get isResolved => resolution != null && resolvedAt != null;

  /// 解决冲突
  void resolve(ConflictResolution strategy, Map<String, dynamic> data) {
    resolution = strategy;
    resolvedData = data;
    resolvedAt = DateTime.now();
  }
}

/// 离线支持
class OfflineSupport {
  /// 连接状态
  ConnectionStatus _connectionStatus = ConnectionStatus.online;

  /// 操作队列
  final List<OfflineOperation> _operationQueue = [];

  /// 缓存存储
  final Map<String, CacheEntry> _cache = {};

  /// 同步冲突
  final List<SyncConflict> _conflicts = [];

  /// 缓存文件路径
  final String _cacheFilePath;

  /// 操作队列文件路径
  final String _queueFilePath;

  /// 连接检查定时器
  Timer? _connectionTimer;

  /// 同步定时器
  Timer? _syncTimer;

  /// 连接状态变化监听器
  final List<Function(ConnectionStatus)> _connectionListeners = [];

  /// 同步状态变化监听器
  final List<Function(SyncStatus)> _syncListeners = [];

  /// 构造函数
  OfflineSupport({
    String? cacheDir,
  })  : _cacheFilePath = '${cacheDir ?? './cache'}/offline_cache.json',
        _queueFilePath = '${cacheDir ?? './cache'}/operation_queue.json' {
    _initializeOfflineSupport();
  }

  /// 当前连接状态
  ConnectionStatus get connectionStatus => _connectionStatus;

  /// 是否在线
  bool get isOnline => _connectionStatus == ConnectionStatus.online;

  /// 是否离线
  bool get isOffline => _connectionStatus == ConnectionStatus.offline;

  /// 添加连接状态监听器
  void addConnectionListener(Function(ConnectionStatus) listener) {
    _connectionListeners.add(listener);
  }

  /// 移除连接状态监听器
  void removeConnectionListener(Function(ConnectionStatus) listener) {
    _connectionListeners.remove(listener);
  }

  /// 添加同步状态监听器
  void addSyncListener(Function(SyncStatus) listener) {
    _syncListeners.add(listener);
  }

  /// 移除同步状态监听器
  void removeSyncListener(Function(SyncStatus) listener) {
    _syncListeners.remove(listener);
  }

  /// 检测连接状态
  Future<ConnectionStatus> detectConnectionStatus() async {
    try {
      // 尝试连接到一个可靠的服务器
      final result = await io.InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return ConnectionStatus.online;
      }
    } catch (e) {
      // 连接失败
    }

    return ConnectionStatus.offline;
  }

  /// 设置连接状态
  void setConnectionStatus(ConnectionStatus status) {
    if (_connectionStatus != status) {
      _connectionStatus = status;
      _notifyConnectionListeners(status);

      // 如果重新连接，开始同步
      if (status == ConnectionStatus.online) {
        _startSync();
      }
    }
  }

  /// 添加离线操作
  void addOfflineOperation(OfflineOperation operation) {
    _operationQueue.add(operation);
    _saveOperationQueue();

    // 如果在线，立即尝试同步
    if (isOnline) {
      _syncOperation(operation);
    }
  }

  /// 获取缓存数据
  T? getCachedData<T>(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      entry.access();
      return entry.value as T?;
    }

    // 移除过期缓存
    if (entry != null && entry.isExpired) {
      _cache.remove(key);
    }

    return null;
  }

  /// 设置缓存数据
  void setCachedData(
    String key,
    dynamic value, {
    Duration? ttl,
  }) {
    final expiresAt = ttl != null ? DateTime.now().add(ttl) : null;
    _cache[key] = CacheEntry(
      key: key,
      value: value,
      expiresAt: expiresAt,
    );

    _saveCache();
  }

  /// 移除缓存数据
  void removeCachedData(String key) {
    _cache.remove(key);
    _saveCache();
  }

  /// 清空缓存
  void clearCache() {
    _cache.clear();
    _saveCache();
  }

  /// 获取操作队列状态
  Map<String, dynamic> getQueueStatus() {
    final pendingOps = _operationQueue.where((op) => !op.isCompleted).length;
    final completedOps = _operationQueue.where((op) => op.isCompleted).length;
    final failedOps = _operationQueue.where((op) => op.error != null).length;

    return {
      'totalOperations': _operationQueue.length,
      'pendingOperations': pendingOps,
      'completedOperations': completedOps,
      'failedOperations': failedOps,
      'conflicts': _conflicts.length,
      'unresolvedConflicts': _conflicts.where((c) => !c.isResolved).length,
    };
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    final totalEntries = _cache.length;
    final expiredEntries = _cache.values.where((e) => e.isExpired).length;
    final totalSize = _calculateCacheSize();

    return {
      'totalEntries': totalEntries,
      'expiredEntries': expiredEntries,
      'activeEntries': totalEntries - expiredEntries,
      'totalSizeBytes': totalSize,
      'hitRate': _calculateCacheHitRate(),
    };
  }

  /// 手动同步
  Future<void> sync() async {
    if (!isOnline) {
      throw Exception('Cannot sync while offline');
    }

    _notifySyncListeners(SyncStatus.syncing);

    try {
      await _syncAllOperations();
      _notifySyncListeners(SyncStatus.synced);
    } catch (e) {
      _notifySyncListeners(SyncStatus.syncFailed);
      rethrow;
    }
  }

  /// 解决同步冲突
  void resolveConflict(
    String conflictId,
    ConflictResolution strategy, {
    Map<String, dynamic>? customData,
  }) {
    final conflict = _conflicts.firstWhere(
      (c) => c.id == conflictId,
      orElse: () => throw Exception('Conflict not found: $conflictId'),
    );

    Map<String, dynamic> resolvedData;

    switch (strategy) {
      case ConflictResolution.clientWins:
        resolvedData = conflict.clientData;
        break;
      case ConflictResolution.serverWins:
        resolvedData = conflict.serverData;
        break;
      case ConflictResolution.latestWins:
        // 简化实现：比较时间戳
        final clientTime = DateTime.tryParse(
            conflict.clientData['updatedAt'] as String? ?? '');
        final serverTime = DateTime.tryParse(
            conflict.serverData['updatedAt'] as String? ?? '');

        if (clientTime != null && serverTime != null) {
          resolvedData = clientTime.isAfter(serverTime)
              ? conflict.clientData
              : conflict.serverData;
        } else {
          resolvedData = conflict.serverData;
        }
        break;
      case ConflictResolution.manual:
        resolvedData = customData ?? conflict.serverData;
        break;
    }

    conflict.resolve(strategy, resolvedData);
  }

  /// 清理资源
  void dispose() {
    _connectionTimer?.cancel();
    _syncTimer?.cancel();
    _saveCache();
    _saveOperationQueue();
  }

  /// 初始化离线支持
  void _initializeOfflineSupport() {
    _loadCache();
    _loadOperationQueue();
    _startConnectionMonitoring();
    _startPeriodicSync();
  }

  /// 开始连接监控
  void _startConnectionMonitoring() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final status = await detectConnectionStatus();
      setConnectionStatus(status);
    });
  }

  /// 开始定期同步
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (isOnline && _operationQueue.any((op) => !op.isCompleted)) {
        _startSync();
      }
    });
  }

  /// 开始同步
  void _startSync() {
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        await _syncAllOperations();
      } catch (e) {
        // 同步失败，稍后重试
      }
    });
  }

  /// 同步所有操作
  Future<void> _syncAllOperations() async {
    final pendingOps = _operationQueue.where((op) => !op.isCompleted).toList();

    for (final operation in pendingOps) {
      await _syncOperation(operation);
    }
  }

  /// 同步单个操作
  Future<void> _syncOperation(OfflineOperation operation) async {
    try {
      // 模拟网络请求
      await Future.delayed(const Duration(milliseconds: 500));

      // 模拟成功
      operation.isCompleted = true;
      _saveOperationQueue();
    } catch (e) {
      operation.retryCount++;
      operation.error = e.toString();

      if (operation.retryCount >= operation.maxRetries) {
        // 达到最大重试次数，标记为失败
        operation.isCompleted = true;
      }

      _saveOperationQueue();
    }
  }

  /// 通知连接状态监听器
  void _notifyConnectionListeners(ConnectionStatus status) {
    for (final listener in _connectionListeners) {
      try {
        listener(status);
      } catch (e) {
        // 忽略监听器错误
      }
    }
  }

  /// 通知同步状态监听器
  void _notifySyncListeners(SyncStatus status) {
    for (final listener in _syncListeners) {
      try {
        listener(status);
      } catch (e) {
        // 忽略监听器错误
      }
    }
  }

  /// 加载缓存
  void _loadCache() {
    try {
      final file = io.File(_cacheFilePath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final data = jsonDecode(content) as Map<String, dynamic>;

        for (final entry in data.entries) {
          _cache[entry.key] =
              CacheEntry.fromJson(entry.value as Map<String, dynamic>);
        }
      }
    } catch (e) {
      // 加载失败，使用空缓存
    }
  }

  /// 保存缓存
  void _saveCache() {
    try {
      final file = io.File(_cacheFilePath);
      file.parent.createSync(recursive: true);

      final data = <String, dynamic>{};
      for (final entry in _cache.entries) {
        data[entry.key] = entry.value.toJson();
      }

      file.writeAsStringSync(jsonEncode(data));
    } catch (e) {
      // 保存失败，忽略
    }
  }

  /// 加载操作队列
  void _loadOperationQueue() {
    try {
      final file = io.File(_queueFilePath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final data = jsonDecode(content) as List<dynamic>;

        _operationQueue.clear();
        for (final item in data) {
          _operationQueue
              .add(OfflineOperation.fromJson(item as Map<String, dynamic>));
        }
      }
    } catch (e) {
      // 加载失败，使用空队列
    }
  }

  /// 保存操作队列
  void _saveOperationQueue() {
    try {
      final file = io.File(_queueFilePath);
      file.parent.createSync(recursive: true);

      final data = _operationQueue.map((op) => op.toJson()).toList();
      file.writeAsStringSync(jsonEncode(data));
    } catch (e) {
      // 保存失败，忽略
    }
  }

  /// 计算缓存大小
  int _calculateCacheSize() {
    int totalSize = 0;
    for (final entry in _cache.values) {
      try {
        final json = jsonEncode(entry.value);
        totalSize += json.length;
      } catch (e) {
        // 忽略无法序列化的条目
      }
    }
    return totalSize;
  }

  /// 计算缓存命中率
  double _calculateCacheHitRate() {
    final totalAccess =
        _cache.values.fold(0, (sum, entry) => sum + entry.accessCount);
    final totalEntries = _cache.length;

    return totalEntries > 0 ? totalAccess / totalEntries : 0.0;
  }
}
