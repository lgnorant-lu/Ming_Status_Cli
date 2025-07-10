/*
---------------------------------------------------------------
File name:          inheritance_system_test.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级继承系统单元测试 (Enterprise Inheritance System Unit Tests)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 继承系统测试;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/inheritance/composition_engine.dart';
import 'package:ming_status_cli/src/core/inheritance/dependency_resolver.dart';
import 'package:ming_status_cli/src/core/inheritance/inheritance_engine.dart';
import 'package:ming_status_cli/src/core/inheritance/inheritance_validator.dart';
import 'package:ming_status_cli/src/core/template_system/advanced_template.dart';
import 'package:ming_status_cli/src/core/template_system/template_metadata.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:ming_status_cli/src/models/template_variable.dart';
import 'package:test/test.dart';

/// 测试用的模板实现
class TestTemplate extends AdvancedTemplate {
  TestTemplate({
    required this.metadata,
    this.dependencies = const [],
    this.parameters = const {},
  });

  @override
  final TemplateMetadata metadata;

  @override
  final List<TemplateDependency> dependencies;

  @override
  final Map<String, TemplateVariable> parameters;

  @override
  TemplateType get type => metadata.type;

  @override
  TemplateSubType? get subType => metadata.subType;

  @override
  PerformanceMetrics? get performanceMetrics => null;

  @override
  Future<void> initialize(TemplateContext context) async {}

  @override
  Future<GenerationResult> generate(GenerationContext context) async {
    return GenerationResult.success(generatedFiles: ['test.dart']);
  }

  @override
  Future<void> cleanup(GenerationContext context) async {}

  @override
  ValidationResult validateParameters(Map<String, dynamic> params) {
    return ValidationResult.success();
  }

  @override
  CompatibilityResult checkCompatibility(TemplateContext context) {
    return const CompatibilityResult(isCompatible: true);
  }
}

void main() {
  group('Inheritance Engine Tests', () {
    late InheritanceEngine inheritanceEngine;
    late DependencyResolver dependencyResolver;
    late CompositionEngine compositionEngine;

    setUp(() {
      dependencyResolver = DependencyResolver();
      compositionEngine = CompositionEngine();
      inheritanceEngine = InheritanceEngine(
        dependencyResolver: dependencyResolver,
        compositionEngine: compositionEngine,
      );
    });

    test('InheritanceContext should be created correctly', () {
      const context = InheritanceContext(
        templateContext: TemplateContext(
          workingDirectory: '/test',
          targetPlatform: TemplatePlatform.mobile,
        ),
        maxDepth: 3,
      );

      expect(context.maxDepth, equals(3));
      expect(context.enableConditionalInheritance, isTrue);
      expect(context.strategy, equals(InheritanceStrategy.merge));
      expect(context.templateContext.workingDirectory, equals('/test'));
    });

    test('InheritanceNode should have correct properties', () {
      final template = TestTemplate(
        metadata: TemplateMetadata(
          id: 'test-001',
          name: 'Test Template',
          version: '1.0.0',
          author: 'Test Author',
          description: 'Test Description',
          type: TemplateType.ui,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final node = InheritanceNode(
        template: template,
        depth: 2,
      );

      expect(node.templateId, equals('test-001'));
      expect(node.depth, equals(2));
      expect(node.isRoot, isTrue); // 没有父节点，所以是根节点
      expect(node.isLeaf, isTrue);
      expect(node.inheritancePath, equals(['test-001']));
    });

    test('InheritanceResult.success should create success result', () {
      final template = TestTemplate(
        metadata: TemplateMetadata(
          id: 'test-001',
          name: 'Test Template',
          version: '1.0.0',
          author: 'Test Author',
          description: 'Test Description',
          type: TemplateType.ui,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final node = InheritanceNode(template: template, depth: 0);
      final result = InheritanceResult.success(
        resolvedTemplate: template,
        inheritanceChain: [node],
        appliedStrategies: {'test.dart': InheritanceStrategy.merge},
      );

      expect(result.success, isTrue);
      expect(result.resolvedTemplate, equals(template));
      expect(result.inheritanceChain, hasLength(1));
      expect(result.appliedStrategies['test.dart'],
          equals(InheritanceStrategy.merge),);
      expect(result.errors, isEmpty);
    });

    test('InheritanceResult.failure should create failure result', () {
      final result = InheritanceResult.failure(
        errors: ['Template not found', 'Invalid configuration'],
        warnings: ['Deprecated feature used'],
      );

      expect(result.success, isFalse);
      expect(result.resolvedTemplate, isNull);
      expect(result.errors, hasLength(2));
      expect(result.warnings, hasLength(1));
      expect(result.inheritanceChain, isEmpty);
    });
  });

  group('Dependency Resolver Tests', () {
    late DependencyResolver resolver;

    setUp(() {
      resolver = DependencyResolver(
        
      );
    });

    test('DependencyNode should be created correctly', () {
      final template = TestTemplate(
        metadata: TemplateMetadata(
          id: 'test-001',
          name: 'Test Template',
          version: '1.0.0',
          author: 'Test Author',
          description: 'Test Description',
          type: TemplateType.ui,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final node = DependencyNode(template: template);

      expect(node.templateId, equals('test-001'));
      expect(node.templateName, equals('Test Template'));
      expect(node.templateVersion, equals('1.0.0'));
      expect(node.resolved, isFalse);
      expect(node.dependencies, isEmpty);
      expect(node.dependents, isEmpty);
    });

    test('DependencyGraph should manage nodes correctly', () {
      final template1 = TestTemplate(
        metadata: TemplateMetadata(
          id: 'test-001',
          name: 'Template 1',
          version: '1.0.0',
          author: 'Test Author',
          description: 'Test Description',
          type: TemplateType.ui,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final template2 = TestTemplate(
        metadata: TemplateMetadata(
          id: 'test-002',
          name: 'Template 2',
          version: '1.0.0',
          author: 'Test Author',
          description: 'Test Description',
          type: TemplateType.service,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final graph = DependencyGraph();
      final node1 = DependencyNode(template: template1);
      final node2 = DependencyNode(template: template2);

      graph.addNode(node1);
      graph.addNode(node2);

      expect(graph.nodeCount, equals(2));
      expect(graph.isEmpty, isFalse);
      expect(graph.getNode('test-001'), equals(node1));
      expect(graph.getNode('test-002'), equals(node2));
    });

    test('DependencyResolutionResult.success should create success result', () {
      final graph = DependencyGraph();
      final result = DependencyResolutionResult.success(
        dependencyGraph: graph,
        resolvedOrder: [],
        warnings: ['Minor version mismatch'],
      );

      expect(result.success, isTrue);
      expect(result.dependencyGraph, equals(graph));
      expect(result.resolvedOrder, isEmpty);
      expect(result.warnings, hasLength(1));
      expect(result.errors, isEmpty);
    });
  });

  group('Composition Engine Tests', () {
    late CompositionEngine compositionEngine;

    setUp(() {
      compositionEngine = CompositionEngine(
        
      );
    });

    test('CompositionConfig should have correct defaults', () {
      const config = CompositionConfig();

      expect(config.defaultStrategy, equals(FileMergeStrategy.merge));
      expect(config.enableAsyncProcessing, isTrue);
      expect(config.enableParallelProcessing, isTrue);
      expect(config.maxParallelTasks, equals(4));
      expect(config.enableValidation, isTrue);
    });

    test('CompositionFragment should be created correctly', () {
      const fragment = CompositionFragment(
        templateId: 'test-001',
        filePath: 'lib/main.dart',
        content: 'void main() {}',
        priority: 10,
      );

      expect(fragment.templateId, equals('test-001'));
      expect(fragment.filePath, equals('lib/main.dart'));
      expect(fragment.content, equals('void main() {}'));
      expect(fragment.priority, equals(10));
      expect(fragment.metadata, isEmpty);
    });

    test('SlotSystem should manage slots correctly', () {
      final slotSystem = SlotSystem();
      const fragment1 = CompositionFragment(
        templateId: 'test-001',
        filePath: 'test.dart',
        content: 'content1',
        priority: 1,
      );
      const fragment2 = CompositionFragment(
        templateId: 'test-002',
        filePath: 'test.dart',
        content: 'content2',
        priority: 2,
      );

      slotSystem.registerSlot('main', fragment1);
      slotSystem.registerSlot('main', fragment2);

      final slotContent = slotSystem.getSlotContent('main');
      expect(slotContent, hasLength(2));

      final mergedContent = slotSystem.mergeSlotContent('main');
      expect(mergedContent, contains('content1'));
      expect(mergedContent, contains('content2'));
    });

    test('CompositionResult.success should create success result', () {
      final template = TestTemplate(
        metadata: TemplateMetadata(
          id: 'test-001',
          name: 'Test Template',
          version: '1.0.0',
          author: 'Test Author',
          description: 'Test Description',
          type: TemplateType.ui,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final result = CompositionResult.success(
        composedTemplate: template,
        appliedStrategies: {'main.dart': FileMergeStrategy.merge},
        processedFiles: ['main.dart', 'config.yaml'],
      );

      expect(result.success, isTrue);
      expect(result.composedTemplate, equals(template));
      expect(result.appliedStrategies['main.dart'],
          equals(FileMergeStrategy.merge),);
      expect(result.processedFiles, hasLength(2));
      expect(result.errors, isEmpty);
    });
  });

  group('Inheritance Validator Tests', () {
    late InheritanceValidator validator;

    setUp(() {
      validator = InheritanceValidator(
        
      );
    });

    test('ValidationIssue should be created correctly', () {
      const issue = ValidationIssue(
        ruleType: ValidationRuleType.chainIntegrity,
        severity: ValidationSeverity.warning,
        message: 'Chain depth exceeds recommendation',
        templateId: 'test-001',
        suggestion: 'Consider refactoring inheritance',
      );

      expect(issue.ruleType, equals(ValidationRuleType.chainIntegrity));
      expect(issue.severity, equals(ValidationSeverity.warning));
      expect(issue.message, equals('Chain depth exceeds recommendation'));
      expect(issue.templateId, equals('test-001'));
      expect(issue.suggestion, equals('Consider refactoring inheritance'));
    });

    test('InheritanceValidationResult should categorize issues correctly', () {
      const issues = [
        ValidationIssue(
          ruleType: ValidationRuleType.chainIntegrity,
          severity: ValidationSeverity.error,
          message: 'Error message',
          templateId: 'test-001',
        ),
        ValidationIssue(
          ruleType: ValidationRuleType.parameterCompatibility,
          severity: ValidationSeverity.warning,
          message: 'Warning message',
          templateId: 'test-002',
        ),
        ValidationIssue(
          ruleType: ValidationRuleType.bestPractices,
          severity: ValidationSeverity.info,
          message: 'Info message',
          templateId: 'test-003',
        ),
      ];

      const result = InheritanceValidationResult(
        isValid: false,
        issues: issues,
      );

      expect(result.errors, hasLength(1));
      expect(result.warnings, hasLength(1));
      expect(result.infos, hasLength(1));
      expect(result.hasErrors, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(result.hasFatalErrors, isFalse);
    });
  });
}
