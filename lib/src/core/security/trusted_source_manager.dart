/*
---------------------------------------------------------------
File name:          trusted_source_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        可信源管理器 (Trusted Source Manager)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.2 企业级安全验证系统;
---------------------------------------------------------------
*/

import 'dart:async';

/// 可信源级别枚举
enum TrustLevel {
  /// 官方源 - 最高信任级别
  official,

  /// 认证源 - 经过认证的第三方
  certified,

  /// 社区源 - 社区验证的源
  community,

  /// 未知源 - 未验证的源
  unknown,

  /// 不可信源 - 明确标记为不可信
  untrusted,
}

/// 可信源状态枚举
enum TrustSourceStatus {
  /// 活跃
  active,

  /// 暂停
  suspended,

  /// 已撤销
  revoked,

  /// 待审核
  pending,

  /// 已过期
  expired,
}

/// 可信源信息
class TrustedSource {
  const TrustedSource({
    required this.id,
    required this.name,
    required this.url,
    required this.trustLevel,
    required this.status,
    required this.createdAt,
    required this.lastVerifiedAt,
    required this.reputationScore,
    required this.verificationCount,
    required this.failureCount,
    required this.tags,
    required this.metadata,
    this.certificateFingerprint,
    this.publicKeyFingerprint,
    this.expiresAt,
  });

  /// 源标识符
  final String id;

  /// 源名称
  final String name;

  /// 源URL或域名
  final String url;

  /// 信任级别
  final TrustLevel trustLevel;

  /// 源状态
  final TrustSourceStatus status;

  /// 证书指纹
  final String? certificateFingerprint;

  /// 公钥指纹
  final String? publicKeyFingerprint;

  /// 创建时间
  final DateTime createdAt;

  /// 最后验证时间
  final DateTime lastVerifiedAt;

  /// 过期时间
  final DateTime? expiresAt;

  /// 信誉评分 (0-100)
  final int reputationScore;

  /// 验证次数
  final int verificationCount;

  /// 失败次数
  final int failureCount;

  /// 标签
  final List<String> tags;

  /// 元数据
  final Map<String, dynamic> metadata;

  /// 是否活跃
  bool get isActive => status == TrustSourceStatus.active;

  /// 是否过期
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// 是否可信
  bool get isTrusted =>
      isActive && !isExpired && trustLevel != TrustLevel.untrusted;

  /// 成功率
  double get successRate {
    final total = verificationCount + failureCount;
    return total > 0 ? verificationCount / total : 0.0;
  }

  /// 信任评级
  String get trustRating {
    if (reputationScore >= 90) return 'Excellent';
    if (reputationScore >= 80) return 'Good';
    if (reputationScore >= 70) return 'Fair';
    if (reputationScore >= 60) return 'Poor';
    return 'Very Poor';
  }
}

/// 信誉事件类型
enum ReputationEventType {
  /// 成功验证
  successfulVerification,

  /// 验证失败
  verificationFailure,

  /// 安全事件
  securityIncident,

  /// 用户举报
  userReport,

  /// 管理员操作
  adminAction,
}

/// 信誉事件
class ReputationEvent {
  const ReputationEvent({
    required this.id,
    required this.sourceId,
    required this.type,
    required this.description,
    required this.impact,
    required this.timestamp,
    required this.metadata,
  });

  /// 事件ID
  final String id;

  /// 源ID
  final String sourceId;

  /// 事件类型
  final ReputationEventType type;

  /// 事件描述
  final String description;

  /// 影响分数 (可正可负)
  final int impact;

  /// 事件时间
  final DateTime timestamp;

  /// 事件元数据
  final Map<String, dynamic> metadata;
}

/// 证书透明度日志条目
class CertificateTransparencyLog {
  const CertificateTransparencyLog({
    required this.logId,
    required this.certificateFingerprint,
    required this.domain,
    required this.issuedAt,
    required this.loggedAt,
    required this.logServer,
    required this.isValid,
  });

  /// 日志ID
  final String logId;

  /// 证书指纹
  final String certificateFingerprint;

  /// 域名
  final String domain;

  /// 颁发时间
  final DateTime issuedAt;

  /// 日志时间
  final DateTime loggedAt;

  /// 日志服务器
  final String logServer;

  /// 是否有效
  final bool isValid;
}

/// 可信源管理器
class TrustedSourceManager {
  /// 构造函数
  TrustedSourceManager({
    int updateInterval = 24,
  }) : _updateInterval = updateInterval {
    _initializeDefaultSources();
  }

  /// 可信源列表
  final Map<String, TrustedSource> _trustedSources = {};

  /// 白名单
  final Set<String> _whitelist = {};

  /// 黑名单
  final Set<String> _blacklist = {};

  /// 信誉事件历史
  final List<ReputationEvent> _reputationEvents = [];

  /// 证书透明度日志
  final List<CertificateTransparencyLog> _ctLogs = [];

  /// 自动更新间隔 (小时)
  final int _updateInterval;

  /// 最后更新时间
  DateTime? _lastUpdateTime;

  /// 添加可信源
  Future<void> addTrustedSource(TrustedSource source) async {
    _trustedSources[source.id] = source;

    // 记录事件
    await _recordReputationEvent(
      source.id,
      ReputationEventType.adminAction,
      'Trusted source added',
      10,
    );
  }

  /// 移除可信源
  Future<void> removeTrustedSource(String sourceId) async {
    final source = _trustedSources.remove(sourceId);
    if (source != null) {
      await _recordReputationEvent(
        sourceId,
        ReputationEventType.adminAction,
        'Trusted source removed',
        -50,
      );
    }
  }

  /// 更新可信源状态
  Future<void> updateSourceStatus(
    String sourceId,
    TrustSourceStatus newStatus,
  ) async {
    final source = _trustedSources[sourceId];
    if (source != null) {
      final updatedSource = TrustedSource(
        id: source.id,
        name: source.name,
        url: source.url,
        trustLevel: source.trustLevel,
        status: newStatus,
        certificateFingerprint: source.certificateFingerprint,
        publicKeyFingerprint: source.publicKeyFingerprint,
        createdAt: source.createdAt,
        lastVerifiedAt: DateTime.now(),
        expiresAt: source.expiresAt,
        reputationScore: source.reputationScore,
        verificationCount: source.verificationCount,
        failureCount: source.failureCount,
        tags: source.tags,
        metadata: source.metadata,
      );

      _trustedSources[sourceId] = updatedSource;

      await _recordReputationEvent(
        sourceId,
        ReputationEventType.adminAction,
        'Status updated to ${newStatus.name}',
        newStatus == TrustSourceStatus.active ? 5 : -5,
      );
    }
  }

  /// 验证源的可信性
  Future<bool> verifySourceTrust(String url) async {
    // 检查黑名单
    if (_isInBlacklist(url)) {
      return false;
    }

    // 检查白名单
    if (_isInWhitelist(url)) {
      return true;
    }

    // 查找匹配的可信源
    final source = _findSourceByUrl(url);
    if (source != null) {
      // 记录验证事件
      await _recordVerificationEvent(source.id, true);
      return source.isTrusted;
    }

    // 未知源，根据策略决定
    return false;
  }

  /// 获取源的信任级别
  TrustLevel getSourceTrustLevel(String url) {
    if (_isInBlacklist(url)) {
      return TrustLevel.untrusted;
    }

    final source = _findSourceByUrl(url);
    return source?.trustLevel ?? TrustLevel.unknown;
  }

  /// 获取源的信誉评分
  int getSourceReputationScore(String url) {
    final source = _findSourceByUrl(url);
    return source?.reputationScore ?? 0;
  }

  /// 添加到白名单
  void addToWhitelist(String url) {
    _whitelist.add(_normalizeUrl(url));
  }

  /// 添加到黑名单
  void addToBlacklist(String url) {
    _blacklist.add(_normalizeUrl(url));
  }

  /// 从白名单移除
  void removeFromWhitelist(String url) {
    _whitelist.remove(_normalizeUrl(url));
  }

  /// 从黑名单移除
  void removeFromBlacklist(String url) {
    _blacklist.remove(_normalizeUrl(url));
  }

  /// 更新信誉评分
  Future<void> updateReputationScore(
    String sourceId,
    ReputationEventType eventType,
    String description,
    int impact,
  ) async {
    final source = _trustedSources[sourceId];
    if (source != null) {
      final newScore = (source.reputationScore + impact).clamp(0, 100);

      final updatedSource = TrustedSource(
        id: source.id,
        name: source.name,
        url: source.url,
        trustLevel: source.trustLevel,
        status: source.status,
        certificateFingerprint: source.certificateFingerprint,
        publicKeyFingerprint: source.publicKeyFingerprint,
        createdAt: source.createdAt,
        lastVerifiedAt: source.lastVerifiedAt,
        expiresAt: source.expiresAt,
        reputationScore: newScore,
        verificationCount: source.verificationCount,
        failureCount: source.failureCount,
        tags: source.tags,
        metadata: source.metadata,
      );

      _trustedSources[sourceId] = updatedSource;

      await _recordReputationEvent(sourceId, eventType, description, impact);
    }
  }

  /// 检查证书透明度
  Future<bool> checkCertificateTransparency(String domain) async {
    // 模拟CT日志查询
    await Future.delayed(const Duration(milliseconds: 100));

    final ctLog = _ctLogs.firstWhere(
      (log) => log.domain == domain,
      orElse: () => CertificateTransparencyLog(
        logId: 'ct_${DateTime.now().millisecondsSinceEpoch}',
        certificateFingerprint: 'SHA256:1234567890ABCDEF',
        domain: domain,
        issuedAt: DateTime.now().subtract(const Duration(days: 30)),
        loggedAt: DateTime.now().subtract(const Duration(days: 29)),
        logServer: 'ct.googleapis.com/logs/argon2024/',
        isValid: true,
      ),
    );

    return ctLog.isValid;
  }

  /// 获取所有可信源
  List<TrustedSource> getAllTrustedSources() {
    return _trustedSources.values.toList();
  }

  /// 获取活跃的可信源
  List<TrustedSource> getActiveTrustedSources() {
    return _trustedSources.values
        .where((source) => source.isActive && !source.isExpired)
        .toList();
  }

  /// 获取信誉事件历史
  List<ReputationEvent> getReputationEvents(String? sourceId) {
    if (sourceId != null) {
      return _reputationEvents
          .where((event) => event.sourceId == sourceId)
          .toList();
    }
    return List.from(_reputationEvents);
  }

  /// 获取统计信息
  Map<String, dynamic> getStatistics() {
    final sources = _trustedSources.values.toList();

    return {
      'totalSources': sources.length,
      'activeSources': sources.where((s) => s.isActive).length,
      'expiredSources': sources.where((s) => s.isExpired).length,
      'trustLevelDistribution': _getTrustLevelDistribution(sources),
      'averageReputationScore': _getAverageReputationScore(sources),
      'whitelistSize': _whitelist.length,
      'blacklistSize': _blacklist.length,
      'reputationEvents': _reputationEvents.length,
      'ctLogsCount': _ctLogs.length,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
    };
  }

  /// 自动更新可信源
  Future<void> autoUpdateTrustedSources() async {
    final now = DateTime.now();

    if (_lastUpdateTime == null ||
        now.difference(_lastUpdateTime!).inHours >= _updateInterval) {
      // 模拟从远程服务器更新可信源列表
      await Future.delayed(const Duration(milliseconds: 500));

      // 检查过期的源
      final expiredSources =
          _trustedSources.values.where((source) => source.isExpired).toList();

      for (final source in expiredSources) {
        await updateSourceStatus(source.id, TrustSourceStatus.expired);
      }

      _lastUpdateTime = now;
    }
  }

  /// 初始化默认可信源
  void _initializeDefaultSources() {
    final defaultSources = [
      TrustedSource(
        id: 'ming_official',
        name: 'Ming Official Registry',
        url: 'https://templates.ming.dev',
        trustLevel: TrustLevel.official,
        status: TrustSourceStatus.active,
        certificateFingerprint: 'SHA256:ABCDEF1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        lastVerifiedAt: DateTime.now(),
        reputationScore: 100,
        verificationCount: 1000,
        failureCount: 0,
        tags: ['official', 'verified'],
        metadata: {'region': 'global', 'priority': 1},
      ),
      TrustedSource(
        id: 'github_templates',
        name: 'GitHub Templates',
        url: 'https://github.com',
        trustLevel: TrustLevel.certified,
        status: TrustSourceStatus.active,
        certificateFingerprint: 'SHA256:1234567890ABCDEF',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        lastVerifiedAt: DateTime.now(),
        reputationScore: 95,
        verificationCount: 500,
        failureCount: 5,
        tags: ['github', 'community'],
        metadata: {'region': 'global', 'priority': 2},
      ),
    ];

    for (final source in defaultSources) {
      _trustedSources[source.id] = source;
    }

    // 添加默认白名单
    _whitelist.addAll([
      'templates.ming.dev',
      'github.com',
      'gitlab.com',
    ]);
  }

  /// 查找源
  TrustedSource? _findSourceByUrl(String url) {
    final normalizedUrl = _normalizeUrl(url);
    try {
      return _trustedSources.values.firstWhere(
        (source) => _normalizeUrl(source.url) == normalizedUrl,
      );
    } catch (e) {
      return null;
    }
  }

  /// 标准化URL
  String _normalizeUrl(String url) {
    return url
        .toLowerCase()
        .replaceAll(RegExp('^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');
  }

  /// 检查是否在白名单
  bool _isInWhitelist(String url) {
    return _whitelist.contains(_normalizeUrl(url));
  }

  /// 检查是否在黑名单
  bool _isInBlacklist(String url) {
    return _blacklist.contains(_normalizeUrl(url));
  }

  /// 记录信誉事件
  Future<void> _recordReputationEvent(
    String sourceId,
    ReputationEventType type,
    String description,
    int impact,
  ) async {
    final event = ReputationEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      sourceId: sourceId,
      type: type,
      description: description,
      impact: impact,
      timestamp: DateTime.now(),
      metadata: {},
    );

    _reputationEvents.add(event);

    // 保持事件历史在合理范围内
    if (_reputationEvents.length > 10000) {
      _reputationEvents.removeRange(0, _reputationEvents.length - 10000);
    }
  }

  /// 记录验证事件
  Future<void> _recordVerificationEvent(String sourceId, bool success) async {
    final source = _trustedSources[sourceId];
    if (source != null) {
      final updatedSource = TrustedSource(
        id: source.id,
        name: source.name,
        url: source.url,
        trustLevel: source.trustLevel,
        status: source.status,
        certificateFingerprint: source.certificateFingerprint,
        publicKeyFingerprint: source.publicKeyFingerprint,
        createdAt: source.createdAt,
        lastVerifiedAt: DateTime.now(),
        expiresAt: source.expiresAt,
        reputationScore: source.reputationScore,
        verificationCount:
            success ? source.verificationCount + 1 : source.verificationCount,
        failureCount: success ? source.failureCount : source.failureCount + 1,
        tags: source.tags,
        metadata: source.metadata,
      );

      _trustedSources[sourceId] = updatedSource;

      await _recordReputationEvent(
        sourceId,
        success
            ? ReputationEventType.successfulVerification
            : ReputationEventType.verificationFailure,
        success ? 'Verification successful' : 'Verification failed',
        success ? 1 : -2,
      );
    }
  }

  /// 获取信任级别分布
  Map<String, int> _getTrustLevelDistribution(List<TrustedSource> sources) {
    final distribution = <String, int>{};
    for (final level in TrustLevel.values) {
      distribution[level.name] =
          sources.where((s) => s.trustLevel == level).length;
    }
    return distribution;
  }

  /// 获取平均信誉评分
  double _getAverageReputationScore(List<TrustedSource> sources) {
    if (sources.isEmpty) return 0;
    final total =
        sources.fold(0, (sum, source) => sum + source.reputationScore);
    return total / sources.length;
  }
}
