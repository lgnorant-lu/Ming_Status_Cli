/*
---------------------------------------------------------------
File name:          private_registry.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        私有注册表 (Private Registry)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.4 企业级模板管理;
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

/// 部署模式枚举
enum DeploymentMode {
  /// 本地部署
  onPremise,

  /// 云端部署
  cloud,

  /// 混合部署
  hybrid,

  /// 联邦部署
  federated,
}

/// 认证类型枚举
enum AuthenticationType {
  /// 无认证
  none,

  /// API密钥
  apiKey,

  /// OAuth2
  oauth2,

  /// LDAP
  ldap,

  /// Active Directory
  activeDirectory,

  /// SAML
  saml,

  /// 证书认证
  certificate,
}

/// 同步状态枚举
enum SyncStatus {
  /// 同步中
  syncing,

  /// 已同步
  synced,

  /// 同步失败
  failed,

  /// 冲突
  conflict,

  /// 暂停
  paused,
}

/// 租户信息
class TenantInfo {
  const TenantInfo({
    required this.id,
    required this.name,
    required this.domain,
    required this.status,
    required this.createdAt,
    required this.lastActiveAt,
    required this.storageQuota,
    required this.storageUsed,
    required this.userLimit,
    required this.currentUsers,
    required this.config,
    required this.metadata,
  });

  /// 租户ID
  final String id;

  /// 租户名称
  final String name;

  /// 租户域名
  final String domain;

  /// 租户状态
  final String status;

  /// 创建时间
  final DateTime createdAt;

  /// 最后活跃时间
  final DateTime lastActiveAt;

  /// 存储配额 (字节)
  final int storageQuota;

  /// 已使用存储 (字节)
  final int storageUsed;

  /// 用户数量限制
  final int userLimit;

  /// 当前用户数量
  final int currentUsers;

  /// 配置信息
  final Map<String, dynamic> config;

  /// 元数据
  final Map<String, dynamic> metadata;

  /// 存储使用率
  double get storageUsageRate =>
      storageQuota > 0 ? storageUsed / storageQuota : 0.0;

  /// 用户使用率
  double get userUsageRate => userLimit > 0 ? currentUsers / userLimit : 0.0;

  /// 是否活跃
  bool get isActive => status == 'active';

  /// 是否接近配额
  bool get isNearQuota => storageUsageRate > 0.8 || userUsageRate > 0.8;
}

/// 注册表配置
class RegistryConfig {
  const RegistryConfig({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.deploymentMode,
    required this.authType,
    required this.authConfig,
    required this.multiTenant,
    required this.federationEnabled,
    required this.syncConfig,
    required this.storageConfig,
    required this.networkConfig,
  });

  /// 注册表ID
  final String id;

  /// 注册表名称
  final String name;

  /// 注册表URL
  final String url;

  /// 注册表类型
  final RegistryType type;

  /// 部署模式
  final DeploymentMode deploymentMode;

  /// 认证类型
  final AuthenticationType authType;

  /// 认证配置
  final Map<String, dynamic> authConfig;

  /// 是否启用多租户
  final bool multiTenant;

  /// 是否启用联邦
  final bool federationEnabled;

  /// 同步配置
  final Map<String, dynamic> syncConfig;

  /// 存储配置
  final Map<String, dynamic> storageConfig;

  /// 网络配置
  final Map<String, dynamic> networkConfig;
}

/// 联邦同步信息
class FederationSync {
  const FederationSync({
    required this.id,
    required this.sourceRegistry,
    required this.targetRegistry,
    required this.status,
    required this.strategy,
    required this.lastSyncTime,
    required this.nextSyncTime,
    required this.syncedTemplates,
    required this.conflicts,
    required this.config,
    this.error,
  });

  /// 同步ID
  final String id;

  /// 源注册表
  final String sourceRegistry;

  /// 目标注册表
  final String targetRegistry;

  /// 同步状态
  final SyncStatus status;

  /// 同步策略
  final String strategy;

  /// 最后同步时间
  final DateTime lastSyncTime;

  /// 下次同步时间
  final DateTime nextSyncTime;

  /// 同步的模板数量
  final int syncedTemplates;

  /// 冲突数量
  final int conflicts;

  /// 错误信息
  final String? error;

  /// 同步配置
  final Map<String, dynamic> config;

  /// 是否需要同步
  bool get needsSync => DateTime.now().isAfter(nextSyncTime);

  /// 是否有冲突
  bool get hasConflicts => conflicts > 0;

  /// 同步成功率
  double get successRate => syncedTemplates > 0
      ? (syncedTemplates - conflicts) / syncedTemplates
      : 0.0;
}

/// 私有注册表
class PrivateRegistry {
  /// 构造函数
  PrivateRegistry({
    required RegistryConfig config,
  }) : _config = config {
    _initializeRegistry();
  }

  /// 注册表配置
  final RegistryConfig _config;

  /// 租户列表
  final Map<String, TenantInfo> _tenants = {};

  /// 联邦同步列表
  final List<FederationSync> _federationSyncs = [];

  /// 认证提供者
  final Map<String, dynamic> _authProviders = {};

  /// 存储提供者
  final Map<String, dynamic> _storageProviders = {};

  /// 监控指标
  final Map<String, dynamic> _metrics = {};

  /// 事件监听器
  final List<void Function(String, Map<String, dynamic>)> _eventListeners = [];

  /// 创建租户
  Future<TenantInfo> createTenant({
    required String name,
    required String domain,
    int storageQuota = 1024 * 1024 * 1024, // 1GB
    int userLimit = 100,
    Map<String, dynamic>? config,
    Map<String, dynamic>? metadata,
  }) async {
    final tenantId = _generateTenantId(name);

    final tenant = TenantInfo(
      id: tenantId,
      name: name,
      domain: domain,
      status: 'active',
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      storageQuota: storageQuota,
      storageUsed: 0,
      userLimit: userLimit,
      currentUsers: 0,
      config: config ?? {},
      metadata: metadata ?? {},
    );

    _tenants[tenantId] = tenant;

    // 初始化租户存储
    await _initializeTenantStorage(tenant);

    // 发送事件
    _emitEvent('tenant_created', {
      'tenantId': tenantId,
      'name': name,
      'domain': domain,
    });

    return tenant;
  }

  /// 删除租户
  Future<void> deleteTenant(String tenantId) async {
    final tenant = _tenants[tenantId];
    if (tenant == null) {
      throw Exception('Tenant not found: $tenantId');
    }

    // 清理租户数据
    await _cleanupTenantData(tenant);

    // 移除租户
    _tenants.remove(tenantId);

    // 发送事件
    _emitEvent('tenant_deleted', {
      'tenantId': tenantId,
      'name': tenant.name,
    });
  }

  /// 获取租户信息
  TenantInfo? getTenant(String tenantId) {
    return _tenants[tenantId];
  }

  /// 获取所有租户
  List<TenantInfo> getAllTenants() {
    return _tenants.values.toList();
  }

  /// 更新租户配额
  Future<void> updateTenantQuota(
    String tenantId, {
    int? storageQuota,
    int? userLimit,
  }) async {
    final tenant = _tenants[tenantId];
    if (tenant == null) {
      throw Exception('Tenant not found: $tenantId');
    }

    final updatedTenant = TenantInfo(
      id: tenant.id,
      name: tenant.name,
      domain: tenant.domain,
      status: tenant.status,
      createdAt: tenant.createdAt,
      lastActiveAt: DateTime.now(),
      storageQuota: storageQuota ?? tenant.storageQuota,
      storageUsed: tenant.storageUsed,
      userLimit: userLimit ?? tenant.userLimit,
      currentUsers: tenant.currentUsers,
      config: tenant.config,
      metadata: tenant.metadata,
    );

    _tenants[tenantId] = updatedTenant;

    // 发送事件
    _emitEvent('tenant_quota_updated', {
      'tenantId': tenantId,
      'storageQuota': updatedTenant.storageQuota,
      'userLimit': updatedTenant.userLimit,
    });
  }

  /// 配置联邦同步
  Future<FederationSync> configureFederationSync({
    required String sourceRegistry,
    required String targetRegistry,
    required String strategy,
    required Map<String, dynamic> config,
  }) async {
    final syncId = _generateSyncId(sourceRegistry, targetRegistry);

    final federationSync = FederationSync(
      id: syncId,
      sourceRegistry: sourceRegistry,
      targetRegistry: targetRegistry,
      status: SyncStatus.paused,
      strategy: strategy,
      lastSyncTime: DateTime.now(),
      nextSyncTime: DateTime.now().add(
        Duration(
          minutes: config['intervalMinutes'] as int? ?? 60,
        ),
      ),
      syncedTemplates: 0,
      conflicts: 0,
      config: config,
    );

    _federationSyncs.add(federationSync);

    // 发送事件
    _emitEvent('federation_sync_configured', {
      'syncId': syncId,
      'sourceRegistry': sourceRegistry,
      'targetRegistry': targetRegistry,
    });

    return federationSync;
  }

  /// 执行联邦同步
  Future<void> executeFederationSync(String syncId) async {
    final syncIndex = _federationSyncs.indexWhere((sync) => sync.id == syncId);
    if (syncIndex == -1) {
      throw Exception('Federation sync not found: $syncId');
    }

    final sync = _federationSyncs[syncIndex];

    // 更新同步状态
    final updatedSync = FederationSync(
      id: sync.id,
      sourceRegistry: sync.sourceRegistry,
      targetRegistry: sync.targetRegistry,
      status: SyncStatus.syncing,
      strategy: sync.strategy,
      lastSyncTime: DateTime.now(),
      nextSyncTime: sync.nextSyncTime,
      syncedTemplates: sync.syncedTemplates,
      conflicts: sync.conflicts,
      config: sync.config,
    );

    _federationSyncs[syncIndex] = updatedSync;

    try {
      // 执行同步逻辑
      final result = await _performSync(sync);

      // 更新同步结果
      final completedSync = FederationSync(
        id: sync.id,
        sourceRegistry: sync.sourceRegistry,
        targetRegistry: sync.targetRegistry,
        status: (result['conflicts'] as int? ?? 0) > 0
            ? SyncStatus.conflict
            : SyncStatus.synced,
        strategy: sync.strategy,
        lastSyncTime: DateTime.now(),
        nextSyncTime: DateTime.now().add(
          Duration(
            minutes: sync.config['intervalMinutes'] as int? ?? 60,
          ),
        ),
        syncedTemplates: result['syncedTemplates'] as int,
        conflicts: result['conflicts'] as int,
        config: sync.config,
      );

      _federationSyncs[syncIndex] = completedSync;

      // 发送事件
      _emitEvent('federation_sync_completed', {
        'syncId': syncId,
        'syncedTemplates': result['syncedTemplates'],
        'conflicts': result['conflicts'],
      });
    } catch (e) {
      // 更新失败状态
      final failedSync = FederationSync(
        id: sync.id,
        sourceRegistry: sync.sourceRegistry,
        targetRegistry: sync.targetRegistry,
        status: SyncStatus.failed,
        strategy: sync.strategy,
        lastSyncTime: DateTime.now(),
        nextSyncTime: sync.nextSyncTime,
        syncedTemplates: sync.syncedTemplates,
        conflicts: sync.conflicts,
        error: e.toString(),
        config: sync.config,
      );

      _federationSyncs[syncIndex] = failedSync;

      // 发送事件
      _emitEvent('federation_sync_failed', {
        'syncId': syncId,
        'error': e.toString(),
      });

      rethrow;
    }
  }

  /// 配置身份认证
  Future<void> configureAuthentication({
    required AuthenticationType authType,
    required Map<String, dynamic> authConfig,
  }) async {
    _authProviders[authType.name] = {
      'type': authType.name,
      'config': authConfig,
      'configuredAt': DateTime.now().toIso8601String(),
    };

    // 发送事件
    _emitEvent('authentication_configured', {
      'authType': authType.name,
      'configuredAt': DateTime.now().toIso8601String(),
    });
  }

  /// 获取注册表统计
  Map<String, dynamic> getRegistryStats() {
    final tenants = _tenants.values.toList();
    final activeTenants = tenants.where((t) => t.isActive).length;
    final totalStorage = tenants.fold(0, (sum, t) => sum + t.storageUsed);
    final totalUsers = tenants.fold(0, (sum, t) => sum + t.currentUsers);

    return {
      'registryId': _config.id,
      'registryName': _config.name,
      'registryType': _config.type.name,
      'deploymentMode': _config.deploymentMode.name,
      'multiTenant': _config.multiTenant,
      'tenants': {
        'total': tenants.length,
        'active': activeTenants,
        'nearQuota': tenants.where((t) => t.isNearQuota).length,
      },
      'storage': {
        'totalUsed': totalStorage,
        'averageUsage': tenants.isNotEmpty ? totalStorage / tenants.length : 0,
      },
      'users': {
        'total': totalUsers,
        'averagePerTenant':
            tenants.isNotEmpty ? totalUsers / tenants.length : 0,
      },
      'federation': {
        'totalSyncs': _federationSyncs.length,
        'activeSyncs': _federationSyncs
            .where((s) => s.status == SyncStatus.syncing)
            .length,
        'conflictSyncs': _federationSyncs.where((s) => s.hasConflicts).length,
      },
      'authentication': {
        'providers': _authProviders.keys.toList(),
        'primaryType': _config.authType.name,
      },
    };
  }

  /// 添加事件监听器
  void addEventListener(void Function(String, Map<String, dynamic>) listener) {
    _eventListeners.add(listener);
  }

  /// 移除事件监听器
  void removeEventListener(
      void Function(String, Map<String, dynamic>) listener,) {
    _eventListeners.remove(listener);
  }

  /// 初始化注册表
  void _initializeRegistry() {
    // 初始化存储提供者
    _storageProviders['local'] = {
      'type': 'local',
      'path': './registry_data',
      'initialized': true,
    };

    // 初始化认证提供者
    _authProviders[_config.authType.name] = {
      'type': _config.authType.name,
      'config': _config.authConfig,
      'initialized': true,
    };

    // 初始化监控指标
    _metrics['startTime'] = DateTime.now().toIso8601String();
    _metrics['requests'] = 0;
    _metrics['errors'] = 0;
  }

  /// 初始化租户存储
  Future<void> _initializeTenantStorage(TenantInfo tenant) async {
    // 模拟存储初始化
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // 创建租户目录结构
    // final tenantPath = './registry_data/tenants/${tenant.id}';
    // 在实际实现中，这里会创建实际的目录结构
  }

  /// 清理租户数据
  Future<void> _cleanupTenantData(TenantInfo tenant) async {
    // 模拟数据清理
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // 删除租户数据
    // final tenantPath = './registry_data/tenants/${tenant.id}';
    // 在实际实现中，这里会删除实际的数据
  }

  /// 执行同步
  Future<Map<String, dynamic>> _performSync(FederationSync sync) async {
    // 模拟同步过程
    await Future<void>.delayed(const Duration(seconds: 1));

    // 模拟同步结果
    return {
      'syncedTemplates': 50,
      'conflicts': 2,
      'duration': 1000,
    };
  }

  /// 生成租户ID
  String _generateTenantId(String name) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final normalized = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    return '${normalized}_$timestamp';
  }

  /// 生成同步ID
  String _generateSyncId(String source, String target) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'sync_${source}_${target}_$timestamp';
  }

  /// 发送事件
  void _emitEvent(String eventType, Map<String, dynamic> data) {
    for (final listener in _eventListeners) {
      try {
        listener(eventType, data);
      } catch (e) {
        // 忽略监听器错误
      }
    }
  }
}
