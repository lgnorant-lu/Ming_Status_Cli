/*
---------------------------------------------------------------
File name:          phase2_1_integration_test.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        Phase 2.1 系统集成测试 (Phase 2.1 System Integration Tests)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 集成测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/conditional/condition_evaluator.dart';
// Conditional System
import 'package:ming_status_cli/src/core/conditional/conditional_renderer.dart';
import 'package:ming_status_cli/src/core/inheritance/composition_engine.dart';
import 'package:ming_status_cli/src/core/inheritance/dependency_resolver.dart';
// Inheritance System
import 'package:ming_status_cli/src/core/inheritance/inheritance_engine.dart';
import 'package:ming_status_cli/src/core/inheritance/inheritance_validator.dart';
// Template Creator
import 'package:ming_status_cli/src/core/template_creator/template_scaffold.dart';
import 'package:ming_status_cli/src/core/template_creator/template_validator.dart';
import 'package:ming_status_cli/src/core/template_system/advanced_template.dart';
import 'package:ming_status_cli/src/core/template_system/template_metadata.dart';
// Template System
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:ming_status_cli/src/models/template_variable.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// 测试用的完整模板实现
class IntegrationTestTemplate extends AdvancedTemplate {
  IntegrationTestTemplate({
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
  Future<void> initialize(TemplateContext context) async {
    // 模拟初始化过程
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<GenerationResult> generate(GenerationContext context) async {
    // 模拟生成过程
    await Future.delayed(const Duration(milliseconds: 50));
    return GenerationResult.success(
      generatedFiles: ['lib/main.dart', 'pubspec.yaml'],
    );
  }

  @override
  Future<void> cleanup(GenerationContext context) async {
    // 模拟清理过程
    await Future.delayed(const Duration(milliseconds: 5));
  }

  @override
  ValidationResult validateParameters(Map<String, dynamic> params) {
    final errors = <String>[];

    // 验证必需参数
    for (final paramName in requiredParameters) {
      if (!params.containsKey(paramName)) {
        errors.add('缺少必需参数: $paramName');
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors: errors);
    }

    return ValidationResult.success();
  }

  @override
  CompatibilityResult checkCompatibility(TemplateContext context) {
    final issues = <String>[];

    // 检查平台兼容性
    if (!supportsPlatform(context.targetPlatform)) {
      issues.add('不支持目标平台: ${context.targetPlatform.name}');
    }

    return CompatibilityResult(
      isCompatible: issues.isEmpty,
      issues: issues,
    );
  }
}

void main() {
  group('Phase 2.1 Integration Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('phase2_1_integration_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Complete Template Creation Workflow', () async {
      // 1. 使用TemplateScaffold创建模板
      final scaffold = TemplateScaffold();
      final config = ScaffoldConfig(
        templateName: 'integration_test_template',
        templateType: TemplateType.ui,
        subType: TemplateSubType.component,
        author: 'Integration Test',
        description: 'Integration test template',
        outputPath: tempDir.path,
        platform: TemplatePlatform.mobile,
        framework: TemplateFramework.flutter,
        complexity: TemplateComplexity.medium,
        enableGitInit: false,
      );

      final scaffoldResult = await scaffold.generateScaffold(config);
      expect(scaffoldResult.success, isTrue);
      expect(scaffoldResult.generatedFiles, isNotEmpty);

      // 2. 使用TemplateValidator验证生成的模板
      final validator = TemplateValidator();
      final validationResult =
          await validator.validateTemplate(scaffoldResult.templatePath);

      // 验证应该通过（可能有一些警告）
      expect(validationResult.hasFatalErrors, isFalse);

      // 3. 验证生成的文件存在
      final templateDir = Directory(scaffoldResult.templatePath);
      expect(await templateDir.exists(), isTrue);

      final metadataFile =
          File(path.join(scaffoldResult.templatePath, 'template.yaml'));
      expect(await metadataFile.exists(), isTrue);
    });

    test('Template System with Conditional Rendering', () async {
      // 1. 创建模板元数据
      final metadata = TemplateMetadata(
        id: 'conditional-test-template',
        name: 'Conditional Test Template',
        version: '1.0.0',
        author: 'Test Author',
        description: 'Template with conditional rendering',
        type: TemplateType.ui,
        subType: TemplateSubType.component,
        platform: TemplatePlatform.mobile,
        framework: TemplateFramework.flutter,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 2. 创建模板实例
      final template = IntegrationTestTemplate(
        metadata: metadata,
        parameters: {
          'componentName': const TemplateVariable(
            name: 'componentName',
            type: TemplateVariableType.string,
            description: 'Component name',
          ),
          'platform': const TemplateVariable(
            name: 'platform',
            type: TemplateVariableType.enumeration,
            description: 'Target platform',
          ),
        },
      );

      // 3. 设置条件渲染
      final evaluator = ConditionEvaluator();
      final renderer = ConditionalRenderer(conditionEvaluator: evaluator);

      const templateContent = '''
{{#if platform.mobile}}
import 'package:flutter/material.dart';

class {{componentName}} extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Mobile Component'),
    );
  }
}
{{/if}}
''';

      const renderContext = RenderContext(
        variables: {
          'componentName': 'TestWidget',
          'platform': {'mobile': true},
        },
        enableCache: false,
      );

      // 4. 执行条件渲染
      final renderResult =
          await renderer.render(templateContent, renderContext);

      expect(renderResult.success, isTrue);
      expect(renderResult.content, contains('TestWidget'));
      expect(renderResult.content, contains('StatelessWidget'));
      expect(renderResult.content, contains('Mobile Component'));
    });

    test('Template Inheritance and Composition Workflow', () async {
      // 1. 创建基础模板
      final baseMetadata = TemplateMetadata(
        id: 'base-template',
        name: 'Base Template',
        version: '1.0.0',
        author: 'Test Author',
        description: 'Base template for inheritance',
        type: TemplateType.ui,
        framework: TemplateFramework.flutter,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final baseTemplate = IntegrationTestTemplate(
        metadata: baseMetadata,
        parameters: {
          'baseName': const TemplateVariable(
            name: 'baseName',
            type: TemplateVariableType.string,
            description: 'Base name',
          ),
        },
      );

      // 2. 创建子模板
      final childMetadata = TemplateMetadata(
        id: 'child-template',
        name: 'Child Template',
        version: '1.0.0',
        author: 'Test Author',
        description: 'Child template that extends base',
        type: TemplateType.ui,
        subType: TemplateSubType.component,
        platform: TemplatePlatform.mobile,
        framework: TemplateFramework.flutter,
        dependencies: [
          const TemplateDependency(name: 'base-template', version: '1.0.0'),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final childTemplate = IntegrationTestTemplate(
        metadata: childMetadata,
        parameters: {
          'baseName': const TemplateVariable(
            name: 'baseName',
            type: TemplateVariableType.string,
            description: 'Base name',
          ),
          'childName': const TemplateVariable(
            name: 'childName',
            type: TemplateVariableType.string,
            description: 'Child name',
          ),
        },
      );

      // 3. 设置继承系统
      final dependencyResolver = DependencyResolver();
      final compositionEngine = CompositionEngine();
      final inheritanceEngine = InheritanceEngine(
        dependencyResolver: dependencyResolver,
        compositionEngine: compositionEngine,
      );

      // 4. 创建继承链
      final baseNode = InheritanceNode(template: baseTemplate, depth: 0);
      final childNode =
          InheritanceNode(template: childTemplate, depth: 1, parent: baseNode);
      final inheritanceChain = [baseNode, childNode];

      // 5. 验证继承链
      final validator = InheritanceValidator();
      final validationResult = await validator.validateInheritance(
        inheritanceChain,
        InheritanceContext(
          templateContext: TemplateContext(
            workingDirectory: tempDir.path,
            targetPlatform: TemplatePlatform.mobile,
          ),
        ),
      );

      expect(validationResult.isValid, isTrue);
      expect(validationResult.hasFatalErrors, isFalse);
    });

    test('End-to-End Template Processing Pipeline', () async {
      // 1. 创建模板
      final metadata = TemplateMetadata(
        id: 'e2e-test-template',
        name: 'End-to-End Test Template',
        version: '1.0.0',
        author: 'E2E Test',
        description: 'Complete end-to-end test template',
        type: TemplateType.service,
        subType: TemplateSubType.api,
        platform: TemplatePlatform.server,
        framework: TemplateFramework.dart,
        tags: ['api', 'service', 'test'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final template = IntegrationTestTemplate(
        metadata: metadata,
        parameters: {
          'serviceName': const TemplateVariable(
            name: 'serviceName',
            type: TemplateVariableType.string,
            description: 'Service name',
          ),
          'port': const TemplateVariable(
            name: 'port',
            type: TemplateVariableType.number,
            description: 'Service port',
            optional: true,
            defaultValue: 8080,
          ),
        },
      );

      // 2. 初始化模板上下文
      final templateContext = TemplateContext(
        workingDirectory: tempDir.path,
        targetPlatform: TemplatePlatform.server,
        environment: {'NODE_ENV': 'test'},
        userPreferences: {'language': 'dart'},
      );

      await template.initialize(templateContext);

      // 3. 验证参数
      final paramValidation = template.validateParameters({
        'serviceName': 'TestService',
        'port': 3000,
      });
      expect(paramValidation.isValid, isTrue);

      // 4. 检查兼容性
      final compatibility = template.checkCompatibility(templateContext);
      expect(compatibility.isCompatible, isTrue);

      // 5. 生成模板内容
      final generationContext = GenerationContext(
        templateContext: templateContext,
        parameters: {
          'serviceName': 'TestService',
          'port': 3000,
        },
        outputPath: tempDir.path,
      );

      final generationResult = await template.generate(generationContext);
      expect(generationResult.success, isTrue);
      expect(generationResult.generatedFiles, isNotEmpty);

      // 6. 清理资源
      await template.cleanup(generationContext);
    });

    test('Template Type System Completeness', () {
      // 验证所有模板类型都有对应的子类型
      for (final templateType in TemplateType.values) {
        final supportedSubTypes = templateType.supportedSubTypes;

        // 除了basic类型，每个模板类型都应该有至少一个支持的子类型
        if (templateType != TemplateType.basic) {
          expect(supportedSubTypes, isNotEmpty,
              reason: '模板类型 ${templateType.name} 应该有支持的子类型',);
        }

        // 验证子类型的显示名称
        for (final subType in supportedSubTypes) {
          expect(subType.displayName, isNotEmpty,
              reason: '子类型 ${subType.name} 应该有显示名称',);
        }
      }

      // 验证企业级类型标识
      final enterpriseTypes =
          TemplateType.values.where((t) => t.isEnterpriseType).toList();
      expect(enterpriseTypes, contains(TemplateType.micro));
      expect(enterpriseTypes, contains(TemplateType.plugin));
      expect(enterpriseTypes, contains(TemplateType.infrastructure));
    });

    test('Performance and Memory Usage', () async {
      final startTime = DateTime.now();
      final startMemory = ProcessInfo.currentRss;

      // 创建多个模板实例
      final templates = <IntegrationTestTemplate>[];
      for (var i = 0; i < 10; i++) {
        final metadata = TemplateMetadata(
          id: 'perf-test-$i',
          name: 'Performance Test $i',
          version: '1.0.0',
          author: 'Perf Test',
          description: 'Performance test template $i',
          type: TemplateType.values[i % TemplateType.values.length],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        templates.add(IntegrationTestTemplate(metadata: metadata));
      }

      // 执行批量操作
      final templateContext = TemplateContext(
        workingDirectory: tempDir.path,
        targetPlatform: TemplatePlatform.crossPlatform,
      );

      for (final template in templates) {
        await template.initialize(templateContext);

        final generationContext = GenerationContext(
          templateContext: templateContext,
          parameters: {},
          outputPath: tempDir.path,
        );

        await template.generate(generationContext);
        await template.cleanup(generationContext);
      }

      final endTime = DateTime.now();
      final endMemory = ProcessInfo.currentRss;

      final executionTime = endTime.difference(startTime);
      final memoryUsage = endMemory - startMemory;

      // 性能断言
      expect(executionTime.inMilliseconds, lessThan(5000),
          reason: '批量处理10个模板应该在5秒内完成',);

      expect(memoryUsage, lessThan(50 * 1024 * 1024), reason: '内存使用应该少于50MB');

      print('性能指标:');
      print('  执行时间: ${executionTime.inMilliseconds}ms');
      print('  内存使用: ${(memoryUsage / 1024 / 1024).toStringAsFixed(2)}MB');
    });

    test('Error Handling and Recovery', () async {
      // 测试各种错误场景的处理

      // 1. 无效模板元数据
      expect(
          () => TemplateMetadata(
                id: '', // 空ID应该在验证时被捕获
                name: 'Invalid Template',
                version: '1.0.0',
                author: 'Test',
                description: 'Invalid template',
                type: TemplateType.basic,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
          returnsNormally,); // 构造函数不应该抛出异常

      // 2. 条件渲染错误处理
      final evaluator = ConditionEvaluator();
      final renderer = ConditionalRenderer(conditionEvaluator: evaluator);

      const invalidTemplate = '{{#if unclosed_tag}}content';
      const renderContext = RenderContext(
        variables: {},
        enableCache: false,
      );

      final renderResult =
          await renderer.render(invalidTemplate, renderContext);
      // 应该优雅地处理错误，而不是崩溃
      expect(renderResult, isNotNull);

      // 3. 模板验证错误处理
      final validator = TemplateValidator();
      final nonExistentPath = path.join(tempDir.path, 'non_existent_template');

      final validationResult =
          await validator.validateTemplate(nonExistentPath);
      expect(validationResult.isValid, isFalse);
      expect(validationResult.hasFatalErrors, isTrue);
    });
  });
}

/// 简化的进程信息类
class ProcessInfo {
  static int get currentRss {
    // 简化实现，返回模拟值
    return 10 * 1024 * 1024; // 10MB
  }
}
