/*
---------------------------------------------------------------
File name:          template_system_test.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板系统单元测试 (Enterprise Template System Unit Tests)
---------------------------------------------------------------
Change History:    
    2025/07/10: Initial creation - Phase 2.1 高级模板系统测试;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_system/advanced_template.dart';
import 'package:ming_status_cli/src/core/template_system/template_metadata.dart';
import 'package:ming_status_cli/src/core/template_system/template_registry.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:test/test.dart';

void main() {
  group('Template Types Tests', () {
    test('TemplateType should have correct display names', () {
      expect(TemplateType.ui.displayName, equals('UI组件'));
      expect(TemplateType.service.displayName, equals('业务服务'));
      expect(TemplateType.micro.displayName, equals('微服务'));
      expect(TemplateType.plugin.displayName, equals('插件系统'));
    });

    test('TemplateType should have correct descriptions', () {
      expect(TemplateType.ui.description, contains('用户界面'));
      expect(TemplateType.service.description, contains('业务逻辑'));
      expect(TemplateType.micro.description, contains('微服务架构'));
    });

    test('TemplateType should have correct supported sub types', () {
      final uiSubTypes = TemplateType.ui.supportedSubTypes;
      expect(uiSubTypes, contains(TemplateSubType.component));
      expect(uiSubTypes, contains(TemplateSubType.page));
      expect(uiSubTypes, contains(TemplateSubType.theme));
      expect(uiSubTypes, contains(TemplateSubType.layout));

      final microSubTypes = TemplateType.micro.supportedSubTypes;
      expect(microSubTypes, contains(TemplateSubType.standalone));
      expect(microSubTypes, contains(TemplateSubType.gateway));
      expect(microSubTypes, contains(TemplateSubType.messaging));
    });

    test('TemplateType should correctly identify enterprise types', () {
      expect(TemplateType.micro.isEnterpriseType, isTrue);
      expect(TemplateType.plugin.isEnterpriseType, isTrue);
      expect(TemplateType.infrastructure.isEnterpriseType, isTrue);
      
      expect(TemplateType.ui.isEnterpriseType, isFalse);
      expect(TemplateType.service.isEnterpriseType, isFalse);
      expect(TemplateType.basic.isEnterpriseType, isFalse);
    });

    test('TemplateSubType should have correct display names', () {
      expect(TemplateSubType.component.displayName, equals('UI组件'));
      expect(TemplateSubType.api.displayName, equals('API服务'));
      expect(TemplateSubType.standalone.displayName, equals('独立服务'));
      expect(TemplateSubType.containerization.displayName, equals('容器化'));
    });
  });

  group('Template Metadata Tests', () {
    late TemplateMetadata metadata;

    setUp(() {
      metadata = TemplateMetadata(
        id: 'test-template-001',
        name: 'Test Template',
        version: '1.0.0',
        author: 'Test Author',
        description: 'A test template for unit testing',
        type: TemplateType.ui,
        subType: TemplateSubType.component,
        tags: ['test', 'ui', 'component'],
        complexity: TemplateComplexity.simple,
        framework: TemplateFramework.flutter,
        createdAt: DateTime(2025, 7, 10),
        updatedAt: DateTime(2025, 7, 10),
      );
    });

    test('TemplateMetadata should be created correctly', () {
      expect(metadata.id, equals('test-template-001'));
      expect(metadata.name, equals('Test Template'));
      expect(metadata.version, equals('1.0.0'));
      expect(metadata.type, equals(TemplateType.ui));
      expect(metadata.subType, equals(TemplateSubType.component));
    });

    test('TemplateMetadata should convert to JSON correctly', () {
      final json = metadata.toJson();
      
      expect(json['id'], equals('test-template-001'));
      expect(json['name'], equals('Test Template'));
      expect(json['type'], equals('ui'));
      expect(json['subType'], equals('component'));
      expect(json['complexity'], equals('simple'));
      expect(json['maturity'], equals('stable'));
      expect(json['platform'], equals('crossPlatform'));
      expect(json['framework'], equals('flutter'));
    });

    test('TemplateMetadata should be created from JSON correctly', () {
      final json = metadata.toJson();
      final recreated = TemplateMetadata.fromJson(json);
      
      expect(recreated.id, equals(metadata.id));
      expect(recreated.name, equals(metadata.name));
      expect(recreated.version, equals(metadata.version));
      expect(recreated.type, equals(metadata.type));
      expect(recreated.subType, equals(metadata.subType));
      expect(recreated.complexity, equals(metadata.complexity));
      expect(recreated.maturity, equals(metadata.maturity));
    });

    test('TemplateMetadata should support copyWith', () {
      final updated = metadata.copyWith(
        version: '1.1.0',
        description: 'Updated description',
        maturity: TemplateMaturity.beta,
      );
      
      expect(updated.id, equals(metadata.id));
      expect(updated.name, equals(metadata.name));
      expect(updated.version, equals('1.1.0'));
      expect(updated.description, equals('Updated description'));
      expect(updated.maturity, equals(TemplateMaturity.beta));
      expect(updated.type, equals(metadata.type));
    });

    test('TemplateMetadata equality should work correctly', () {
      final same = TemplateMetadata(
        id: metadata.id,
        name: 'Different Name',
        version: metadata.version,
        author: 'Different Author',
        description: 'Different Description',
        type: TemplateType.service,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final different = metadata.copyWith(version: '2.0.0');
      
      expect(metadata == same, isTrue);
      expect(metadata == different, isFalse);
    });
  });

  group('Template Dependency Tests', () {
    test('TemplateDependency should be created correctly', () {
      const dependency = TemplateDependency(
        name: 'flutter',
        version: '^3.16.0',
        description: 'Flutter framework dependency',
      );
      
      expect(dependency.name, equals('flutter'));
      expect(dependency.version, equals('^3.16.0'));
      expect(dependency.type, equals(DependencyType.required));
      expect(dependency.description, equals('Flutter framework dependency'));
    });

    test('TemplateDependency should convert to/from JSON correctly', () {
      const dependency = TemplateDependency(
        name: 'dart',
        version: '>=3.0.0 <4.0.0',
        type: DependencyType.peer,
      );
      
      final json = dependency.toJson();
      expect(json['name'], equals('dart'));
      expect(json['version'], equals('>=3.0.0 <4.0.0'));
      expect(json['type'], equals('peer'));
      
      final recreated = TemplateDependency.fromJson(json);
      expect(recreated.name, equals(dependency.name));
      expect(recreated.version, equals(dependency.version));
      expect(recreated.type, equals(dependency.type));
    });
  });

  group('Template Context Tests', () {
    test('TemplateContext should be created correctly', () {
      const context = TemplateContext(
        workingDirectory: '/test/project',
        targetPlatform: TemplatePlatform.mobile,
        environment: {'NODE_ENV': 'development'},
        userPreferences: {'theme': 'dark'},
        projectConfig: {'name': 'test_project'},
      );
      
      expect(context.workingDirectory, equals('/test/project'));
      expect(context.targetPlatform, equals(TemplatePlatform.mobile));
      expect(context.environment['NODE_ENV'], equals('development'));
      expect(context.userPreferences['theme'], equals('dark'));
      expect(context.projectConfig['name'], equals('test_project'));
    });
  });

  group('Generation Result Tests', () {
    test('GenerationResult.success should create success result', () {
      final result = GenerationResult.success(
        generatedFiles: ['lib/main.dart', 'pubspec.yaml'],
        warnings: ['Warning: deprecated API used'],
        metadata: {'fileCount': 2},
      );
      
      expect(result.success, isTrue);
      expect(result.generatedFiles, hasLength(2));
      expect(result.generatedFiles, contains('lib/main.dart'));
      expect(result.warnings, hasLength(1));
      expect(result.errors, isEmpty);
      expect(result.metadata['fileCount'], equals(2));
    });

    test('GenerationResult.failure should create failure result', () {
      final result = GenerationResult.failure(
        errors: ['Error: template not found', 'Error: invalid parameters'],
        warnings: ['Warning: using default values'],
        generatedFiles: ['partial.dart'],
      );
      
      expect(result.success, isFalse);
      expect(result.errors, hasLength(2));
      expect(result.warnings, hasLength(1));
      expect(result.generatedFiles, hasLength(1));
    });
  });

  group('Validation Result Tests', () {
    test('ValidationResult.success should create success result', () {
      final result = ValidationResult.success(
        warnings: ['Parameter could be more specific'],
        suggestions: ['Consider using enum type'],
      );
      
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.warnings, hasLength(1));
      expect(result.suggestions, hasLength(1));
    });

    test('ValidationResult.failure should create failure result', () {
      final result = ValidationResult.failure(
        errors: ['Required parameter missing', 'Invalid parameter type'],
        warnings: ['Deprecated parameter used'],
      );
      
      expect(result.isValid, isFalse);
      expect(result.errors, hasLength(2));
      expect(result.warnings, hasLength(1));
    });
  });

  group('Performance Metrics Tests', () {
    test('PerformanceMetrics should calculate execution time correctly', () {
      final startTime = DateTime(2025, 7, 10, 10);
      final endTime = DateTime(2025, 7, 10, 10, 0, 5); // 5 seconds later
      
      final metrics = PerformanceMetrics(
        startTime: startTime,
        endTime: endTime,
        memoryUsage: 1024 * 1024, // 1MB
        cacheHits: 8,
        cacheMisses: 2,
        fileOperations: 10,
      );
      
      expect(metrics.executionTimeMs, equals(5000));
      expect(metrics.cacheHitRate, equals(0.8));
      expect(metrics.memoryUsage, equals(1024 * 1024));
    });

    test('PerformanceMetrics should handle zero cache operations', () {
      final metrics = PerformanceMetrics(
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        memoryUsage: 0,
      );
      
      expect(metrics.cacheHitRate, equals(0.0));
    });
  });

  group('Template Search Query Tests', () {
    test('TemplateSearchQuery should be created with default values', () {
      const query = TemplateSearchQuery();
      
      expect(query.keyword, isNull);
      expect(query.type, isNull);
      expect(query.sortBy, equals(TemplateSortBy.relevance));
      expect(query.sortOrder, equals(SortOrder.descending));
      expect(query.limit, equals(50));
      expect(query.offset, equals(0));
      expect(query.tags, isEmpty);
    });

    test('TemplateSearchQuery should be created with custom values', () {
      const query = TemplateSearchQuery(
        keyword: 'flutter',
        type: TemplateType.ui,
        platform: TemplatePlatform.mobile,
        complexity: TemplateComplexity.medium,
        tags: ['mobile', 'ui'],
        sortBy: TemplateSortBy.rating,
        sortOrder: SortOrder.ascending,
        limit: 20,
        offset: 10,
      );
      
      expect(query.keyword, equals('flutter'));
      expect(query.type, equals(TemplateType.ui));
      expect(query.platform, equals(TemplatePlatform.mobile));
      expect(query.complexity, equals(TemplateComplexity.medium));
      expect(query.tags, contains('mobile'));
      expect(query.tags, contains('ui'));
      expect(query.sortBy, equals(TemplateSortBy.rating));
      expect(query.sortOrder, equals(SortOrder.ascending));
      expect(query.limit, equals(20));
      expect(query.offset, equals(10));
    });
  });
}
