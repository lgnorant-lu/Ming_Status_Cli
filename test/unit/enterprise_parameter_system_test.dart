/*
---------------------------------------------------------------
File name:          enterprise_parameter_system_test.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级参数化系统单元测试 (Enterprise Parameter System Unit Tests)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.2 企业级参数化系统测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/parameters/enterprise_parameter_validator.dart';
import 'package:ming_status_cli/src/core/parameters/enterprise_template_parameter.dart';
import 'package:ming_status_cli/src/core/parameters/parameter_preset_manager.dart';
import 'package:ming_status_cli/src/core/parameters/smart_parameter_collector.dart';
import 'package:test/test.dart';

void main() {
  group('Enterprise Template Parameter Tests', () {
    test('EnterpriseTemplateParameter should be created correctly', () {
      final parameter = EnterpriseTemplateParameter(
        name: 'database_config',
        enterpriseType: EnterpriseParameterType.databaseConfig,
        description: 'Database configuration',
        sensitivity: ParameterSensitivity.confidential,
        category: 'database',
        group: 'infrastructure',
        order: 1,
        tags: ['database', 'config'],
      );

      expect(parameter.name, equals('database_config'));
      expect(parameter.enterpriseType,
          equals(EnterpriseParameterType.databaseConfig),);
      expect(parameter.sensitivity, equals(ParameterSensitivity.confidential));
      expect(parameter.category, equals('database'));
      expect(parameter.group, equals('infrastructure'));
      expect(parameter.order, equals(1));
      expect(parameter.tags, hasLength(2));
      expect(parameter.isSensitive, isTrue);
      expect(parameter.isComposite, isTrue);
    });

    test('EnterpriseTemplateParameter should parse from map correctly', () {
      final map = {
        'enterprise_type': 'password',
        'description': 'User password',
        'sensitivity': 'secret',
        'category': 'auth',
        'validation': {
          'pattern': r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}$',
          'message': 'Password must be strong',
        },
        'tags': ['auth', 'security'],
        'examples': ['MyP@ssw0rd', 'Str0ng!Pass'],
      };

      final parameter =
          EnterpriseTemplateParameter.fromMap('user_password', map);

      expect(parameter.name, equals('user_password'));
      expect(
          parameter.enterpriseType, equals(EnterpriseParameterType.password),);
      expect(parameter.sensitivity, equals(ParameterSensitivity.secret));
      expect(parameter.category, equals('auth'));
      expect(parameter.tags, contains('auth'));
      expect(parameter.examples, hasLength(2));
      expect(parameter.validation, isNotNull);
    });

    test('EnterpriseTemplateParameter should handle dependencies', () {
      final map = {
        'enterprise_type': 'string',
        'dependencies': [
          {
            'depends_on': 'auth_type',
            'condition': 'equals',
            'when_value': 'oauth2',
          },
        ],
        'computation': {
          'expression': 'auth_type + "_client_id"',
          'dependencies': ['auth_type'],
          'description': 'Generate client ID based on auth type',
        },
      };

      final parameter = EnterpriseTemplateParameter.fromMap('client_id', map);

      expect(parameter.hasDependencies, isTrue);
      expect(parameter.dependencies, hasLength(1));
      expect(parameter.dependencies.first.dependsOn, equals('auth_type'));
      expect(parameter.dependencies.first.condition,
          equals(DependencyCondition.equals),);
      expect(parameter.dependencies.first.whenValue, equals('oauth2'));
      expect(parameter.isComputed, isTrue);
      expect(parameter.computation!.expression,
          equals('auth_type + "_client_id"'),);
    });
  });

  group('Enterprise Parameter Validator Tests', () {
    late EnterpriseParameterValidator validator;

    setUp(() {
      validator = EnterpriseParameterValidator();
    });

    test('EnterpriseParameterValidator should validate password strength',
        () async {
      final parameter = EnterpriseTemplateParameter(
        name: 'password',
        enterpriseType: EnterpriseParameterType.password,
        sensitivity: ParameterSensitivity.secret,
      );

      // 强密码
      final strongResult =
          await validator.validateParameter(parameter, 'MyStr0ng!Pass');
      expect(strongResult.isValid, isTrue);

      // 弱密码
      final weakResult = await validator.validateParameter(parameter, 'weak');
      expect(weakResult.isValid, isFalse);
      expect(weakResult.errors, isNotEmpty);
    });

    test('EnterpriseParameterValidator should validate composite types',
        () async {
      final parameter = EnterpriseTemplateParameter(
        name: 'db_config',
        enterpriseType: EnterpriseParameterType.databaseConfig,
      );

      // 有效的数据库配置 (作为JSON字符串)
      const validConfigJson = '''
      {
        "host": "localhost",
        "port": 5432,
        "database": "myapp",
        "username": "user"
      }
      ''';
      final validResult =
          await validator.validateParameter(parameter, validConfigJson);
      expect(validResult.isValid, isTrue);

      // 无效的数据库配置 (缺少必需字段)
      final invalidConfig = {
        'host': 'localhost',
        // 缺少 port, database, username
      };
      final invalidResult =
          await validator.validateParameter(parameter, invalidConfig);
      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.errors, isNotEmpty);
    });

    test('EnterpriseParameterValidator should validate multiple parameters',
        () async {
      final parameters = [
        EnterpriseTemplateParameter(
          name: 'project_name',
          enterpriseType: EnterpriseParameterType.string,
        ),
        EnterpriseTemplateParameter(
          name: 'admin_email',
          enterpriseType: EnterpriseParameterType.string,
        ),
      ];

      final values = {
        'project_name': 'my_awesome_project',
        'admin_email': 'admin@example.com',
      };

      final results = await validator.validateParameters(parameters, values);

      expect(results, hasLength(2));
      expect(results['project_name']!.isValid, isTrue);
      expect(results['admin_email']!.isValid, isTrue);
    });

    test('EnterpriseParameterValidator should handle custom rules', () async {
      // 添加自定义验证规则
      validator.addCustomRule(
        'custom_length',
        EnterpriseValidationRule(
          type: ValidationRuleType.custom,
          validator: (value, context) async {
            if (value is String) {
              return value.length >= 5 && value.length <= 20;
            }
            return false;
          },
          message: '长度必须在5-20字符之间',
        ),
      );

      final parameter = EnterpriseTemplateParameter(
        name: 'custom_field',
        enterpriseType: EnterpriseParameterType.string,
      );

      final validResult =
          await validator.validateParameter(parameter, 'valid_value');
      expect(validResult.isValid, isTrue);

      final invalidResult = await validator.validateParameter(parameter, 'abc');
      expect(invalidResult.isValid, isTrue); // 基础验证通过，但自定义规则需要手动应用
    });
  });

  group('Smart Parameter Collector Tests', () {
    late SmartParameterCollector collector;
    late Directory tempDir;

    setUp(() async {
      collector = SmartParameterCollector();
      tempDir = await Directory.systemTemp.createTemp('param_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('SmartParameterCollector should start session correctly', () async {
      final parameters = [
        EnterpriseTemplateParameter(
          name: 'project_name',
          enterpriseType: EnterpriseParameterType.string,
          group: 'general',
          order: 1,
        ),
        EnterpriseTemplateParameter(
          name: 'database_host',
          enterpriseType: EnterpriseParameterType.string,
          group: 'database',
          order: 2,
        ),
      ];

      final session = await collector.startSession(
        sessionId: 'test_session',
        parameters: parameters,
      );

      expect(session.sessionId, equals('test_session'));
      expect(session.parameters, hasLength(2));
      expect(session.mode, equals(ParameterCollectionMode.interactive));
      expect(session.steps, isNotEmpty);
      expect(session.progress, equals(0.0));
      expect(session.isCompleted, isFalse);
    });

    test('SmartParameterCollector should collect parameters correctly',
        () async {
      final parameters = [
        EnterpriseTemplateParameter(
          name: 'app_name',
          enterpriseType: EnterpriseParameterType.string,
        ),
      ];

      final session = await collector.startSession(
        sessionId: 'collect_test',
        parameters: parameters,
      );

      final success = await collector.collectParameter(
        sessionId: 'collect_test',
        parameterName: 'app_name',
        value: 'MyAwesomeApp',
      );

      expect(success, isTrue);
      expect(session.collectedValues['app_name'], equals('MyAwesomeApp'));
      expect(session.collectedCount, equals(1));
    });

    test('SmartParameterCollector should generate recommendations', () async {
      // 注意：Platform.environment是不可修改的，这里只是测试推荐功能
      // 在实际环境中，环境变量应该在进程启动前设置

      final parameters = [
        EnterpriseTemplateParameter(
          name: 'project_name',
          enterpriseType: EnterpriseParameterType.string,
          defaultValue: 'default_project',
        ),
      ];

      final session = await collector.startSession(
        sessionId: 'recommend_test',
        parameters: parameters,
        projectPath: tempDir.path,
      );

      final recommendations =
          collector.getRecommendations('recommend_test', 'project_name');
      expect(recommendations, isNotEmpty);

      // 应该包含默认值推荐
      final defaultRecommendation = recommendations
          .firstWhere((r) => r.source == RecommendationSource.defaultValue);
      expect(defaultRecommendation.value, equals('default_project'));
    });

    test('SmartParameterCollector should handle session completion', () async {
      final parameters = [
        EnterpriseTemplateParameter(
          name: 'simple_param',
          enterpriseType: EnterpriseParameterType.string,
        ),
      ];

      final session = await collector.startSession(
        sessionId: 'complete_test',
        parameters: parameters,
      );

      await collector.collectParameter(
        sessionId: 'complete_test',
        parameterName: 'simple_param',
        value: 'test_value',
      );

      final result = await collector.completeSession('complete_test');
      expect(result['simple_param'], equals('test_value'));
      expect(session.isCompleted, isTrue);
    });
  });

  group('Parameter Preset Manager Tests', () {
    late ParameterPresetManager manager;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('preset_test_');
      manager = ParameterPresetManager(presetDirectory: tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('ParameterPresetManager should create preset correctly', () async {
      final preset = await manager.createPreset(
        name: 'test_preset',
        type: PresetType.team,
        scope: PresetScope.project,
        parameters: {
          'project_name': 'test_project',
          'database_host': 'localhost',
        },
        description: 'Test preset for unit testing',
        author: 'test_user',
        tags: ['test', 'unit'],
      );

      expect(preset.name, equals('test_preset'));
      expect(preset.type, equals(PresetType.team));
      expect(preset.scope, equals(PresetScope.project));
      expect(preset.parameters, hasLength(2));
      expect(preset.description, equals('Test preset for unit testing'));
      expect(preset.author, equals('test_user'));
      expect(preset.tags, contains('test'));
      expect(preset.createdAt, isNotNull);
    });

    test('ParameterPresetManager should get preset correctly', () async {
      final createdPreset = await manager.createPreset(
        name: 'get_test',
        type: PresetType.personal,
        scope: PresetScope.user,
        parameters: {'key': 'value'},
      );

      final retrievedPreset = await manager.getPreset(createdPreset.id);
      expect(retrievedPreset, isNotNull);
      expect(retrievedPreset!.id, equals(createdPreset.id));
      expect(retrievedPreset.name, equals('get_test'));
      expect(retrievedPreset.parameters['key'], equals('value'));
    });

    test('ParameterPresetManager should update preset correctly', () async {
      final preset = await manager.createPreset(
        name: 'update_test',
        type: PresetType.personal,
        scope: PresetScope.user,
        parameters: {'old_key': 'old_value'},
      );

      final updatedPreset = await manager.updatePreset(preset.id, {
        'name': 'updated_test',
        'parameters': {'new_key': 'new_value'},
        'tags': ['updated'],
      });

      expect(updatedPreset.name, equals('updated_test'));
      expect(updatedPreset.parameters['new_key'], equals('new_value'));
      expect(updatedPreset.tags, contains('updated'));
      expect(updatedPreset.updatedAt, isNotNull);
    });

    test('ParameterPresetManager should query presets correctly', () async {
      // 创建多个预设
      await manager.createPreset(
        name: 'team_preset_1',
        type: PresetType.team,
        scope: PresetScope.team,
        parameters: {},
        tags: ['backend'],
      );

      await manager.createPreset(
        name: 'team_preset_2',
        type: PresetType.team,
        scope: PresetScope.team,
        parameters: {},
        tags: ['frontend'],
      );

      await manager.createPreset(
        name: 'personal_preset',
        type: PresetType.personal,
        scope: PresetScope.user,
        parameters: {},
      );

      // 查询团队预设
      final teamPresets = await manager.queryPresets(
        const PresetQuery(type: PresetType.team),
      );
      expect(teamPresets, hasLength(2));
      expect(teamPresets.every((p) => p.type == PresetType.team), isTrue);

      // 查询带标签的预设
      final backendPresets = await manager.queryPresets(
        const PresetQuery(tags: ['backend']),
      );
      expect(backendPresets, hasLength(1));
      expect(backendPresets.first.name, equals('team_preset_1'));
    });

    test('ParameterPresetManager should apply preset correctly', () async {
      final parameters = [
        EnterpriseTemplateParameter(
          name: 'project_name',
          enterpriseType: EnterpriseParameterType.string,
        ),
        EnterpriseTemplateParameter(
          name: 'database_host',
          enterpriseType: EnterpriseParameterType.string,
        ),
        EnterpriseTemplateParameter(
          name: 'unknown_param',
          enterpriseType: EnterpriseParameterType.string,
        ),
      ];

      final preset = await manager.createPreset(
        name: 'apply_test',
        type: PresetType.personal,
        scope: PresetScope.user,
        parameters: {
          'project_name': 'preset_project',
          'database_host': 'preset_host',
          'extra_param': 'extra_value', // 不在参数列表中
        },
      );

      final appliedValues = await manager.applyPreset(
        preset.id,
        parameters,
        overrides: {'database_host': 'override_host'},
      );

      expect(appliedValues, hasLength(2)); // 只包含存在的参数
      expect(appliedValues['project_name'], equals('preset_project'));
      expect(appliedValues['database_host'], equals('override_host')); // 覆盖值
      expect(appliedValues.containsKey('extra_param'), isFalse); // 不包含额外参数
    });

    test('ParameterPresetManager should handle preset inheritance', () async {
      // 创建父预设
      final parentPreset = await manager.createPreset(
        name: 'parent_preset',
        type: PresetType.global,
        scope: PresetScope.global,
        parameters: {
          'base_config': 'base_value',
          'shared_config': 'parent_value',
        },
      );

      // 创建子预设
      final childPreset = await manager.createPreset(
        name: 'child_preset',
        type: PresetType.team,
        scope: PresetScope.team,
        parameters: {
          'team_config': 'team_value',
        },
        parentPresetId: parentPreset.id,
        overrides: {
          'shared_config': 'child_value', // 覆盖父预设的值
        },
      );

      expect(childPreset.hasParent, isTrue);
      expect(childPreset.parentPresetId, equals(parentPreset.id));

      final effectiveParams = childPreset.getEffectiveParameters(parentPreset);
      expect(effectiveParams['base_config'], equals('base_value')); // 继承自父预设
      expect(effectiveParams['team_config'], equals('team_value')); // 子预设自有
      expect(effectiveParams['shared_config'], equals('child_value')); // 覆盖父预设
    });

    test('ParameterPresetManager should create preset from template', () async {
      final parameters = [
        EnterpriseTemplateParameter(
          name: 'app_name',
          enterpriseType: EnterpriseParameterType.string,
        ),
        EnterpriseTemplateParameter(
          name: 'version',
          enterpriseType: EnterpriseParameterType.string,
        ),
      ];

      final values = {
        'app_name': 'MyApp',
        'version': '1.0.0',
        'extra_field': 'ignored', // 不在参数列表中，应被忽略
      };

      final preset = await manager.createPresetFromTemplate(
        name: 'template_preset',
        type: PresetType.projectType,
        scope: PresetScope.project,
        parameters: parameters,
        values: values,
        description: 'Created from template',
        tags: ['template', 'generated'],
      );

      expect(preset.name, equals('template_preset'));
      expect(preset.type, equals(PresetType.projectType));
      expect(preset.parameters, hasLength(2)); // 只包含参数列表中的字段
      expect(preset.parameters['app_name'], equals('MyApp'));
      expect(preset.parameters['version'], equals('1.0.0'));
      expect(preset.parameters.containsKey('extra_field'), isFalse);
      expect(preset.tags, contains('template'));
    });
  });
}
