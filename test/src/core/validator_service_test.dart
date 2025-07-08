/*
---------------------------------------------------------------
File name:          validator_service_test.dart
Author:             Ignorant-lu
Date created:       2025/07/04
Last modified:      2025/07/04
Dart Version:       3.32.4
Description:        ValidatorService核心服务测试套件 - Task 44.1
---------------------------------------------------------------
Change History:
    2025/07/04: Initial creation - 核心验证服务测试套件实现;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/core/validator_service.dart';
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:test/test.dart';

void main() {
  group('ValidatorService Core Tests', () {
    late ValidatorService service;
    late Directory tempDir;

    setUpAll(() async {
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('validator_test_');
    });

    setUp(() {
      service = ValidatorService();
    });

    tearDownAll(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Service Initialization', () {
      test('should create service instance successfully', () {
        expect(service, isNotNull);
        expect(service.registeredValidators, isEmpty);
      });

      test('should handle default configuration', () {
        const config = ValidationConfig(level: ValidationLevel.basic);
        expect(config.level, equals(ValidationLevel.basic));
        expect(config.enabledValidators, isEmpty);
        expect(config.enableCache, isTrue);
        expect(config.parallelExecution, isTrue);
        expect(config.timeoutSeconds, equals(300));
      });
    });

    group('Validator Registration', () {
      test('should register validator successfully', () {
        final validator = MockValidator('test');
        
        service.registerValidator(validator);
        
        expect(service.registeredValidators, hasLength(1));
        expect(
          service.registeredValidators.first.validatorName, equals('test'),
        );
      });

      test('should register multiple validators with priority order', () {
        final validator1 = MockValidator('high-priority', priority: 1);
        final validator2 = MockValidator('low-priority', priority: 10);
        final validator3 = MockValidator('medium-priority',);
        
        service
          ..registerValidator(validator2)
          ..registerValidator(validator1)
          ..registerValidator(validator3);
        
        expect(service.registeredValidators, hasLength(3));
        // 验证优先级排序
        expect(
          service.registeredValidators[0].validatorName,
          equals('high-priority'),
        );
        expect(
          service.registeredValidators[1].validatorName,
          equals('medium-priority'),
        );
        expect(
          service.registeredValidators[2].validatorName,
          equals('low-priority'),
        );
      });
    });

    group('Health Check System', () {
      test('should perform health check on empty service', () async {
        final result = await service.checkValidatorsHealth();
        
        expect(result, isA<Map<String, bool>>());
        expect(result, isEmpty);
      });

      test('should perform health check on registered validators', () async {
        final healthyValidator = MockValidator('healthy',);
        final unhealthyValidator = MockValidator('unhealthy', isHealthy: false);
        
        service
          ..registerValidator(healthyValidator)
          ..registerValidator(unhealthyValidator);
        
        final result = await service.checkValidatorsHealth();
        
        expect(result, hasLength(2));
        expect(result['healthy'], isTrue);
        expect(result['unhealthy'], isFalse);
      });

      test('should handle health check timeout', () async {
        final slowValidator = MockValidator(
          'slow', 
          healthCheckDelay: const Duration(seconds: 2),
        );
        
        service.registerValidator(slowValidator);
        
        final result = await service.checkValidatorsHealth();
        
        // 健康检查应该正常完成
        expect(result.containsKey('slow'), isTrue);
      });
    });

    group('Module Validation', () {
      test('should validate module with no validators', () async {
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await service.validateModule(
          tempDir.path,
          context: context,
        );
        
        expect(result.isValid, isTrue);
        expect(result.messages, isEmpty);
        expect(result.getSummary().errorCount, equals(0));
      });

      test('should validate module with successful validators', () async {
        final validator1 = MockValidator('success1',);
        final validator2 = MockValidator('success2',);
        
        service
          ..registerValidator(validator1)
          ..registerValidator(validator2);
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await service.validateModule(
          tempDir.path,
          context: context,
        );
        
        expect(result.isValid, isTrue);
        expect(result.messages, hasLength(2));
        expect(result.getMessagesByValidator('success1'), hasLength(1));
        expect(result.getMessagesByValidator('success2'), hasLength(1));
      });

      test('should handle failing validators', () async {
        final failingValidator = MockValidator('failing', shouldSucceed: false);
        
        service.registerValidator(failingValidator);
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await service.validateModule(
          tempDir.path,
          context: context,
        );
        
        expect(result.isValid, isFalse);
        expect(result.messages, hasLength(1));
        expect(
          result.messages.first.severity, equals(ValidationSeverity.error),
        );
        expect(result.messages.first.validatorName, equals('failing'));
      });

      test('should handle validator exceptions gracefully', () async {
        final throwingValidator = MockValidator('throwing', shouldThrow: true);
        
        service.registerValidator(throwingValidator);
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await service.validateModule(
          tempDir.path,
          context: context,
        );
        
        expect(result.isValid, isFalse);
        expect(result.messages, hasLength(1));
        expect(
          result.messages.first.severity, equals(ValidationSeverity.error),
        );
        expect(result.messages.first.message, contains('执行异常'));
      });
    });

    group('Parallel vs Sequential Execution', () {
      test('should execute validators in parallel when enabled', () async {
        final validator1 = MockValidator('parallel1', 
          executionDelay: const Duration(milliseconds: 100),
        );
        final validator2 = MockValidator('parallel2', 
          executionDelay: const Duration(milliseconds: 100),
        );
        final validator3 = MockValidator('parallel3', 
          executionDelay: const Duration(milliseconds: 100),
        );
        
        service
          ..registerValidator(validator1)
          ..registerValidator(validator2)
          ..registerValidator(validator3);
        
        const config = ValidationConfig(
          level: ValidationLevel.basic,
        );
        final parallelService = ValidatorService(config: config)
          ..registerValidators([validator1, validator2, validator3]);
        
        final stopwatch = Stopwatch()..start();
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await parallelService.validateModule(
          tempDir.path,
          context: context,
        );
        stopwatch.stop();
        
        // 并行执行应该大约是100ms，而不是300ms
        expect(stopwatch.elapsedMilliseconds, lessThan(250));
        expect(result.messages, hasLength(3));
      });

      test('should execute validators sequentially when disabled', () async {
        final validator1 = MockValidator('sequential1', 
          executionDelay: const Duration(milliseconds: 50),
        );
        final validator2 = MockValidator('sequential2', 
          executionDelay: const Duration(milliseconds: 50),
        );
        
        service
          ..registerValidator(validator1)
          ..registerValidator(validator2);
        
        const config = ValidationConfig(
          level: ValidationLevel.basic,
          parallelExecution: false,
        );
        final sequentialService = ValidatorService(config: config)
          ..registerValidators([validator1, validator2]);
        
        final stopwatch = Stopwatch()..start();
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await sequentialService.validateModule(
          tempDir.path,
          context: context,
        );
        stopwatch.stop();
        
        // 串行执行应该大约是100ms
        expect(stopwatch.elapsedMilliseconds, greaterThan(90));
        expect(result.messages, hasLength(2));
      });
    });

    group('Caching System', () {
      test('should cache validation results when enabled', () async {
        final validator = MockValidator('cacheable',);
        
        const config = ValidationConfig(
          level: ValidationLevel.basic,
        );
        final cacheService = ValidatorService(config: config)
          ..registerValidator(validator);
        
        final context = ValidationContext(projectPath: tempDir.path);
        
        // 首次验证
        final result1 = await cacheService.validateModule(
          tempDir.path, 
          context: context,
        );
        expect(result1.messages, hasLength(1));
        
        // 第二次验证应该使用缓存
        final result2 = await cacheService.validateModule(
          tempDir.path, 
          context: context,
        );
        expect(result2.messages, hasLength(1));
        
        // 验证缓存统计
        final cacheStats = cacheService.getCacheStats();
        expect(cacheStats['totalEntries'], greaterThan(0));
      });

      test('should skip cache when disabled', () async {
        final validator = MockValidator('non-cacheable',);
        
        const config = ValidationConfig(
          level: ValidationLevel.basic,
          enableCache: false,
        );
        final noCacheService = ValidatorService(config: config)
          ..registerValidator(validator);
        
        final context = ValidationContext(projectPath: tempDir.path);
        
        // 两次验证都应该重新执行
        await noCacheService.validateModule(tempDir.path, context: context);
        await noCacheService.validateModule(tempDir.path, context: context);
        
        final cacheStats = noCacheService.getCacheStats();
        expect(cacheStats['totalEntries'], equals(0));
      });

      test('should clear cache on demand', () async {
        final validator = MockValidator('clearable',);
        
        const config = ValidationConfig(
          level: ValidationLevel.basic,
        );
        final clearService = ValidatorService(config: config)
          ..registerValidator(validator);
        
        final context = ValidationContext(projectPath: tempDir.path);
        
        // 创建缓存
        await clearService.validateModule(tempDir.path, context: context);
        
        // 清理缓存
        clearService.clearCache();
        
        // 验证缓存已清理
        final cacheStats = clearService.getCacheStats();
        expect(cacheStats['totalEntries'], equals(0));
      });
    });

    group('Validation Statistics', () {
      test('should collect execution statistics', () async {
        final validator1 = MockValidator('stats1',);
        final validator2 = MockValidator('stats2', shouldSucceed: false);
        
        service
          ..registerValidator(validator1)
          ..registerValidator(validator2);
        
        final context = ValidationContext(projectPath: tempDir.path);
        await service.validateModule(
          tempDir.path,
          context: context,
        );
        
        final stats = service.lastValidationStats;
        expect(stats, isNotNull);
        expect(stats!.executedValidators, equals(2));
        expect(stats.totalValidators, greaterThanOrEqualTo(2));
      });

      test('should track timing information', () async {
        final slowValidator = MockValidator('slow', 
          executionDelay: const Duration(milliseconds: 100),
        );
        
        service.registerValidator(slowValidator);
        
        final stopwatch = Stopwatch()..start();
        final context = ValidationContext(projectPath: tempDir.path);
        await service.validateModule(
          tempDir.path,
          context: context,
        );
        stopwatch.stop();
        
        final stats = service.lastValidationStats;
        expect(stats, isNotNull);
        expect(stats!.totalDurationMs, greaterThan(0));
      });
    });

    group('Multiple Module Validation', () {
      test('should validate multiple modules', () async {
        // 创建多个测试目录
        final tempDir2 = 
          await Directory.systemTemp.createTemp('validator_test2_');
        final tempDir3 = 
          await Directory.systemTemp.createTemp('validator_test3_');
        
        try {
          final validator = MockValidator('multi',);
          service
            ..registerValidator(validator)
            ..registerValidator(validator);
          
          final context = ValidationContext(projectPath: tempDir.path);
          final results = await service.validateMultipleModules(
            [tempDir.path, tempDir2.path, tempDir3.path],
            context: context,
          );
          
          expect(results, hasLength(3));
          expect(results.values.every((r) => r.isValid), isTrue);
          expect(results.values.every((r) => r.messages.isNotEmpty), isTrue);
        } finally {
          // 清理
          await tempDir2.delete(recursive: true);
          await tempDir3.delete(recursive: true);
        }
      });

      test('should handle mixed success/failure in multiple modules', () async {
        final tempDir2 = 
          await Directory.systemTemp.createTemp('validator_test2_');
        
        try {
          // 创建一个对第二个目录会失败的验证器
          final validator = MockFailOnPathValidator(['validator_test2']);
          service.registerValidator(validator);
          
          final context = ValidationContext(projectPath: tempDir.path);
          final results = await service.validateMultipleModules(
            [tempDir.path, tempDir2.path],
            context: context,
          );
          
          expect(results, hasLength(2));
          final resultsList = results.values.toList();
          // 第一个应该成功，第二个应该失败
          expect(resultsList.any((r) => r.isValid), isTrue);
          expect(resultsList.any((r) => !r.isValid), isTrue);
        } finally {
          await tempDir2.delete(recursive: true);
        }
      });
    });
  });
}

// ===== Mock 验证器实现 =====

/// 基础Mock验证器
class MockValidator extends ModuleValidator {
  
  MockValidator(
    this._name, {
    int priority = 5,
    bool isHealthy = true,
    bool shouldSucceed = true,
    bool shouldThrow = false,
    Duration? executionDelay,
    Duration? healthCheckDelay,
  }) : _priority = priority,
       _isHealthy = isHealthy,
       _shouldSucceed = shouldSucceed,
       _shouldThrow = shouldThrow,
       _executionDelay = executionDelay,
       _healthCheckDelay = healthCheckDelay;

  final String _name;
  final int _priority;
  final bool _isHealthy;
  final bool _shouldSucceed;
  final bool _shouldThrow;
  final Duration? _executionDelay;
  final Duration? _healthCheckDelay;

  @override
  String get validatorName => _name;

  @override
  List<ValidationType> get supportedTypes => [ValidationType.structure];

  @override
  int get priority => _priority;

  @override
  Future<bool> healthCheck() async {
    if (_healthCheckDelay != null) {
      await Future.delayed(_healthCheckDelay);
    }
    return _isHealthy;
  }

  @override
  Future<ValidationResult> validate(
    String modulePath,
    ValidationContext context,
  ) async {
    if (_executionDelay != null) {
      await Future.delayed(_executionDelay);
    }
    
    if (_shouldThrow) {
      throw Exception('Mock validator exception');
    }
    
    final result = ValidationResult(strictMode: context.strictMode);
    
    if (_shouldSucceed) {
      result.addInfo(
        'Mock validation success',
        validationType: ValidationType.structure,
        validatorName: _name,
      );
    } else {
      result.addError(
        'Mock validation failure',
        validationType: ValidationType.structure,
        validatorName: _name,
      );
    }
    
    result.markCompleted();
    return result;
  }
}

/// 基于路径条件失败的Mock验证器
class MockFailOnPathValidator extends ModuleValidator {
  MockFailOnPathValidator(this._failPatterns);
 
  final List<String> _failPatterns;
  
  @override
  String get validatorName => 'fail-on-path';

  @override
  List<ValidationType> get supportedTypes => [ValidationType.structure];

  @override
  int get priority => 5;

  @override
  Future<bool> healthCheck() async => true;

  @override
  Future<ValidationResult> validate(
    String modulePath,
    ValidationContext context,
  ) async {
    final result = ValidationResult(strictMode: context.strictMode);
    
    final shouldFail = _failPatterns.any(
      (pattern) => modulePath.contains(pattern),
    );
    
    if (shouldFail) {
      result.addError(
        'Conditional failure based on path',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
    } else {
      result.addInfo(
        'Conditional success',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
    }
    
    result.markCompleted();
    return result;
  }
}
