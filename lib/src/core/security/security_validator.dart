/*
---------------------------------------------------------------
File name:          security_validator.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        安全验证器 (Security Validator)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.2 企业级安全验证系统;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:typed_data';

import 'package:ming_status_cli/src/core/security/digital_signature.dart';
import 'package:ming_status_cli/src/core/security/malware_detector.dart';
import 'package:ming_status_cli/src/core/security/trusted_source_manager.dart';

/// 安全等级枚举
enum SecurityLevel {
  /// 安全 - 通过所有检查
  safe,

  /// 警告 - 有轻微安全问题
  warning,

  /// 危险 - 有严重安全问题
  dangerous,

  /// 阻止 - 禁止使用
  blocked,
}

/// 安全策略枚举
enum SecurityPolicy {
  /// 企业级 - 最严格的安全策略
  enterprise,

  /// 标准 - 平衡安全性和可用性
  standard,

  /// 宽松 - 较为宽松的安全策略
  relaxed,
}

/// 验证步骤枚举
enum ValidationStep {
  /// 数字签名验证
  signatureVerification,

  /// 可信源验证
  trustedSourceVerification,

  /// 恶意代码检测
  malwareDetection,

  /// 安全策略检查
  policyCheck,
}

/// 安全验证结果
class SecurityValidationResult {
  const SecurityValidationResult({
    required this.securityLevel,
    required this.isValid,
    required this.stepResults,
    required this.securityIssues,
    required this.validatedAt,
    required this.validationDuration,
    required this.policy,
    required this.validatorVersion,
    required this.metadata,
    this.signatureResult,
    this.trustedSourceResult,
    this.malwareResult,
  });

  /// 安全等级
  final SecurityLevel securityLevel;

  /// 验证是否通过
  final bool isValid;

  /// 验证步骤结果
  final Map<ValidationStep, bool> stepResults;

  /// 数字签名验证结果
  final SignatureVerificationResult? signatureResult;

  /// 可信源验证结果
  final bool? trustedSourceResult;

  /// 恶意代码检测结果
  final DetectionResult? malwareResult;

  /// 安全问题列表
  final List<SecurityIssue> securityIssues;

  /// 验证时间
  final DateTime validatedAt;

  /// 验证耗时
  final Duration validationDuration;

  /// 使用的安全策略
  final SecurityPolicy policy;

  /// 验证器版本
  final String validatorVersion;

  /// 额外信息
  final Map<String, dynamic> metadata;

  /// 是否有签名
  bool get hasSigned => signatureResult?.hasSigned ?? false;

  /// 是否有可信签名
  bool get hasTrustedSignature => signatureResult?.hasTrustedSignature ?? false;

  /// 是否来自可信源
  bool get isFromTrustedSource => trustedSourceResult ?? false;

  /// 是否检测到恶意代码
  bool get hasMalware => malwareResult?.hasThreat ?? false;

  /// 是否可以安全使用
  bool get isSafeToUse =>
      securityLevel == SecurityLevel.safe ||
      securityLevel == SecurityLevel.warning;
}

/// 安全事件
class SecurityEvent {
  const SecurityEvent({
    required this.id,
    required this.eventType,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.eventData,
    this.filePath,
    this.sourceUrl,
    this.userId,
  });

  /// 事件ID
  final String id;

  /// 事件类型
  final String eventType;

  /// 事件描述
  final String description;

  /// 严重程度
  final SecurityLevel severity;

  /// 文件路径
  final String? filePath;

  /// 源URL
  final String? sourceUrl;

  /// 事件时间
  final DateTime timestamp;

  /// 用户信息
  final String? userId;

  /// 事件数据
  final Map<String, dynamic> eventData;
}

/// 安全审计日志
class SecurityAuditLog {
  const SecurityAuditLog({
    required this.id,
    required this.operation,
    required this.success,
    required this.timestamp,
    required this.details,
    this.userId,
    this.resourcePath,
  });

  /// 日志ID
  final String id;

  /// 操作类型
  final String operation;

  /// 操作结果
  final bool success;

  /// 用户ID
  final String? userId;

  /// 资源路径
  final String? resourcePath;

  /// 操作时间
  final DateTime timestamp;

  /// 详细信息
  final Map<String, dynamic> details;
}

/// 安全验证器
class SecurityValidator {
  /// 构造函数
  SecurityValidator({
    DigitalSignature? digitalSignature,
    TrustedSourceManager? trustedSourceManager,
    MalwareDetector? malwareDetector,
    SecurityPolicy policy = SecurityPolicy.standard,
  })  : _digitalSignature = digitalSignature ?? DigitalSignature(),
        _trustedSourceManager = trustedSourceManager ?? TrustedSourceManager(),
        _malwareDetector = malwareDetector ?? MalwareDetector(),
        _policy = policy;

  /// 数字签名验证器
  final DigitalSignature _digitalSignature;

  /// 可信源管理器
  final TrustedSourceManager _trustedSourceManager;

  /// 恶意代码检测器
  final MalwareDetector _malwareDetector;

  /// 安全策略
  final SecurityPolicy _policy;

  /// 安全事件列表
  final List<SecurityEvent> _securityEvents = [];

  /// 审计日志列表
  final List<SecurityAuditLog> _auditLogs = [];

  /// 验证统计
  final Map<String, int> _validationStats = {};

  /// 告警阈值配置
  final Map<String, int> _alertThresholds = {
    'malware_detections_per_hour': 5,
    'signature_failures_per_hour': 10,
    'untrusted_source_attempts_per_hour': 20,
  };

  /// 验证模板安全性
  Future<SecurityValidationResult> validateTemplateSecurity(
    String filePath,
    Uint8List fileData,
    String? sourceUrl,
  ) async {
    final startTime = DateTime.now();
    final stepResults = <ValidationStep, bool>{};
    final securityIssues = <SecurityIssue>[];

    try {
      // 记录审计日志
      await _recordAuditLog(
        'template_security_validation',
        true,
        resourcePath: filePath,
        details: {
          'sourceUrl': sourceUrl,
          'fileSize': fileData.length,
          'policy': _policy.name,
        },
      );

      // 步骤1: 数字签名验证
      SignatureVerificationResult? signatureResult;
      try {
        signatureResult =
            await _digitalSignature.verifyFileSignature(filePath, fileData);
        stepResults[ValidationStep.signatureVerification] =
            signatureResult.isValid;

        if (!signatureResult.isValid && _policy == SecurityPolicy.enterprise) {
          securityIssues.addAll(
            signatureResult.errors.map(
              (error) => SecurityIssue(
                id: 'signature_error',
                title: 'Signature Verification Failed',
                description: error,
                threatType: ThreatType.suspiciousBehavior,
                severity: ThreatLevel.high,
                filePath: filePath,
                references: [],
                confidence: 90,
              ),
            ),
          );
        }
      } catch (e) {
        stepResults[ValidationStep.signatureVerification] = false;
        await _recordSecurityEvent(
          'signature_verification_error',
          'Signature verification failed: $e',
          SecurityLevel.warning,
          filePath: filePath,
          sourceUrl: sourceUrl,
        );
      }

      // 步骤2: 可信源验证
      bool? trustedSourceResult;
      if (sourceUrl != null) {
        try {
          trustedSourceResult =
              await _trustedSourceManager.verifySourceTrust(sourceUrl);
          stepResults[ValidationStep.trustedSourceVerification] =
              trustedSourceResult;

          if (!trustedSourceResult) {
            securityIssues.add(
              SecurityIssue(
                id: 'untrusted_source',
                title: 'Untrusted Source',
                description:
                    'Template comes from an untrusted source: $sourceUrl',
                threatType: ThreatType.suspiciousBehavior,
                severity: _policy == SecurityPolicy.enterprise
                    ? ThreatLevel.high
                    : ThreatLevel.medium,
                filePath: filePath,
                references: [],
                confidence: 80,
              ),
            );

            await _recordSecurityEvent(
              'untrusted_source_access',
              'Access attempt from untrusted source: $sourceUrl',
              SecurityLevel.warning,
              filePath: filePath,
              sourceUrl: sourceUrl,
            );
          }
        } catch (e) {
          stepResults[ValidationStep.trustedSourceVerification] = false;
          await _recordSecurityEvent(
            'trusted_source_verification_error',
            'Trusted source verification failed: $e',
            SecurityLevel.warning,
            filePath: filePath,
            sourceUrl: sourceUrl,
          );
        }
      } else {
        stepResults[ValidationStep.trustedSourceVerification] =
            true; // 无源URL时默认通过
      }

      // 步骤3: 恶意代码检测
      DetectionResult? malwareResult;
      try {
        malwareResult = await _malwareDetector.scanData(fileData, filePath);
        stepResults[ValidationStep.malwareDetection] = !malwareResult.hasThreat;

        if (malwareResult.hasThreat) {
          securityIssues.addAll(malwareResult.issues);

          await _recordSecurityEvent(
            'malware_detected',
            'Malware detected in template: ${malwareResult.threatTypes.join(', ')}',
            SecurityLevel.dangerous,
            filePath: filePath,
            sourceUrl: sourceUrl,
          );
        }
      } catch (e) {
        stepResults[ValidationStep.malwareDetection] = false;
        await _recordSecurityEvent(
          'malware_detection_error',
          'Malware detection failed: $e',
          SecurityLevel.warning,
          filePath: filePath,
          sourceUrl: sourceUrl,
        );
      }

      // 步骤4: 安全策略检查
      final policyCheckResult = await _performPolicyCheck(
        signatureResult,
        trustedSourceResult,
        malwareResult,
        securityIssues,
      );
      stepResults[ValidationStep.policyCheck] = policyCheckResult;

      // 计算安全等级
      final securityLevel =
          _calculateSecurityLevel(stepResults, securityIssues);

      // 判断是否通过验证
      final isValid = _isValidationPassed(securityLevel, stepResults);

      final endTime = DateTime.now();

      // 更新统计
      _updateValidationStats(securityLevel, isValid);

      // 检查告警阈值
      await _checkAlertThresholds();

      return SecurityValidationResult(
        securityLevel: securityLevel,
        isValid: isValid,
        stepResults: stepResults,
        signatureResult: signatureResult,
        trustedSourceResult: trustedSourceResult,
        malwareResult: malwareResult,
        securityIssues: securityIssues,
        validatedAt: endTime,
        validationDuration: endTime.difference(startTime),
        policy: _policy,
        validatorVersion: '1.0.0',
        metadata: {
          'filePath': filePath,
          'sourceUrl': sourceUrl,
          'fileSize': fileData.length,
          'stepsCompleted': stepResults.length,
        },
      );
    } catch (e) {
      final endTime = DateTime.now();

      await _recordSecurityEvent(
        'validation_error',
        'Security validation failed: $e',
        SecurityLevel.dangerous,
        filePath: filePath,
        sourceUrl: sourceUrl,
      );

      return SecurityValidationResult(
        securityLevel: SecurityLevel.blocked,
        isValid: false,
        stepResults: stepResults,
        securityIssues: [
          SecurityIssue(
            id: 'validation_error',
            title: 'Validation Error',
            description: 'Security validation failed: $e',
            threatType: ThreatType.suspiciousBehavior,
            severity: ThreatLevel.critical,
            filePath: filePath,
            references: [],
            confidence: 100,
          ),
        ],
        validatedAt: DateTime.now(),
        validationDuration: endTime.difference(startTime),
        policy: _policy,
        validatorVersion: '1.0.0',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// 批量验证
  Future<List<SecurityValidationResult>> validateBatch(
    List<String> filePaths,
    List<Uint8List> fileDataList,
    List<String?> sourceUrls,
  ) async {
    final results = <SecurityValidationResult>[];

    for (var i = 0; i < filePaths.length; i++) {
      final result = await validateTemplateSecurity(
        filePaths[i],
        fileDataList[i],
        sourceUrls.length > i ? sourceUrls[i] : null,
      );
      results.add(result);
    }

    return results;
  }

  /// 获取安全事件
  List<SecurityEvent> getSecurityEvents({
    SecurityLevel? minSeverity,
    DateTime? since,
    int? limit,
  }) {
    var events = _securityEvents.where((event) {
      if (minSeverity != null && event.severity.index < minSeverity.index) {
        return false;
      }
      if (since != null && event.timestamp.isBefore(since)) {
        return false;
      }
      return true;
    }).toList();

    // 按时间倒序排列
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && events.length > limit) {
      events = events.take(limit).toList();
    }

    return events;
  }

  /// 获取审计日志
  List<SecurityAuditLog> getAuditLogs({
    bool? successOnly,
    DateTime? since,
    int? limit,
  }) {
    var logs = _auditLogs.where((log) {
      if (successOnly != null && log.success != successOnly) {
        return false;
      }
      if (since != null && log.timestamp.isBefore(since)) {
        return false;
      }
      return true;
    }).toList();

    // 按时间倒序排列
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && logs.length > limit) {
      logs = logs.take(limit).toList();
    }

    return logs;
  }

  /// 生成安全报告
  Map<String, dynamic> generateSecurityReport() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));

    final recentEvents = getSecurityEvents(since: last24Hours);
    final recentLogs = getAuditLogs(since: last24Hours);

    return {
      'reportGeneratedAt': now.toIso8601String(),
      'policy': _policy.name,
      'validatorVersion': '1.0.0',
      'statistics': {
        'totalValidations':
            _validationStats.values.fold(0, (sum, count) => sum + count),
        'validationsByLevel': Map<String, int>.from(_validationStats),
        'recentEvents': recentEvents.length,
        'recentAuditLogs': recentLogs.length,
      },
      'recentSecurityEvents': recentEvents
          .take(10)
          .map(
            (event) => {
              'id': event.id,
              'type': event.eventType,
              'severity': event.severity.name,
              'timestamp': event.timestamp.toIso8601String(),
              'description': event.description,
            },
          )
          .toList(),
      'alertThresholds': Map<String, int>.from(_alertThresholds),
      'componentStatus': {
        'digitalSignature': 'active',
        'trustedSourceManager': 'active',
        'malwareDetector': 'active',
      },
    };
  }

  /// 执行安全策略检查
  Future<bool> _performPolicyCheck(
    SignatureVerificationResult? signatureResult,
    bool? trustedSourceResult,
    DetectionResult? malwareResult,
    List<SecurityIssue> securityIssues,
  ) async {
    switch (_policy) {
      case SecurityPolicy.enterprise:
        // 企业级策略：必须有签名、来自可信源、无恶意代码
        return (signatureResult?.isValid ?? false) &&
            (trustedSourceResult ?? false) &&
            !(malwareResult?.hasThreat ?? true);

      case SecurityPolicy.standard:
        // 标准策略：有签名或来自可信源，且无高危恶意代码
        final hasSignatureOrTrustedSource =
            (signatureResult?.isValid ?? false) ||
                (trustedSourceResult ?? false);
        final noHighRiskMalware = !(malwareResult?.isHighRisk ?? false);
        return hasSignatureOrTrustedSource && noHighRiskMalware;

      case SecurityPolicy.relaxed:
        // 宽松策略：仅检查严重威胁
        return !(malwareResult?.threatLevel == ThreatLevel.critical);
    }
  }

  /// 计算安全等级
  SecurityLevel _calculateSecurityLevel(
    Map<ValidationStep, bool> stepResults,
    List<SecurityIssue> securityIssues,
  ) {
    // 检查是否有严重问题
    final hasCriticalIssues = securityIssues.any(
      (issue) => issue.severity == ThreatLevel.critical,
    );
    if (hasCriticalIssues) return SecurityLevel.blocked;

    // 检查是否有高风险问题
    final hasHighRiskIssues = securityIssues.any(
      (issue) => issue.severity == ThreatLevel.high,
    );
    if (hasHighRiskIssues) return SecurityLevel.dangerous;

    // 检查是否有中等风险问题
    final hasMediumRiskIssues = securityIssues.any(
      (issue) => issue.severity == ThreatLevel.medium,
    );
    if (hasMediumRiskIssues) return SecurityLevel.warning;

    // 检查验证步骤是否全部通过
    final allStepsPassed = stepResults.values.every((result) => result);
    if (allStepsPassed) return SecurityLevel.safe;

    return SecurityLevel.warning;
  }

  /// 判断验证是否通过
  bool _isValidationPassed(
    SecurityLevel securityLevel,
    Map<ValidationStep, bool> stepResults,
  ) {
    switch (_policy) {
      case SecurityPolicy.enterprise:
        return securityLevel == SecurityLevel.safe;
      case SecurityPolicy.standard:
        return securityLevel == SecurityLevel.safe ||
            securityLevel == SecurityLevel.warning;
      case SecurityPolicy.relaxed:
        return securityLevel != SecurityLevel.blocked;
    }
  }

  /// 记录安全事件
  Future<void> _recordSecurityEvent(
    String eventType,
    String description,
    SecurityLevel severity, {
    String? filePath,
    String? sourceUrl,
    String? userId,
    Map<String, dynamic>? eventData,
  }) async {
    final event = SecurityEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      eventType: eventType,
      description: description,
      severity: severity,
      filePath: filePath,
      sourceUrl: sourceUrl,
      timestamp: DateTime.now(),
      userId: userId,
      eventData: eventData ?? {},
    );

    _securityEvents.add(event);

    // 保持事件列表在合理范围内
    if (_securityEvents.length > 10000) {
      _securityEvents.removeRange(0, _securityEvents.length - 10000);
    }
  }

  /// 记录审计日志
  Future<void> _recordAuditLog(
    String operation,
    bool success, {
    String? userId,
    String? resourcePath,
    Map<String, dynamic>? details,
  }) async {
    final log = SecurityAuditLog(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      operation: operation,
      success: success,
      userId: userId,
      resourcePath: resourcePath,
      timestamp: DateTime.now(),
      details: details ?? {},
    );

    _auditLogs.add(log);

    // 保持审计日志在合理范围内
    if (_auditLogs.length > 50000) {
      _auditLogs.removeRange(0, _auditLogs.length - 50000);
    }
  }

  /// 更新验证统计
  void _updateValidationStats(SecurityLevel level, bool isValid) {
    final levelKey = level.name;
    _validationStats[levelKey] = (_validationStats[levelKey] ?? 0) + 1;

    final resultKey = isValid ? 'passed' : 'failed';
    _validationStats[resultKey] = (_validationStats[resultKey] ?? 0) + 1;
  }

  /// 检查告警阈值
  Future<void> _checkAlertThresholds() async {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    // 检查恶意代码检测告警
    final malwareEvents = _securityEvents
        .where(
          (event) =>
              event.eventType == 'malware_detected' &&
              event.timestamp.isAfter(oneHourAgo),
        )
        .length;

    if (malwareEvents >= _alertThresholds['malware_detections_per_hour']!) {
      await _recordSecurityEvent(
        'alert_threshold_exceeded',
        'Malware detection threshold exceeded: $malwareEvents detections in the last hour',
        SecurityLevel.dangerous,
      );
    }
  }
}
