/*
---------------------------------------------------------------
File name:          bandwidth_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        带宽管理器 (Bandwidth Manager)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.5 网络通信和离线支持;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:collection';
import 'dart:math';

/// 网络类型枚举
enum NetworkType {
  /// WiFi
  wifi,

  /// 移动网络
  mobile,

  /// 以太网
  ethernet,

  /// 未知
  unknown,
}

/// 优先级枚举
enum Priority {
  /// 低优先级
  low,

  /// 普通优先级
  normal,

  /// 高优先级
  high,

  /// 紧急优先级
  urgent,
}

/// QoS类型枚举
enum QosType {
  /// 尽力而为
  bestEffort,

  /// 保证带宽
  guaranteed,

  /// 限制带宽
  limited,

  /// 优先级
  priority,
}

/// 带宽限制配置
class BandwidthLimit {
  const BandwidthLimit({
    required this.maxDownloadSpeed,
    required this.maxUploadSpeed,
    required this.maxConnections,
    this.enabled = true,
  });

  /// 最大下载速度 (字节/秒)
  final int maxDownloadSpeed;

  /// 最大上传速度 (字节/秒)
  final int maxUploadSpeed;

  /// 并发连接数限制
  final int maxConnections;

  /// 是否启用
  final bool enabled;

  /// 无限制配置
  static const unlimited = BandwidthLimit(
    maxDownloadSpeed: -1,
    maxUploadSpeed: -1,
    maxConnections: -1,
    enabled: false,
  );

  /// 移动网络配置
  static const mobile = BandwidthLimit(
    maxDownloadSpeed: 1024 * 1024, // 1MB/s
    maxUploadSpeed: 512 * 1024, // 512KB/s
    maxConnections: 5,
  );

  /// WiFi配置
  static const wifi = BandwidthLimit(
    maxDownloadSpeed: 10 * 1024 * 1024, // 10MB/s
    maxUploadSpeed: 5 * 1024 * 1024, // 5MB/s
    maxConnections: 20,
  );
}

/// 网络请求
class NetworkRequest {
  NetworkRequest({
    required this.id,
    required this.url,
    required this.size,
    required this.priority,
    required this.qosType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 请求ID
  final String id;

  /// 请求URL
  final String url;

  /// 请求大小 (字节)
  final int size;

  /// 优先级
  final Priority priority;

  /// QoS类型
  final QosType qosType;

  /// 创建时间
  final DateTime createdAt;

  /// 开始时间
  DateTime? startedAt;

  /// 完成时间
  DateTime? completedAt;

  /// 已传输字节数
  int transferredBytes = 0;

  /// 是否已完成
  bool get isCompleted => completedAt != null;

  /// 是否正在进行
  bool get isInProgress => startedAt != null && !isCompleted;

  /// 传输进度
  double get progress => size > 0 ? transferredBytes / size : 0.0;

  /// 开始传输
  void start() {
    startedAt = DateTime.now();
  }

  /// 完成传输
  void complete() {
    completedAt = DateTime.now();
    transferredBytes = size;
  }

  /// 更新传输进度
  void updateProgress(int bytes) {
    transferredBytes = min(bytes, size);
  }
}

/// 带宽使用统计
class BandwidthStats {
  /// 总下载字节数
  int totalDownloadBytes = 0;

  /// 总上传字节数
  int totalUploadBytes = 0;

  /// 当前下载速度 (字节/秒)
  double currentDownloadSpeed = 0;

  /// 当前上传速度 (字节/秒)
  double currentUploadSpeed = 0;

  /// 平均下载速度 (字节/秒)
  double averageDownloadSpeed = 0;

  /// 平均上传速度 (字节/秒)
  double averageUploadSpeed = 0;

  /// 峰值下载速度 (字节/秒)
  double peakDownloadSpeed = 0;

  /// 峰值上传速度 (字节/秒)
  double peakUploadSpeed = 0;

  /// 活跃连接数
  int activeConnections = 0;

  /// 队列中的请求数
  int queuedRequests = 0;

  /// 完成的请求数
  int completedRequests = 0;

  /// 失败的请求数
  int failedRequests = 0;

  /// 统计开始时间
  final DateTime startTime = DateTime.now();

  /// 成功率
  double get successRate {
    final totalRequests = completedRequests + failedRequests;
    return totalRequests > 0 ? completedRequests / totalRequests : 0.0;
  }

  /// 总传输字节数
  int get totalBytes => totalDownloadBytes + totalUploadBytes;

  /// 运行时间
  Duration get uptime => DateTime.now().difference(startTime);

  /// 重置统计
  void reset() {
    totalDownloadBytes = 0;
    totalUploadBytes = 0;
    currentDownloadSpeed = 0.0;
    currentUploadSpeed = 0.0;
    averageDownloadSpeed = 0.0;
    averageUploadSpeed = 0.0;
    peakDownloadSpeed = 0.0;
    peakUploadSpeed = 0.0;
    activeConnections = 0;
    queuedRequests = 0;
    completedRequests = 0;
    failedRequests = 0;
  }
}

/// 优先级队列
class PriorityQueue<T> {
  PriorityQueue(this._compare);
  final List<T> _items = [];
  final int Function(T, T) _compare;

  /// 添加元素
  void add(T item) {
    _items.add(item);
    _items.sort(_compare);
  }

  /// 移除并返回第一个元素
  T? removeFirst() {
    return _items.isNotEmpty ? _items.removeAt(0) : null;
  }

  /// 查看第一个元素
  T? get first => _items.isNotEmpty ? _items.first : null;

  /// 是否为空
  bool get isEmpty => _items.isEmpty;

  /// 长度
  int get length => _items.length;

  /// 清空
  void clear() => _items.clear();

  /// 转换为列表
  List<T> toList() => List.from(_items);
}

/// 带宽管理器
class BandwidthManager {
  /// 构造函数
  BandwidthManager() {
    _startMonitoring();
  }

  /// 当前网络类型
  NetworkType _networkType = NetworkType.wifi;

  /// 带宽限制配置
  final Map<NetworkType, BandwidthLimit> _limits = {
    NetworkType.wifi: BandwidthLimit.wifi,
    NetworkType.mobile: BandwidthLimit.mobile,
    NetworkType.ethernet: BandwidthLimit.unlimited,
    NetworkType.unknown: BandwidthLimit.mobile,
  };

  /// 请求队列
  final PriorityQueue<NetworkRequest> _requestQueue =
      PriorityQueue<NetworkRequest>(
    (a, b) => b.priority.index.compareTo(a.priority.index),
  );

  /// 活跃请求
  final Map<String, NetworkRequest> _activeRequests = {};

  /// 带宽统计
  final BandwidthStats _stats = BandwidthStats();

  /// 速度历史记录
  final Queue<double> _downloadSpeedHistory = Queue();
  final Queue<double> _uploadSpeedHistory = Queue();

  /// 定时器
  Timer? _statsTimer;
  Timer? _queueProcessTimer;

  /// 是否启用
  bool _enabled = true;

  /// 当前网络类型
  NetworkType get networkType => _networkType;

  /// 设置网络类型
  void setNetworkType(NetworkType type) {
    _networkType = type;
    _adjustLimitsForNetworkType();
  }

  /// 获取当前带宽限制
  BandwidthLimit get currentLimit =>
      _limits[_networkType] ?? BandwidthLimit.mobile;

  /// 设置带宽限制
  void setBandwidthLimit(NetworkType networkType, BandwidthLimit limit) {
    _limits[networkType] = limit;
  }

  /// 启用/禁用带宽管理
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// 是否启用
  bool get isEnabled => _enabled;

  /// 添加网络请求
  Future<void> addRequest(NetworkRequest request) async {
    if (!_enabled) {
      // 如果禁用带宽管理，直接执行
      await _executeRequest(request);
      return;
    }

    _requestQueue.add(request);
    _stats.queuedRequests++;

    // 触发队列处理
    _processQueue();
  }

  /// 取消请求
  void cancelRequest(String requestId) {
    // 从队列中移除
    final queueItems = _requestQueue.toList();
    _requestQueue.clear();
    for (final item in queueItems) {
      if (item.id != requestId) {
        _requestQueue.add(item);
      }
    }

    // 从活跃请求中移除
    _activeRequests.remove(requestId);
  }

  /// 获取带宽统计
  BandwidthStats get stats => _stats;

  /// 获取队列状态
  Map<String, dynamic> getQueueStatus() {
    return {
      'queuedRequests': _requestQueue.length,
      'activeRequests': _activeRequests.length,
      'requestsByPriority': _getRequestsByPriority(),
      'requestsByQos': _getRequestsByQos(),
    };
  }

  /// 获取网络成本信息
  Map<String, dynamic> getNetworkCost() {
    final costPerMB = _getCostPerMB(_networkType);
    final totalMB = _stats.totalBytes / (1024 * 1024);

    return {
      'networkType': _networkType.name,
      'costPerMB': costPerMB,
      'totalMB': totalMB,
      'estimatedCost': totalMB * costPerMB,
      'downloadMB': _stats.totalDownloadBytes / (1024 * 1024),
      'uploadMB': _stats.totalUploadBytes / (1024 * 1024),
    };
  }

  /// 优化网络使用
  void optimizeNetworkUsage() {
    if (_networkType == NetworkType.mobile) {
      // 移动网络优化
      _optimizeForMobile();
    } else {
      // WiFi/以太网优化
      _optimizeForHighSpeed();
    }
  }

  /// 清理资源
  void dispose() {
    _statsTimer?.cancel();
    _queueProcessTimer?.cancel();
    _requestQueue.clear();
    _activeRequests.clear();
  }

  /// 处理请求队列
  void _processQueue() {
    if (_queueProcessTimer?.isActive == true) return;

    _queueProcessTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _processQueueBatch();
    });
  }

  /// 批量处理队列
  void _processQueueBatch() {
    final limit = currentLimit;

    // 检查连接数限制
    if (limit.maxConnections > 0 &&
        _activeRequests.length >= limit.maxConnections) {
      return;
    }

    // 检查带宽限制
    if (!_canStartNewRequest()) {
      return;
    }

    // 从队列中取出请求
    final request = _requestQueue.removeFirst();
    if (request != null) {
      _stats.queuedRequests--;
      _executeRequest(request);
    }

    // 如果队列为空，停止定时器
    if (_requestQueue.isEmpty) {
      _queueProcessTimer?.cancel();
    }
  }

  /// 检查是否可以开始新请求
  bool _canStartNewRequest() {
    final limit = currentLimit;

    // 检查下载速度限制
    if (limit.maxDownloadSpeed > 0 &&
        _stats.currentDownloadSpeed >= limit.maxDownloadSpeed) {
      return false;
    }

    // 检查上传速度限制
    if (limit.maxUploadSpeed > 0 &&
        _stats.currentUploadSpeed >= limit.maxUploadSpeed) {
      return false;
    }

    return true;
  }

  /// 执行请求
  Future<void> _executeRequest(NetworkRequest request) async {
    request.start();
    _activeRequests[request.id] = request;
    _stats.activeConnections++;

    try {
      // 模拟网络请求
      await _simulateNetworkRequest(request);

      request.complete();
      _stats.completedRequests++;
      _updateTransferStats(request, true);
    } catch (e) {
      _stats.failedRequests++;
      _updateTransferStats(request, false);
    } finally {
      _activeRequests.remove(request.id);
      _stats.activeConnections--;
    }
  }

  /// 模拟网络请求
  Future<void> _simulateNetworkRequest(NetworkRequest request) async {
    const chunkSize = 8192; // 8KB chunks
    final totalChunks = (request.size / chunkSize).ceil();

    for (var i = 0; i < totalChunks; i++) {
      // 检查带宽限制
      await _applyBandwidthThrottling();

      // 模拟传输一个chunk
      final chunkBytes =
          min(chunkSize, request.size - request.transferredBytes);
      request.updateProgress(request.transferredBytes + chunkBytes);

      // 更新统计
      _updateSpeedStats(chunkBytes, true);

      // 模拟网络延迟
      await Future<void>.delayed(Duration(milliseconds: _getNetworkDelay()));
    }
  }

  /// 应用带宽限制
  Future<void> _applyBandwidthThrottling() async {
    final limit = currentLimit;

    if (!limit.enabled) return;

    // 计算需要的延迟
    var delay = 0;

    if (limit.maxDownloadSpeed > 0 &&
        _stats.currentDownloadSpeed > limit.maxDownloadSpeed) {
      delay = max(delay, 100); // 100ms延迟
    }

    if (limit.maxUploadSpeed > 0 &&
        _stats.currentUploadSpeed > limit.maxUploadSpeed) {
      delay = max(delay, 100);
    }

    if (delay > 0) {
      await Future<void>.delayed(Duration(milliseconds: delay));
    }
  }

  /// 获取网络延迟
  int _getNetworkDelay() {
    switch (_networkType) {
      case NetworkType.wifi:
        return 10;
      case NetworkType.mobile:
        return 50;
      case NetworkType.ethernet:
        return 5;
      case NetworkType.unknown:
        return 100;
    }
  }

  /// 更新传输统计
  void _updateTransferStats(NetworkRequest request, bool success) {
    if (success) {
      _stats.totalDownloadBytes += request.size;
    }
  }

  /// 更新速度统计
  void _updateSpeedStats(int bytes, bool isDownload) {
    final speed = bytes.toDouble(); // 简化计算

    if (isDownload) {
      _downloadSpeedHistory.add(speed);
      _stats.currentDownloadSpeed = speed;
      _stats.peakDownloadSpeed = max(_stats.peakDownloadSpeed, speed);
    } else {
      _uploadSpeedHistory.add(speed);
      _stats.currentUploadSpeed = speed;
      _stats.peakUploadSpeed = max(_stats.peakUploadSpeed, speed);
    }

    // 保持历史记录大小
    if (_downloadSpeedHistory.length > 100) {
      _downloadSpeedHistory.removeFirst();
    }
    if (_uploadSpeedHistory.length > 100) {
      _uploadSpeedHistory.removeFirst();
    }

    // 计算平均速度
    _calculateAverageSpeeds();
  }

  /// 计算平均速度
  void _calculateAverageSpeeds() {
    if (_downloadSpeedHistory.isNotEmpty) {
      _stats.averageDownloadSpeed =
          _downloadSpeedHistory.reduce((a, b) => a + b) /
              _downloadSpeedHistory.length;
    }

    if (_uploadSpeedHistory.isNotEmpty) {
      _stats.averageUploadSpeed = _uploadSpeedHistory.reduce((a, b) => a + b) /
          _uploadSpeedHistory.length;
    }
  }

  /// 根据网络类型调整限制
  void _adjustLimitsForNetworkType() {
    // 可以根据网络类型动态调整限制
    optimizeNetworkUsage();
  }

  /// 移动网络优化
  void _optimizeForMobile() {
    // 降低并发连接数
    _limits[NetworkType.mobile] = const BandwidthLimit(
      maxDownloadSpeed: 512 * 1024, // 512KB/s
      maxUploadSpeed: 256 * 1024, // 256KB/s
      maxConnections: 3,
    );
  }

  /// 高速网络优化
  void _optimizeForHighSpeed() {
    // 提高并发连接数
    _limits[NetworkType.wifi] = const BandwidthLimit(
      maxDownloadSpeed: 20 * 1024 * 1024, // 20MB/s
      maxUploadSpeed: 10 * 1024 * 1024, // 10MB/s
      maxConnections: 50,
    );
  }

  /// 获取按优先级分组的请求
  Map<String, int> _getRequestsByPriority() {
    final result = <String, int>{};
    for (final priority in Priority.values) {
      result[priority.name] = 0;
    }

    for (final request in _requestQueue.toList()) {
      result[request.priority.name] = (result[request.priority.name] ?? 0) + 1;
    }

    return result;
  }

  /// 获取按QoS分组的请求
  Map<String, int> _getRequestsByQos() {
    final result = <String, int>{};
    for (final qos in QosType.values) {
      result[qos.name] = 0;
    }

    for (final request in _requestQueue.toList()) {
      result[request.qosType.name] = (result[request.qosType.name] ?? 0) + 1;
    }

    return result;
  }

  /// 获取每MB成本
  double _getCostPerMB(NetworkType networkType) {
    switch (networkType) {
      case NetworkType.mobile:
        return 0.1; // $0.1 per MB
      case NetworkType.wifi:
        return 0; // Free
      case NetworkType.ethernet:
        return 0; // Free
      case NetworkType.unknown:
        return 0.05; // $0.05 per MB
    }
  }

  /// 开始监控
  void _startMonitoring() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStats();
    });
  }

  /// 更新统计
  void _updateStats() {
    // 这里可以添加实时统计更新逻辑
    // 例如：检测网络类型变化、更新速度统计等
  }
}
