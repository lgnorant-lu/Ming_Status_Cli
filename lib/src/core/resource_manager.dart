/*
---------------------------------------------------------------
File name:          resource_manager.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.3 - 资源管理器
                    实现内存管理、连接池和资源优化
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 资源管理器;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart';

/// 资源类型
enum ResourceType {
  memory, // 内存资源
  file, // 文件资源
  network, // 网络连接
  process, // 进程资源
  timer, // 定时器
  stream, // 流资源
}

/// 资源状态
enum ResourceStatus {
  available, // 可用
  inUse, // 使用中
  disposed, // 已释放
  error, // 错误状态
}

/// 资源项
abstract class Resource {
  Resource({
    required this.id,
    required this.type,
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastUsedAt = DateTime.now(),
        useCount = 0,
        status = ResourceStatus.available;

  /// 资源ID
  final String id;

  /// 资源类型
  final ResourceType type;

  /// 创建时间
  final DateTime createdAt;

  /// 最后使用时间
  DateTime lastUsedAt;

  /// 使用次数
  int useCount;

  /// 资源状态
  ResourceStatus status;

  /// 使用资源
  void use() {
    lastUsedAt = DateTime.now();
    useCount++;
    status = ResourceStatus.inUse;
  }

  /// 释放资源
  Future<void> dispose();

  /// 检查资源是否可用
  bool get isAvailable => status == ResourceStatus.available;

  /// 检查资源是否已释放
  bool get isDisposed => status == ResourceStatus.disposed;

  /// 获取资源年龄（秒）
  int get ageInSeconds => DateTime.now().difference(createdAt).inSeconds;

  /// 获取空闲时间（秒）
  int get idleTimeInSeconds => DateTime.now().difference(lastUsedAt).inSeconds;
}

/// 文件资源
class FileResource extends Resource {
  FileResource({
    required super.id,
    required this.file,
    required this.filePath,
  }) : super(type: ResourceType.file);

  /// 文件句柄
  final RandomAccessFile file;

  /// 文件路径
  final String filePath;

  @override
  Future<void> dispose() async {
    try {
      await file.close();
      status = ResourceStatus.disposed;
      Logger.debug('文件资源已释放: $filePath');
    } catch (e) {
      status = ResourceStatus.error;
      Logger.error('文件资源释放失败: $filePath - $e');
    }
  }
}

/// 网络连接资源
class NetworkResource extends Resource {
  NetworkResource({
    required super.id,
    required this.socket,
    required this.remoteAddress,
  }) : super(type: ResourceType.network);

  /// Socket连接
  final Socket socket;

  /// 远程地址
  final String remoteAddress;

  @override
  Future<void> dispose() async {
    try {
      await socket.close();
      status = ResourceStatus.disposed;
      Logger.debug('网络资源已释放: $remoteAddress');
    } catch (e) {
      status = ResourceStatus.error;
      Logger.error('网络资源释放失败: $remoteAddress - $e');
    }
  }
}

/// 定时器资源
class TimerResource extends Resource {
  TimerResource({
    required super.id,
    required this.timer,
    required this.description,
  }) : super(type: ResourceType.timer);

  /// 定时器
  final Timer timer;

  /// 定时器描述
  final String description;

  @override
  Future<void> dispose() async {
    try {
      timer.cancel();
      status = ResourceStatus.disposed;
      Logger.debug('定时器资源已释放: $description');
    } catch (e) {
      status = ResourceStatus.error;
      Logger.error('定时器资源释放失败: $description - $e');
    }
  }
}

/// 流资源
class StreamResource extends Resource {
  StreamResource({
    required super.id,
    required this.controller,
    required this.description,
  }) : super(type: ResourceType.stream);

  /// 流控制器
  final StreamController<dynamic> controller;

  /// 流描述
  final String description;

  @override
  Future<void> dispose() async {
    try {
      await controller.close();
      status = ResourceStatus.disposed;
      Logger.debug('流资源已释放: $description');
    } catch (e) {
      status = ResourceStatus.error;
      Logger.error('流资源释放失败: $description - $e');
    }
  }
}

/// 资源池
class ResourcePool<T extends Resource> {
  ResourcePool({
    required this.name,
    required this.maxResources,
    required this.resourceFactory,
    this.idleTimeoutSeconds = 300, // 5分钟
  }) {
    // 启动定期清理
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanupIdleResources();
    });
  }

  /// 池名称
  final String name;

  /// 最大资源数
  final int maxResources;

  /// 资源空闲超时（秒）
  final int idleTimeoutSeconds;

  /// 资源创建函数
  final Future<T> Function() resourceFactory;

  /// 可用资源队列
  final Queue<T> _availableResources = Queue<T>();

  /// 使用中的资源
  final Set<T> _inUseResources = <T>{};

  /// 资源清理定时器
  Timer? _cleanupTimer;

  /// 获取资源
  Future<T> acquire() async {
    // 尝试从可用资源中获取
    if (_availableResources.isNotEmpty) {
      final resource = _availableResources.removeFirst();
      resource.use();
      _inUseResources.add(resource);
      return resource;
    }

    // 检查是否可以创建新资源
    if (totalResources < maxResources) {
      final resource = await resourceFactory();
      resource.use();
      _inUseResources.add(resource);
      Logger.debug('创建新资源: ${resource.id} (池: $name)');
      return resource;
    }

    // 等待资源释放
    throw StateError('资源池已满，无法获取新资源: $name');
  }

  /// 释放资源
  void release(T resource) {
    if (!_inUseResources.remove(resource)) {
      Logger.warning('尝试释放不属于此池的资源: ${resource.id}');
      return;
    }

    if (resource.isDisposed) {
      Logger.debug('资源已释放，不返回池中: ${resource.id}');
      return;
    }

    resource.status = ResourceStatus.available;
    _availableResources.add(resource);
    Logger.debug('资源已返回池中: ${resource.id} (池: $name)');
  }

  /// 清理空闲资源
  void _cleanupIdleResources() {
    final now = DateTime.now();
    final toRemove = <T>[];

    for (final resource in _availableResources) {
      // 计算资源空闲时间
      final idleTime = now.difference(resource.lastUsedAt).inSeconds;
      if (idleTime > idleTimeoutSeconds) {
        toRemove.add(resource);
      }
    }

    for (final resource in toRemove) {
      _availableResources.remove(resource);
      resource.dispose();
      Logger.debug('清理空闲资源: ${resource.id} (池: $name)');
    }

    if (toRemove.isNotEmpty) {
      Logger.info('资源池 $name 清理了 ${toRemove.length} 个空闲资源');
    }
  }

  /// 获取总资源数
  int get totalResources => _availableResources.length + _inUseResources.length;

  /// 获取可用资源数
  int get availableResources => _availableResources.length;

  /// 获取使用中资源数
  int get inUseResources => _inUseResources.length;

  /// 获取池统计
  Map<String, dynamic> getStats() {
    return {
      'name': name,
      'maxResources': maxResources,
      'totalResources': totalResources,
      'availableResources': availableResources,
      'inUseResources': inUseResources,
      'utilizationRate':
          totalResources > 0 ? inUseResources / totalResources : 0.0,
    };
  }

  /// 销毁资源池
  Future<void> dispose() async {
    _cleanupTimer?.cancel();

    // 释放所有资源
    final allResources = [..._availableResources, ..._inUseResources];
    for (final resource in allResources) {
      await resource.dispose();
    }

    _availableResources.clear();
    _inUseResources.clear();

    Logger.info('资源池已销毁: $name');
  }
}

/// 资源管理器
class ResourceManager {
  factory ResourceManager() => _instance;
  ResourceManager._internal();
  static final ResourceManager _instance = ResourceManager._internal();

  /// 资源池映射
  final Map<String, ResourcePool> _pools = {};

  /// 所有资源
  final Map<String, Resource> _allResources = {};

  /// 资源清理定时器
  Timer? _globalCleanupTimer;

  /// 内存监控定时器
  Timer? _memoryMonitorTimer;

  /// 内存使用阈值（字节）
  int memoryThresholdBytes = 200 * 1024 * 1024; // 200MB

  /// 初始化资源管理器
  void initialize() {
    // 启动全局资源清理
    _globalCleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performGlobalCleanup();
    });

    // 启动内存监控
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _monitorMemoryUsage();
    });

    Logger.info('资源管理器已初始化');
  }

  /// 注册资源池
  void registerPool<T extends Resource>(ResourcePool<T> pool) {
    _pools[pool.name] = pool;
    Logger.info('资源池已注册: ${pool.name}');
  }

  /// 获取资源池
  ResourcePool<T>? getPool<T extends Resource>(String name) {
    return _pools[name] as ResourcePool<T>?;
  }

  /// 注册资源
  void registerResource(Resource resource) {
    _allResources[resource.id] = resource;
    Logger.debug('资源已注册: ${resource.id} (${resource.type.name})');
  }

  /// 注销资源
  void unregisterResource(String resourceId) {
    final resource = _allResources.remove(resourceId);
    if (resource != null) {
      Logger.debug('资源已注销: $resourceId (${resource.type.name})');
    }
  }

  /// 获取资源
  Resource? getResource(String resourceId) {
    return _allResources[resourceId];
  }

  /// 释放资源
  Future<void> disposeResource(String resourceId) async {
    final resource = _allResources[resourceId];
    if (resource != null) {
      await resource.dispose();
      _allResources.remove(resourceId);
    }
  }

  /// 执行全局清理
  void _performGlobalCleanup() {
    final disposedResources = <String>[];

    for (final entry in _allResources.entries) {
      final resource = entry.value;

      // 清理已释放的资源
      if (resource.isDisposed) {
        disposedResources.add(entry.key);
      }
      // 清理长时间未使用的资源
      else if (resource.idleTimeInSeconds > 1800) {
        // 30分钟
        resource.dispose();
        disposedResources.add(entry.key);
      }
    }

    for (final resourceId in disposedResources) {
      _allResources.remove(resourceId);
    }

    if (disposedResources.isNotEmpty) {
      Logger.info('全局清理完成: 清理了 ${disposedResources.length} 个资源');
    }
  }

  /// 监控内存使用
  void _monitorMemoryUsage() {
    try {
      final currentMemory = ProcessInfo.currentRss;

      if (currentMemory > memoryThresholdBytes) {
        Logger.warning('内存使用超过阈值: ${_formatBytes(currentMemory)}');
        _performEmergencyCleanup();
      }
    } catch (e) {
      // 某些平台可能不支持
    }
  }

  /// 执行紧急清理
  void _performEmergencyCleanup() {
    Logger.info('执行紧急内存清理');

    // 强制垃圾回收
    // 注意：Dart没有显式的垃圾回收API，这里只是示例

    // 清理所有资源池中的空闲资源
    for (final pool in _pools.values) {
      pool._cleanupIdleResources();
    }

    // 清理长时间未使用的资源
    final toDispose = <String>[];
    for (final entry in _allResources.entries) {
      if (entry.value.idleTimeInSeconds > 600) {
        // 10分钟
        toDispose.add(entry.key);
      }
    }

    for (final resourceId in toDispose) {
      disposeResource(resourceId);
    }
  }

  /// 获取资源统计
  Map<String, dynamic> getResourceStats() {
    final statsByType = <String, int>{};
    final statusCounts = <String, int>{};

    for (final resource in _allResources.values) {
      final typeName = resource.type.name;
      statsByType[typeName] = (statsByType[typeName] ?? 0) + 1;

      final statusName = resource.status.name;
      statusCounts[statusName] = (statusCounts[statusName] ?? 0) + 1;
    }

    final poolStats = <String, dynamic>{};
    for (final pool in _pools.values) {
      poolStats[pool.name] = pool.getStats();
    }

    return {
      'totalResources': _allResources.length,
      'resourcesByType': statsByType,
      'resourcesByStatus': statusCounts,
      'pools': poolStats,
      'memoryThreshold': _formatBytes(memoryThresholdBytes),
      'currentMemory': _formatBytes(_getCurrentMemoryUsage()),
    };
  }

  /// 获取当前内存使用
  int _getCurrentMemoryUsage() {
    try {
      return ProcessInfo.currentRss;
    } catch (e) {
      return 0;
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

  /// 设置内存阈值
  void setMemoryThreshold(int bytes) {
    memoryThresholdBytes = bytes;
    Logger.info('内存阈值已设置为: ${_formatBytes(bytes)}');
  }

  /// 销毁资源管理器
  Future<void> dispose() async {
    _globalCleanupTimer?.cancel();
    _memoryMonitorTimer?.cancel();

    // 销毁所有资源池
    for (final pool in _pools.values) {
      await pool.dispose();
    }
    _pools.clear();

    // 释放所有资源
    for (final resource in _allResources.values) {
      await resource.dispose();
    }
    _allResources.clear();

    Logger.info('资源管理器已销毁');
  }
}
