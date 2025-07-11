/*
---------------------------------------------------------------
File name:          dependency_resolver.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        依赖解析器 (Dependency Resolver)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 Week 2 智能搜索和分发系统;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:collection';

/// 版本约束类型
enum VersionConstraintType {
  /// 精确版本 (=1.0.0)
  exact,

  /// 兼容版本 (^1.0.0)
  compatible,

  /// 近似版本 (~1.0.0)
  approximate,

  /// 范围版本 (>=1.0.0 <2.0.0)
  range,

  /// 任意版本 (*)
  any,
}

/// 依赖类型
enum DependencyType {
  /// 运行时依赖
  runtime,

  /// 开发依赖
  development,

  /// 可选依赖
  optional,

  /// 对等依赖
  peer,

  /// 条件依赖
  conditional,
}

/// 版本信息
class Version implements Comparable<Version> {
  const Version({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease,
    this.build,
  });

  /// 从字符串解析版本
  factory Version.parse(String version) {
    final regex = RegExp(
        r'^(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9.-]+))?(?:\+([a-zA-Z0-9.-]+))?$');
    final match = regex.firstMatch(version);

    if (match == null) {
      throw FormatException('Invalid version format: $version');
    }

    return Version(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      preRelease: match.group(4),
      build: match.group(5),
    );
  }

  /// 主版本号
  final int major;

  /// 次版本号
  final int minor;

  /// 修订版本号
  final int patch;

  /// 预发布标识
  final String? preRelease;

  /// 构建元数据
  final String? build;

  @override
  int compareTo(Version other) {
    // 比较主版本号
    if (major != other.major) return major.compareTo(other.major);

    // 比较次版本号
    if (minor != other.minor) return minor.compareTo(other.minor);

    // 比较修订版本号
    if (patch != other.patch) return patch.compareTo(other.patch);

    // 比较预发布版本
    if (preRelease == null && other.preRelease == null) return 0;
    if (preRelease == null) return 1; // 正式版本 > 预发布版本
    if (other.preRelease == null) return -1;

    return preRelease!.compareTo(other.preRelease!);
  }

  @override
  String toString() {
    final buffer = StringBuffer('$major.$minor.$patch');
    if (preRelease != null) buffer.write('-$preRelease');
    if (build != null) buffer.write('+$build');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    return other is Version && compareTo(other) == 0;
  }

  @override
  int get hashCode => toString().hashCode;
}

/// 版本约束
class VersionConstraint {
  const VersionConstraint({
    required this.type,
    required this.expression,
    this.minVersion,
    this.maxVersion,
    this.includeMin = true,
    this.includeMax = false,
  });

  /// 从字符串解析版本约束
  factory VersionConstraint.parse(String constraint) {
    constraint = constraint.trim();

    // 任意版本
    if (constraint == '*' || constraint.isEmpty) {
      return VersionConstraint(
        type: VersionConstraintType.any,
        expression: constraint,
      );
    }

    // 兼容版本 (^1.0.0)
    if (constraint.startsWith('^')) {
      final version = Version.parse(constraint.substring(1));
      return VersionConstraint(
        type: VersionConstraintType.compatible,
        expression: constraint,
        minVersion: version,
        maxVersion: Version(major: version.major + 1, minor: 0, patch: 0),
      );
    }

    // 近似版本 (~1.0.0)
    if (constraint.startsWith('~')) {
      final version = Version.parse(constraint.substring(1));
      return VersionConstraint(
        type: VersionConstraintType.approximate,
        expression: constraint,
        minVersion: version,
        maxVersion:
            Version(major: version.major, minor: version.minor + 1, patch: 0),
      );
    }

    // 范围版本 (>=1.0.0 <2.0.0)
    final rangeRegex = RegExp(r'(>=|>|<=|<|=)\s*([^\s]+)');
    final matches = rangeRegex.allMatches(constraint).toList();

    if (matches.length >= 2) {
      Version? minVer;
      Version? maxVer;
      var includeMin = true;
      var includeMax = false;

      for (final match in matches) {
        final operator = match.group(1)!;
        final version = Version.parse(match.group(2)!);

        switch (operator) {
          case '>=':
            minVer = version;
            includeMin = true;
          case '>':
            minVer = version;
            includeMin = false;
          case '<=':
            maxVer = version;
            includeMax = true;
          case '<':
            maxVer = version;
            includeMax = false;
          case '=':
            return VersionConstraint(
              type: VersionConstraintType.exact,
              expression: constraint,
              minVersion: version,
              maxVersion: version,
              includeMax: true,
            );
        }
      }

      return VersionConstraint(
        type: VersionConstraintType.range,
        expression: constraint,
        minVersion: minVer,
        maxVersion: maxVer,
        includeMin: includeMin,
        includeMax: includeMax,
      );
    }

    // 精确版本
    final version = Version.parse(constraint);
    return VersionConstraint(
      type: VersionConstraintType.exact,
      expression: constraint,
      minVersion: version,
      maxVersion: version,
      includeMax: true,
    );
  }

  /// 约束类型
  final VersionConstraintType type;

  /// 约束表达式
  final String expression;

  /// 最小版本
  final Version? minVersion;

  /// 最大版本
  final Version? maxVersion;

  /// 是否包含最小版本
  final bool includeMin;

  /// 是否包含最大版本
  final bool includeMax;

  /// 检查版本是否满足约束
  bool allows(Version version) {
    switch (type) {
      case VersionConstraintType.any:
        return true;

      case VersionConstraintType.exact:
        return version == minVersion;

      case VersionConstraintType.compatible:
      case VersionConstraintType.approximate:
      case VersionConstraintType.range:
        var satisfiesMin = true;
        var satisfiesMax = true;

        if (minVersion != null) {
          final comparison = version.compareTo(minVersion!);
          satisfiesMin = includeMin ? comparison >= 0 : comparison > 0;
        }

        if (maxVersion != null) {
          final comparison = version.compareTo(maxVersion!);
          satisfiesMax = includeMax ? comparison <= 0 : comparison < 0;
        }

        return satisfiesMin && satisfiesMax;
    }
  }
}

/// 依赖信息
class Dependency {
  const Dependency({
    required this.name,
    required this.versionConstraint,
    this.type = DependencyType.runtime,
    this.optional = false,
    this.condition,
    this.license,
    this.securityRating,
  });

  /// 从JSON创建依赖
  factory Dependency.fromJson(Map<String, dynamic> json) {
    return Dependency(
      name: json['name'] as String,
      versionConstraint: VersionConstraint.parse(json['version'] as String),
      type: DependencyType.values.byName(json['type'] as String? ?? 'runtime'),
      optional: json['optional'] as bool? ?? false,
      condition: json['condition'] as String?,
      license: json['license'] as String?,
      securityRating: json['securityRating'] as String?,
    );
  }

  /// 依赖名称
  final String name;

  /// 版本约束
  final VersionConstraint versionConstraint;

  /// 依赖类型
  final DependencyType type;

  /// 是否可选
  final bool optional;

  /// 条件表达式
  final String? condition;

  /// 许可证信息
  final String? license;

  /// 安全评级
  final String? securityRating;
}

/// 依赖冲突
class DependencyConflict {
  const DependencyConflict({
    required this.dependencyName,
    required this.conflictingConstraints,
    required this.sources,
    this.suggestedResolution,
  });

  /// 冲突的依赖名称
  final String dependencyName;

  /// 冲突的版本约束
  final List<VersionConstraint> conflictingConstraints;

  /// 冲突来源
  final List<String> sources;

  /// 建议的解决方案
  final String? suggestedResolution;
}

/// 依赖解析结果
class ResolutionResult {
  const ResolutionResult({
    required this.resolvedVersions,
    required this.conflicts,
    required this.vulnerabilities,
    required this.licenseIssues,
    required this.resolutionTime,
  });

  /// 解析的依赖图
  final Map<String, Version> resolvedVersions;

  /// 依赖冲突列表
  final List<DependencyConflict> conflicts;

  /// 安全漏洞列表
  final List<String> vulnerabilities;

  /// 许可证兼容性问题
  final List<String> licenseIssues;

  /// 解析时间
  final Duration resolutionTime;

  /// 是否解析成功
  bool get isSuccessful => conflicts.isEmpty;

  /// 是否有安全问题
  bool get hasSecurityIssues => vulnerabilities.isNotEmpty;

  /// 是否有许可证问题
  bool get hasLicenseIssues => licenseIssues.isNotEmpty;
}

/// 依赖解析器
class DependencyResolver {
  /// 可用版本缓存
  final Map<String, List<Version>> _availableVersions = {};

  /// 依赖图缓存
  final Map<String, Map<String, Dependency>> _dependencyGraphs = {};

  /// 安全数据库
  final Map<String, List<String>> _vulnerabilityDatabase = {};

  /// 许可证兼容性矩阵
  final Map<String, List<String>> _licenseCompatibility = {};

  /// 解析依赖
  Future<ResolutionResult> resolveDependencies(
    List<Dependency> rootDependencies,
  ) async {
    final startTime = DateTime.now();

    try {
      // 构建依赖图
      final dependencyGraph = await _buildDependencyGraph(rootDependencies);

      // 解析版本冲突
      final resolvedVersions = await _resolveVersionConflicts(dependencyGraph);

      // 检查安全漏洞
      final vulnerabilities = await _checkVulnerabilities(resolvedVersions);

      // 检查许可证兼容性
      final licenseIssues = await _checkLicenseCompatibility(resolvedVersions);

      final resolutionTime = DateTime.now().difference(startTime);

      return ResolutionResult(
        resolvedVersions: resolvedVersions,
        conflicts: [],
        vulnerabilities: vulnerabilities,
        licenseIssues: licenseIssues,
        resolutionTime: resolutionTime,
      );
    } catch (e) {
      final resolutionTime = DateTime.now().difference(startTime);

      return ResolutionResult(
        resolvedVersions: {},
        conflicts: [
          DependencyConflict(
            dependencyName: 'resolution_error',
            conflictingConstraints: [],
            sources: [],
            suggestedResolution: e.toString(),
          ),
        ],
        vulnerabilities: [],
        licenseIssues: [],
        resolutionTime: resolutionTime,
      );
    }
  }

  /// 构建依赖图
  Future<Map<String, List<Dependency>>> _buildDependencyGraph(
    List<Dependency> rootDependencies,
  ) async {
    final graph = <String, List<Dependency>>{};
    final visited = <String>{};
    final queue = Queue<Dependency>.from(rootDependencies);

    while (queue.isNotEmpty) {
      final dependency = queue.removeFirst();

      if (visited.contains(dependency.name)) continue;
      visited.add(dependency.name);

      // 获取依赖的子依赖
      final subDependencies = await _getSubDependencies(dependency.name);
      graph[dependency.name] = subDependencies;

      // 添加子依赖到队列
      queue.addAll(subDependencies);
    }

    return graph;
  }

  /// 获取子依赖
  Future<List<Dependency>> _getSubDependencies(String packageName) async {
    // 模拟获取依赖信息
    await Future.delayed(const Duration(milliseconds: 10));

    // 返回模拟的依赖列表
    switch (packageName) {
      case 'flutter_clean_app':
        return [
          Dependency(
            name: 'flutter',
            versionConstraint: VersionConstraint.parse('^3.0.0'),
          ),
          Dependency(
            name: 'provider',
            versionConstraint: VersionConstraint.parse('^6.0.0'),
          ),
        ];
      case 'react_dashboard':
        return [
          Dependency(
            name: 'react',
            versionConstraint: VersionConstraint.parse('^18.0.0'),
          ),
          Dependency(
            name: 'typescript',
            versionConstraint: VersionConstraint.parse('^4.0.0'),
          ),
        ];
      default:
        return [];
    }
  }

  /// 解析版本冲突
  Future<Map<String, Version>> _resolveVersionConflicts(
    Map<String, List<Dependency>> dependencyGraph,
  ) async {
    final resolvedVersions = <String, Version>{};

    // 简化实现：选择每个依赖的最新兼容版本
    for (final packageName in dependencyGraph.keys) {
      final availableVersions = await _getAvailableVersions(packageName);
      if (availableVersions.isNotEmpty) {
        resolvedVersions[packageName] = availableVersions.last;
      }
    }

    return resolvedVersions;
  }

  /// 获取可用版本
  Future<List<Version>> _getAvailableVersions(String packageName) async {
    if (_availableVersions.containsKey(packageName)) {
      return _availableVersions[packageName]!;
    }

    // 模拟获取版本信息
    await Future.delayed(const Duration(milliseconds: 5));

    final versions = <Version>[];
    switch (packageName) {
      case 'flutter':
        versions.addAll([
          Version.parse('3.0.0'),
          Version.parse('3.1.0'),
          Version.parse('3.2.0'),
        ]);
      case 'provider':
        versions.addAll([
          Version.parse('6.0.0'),
          Version.parse('6.1.0'),
        ]);
      default:
        versions.add(Version.parse('1.0.0'));
    }

    _availableVersions[packageName] = versions;
    return versions;
  }

  /// 检查安全漏洞
  Future<List<String>> _checkVulnerabilities(
      Map<String, Version> resolvedVersions) async {
    final vulnerabilities = <String>[];

    for (final entry in resolvedVersions.entries) {
      final packageName = entry.key;
      final version = entry.value;

      // 模拟安全检查
      if (packageName == 'vulnerable_package' && version.major < 2) {
        vulnerabilities.add(
            '$packageName@$version has known security vulnerability CVE-2023-1234');
      }
    }

    return vulnerabilities;
  }

  /// 检查许可证兼容性
  Future<List<String>> _checkLicenseCompatibility(
      Map<String, Version> resolvedVersions) async {
    final licenseIssues = <String>[];

    // 模拟许可证检查
    for (final packageName in resolvedVersions.keys) {
      if (packageName == 'gpl_package') {
        licenseIssues.add(
            '$packageName uses GPL license which may not be compatible with commercial use');
      }
    }

    return licenseIssues;
  }
}
