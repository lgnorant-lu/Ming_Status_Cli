/*
---------------------------------------------------------------
File name:          template_registry.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板注册表核心类 (Template Registry Core)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 远程模板生态建设;
---------------------------------------------------------------
*/

import 'dart:async';

/// 注册表类型枚举
enum RegistryType {
  /// 官方注册表
  official,

  /// 社区注册表
  community,

  /// 企业注册表
  enterprise,

  /// 私有注册表
  private,
}

/// 注册表状态枚举
enum RegistryStatus {
  /// 健康状态
  healthy,

  /// 警告状态
  warning,

  /// 错误状态
  error,

  /// 离线状态
  offline,
}

/// 注册表配置类
class RegistryConfig {
  const RegistryConfig({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.priority = 100,
    this.enabled = true,
    this.auth,
    this.timeout = 30,
    this.retryCount = 3,
  });

  /// 从JSON创建配置
  factory RegistryConfig.fromJson(Map<String, dynamic> json) {
    return RegistryConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      type: RegistryType.values.byName(json['type'] as String),
      priority: json['priority'] as int? ?? 100,
      enabled: json['enabled'] as bool? ?? true,
      auth: json['auth'] as Map<String, String>?,
      timeout: json['timeout'] as int? ?? 30,
      retryCount: json['retryCount'] as int? ?? 3,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 注册表ID
  final String id;

  /// 注册表名称
  final String name;

  /// 注册表URL
  final String url;

  /// 注册表类型
  final RegistryType type;

  /// 优先级 (数字越小优先级越高)
  final int priority;

  /// 是否启用
  final bool enabled;

  /// 认证信息
  final Map<String, String>? auth;

  /// 超时设置 (秒)
  final int timeout;

  /// 重试次数
  final int retryCount;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type.name,
      'priority': priority,
      'enabled': enabled,
      'auth': auth,
      'timeout': timeout,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// 注册表健康状态
class RegistryHealth {
  const RegistryHealth({
    required this.registryId,
    required this.status,
    required this.responseTime,
    required this.lastCheck,
    required this.availability,
    required this.templateCount,
    this.error,
  });

  /// 注册表ID
  final String registryId;

  /// 状态
  final RegistryStatus status;

  /// 响应时间 (毫秒)
  final int responseTime;

  /// 最后检查时间
  final DateTime lastCheck;

  /// 错误信息
  final String? error;

  /// 可用性百分比
  final double availability;

  /// 模板数量
  final int templateCount;
}

/// 注册表统计信息
class RegistryStats {
  const RegistryStats({
    required this.registryId,
    required this.totalRequests,
    required this.successRequests,
    required this.failedRequests,
    required this.avgResponseTime,
    required this.bytesTransferred,
    required this.startTime,
    required this.endTime,
  });

  /// 注册表ID
  final String registryId;

  /// 总请求数
  final int totalRequests;

  /// 成功请求数
  final int successRequests;

  /// 失败请求数
  final int failedRequests;

  /// 平均响应时间
  final double avgResponseTime;

  /// 数据传输量 (字节)
  final int bytesTransferred;

  /// 统计时间范围
  final DateTime startTime;
  final DateTime endTime;

  /// 成功率
  double get successRate =>
      totalRequests > 0 ? successRequests / totalRequests : 0.0;
}

/// 模板注册表核心类
class TemplateRegistry {
  /// 注册表配置列表
  final List<RegistryConfig> _registries = [];

  /// 注册表健康状态缓存
  final Map<String, RegistryHealth> _healthCache = {};

  /// 注册表统计信息
  final Map<String, RegistryStats> _statsCache = {};

  /// 健康检查定时器
  Timer? _healthCheckTimer;

  /// 添加注册表
  Future<void> addRegistry(RegistryConfig config) async {
    // 检查ID是否已存在
    if (_registries.any((r) => r.id == config.id)) {
      throw Exception('Registry with ID ${config.id} already exists');
    }

    // 验证注册表连接
    await _validateRegistry(config);

    // 添加到列表并排序
    _registries.add(config);
    _sortRegistriesByPriority();

    // 初始化健康检查
    await _performHealthCheck(config);
  }

  /// 移除注册表
  Future<void> removeRegistry(String registryId) async {
    _registries.removeWhere((r) => r.id == registryId);
    _healthCache.remove(registryId);
    _statsCache.remove(registryId);
  }

  /// 更新注册表配置
  Future<void> updateRegistry(
      String registryId, RegistryConfig newConfig) async {
    final index = _registries.indexWhere((r) => r.id == registryId);
    if (index == -1) {
      throw Exception('Registry with ID $registryId not found');
    }

    // 验证新配置
    await _validateRegistry(newConfig);

    // 更新配置
    _registries[index] = newConfig;
    _sortRegistriesByPriority();

    // 重新检查健康状态
    await _performHealthCheck(newConfig);
  }

  /// 获取所有注册表
  List<RegistryConfig> getAllRegistries() {
    return List.unmodifiable(_registries);
  }

  /// 获取启用的注册表
  List<RegistryConfig> getEnabledRegistries() {
    return _registries.where((r) => r.enabled).toList();
  }

  /// 根据类型获取注册表
  List<RegistryConfig> getRegistriesByType(RegistryType type) {
    return _registries.where((r) => r.type == type).toList();
  }

  /// 获取注册表健康状态
  RegistryHealth? getRegistryHealth(String registryId) {
    return _healthCache[registryId];
  }

  /// 获取注册表统计信息
  RegistryStats? getRegistryStats(String registryId) {
    return _statsCache[registryId];
  }

  /// 启动健康检查
  void startHealthCheck({Duration interval = const Duration(minutes: 5)}) {
    _healthCheckTimer?.cancel();
    _healthCheckTimer =
        Timer.periodic(interval, (_) => _performAllHealthChecks());
  }

  /// 停止健康检查
  void stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// 执行故障转移
  Future<RegistryConfig?> performFailover(String failedRegistryId) async {
    final failedRegistry = _registries.firstWhere(
      (r) => r.id == failedRegistryId,
      orElse: () => throw Exception('Registry not found'),
    );

    // 查找同类型的备用注册表
    final alternatives = _registries
        .where(
          (r) =>
              r.type == failedRegistry.type &&
              r.id != failedRegistryId &&
              r.enabled,
        )
        .toList();

    if (alternatives.isEmpty) {
      return null;
    }

    // 选择优先级最高的健康注册表
    for (final registry in alternatives) {
      final health = await _performHealthCheck(registry);
      if (health.status == RegistryStatus.healthy) {
        return registry;
      }
    }

    return null;
  }

  /// 验证注册表连接
  Future<void> _validateRegistry(RegistryConfig config) async {
    // TODO: 实现实际的网络连接验证
    // 这里应该发送HTTP请求验证注册表是否可访问
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 执行健康检查
  Future<RegistryHealth> _performHealthCheck(RegistryConfig config) async {
    final startTime = DateTime.now();

    try {
      // TODO: 实现实际的健康检查逻辑
      await Future.delayed(const Duration(milliseconds: 200));

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      final health = RegistryHealth(
        registryId: config.id,
        status: RegistryStatus.healthy,
        responseTime: responseTime,
        lastCheck: DateTime.now(),
        availability: 99.9,
        templateCount: 1000, // 模拟数据
      );

      _healthCache[config.id] = health;
      return health;
    } catch (e) {
      final health = RegistryHealth(
        registryId: config.id,
        status: RegistryStatus.error,
        responseTime: DateTime.now().difference(startTime).inMilliseconds,
        lastCheck: DateTime.now(),
        error: e.toString(),
        availability: 0,
        templateCount: 0,
      );

      _healthCache[config.id] = health;
      return health;
    }
  }

  /// 执行所有注册表健康检查
  Future<void> _performAllHealthChecks() async {
    final futures = _registries.map(_performHealthCheck);
    await Future.wait(futures);
  }

  /// 按优先级排序注册表
  void _sortRegistriesByPriority() {
    _registries.sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// 释放资源
  void dispose() {
    stopHealthCheck();
    _healthCache.clear();
    _statsCache.clear();
  }
}
