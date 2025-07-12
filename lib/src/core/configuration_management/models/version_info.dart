/*
---------------------------------------------------------------
File name:          version_info.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        版本信息模型 (Version Info Model)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 企业级模板配置管理系统;
---------------------------------------------------------------
*/
import 'package:pub_semver/pub_semver.dart';

/// 版本信息模型
///
/// 包含依赖包的版本信息、发布时间、稳定性等元数据
class VersionInfo {
  /// 创建版本信息实例
  const VersionInfo({
    required this.packageName,
    required this.version,
    required this.publishedAt,
    this.isPrerelease = false,
    this.isStable = true,
    this.downloadCount,
    this.description,
    this.changelogUrl,
    this.documentationUrl,
    this.repositoryUrl,
    this.license,
    this.dependencies = const {},
    this.devDependencies = const {},
  });

  /// 从JSON创建版本信息实例
  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      packageName: json['packageName'] as String,
      version: Version.parse(json['version'] as String),
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      isPrerelease: json['isPrerelease'] as bool? ?? false,
      isStable: json['isStable'] as bool? ?? true,
      downloadCount: json['downloadCount'] as int?,
      description: json['description'] as String?,
      changelogUrl: json['changelogUrl'] as String?,
      documentationUrl: json['documentationUrl'] as String?,
      repositoryUrl: json['repositoryUrl'] as String?,
      license: json['license'] as String?,
      dependencies: _parseVersionConstraints(
          json['dependencies'] as Map<String, dynamic>?),
      devDependencies: _parseVersionConstraints(
          json['devDependencies'] as Map<String, dynamic>?),
    );
  }

  /// 包名
  final String packageName;

  /// 版本号
  final Version version;

  /// 发布时间
  final DateTime publishedAt;

  /// 是否为预发布版本
  final bool isPrerelease;

  /// 是否为稳定版本
  final bool isStable;

  /// 下载量（用于评估流行度）
  final int? downloadCount;

  /// 版本描述
  final String? description;

  /// 变更日志URL
  final String? changelogUrl;

  /// 文档URL
  final String? documentationUrl;

  /// 仓库URL
  final String? repositoryUrl;

  /// 许可证
  final String? license;

  /// 依赖列表
  final Map<String, VersionConstraint> dependencies;

  /// 开发依赖列表
  final Map<String, VersionConstraint> devDependencies;

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'version': version.toString(),
      'publishedAt': publishedAt.toIso8601String(),
      'isPrerelease': isPrerelease,
      'isStable': isStable,
      'downloadCount': downloadCount,
      'description': description,
      'changelogUrl': changelogUrl,
      'documentationUrl': documentationUrl,
      'repositoryUrl': repositoryUrl,
      'license': license,
      'dependencies': _versionConstraintsToJson(dependencies),
      'devDependencies': _versionConstraintsToJson(devDependencies),
    };
  }

  /// 创建副本
  VersionInfo copyWith({
    String? packageName,
    Version? version,
    DateTime? publishedAt,
    bool? isPrerelease,
    bool? isStable,
    int? downloadCount,
    String? description,
    String? changelogUrl,
    String? documentationUrl,
    String? repositoryUrl,
    String? license,
    Map<String, VersionConstraint>? dependencies,
    Map<String, VersionConstraint>? devDependencies,
  }) {
    return VersionInfo(
      packageName: packageName ?? this.packageName,
      version: version ?? this.version,
      publishedAt: publishedAt ?? this.publishedAt,
      isPrerelease: isPrerelease ?? this.isPrerelease,
      isStable: isStable ?? this.isStable,
      downloadCount: downloadCount ?? this.downloadCount,
      description: description ?? this.description,
      changelogUrl: changelogUrl ?? this.changelogUrl,
      documentationUrl: documentationUrl ?? this.documentationUrl,
      repositoryUrl: repositoryUrl ?? this.repositoryUrl,
      license: license ?? this.license,
      dependencies: dependencies ?? this.dependencies,
      devDependencies: devDependencies ?? this.devDependencies,
    );
  }

  /// 计算版本新鲜度（0-1之间，1表示最新）
  double calculateFreshness() {
    final now = DateTime.now();
    final daysSincePublished = now.difference(publishedAt).inDays;

    // 30天内的版本认为是新鲜的
    if (daysSincePublished <= 30) return 1;

    // 1年后的版本新鲜度为0
    if (daysSincePublished >= 365) return 0;

    // 线性衰减
    return 1.0 - (daysSincePublished - 30) / (365 - 30);
  }

  /// 计算版本稳定性评分（0-1之间，1表示最稳定）
  double calculateStabilityScore() {
    var score = 0.0;

    // 基础稳定性
    if (isStable) score += 0.4;
    if (!isPrerelease) score += 0.3;

    // 发布时间稳定性（发布时间越久越稳定）
    final daysSincePublished = DateTime.now().difference(publishedAt).inDays;
    if (daysSincePublished >= 90) {
      score += 0.2; // 发布90天以上认为稳定
    } else {
      score += (daysSincePublished / 90) * 0.2;
    }

    // 流行度稳定性
    if (downloadCount != null) {
      if (downloadCount! >= 10000) {
        score += 0.1; // 高下载量认为稳定
      } else {
        score += (downloadCount! / 10000) * 0.1;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// 检查是否与另一个版本兼容
  bool isCompatibleWith(VersionInfo other) {
    // 1. 检查直接依赖冲突
    if (!_checkDirectDependencyCompatibility(other)) {
      return false;
    }

    // 2. 检查传递依赖冲突
    if (!_checkTransitiveDependencyCompatibility(other)) {
      return false;
    }

    // 3. 检查版本范围兼容性
    if (!_checkVersionRangeCompatibility(other)) {
      return false;
    }

    // 4. 检查平台兼容性
    if (!_checkPlatformCompatibility(other)) {
      return false;
    }

    return true;
  }

  /// 检查直接依赖兼容性
  bool _checkDirectDependencyCompatibility(VersionInfo other) {
    for (final entry in dependencies.entries) {
      final packageName = entry.key;
      final constraint = entry.value;

      if (other.dependencies.containsKey(packageName)) {
        final otherConstraint = other.dependencies[packageName]!;
        if (!_constraintsCompatible(constraint, otherConstraint)) {
          return false;
        }
      }
    }
    return true;
  }

  /// 检查传递依赖兼容性
  bool _checkTransitiveDependencyCompatibility(VersionInfo other) {
    // 检查开发依赖与生产依赖的冲突
    for (final entry in devDependencies.entries) {
      final packageName = entry.key;
      final devConstraint = entry.value;

      if (other.dependencies.containsKey(packageName)) {
        final prodConstraint = other.dependencies[packageName]!;
        // 开发依赖和生产依赖可能有不同的版本要求
        if (!_isDevProdCompatible(devConstraint, prodConstraint)) {
          return false;
        }
      }
    }
    return true;
  }

  /// 检查版本范围兼容性
  bool _checkVersionRangeCompatibility(VersionInfo other) {
    // 检查主版本兼容性
    if (version.major != other.version.major) {
      // 主版本不同时，检查是否在兼容范围内
      return _isMajorVersionCompatible(version, other.version);
    }

    // 检查次版本兼容性
    if (version.minor != other.version.minor) {
      return _isMinorVersionCompatible(version, other.version);
    }

    return true;
  }

  /// 检查平台兼容性
  bool _checkPlatformCompatibility(VersionInfo other) {
    // 检查 Flutter/Dart SDK 兼容性
    if (packageName == 'flutter' || other.packageName == 'flutter') {
      return _isFlutterCompatible(other);
    }

    // 检查平台特定包的兼容性
    if (_isPlatformSpecific(packageName) ||
        _isPlatformSpecific(other.packageName)) {
      return _arePlatformPackagesCompatible(other);
    }

    return true;
  }

  /// 检查开发依赖和生产依赖兼容性
  bool _isDevProdCompatible(
    VersionConstraint devConstraint,
    VersionConstraint prodConstraint,
  ) {
    try {
      // 开发依赖通常可以使用更新的版本
      final intersection = devConstraint.intersect(prodConstraint);
      return intersection != VersionConstraint.empty ||
          _isDevVersionAcceptable(devConstraint, prodConstraint);
    } catch (e) {
      return false;
    }
  }

  /// 检查开发版本是否可接受
  bool _isDevVersionAcceptable(
    VersionConstraint devConstraint,
    VersionConstraint prodConstraint,
  ) {
    // 开发依赖可以使用更高版本，只要不破坏生产依赖
    if (devConstraint is VersionRange && prodConstraint is VersionRange) {
      return devConstraint.min != null &&
          prodConstraint.max != null &&
          devConstraint.min!.compareTo(prodConstraint.max!) <= 0;
    }
    return false;
  }

  /// 检查主版本兼容性
  bool _isMajorVersionCompatible(Version v1, Version v2) {
    // 对于某些包，主版本差异是可接受的
    const flexiblePackages = {
      'build_runner',
      'json_serializable',
      'freezed',
      'very_good_analysis',
      'mocktail',
      'test',
    };

    if (flexiblePackages.contains(packageName)) {
      // 允许向后兼容的主版本差异
      return (v1.major - v2.major).abs() <= 1;
    }

    return false;
  }

  /// 检查次版本兼容性
  bool _isMinorVersionCompatible(Version v1, Version v2) {
    // 次版本差异通常是兼容的（语义化版本）
    return (v1.minor - v2.minor).abs() <= 5; // 允许5个次版本的差异
  }

  /// 检查 Flutter 兼容性
  bool _isFlutterCompatible(VersionInfo other) {
    // Flutter 版本兼容性检查
    const flutterDartCompatibility = {
      '3.16.0': '3.2.0',
      '3.17.0': '3.3.0',
      '3.18.0': '3.4.0',
      '3.19.0': '3.5.0',
    };

    if (packageName == 'flutter' && other.packageName == 'dart') {
      final requiredDart = flutterDartCompatibility[version.toString()];
      if (requiredDart != null) {
        final requiredVersion = Version.parse(requiredDart);
        return other.version.compareTo(requiredVersion) >= 0;
      }
    }

    return true;
  }

  /// 检查是否为平台特定包
  bool _isPlatformSpecific(String packageName) {
    const platformPackages = {
      'flutter',
      'flutter_test',
      'flutter_driver',
      'cupertino_icons',
      'material_design_icons_flutter',
      'path_provider',
      'shared_preferences',
      'sqflite',
    };
    return platformPackages.contains(packageName);
  }

  /// 检查平台包兼容性
  bool _arePlatformPackagesCompatible(VersionInfo other) {
    // 平台特定包的兼容性检查
    const incompatiblePairs = {
      'cupertino_icons': ['material_design_icons_flutter'],
      'sqflite': ['hive', 'isar'], // 数据库包可能冲突
    };

    final conflicts = incompatiblePairs[packageName];
    if (conflicts != null && conflicts.contains(other.packageName)) {
      return false;
    }

    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VersionInfo &&
        other.packageName == packageName &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(packageName, version);

  @override
  String toString() {
    return 'VersionInfo(packageName: $packageName, version: $version, '
        'publishedAt: $publishedAt, isStable: $isStable)';
  }

  /// 解析版本约束
  static Map<String, VersionConstraint> _parseVersionConstraints(
    Map<String, dynamic>? json,
  ) {
    if (json == null) return {};

    return json.map((key, value) {
      return MapEntry(key, VersionConstraint.parse(value as String));
    });
  }

  /// 版本约束转JSON
  static Map<String, String> _versionConstraintsToJson(
    Map<String, VersionConstraint> constraints,
  ) {
    return constraints.map((key, value) {
      return MapEntry(key, value.toString());
    });
  }

  /// 检查两个版本约束是否兼容
  static bool _constraintsCompatible(VersionConstraint a, VersionConstraint b) {
    // 简化的兼容性检查，实际实现可能更复杂
    try {
      return a.intersect(b) != VersionConstraint.empty;
    } catch (e) {
      return false;
    }
  }
}
