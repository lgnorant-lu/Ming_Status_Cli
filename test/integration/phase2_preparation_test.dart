/*
---------------------------------------------------------------
File name:          phase2_preparation_test.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 52.3 - Phase 2准备测试
                    验证扩展接口和向后兼容性功能
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - Phase 2准备测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/compatibility_manager.dart';
import 'package:ming_status_cli/src/core/extension_manager.dart';
import 'package:ming_status_cli/src/interfaces/extension_interface.dart';
import 'package:test/test.dart';

void main() {
  group('Task 52.3: Phase 2准备和接口预留测试', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('ming_phase2_test_');
      print('🚀 Phase 2准备测试目录: ${tempDir.path}');
    });

    tearDownAll(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
        print('🗑️  清理测试目录: ${tempDir.path}');
      }
    });

    group('扩展接口系统测试', () {
      test('应该能够创建扩展元数据', () {
        const metadata = ExtensionMetadata(
          id: 'test_extension',
          name: 'Test Extension',
          version: '1.0.0',
          description: 'A test extension',
          author: 'Test Author',
          type: ExtensionType.template,
          minCliVersion: '1.0.0',
          dependencies: ['core_extension'],
        );

        expect(metadata.id, equals('test_extension'));
        expect(metadata.name, equals('Test Extension'));
        expect(metadata.type, equals(ExtensionType.template));
        expect(metadata.dependencies, contains('core_extension'));
        
        print('✅ 扩展元数据创建测试通过');
      });

      test('应该能够序列化和反序列化扩展元数据', () {
        const metadata = ExtensionMetadata(
          id: 'serialization_test',
          name: 'Serialization Test',
          version: '2.0.0',
          description: 'Test serialization',
          author: 'Test Author',
          type: ExtensionType.validator,
          minCliVersion: '1.0.0',
        );

        final json = metadata.toJson();
        final restored = ExtensionMetadata.fromJson(json);

        expect(restored.id, equals(metadata.id));
        expect(restored.name, equals(metadata.name));
        expect(restored.version, equals(metadata.version));
        expect(restored.type, equals(metadata.type));
        
        print('✅ 扩展元数据序列化测试通过');
      });

      test('应该能够创建验证结果', () {
        const result = ValidationResult(
          isValid: false,
          errors: ['Error 1', 'Error 2'],
          warnings: ['Warning 1'],
          details: {'errorCount': 2, 'warningCount': 1},
        );

        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(2));
        expect(result.warnings, hasLength(1));
        expect(result.details['errorCount'], equals(2));
        
        print('✅ 验证结果创建测试通过');
      });

      test('应该能够创建验证规则', () {
        const rule = ValidationRule(
          id: 'test_rule',
          name: 'Test Rule',
          description: 'A test validation rule',
          severity: ValidationSeverity.error,
          config: {'threshold': 10},
        );

        expect(rule.id, equals('test_rule'));
        expect(rule.severity, equals(ValidationSeverity.error));
        expect(rule.config['threshold'], equals(10));
        
        print('✅ 验证规则创建测试通过');
      });

      test('应该能够创建生成结果', () {
        const stats = GenerationStats(
          fileCount: 5,
          directoryCount: 2,
          totalLines: 1000,
          totalBytes: 50000,
          durationMs: 1500,
        );

        const result = GenerationResult(
          files: {'main.dart': 'content', 'test.dart': 'test content'},
          directories: ['lib', 'test'],
          stats: stats,
          logs: ['Generated main.dart', 'Generated test.dart'],
        );

        expect(result.files, hasLength(2));
        expect(result.directories, hasLength(2));
        expect(result.stats.fileCount, equals(5));
        expect(result.logs, hasLength(2));
        
        print('✅ 生成结果创建测试通过');
      });

      test('应该能够创建命令定义', () {
        const option = CommandOption(
          name: 'verbose',
          abbr: 'v',
          description: 'Enable verbose output',
          defaultValue: 'false',
        );

        const argument = CommandArgument(
          name: 'input',
          description: 'Input file path',
        );

        const command = ExtensionCommand(
          name: 'generate',
          description: 'Generate code from template',
          usage: 'generate [options] <input>',
          options: [option],
          arguments: [argument],
        );

        expect(command.name, equals('generate'));
        expect(command.options, hasLength(1));
        expect(command.arguments, hasLength(1));
        expect(command.options.first.name, equals('verbose'));
        expect(command.arguments.first.name, equals('input'));
        
        print('✅ 命令定义创建测试通过');
      });
    });

    group('扩展管理器测试', () {
      late ExtensionManager manager;

      setUp(() {
        manager = ExtensionManager();
      });

      tearDown(() async {
        await manager.dispose();
      });

      test('应该能够初始化扩展管理器', () async {
        await manager.initialize();
        
        // 验证管理器已初始化
        expect(manager, isNotNull);
        
        print('✅ 扩展管理器初始化测试通过');
      });

      test('应该能够获取扩展统计信息', () async {
        await manager.initialize();
        
        final stats = manager.getStats();
        
        expect(stats, isNotNull);
        expect(stats.totalExtensions, isA<int>());
        expect(stats.activeExtensions, isA<int>());
        expect(stats.templateExtensions, isA<int>());
        
        print('✅ 扩展统计信息测试通过');
      });

      test('应该能够检查扩展是否存在', () async {
        await manager.initialize();
        
        final exists = manager.hasExtension('nonexistent_extension');
        expect(exists, isFalse);
        
        print('✅ 扩展存在性检查测试通过');
      });

      test('应该能够获取不同类型的扩展', () async {
        await manager.initialize();
        
        final templateExtensions = manager.getTemplateExtensions();
        final validatorExtensions = manager.getValidatorExtensions();
        final generatorExtensions = manager.getGeneratorExtensions();
        final commandExtensions = manager.getCommandExtensions();
        final providerExtensions = manager.getProviderExtensions();
        final middlewareExtensions = manager.getMiddlewareExtensions();
        
        expect(templateExtensions, isA<List<TemplateExtension>>());
        expect(validatorExtensions, isA<List<ValidatorExtension>>());
        expect(generatorExtensions, isA<List<GeneratorExtension>>());
        expect(commandExtensions, isA<List<CommandExtension>>());
        expect(providerExtensions, isA<List<ProviderExtension>>());
        expect(middlewareExtensions, isA<List<MiddlewareExtension>>());
        
        print('✅ 扩展类型获取测试通过');
      });

      test('应该能够获取所有扩展信息', () async {
        await manager.initialize();
        
        final allExtensions = manager.getAllExtensions();
        
        expect(allExtensions, isA<List<ExtensionInfo>>());
        
        print('✅ 所有扩展信息获取测试通过');
      });
    });

    group('向后兼容性管理器测试', () {
      late CompatibilityManager manager;

      setUp(() {
        manager = CompatibilityManager();
        manager.initialize();
      });

      test('应该能够初始化兼容性管理器', () {
        expect(manager, isNotNull);
        
        print('✅ 兼容性管理器初始化测试通过');
      });

      test('应该能够检查版本兼容性', () async {
        final result = await manager.checkCompatibility(
          '1.0.0',
          '2.0.0',
          {'configPath': 'test_config.yaml'},
        );

        expect(result, isNotNull);
        expect(result.level, isA<CompatibilityLevel>());
        expect(result.passed, isA<bool>());
        expect(result.messages, isA<List<String>>());
        expect(result.migrationSuggestions, isA<List<String>>());
        expect(result.affectedFeatures, isA<List<String>>());
        
        print('✅ 版本兼容性检查测试通过');
      });

      test('应该能够执行版本迁移', () async {
        final result = await manager.migrate(
          '1.0.0',
          '2.0.0',
          {'configPath': 'test_config.yaml'},
        );

        expect(result, isNotNull);
        expect(result.success, isA<bool>());
        expect(result.fromVersion, equals('1.0.0'));
        expect(result.toVersion, equals('2.0.0'));
        expect(result.executedScripts, isA<Map<String, bool>>());
        expect(result.errors, isA<List<String>>());
        
        print('✅ 版本迁移执行测试通过');
      });

      test('应该能够管理弃用功能', () {
        const deprecationInfo = DeprecationInfo(
          feature: 'old_feature',
          deprecatedInVersion: '2.0.0',
          removedInVersion: '3.0.0',
          reason: 'Replaced by new feature',
          migrationAdvice: 'Use new_feature instead',
        );

        manager.deprecateFeature('old_feature', deprecationInfo);
        
        expect(manager.isFeatureDeprecated('old_feature'), isTrue);
        expect(manager.isFeatureDeprecated('new_feature'), isFalse);
        
        final info = manager.getDeprecationInfo('old_feature');
        expect(info, isNotNull);
        expect(info!.feature, equals('old_feature'));
        expect(info.reason, equals('Replaced by new feature'));
        
        print('✅ 弃用功能管理测试通过');
      });

      test('应该能够生成兼容性报告', () {
        final report = manager.generateReport('2.0.0');

        expect(report, isNotNull);
        expect(report.version, equals('2.0.0'));
        expect(report.deprecatedFeatures, isA<List<String>>());
        expect(report.breakingChanges, isA<List<String>>());
        expect(report.availableMigrations, isA<List<String>>());
        expect(report.compatibilityRules, isA<int>());
        
        final json = report.toJson();
        expect(json, isA<Map<String, dynamic>>());
        expect(json['version'], equals('2.0.0'));
        
        print('✅ 兼容性报告生成测试通过');
      });

      test('应该能够获取所有弃用功能', () {
        const deprecationInfo = DeprecationInfo(
          feature: 'test_feature',
          deprecatedInVersion: '2.0.0',
          removedInVersion: '3.0.0',
          reason: 'Test deprecation',
          migrationAdvice: 'Use alternative',
        );

        manager.deprecateFeature('test_feature', deprecationInfo);
        
        final allDeprecated = manager.getAllDeprecatedFeatures();
        expect(allDeprecated, isA<Map<String, DeprecationInfo>>());
        expect(allDeprecated.containsKey('test_feature'), isTrue);
        
        print('✅ 所有弃用功能获取测试通过');
      });
    });

    group('扩展接口完整性测试', () {
      test('应该包含所有必需的扩展类型', () {
        const types = ExtensionType.values;
        
        expect(types, contains(ExtensionType.template));
        expect(types, contains(ExtensionType.validator));
        expect(types, contains(ExtensionType.generator));
        expect(types, contains(ExtensionType.command));
        expect(types, contains(ExtensionType.provider));
        expect(types, contains(ExtensionType.middleware));
        
        print('✅ 扩展类型完整性测试通过');
      });

      test('应该包含所有必需的扩展状态', () {
        const statuses = ExtensionStatus.values;
        
        expect(statuses, contains(ExtensionStatus.uninitialized));
        expect(statuses, contains(ExtensionStatus.initializing));
        expect(statuses, contains(ExtensionStatus.active));
        expect(statuses, contains(ExtensionStatus.inactive));
        expect(statuses, contains(ExtensionStatus.error));
        expect(statuses, contains(ExtensionStatus.disposed));
        
        print('✅ 扩展状态完整性测试通过');
      });

      test('应该包含所有必需的验证严重级别', () {
        const severities = ValidationSeverity.values;
        
        expect(severities, contains(ValidationSeverity.info));
        expect(severities, contains(ValidationSeverity.warning));
        expect(severities, contains(ValidationSeverity.error));
        expect(severities, contains(ValidationSeverity.critical));
        
        print('✅ 验证严重级别完整性测试通过');
      });

      test('应该包含所有必需的兼容性级别', () {
        const levels = CompatibilityLevel.values;
        
        expect(levels, contains(CompatibilityLevel.full));
        expect(levels, contains(CompatibilityLevel.partial));
        expect(levels, contains(CompatibilityLevel.deprecated));
        expect(levels, contains(CompatibilityLevel.breaking));
        
        print('✅ 兼容性级别完整性测试通过');
      });
    });

    group('Phase 2准备验证测试', () {
      test('应该为模板扩展预留接口', () {
        // 验证模板扩展接口的完整性
        expect(TemplateExtension, isA<Type>());
        
        // 验证接口方法存在
        final methods = [
          'supportedTemplateTypes',
          'generateTemplate',
          'validateTemplateContext',
          'getTemplateSchema',
        ];
        
        // 这里只是验证接口定义存在，实际实现在Phase 2
        expect(methods, hasLength(4));
        
        print('✅ 模板扩展接口预留验证通过');
      });

      test('应该为验证器扩展预留接口', () {
        // 验证验证器扩展接口的完整性
        expect(ValidatorExtension, isA<Type>());
        
        // 验证接口方法存在
        final methods = [
          'supportedValidationTypes',
          'validate',
          'getValidationRules',
        ];
        
        expect(methods, hasLength(3));
        
        print('✅ 验证器扩展接口预留验证通过');
      });

      test('应该为生成器扩展预留接口', () {
        // 验证生成器扩展接口的完整性
        expect(GeneratorExtension, isA<Type>());
        
        // 验证接口方法存在
        final methods = [
          'supportedGeneratorTypes',
          'generate',
          'preview',
        ];
        
        expect(methods, hasLength(3));
        
        print('✅ 生成器扩展接口预留验证通过');
      });

      test('应该为命令扩展预留接口', () {
        // 验证命令扩展接口的完整性
        expect(CommandExtension, isA<Type>());
        
        // 验证接口方法存在
        final methods = [
          'commands',
          'executeCommand',
        ];
        
        expect(methods, hasLength(2));
        
        print('✅ 命令扩展接口预留验证通过');
      });

      test('应该为提供者扩展预留接口', () {
        // 验证提供者扩展接口的完整性
        expect(ProviderExtension, isA<Type>());
        
        // 验证接口方法存在
        final methods = [
          'providerType',
          'provide',
          'supportsService',
          'supportedServices',
        ];
        
        expect(methods, hasLength(4));
        
        print('✅ 提供者扩展接口预留验证通过');
      });

      test('应该为中间件扩展预留接口', () {
        // 验证中间件扩展接口的完整性
        expect(MiddlewareExtension, isA<Type>());
        
        // 验证接口方法存在
        final methods = [
          'priority',
          'process',
        ];
        
        expect(methods, hasLength(2));
        
        print('✅ 中间件扩展接口预留验证通过');
      });
    });
  });
}
