/*
---------------------------------------------------------------
File name:          template_metadata.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板元数据系统 (Enterprise Template Metadata System)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 高级模板元数据管理;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 企业级模板元数据
///
/// 包含模板的完整元数据信息，支持企业级管理需求
class TemplateMetadata {
  /// 创建模板元数据实例
  const TemplateMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.subType,
    this.tags = const [],
    this.complexity = TemplateComplexity.medium,
    this.maturity = TemplateMaturity.stable,
    this.platform = TemplatePlatform.crossPlatform,
    this.framework = TemplateFramework.agnostic,
    this.license,
    this.support,
    this.security,
    this.organizationId,
    this.teamId,
    this.compliance,
    this.certification,
    this.dependencies = const [],
    this.keywords = const [],
    this.category,
    this.homepage,
    this.repository,
    this.documentation,
    this.changelog,
    this.downloadCount = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  /// 从JSON创建实例
  factory TemplateMetadata.fromJson(Map<String, dynamic> json) {
    return TemplateMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      author: json['author'] as String,
      description: json['description'] as String,
      type: TemplateType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TemplateType.basic,
      ),
      subType: json['subType'] != null
          ? TemplateSubType.values.firstWhere(
              (st) => st.name == json['subType'],
            )
          : null,
      tags:
          (json['tags'] as List<dynamic>?)?.map((t) => t as String).toList() ??
              [],
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((k) => k as String)
              .toList() ??
          [],
      category: json['category'] as String?,
      complexity: TemplateComplexity.values.firstWhere(
        (c) => c.name == json['complexity'],
        orElse: () => TemplateComplexity.medium,
      ),
      maturity: TemplateMaturity.values.firstWhere(
        (m) => m.name == json['maturity'],
        orElse: () => TemplateMaturity.stable,
      ),
      platform: TemplatePlatform.values.firstWhere(
        (p) => p.name == json['platform'],
        orElse: () => TemplatePlatform.crossPlatform,
      ),
      framework: TemplateFramework.values.firstWhere(
        (f) => f.name == json['framework'],
        orElse: () => TemplateFramework.agnostic,
      ),
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map(
                (d) => TemplateDependency.fromJson(d as Map<String, dynamic>),
              )
              .toList() ??
          [],
      license: json['license'] != null
          ? LicenseInfo.fromJson(json['license'] as Map<String, dynamic>)
          : null,
      support: json['support'] != null
          ? SupportInfo.fromJson(json['support'] as Map<String, dynamic>)
          : null,
      security: json['security'] != null
          ? SecurityInfo.fromJson(json['security'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      organizationId: json['organizationId'] as String?,
      teamId: json['teamId'] as String?,
      compliance: json['compliance'] != null
          ? ComplianceInfo.fromJson(json['compliance'] as Map<String, dynamic>)
          : null,
      certification: json['certification'] != null
          ? CertificationInfo.fromJson(
              json['certification'] as Map<String, dynamic>,
            )
          : null,
      homepage: json['homepage'] as String?,
      repository: json['repository'] as String?,
      documentation: json['documentation'] as String?,
      changelog: json['changelog'] as String?,
      downloadCount: json['downloadCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }

  // === 基础信息 ===
  /// 模板唯一标识符
  final String id;

  /// 模板名称
  final String name;

  /// 模板版本 (遵循SemVer规范)
  final String version;

  /// 模板作者
  final String author;

  /// 模板描述
  final String description;

  /// 模板类型
  final TemplateType type;

  /// 模板子类型
  final TemplateSubType? subType;

  /// 标签列表
  final List<String> tags;

  /// 关键词列表 (用于搜索)
  final List<String> keywords;

  /// 模板分类
  final String? category;

  // === 技术信息 ===
  /// 复杂度等级
  final TemplateComplexity complexity;

  /// 成熟度等级
  final TemplateMaturity maturity;

  /// 支持平台
  final TemplatePlatform platform;

  /// 技术框架
  final TemplateFramework framework;

  /// 依赖列表
  final List<TemplateDependency> dependencies;

  // === 法律和支持信息 ===
  /// 许可证信息
  final LicenseInfo? license;

  /// 支持信息
  final SupportInfo? support;

  /// 安全信息
  final SecurityInfo? security;

  // === 时间信息 ===
  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime updatedAt;

  // === 企业级信息 ===
  /// 组织ID
  final String? organizationId;

  /// 团队ID
  final String? teamId;

  /// 合规信息
  final ComplianceInfo? compliance;

  /// 认证信息
  final CertificationInfo? certification;

  // === 链接信息 ===
  /// 主页链接
  final String? homepage;

  /// 代码仓库链接
  final String? repository;

  /// 文档链接
  final String? documentation;

  /// 变更日志链接
  final String? changelog;

  // === 使用统计 ===
  /// 下载次数
  final int downloadCount;

  /// 平均评分 (0.0-5.0)
  final double rating;

  /// 评价数量
  final int reviewCount;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'author': author,
      'description': description,
      'type': type.name,
      'subType': subType?.name,
      'tags': tags,
      'keywords': keywords,
      'category': category,
      'complexity': complexity.name,
      'maturity': maturity.name,
      'platform': platform.name,
      'framework': framework.name,
      'dependencies': dependencies.map((d) => d.toJson()).toList(),
      'license': license?.toJson(),
      'support': support?.toJson(),
      'security': security?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'organizationId': organizationId,
      'teamId': teamId,
      'compliance': compliance?.toJson(),
      'certification': certification?.toJson(),
      'homepage': homepage,
      'repository': repository,
      'documentation': documentation,
      'changelog': changelog,
      'downloadCount': downloadCount,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  /// 创建副本并更新指定字段
  TemplateMetadata copyWith({
    String? id,
    String? name,
    String? version,
    String? author,
    String? description,
    TemplateType? type,
    TemplateSubType? subType,
    List<String>? tags,
    List<String>? keywords,
    String? category,
    TemplateComplexity? complexity,
    TemplateMaturity? maturity,
    TemplatePlatform? platform,
    TemplateFramework? framework,
    List<TemplateDependency>? dependencies,
    LicenseInfo? license,
    SupportInfo? support,
    SecurityInfo? security,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? organizationId,
    String? teamId,
    ComplianceInfo? compliance,
    CertificationInfo? certification,
    String? homepage,
    String? repository,
    String? documentation,
    String? changelog,
    int? downloadCount,
    double? rating,
    int? reviewCount,
  }) {
    return TemplateMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      author: author ?? this.author,
      description: description ?? this.description,
      type: type ?? this.type,
      subType: subType ?? this.subType,
      tags: tags ?? this.tags,
      keywords: keywords ?? this.keywords,
      category: category ?? this.category,
      complexity: complexity ?? this.complexity,
      maturity: maturity ?? this.maturity,
      platform: platform ?? this.platform,
      framework: framework ?? this.framework,
      dependencies: dependencies ?? this.dependencies,
      license: license ?? this.license,
      support: support ?? this.support,
      security: security ?? this.security,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organizationId: organizationId ?? this.organizationId,
      teamId: teamId ?? this.teamId,
      compliance: compliance ?? this.compliance,
      certification: certification ?? this.certification,
      homepage: homepage ?? this.homepage,
      repository: repository ?? this.repository,
      documentation: documentation ?? this.documentation,
      changelog: changelog ?? this.changelog,
      downloadCount: downloadCount ?? this.downloadCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  @override
  String toString() {
    return 'TemplateMetadata(id: $id, name: $name, version: $version, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateMetadata &&
        other.id == id &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(id, version);
}

/// 模板依赖信息
class TemplateDependency {
  /// 创建模板依赖实例
  const TemplateDependency({
    required this.name,
    required this.version,
    this.type = DependencyType.required,
    this.description,
  });

  /// 从JSON创建实例
  factory TemplateDependency.fromJson(Map<String, dynamic> json) {
    return TemplateDependency(
      name: json['name'] as String,
      version: json['version'] as String,
      type: DependencyType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DependencyType.required,
      ),
      description: json['description'] as String?,
    );
  }

  /// 依赖名称
  final String name;

  /// 依赖版本约束
  final String version;

  /// 依赖类型
  final DependencyType type;

  /// 依赖描述
  final String? description;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'type': type.name,
      'description': description,
    };
  }
}

/// 依赖类型枚举
enum DependencyType {
  /// 必需依赖
  required,

  /// 可选依赖
  optional,

  /// 开发依赖
  development,

  /// 对等依赖
  peer,
}

/// 许可证信息
class LicenseInfo {
  /// 创建许可证信息实例
  const LicenseInfo({
    required this.name,
    required this.url,
    this.spdxId,
  });

  /// 从JSON创建实例
  factory LicenseInfo.fromJson(Map<String, dynamic> json) {
    return LicenseInfo(
      name: json['name'] as String,
      url: json['url'] as String,
      spdxId: json['spdxId'] as String?,
    );
  }

  /// 许可证名称
  final String name;

  /// 许可证URL
  final String url;

  /// SPDX许可证标识符
  final String? spdxId;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'spdxId': spdxId,
    };
  }
}

/// 支持信息
class SupportInfo {
  /// 创建支持信息实例
  const SupportInfo({
    this.email,
    this.website,
    this.documentation,
    this.community,
    this.level = SupportLevel.community,
  });

  /// 从JSON创建实例
  factory SupportInfo.fromJson(Map<String, dynamic> json) {
    return SupportInfo(
      email: json['email'] as String?,
      website: json['website'] as String?,
      documentation: json['documentation'] as String?,
      community: json['community'] as String?,
      level: SupportLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => SupportLevel.community,
      ),
    );
  }

  /// 支持邮箱
  final String? email;

  /// 支持网站
  final String? website;

  /// 文档链接
  final String? documentation;

  /// 社区链接
  final String? community;

  /// 支持级别
  final SupportLevel level;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'website': website,
      'documentation': documentation,
      'community': community,
      'level': level.name,
    };
  }
}

/// 支持级别枚举
enum SupportLevel {
  /// 社区支持
  community,

  /// 商业支持
  commercial,

  /// 企业支持
  enterprise,

  /// 无支持
  none,
}

/// 安全信息
class SecurityInfo {
  /// 创建安全信息实例
  const SecurityInfo({
    this.vulnerabilities = const [],
    this.lastAudit,
    this.securityPolicy,
    this.contactEmail,
  });

  /// 从JSON创建实例
  factory SecurityInfo.fromJson(Map<String, dynamic> json) {
    return SecurityInfo(
      vulnerabilities: (json['vulnerabilities'] as List<dynamic>?)
              ?.map((v) => v as String)
              .toList() ??
          [],
      lastAudit: json['lastAudit'] != null
          ? DateTime.parse(json['lastAudit'] as String)
          : null,
      securityPolicy: json['securityPolicy'] as String?,
      contactEmail: json['contactEmail'] as String?,
    );
  }

  /// 已知漏洞列表
  final List<String> vulnerabilities;

  /// 最后安全审计时间
  final DateTime? lastAudit;

  /// 安全策略链接
  final String? securityPolicy;

  /// 安全联系邮箱
  final String? contactEmail;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'vulnerabilities': vulnerabilities,
      'lastAudit': lastAudit?.toIso8601String(),
      'securityPolicy': securityPolicy,
      'contactEmail': contactEmail,
    };
  }
}

/// 合规信息
class ComplianceInfo {
  /// 创建合规信息实例
  const ComplianceInfo({
    this.standards = const [],
    this.certifications = const [],
    this.auditDate,
    this.auditReport,
  });

  /// 从JSON创建实例
  factory ComplianceInfo.fromJson(Map<String, dynamic> json) {
    return ComplianceInfo(
      standards: (json['standards'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((c) => c as String)
              .toList() ??
          [],
      auditDate: json['auditDate'] != null
          ? DateTime.parse(json['auditDate'] as String)
          : null,
      auditReport: json['auditReport'] as String?,
    );
  }

  /// 合规标准列表
  final List<String> standards;

  /// 认证列表
  final List<String> certifications;

  /// 审计日期
  final DateTime? auditDate;

  /// 审计报告链接
  final String? auditReport;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'standards': standards,
      'certifications': certifications,
      'auditDate': auditDate?.toIso8601String(),
      'auditReport': auditReport,
    };
  }
}

/// 认证信息
class CertificationInfo {
  /// 创建认证信息实例
  const CertificationInfo({
    required this.name,
    required this.issuer,
    required this.issuedDate,
    this.expiryDate,
    this.certificateUrl,
  });

  /// 从JSON创建实例
  factory CertificationInfo.fromJson(Map<String, dynamic> json) {
    return CertificationInfo(
      name: json['name'] as String,
      issuer: json['issuer'] as String,
      issuedDate: DateTime.parse(json['issuedDate'] as String),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      certificateUrl: json['certificateUrl'] as String?,
    );
  }

  /// 认证名称
  final String name;

  /// 颁发机构
  final String issuer;

  /// 颁发日期
  final DateTime issuedDate;

  /// 过期日期
  final DateTime? expiryDate;

  /// 证书链接
  final String? certificateUrl;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'issuedDate': issuedDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'certificateUrl': certificateUrl,
    };
  }
}
