/*
---------------------------------------------------------------
File name:          conditional_system_test.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        条件生成系统单元测试 (Conditional System Unit Tests)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 条件生成系统测试;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/conditional/condition_evaluator.dart';
import 'package:ming_status_cli/src/core/conditional/conditional_renderer.dart';
import 'package:test/test.dart';

void main() {
  group('Condition Evaluator Tests', () {
    late ConditionEvaluator evaluator;

    setUp(() {
      evaluator = ConditionEvaluator();
    });

    test('EvaluationResult.success should create success result', () {
      final result = EvaluationResult.success(
        value: true,
        warnings: ['Minor warning'],
      );

      expect(result.success, isTrue);
      expect(result.value, isTrue);
      expect(result.warnings, hasLength(1));
      expect(result.errors, isEmpty);
    });

    test('EvaluationResult.failure should create failure result', () {
      final result = EvaluationResult.failure(
        errors: ['Evaluation failed', 'Invalid expression'],
        warnings: ['Deprecated syntax'],
      );

      expect(result.success, isFalse);
      expect(result.value, isNull);
      expect(result.errors, hasLength(2));
      expect(result.warnings, hasLength(1));
    });

    test('LiteralNode should evaluate correctly', () async {
      final node = LiteralNode(42);
      final result = await node.evaluate({});

      expect(result.success, isTrue);
      expect(result.value, equals(42));
    });

    test('VariableNode should evaluate existing variable', () async {
      final node = VariableNode('platform.mobile');
      final variables = {
        'platform': {'mobile': true, 'web': false},
      };
      final result = await node.evaluate(variables);

      expect(result.success, isTrue);
      expect(result.value, isTrue);
    });

    test('VariableNode should fail for non-existing variable', () async {
      final node = VariableNode('nonexistent.variable');
      final result = await node.evaluate({});

      expect(result.success, isFalse);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('变量未定义'));
    });

    test('BinaryOperationNode should perform AND operation', () async {
      final node = BinaryOperationNode(
        left: LiteralNode(true),
        operator: OperatorType.and,
        right: LiteralNode(false),
      );
      final result = await node.evaluate({});

      expect(result.success, isTrue);
      expect(result.value, isFalse);
    });

    test('BinaryOperationNode should perform OR operation', () async {
      final node = BinaryOperationNode(
        left: LiteralNode(true),
        operator: OperatorType.or,
        right: LiteralNode(false),
      );
      final result = await node.evaluate({});

      expect(result.success, isTrue);
      expect(result.value, isTrue);
    });

    test('BinaryOperationNode should perform comparison operations', () async {
      final greaterNode = BinaryOperationNode(
        left: LiteralNode(10),
        operator: OperatorType.greaterThan,
        right: LiteralNode(5),
      );
      final greaterResult = await greaterNode.evaluate({});

      expect(greaterResult.success, isTrue);
      expect(greaterResult.value, isTrue);

      final equalNode = BinaryOperationNode(
        left: LiteralNode(5),
        operator: OperatorType.equal,
        right: LiteralNode(5),
      );
      final equalResult = await equalNode.evaluate({});

      expect(equalResult.success, isTrue);
      expect(equalResult.value, isTrue);
    });

    test('BinaryOperationNode should perform string operations', () async {
      final containsNode = BinaryOperationNode(
        left: LiteralNode('hello world'),
        operator: OperatorType.contains,
        right: LiteralNode('world'),
      );
      final containsResult = await containsNode.evaluate({});

      expect(containsResult.success, isTrue);
      expect(containsResult.value, isTrue);

      final startsWithNode = BinaryOperationNode(
        left: LiteralNode('hello world'),
        operator: OperatorType.startsWith,
        right: LiteralNode('hello'),
      );
      final startsWithResult = await startsWithNode.evaluate({});

      expect(startsWithResult.success, isTrue);
      expect(startsWithResult.value, isTrue);
    });

    test('UnaryOperationNode should perform NOT operation', () async {
      final node = UnaryOperationNode(
        operator: OperatorType.not,
        operand: LiteralNode(true),
      );
      final result = await node.evaluate({});

      expect(result.success, isTrue);
      expect(result.value, isFalse);
    });

    test('FunctionCallNode should call version_gte function', () async {
      final node = FunctionCallNode(
        functionName: 'version_gte',
        arguments: [
          LiteralNode('3.1.0'),
          LiteralNode('3.0.0'),
        ],
      );
      final result = await node.evaluate({});

      expect(result.success, isTrue);
      expect(result.value, isTrue);
    });

    test('FunctionCallNode should call length function', () async {
      final node = FunctionCallNode(
        functionName: 'length',
        arguments: [
          LiteralNode([1, 2, 3, 4, 5]),
        ],
      );
      final result = await node.evaluate({});

      expect(result.success, isTrue);
      expect(result.value, equals(5));
    });

    test('ConditionEvaluator should evaluate simple expressions', () async {
      final variables = {'platform': 'mobile', 'version': '3.1.0'};

      final trueResult = await evaluator.evaluate('true', variables);
      expect(trueResult.success, isTrue);
      expect(trueResult.value, isTrue);

      final falseResult = await evaluator.evaluate('false', variables);
      expect(falseResult.success, isTrue);
      expect(falseResult.value, isFalse);

      final numberResult = await evaluator.evaluate('42', variables);
      expect(numberResult.success, isTrue);
      expect(numberResult.value, equals(42));

      final stringResult = await evaluator.evaluate('"hello"', variables);
      expect(stringResult.success, isTrue);
      expect(stringResult.value, equals('hello'));

      final variableResult = await evaluator.evaluate('platform', variables);
      expect(variableResult.success, isTrue);
      expect(variableResult.value, equals('mobile'));
    });

    test('ConditionEvaluator should handle safety checks', () async {
      final unsafeEvaluator = ConditionEvaluator();

      final result =
          await unsafeEvaluator.evaluate('eval("malicious code")', {});
      expect(result.success, isFalse);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('安全检查失败'));
    });
  });

  group('Conditional Renderer Tests', () {
    late ConditionalRenderer renderer;
    late ConditionEvaluator evaluator;

    setUp(() {
      evaluator = ConditionEvaluator();
      renderer = ConditionalRenderer(conditionEvaluator: evaluator);
    });

    test('RenderContext should be created correctly', () {
      const context = RenderContext(
        variables: {'platform': 'mobile', 'debug': true},
        enableDebug: true,
        enableCache: false,
        maxNestingDepth: 5,
      );

      expect(context.variables['platform'], equals('mobile'));
      expect(context.variables['debug'], isTrue);
      expect(context.enableDebug, isTrue);
      expect(context.enableCache, isFalse);
      expect(context.maxNestingDepth, equals(5));
    });

    test('ConditionalBlock should be created correctly', () {
      const block = ConditionalBlock(
        type: ConditionalBlockType.ifBlock,
        condition: 'platform.mobile',
        content: 'Mobile content',
        elseContent: 'Desktop content',
        endPosition: 50,
      );

      expect(block.type, equals(ConditionalBlockType.ifBlock));
      expect(block.condition, equals('platform.mobile'));
      expect(block.content, equals('Mobile content'));
      expect(block.elseContent, equals('Desktop content'));
      expect(block.startPosition, equals(0));
      expect(block.endPosition, equals(50));
    });

    test('RenderResult.success should create success result', () {
      final result = RenderResult.success(
        content: 'Rendered content',
        warnings: ['Minor warning'],
        debugInfo: {'blocksCount': 2},
      );

      expect(result.success, isTrue);
      expect(result.content, equals('Rendered content'));
      expect(result.warnings, hasLength(1));
      expect(result.errors, isEmpty);
      expect(result.debugInfo['blocksCount'], equals(2));
    });

    test('RenderResult.failure should create failure result', () {
      final result = RenderResult.failure(
        errors: ['Render failed', 'Invalid template'],
        content: 'Partial content',
        warnings: ['Deprecated syntax'],
      );

      expect(result.success, isFalse);
      expect(result.content, equals('Partial content'));
      expect(result.errors, hasLength(2));
      expect(result.warnings, hasLength(1));
    });

    test('ConditionalRenderer should render simple template', () async {
      const template = 'Hello {{name}}!';
      const context = RenderContext(
        variables: {'name': 'World'},
        enableCache: false,
      );

      final result = await renderer.render(template, context);

      expect(result.success, isTrue);
      expect(result.content, equals('Hello World!'));
    });

    test('ConditionalRenderer should handle if blocks', () async {
      const template = '''
{{#if platform.mobile}}
Mobile version
{{/if}}
''';
      const context = RenderContext(
        variables: {
          'platform': {'mobile': true},
        },
        enableCache: false,
      );

      final result = await renderer.render(template, context);

      expect(result.success, isTrue);
      expect(result.content, contains('Mobile version'));
    });

    test('ConditionalRenderer should handle unless blocks', () async {
      const template = '''
{{#unless platform.mobile}}
Desktop version
{{/unless}}
''';
      const context = RenderContext(
        variables: {
          'platform': {'mobile': false},
        },
        enableCache: false,
      );

      final result = await renderer.render(template, context);

      expect(result.success, isTrue);
      expect(result.content, contains('Desktop version'));
    });

    test('ConditionalRenderer should handle each blocks', () async {
      const template = '''
{{#each items}}
Item: {{this}}
{{/each}}
''';
      const context = RenderContext(
        variables: {
          'items': ['apple', 'banana', 'cherry'],
        },
        enableCache: false,
      );

      final result = await renderer.render(template, context);

      expect(result.success, isTrue);
      expect(result.content, contains('Item: apple'));
      expect(result.content, contains('Item: banana'));
      expect(result.content, contains('Item: cherry'));
    });

    test('ConditionalRenderer should handle with blocks', () async {
      const template = '''
{{#with user}}
Name: {{name}}
Age: {{age}}
{{/with}}
''';
      const context = RenderContext(
        variables: {
          'user': {'name': 'John', 'age': 30},
        },
        enableCache: false,
      );

      final result = await renderer.render(template, context);

      expect(result.success, isTrue);
      expect(result.content, contains('Name: John'));
      expect(result.content, contains('Age: 30'));
    });

    test('ConditionalRenderer should handle nested variables', () async {
      const template =
          'Platform: {{platform.name}}, Version: {{platform.version}}';
      const context = RenderContext(
        variables: {
          'platform': {
            'name': 'Flutter',
            'version': '3.16.0',
          },
        },
        enableCache: false,
      );

      final result = await renderer.render(template, context);

      expect(result.success, isTrue);
      expect(result.content, equals('Platform: Flutter, Version: 3.16.0'));
    });

    test('ConditionalRenderer should use cache when enabled', () async {
      const template = 'Hello {{name}}!';
      const context = RenderContext(
        variables: {'name': 'World'},
      );

      // First render
      final result1 = await renderer.render(template, context);
      expect(result1.success, isTrue);

      // Second render (should use cache)
      final result2 = await renderer.render(template, context);
      expect(result2.success, isTrue);
      expect(result2.content, equals(result1.content));
    });
  });
}
