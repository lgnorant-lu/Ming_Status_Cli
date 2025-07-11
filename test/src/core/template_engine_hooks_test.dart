/*
---------------------------------------------------------------
File name:          template_engine_hooks_test.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        模板引擎钩子系统测试用例
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_engine/template_engine.dart';
import 'package:ming_status_cli/src/core/template_engine/template_models.dart';
import 'package:test/test.dart';

/// 简单的测试钩子
class SimpleTestHook extends TemplateHook {
  SimpleTestHook(String name, this.hookType, {this.hookPriority = 100})
      : super(name: name);

  final HookType hookType;
  final int hookPriority;
  bool executed = false;
  HookContext? lastContext;

  @override
  HookType get type => hookType;

  @override
  int get priority => hookPriority;

  @override
  Future<HookResult> execute(HookContext context) async {
    executed = true;
    lastContext = context;
    return HookResult.successResult;
  }
}

/// 变量修改钩子
class VariableModifyingHook extends TemplateHook {
  VariableModifyingHook() : super(name: 'variable_modifying_hook');

  @override
  HookType get type => HookType.preGeneration;

  @override
  Future<HookResult> execute(HookContext context) async {
    return HookResult(
      success: true,
      modifiedVariables: {
        'hook_added_var': 'hook_value',
        'modified_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}

/// 失败钩子
class FailingHook extends TemplateHook {
  FailingHook() : super(name: 'failing_hook');

  @override
  HookType get type => HookType.preGeneration;

  @override
  Future<HookResult> execute(HookContext context) async {
    return HookResult.failure('Hook intentionally failed');
  }
}

void main() {
  group('TemplateEngine 钩子系统测试', () {
    late TemplateEngine engine;

    setUp(() {
      engine = TemplateEngine();
    });

    group('HookRegistry 测试', () {
      test('应该能注册钩子', () {
        final hook = SimpleTestHook('test_hook', HookType.preGeneration);
        engine.hookRegistry.register(hook);

        final hooks = engine.hookRegistry.getHooks(HookType.preGeneration);
        expect(hooks.length, equals(1));
        expect(hooks.first.name, equals('test_hook'));
      });

      test('应该按优先级排序钩子', () {
        final hook1 = SimpleTestHook(
          'hook1',
          HookType.preGeneration,
        );
        final hook2 = SimpleTestHook(
          'hook2',
          HookType.preGeneration,
          hookPriority: 50,
        );
        final hook3 = SimpleTestHook(
          'hook3',
          HookType.preGeneration,
          hookPriority: 200,
        );

        engine.hookRegistry.register(hook1);
        engine.hookRegistry.register(hook2);
        engine.hookRegistry.register(hook3);

        final hooks = engine.hookRegistry.getHooks(HookType.preGeneration);
        expect(hooks.length, equals(3));
        expect(hooks[0].priority, equals(50)); // 最高优先级
        expect(hooks[1].priority, equals(100));
        expect(hooks[2].priority, equals(200)); // 最低优先级
      });

      test('应该能注销钩子', () {
        final hook = SimpleTestHook('test_hook', HookType.preGeneration);
        engine.hookRegistry.register(hook);

        expect(
          engine.hookRegistry.getHooks(HookType.preGeneration).length,
          equals(1),
        );

        engine.hookRegistry.unregister('test_hook', HookType.preGeneration);

        expect(
          engine.hookRegistry.getHooks(HookType.preGeneration).length,
          equals(0),
        );
      });

      test('应该清空所有钩子', () {
        engine.hookRegistry.register(
          SimpleTestHook('hook1', HookType.preGeneration),
        );
        engine.hookRegistry.register(
          SimpleTestHook('hook2', HookType.postGeneration),
        );

        expect(
          engine.hookRegistry.getHooks(HookType.preGeneration).length,
          greaterThan(0),
        );
        expect(
          engine.hookRegistry.getHooks(HookType.postGeneration).length,
          greaterThan(0),
        );

        engine.hookRegistry.clear();

        expect(
          engine.hookRegistry.getHooks(HookType.preGeneration).length,
          equals(0),
        );
        expect(
          engine.hookRegistry.getHooks(HookType.postGeneration).length,
          equals(0),
        );
      });
    });

    group('HookResult 测试', () {
      test('应该创建成功结果', () {
        const result = HookResult(success: true);
        expect(result.success, isTrue);
        expect(result.shouldContinue, isTrue);
        expect(result.message, isNull);
        expect(result.modifiedVariables, isNull);
      });

      test('应该创建失败结果', () {
        final result = HookResult.failure('Test failure');
        expect(result.success, isFalse);
        expect(result.message, equals('Test failure'));
        expect(result.shouldContinue, isTrue);
      });

      test('应该创建停止结果', () {
        final result = HookResult.stop('Stop execution');
        expect(result.success, isTrue);
        expect(result.shouldContinue, isFalse);
        expect(result.message, equals('Stop execution'));
      });

      test('应该使用静态成功结果', () {
        const result = HookResult.successResult;
        expect(result.success, isTrue);
        expect(result.shouldContinue, isTrue);
      });
    });

    group('HookContext 测试', () {
      test('应该正确创建上下文', () {
        const context = HookContext(
          templateName: 'test_template',
          outputPath: '/test/output',
          variables: {'key': 'value'},
          metadata: {'meta': 'data'},
        );

        expect(context.templateName, equals('test_template'));
        expect(context.outputPath, equals('/test/output'));
        expect(context.variables['key'], equals('value'));
        expect(context.metadata['meta'], equals('data'));
      });
    });

    group('TemplateInheritance 测试', () {
      test('应该正确创建继承配置', () {
        const inheritance = TemplateInheritance(
          baseTemplate: 'base_template',
          overrides: {'key': 'value'},
          excludeFiles: ['exclude.txt'],
        );

        expect(inheritance.baseTemplate, equals('base_template'));
        expect(inheritance.overrides['key'], equals('value'));
        expect(inheritance.excludeFiles, contains('exclude.txt'));
      });

      test('应该支持空的覆盖和排除', () {
        const inheritance = TemplateInheritance(
          baseTemplate: 'base_template',
        );

        expect(inheritance.baseTemplate, equals('base_template'));
        expect(inheritance.overrides, isEmpty);
        expect(inheritance.excludeFiles, isEmpty);
      });
    });

    group('GenerationResult 测试', () {
      test('应该创建成功结果', () {
        const result = GenerationResult(
          success: true,
          outputPath: '/test/output',
          generatedFiles: ['file1.dart', 'file2.dart'],
          message: 'Success',
          metadata: {'key': 'value'},
        );

        expect(result.success, isTrue);
        expect(result.outputPath, equals('/test/output'));
        expect(result.generatedFiles.length, equals(2));
        expect(result.message, equals('Success'));
        expect(result.metadata['key'], equals('value'));
      });

      test('应该创建失败结果', () {
        final result = GenerationResult.failure(
          'Generation failed',
          outputPath: '/test/output',
        );

        expect(result.success, isFalse);
        expect(result.message, equals('Generation failed'));
        expect(result.outputPath, equals('/test/output'));
        expect(result.generatedFiles, isEmpty);
      });
    });

    group('默认钩子测试', () {
      test('应该注册默认钩子', () {
        engine.registerDefaultHooks();

        final preHooks = engine.hookRegistry.getHooks(HookType.preGeneration);
        final postHooks = engine.hookRegistry.getHooks(HookType.postGeneration);

        expect(preHooks.any((h) => h.name == 'default_validation'), isTrue);
        expect(postHooks.any((h) => h.name == 'default_logging'), isTrue);
      });

      test('默认验证钩子应该验证必需变量', () async {
        engine.registerDefaultHooks();
        final hooks = engine.hookRegistry.getHooks(HookType.preGeneration);
        final validationHook = hooks.firstWhere(
          (h) => h.name == 'default_validation',
        );

        // 测试缺少必需变量
        const context1 = HookContext(
          templateName: 'test',
          outputPath: '/test',
          variables: {},
        );
        final result1 = await validationHook.execute(context1);
        expect(result1.success, isFalse);

        // 测试包含必需变量
        const context2 = HookContext(
          templateName: 'test',
          outputPath: '/test',
          variables: {
            'module_id': 'test_module',
            'module_name': 'Test Module',
          },
        );
        final result2 = await validationHook.execute(context2);
        expect(result2.success, isTrue);
      });
    });

    group('并发生成测试', () {
      test('应该处理空任务列表', () async {
        final results = await engine.generateConcurrent(
          generationTasks: [],
        );
        expect(results, isEmpty);
      });

      test('应该处理单个任务', () async {
        final tasks = [
          {
            'templateName': 'test_template',
            'outputPath': '/test/output',
            'variables': {'module_id': 'test', 'module_name': 'Test'},
            'overwrite': false,
          }
        ];

        final results = await engine.generateConcurrent(
          generationTasks: tasks,
        );
        expect(results.length, equals(1));
        // 注意：实际模板不存在，所以会失败，但我们验证了调用结构
        expect(results.first.success, isFalse);
      });
    });

    group('缓存管理测试', () {
      test('应该清理所有缓存', () {
        // 这个测试主要验证clearCache方法不会抛出异常
        expect(() => engine.clearCache(), returnsNormally);
      });
    });
  });
}
