/*
---------------------------------------------------------------
File name:          dependency_security_checker.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.2 - 依赖安全检查器
                    实现依赖版本检查、漏洞扫描和安全评估
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 依赖安全检查器;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/core/security_system/security_validator.dart';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// 依赖安全级别
enum DependencySecurityLevel {
  safe, // 安全
  low, // 低风险
  medium, // 中风险
  high, // 高风险
  critical, // 严重风险
}

/// 依赖漏洞信息
class DependencyVulnerability {
  const DependencyVulnerability({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.affectedVersions,
    this.fixedVersion,
    this.references = const [],
  });

  /// 漏洞ID
  final String id;

  /// 漏洞标题
  final String title;

  /// 漏洞描述
  final String description;

  /// 安全级别
  final DependencySecurityLevel severity;

  /// 影响的版本范围
  final String affectedVersions;

  /// 修复版本
  final String? fixedVersion;

  /// 参考链接
  final List<String> references;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'severity': severity.name,
        'affectedVersions': affectedVersions,
        'fixedVersion': fixedVersion,
        'references': references,
      };
}

/// 依赖信息
class DependencyInfo {
  const DependencyInfo({
    required this.name,
    required this.currentVersion,
    this.latestVersion,
    this.isDev = false,
    this.securityLevel = DependencySecurityLevel.safe,
    this.vulnerabilities = const [],
    this.license,
    this.isOutdated = false,
  });

  /// 包名
  final String name;

  /// 当前版本
  final String currentVersion;

  /// 最新版本
  final String? latestVersion;

  /// 是否为开发依赖
  final bool isDev;

  /// 安全级别
  final DependencySecurityLevel securityLevel;

  /// 发现的漏洞
  final List<DependencyVulnerability> vulnerabilities;

  /// 许可证
  final String? license;

  /// 是否过时
  final bool isOutdated;

  Map<String, dynamic> toJson() => {
        'name': name,
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'isDev': isDev,
        'securityLevel': securityLevel.name,
        'vulnerabilities': vulnerabilities.map((v) => v.toJson()).toList(),
        'license': license,
        'isOutdated': isOutdated,
      };
}

/// 依赖安全报告
class DependencySecurityReport {
  const DependencySecurityReport({
    required this.scanTime,
    required this.totalDependencies,
    required this.safeDependencies,
    required this.vulnerableDependencies,
    required this.dependencies,
    required this.totalVulnerabilities,
    required this.vulnerabilitiesBySeverity,
  });

  /// 扫描时间
  final DateTime scanTime;

  /// 总依赖数
  final int totalDependencies;

  /// 安全依赖数
  final int safeDependencies;

  /// 有风险的依赖数
  final int vulnerableDependencies;

  /// 依赖详情
  final List<DependencyInfo> dependencies;

  /// 发现的漏洞总数
  final int totalVulnerabilities;

  /// 按严重程度分组的漏洞数
  final Map<DependencySecurityLevel, int> vulnerabilitiesBySeverity;

  Map<String, dynamic> toJson() => {
        'scanTime': scanTime.toIso8601String(),
        'totalDependencies': totalDependencies,
        'safeDependencies': safeDependencies,
        'vulnerableDependencies': vulnerableDependencies,
        'dependencies': dependencies.map((d) => d.toJson()).toList(),
        'totalVulnerabilities': totalVulnerabilities,
        'vulnerabilitiesBySeverity': vulnerabilitiesBySeverity.map(
          (key, value) => MapEntry(key.name, value),
        ),
      };
}

/// 依赖安全检查器
class DependencySecurityChecker {
  factory DependencySecurityChecker() => _instance;
  DependencySecurityChecker._internal();
  static final DependencySecurityChecker _instance =
      DependencySecurityChecker._internal();

  /// 已知漏洞数据库（简化版）
  static final Map<String, List<DependencyVulnerability>>
      _vulnerabilityDatabase = {
    'http': [
      const DependencyVulnerability(
        id: 'CVE-2023-EXAMPLE',
        title: 'HTTP包示例漏洞',
        description: '这是一个示例漏洞，用于演示安全检查功能',
        severity: DependencySecurityLevel.low,
        affectedVersions: '<0.13.0',
        fixedVersion: '0.13.0',
        references: ['https://example.com/advisory'],
      ),
    ],
  };

  /// 不安全的包列表
  static final Set<String> _unsafePackages = {
    'unsafe_package_example',
    'deprecated_package',
  };

  /// 扫描pubspec.yaml文件
  Future<DependencySecurityReport> scanPubspecFile(String pubspecPath) async {
    try {
      Logger.info('开始扫描依赖安全性: $pubspecPath');

      // 读取pubspec.yaml
      final pubspecFile = File(pubspecPath);
      if (!pubspecFile.existsSync()) {
        throw SecurityValidationError(
          message: 'pubspec.yaml文件不存在',
          result: SecurityValidationResult.blocked,
          details: '文件路径: $pubspecPath',
        );
      }

      final content = await pubspecFile.readAsString();
      final pubspec = loadYaml(content) as Map;

      // 解析依赖
      final dependencies = <DependencyInfo>[];

      // 处理普通依赖
      if (pubspec['dependencies'] != null) {
        final deps = pubspec['dependencies'] as Map;
        for (final entry in deps.entries) {
          if (entry.key != 'flutter' && entry.key != 'dart') {
            final depInfo = await _analyzeDependency(
              entry.key.toString(),
              entry.value.toString(),
              false,
            );
            dependencies.add(depInfo);
          }
        }
      }

      // 处理开发依赖
      if (pubspec['dev_dependencies'] != null) {
        final devDeps = pubspec['dev_dependencies'] as Map;
        for (final entry in devDeps.entries) {
          if (entry.key != 'flutter_test') {
            final depInfo = await _analyzeDependency(
              entry.key.toString(),
              entry.value.toString(),
              true,
            );
            dependencies.add(depInfo);
          }
        }
      }

      // 生成报告
      final report = _generateReport(dependencies);

      Logger.info('依赖安全扫描完成: ${dependencies.length}个依赖');
      return report;
    } catch (e) {
      Logger.error('依赖安全扫描失败: $e');
      rethrow;
    }
  }

  /// 分析单个依赖
  Future<DependencyInfo> _analyzeDependency(
      String name, String version, bool isDev,) async {
    // 检查是否为不安全包
    if (_unsafePackages.contains(name)) {
      return DependencyInfo(
        name: name,
        currentVersion: version,
        isDev: isDev,
        securityLevel: DependencySecurityLevel.high,
        vulnerabilities: [
          const DependencyVulnerability(
            id: 'UNSAFE-PACKAGE',
            title: '不安全的包',
            description: '此包被标记为不安全或已弃用',
            severity: DependencySecurityLevel.high,
            affectedVersions: 'all',
          ),
        ],
      );
    }

    // 检查已知漏洞
    final vulnerabilities = _checkVulnerabilities(name, version);

    // 确定安全级别
    final securityLevel = _determineSecurityLevel(vulnerabilities);

    // 检查版本格式
    final isOutdated = _isVersionOutdated(version);

    return DependencyInfo(
      name: name,
      currentVersion: version,
      isDev: isDev,
      securityLevel: securityLevel,
      vulnerabilities: vulnerabilities,
      isOutdated: isOutdated,
    );
  }

  /// 检查漏洞
  List<DependencyVulnerability> _checkVulnerabilities(
      String packageName, String version,) {
    final vulnerabilities = <DependencyVulnerability>[];

    // 检查已知漏洞数据库
    if (_vulnerabilityDatabase.containsKey(packageName)) {
      final packageVulns = _vulnerabilityDatabase[packageName]!;

      for (final vuln in packageVulns) {
        if (_isVersionAffected(version, vuln.affectedVersions)) {
          vulnerabilities.add(vuln);
        }
      }
    }

    return vulnerabilities;
  }

  /// 判断版本是否受影响
  bool _isVersionAffected(String currentVersion, String affectedVersions) {
    // 简化的版本比较逻辑
    // 在实际实现中，应该使用更复杂的版本范围解析

    if (affectedVersions == 'all') return true;

    // 处理 <version 格式
    if (affectedVersions.startsWith('<')) {
      final targetVersion = affectedVersions.substring(1);
      return _compareVersions(currentVersion, targetVersion) < 0;
    }

    // 处理 >=version 格式
    if (affectedVersions.startsWith('>=')) {
      final targetVersion = affectedVersions.substring(2);
      return _compareVersions(currentVersion, targetVersion) >= 0;
    }

    // 处理 =version 格式
    if (affectedVersions.startsWith('=')) {
      final targetVersion = affectedVersions.substring(1);
      return currentVersion == targetVersion;
    }

    return false;
  }

  /// 简化的版本比较
  int _compareVersions(String version1, String version2) {
    // 移除版本约束符号
    version1 = version1.replaceAll(RegExp(r'[^\d\.]'), '');
    version2 = version2.replaceAll(RegExp(r'[^\d\.]'), '');

    final parts1 = version1
        .split('.')
        .map(int.tryParse)
        .where((v) => v != null)
        .cast<int>()
        .toList();
    final parts2 = version2
        .split('.')
        .map(int.tryParse)
        .where((v) => v != null)
        .cast<int>()
        .toList();

    final maxLength =
        parts1.length > parts2.length ? parts1.length : parts2.length;

    for (var i = 0; i < maxLength; i++) {
      final v1 = i < parts1.length ? parts1[i] : 0;
      final v2 = i < parts2.length ? parts2[i] : 0;

      if (v1 < v2) return -1;
      if (v1 > v2) return 1;
    }

    return 0;
  }

  /// 确定安全级别
  DependencySecurityLevel _determineSecurityLevel(
      List<DependencyVulnerability> vulnerabilities,) {
    if (vulnerabilities.isEmpty) return DependencySecurityLevel.safe;

    // 返回最高的安全级别
    var maxLevel = DependencySecurityLevel.safe;
    for (final vuln in vulnerabilities) {
      if (vuln.severity.index > maxLevel.index) {
        maxLevel = vuln.severity;
      }
    }

    return maxLevel;
  }

  /// 检查版本是否过时
  bool _isVersionOutdated(String version) {
    // 简化的过时检查
    // 检查是否使用了宽泛的版本约束
    return version.contains('^') || version.contains('>=') || version == 'any';
  }

  /// 生成安全报告
  DependencySecurityReport _generateReport(List<DependencyInfo> dependencies) {
    final totalDependencies = dependencies.length;
    final safeDependencies = dependencies
        .where((d) => d.securityLevel == DependencySecurityLevel.safe)
        .length;
    final vulnerableDependencies = totalDependencies - safeDependencies;

    final allVulnerabilities =
        dependencies.expand((d) => d.vulnerabilities).toList();
    final totalVulnerabilities = allVulnerabilities.length;

    final vulnerabilitiesBySeverity = <DependencySecurityLevel, int>{};
    for (final vuln in allVulnerabilities) {
      vulnerabilitiesBySeverity[vuln.severity] =
          (vulnerabilitiesBySeverity[vuln.severity] ?? 0) + 1;
    }

    return DependencySecurityReport(
      scanTime: DateTime.now(),
      totalDependencies: totalDependencies,
      safeDependencies: safeDependencies,
      vulnerableDependencies: vulnerableDependencies,
      dependencies: dependencies,
      totalVulnerabilities: totalVulnerabilities,
      vulnerabilitiesBySeverity: vulnerabilitiesBySeverity,
    );
  }

  /// 扫描项目目录
  Future<DependencySecurityReport> scanProject(String projectPath) async {
    final pubspecPath = path.join(projectPath, 'pubspec.yaml');
    return scanPubspecFile(pubspecPath);
  }

  /// 生成安全建议
  List<String> generateSecurityRecommendations(
      DependencySecurityReport report,) {
    final recommendations = <String>[];

    // 检查高风险依赖
    final highRiskDeps = report.dependencies
        .where(
          (d) =>
              d.securityLevel == DependencySecurityLevel.high ||
              d.securityLevel == DependencySecurityLevel.critical,
        )
        .toList();

    if (highRiskDeps.isNotEmpty) {
      recommendations.add('立即更新或移除以下高风险依赖:');
      for (final dep in highRiskDeps) {
        recommendations.add('  - ${dep.name}: ${dep.currentVersion}');
        for (final vuln in dep.vulnerabilities) {
          if (vuln.fixedVersion != null) {
            recommendations.add('    建议升级到: ${vuln.fixedVersion}');
          }
        }
      }
    }

    // 检查过时依赖
    final outdatedDeps =
        report.dependencies.where((d) => d.isOutdated).toList();
    if (outdatedDeps.isNotEmpty) {
      recommendations.add('考虑更新以下使用宽泛版本约束的依赖:');
      for (final dep in outdatedDeps) {
        recommendations.add('  - ${dep.name}: ${dep.currentVersion}');
      }
    }

    // 总体建议
    if (report.vulnerableDependencies > 0) {
      recommendations.add('定期运行依赖安全扫描');
      recommendations.add('订阅安全公告以及时了解漏洞信息');
      recommendations.add('使用依赖锁定文件固定版本');
    }

    if (recommendations.isEmpty) {
      recommendations.add('所有依赖都是安全的，继续保持良好的安全实践！');
    }

    return recommendations;
  }

  /// 导出安全报告
  Future<void> exportReport(
      DependencySecurityReport report, String outputPath,) async {
    try {
      final reportJson = jsonEncode(report.toJson());
      final file = File(outputPath);
      await file.writeAsString(reportJson);

      Logger.info('依赖安全报告已导出: $outputPath');
    } catch (e) {
      Logger.error('导出安全报告失败: $e');
      rethrow;
    }
  }
}
