/*
---------------------------------------------------------------
File name:          lifecycle_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        生命周期管理器 (Lifecycle Manager)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.4 企业级模板管理;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';

/// 生命周期状态枚举
enum LifecycleState {
  /// 开发中
  development,

  /// 测试中
  testing,

  /// 预发布
  prerelease,

  /// 已发布
  released,

  /// 维护中
  maintenance,

  /// 已弃用
  deprecated,

  /// 已归档
  archived,

  /// 已删除
  deleted,
}

/// 版本策略枚举
enum VersionStrategy {
  /// 语义化版本
  semantic,

  /// 时间戳版本
  timestamp,

  /// 构建号版本
  buildNumber,

  /// 自定义版本
  custom,
}

/// 审批状态枚举
enum ApprovalStatus {
  /// 待审批
  pending,

  /// 已批准
  approved,

  /// 已拒绝
  rejected,

  /// 已撤回
  withdrawn,

  /// 已过期
  expired,
}

/// 生命周期事件类型枚举
enum LifecycleEventType {
  /// 状态变更
  stateChange,

  /// 版本发布
  versionRelease,

  /// 审批请求
  approvalRequest,

  /// 审批决定
  approvalDecision,

  /// 自动化操作
  automation,

  /// 手动操作
  manual,
}

/// 模板版本信息
class TemplateVersion {
  /// 版本ID
  final String id;

  /// 模板ID
  final String templateId;

  /// 版本号
  final String version;

  /// 版本名称
  final String? name;

  /// 版本描述
  final String description;

  /// 生命周期状态
  final LifecycleState state;

  /// 创建时间
  final DateTime createdAt;

  /// 发布时间
  final DateTime? releasedAt;

  /// 创建者
  final String createdBy;

  /// 变更日志
  final List<String> changelog;

  /// 依赖信息
  final Map<String, String> dependencies;

  /// 兼容性信息
  final Map<String, dynamic> compatibility;

  /// 元数据
  final Map<String, dynamic> metadata;

  const TemplateVersion({
    required this.id,
    required this.templateId,
    required this.version,
    this.name,
    required this.description,
    required this.state,
    required this.createdAt,
    this.releasedAt,
    required this.createdBy,
    required this.changelog,
    required this.dependencies,
    required this.compatibility,
    required this.metadata,
  });

  /// 是否已发布
  bool get isReleased => state == LifecycleState.released;

  /// 是否已弃用
  bool get isDeprecated => state == LifecycleState.deprecated;

  /// 是否可用
  bool get isAvailable => [
        LifecycleState.released,
        LifecycleState.maintenance,
      ].contains(state);
}

/// 审批请求
class ApprovalRequest {
  /// 请求ID
  final String id;

  /// 模板版本ID
  final String versionId;

  /// 请求类型
  final String requestType;

  /// 请求者
  final String requestedBy;

  /// 请求时间
  final DateTime requestedAt;

  /// 目标状态
  final LifecycleState targetState;

  /// 当前状态
  final LifecycleState currentState;

  /// 审批状态
  final ApprovalStatus status;

  /// 审批者列表
  final List<String> approvers;

  /// 已审批者
  final List<String> approvedBy;

  /// 拒绝者
  final List<String> rejectedBy;

  /// 请求原因
  final String reason;

  /// 审批意见
  final List<Map<String, dynamic>> comments;

  /// 过期时间
  final DateTime? expiresAt;

  const ApprovalRequest({
    required this.id,
    required this.versionId,
    required this.requestType,
    required this.requestedBy,
    required this.requestedAt,
    required this.targetState,
    required this.currentState,
    required this.status,
    required this.approvers,
    required this.approvedBy,
    required this.rejectedBy,
    required this.reason,
    required this.comments,
    this.expiresAt,
  });

  /// 是否需要审批
  bool get needsApproval => status == ApprovalStatus.pending;

  /// 是否已过期
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// 审批进度
  double get approvalProgress =>
      approvers.isNotEmpty ? approvedBy.length / approvers.length : 0.0;
}

/// 生命周期事件
class LifecycleEvent {
  /// 事件ID
  final String id;

  /// 模板版本ID
  final String versionId;

  /// 事件类型
  final LifecycleEventType eventType;

  /// 事件时间
  final DateTime timestamp;

  /// 操作者
  final String actor;

  /// 前状态
  final LifecycleState? fromState;

  /// 后状态
  final LifecycleState? toState;

  /// 事件描述
  final String description;

  /// 事件数据
  final Map<String, dynamic> data;

  /// 是否自动化
  final bool automated;

  const LifecycleEvent({
    required this.id,
    required this.versionId,
    required this.eventType,
    required this.timestamp,
    required this.actor,
    this.fromState,
    this.toState,
    required this.description,
    required this.data,
    required this.automated,
  });
}

/// 版本策略配置
class VersionStrategyConfig {
  /// 策略类型
  final VersionStrategy strategy;

  /// 版本格式
  final String format;

  /// 自动递增规则
  final Map<String, dynamic> incrementRules;

  /// 分支策略
  final Map<String, String> branchStrategy;

  /// 标签策略
  final Map<String, String> tagStrategy;

  const VersionStrategyConfig({
    required this.strategy,
    required this.format,
    required this.incrementRules,
    required this.branchStrategy,
    required this.tagStrategy,
  });
}

/// 生命周期管理器
class LifecycleManager {
  /// 模板版本列表
  final Map<String, TemplateVersion> _versions = {};

  /// 审批请求列表
  final Map<String, ApprovalRequest> _approvalRequests = {};

  /// 生命周期事件列表
  final List<LifecycleEvent> _events = [];

  /// 版本策略配置
  final Map<String, VersionStrategyConfig> _versionStrategies = {};

  /// 自动化规则
  final Map<String, Map<String, dynamic>> _automationRules = {};

  /// 通知配置
  final Map<String, List<String>> _notificationConfig = {};

  /// 构造函数
  LifecycleManager() {
    _initializeDefaultStrategies();
    _initializeAutomationRules();
  }

  /// 创建模板版本
  Future<TemplateVersion> createVersion({
    required String templateId,
    required String version,
    String? name,
    required String description,
    required String createdBy,
    List<String>? changelog,
    Map<String, String>? dependencies,
    Map<String, dynamic>? compatibility,
    Map<String, dynamic>? metadata,
  }) async {
    final versionId = _generateVersionId(templateId, version);

    final templateVersion = TemplateVersion(
      id: versionId,
      templateId: templateId,
      version: version,
      name: name,
      description: description,
      state: LifecycleState.development,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      changelog: changelog ?? [],
      dependencies: dependencies ?? {},
      compatibility: compatibility ?? {},
      metadata: metadata ?? {},
    );

    _versions[versionId] = templateVersion;

    // 记录事件
    await _recordEvent(
      versionId: versionId,
      eventType: LifecycleEventType.stateChange,
      actor: createdBy,
      toState: LifecycleState.development,
      description: 'Version created',
      data: {
        'version': version,
        'templateId': templateId,
      },
      automated: false,
    );

    return templateVersion;
  }

  /// 请求状态变更
  Future<ApprovalRequest> requestStateChange({
    required String versionId,
    required LifecycleState targetState,
    required String requestedBy,
    required String reason,
    List<String>? approvers,
    DateTime? expiresAt,
  }) async {
    final version = _versions[versionId];
    if (version == null) {
      throw Exception('Version not found: $versionId');
    }

    // 检查状态转换是否有效
    if (!_isValidStateTransition(version.state, targetState)) {
      throw Exception(
          'Invalid state transition: ${version.state} -> $targetState');
    }

    final requestId = _generateRequestId(versionId);
    final requestType = 'state_change';

    // 确定审批者
    final finalApprovers = approvers ?? await _getDefaultApprovers(targetState);

    final approvalRequest = ApprovalRequest(
      id: requestId,
      versionId: versionId,
      requestType: requestType,
      requestedBy: requestedBy,
      requestedAt: DateTime.now(),
      targetState: targetState,
      currentState: version.state,
      status: ApprovalStatus.pending,
      approvers: finalApprovers,
      approvedBy: [],
      rejectedBy: [],
      reason: reason,
      comments: [],
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 7)),
    );

    _approvalRequests[requestId] = approvalRequest;

    // 记录事件
    await _recordEvent(
      versionId: versionId,
      eventType: LifecycleEventType.approvalRequest,
      actor: requestedBy,
      description: 'State change requested: ${version.state} -> $targetState',
      data: {
        'requestId': requestId,
        'targetState': targetState.name,
        'reason': reason,
      },
      automated: false,
    );

    // 发送通知
    await _sendNotifications('approval_request', {
      'requestId': requestId,
      'versionId': versionId,
      'requestedBy': requestedBy,
      'targetState': targetState.name,
      'approvers': finalApprovers,
    });

    return approvalRequest;
  }

  /// 审批请求
  Future<void> approveRequest({
    required String requestId,
    required String approver,
    String? comment,
  }) async {
    final request = _approvalRequests[requestId];
    if (request == null) {
      throw Exception('Approval request not found: $requestId');
    }

    if (request.status != ApprovalStatus.pending) {
      throw Exception('Request is not pending approval');
    }

    if (!request.approvers.contains(approver)) {
      throw Exception('User is not authorized to approve this request');
    }

    if (request.approvedBy.contains(approver)) {
      throw Exception('User has already approved this request');
    }

    // 添加审批
    final updatedApprovedBy = [...request.approvedBy, approver];
    final comments = [...request.comments];

    if (comment != null) {
      comments.add({
        'approver': approver,
        'comment': comment,
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'approve',
      });
    }

    // 检查是否所有审批者都已审批
    final allApproved =
        request.approvers.every((a) => updatedApprovedBy.contains(a));
    final newStatus =
        allApproved ? ApprovalStatus.approved : ApprovalStatus.pending;

    final updatedRequest = ApprovalRequest(
      id: request.id,
      versionId: request.versionId,
      requestType: request.requestType,
      requestedBy: request.requestedBy,
      requestedAt: request.requestedAt,
      targetState: request.targetState,
      currentState: request.currentState,
      status: newStatus,
      approvers: request.approvers,
      approvedBy: updatedApprovedBy,
      rejectedBy: request.rejectedBy,
      reason: request.reason,
      comments: comments,
      expiresAt: request.expiresAt,
    );

    _approvalRequests[requestId] = updatedRequest;

    // 记录事件
    await _recordEvent(
      versionId: request.versionId,
      eventType: LifecycleEventType.approvalDecision,
      actor: approver,
      description: 'Request approved by $approver',
      data: {
        'requestId': requestId,
        'comment': comment,
        'allApproved': allApproved,
      },
      automated: false,
    );

    // 如果全部审批通过，执行状态变更
    if (allApproved) {
      await _executeStateChange(
          request.versionId, request.targetState, 'system');
    }
  }

  /// 拒绝请求
  Future<void> rejectRequest({
    required String requestId,
    required String approver,
    required String reason,
  }) async {
    final request = _approvalRequests[requestId];
    if (request == null) {
      throw Exception('Approval request not found: $requestId');
    }

    if (request.status != ApprovalStatus.pending) {
      throw Exception('Request is not pending approval');
    }

    if (!request.approvers.contains(approver)) {
      throw Exception('User is not authorized to reject this request');
    }

    // 添加拒绝
    final comments = [...request.comments];
    comments.add({
      'approver': approver,
      'comment': reason,
      'timestamp': DateTime.now().toIso8601String(),
      'action': 'reject',
    });

    final updatedRequest = ApprovalRequest(
      id: request.id,
      versionId: request.versionId,
      requestType: request.requestType,
      requestedBy: request.requestedBy,
      requestedAt: request.requestedAt,
      targetState: request.targetState,
      currentState: request.currentState,
      status: ApprovalStatus.rejected,
      approvers: request.approvers,
      approvedBy: request.approvedBy,
      rejectedBy: [...request.rejectedBy, approver],
      reason: request.reason,
      comments: comments,
      expiresAt: request.expiresAt,
    );

    _approvalRequests[requestId] = updatedRequest;

    // 记录事件
    await _recordEvent(
      versionId: request.versionId,
      eventType: LifecycleEventType.approvalDecision,
      actor: approver,
      description: 'Request rejected by $approver',
      data: {
        'requestId': requestId,
        'reason': reason,
      },
      automated: false,
    );
  }

  /// 配置版本策略
  Future<void> configureVersionStrategy({
    required String templateId,
    required VersionStrategy strategy,
    required String format,
    Map<String, dynamic>? incrementRules,
    Map<String, String>? branchStrategy,
    Map<String, String>? tagStrategy,
  }) async {
    final config = VersionStrategyConfig(
      strategy: strategy,
      format: format,
      incrementRules: incrementRules ?? {},
      branchStrategy: branchStrategy ?? {},
      tagStrategy: tagStrategy ?? {},
    );

    _versionStrategies[templateId] = config;
  }

  /// 生成下一个版本号
  String generateNextVersion(String templateId, String currentVersion) {
    final strategy = _versionStrategies[templateId];
    if (strategy == null) {
      // 默认语义化版本递增
      return _incrementSemanticVersion(currentVersion, 'patch');
    }

    switch (strategy.strategy) {
      case VersionStrategy.semantic:
        return _incrementSemanticVersion(currentVersion, 'patch');
      case VersionStrategy.timestamp:
        return DateTime.now().millisecondsSinceEpoch.toString();
      case VersionStrategy.buildNumber:
        final buildNumber = int.tryParse(currentVersion) ?? 0;
        return (buildNumber + 1).toString();
      case VersionStrategy.custom:
        return _applyCustomVersionStrategy(strategy, currentVersion);
    }
  }

  /// 获取版本历史
  List<TemplateVersion> getVersionHistory(String templateId) {
    return _versions.values.where((v) => v.templateId == templateId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取生命周期事件
  List<LifecycleEvent> getLifecycleEvents({
    String? versionId,
    LifecycleEventType? eventType,
    DateTime? since,
    int? limit,
  }) {
    var events = _events.where((event) {
      if (versionId != null && event.versionId != versionId) return false;
      if (eventType != null && event.eventType != eventType) return false;
      if (since != null && event.timestamp.isBefore(since)) return false;
      return true;
    }).toList();

    // 按时间倒序排列
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && events.length > limit) {
      events = events.take(limit).toList();
    }

    return events;
  }

  /// 获取待审批请求
  List<ApprovalRequest> getPendingApprovals({String? approver}) {
    return _approvalRequests.values.where((request) {
      if (request.status != ApprovalStatus.pending) return false;
      if (request.isExpired) return false;
      if (approver != null && !request.approvers.contains(approver))
        return false;
      return true;
    }).toList()
      ..sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
  }

  /// 获取生命周期统计
  Map<String, dynamic> getLifecycleStats() {
    final versionsByState = <String, int>{};
    for (final state in LifecycleState.values) {
      versionsByState[state.name] =
          _versions.values.where((v) => v.state == state).length;
    }

    final requestsByStatus = <String, int>{};
    for (final status in ApprovalStatus.values) {
      requestsByStatus[status.name] =
          _approvalRequests.values.where((r) => r.status == status).length;
    }

    return {
      'versions': {
        'total': _versions.length,
        'byState': versionsByState,
        'released': _versions.values.where((v) => v.isReleased).length,
        'deprecated': _versions.values.where((v) => v.isDeprecated).length,
      },
      'approvals': {
        'total': _approvalRequests.length,
        'pending':
            _approvalRequests.values.where((r) => r.needsApproval).length,
        'expired': _approvalRequests.values.where((r) => r.isExpired).length,
        'byStatus': requestsByStatus,
      },
      'events': {
        'total': _events.length,
        'recent': _events
            .where((e) => DateTime.now().difference(e.timestamp).inHours < 24)
            .length,
        'automated': _events.where((e) => e.automated).length,
      },
      'strategies': {
        'configured': _versionStrategies.length,
        'automationRules': _automationRules.length,
      },
    };
  }

  /// 执行状态变更
  Future<void> _executeStateChange(
    String versionId,
    LifecycleState targetState,
    String actor,
  ) async {
    final version = _versions[versionId];
    if (version == null) return;

    final fromState = version.state;

    // 更新版本状态
    final updatedVersion = TemplateVersion(
      id: version.id,
      templateId: version.templateId,
      version: version.version,
      name: version.name,
      description: version.description,
      state: targetState,
      createdAt: version.createdAt,
      releasedAt: targetState == LifecycleState.released
          ? DateTime.now()
          : version.releasedAt,
      createdBy: version.createdBy,
      changelog: version.changelog,
      dependencies: version.dependencies,
      compatibility: version.compatibility,
      metadata: version.metadata,
    );

    _versions[versionId] = updatedVersion;

    // 记录事件
    await _recordEvent(
      versionId: versionId,
      eventType: LifecycleEventType.stateChange,
      actor: actor,
      fromState: fromState,
      toState: targetState,
      description:
          'State changed from ${fromState.name} to ${targetState.name}',
      data: {
        'fromState': fromState.name,
        'toState': targetState.name,
      },
      automated: actor == 'system',
    );

    // 执行自动化规则
    await _executeAutomationRules(versionId, targetState);
  }

  /// 检查状态转换是否有效
  bool _isValidStateTransition(LifecycleState from, LifecycleState to) {
    // 定义有效的状态转换
    const validTransitions = {
      LifecycleState.development: [
        LifecycleState.testing,
        LifecycleState.archived,
      ],
      LifecycleState.testing: [
        LifecycleState.development,
        LifecycleState.prerelease,
        LifecycleState.archived,
      ],
      LifecycleState.prerelease: [
        LifecycleState.testing,
        LifecycleState.released,
        LifecycleState.archived,
      ],
      LifecycleState.released: [
        LifecycleState.maintenance,
        LifecycleState.deprecated,
      ],
      LifecycleState.maintenance: [
        LifecycleState.deprecated,
        LifecycleState.archived,
      ],
      LifecycleState.deprecated: [
        LifecycleState.archived,
      ],
      LifecycleState.archived: [
        LifecycleState.deleted,
      ],
    };

    return validTransitions[from]?.contains(to) ?? false;
  }

  /// 获取默认审批者
  Future<List<String>> _getDefaultApprovers(LifecycleState targetState) async {
    // 根据目标状态返回默认审批者
    switch (targetState) {
      case LifecycleState.released:
        return ['release_manager', 'tech_lead'];
      case LifecycleState.deprecated:
        return ['product_manager', 'tech_lead'];
      case LifecycleState.archived:
        return ['admin'];
      default:
        return ['tech_lead'];
    }
  }

  /// 记录事件
  Future<void> _recordEvent({
    required String versionId,
    required LifecycleEventType eventType,
    required String actor,
    LifecycleState? fromState,
    LifecycleState? toState,
    required String description,
    required Map<String, dynamic> data,
    required bool automated,
  }) async {
    final event = LifecycleEvent(
      id: _generateEventId(),
      versionId: versionId,
      eventType: eventType,
      timestamp: DateTime.now(),
      actor: actor,
      fromState: fromState,
      toState: toState,
      description: description,
      data: data,
      automated: automated,
    );

    _events.add(event);

    // 保持事件列表在合理范围内
    if (_events.length > 10000) {
      _events.removeRange(0, _events.length - 10000);
    }
  }

  /// 发送通知
  Future<void> _sendNotifications(
      String type, Map<String, dynamic> data) async {
    // 模拟通知发送
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// 执行自动化规则
  Future<void> _executeAutomationRules(
      String versionId, LifecycleState state) async {
    final rules = _automationRules[state.name];
    if (rules == null) return;

    // 模拟自动化规则执行
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 初始化默认策略
  void _initializeDefaultStrategies() {
    _versionStrategies['default'] = const VersionStrategyConfig(
      strategy: VersionStrategy.semantic,
      format: 'MAJOR.MINOR.PATCH',
      incrementRules: {
        'major': 'breaking_changes',
        'minor': 'new_features',
        'patch': 'bug_fixes',
      },
      branchStrategy: {
        'main': 'release',
        'develop': 'development',
        'feature': 'feature_branches',
      },
      tagStrategy: {
        'release': 'v{version}',
        'prerelease': 'v{version}-rc.{build}',
      },
    );
  }

  /// 初始化自动化规则
  void _initializeAutomationRules() {
    _automationRules[LifecycleState.released.name] = {
      'notify_users': true,
      'update_documentation': true,
      'create_backup': true,
    };

    _automationRules[LifecycleState.deprecated.name] = {
      'notify_users': true,
      'update_documentation': true,
      'schedule_removal': true,
    };
  }

  /// 递增语义化版本
  String _incrementSemanticVersion(String version, String type) {
    final parts = version.split('.');
    if (parts.length != 3) return version;

    var major = int.tryParse(parts[0]) ?? 0;
    var minor = int.tryParse(parts[1]) ?? 0;
    var patch = int.tryParse(parts[2]) ?? 0;

    switch (type) {
      case 'major':
        major++;
        minor = 0;
        patch = 0;
        break;
      case 'minor':
        minor++;
        patch = 0;
        break;
      case 'patch':
        patch++;
        break;
    }

    return '$major.$minor.$patch';
  }

  /// 应用自定义版本策略
  String _applyCustomVersionStrategy(
      VersionStrategyConfig strategy, String currentVersion) {
    // 简化实现
    return currentVersion;
  }

  /// 生成版本ID
  String _generateVersionId(String templateId, String version) {
    return '${templateId}_$version';
  }

  /// 生成请求ID
  String _generateRequestId(String versionId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'request_${versionId}_$timestamp';
  }

  /// 生成事件ID
  String _generateEventId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'event_$timestamp';
  }
}
