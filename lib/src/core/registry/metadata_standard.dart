/*
---------------------------------------------------------------
File name:          metadata_standard.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板元数据标准 (Template Metadata Standard)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 远程模板生态建设;
---------------------------------------------------------------
*/

/// 模板复杂度枚举
enum TemplateComplexity {
  /// 简单
  simple,

  /// 中等
  medium,

  /// 复杂
  complex,

  /// 高级
  advanced,
}

/// 模板成熟度枚举
enum TemplateMaturity {
  /// 实验性
  experimental,

  /// Alpha版本
  alpha,

  /// Beta版本
  beta,

  /// 稳定版本
  stable,

  /// 已弃用
  deprecated,
}

/// 许可证信息
class LicenseInfo {
  const LicenseInfo({
    required this.spdxId,
    required this.name,
    required this.isOpenSource,
    required this.isCommercialFriendly,
    this.url,
  });

  factory LicenseInfo.fromJson(Map<String, dynamic> json) {
    return LicenseInfo(
      spdxId: json['spdxId'] as String,
      name: json['name'] as String,
      url: json['url'] as String?,
      isOpenSource: json['isOpenSource'] as bool,
      isCommercialFriendly: json['isCommercialFriendly'] as bool,
    );
  }

  /// 许可证标识符 (SPDX)
  final String spdxId;

  /// 许可证名称
  final String name;

  /// 许可证URL
  final String? url;

  /// 是否开源
  final bool isOpenSource;

  /// 是否商业友好
  final bool isCommercialFriendly;

  Map<String, dynamic> toJson() {
    return {
      'spdxId': spdxId,
      'name': name,
      'url': url,
      'isOpenSource': isOpenSource,
      'isCommercialFriendly': isCommercialFriendly,
    };
  }
}

/// 支持信息
class SupportInfo {
  const SupportInfo({
    this.email,
    this.url,
    this.docsUrl,
    this.issuesUrl,
    this.communityUrl,
  });

  factory SupportInfo.fromJson(Map<String, dynamic> json) {
    return SupportInfo(
      email: json['email'] as String?,
      url: json['url'] as String?,
      docsUrl: json['docsUrl'] as String?,
      issuesUrl: json['issuesUrl'] as String?,
      communityUrl: json['communityUrl'] as String?,
    );
  }

  /// 支持邮箱
  final String? email;

  /// 支持URL
  final String? url;

  /// 文档URL
  final String? docsUrl;

  /// 问题追踪URL
  final String? issuesUrl;

  /// 社区URL
  final String? communityUrl;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'url': url,
      'docsUrl': docsUrl,
      'issuesUrl': issuesUrl,
      'communityUrl': communityUrl,
    };
  }
}

/// 安全信息
class SecurityInfo {
  const SecurityInfo({
    this.signature,
    this.signatureAlgorithm,
    this.certificateFingerprint,
    this.scanResults,
    this.vulnerabilities,
    this.securityLevel,
  });

  factory SecurityInfo.fromJson(Map<String, dynamic> json) {
    return SecurityInfo(
      signature: json['signature'] as String?,
      signatureAlgorithm: json['signatureAlgorithm'] as String?,
      certificateFingerprint: json['certificateFingerprint'] as String?,
      scanResults: json['scanResults'] as Map<String, dynamic>?,
      vulnerabilities:
          (json['vulnerabilities'] as List<dynamic>?)?.cast<String>(),
      securityLevel: json['securityLevel'] as String?,
    );
  }

  /// 数字签名
  final String? signature;

  /// 签名算法
  final String? signatureAlgorithm;

  /// 证书指纹
  final String? certificateFingerprint;

  /// 安全扫描结果
  final Map<String, dynamic>? scanResults;

  /// 漏洞报告
  final List<String>? vulnerabilities;

  /// 安全等级
  final String? securityLevel;

  Map<String, dynamic> toJson() {
    return {
      'signature': signature,
      'signatureAlgorithm': signatureAlgorithm,
      'certificateFingerprint': certificateFingerprint,
      'scanResults': scanResults,
      'vulnerabilities': vulnerabilities,
      'securityLevel': securityLevel,
    };
  }
}

/// 依赖信息
class DependencyInfo {
  const DependencyInfo({
    required this.name,
    required this.versionConstraint,
    this.optional = false,
    this.type = 'runtime',
    this.description,
  });

  factory DependencyInfo.fromJson(Map<String, dynamic> json) {
    return DependencyInfo(
      name: json['name'] as String,
      versionConstraint: json['versionConstraint'] as String,
      optional: json['optional'] as bool? ?? false,
      type: json['type'] as String? ?? 'runtime',
      description: json['description'] as String?,
    );
  }

  /// 依赖名称
  final String name;

  /// 版本约束
  final String versionConstraint;

  /// 是否可选
  final bool optional;

  /// 依赖类型
  final String type;

  /// 描述
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'versionConstraint': versionConstraint,
      'optional': optional,
      'type': type,
      'description': description,
    };
  }
}

/// 兼容性信息
class CompatibilityInfo {
  const CompatibilityInfo({
    required this.platforms,
    required this.minimumVersions,
    required this.testedVersions,
    required this.incompatibleVersions,
  });

  factory CompatibilityInfo.fromJson(Map<String, dynamic> json) {
    return CompatibilityInfo(
      platforms: (json['platforms'] as List<dynamic>).cast<String>(),
      minimumVersions: (json['minimumVersions'] as Map<String, dynamic>)
          .cast<String, String>(),
      testedVersions: (json['testedVersions'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
      ),
      incompatibleVersions:
          (json['incompatibleVersions'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
      ),
    );
  }

  /// 支持的平台
  final List<String> platforms;

  /// 最低版本要求
  final Map<String, String> minimumVersions;

  /// 测试过的版本
  final Map<String, List<String>> testedVersions;

  /// 已知不兼容的版本
  final Map<String, List<String>> incompatibleVersions;

  Map<String, dynamic> toJson() {
    return {
      'platforms': platforms,
      'minimumVersions': minimumVersions,
      'testedVersions': testedVersions,
      'incompatibleVersions': incompatibleVersions,
    };
  }
}

/// 本地化信息
class LocalizationInfo {
  const LocalizationInfo({
    required this.language,
    required this.name,
    required this.description,
    required this.tags,
    required this.keywords,
  });

  factory LocalizationInfo.fromJson(Map<String, dynamic> json) {
    return LocalizationInfo(
      language: json['language'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      keywords: (json['keywords'] as List<dynamic>).cast<String>(),
    );
  }

  /// 语言代码
  final String language;

  /// 本地化的名称
  final String name;

  /// 本地化的描述
  final String description;

  /// 本地化的标签
  final List<String> tags;

  /// 本地化的关键词
  final List<String> keywords;

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'name': name,
      'description': description,
      'tags': tags,
      'keywords': keywords,
    };
  }
}

/// 模板元数据标准 v2.0
class TemplateMetadataV2 {
  const TemplateMetadataV2({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.tags,
    required this.keywords,
    required this.complexity,
    required this.maturity,
    required this.license,
    required this.support,
    required this.dependencies,
    required this.compatibility,
    required this.localizations,
    required this.createdAt,
    required this.updatedAt,
    required this.downloadUrl,
    required this.fileSize,
    required this.fileHash,
    this.metadataVersion = '2.0',
    this.authorEmail,
    this.security,
    this.custom = const {},
  });

  factory TemplateMetadataV2.fromJson(Map<String, dynamic> json) {
    return TemplateMetadataV2(
      metadataVersion: json['metadataVersion'] as String? ?? '2.0',
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      authorEmail: json['authorEmail'] as String?,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      keywords: (json['keywords'] as List<dynamic>).cast<String>(),
      complexity:
          TemplateComplexity.values.byName(json['complexity'] as String),
      maturity: TemplateMaturity.values.byName(json['maturity'] as String),
      license: LicenseInfo.fromJson(json['license'] as Map<String, dynamic>),
      support: SupportInfo.fromJson(json['support'] as Map<String, dynamic>),
      security: json['security'] != null
          ? SecurityInfo.fromJson(json['security'] as Map<String, dynamic>)
          : null,
      dependencies: (json['dependencies'] as List<dynamic>)
          .map((dep) => DependencyInfo.fromJson(dep as Map<String, dynamic>))
          .toList(),
      compatibility: CompatibilityInfo.fromJson(
          json['compatibility'] as Map<String, dynamic>),
      localizations: (json['localizations'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
            key, LocalizationInfo.fromJson(value as Map<String, dynamic>)),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      downloadUrl: json['downloadUrl'] as String,
      fileSize: json['fileSize'] as int,
      fileHash: json['fileHash'] as String,
      custom: json['custom'] as Map<String, dynamic>? ?? {},
    );
  }

  /// 元数据版本
  final String metadataVersion;

  /// 模板ID
  final String id;

  /// 模板名称
  final String name;

  /// 版本
  final String version;

  /// 描述
  final String description;

  /// 作者
  final String author;

  /// 作者邮箱
  final String? authorEmail;

  /// 标签
  final List<String> tags;

  /// 关键词
  final List<String> keywords;

  /// 复杂度
  final TemplateComplexity complexity;

  /// 成熟度
  final TemplateMaturity maturity;

  /// 许可证信息
  final LicenseInfo license;

  /// 支持信息
  final SupportInfo support;

  /// 安全信息
  final SecurityInfo? security;

  /// 依赖列表
  final List<DependencyInfo> dependencies;

  /// 兼容性信息
  final CompatibilityInfo compatibility;

  /// 本地化信息
  final Map<String, LocalizationInfo> localizations;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  /// 下载URL
  final String downloadUrl;

  /// 文件大小 (字节)
  final int fileSize;

  /// 文件哈希 (SHA-256)
  final String fileHash;

  /// 自定义字段
  final Map<String, dynamic> custom;

  Map<String, dynamic> toJson() {
    return {
      'metadataVersion': metadataVersion,
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'author': author,
      'authorEmail': authorEmail,
      'tags': tags,
      'keywords': keywords,
      'complexity': complexity.name,
      'maturity': maturity.name,
      'license': license.toJson(),
      'support': support.toJson(),
      'security': security?.toJson(),
      'dependencies': dependencies.map((dep) => dep.toJson()).toList(),
      'compatibility': compatibility.toJson(),
      'localizations':
          localizations.map((key, value) => MapEntry(key, value.toJson())),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'downloadUrl': downloadUrl,
      'fileSize': fileSize,
      'fileHash': fileHash,
      'custom': custom,
    };
  }

  /// 验证元数据完整性
  List<String> validate() {
    final errors = <String>[];

    if (id.isEmpty) errors.add('Template ID is required');
    if (name.isEmpty) errors.add('Template name is required');
    if (version.isEmpty) errors.add('Template version is required');
    if (description.isEmpty) errors.add('Template description is required');
    if (author.isEmpty) errors.add('Template author is required');
    if (downloadUrl.isEmpty) errors.add('Download URL is required');
    if (fileSize <= 0) errors.add('File size must be positive');
    if (fileHash.isEmpty) errors.add('File hash is required');

    // 验证版本格式 (语义化版本)
    final versionRegex =
        RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$');
    if (!versionRegex.hasMatch(version)) {
      errors.add('Version must follow semantic versioning format');
    }

    // 验证URL格式
    try {
      Uri.parse(downloadUrl);
    } catch (e) {
      errors.add('Invalid download URL format');
    }

    // 验证哈希格式 (SHA-256)
    final hashRegex = RegExp(r'^[a-fA-F0-9]{64}$');
    if (!hashRegex.hasMatch(fileHash)) {
      errors.add('File hash must be a valid SHA-256 hash');
    }

    return errors;
  }

  /// 获取本地化信息
  LocalizationInfo? getLocalization(String language) {
    return localizations[language];
  }

  /// 获取默认本地化信息
  LocalizationInfo getDefaultLocalization() {
    return localizations['en'] ??
        LocalizationInfo(
          language: 'en',
          name: name,
          description: description,
          tags: tags,
          keywords: keywords,
        );
  }
}
