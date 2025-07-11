/*
---------------------------------------------------------------
File name:          compliance_checker.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        合规检查器 (Compliance Checker)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.4 企业级模板管理;
---------------------------------------------------------------
*/

import 'dart:async';

/// 合规标准枚举
enum ComplianceStandard {
  /// SOX法案
  sox,

  /// GDPR
  gdpr,

  /// HIPAA
  hipaa,

  /// PCI DSS
  pciDss,

  /// ISO 27001
  iso27001,

  /// SOC 2
  soc2,

  /// 自定义标准
  custom,
}

/// 合规级别枚举
enum ComplianceLevel {
  /// 完全合规
  compliant,

  /// 部分合规
  partiallyCompliant,

  /// 不合规
  nonCompliant,

  /// 需要审查
  requiresReview,

  /// 豁免
  exempt,
}

/// 违规严重程度枚举
enum ViolationSeverity {
  /// 严重
  critical,

  /// 高
  high,

  /// 中等
  medium,

  /// 低
  low,

  /// 信息
  info,
}

/// 合规规则
class ComplianceRule {
  const ComplianceRule({
    required this.id,
    required this.name,
    required this.standard,
    required this.description,
    required this.ruleType,
    required this.severity,
    required this.enabled,
    required this.conditions,
    required this.remediation,
    required this.references,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 规则ID
  final String id;

  /// 规则名称
  final String name;

  /// 合规标准
  final ComplianceStandard standard;

  /// 规则描述
  final String description;

  /// 规则类型
  final String ruleType;

  /// 严重程度
  final ViolationSeverity severity;

  /// 是否启用
  final bool enabled;

  /// 检查条件
  final Map<String, dynamic> conditions;

  /// 修复建议
  final String remediation;

  /// 参考文档
  final List<String> references;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;
}

/// 合规违规
class ComplianceViolation {
  const ComplianceViolation({
    required this.id,
    required this.ruleId,
    required this.resourceId,
    required this.resourceType,
    required this.description,
    required this.severity,
    required this.discoveredAt,
    required this.status,
    required this.details,
    required this.evidence,
    this.assignee,
    this.dueDate,
    this.remediationStatus,
    this.remediatedAt,
  });

  /// 违规ID
  final String id;

  /// 规则ID
  final String ruleId;

  /// 资源ID
  final String resourceId;

  /// 资源类型
  final String resourceType;

  /// 违规描述
  final String description;

  /// 严重程度
  final ViolationSeverity severity;

  /// 发现时间
  final DateTime discoveredAt;

  /// 状态
  final String status;

  /// 负责人
  final String? assignee;

  /// 截止时间
  final DateTime? dueDate;

  /// 修复状态
  final String? remediationStatus;

  /// 修复时间
  final DateTime? remediatedAt;

  /// 违规详情
  final Map<String, dynamic> details;

  /// 证据
  final List<String> evidence;

  /// 是否已修复
  bool get isRemediated => status == 'remediated';

  /// 是否过期
  bool get isOverdue =>
      dueDate != null && DateTime.now().isAfter(dueDate!) && !isRemediated;

  /// 是否严重
  bool get isCritical => severity == ViolationSeverity.critical;
}

/// 合规报告
class ComplianceReport {
  const ComplianceReport({
    required this.id,
    required this.name,
    required this.standard,
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.overallLevel,
    required this.totalResources,
    required this.compliantResources,
    required this.totalViolations,
    required this.violationsBySeverity,
    required this.violations,
    required this.complianceScore,
    required this.trends,
    required this.recommendations,
  });

  /// 报告ID
  final String id;

  /// 报告名称
  final String name;

  /// 合规标准
  final ComplianceStandard standard;

  /// 生成时间
  final DateTime generatedAt;

  /// 报告期间
  final DateTime periodStart;
  final DateTime periodEnd;

  /// 总体合规级别
  final ComplianceLevel overallLevel;

  /// 检查的资源数量
  final int totalResources;

  /// 合规资源数量
  final int compliantResources;

  /// 违规数量
  final int totalViolations;

  /// 按严重程度分组的违规
  final Map<ViolationSeverity, int> violationsBySeverity;

  /// 违规列表
  final List<ComplianceViolation> violations;

  /// 合规分数 (0-100)
  final double complianceScore;

  /// 趋势数据
  final Map<String, dynamic> trends;

  /// 建议
  final List<String> recommendations;

  /// 合规率
  double get complianceRate =>
      totalResources > 0 ? compliantResources / totalResources : 0.0;

  /// 是否合规
  bool get isCompliant => overallLevel == ComplianceLevel.compliant;
}

/// 合规检查器
class ComplianceChecker {
  /// 构造函数
  ComplianceChecker() {
    _initializeDefaultRules();
  }

  /// 合规规则列表
  final Map<String, ComplianceRule> _rules = {};

  /// 违规记录
  final List<ComplianceViolation> _violations = [];

  /// 合规报告
  final List<ComplianceReport> _reports = [];

  /// 检查历史
  final List<Map<String, dynamic>> _checkHistory = [];

  /// 配置
  final Map<String, dynamic> _config = {};

  /// 添加合规规则
  Future<void> addRule(ComplianceRule rule) async {
    _rules[rule.id] = rule;
  }

  /// 移除合规规则
  Future<void> removeRule(String ruleId) async {
    _rules.remove(ruleId);
  }

  /// 启用/禁用规则
  Future<void> toggleRule(String ruleId, bool enabled) async {
    final rule = _rules[ruleId];
    if (rule == null) return;

    final updatedRule = ComplianceRule(
      id: rule.id,
      name: rule.name,
      standard: rule.standard,
      description: rule.description,
      ruleType: rule.ruleType,
      severity: rule.severity,
      enabled: enabled,
      conditions: rule.conditions,
      remediation: rule.remediation,
      references: rule.references,
      createdAt: rule.createdAt,
      updatedAt: DateTime.now(),
    );

    _rules[ruleId] = updatedRule;
  }

  /// 执行合规检查
  Future<List<ComplianceViolation>> performComplianceCheck({
    required String resourceId,
    required String resourceType,
    required Map<String, dynamic> resourceData,
    ComplianceStandard? standard,
  }) async {
    final violations = <ComplianceViolation>[];

    // 获取适用的规则
    final applicableRules = _getApplicableRules(resourceType, standard);

    for (final rule in applicableRules) {
      if (!rule.enabled) continue;

      // 执行规则检查
      final ruleViolations =
          await _checkRule(rule, resourceId, resourceType, resourceData);
      violations.addAll(ruleViolations);
    }

    // 记录检查历史
    _checkHistory.add({
      'resourceId': resourceId,
      'resourceType': resourceType,
      'checkedAt': DateTime.now().toIso8601String(),
      'rulesChecked': applicableRules.length,
      'violationsFound': violations.length,
    });

    // 添加到违规记录
    _violations.addAll(violations);

    return violations;
  }

  /// 批量合规检查
  Future<Map<String, List<ComplianceViolation>>> performBatchCheck({
    required List<Map<String, dynamic>> resources,
    ComplianceStandard? standard,
  }) async {
    final results = <String, List<ComplianceViolation>>{};

    for (final resource in resources) {
      final resourceId = resource['id'] as String;
      final resourceType = resource['type'] as String;
      final resourceData = resource['data'] as Map<String, dynamic>;

      final violations = await performComplianceCheck(
        resourceId: resourceId,
        resourceType: resourceType,
        resourceData: resourceData,
        standard: standard,
      );

      results[resourceId] = violations;
    }

    return results;
  }

  /// 生成合规报告
  Future<ComplianceReport> generateComplianceReport({
    required ComplianceStandard standard,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? name,
  }) async {
    final reportId = _generateReportId();
    final reportName = name ?? 'Compliance Report ${standard.name}';

    // 获取期间内的违规
    final periodViolations = _violations
        .where(
          (v) =>
              v.discoveredAt.isAfter(periodStart) &&
              v.discoveredAt.isBefore(periodEnd),
        )
        .toList();

    // 按严重程度分组
    final violationsBySeverity = <ViolationSeverity, int>{};
    for (final severity in ViolationSeverity.values) {
      violationsBySeverity[severity] =
          periodViolations.where((v) => v.severity == severity).length;
    }

    // 计算合规指标
    final totalResources = _getTotalResourcesInPeriod(periodStart, periodEnd);
    final violatedResources =
        periodViolations.map((v) => v.resourceId).toSet().length;
    final compliantResources = totalResources - violatedResources;

    // 计算合规分数
    final complianceScore = _calculateComplianceScore(
      totalResources,
      compliantResources,
      periodViolations,
    );

    // 确定总体合规级别
    final overallLevel =
        _determineComplianceLevel(complianceScore, periodViolations);

    // 生成趋势数据
    final trends = await _generateTrendData(standard, periodStart, periodEnd);

    // 生成建议
    final recommendations = _generateRecommendations(periodViolations);

    final report = ComplianceReport(
      id: reportId,
      name: reportName,
      standard: standard,
      generatedAt: DateTime.now(),
      periodStart: periodStart,
      periodEnd: periodEnd,
      overallLevel: overallLevel,
      totalResources: totalResources,
      compliantResources: compliantResources,
      totalViolations: periodViolations.length,
      violationsBySeverity: violationsBySeverity,
      violations: periodViolations,
      complianceScore: complianceScore,
      trends: trends,
      recommendations: recommendations,
    );

    _reports.add(report);
    return report;
  }

  /// 修复违规
  Future<void> remediateViolation({
    required String violationId,
    required String remediatedBy,
    String? notes,
  }) async {
    final violationIndex = _violations.indexWhere((v) => v.id == violationId);
    if (violationIndex == -1) return;

    final violation = _violations[violationIndex];
    final remediatedViolation = ComplianceViolation(
      id: violation.id,
      ruleId: violation.ruleId,
      resourceId: violation.resourceId,
      resourceType: violation.resourceType,
      description: violation.description,
      severity: violation.severity,
      discoveredAt: violation.discoveredAt,
      status: 'remediated',
      assignee: violation.assignee,
      dueDate: violation.dueDate,
      remediationStatus: 'completed',
      remediatedAt: DateTime.now(),
      details: {
        ...violation.details,
        'remediatedBy': remediatedBy,
        'remediationNotes': notes,
      },
      evidence: violation.evidence,
    );

    _violations[violationIndex] = remediatedViolation;
  }

  /// 获取违规统计
  Map<String, dynamic> getViolationStats() {
    final totalViolations = _violations.length;
    final openViolations = _violations.where((v) => !v.isRemediated).length;
    final overdueViolations = _violations.where((v) => v.isOverdue).length;
    final criticalViolations = _violations.where((v) => v.isCritical).length;

    final violationsByStandard = <String, int>{};
    for (final standard in ComplianceStandard.values) {
      violationsByStandard[standard.name] = _violations
          .where((v) => _rules[v.ruleId]?.standard == standard)
          .length;
    }

    return {
      'total': totalViolations,
      'open': openViolations,
      'overdue': overdueViolations,
      'critical': criticalViolations,
      'remediated': totalViolations - openViolations,
      'byStandard': violationsByStandard,
      'bySeverity': _getViolationsBySeverity(),
    };
  }

  /// 获取合规规则
  List<ComplianceRule> getRules({ComplianceStandard? standard}) {
    if (standard == null) {
      return _rules.values.toList();
    }
    return _rules.values.where((rule) => rule.standard == standard).toList();
  }

  /// 获取违规记录
  List<ComplianceViolation> getViolations({
    ComplianceStandard? standard,
    ViolationSeverity? severity,
    String? status,
    int? limit,
  }) {
    var violations = _violations.where((violation) {
      if (standard != null) {
        final rule = _rules[violation.ruleId];
        if (rule?.standard != standard) return false;
      }
      if (severity != null && violation.severity != severity) return false;
      if (status != null && violation.status != status) return false;
      return true;
    }).toList();

    // 按发现时间倒序排列
    violations.sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));

    if (limit != null && violations.length > limit) {
      violations = violations.take(limit).toList();
    }

    return violations;
  }

  /// 获取适用的规则
  List<ComplianceRule> _getApplicableRules(
    String resourceType,
    ComplianceStandard? standard,
  ) {
    return _rules.values.where((rule) {
      if (standard != null && rule.standard != standard) return false;
      if (!rule.enabled) return false;

      // 检查规则是否适用于资源类型
      final applicableTypes =
          rule.conditions['applicableTypes'] as List<String>?;
      if (applicableTypes != null && !applicableTypes.contains(resourceType)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// 检查规则
  Future<List<ComplianceViolation>> _checkRule(
    ComplianceRule rule,
    String resourceId,
    String resourceType,
    Map<String, dynamic> resourceData,
  ) async {
    final violations = <ComplianceViolation>[];

    // 模拟规则检查逻辑
    final checkResult = await _executeRuleCheck(rule, resourceData);

    if (checkResult['passed'] != true) {
      final violation = ComplianceViolation(
        id: _generateViolationId(),
        ruleId: rule.id,
        resourceId: resourceId,
        resourceType: resourceType,
        description: checkResult['description'] as String,
        severity: rule.severity,
        discoveredAt: DateTime.now(),
        status: 'open',
        details: checkResult['details'] as Map<String, dynamic>,
        evidence: checkResult['evidence'] as List<String>,
      );

      violations.add(violation);
    }

    return violations;
  }

  /// 执行规则检查
  Future<Map<String, dynamic>> _executeRuleCheck(
    ComplianceRule rule,
    Map<String, dynamic> resourceData,
  ) async {
    // 模拟规则检查
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // 简化的检查逻辑
    switch (rule.ruleType) {
      case 'data_retention':
        return _checkDataRetention(rule, resourceData);
      case 'access_control':
        return _checkAccessControl(rule, resourceData);
      case 'encryption':
        return _checkEncryption(rule, resourceData);
      case 'audit_logging':
        return _checkAuditLogging(rule, resourceData);
      default:
        return {
          'passed': true,
          'description': 'Rule check passed',
          'details': <String, dynamic>{},
          'evidence': <String>[],
        };
    }
  }

  /// 检查数据保留
  Map<String, dynamic> _checkDataRetention(
    ComplianceRule rule,
    Map<String, dynamic> data,
  ) {
    final retentionPeriod = rule.conditions['retentionPeriod'] as int? ?? 365;
    final createdAt = DateTime.tryParse(data['createdAt'] as String? ?? '');

    if (createdAt != null) {
      final age = DateTime.now().difference(createdAt).inDays;
      if (age > retentionPeriod) {
        return {
          'passed': false,
          'description': 'Data retention period exceeded',
          'details': {
            'age': age,
            'retentionPeriod': retentionPeriod,
          },
          'evidence': ['createdAt: ${createdAt.toIso8601String()}'],
        };
      }
    }

    return {
      'passed': true,
      'description': 'Data retention check passed',
      'details': <String, dynamic>{},
      'evidence': <String>[],
    };
  }

  /// 检查访问控制
  Map<String, dynamic> _checkAccessControl(
    ComplianceRule rule,
    Map<String, dynamic> data,
  ) {
    final requiredPermissions =
        rule.conditions['requiredPermissions'] as List<String>? ?? [];
    final actualPermissions = data['permissions'] as List<String>? ?? [];

    final missingPermissions = requiredPermissions
        .where((perm) => !actualPermissions.contains(perm))
        .toList();

    if (missingPermissions.isNotEmpty) {
      return {
        'passed': false,
        'description': 'Missing required permissions',
        'details': {
          'missingPermissions': missingPermissions,
          'requiredPermissions': requiredPermissions,
          'actualPermissions': actualPermissions,
        },
        'evidence': ['permissions: ${actualPermissions.join(', ')}'],
      };
    }

    return {
      'passed': true,
      'description': 'Access control check passed',
      'details': <String, dynamic>{},
      'evidence': <String>[],
    };
  }

  /// 检查加密
  Map<String, dynamic> _checkEncryption(
    ComplianceRule rule,
    Map<String, dynamic> data,
  ) {
    final requiresEncryption =
        rule.conditions['requiresEncryption'] as bool? ?? true;
    final isEncrypted = data['encrypted'] as bool? ?? false;

    if (requiresEncryption && !isEncrypted) {
      return {
        'passed': false,
        'description': 'Data is not encrypted',
        'details': {
          'requiresEncryption': requiresEncryption,
          'isEncrypted': isEncrypted,
        },
        'evidence': ['encrypted: $isEncrypted'],
      };
    }

    return {
      'passed': true,
      'description': 'Encryption check passed',
      'details': <String, dynamic>{},
      'evidence': <String>[],
    };
  }

  /// 检查审计日志
  Map<String, dynamic> _checkAuditLogging(
    ComplianceRule rule,
    Map<String, dynamic> data,
  ) {
    final requiresAuditLog =
        rule.conditions['requiresAuditLog'] as bool? ?? true;
    final hasAuditLog = data['auditLogEnabled'] as bool? ?? false;

    if (requiresAuditLog && !hasAuditLog) {
      return {
        'passed': false,
        'description': 'Audit logging is not enabled',
        'details': {
          'requiresAuditLog': requiresAuditLog,
          'hasAuditLog': hasAuditLog,
        },
        'evidence': ['auditLogEnabled: $hasAuditLog'],
      };
    }

    return {
      'passed': true,
      'description': 'Audit logging check passed',
      'details': <String, dynamic>{},
      'evidence': <String>[],
    };
  }

  /// 计算合规分数
  double _calculateComplianceScore(
    int totalResources,
    int compliantResources,
    List<ComplianceViolation> violations,
  ) {
    if (totalResources == 0) return 100;

    final baseScore = (compliantResources / totalResources) * 100;

    // 根据违规严重程度调整分数
    var penalty = 0.0;
    for (final violation in violations) {
      switch (violation.severity) {
        case ViolationSeverity.critical:
          penalty += 10.0;
        case ViolationSeverity.high:
          penalty += 5.0;
        case ViolationSeverity.medium:
          penalty += 2.0;
        case ViolationSeverity.low:
          penalty += 1.0;
        case ViolationSeverity.info:
          penalty += 0.5;
      }
    }

    return (baseScore - penalty).clamp(0.0, 100.0);
  }

  /// 确定合规级别
  ComplianceLevel _determineComplianceLevel(
    double score,
    List<ComplianceViolation> violations,
  ) {
    final criticalViolations = violations.where((v) => v.isCritical).length;

    if (criticalViolations > 0) {
      return ComplianceLevel.nonCompliant;
    }

    if (score >= 95.0) {
      return ComplianceLevel.compliant;
    } else if (score >= 80.0) {
      return ComplianceLevel.partiallyCompliant;
    } else {
      return ComplianceLevel.nonCompliant;
    }
  }

  /// 生成趋势数据
  Future<Map<String, dynamic>> _generateTrendData(
    ComplianceStandard standard,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    // 模拟趋势数据生成
    return {
      'complianceScoreTrend': [85.0, 87.0, 89.0, 91.0, 93.0],
      'violationTrend': [15, 12, 10, 8, 6],
      'remediationRate': 0.85,
    };
  }

  /// 生成建议
  List<String> _generateRecommendations(List<ComplianceViolation> violations) {
    final recommendations = <String>[];

    final criticalCount = violations.where((v) => v.isCritical).length;
    if (criticalCount > 0) {
      recommendations
          .add('Address $criticalCount critical violations immediately');
    }

    final overdueCount = violations.where((v) => v.isOverdue).length;
    if (overdueCount > 0) {
      recommendations.add('Resolve $overdueCount overdue violations');
    }

    recommendations.add('Implement automated compliance monitoring');
    recommendations.add('Conduct regular compliance training');

    return recommendations;
  }

  /// 获取期间内的总资源数
  int _getTotalResourcesInPeriod(DateTime start, DateTime end) {
    // 模拟获取资源数量
    return 100;
  }

  /// 获取按严重程度分组的违规
  Map<String, int> _getViolationsBySeverity() {
    final result = <String, int>{};
    for (final severity in ViolationSeverity.values) {
      result[severity.name] =
          _violations.where((v) => v.severity == severity).length;
    }
    return result;
  }

  /// 初始化默认规则
  void _initializeDefaultRules() {
    // SOX合规规则
    _rules['sox_data_retention'] = ComplianceRule(
      id: 'sox_data_retention',
      name: 'SOX Data Retention',
      standard: ComplianceStandard.sox,
      description: 'Financial data must be retained for 7 years',
      ruleType: 'data_retention',
      severity: ViolationSeverity.high,
      enabled: true,
      conditions: {
        'retentionPeriod': 2555, // 7 years in days
        'applicableTypes': ['financial_template', 'audit_template'],
      },
      remediation: 'Ensure financial data retention policies are implemented',
      references: ['SOX Section 802'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // GDPR合规规则
    _rules['gdpr_encryption'] = ComplianceRule(
      id: 'gdpr_encryption',
      name: 'GDPR Data Encryption',
      standard: ComplianceStandard.gdpr,
      description: 'Personal data must be encrypted',
      ruleType: 'encryption',
      severity: ViolationSeverity.critical,
      enabled: true,
      conditions: {
        'requiresEncryption': true,
        'applicableTypes': ['user_template', 'personal_data_template'],
      },
      remediation: 'Implement encryption for personal data',
      references: ['GDPR Article 32'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 通用访问控制规则
    _rules['access_control'] = ComplianceRule(
      id: 'access_control',
      name: 'Access Control',
      standard: ComplianceStandard.iso27001,
      description: 'Proper access controls must be in place',
      ruleType: 'access_control',
      severity: ViolationSeverity.medium,
      enabled: true,
      conditions: {
        'requiredPermissions': ['read', 'audit'],
        'applicableTypes': ['template'],
      },
      remediation: 'Implement proper access controls',
      references: ['ISO 27001 A.9'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 生成报告ID
  String _generateReportId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'report_$timestamp';
  }

  /// 生成违规ID
  String _generateViolationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'violation_$timestamp';
  }
}
