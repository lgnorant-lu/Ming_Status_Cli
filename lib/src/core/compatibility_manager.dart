/*
---------------------------------------------------------------
File name:          compatibility_manager.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 52.3 - 向后兼容性管理器
                    确保新版本与旧版本的兼容性
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 向后兼容性管理器;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart';

/// 兼容性级别
enum CompatibilityLevel {
  full, // 完全兼容
  partial, // 部分兼容
  deprecated, // 已弃用但兼容
  breaking, // 破坏性变更
}

/// 兼容性检查结果
class CompatibilityResult {
  const CompatibilityResult({
    required this.level,
    required this.passed,
    this.messages = const [],
    this.migrationSuggestions = const [],
    this.affectedFeatures = const [],
  });

  /// 兼容性级别
  final CompatibilityLevel level;

  /// 检查是否通过
  final bool passed;

  /// 兼容性消息
  final List<String> messages;

  /// 迁移建议
  final List<String> migrationSuggestions;

  /// 受影响的功能
  final List<String> affectedFeatures;
}

/// 版本兼容性规则
class CompatibilityRule {
  const CompatibilityRule({
    required this.id,
    required this.name,
    required this.versionRange,
    required this.level,
    required this.checker,
    required this.description,
    this.migrator,
  });

  /// 规则ID
  final String id;

  /// 规则名称
  final String name;

  /// 适用的版本范围
  final String versionRange;

  /// 兼容性级别
  final CompatibilityLevel level;

  /// 检查函数
  final Future<bool> Function(Map<String, dynamic> context) checker;

  /// 迁移函数
  final Future<void> Function(Map<String, dynamic> context)? migrator;

  /// 规则描述
  final String description;
}

/// 向后兼容性管理器
class CompatibilityManager {
  factory CompatibilityManager() => _instance;
  CompatibilityManager._internal();
  static final CompatibilityManager _instance =
      CompatibilityManager._internal();

  /// 兼容性规则
  final List<CompatibilityRule> _rules = [];

  /// 已知的破坏性变更
  final Map<String, List<String>> _breakingChanges = {};

  /// 弃用的功能
  final Map<String, DeprecationInfo> _deprecatedFeatures = {};

  /// 迁移脚本
  final Map<String, MigrationScript> _migrationScripts = {};

  /// 初始化兼容性管理器
  void initialize() {
    Logger.info('初始化向后兼容性管理器...');

    // 注册内置兼容性规则
    _registerBuiltinRules();

    // 加载破坏性变更信息
    _loadBreakingChanges();

    // 加载弃用功能信息
    _loadDeprecatedFeatures();

    // 加载迁移脚本
    _loadMigrationScripts();

    Logger.info('向后兼容性管理器初始化完成');
  }

  /// 检查版本兼容性
  Future<CompatibilityResult> checkCompatibility(
    String fromVersion,
    String toVersion,
    Map<String, dynamic> context,
  ) async {
    Logger.info('检查版本兼容性: $fromVersion -> $toVersion');

    final messages = <String>[];
    final migrationSuggestions = <String>[];
    final affectedFeatures = <String>[];
    var overallLevel = CompatibilityLevel.full;
    var passed = true;

    // 检查破坏性变更
    final breakingChanges = _getBreakingChanges(fromVersion, toVersion);
    if (breakingChanges.isNotEmpty) {
      overallLevel = CompatibilityLevel.breaking;
      passed = false;
      messages.addAll(breakingChanges.map((change) => '破坏性变更: $change'));
      affectedFeatures.addAll(breakingChanges);
    }

    // 检查弃用功能
    final deprecations = _getDeprecations(fromVersion, toVersion);
    if (deprecations.isNotEmpty) {
      if (overallLevel == CompatibilityLevel.full) {
        overallLevel = CompatibilityLevel.deprecated;
      }
      messages.addAll(deprecations.map((dep) => '功能已弃用: ${dep.feature}'));
      migrationSuggestions
          .addAll(deprecations.map((dep) => dep.migrationAdvice));
      affectedFeatures.addAll(deprecations.map((dep) => dep.feature));
    }

    // 运行兼容性规则检查
    for (final rule in _rules) {
      if (_isVersionInRange(toVersion, rule.versionRange)) {
        try {
          final ruleResult = await rule.checker(context);
          if (!ruleResult) {
            passed = false;
            messages.add('兼容性规则失败: ${rule.name}');

            if (rule.level.index > overallLevel.index) {
              overallLevel = rule.level;
            }

            if (rule.migrator != null) {
              migrationSuggestions.add('运行迁移: ${rule.description}');
            }
          }
        } catch (e) {
          Logger.error('兼容性规则检查失败: ${rule.id} - $e');
          messages.add('兼容性检查错误: ${rule.name}');
        }
      }
    }

    return CompatibilityResult(
      level: overallLevel,
      passed: passed,
      messages: messages,
      migrationSuggestions: migrationSuggestions,
      affectedFeatures: affectedFeatures,
    );
  }

  /// 执行迁移
  Future<MigrationResult> migrate(
    String fromVersion,
    String toVersion,
    Map<String, dynamic> context,
  ) async {
    Logger.info('执行版本迁移: $fromVersion -> $toVersion');

    final results = <String, bool>{};
    final errors = <String>[];

    // 查找适用的迁移脚本
    final applicableScripts =
        _findApplicableMigrationScripts(fromVersion, toVersion);

    for (final script in applicableScripts) {
      try {
        Logger.info('执行迁移脚本: ${script.name}');
        await script.execute(context);
        results[script.id] = true;
        Logger.info('迁移脚本执行成功: ${script.name}');
      } catch (e) {
        Logger.error('迁移脚本执行失败: ${script.name} - $e');
        results[script.id] = false;
        errors.add('${script.name}: $e');
      }
    }

    final success = errors.isEmpty;

    return MigrationResult(
      success: success,
      fromVersion: fromVersion,
      toVersion: toVersion,
      executedScripts: results,
      errors: errors,
    );
  }

  /// 注册兼容性规则
  void registerRule(CompatibilityRule rule) {
    _rules.add(rule);
    Logger.debug('注册兼容性规则: ${rule.name}');
  }

  /// 注册迁移脚本
  void registerMigrationScript(MigrationScript script) {
    _migrationScripts[script.id] = script;
    Logger.debug('注册迁移脚本: ${script.name}');
  }

  /// 标记功能为弃用
  void deprecateFeature(String feature, DeprecationInfo info) {
    _deprecatedFeatures[feature] = info;
    Logger.info('功能已标记为弃用: $feature');
  }

  /// 检查功能是否已弃用
  bool isFeatureDeprecated(String feature) {
    return _deprecatedFeatures.containsKey(feature);
  }

  /// 获取弃用信息
  DeprecationInfo? getDeprecationInfo(String feature) {
    return _deprecatedFeatures[feature];
  }

  /// 获取所有弃用功能
  Map<String, DeprecationInfo> getAllDeprecatedFeatures() {
    return Map.from(_deprecatedFeatures);
  }

  /// 获取兼容性报告
  CompatibilityReport generateReport(String version) {
    final deprecatedFeatures = _deprecatedFeatures.entries
        .where(
          (entry) =>
              _isVersionInRange(version, entry.value.deprecatedInVersion),
        )
        .map((entry) => entry.key)
        .toList();

    final breakingChanges = _breakingChanges[version] ?? [];

    final availableMigrations = _migrationScripts.values
        .where(
          (script) => _isVersionInRange(version, script.targetVersionRange),
        )
        .map((script) => script.name)
        .toList();

    return CompatibilityReport(
      version: version,
      deprecatedFeatures: deprecatedFeatures,
      breakingChanges: breakingChanges,
      availableMigrations: availableMigrations,
      compatibilityRules: _rules.length,
    );
  }

  /// 注册内置兼容性规则
  void _registerBuiltinRules() {
    // Phase 1 -> Phase 2 兼容性规则
    registerRule(
      CompatibilityRule(
        id: 'config_format_v1_to_v2',
        name: '配置文件格式兼容性',
        versionRange: '>=2.0.0',
        level: CompatibilityLevel.partial,
        description: '检查配置文件格式是否需要升级',
        checker: (context) async {
          // 检查配置文件格式
          final configPath = context['configPath'] as String?;
          if (configPath == null) return true;

          final configFile = File(configPath);
          if (!configFile.existsSync()) return true;

          try {
            final content = await configFile.readAsString();
            final config = jsonDecode(content);

            // 检查是否包含v2格式的字段
            final version = config['version'];
            return version != null &&
                version is String &&
                version.compareTo('2.0.0') >= 0;
          } catch (e) {
            return false;
          }
        },
      ),
    );

    registerRule(
      CompatibilityRule(
        id: 'template_engine_v1_to_v2',
        name: '模板引擎兼容性',
        versionRange: '>=2.0.0',
        level: CompatibilityLevel.deprecated,
        description: '检查模板引擎API使用',
        checker: (context) async {
          // 检查是否使用了旧的模板API
          // 这里是预留接口，Phase 2实现
          return true;
        },
      ),
    );
  }

  /// 加载破坏性变更信息
  void _loadBreakingChanges() {
    // Phase 1 -> Phase 2 的破坏性变更
    _breakingChanges['2.0.0'] = [
      '模板引擎API重构',
      '配置文件格式变更',
      '验证器接口更新',
    ];

    // 未来版本的破坏性变更
    _breakingChanges['3.0.0'] = [
      'CLI命令结构重组',
      '插件系统重构',
      '配置系统升级',
    ];
  }

  /// 加载弃用功能信息
  void _loadDeprecatedFeatures() {
    // Phase 1 中将在 Phase 2 弃用的功能
    deprecateFeature(
      'basic_template_engine',
      const DeprecationInfo(
        feature: 'basic_template_engine',
        deprecatedInVersion: '2.0.0',
        removedInVersion: '3.0.0',
        reason: '被高级模板系统替代',
        migrationAdvice: '使用新的高级模板API',
      ),
    );

    deprecateFeature(
      'simple_validator',
      const DeprecationInfo(
        feature: 'simple_validator',
        deprecatedInVersion: '2.1.0',
        removedInVersion: '3.0.0',
        reason: '被企业级验证器替代',
        migrationAdvice: '迁移到新的验证器框架',
      ),
    );
  }

  /// 加载迁移脚本
  void _loadMigrationScripts() {
    // v1 -> v2 配置迁移
    registerMigrationScript(
      MigrationScript(
        id: 'config_v1_to_v2',
        name: '配置文件v1到v2迁移',
        fromVersion: '1.x.x',
        toVersion: '2.x.x',
        targetVersionRange: '>=2.0.0',
        description: '将v1配置文件格式升级到v2',
        execute: (context) async {
          final configPath = context['configPath'] as String?;
          if (configPath == null) return;

          final configFile = File(configPath);
          if (!configFile.existsSync()) return;

          // 读取v1配置
          final content = await configFile.readAsString();
          final v1Config = jsonDecode(content);

          // 转换为v2格式
          final v2Config = <String, dynamic>{
            'version': '2.0.0',
            'migrated_from': '1.x.x',
            'migration_date': DateTime.now().toIso8601String(),
          };

          // 合并v1配置
          if (v1Config is Map<String, dynamic>) {
            v2Config.addAll(v1Config);
          }

          // 备份原配置
          final backupPath = '$configPath.v1.backup';
          await configFile.copy(backupPath);

          // 写入v2配置
          await configFile.writeAsString(
            const JsonEncoder.withIndent('  ').convert(v2Config),
          );

          Logger.info('配置文件已迁移到v2格式，原文件备份为: $backupPath');
        },
      ),
    );
  }

  /// 获取破坏性变更
  List<String> _getBreakingChanges(String fromVersion, String toVersion) {
    final changes = <String>[];

    for (final entry in _breakingChanges.entries) {
      final version = entry.key;
      if (_isVersionBetween(version, fromVersion, toVersion)) {
        changes.addAll(entry.value);
      }
    }

    return changes;
  }

  /// 获取弃用功能
  List<DeprecationInfo> _getDeprecations(String fromVersion, String toVersion) {
    return _deprecatedFeatures.values
        .where(
          (dep) => _isVersionBetween(
              dep.deprecatedInVersion, fromVersion, toVersion),
        )
        .toList();
  }

  /// 查找适用的迁移脚本
  List<MigrationScript> _findApplicableMigrationScripts(
    String fromVersion,
    String toVersion,
  ) {
    return _migrationScripts.values
        .where(
          (script) =>
              _isVersionInRange(fromVersion, script.fromVersion) &&
              _isVersionInRange(toVersion, script.toVersion),
        )
        .toList();
  }

  /// 检查版本是否在范围内
  bool _isVersionInRange(String version, String range) {
    // 简化的版本范围检查，Phase 2 实现完整的语义化版本检查
    return true;
  }

  /// 检查版本是否在两个版本之间
  bool _isVersionBetween(String version, String fromVersion, String toVersion) {
    // 简化的版本比较，Phase 2 实现完整的语义化版本比较
    return true;
  }
}

/// 弃用信息
class DeprecationInfo {
  const DeprecationInfo({
    required this.feature,
    required this.deprecatedInVersion,
    required this.removedInVersion,
    required this.reason,
    required this.migrationAdvice,
  });

  /// 弃用的功能
  final String feature;

  /// 弃用版本
  final String deprecatedInVersion;

  /// 移除版本
  final String removedInVersion;

  /// 弃用原因
  final String reason;

  /// 迁移建议
  final String migrationAdvice;
}

/// 迁移脚本
class MigrationScript {
  const MigrationScript({
    required this.id,
    required this.name,
    required this.fromVersion,
    required this.toVersion,
    required this.targetVersionRange,
    required this.description,
    required this.execute,
  });

  /// 脚本ID
  final String id;

  /// 脚本名称
  final String name;

  /// 源版本
  final String fromVersion;

  /// 目标版本
  final String toVersion;

  /// 目标版本范围
  final String targetVersionRange;

  /// 脚本描述
  final String description;

  /// 执行函数
  final Future<void> Function(Map<String, dynamic> context) execute;
}

/// 迁移结果
class MigrationResult {
  const MigrationResult({
    required this.success,
    required this.fromVersion,
    required this.toVersion,
    required this.executedScripts,
    this.errors = const [],
  });

  /// 迁移是否成功
  final bool success;

  /// 源版本
  final String fromVersion;

  /// 目标版本
  final String toVersion;

  /// 执行的脚本结果
  final Map<String, bool> executedScripts;

  /// 错误信息
  final List<String> errors;
}

/// 兼容性报告
class CompatibilityReport {
  const CompatibilityReport({
    required this.version,
    required this.deprecatedFeatures,
    required this.breakingChanges,
    required this.availableMigrations,
    required this.compatibilityRules,
  });

  /// 版本
  final String version;

  /// 弃用功能
  final List<String> deprecatedFeatures;

  /// 破坏性变更
  final List<String> breakingChanges;

  /// 可用迁移
  final List<String> availableMigrations;

  /// 兼容性规则数量
  final int compatibilityRules;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'deprecatedFeatures': deprecatedFeatures,
      'breakingChanges': breakingChanges,
      'availableMigrations': availableMigrations,
      'compatibilityRules': compatibilityRules,
    };
  }
}
