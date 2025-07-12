/*
---------------------------------------------------------------
File name:          dependency_manager_base.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        依赖管理器基类 (Dependency Manager Base)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加依赖冲突检测
    - [ ] 支持语义版本管理
    - [ ] 添加依赖安全扫描
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 依赖管理器基类
///
/// 定义依赖管理的通用接口和基础功能
abstract class DependencyManagerBase {
  /// 创建依赖管理器实例
  const DependencyManagerBase();

  /// 获取依赖类型
  DependencyType get dependencyType;

  /// 获取支持的框架
  List<TemplateFramework> get supportedFrameworks;

  /// 获取依赖列表
  ///
  /// [config] 脚手架配置
  /// 返回依赖映射表
  Map<String, String> getDependencies(ScaffoldConfig config);

  /// 获取开发依赖列表
  ///
  /// [config] 脚手架配置
  /// 返回开发依赖映射表
  Map<String, String> getDevDependencies(ScaffoldConfig config);

  /// 获取依赖覆盖列表
  ///
  /// [config] 脚手架配置
  /// 返回依赖覆盖映射表
  Map<String, String> getDependencyOverrides(ScaffoldConfig config) {
    return {};
  }

  /// 验证依赖兼容性
  ///
  /// [dependencies] 依赖映射表
  /// [config] 脚手架配置
  /// 返回验证结果
  DependencyValidationResult validateDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    final issues = <DependencyIssue>[];

    // 检查依赖冲突
    final conflicts = _checkDependencyConflicts(dependencies);
    issues.addAll(conflicts);

    // 检查版本兼容性
    final versionIssues = _checkVersionCompatibility(dependencies, config);
    issues.addAll(versionIssues);

    // 检查安全问题
    final securityIssues = _checkSecurityIssues(dependencies);
    issues.addAll(securityIssues);

    return DependencyValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }

  /// 解析依赖版本
  ///
  /// [versionConstraint] 版本约束字符串
  /// 返回解析后的版本信息
  DependencyVersion parseVersion(String versionConstraint) {
    // 简单的版本解析实现
    if (versionConstraint.startsWith('^')) {
      return DependencyVersion(
        constraint: versionConstraint,
        type: VersionType.caret,
        version: versionConstraint.substring(1),
      );
    } else if (versionConstraint.startsWith('>=')) {
      return DependencyVersion(
        constraint: versionConstraint,
        type: VersionType.range,
        version: versionConstraint.substring(2).split(' ')[0],
      );
    } else if (versionConstraint == 'any') {
      return DependencyVersion(
        constraint: versionConstraint,
        type: VersionType.any,
        version: 'any',
      );
    } else {
      return DependencyVersion(
        constraint: versionConstraint,
        type: VersionType.exact,
        version: versionConstraint,
      );
    }
  }

  /// 获取推荐版本
  ///
  /// [packageName] 包名
  /// [config] 脚手架配置
  /// 返回推荐版本
  String getRecommendedVersion(String packageName, ScaffoldConfig config) {
    // 这里可以实现从pub.dev或其他源获取最新版本的逻辑
    // 目前返回默认推荐版本
    return _getDefaultRecommendedVersions()[packageName] ?? 'any';
  }

  /// 检查依赖冲突
  List<DependencyIssue> _checkDependencyConflicts(
    Map<String, String> dependencies,
  ) {
    final issues = <DependencyIssue>[];

    // 检查已知的冲突包
    final conflictPairs = _getKnownConflicts();

    for (final conflict in conflictPairs) {
      if (dependencies.containsKey(conflict.package1) &&
          dependencies.containsKey(conflict.package2)) {
        issues.add(
          DependencyIssue(
            type: DependencyIssueType.conflict,
            packageName: conflict.package1,
            message: 'Conflicts with ${conflict.package2}: ${conflict.reason}',
            severity: DependencyIssueSeverity.error,
          ),
        );
      }
    }

    return issues;
  }

  /// 检查版本兼容性
  List<DependencyIssue> _checkVersionCompatibility(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    final issues = <DependencyIssue>[];

    // 检查Flutter SDK版本兼容性
    if (config.framework == TemplateFramework.flutter) {
      for (final entry in dependencies.entries) {
        final compatibility = _checkFlutterCompatibility(
          entry.key,
          entry.value,
          config,
        );
        if (!compatibility.isCompatible) {
          issues.add(
            DependencyIssue(
              type: DependencyIssueType.incompatible,
              packageName: entry.key,
              message: compatibility.reason,
              severity: DependencyIssueSeverity.warning,
            ),
          );
        }
      }
    }

    return issues;
  }

  /// 检查安全问题
  List<DependencyIssue> _checkSecurityIssues(
    Map<String, String> dependencies,
  ) {
    final issues = <DependencyIssue>[];

    // 检查已知的安全问题包
    final vulnerablePackages = _getVulnerablePackages();

    for (final entry in dependencies.entries) {
      if (vulnerablePackages.containsKey(entry.key)) {
        final vulnerability = vulnerablePackages[entry.key]!;
        issues.add(
          DependencyIssue(
            type: DependencyIssueType.security,
            packageName: entry.key,
            message: 'Security vulnerability: ${vulnerability.description}',
            severity: vulnerability.severity,
          ),
        );
      }
    }

    return issues;
  }

  /// 检查Flutter兼容性
  CompatibilityResult _checkFlutterCompatibility(
    String packageName,
    String version,
    ScaffoldConfig config,
  ) {
    // 简化的兼容性检查
    // 实际实现中可以查询pub.dev API
    return const CompatibilityResult(
      isCompatible: true,
      reason: 'Compatible with Flutter latest',
    );
  }

  /// 获取默认推荐版本 (优化后 - 2025年7月)
  Map<String, String> _getDefaultRecommendedVersions() {
    return {
      'flutter': 'sdk: flutter',
      'flutter_test': 'sdk: flutter',
      'flutter_riverpod': '^2.6.1',
      'riverpod_annotation': '^2.6.1',
      'go_router': '^14.8.1',
      'freezed_annotation': '^2.4.4',
      'json_annotation': '^4.8.1',
      'dio': '^5.4.0',
      'shared_preferences': '^2.2.2',
      'flutter_localizations': 'sdk: flutter',
      'intl': '^0.19.0',
      'build_runner': '^2.4.7',
      'freezed': '^2.5.7',
      'json_serializable': '^6.9.0',
      'riverpod_generator': '^2.6.3',
      'mockito': '^5.4.4',
      'flutter_gen': '^5.4.0',
    };
  }

  /// 获取已知冲突
  List<DependencyConflict> _getKnownConflicts() {
    return [
      const DependencyConflict(
        package1: 'provider',
        package2: 'flutter_riverpod',
        reason: 'Both are state management solutions',
      ),
      const DependencyConflict(
        package1: 'bloc',
        package2: 'flutter_riverpod',
        reason: 'Both are state management solutions',
      ),
    ];
  }

  /// 获取有漏洞的包
  Map<String, SecurityVulnerability> _getVulnerablePackages() {
    return {
      // 示例：实际使用中应该从安全数据库获取
      'example_vulnerable_package': const SecurityVulnerability(
        description: 'Known security vulnerability',
        severity: DependencyIssueSeverity.error,
        cveId: 'CVE-2023-XXXX',
      ),
    };
  }
}

/// 依赖类型枚举
enum DependencyType {
  /// 生产依赖
  production,

  /// 开发依赖
  development,

  /// 依赖覆盖
  override,
}

/// 版本类型枚举
enum VersionType {
  /// 精确版本
  exact,

  /// 插入符版本
  caret,

  /// 范围版本
  range,

  /// 任意版本
  any,
}

/// 依赖版本信息
class DependencyVersion {
  /// 创建依赖版本信息实例
  const DependencyVersion({
    required this.constraint,
    required this.type,
    required this.version,
  });

  /// 版本约束
  final String constraint;

  /// 版本类型
  final VersionType type;

  /// 版本号
  final String version;

  @override
  String toString() => constraint;
}

/// 依赖验证结果
class DependencyValidationResult {
  /// 创建依赖验证结果实例
  const DependencyValidationResult({
    required this.isValid,
    required this.issues,
  });

  /// 是否有效
  final bool isValid;

  /// 问题列表
  final List<DependencyIssue> issues;

  /// 获取错误数量
  int get errorCount => issues
      .where((issue) => issue.severity == DependencyIssueSeverity.error)
      .length;

  /// 获取警告数量
  int get warningCount => issues
      .where((issue) => issue.severity == DependencyIssueSeverity.warning)
      .length;
}

/// 依赖问题
class DependencyIssue {
  /// 创建依赖问题实例
  const DependencyIssue({
    required this.type,
    required this.packageName,
    required this.message,
    required this.severity,
  });

  /// 问题类型
  final DependencyIssueType type;

  /// 包名
  final String packageName;

  /// 问题描述
  final String message;

  /// 严重程度
  final DependencyIssueSeverity severity;

  @override
  String toString() => '[$severity] $packageName: $message';
}

/// 依赖问题类型枚举
enum DependencyIssueType {
  /// 冲突
  conflict,

  /// 不兼容
  incompatible,

  /// 安全问题
  security,

  /// 过时
  outdated,
}

/// 依赖问题严重程度枚举
enum DependencyIssueSeverity {
  /// 信息
  info,

  /// 警告
  warning,

  /// 错误
  error,
}

/// 依赖冲突
class DependencyConflict {
  /// 创建依赖冲突实例
  const DependencyConflict({
    required this.package1,
    required this.package2,
    required this.reason,
  });

  /// 第一个包
  final String package1;

  /// 第二个包
  final String package2;

  /// 冲突原因
  final String reason;
}

/// 兼容性结果
class CompatibilityResult {
  /// 创建兼容性结果实例
  const CompatibilityResult({
    required this.isCompatible,
    required this.reason,
  });

  /// 是否兼容
  final bool isCompatible;

  /// 原因
  final String reason;
}

/// 安全漏洞
class SecurityVulnerability {
  /// 创建安全漏洞实例
  const SecurityVulnerability({
    required this.description,
    required this.severity,
    this.cveId,
  });

  /// 描述
  final String description;

  /// 严重程度
  final DependencyIssueSeverity severity;

  /// CVE ID
  final String? cveId;
}
