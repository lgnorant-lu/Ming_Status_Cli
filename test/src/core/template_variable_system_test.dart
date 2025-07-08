/*
---------------------------------------------------------------
File name:          template_variable_system_test.dart
Author:             lgnorant-lu
Date created:       2025/06/30
Last modified:      2025/06/30
Dart Version:       3.2+
Description:        模板变量系统测试 (Template variable system tests)
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/template_engine.dart';
import 'package:ming_status_cli/src/core/template_parameter_system.dart';
import 'package:ming_status_cli/src/core/template_variable_processor.dart';
import 'package:ming_status_cli/src/models/template_variable.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('模板变量系统测试', () {
    late Directory tempDir;
    late TemplateEngine templateEngine;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('template_variable_test');
      templateEngine = TemplateEngine(workingDirectory: tempDir.path);
    });

    tearDownAll(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('TemplateVariable 类测试', () {
      test('应该正确创建字符串变量', () {
        final variable = TemplateVariable.fromMap('test_var', {
          'type': 'string',
          'description': '测试变量',
          'default': 'default_value',
          'prompt': '请输入测试值',
        });

        expect(variable.name, equals('test_var'));
        expect(variable.type, equals(TemplateVariableType.string));
        expect(variable.description, equals('测试变量'));
        expect(variable.defaultValue, equals('default_value'));
        expect(variable.prompt, equals('请输入测试值'));
        expect(variable.optional, isFalse);
      });

      test('应该正确创建带验证的变量', () {
        final variable = TemplateVariable.fromMap('email_var', {
          'type': 'string',
          'validation': {
            'pattern': r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            'message': '请输入有效的邮箱地址',
          },
        });

        expect(variable.validation, isNotNull);
        expect(variable.validation!.pattern, isNotNull);
        expect(variable.validation!.message, equals('请输入有效的邮箱地址'));
      });

      test('应该正确验证变量值', () {
        final variable = TemplateVariable.fromMap('age_var', {
          'type': 'number',
          'validation': {
            'min_value': 0,
            'max_value': 120,
          },
        });

        // 有效值
        final validResult = variable.validateValue(25);
        expect(validResult.isValid, isTrue);

        // 无效值（超出范围）
        final invalidResult = variable.validateValue(150);
        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.errors.length, greaterThan(0));
      });

      test('应该正确处理枚举类型', () {
        final variable = TemplateVariable.fromMap('platform_var', {
          'type': 'enum',
          'values': ['android', 'ios', 'web'],
          'default': 'android',
        });

        expect(variable.type, equals(TemplateVariableType.enumeration));
        expect(variable.values, equals(['android', 'ios', 'web']));

        // 有效值
        final validResult = variable.validateValue('ios');
        expect(validResult.isValid, isTrue);

        // 无效值
        final invalidResult = variable.validateValue('windows');
        expect(invalidResult.isValid, isFalse);
      });
    });

    group('TemplateVariableProcessor 类测试', () {
      test('应该正确处理标准派生变量', () {
        final processor = TemplateVariableProcessor();
        final variables = {'module_name': 'UserManager'};
        final definitions = [
          TemplateVariable.fromMap('module_name', {'type': 'string'}),
        ];

        final result = processor.processVariables(
          variables: variables,
          variableDefinitions: definitions,
        );

        expect(
          result.success,
          isTrue,
        );
        expect(
          result.variables['module_name_snake_case'],
          equals('user_manager'),
        );
        expect(
          result.variables['module_name_pascal_case'],
          equals('UserManager'),
        );
        expect(
          result.variables['module_name_camel_case'],
          equals('userManager'),
        );
        expect(
          result.variables['module_name_kebab_case'],
          equals('user-manager'),
        );
      });

      test('应该生成时间戳变量', () {
        final processor = TemplateVariableProcessor();
        final result = processor.processVariables(
          variables: {},
          variableDefinitions: [],
        );

        expect(result.success, isTrue);
        expect(result.variables.containsKey('generated_date'), isTrue);
        expect(result.variables.containsKey('generated_time'), isTrue);
        expect(result.variables.containsKey('generated_year'), isTrue);
      });

      test('应该正确进行变量插值', () {
        final processor = TemplateVariableProcessor();
        const template = '模块名称: {{module_name}}, 文件名: {{file_name}}';
        final variables = {
          'module_name': 'TestModule',
          'file_name': 'test_module.dart',
        };

        final result = processor.interpolateVariables(template, variables);
        expect(result, equals('模块名称: TestModule, 文件名: test_module.dart'));
      });

      test('应该处理条件插值', () {
        final processor = TemplateVariableProcessor();
        const template = '{{#if include_tests}}包含测试文件{{/if}}';

        // 条件为真
        final resultTrue = processor.interpolateVariables(
          template,
          {'include_tests': true},
        );
        expect(resultTrue, equals('包含测试文件'));

        // 条件为假
        final resultFalse = processor.interpolateVariables(
          template,
          {'include_tests': false},
        );
        expect(resultFalse, equals(''));
      });
    });

    group('TemplateParameterSystem 类测试', () {
      test('应该正确加载brick.yaml变量定义', () {
        final parameterSystem = TemplateParameterSystem();
        final brickData = {
          'name': 'test_template',
          'vars': {
            'module_name': {
              'type': 'string',
              'description': '模块名称',
              'prompt': '请输入模块名称',
            },
            'include_docs': {
              'type': 'boolean',
              'default': false,
              'optional': true,
            },
          },
        };

        parameterSystem.loadFromBrickYaml(brickData);

        expect(parameterSystem.variableCount, equals(2));
        expect(parameterSystem.hasVariables, isTrue);

        final moduleVar = parameterSystem.getVariableDefinition('module_name');
        expect(moduleVar, isNotNull);
        expect(moduleVar!.type, equals(TemplateVariableType.string));
      });

      test('应该正确验证变量值集合', () {
        final parameterSystem = TemplateParameterSystem()
          ..loadFromBrickYaml({
            'vars': {
              'name': {'type': 'string'},
              'version': {
                'type': 'string',
                'default': '1.0.0',
                'optional': true,
              },
            },
          });

        final result = parameterSystem.validateVariables({
          'name': 'TestModule',
          'version': '2.0.0',
        });

        expect(result.isValid, isTrue);
        expect(result.validatedVariables['name'], equals('TestModule'));
        expect(result.validatedVariables['version'], equals('2.0.0'));
      });

      test('应该处理变量并生成派生变量', () {
        final parameterSystem = TemplateParameterSystem()
          ..loadFromBrickYaml({
            'vars': {
              'module_name': {'type': 'string'},
            },
          });

        final result = parameterSystem.processVariables({
          'module_name': 'UserService',
        });

        expect(result.success, isTrue);
        expect(
          result.processedVariables['module_name'],
          equals('UserService'),
        );
        expect(
          result.generatedVariables.containsKey('module_name_snake_case'),
          isTrue,
        );
        expect(
          result.generatedVariables['module_name_snake_case'],
          equals('user_service'),
        );
      });
    });

    group('TemplateEngine 集成测试', () {
      setUp(() async {
        // 创建测试模板
        final templateDir = Directory(
          path.join(tempDir.path, 'templates', 'test_template'),
        );
        await templateDir.create(recursive: true);

        // 创建brick.yaml
        final brickFile = File(path.join(templateDir.path, 'brick.yaml'));
        await brickFile.writeAsString('''
name: test_template
description: 测试模板
version: 1.0.0

vars:
  module_name:
    type: string
    description: 模块名称
    prompt: 请输入模块名称
  author:
    type: string
    description: 作者名称
    default: lgnorant-lu
    optional: true
  include_tests:
    type: boolean
    description: 是否包含测试
    default: true
    optional: true
''');

        // 创建__brick__目录和模板文件
        final brickDir = Directory(path.join(templateDir.path, '__brick__'));
        await brickDir.create();

        final templateFile = File(
          path.join(brickDir.path, '{{module_name}}.dart'),
        );
        await templateFile.writeAsString('''
/// {{module_name}} 模块
/// 作者: {{author}}
class {{module_name}} {
  static const String moduleName = '{{module_name}}';
  
  void initialize() {
    // 初始化逻辑
  }
}
''');
      });

      test('应该成功获取模板参数系统', () async {
        final parameterSystem =
            await templateEngine.getParameterSystem('test_template');

        expect(parameterSystem.variableCount, equals(3));
        expect(parameterSystem.hasVariables, isTrue);

        final moduleVar = parameterSystem.getVariableDefinition('module_name');
        expect(moduleVar, isNotNull);
        expect(moduleVar!.name, equals('module_name'));
        expect(moduleVar.type, equals(TemplateVariableType.string));
      });

      test('应该成功处理模板变量', () async {
        final result = await templateEngine.processTemplateVariables(
          'test_template',
          {'module_name': 'TestService'},
        );

        expect(result.success, isTrue);
        expect(
          result.processedVariables['module_name'],
          equals('TestService'),
        );
        expect(
          result.processedVariables['author'],
          equals('lgnorant-lu'),
        ); // 默认值
        expect(
          result.generatedVariables.containsKey('module_name_snake_case'),
          isTrue,
        );
      });

      test('应该正确获取模板默认值', () async {
        final defaults =
            await templateEngine.getTemplateDefaultValues('test_template');

        expect(defaults['author'], equals('lgnorant-lu'));
        expect(defaults['include_tests'], equals(true));
        expect(defaults.containsKey('module_name'), isFalse); // 无默认值
      });

      test('应该正确获取模板提示信息', () async {
        final prompts =
            await templateEngine.getTemplatePrompts('test_template');

        expect(prompts['module_name'], equals('请输入模块名称'));
        expect(prompts.containsKey('author'), isFalse); // 无提示
      });

      test('应该正确验证模板变量', () async {
        final result = await templateEngine.validateTemplateVariablesWithSystem(
          'test_template',
          {
            'module_name': 'ValidModule',
            'author': 'TestAuthor',
            'include_tests': true,
          },
        );

        expect(result.isValid, isTrue);
        expect(result.errors.isEmpty, isTrue);
      });

      test('应该生成变量摘要', () async {
        final summary =
            await templateEngine.getTemplateVariableSummary('test_template');

        expect(summary['total_variables'], equals(3));
        expect(summary['required_variables'], equals(1)); // 只有module_name是必需的
        expect(summary['optional_variables'], equals(2));
        expect(summary['variables_with_defaults'], equals(2));
      });
    });

    group('错误处理测试', () {
      test('应该处理不存在的模板', () async {
        final future =
            templateEngine.getParameterSystem('non_existent_template');
        expect(future, throwsA(isA<Exception>()));
      });

      test('应该处理无效的变量值', () async {
        final parameterSystem = TemplateParameterSystem()
          ..loadFromBrickYaml({
            'vars': {
              'required_field': {'type': 'string'}, // 必需字段
            },
          });

        final result = parameterSystem.validateVariables({
          // 缺少required_field
        });

        expect(result.isValid, isFalse);
        expect(result.errors.isNotEmpty, isTrue);
      });

      test('变量处理器应该处理无效输入', () {
        final processor = TemplateVariableProcessor();
        final result = processor.processVariables(
          variables: {'invalid_type': null},
          variableDefinitions: [
            TemplateVariable.fromMap('required_var', {
              'type': 'string',
              'validation': {'required': true},
            }),
          ],
        );

        expect(result.success, isFalse);
        expect(result.errors.isNotEmpty, isTrue);
      });
    });
  });
}
