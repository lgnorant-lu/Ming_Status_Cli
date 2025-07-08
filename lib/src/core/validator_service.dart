/*
---------------------------------------------------------------
File name:          validator_service.dart
Author:             Ignorant-lu
Date created:       2025/07/03
Last modified:      2025/07/03
Dart Version:       3.32.4
Description:        核心验证服务 - 验证系统的核心编排器
---------------------------------------------------------------
Change History:
    2025/07/03: Initial creation - 核心验证服务实现;
---------------------------------------------------------------
*/

import 'dart:async';

import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:path/path.dart' as path;

/// 模块验证器接口
abstract class ModuleValidator {
  /// 验证器名称
  String get validatorName;

  /// 支持的验证类型
  List<ValidationType> get supportedTypes;

  /// 验证器优先级 (数字越小优先级越高)
  int get priority => 50;

  /// 是否启用验证器
  bool get isEnabled => true;

  /// 验证模块
  Future<ValidationResult> validate(
    String modulePath,
    ValidationContext context,
  );

  /// 验证器健康检查
  Future<bool> healthCheck() async => true;

  /// 获取验证器信息
  Map<String, dynamic> getValidatorInfo() => {
        'name': validatorName,
        'supportedTypes': supportedTypes.map((t) => t.name).toList(),
        'priority': priority,
        'enabled': isEnabled,
      };
}

/// 验证级别
enum ValidationLevel {
  /// 基础验证
  basic,

  /// 标准验证
  standard,

  /// 严格验证
  strict,

  /// 企业级验证
  enterprise,
}

/// 验证配置
class ValidationConfig {
  /// 创建验证配置实例
  const ValidationConfig({
    this.level = ValidationLevel.standard,
    this.enabledValidators = const [],
    this.customRules = const {},
    this.outputFormat = OutputFormat.console,
    this.enableCache = true,
    this.parallelExecution = true,
    this.timeoutSeconds = 300,
  });

  /// 验证级别
  final ValidationLevel level;

  /// 启用的验证器
  final List<ValidationType> enabledValidators;

  /// 自定义规则
  final Map<String, dynamic> customRules;

  /// 输出格式
  final OutputFormat outputFormat;

  /// 启用缓存
  final bool enableCache;

  /// 并行执行
  final bool parallelExecution;

  /// 超时时间(秒)
  final int timeoutSeconds;
}

/// 验证统计信息
class ValidationStats {
  /// 创建验证统计实例
  const ValidationStats({
    required this.totalValidators,
    required this.executedValidators,
    required this.skippedValidators,
    required this.failedValidators,
    required this.totalDurationMs,
    required this.cacheHits,
    required this.cacheMisses,
  });

  /// 总验证器数量
  final int totalValidators;

  /// 已执行验证器数量
  final int executedValidators;

  /// 跳过的验证器数量
  final int skippedValidators;

  /// 失败的验证器数量
  final int failedValidators;

  /// 总耗时(毫秒)
  final int totalDurationMs;

  /// 缓存命中次数
  final int cacheHits;

  /// 缓存未命中次数
  final int cacheMisses;

  /// 缓存命中率
  double get cacheHitRate {
    final total = cacheHits + cacheMisses;
    return total > 0 ? cacheHits / total : 0.0;
  }
}

/// 核心验证服务
class ValidatorService {
  /// 创建验证服务实例
  ValidatorService({
    this.config = const ValidationConfig(),
  });

  /// 验证配置
  final ValidationConfig config;

  /// 注册的验证器
  final List<ModuleValidator> _validators = [];

  /// 验证缓存
  final Map<String, ValidationResult> _cache = {};

  /// 缓存时间戳
  final Map<String, DateTime> _cacheTimestamps = {};

  /// 缓存过期时间 (默认30分钟)
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// 验证统计
  ValidationStats? _lastStats;

  /// 注册验证器
  void registerValidator(ModuleValidator validator) {
    _validators
      ..add(validator)
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// 注册多个验证器
  void registerValidators(List<ModuleValidator> validators) {
    for (final validator in validators) {
      registerValidator(validator);
    }
  }

  /// 获取已注册的验证器
  List<ModuleValidator> get registeredValidators =>
      List.unmodifiable(_validators);

  /// 获取启用的验证器
  List<ModuleValidator> get enabledValidators =>
      _validators.where((v) => v.isEnabled).toList();

  /// 验证模块
  Future<ValidationResult> validateModule(
    String modulePath, {
    ValidationContext? context,
    bool useCache = true,
  }) async {
    // 创建默认上下文
    context ??= ValidationContext(
      projectPath: modulePath,
      strictMode: config.level == ValidationLevel.strict ||
          config.level == ValidationLevel.enterprise,
      outputFormat: config.outputFormat,
      enabledValidators: config.enabledValidators,
    );

    // 检查缓存
    final cacheKey = _generateCacheKey(modulePath, context);
    if (useCache && config.enableCache && _cache.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiry) {
        // 缓存有效，返回缓存结果
        return _cache[cacheKey]!;
      } else {
        // 缓存过期，清除过期缓存
        _cache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    // 执行验证
    final result = await _executeValidation(modulePath, context);

    // 更新缓存
    if (config.enableCache) {
      _cache[cacheKey] = result;
      _cacheTimestamps[cacheKey] = DateTime.now();
    }

    return result;
  }

  /// 批量验证模块
  Future<Map<String, ValidationResult>> validateMultipleModules(
    List<String> modulePaths, {
    ValidationContext? context,
    bool useCache = true,
  }) async {
    final results = <String, ValidationResult>{};

    if (config.parallelExecution) {
      // 并行执行
      final futures = modulePaths.map(
        (path) => validateModule(
          path,
          context: context,
          useCache: useCache,
        ),
      );
      final validationResults = await Future.wait(futures);

      for (var i = 0; i < modulePaths.length; i++) {
        results[modulePaths[i]] = validationResults[i];
      }
    } else {
      // 串行执行
      for (final path in modulePaths) {
        results[path] = await validateModule(
          path,
          context: context,
          useCache: useCache,
        );
      }
    }

    return results;
  }

  /// 执行验证
  Future<ValidationResult> _executeValidation(
    String modulePath,
    ValidationContext context,
  ) async {
    final aggregatedResult = ValidationResult(strictMode: context.strictMode);
    final startTime = DateTime.now();

    var executedCount = 0;
    const skippedCount = 0;
    var failedCount = 0;
    const cacheHits = 0;
    const cacheMisses = 0;

    // 获取要执行的验证器
    final validatorsToRun = _getValidatorsToRun(context);

    try {
      if (config.parallelExecution && validatorsToRun.length > 1) {
        // 并行执行验证器
        final futures = validatorsToRun.map(
          (validator) => _runSingleValidator(validator, modulePath, context),
        );

        final results = await Future.wait(
          futures,
        ).timeout(Duration(seconds: config.timeoutSeconds));

        // 聚合结果
        for (var i = 0; i < results.length; i++) {
          final result = results[i];
          final validator = validatorsToRun[i];

          if (result != null) {
            _mergeResults(aggregatedResult, result, validator.validatorName);
            executedCount++;
          } else {
            failedCount++;
            aggregatedResult.addError(
              '验证器 ${validator.validatorName} 执行失败',
              validatorName: validator.validatorName,
            );
          }
        }
      } else {
        // 串行执行验证器
        for (final validator in validatorsToRun) {
          try {
            final result = await _runSingleValidator(
              validator,
              modulePath,
              context,
            ).timeout(
              Duration(
                seconds: config.timeoutSeconds ~/ validatorsToRun.length,
              ),
            );

            if (result != null) {
              _mergeResults(aggregatedResult, result, validator.validatorName);
              executedCount++;
            } else {
              failedCount++;
              aggregatedResult.addError(
                '验证器 ${validator.validatorName} 执行失败',
                validatorName: validator.validatorName,
              );
            }
          } catch (e) {
            failedCount++;
            aggregatedResult.addError(
              '验证器 ${validator.validatorName} 执行异常: $e',
              validatorName: validator.validatorName,
            );
          }
        }
      }
    } catch (e) {
      aggregatedResult.addError(
        '验证过程发生异常: $e',
      );
    }

    // 标记完成
    aggregatedResult.markCompleted();

    // 更新统计信息
    final endTime = DateTime.now();
    _lastStats = ValidationStats(
      totalValidators: _validators.length,
      executedValidators: executedCount,
      skippedValidators: skippedCount,
      failedValidators: failedCount,
      totalDurationMs: endTime.difference(startTime).inMilliseconds,
      cacheHits: cacheHits,
      cacheMisses: cacheMisses,
    );

    return aggregatedResult;
  }

  /// 运行单个验证器
  Future<ValidationResult?> _runSingleValidator(
    ModuleValidator validator,
    String modulePath,
    ValidationContext context,
  ) async {
    try {
      // 健康检查
      if (!await validator.healthCheck()) {
        return null;
      }

      // 执行验证
      return await validator.validate(modulePath, context);
    } catch (e) {
      // 验证器执行失败
      final result = ValidationResult(strictMode: context.strictMode)
        ..addError(
          '验证器 ${validator.validatorName} 执行异常: $e',
          validatorName: validator.validatorName,
        );
      return result;
    }
  }

  /// 获取要执行的验证器
  List<ModuleValidator> _getValidatorsToRun(ValidationContext context) {
    var validators = enabledValidators;

    // 按配置过滤验证器
    if (context.enabledValidators.isNotEmpty) {
      validators = validators
          .where(
            (v) => v.supportedTypes
                .any((type) => context.enabledValidators.contains(type)),
          )
          .toList();
    }

    // 按验证级别过滤
    switch (config.level) {
      case ValidationLevel.basic:
        validators = validators
            .where(
              (v) => v.supportedTypes.contains(ValidationType.structure),
            )
            .toList();
      case ValidationLevel.standard:
        validators = validators
            .where(
              (v) => v.supportedTypes.any(
                (type) => [
                  ValidationType.structure,
                  ValidationType.quality,
                  ValidationType.dependency,
                  ValidationType.compliance,
                ].contains(type),
              ),
            )
            .toList();
      case ValidationLevel.strict:
      case ValidationLevel.enterprise:
        // 包含所有验证器
        break;
    }

    return validators;
  }

  /// 合并验证结果
  void _mergeResults(
    ValidationResult target,
    ValidationResult source,
    String validatorName,
  ) {
    for (final message in source.messages) {
      // 创建新消息，确保验证器名称正确
      final newMessage = ValidationMessage(
        severity: message.severity,
        message: message.message,
        code: message.code,
        file: message.file,
        line: message.line,
        validationType: message.validationType,
        fixSuggestion: message.fixSuggestion,
        validatorName: validatorName,
      );

      target.messages.add(newMessage);
    }
  }

  /// 生成缓存键
  String _generateCacheKey(String modulePath, ValidationContext context) {
    // 使用更智能的缓存键生成策略
    final normalizedPath = path.normalize(modulePath);
    final pathHash = normalizedPath.hashCode;
    final contextHash = context.hashCode;

    // 包含验证级别和启用的验证器信息
    final levelHash = context.strictMode.hashCode;
    final validatorsHash =
        context.enabledValidators.map((v) => v.toString()).join(',').hashCode;

    return '${pathHash}_${contextHash}_${levelHash}_$validatorsHash';
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// 清除过期缓存
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) >= _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// 获取缓存统计
  Map<String, int> getCacheStats() {
    return {
      'totalEntries': _cache.length,
      'hits': _lastStats?.cacheHits ?? 0,
      'misses': _lastStats?.cacheMisses ?? 0,
    };
  }

  /// 获取最新验证统计
  ValidationStats? get lastValidationStats => _lastStats;

  /// 健康检查所有验证器
  Future<Map<String, bool>> checkValidatorsHealth() async {
    final healthStatus = <String, bool>{};

    for (final validator in _validators) {
      try {
        healthStatus[validator.validatorName] = await validator.healthCheck();
      } catch (e) {
        healthStatus[validator.validatorName] = false;
      }
    }

    return healthStatus;
  }

  /// 获取验证器信息
  List<Map<String, dynamic>> getValidatorsInfo() {
    return _validators.map((v) => v.getValidatorInfo()).toList();
  }
}
