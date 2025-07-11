/*
---------------------------------------------------------------
File name:          access_control.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        访问控制系统 (Access Control System)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.4 企业级模板管理;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';

/// 权限类型枚举
enum Permission {
  /// 读取权限
  read,

  /// 下载权限
  download,

  /// 上传权限
  upload,

  /// 更新权限
  update,

  /// 删除权限
  delete,

  /// 管理权限
  manage,

  /// 审计权限
  audit,

  /// 配置权限
  configure,
}

/// 角色类型枚举
enum RoleType {
  /// 超级管理员
  superAdmin,

  /// 管理员
  admin,

  /// 开发者
  developer,

  /// 查看者
  viewer,

  /// 审计员
  auditor,

  /// 访客
  guest,
}

/// 资源类型枚举
enum ResourceType {
  /// 模板
  template,

  /// 注册表
  registry,

  /// 租户
  tenant,

  /// 用户
  user,

  /// 角色
  role,

  /// 配置
  configuration,
}

/// 访问结果枚举
enum AccessResult {
  /// 允许
  allow,

  /// 拒绝
  deny,

  /// 需要审批
  requireApproval,

  /// 需要多因子认证
  requireMfa,
}

/// 用户信息
class UserInfo {
  /// 用户ID
  final String id;

  /// 用户名
  final String username;

  /// 邮箱
  final String email;

  /// 显示名称
  final String displayName;

  /// 所属租户ID
  final String tenantId;

  /// 用户状态
  final String status;

  /// 创建时间
  final DateTime createdAt;

  /// 最后登录时间
  final DateTime? lastLoginAt;

  /// 用户属性
  final Map<String, dynamic> attributes;

  /// 用户组
  final List<String> groups;

  /// 部门
  final String? department;

  /// 职位
  final String? position;

  const UserInfo({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.tenantId,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
    required this.attributes,
    required this.groups,
    this.department,
    this.position,
  });

  /// 是否活跃
  bool get isActive => status == 'active';

  /// 是否在线
  bool get isOnline =>
      lastLoginAt != null &&
      DateTime.now().difference(lastLoginAt!).inMinutes < 30;
}

/// 角色定义
class Role {
  /// 角色ID
  final String id;

  /// 角色名称
  final String name;

  /// 角色类型
  final RoleType type;

  /// 角色描述
  final String description;

  /// 权限列表
  final Set<Permission> permissions;

  /// 资源范围
  final Map<ResourceType, List<String>> resourceScope;

  /// 是否可继承
  final bool inheritable;

  /// 父角色ID
  final String? parentRoleId;

  /// 创建时间
  final DateTime createdAt;

  /// 创建者
  final String createdBy;

  /// 角色元数据
  final Map<String, dynamic> metadata;

  const Role({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.permissions,
    required this.resourceScope,
    required this.inheritable,
    this.parentRoleId,
    required this.createdAt,
    required this.createdBy,
    required this.metadata,
  });

  /// 是否有权限
  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }

  /// 是否可访问资源
  bool canAccessResource(ResourceType resourceType, String resourceId) {
    final scope = resourceScope[resourceType];
    return scope == null ||
        scope.isEmpty ||
        scope.contains(resourceId) ||
        scope.contains('*');
  }
}

/// 用户角色分配
class UserRoleAssignment {
  /// 分配ID
  final String id;

  /// 用户ID
  final String userId;

  /// 角色ID
  final String roleId;

  /// 资源范围
  final Map<ResourceType, List<String>> resourceScope;

  /// 分配时间
  final DateTime assignedAt;

  /// 分配者
  final String assignedBy;

  /// 过期时间
  final DateTime? expiresAt;

  /// 是否活跃
  final bool active;

  /// 分配原因
  final String? reason;

  /// 条件
  final Map<String, dynamic> conditions;

  const UserRoleAssignment({
    required this.id,
    required this.userId,
    required this.roleId,
    required this.resourceScope,
    required this.assignedAt,
    required this.assignedBy,
    this.expiresAt,
    required this.active,
    this.reason,
    required this.conditions,
  });

  /// 是否过期
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// 是否有效
  bool get isValid => active && !isExpired;
}

/// 访问请求
class AccessRequest {
  /// 请求ID
  final String id;

  /// 用户ID
  final String userId;

  /// 资源类型
  final ResourceType resourceType;

  /// 资源ID
  final String resourceId;

  /// 请求的权限
  final Permission permission;

  /// 请求时间
  final DateTime requestTime;

  /// 请求上下文
  final Map<String, dynamic> context;

  /// IP地址
  final String? ipAddress;

  /// 用户代理
  final String? userAgent;

  /// 会话ID
  final String? sessionId;

  const AccessRequest({
    required this.id,
    required this.userId,
    required this.resourceType,
    required this.resourceId,
    required this.permission,
    required this.requestTime,
    required this.context,
    this.ipAddress,
    this.userAgent,
    this.sessionId,
  });
}

/// 访问决策
class AccessDecision {
  /// 决策结果
  final AccessResult result;

  /// 决策原因
  final String reason;

  /// 决策时间
  final DateTime decisionTime;

  /// 决策者
  final String? decisionMaker;

  /// 有效期
  final Duration? validity;

  /// 条件
  final Map<String, dynamic> conditions;

  /// 审计信息
  final Map<String, dynamic> auditInfo;

  const AccessDecision({
    required this.result,
    required this.reason,
    required this.decisionTime,
    this.decisionMaker,
    this.validity,
    required this.conditions,
    required this.auditInfo,
  });

  /// 是否允许访问
  bool get isAllowed => result == AccessResult.allow;

  /// 是否拒绝访问
  bool get isDenied => result == AccessResult.deny;

  /// 是否需要额外验证
  bool get needsAdditionalAuth =>
      result == AccessResult.requireApproval ||
      result == AccessResult.requireMfa;
}

/// 审计日志条目
class AuditLogEntry {
  /// 日志ID
  final String id;

  /// 用户ID
  final String userId;

  /// 操作类型
  final String operation;

  /// 资源类型
  final ResourceType resourceType;

  /// 资源ID
  final String resourceId;

  /// 操作结果
  final bool success;

  /// 操作时间
  final DateTime timestamp;

  /// IP地址
  final String? ipAddress;

  /// 用户代理
  final String? userAgent;

  /// 操作详情
  final Map<String, dynamic> details;

  /// 错误信息
  final String? error;

  const AuditLogEntry({
    required this.id,
    required this.userId,
    required this.operation,
    required this.resourceType,
    required this.resourceId,
    required this.success,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    required this.details,
    this.error,
  });
}

/// 访问控制系统
class AccessControl {
  /// 用户列表
  final Map<String, UserInfo> _users = {};

  /// 角色列表
  final Map<String, Role> _roles = {};

  /// 用户角色分配
  final List<UserRoleAssignment> _userRoleAssignments = [];

  /// 审计日志
  final List<AuditLogEntry> _auditLogs = [];

  /// 访问策略
  final Map<String, dynamic> _accessPolicies = {};

  /// SSO配置
  final Map<String, dynamic> _ssoConfig = {};

  /// 会话管理
  final Map<String, Map<String, dynamic>> _sessions = {};

  /// 构造函数
  AccessControl() {
    _initializeDefaultRoles();
  }

  /// 创建用户
  Future<UserInfo> createUser({
    required String username,
    required String email,
    required String displayName,
    required String tenantId,
    String? department,
    String? position,
    Map<String, dynamic>? attributes,
    List<String>? groups,
  }) async {
    final userId = _generateUserId(username);

    final user = UserInfo(
      id: userId,
      username: username,
      email: email,
      displayName: displayName,
      tenantId: tenantId,
      status: 'active',
      createdAt: DateTime.now(),
      attributes: attributes ?? {},
      groups: groups ?? [],
      department: department,
      position: position,
    );

    _users[userId] = user;

    // 记录审计日志
    await _recordAuditLog(
      userId: 'system',
      operation: 'create_user',
      resourceType: ResourceType.user,
      resourceId: userId,
      success: true,
      details: {
        'username': username,
        'email': email,
        'tenantId': tenantId,
      },
    );

    return user;
  }

  /// 创建角色
  Future<Role> createRole({
    required String name,
    required RoleType type,
    required String description,
    required Set<Permission> permissions,
    Map<ResourceType, List<String>>? resourceScope,
    bool inheritable = true,
    String? parentRoleId,
    required String createdBy,
    Map<String, dynamic>? metadata,
  }) async {
    final roleId = _generateRoleId(name);

    final role = Role(
      id: roleId,
      name: name,
      type: type,
      description: description,
      permissions: permissions,
      resourceScope: resourceScope ?? {},
      inheritable: inheritable,
      parentRoleId: parentRoleId,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      metadata: metadata ?? {},
    );

    _roles[roleId] = role;

    // 记录审计日志
    await _recordAuditLog(
      userId: createdBy,
      operation: 'create_role',
      resourceType: ResourceType.role,
      resourceId: roleId,
      success: true,
      details: {
        'name': name,
        'type': type.name,
        'permissions': permissions.map((p) => p.name).toList(),
      },
    );

    return role;
  }

  /// 分配角色给用户
  Future<UserRoleAssignment> assignRoleToUser({
    required String userId,
    required String roleId,
    Map<ResourceType, List<String>>? resourceScope,
    required String assignedBy,
    DateTime? expiresAt,
    String? reason,
    Map<String, dynamic>? conditions,
  }) async {
    final assignmentId = _generateAssignmentId(userId, roleId);

    final assignment = UserRoleAssignment(
      id: assignmentId,
      userId: userId,
      roleId: roleId,
      resourceScope: resourceScope ?? {},
      assignedAt: DateTime.now(),
      assignedBy: assignedBy,
      expiresAt: expiresAt,
      active: true,
      reason: reason,
      conditions: conditions ?? {},
    );

    _userRoleAssignments.add(assignment);

    // 记录审计日志
    await _recordAuditLog(
      userId: assignedBy,
      operation: 'assign_role',
      resourceType: ResourceType.user,
      resourceId: userId,
      success: true,
      details: {
        'roleId': roleId,
        'expiresAt': expiresAt?.toIso8601String(),
        'reason': reason,
      },
    );

    return assignment;
  }

  /// 检查访问权限
  Future<AccessDecision> checkAccess(AccessRequest request) async {
    try {
      // 获取用户信息
      final user = _users[request.userId];
      if (user == null || !user.isActive) {
        return AccessDecision(
          result: AccessResult.deny,
          reason: 'User not found or inactive',
          decisionTime: DateTime.now(),
          conditions: {},
          auditInfo: {'userId': request.userId},
        );
      }

      // 获取用户角色
      final userRoles = await _getUserRoles(request.userId);
      if (userRoles.isEmpty) {
        return AccessDecision(
          result: AccessResult.deny,
          reason: 'No roles assigned to user',
          decisionTime: DateTime.now(),
          conditions: {},
          auditInfo: {'userId': request.userId},
        );
      }

      // 检查权限
      bool hasPermission = false;
      String? grantingRole;

      for (final roleAssignment in userRoles) {
        if (!roleAssignment.isValid) continue;

        final role = _roles[roleAssignment.roleId];
        if (role == null) continue;

        // 检查权限
        if (role.hasPermission(request.permission)) {
          // 检查资源范围
          if (role.canAccessResource(
              request.resourceType, request.resourceId)) {
            hasPermission = true;
            grantingRole = role.name;
            break;
          }
        }
      }

      final result = hasPermission ? AccessResult.allow : AccessResult.deny;
      final reason = hasPermission
          ? 'Access granted by role: $grantingRole'
          : 'Insufficient permissions';

      final decision = AccessDecision(
        result: result,
        reason: reason,
        decisionTime: DateTime.now(),
        decisionMaker: 'system',
        conditions: {},
        auditInfo: {
          'userId': request.userId,
          'resourceType': request.resourceType.name,
          'resourceId': request.resourceId,
          'permission': request.permission.name,
          'grantingRole': grantingRole,
        },
      );

      // 记录审计日志
      await _recordAuditLog(
        userId: request.userId,
        operation: 'access_check',
        resourceType: request.resourceType,
        resourceId: request.resourceId,
        success: hasPermission,
        details: {
          'permission': request.permission.name,
          'result': result.name,
          'reason': reason,
        },
        ipAddress: request.ipAddress,
        userAgent: request.userAgent,
      );

      return decision;
    } catch (e) {
      // 记录错误
      await _recordAuditLog(
        userId: request.userId,
        operation: 'access_check',
        resourceType: request.resourceType,
        resourceId: request.resourceId,
        success: false,
        error: e.toString(),
        details: {
          'permission': request.permission.name,
        },
      );

      return AccessDecision(
        result: AccessResult.deny,
        reason: 'Access check failed: $e',
        decisionTime: DateTime.now(),
        conditions: {},
        auditInfo: {'error': e.toString()},
      );
    }
  }

  /// 配置SSO
  Future<void> configureSso({
    required String provider,
    required Map<String, dynamic> config,
  }) async {
    _ssoConfig[provider] = {
      'config': config,
      'configuredAt': DateTime.now().toIso8601String(),
      'enabled': true,
    };
  }

  /// 获取用户角色
  Future<List<UserRoleAssignment>> _getUserRoles(String userId) async {
    return _userRoleAssignments
        .where(
            (assignment) => assignment.userId == userId && assignment.isValid)
        .toList();
  }

  /// 获取审计日志
  List<AuditLogEntry> getAuditLogs({
    String? userId,
    ResourceType? resourceType,
    DateTime? since,
    int? limit,
  }) {
    var logs = _auditLogs.where((log) {
      if (userId != null && log.userId != userId) return false;
      if (resourceType != null && log.resourceType != resourceType)
        return false;
      if (since != null && log.timestamp.isBefore(since)) return false;
      return true;
    }).toList();

    // 按时间倒序排列
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && logs.length > limit) {
      logs = logs.take(limit).toList();
    }

    return logs;
  }

  /// 获取访问控制统计
  Map<String, dynamic> getAccessControlStats() {
    final activeUsers = _users.values.where((u) => u.isActive).length;
    final onlineUsers = _users.values.where((u) => u.isOnline).length;
    final totalRoles = _roles.length;
    final activeAssignments =
        _userRoleAssignments.where((a) => a.isValid).length;

    return {
      'users': {
        'total': _users.length,
        'active': activeUsers,
        'online': onlineUsers,
      },
      'roles': {
        'total': totalRoles,
        'byType': _getRoleTypeDistribution(),
      },
      'assignments': {
        'total': _userRoleAssignments.length,
        'active': activeAssignments,
        'expired': _userRoleAssignments.where((a) => a.isExpired).length,
      },
      'audit': {
        'totalLogs': _auditLogs.length,
        'recentLogs': _auditLogs
            .where(
                (log) => DateTime.now().difference(log.timestamp).inHours < 24)
            .length,
      },
      'sso': {
        'providers': _ssoConfig.keys.toList(),
        'enabled': _ssoConfig.values
            .where((config) => config['enabled'] == true)
            .length,
      },
    };
  }

  /// 初始化默认角色
  void _initializeDefaultRoles() {
    // 超级管理员角色
    _roles['super_admin'] = Role(
      id: 'super_admin',
      name: 'Super Administrator',
      type: RoleType.superAdmin,
      description: 'Full system access',
      permissions: Permission.values.toSet(),
      resourceScope: {},
      inheritable: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
      metadata: {'system': true},
    );

    // 管理员角色
    _roles['admin'] = Role(
      id: 'admin',
      name: 'Administrator',
      type: RoleType.admin,
      description: 'Administrative access',
      permissions: {
        Permission.read,
        Permission.download,
        Permission.upload,
        Permission.update,
        Permission.manage,
        Permission.audit,
      },
      resourceScope: {},
      inheritable: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
      metadata: {'system': true},
    );

    // 开发者角色
    _roles['developer'] = Role(
      id: 'developer',
      name: 'Developer',
      type: RoleType.developer,
      description: 'Development access',
      permissions: {
        Permission.read,
        Permission.download,
        Permission.upload,
        Permission.update,
      },
      resourceScope: {},
      inheritable: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
      metadata: {'system': true},
    );

    // 查看者角色
    _roles['viewer'] = Role(
      id: 'viewer',
      name: 'Viewer',
      type: RoleType.viewer,
      description: 'Read-only access',
      permissions: {
        Permission.read,
        Permission.download,
      },
      resourceScope: {},
      inheritable: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
      metadata: {'system': true},
    );
  }

  /// 记录审计日志
  Future<void> _recordAuditLog({
    required String userId,
    required String operation,
    required ResourceType resourceType,
    required String resourceId,
    required bool success,
    Map<String, dynamic>? details,
    String? error,
    String? ipAddress,
    String? userAgent,
  }) async {
    final logEntry = AuditLogEntry(
      id: _generateLogId(),
      userId: userId,
      operation: operation,
      resourceType: resourceType,
      resourceId: resourceId,
      success: success,
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      details: details ?? {},
      error: error,
    );

    _auditLogs.add(logEntry);

    // 保持日志在合理范围内
    if (_auditLogs.length > 100000) {
      _auditLogs.removeRange(0, _auditLogs.length - 100000);
    }
  }

  /// 获取角色类型分布
  Map<String, int> _getRoleTypeDistribution() {
    final distribution = <String, int>{};
    for (final type in RoleType.values) {
      distribution[type.name] =
          _roles.values.where((r) => r.type == type).length;
    }
    return distribution;
  }

  /// 生成用户ID
  String _generateUserId(String username) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'user_${username}_$timestamp';
  }

  /// 生成角色ID
  String _generateRoleId(String name) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final normalized = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return 'role_${normalized}_$timestamp';
  }

  /// 生成分配ID
  String _generateAssignmentId(String userId, String roleId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'assignment_${userId}_${roleId}_$timestamp';
  }

  /// 生成日志ID
  String _generateLogId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'log_$timestamp';
  }
}
