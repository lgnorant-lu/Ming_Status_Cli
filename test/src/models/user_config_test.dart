/*
---------------------------------------------------------------
File name:          user_config_test.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Python Version:     3.x
Description:        用户配置数据模型的完整单元测试
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 用户配置系统单元测试;
---------------------------------------------------------------
*/

import 'package:test/test.dart';
import 'package:ming_status_cli/src/models/user_config.dart';
import 'dart:convert';

void main() {
  group('UserInfo Tests', () {
    test('should create UserInfo with default values', () {
      const userInfo = UserInfo(name: '');

      expect(userInfo.name, equals(''));
      expect(userInfo.email, equals(''));
      expect(userInfo.company, equals(''));
    });

    test('should create UserInfo with custom values', () {
      const userInfo = UserInfo(
        name: '张三',
        email: 'zhangsan@example.com',
        company: '示例公司',
      );

      expect(userInfo.name, equals('张三'));
      expect(userInfo.email, equals('zhangsan@example.com'));
      expect(userInfo.company, equals('示例公司'));
    });

    test('should serialize to JSON correctly', () {
      const userInfo = UserInfo(
        name: '李四',
        email: 'lisi@test.com',
        company: '测试科技',
      );

      final json = userInfo.toJson();
      expect(json['name'], equals('李四'));
      expect(json['email'], equals('lisi@test.com'));
      expect(json['company'], equals('测试科技'));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'name': '王五',
        'email': 'wangwu@demo.org',
        'company': '演示企业',
      };

      final userInfo = UserInfo.fromJson(json);
      expect(userInfo.name, equals('王五'));
      expect(userInfo.email, equals('wangwu@demo.org'));
      expect(userInfo.company, equals('演示企业'));
    });

    test('should handle partial JSON data', () {
      final json = {'name': '赵六'};

      final userInfo = UserInfo.fromJson(json);
      expect(userInfo.name, equals('赵六'));
      expect(userInfo.email, equals(''));
      expect(userInfo.company, equals(''));
    });

    test('should support copyWith functionality', () {
      const original = UserInfo(
        name: '原始用户',
        email: 'original@test.com',
        company: '原始公司',
      );

      final updated = original.copyWith(
        name: '更新用户',
        email: 'updated@test.com',
      );

      expect(updated.name, equals('更新用户'));
      expect(updated.email, equals('updated@test.com'));
      expect(updated.company, equals('原始公司')); // 保持不变
    });
  });

  group('UserPreferences Tests', () {
    test('should create UserPreferences with default values', () {
      const preferences = UserPreferences();

      expect(preferences.defaultTemplate, equals('basic'));
      expect(preferences.coloredOutput, equals(true));
      expect(preferences.autoUpdateCheck, equals(true));
      expect(preferences.verboseLogging, equals(false));
      expect(preferences.preferredIde, equals('vscode'));
    });

    test('should create UserPreferences with custom values', () {
      const preferences = UserPreferences(
        defaultTemplate: 'enterprise',
        coloredOutput: false,
        autoUpdateCheck: false,
        verboseLogging: true,
        preferredIde: 'idea',
      );

      expect(preferences.defaultTemplate, equals('enterprise'));
      expect(preferences.coloredOutput, equals(false));
      expect(preferences.autoUpdateCheck, equals(false));
      expect(preferences.verboseLogging, equals(true));
      expect(preferences.preferredIde, equals('idea'));
    });

    test('should serialize and deserialize correctly', () {
      const original = UserPreferences(
        defaultTemplate: 'team',
        autoUpdateCheck: false,
        verboseLogging: true,
      );

      final json = original.toJson();
      final deserialized = UserPreferences.fromJson(json);

      expect(deserialized.defaultTemplate, equals(original.defaultTemplate));
      expect(deserialized.coloredOutput, equals(original.coloredOutput));
      expect(deserialized.autoUpdateCheck, equals(original.autoUpdateCheck));
      expect(deserialized.verboseLogging, equals(original.verboseLogging));
      expect(deserialized.preferredIde, equals(original.preferredIde));
    });

    test('should support copyWith functionality', () {
      const original = UserPreferences();

      final updated = original.copyWith(
        defaultTemplate: 'custom',
        verboseLogging: true,
      );

      expect(updated.defaultTemplate, equals('custom'));
      expect(updated.verboseLogging, equals(true));
      expect(updated.coloredOutput, equals(true)); // 保持原值
      expect(updated.autoUpdateCheck, equals(true)); // 保持原值
    });
  });

  group('UserDefaults Tests', () {
    test('should create UserDefaults with appropriate defaults', () {
      const defaults = UserDefaults(
        author: '',
        license: 'MIT',
        dartVersion: '^3.2.0',
      );

      expect(defaults.author, equals(''));
      expect(defaults.license, equals('MIT'));
      expect(defaults.dartVersion, equals('^3.2.0'));
      expect(defaults.description,
          equals('A Flutter module created by Ming Status CLI'),);
    });

    test('should create UserDefaults with custom values', () {
      const defaults = UserDefaults(
        author: '开发者',
        license: 'Apache-2.0',
        dartVersion: '^3.3.0',
        description: '自定义Flutter模块描述',
      );

      expect(defaults.author, equals('开发者'));
      expect(defaults.license, equals('Apache-2.0'));
      expect(defaults.dartVersion, equals('^3.3.0'));
      expect(defaults.description, equals('自定义Flutter模块描述'));
    });

    test('should validate license values', () {
      // 测试常见的开源许可证
      final validLicenses = ['MIT', 'Apache-2.0', 'GPL-3.0', 'BSD-3-Clause'];

      for (final license in validLicenses) {
        final defaults = UserDefaults(
            author: 'Test', license: license, dartVersion: '^3.2.0',);
        expect(defaults.license, equals(license));
      }
    });

    test('should validate Dart version format', () {
      final validVersions = ['^3.2.0', '>=3.1.0 <4.0.0', '^3.3.0'];

      for (final version in validVersions) {
        final defaults =
            UserDefaults(author: 'Test', license: 'MIT', dartVersion: version);
        expect(defaults.dartVersion, equals(version));
      }
    });
  });

  group('SecuritySettings Tests', () {
    test('should create SecuritySettings with secure defaults', () {
      const security = SecuritySettings();

      expect(security.encryptedCredentials, equals(false));
      expect(security.strictPermissions, equals(true));
    });

    test('should allow custom security settings', () {
      const security = SecuritySettings(
        encryptedCredentials: true,
        strictPermissions: false,
      );

      expect(security.encryptedCredentials, equals(true));
      expect(security.strictPermissions, equals(false));
    });

    test('should serialize security settings', () {
      const security = SecuritySettings(
        encryptedCredentials: true,
        strictPermissions: false,
      );

      final json = security.toJson();
      expect(json['encryptedCredentials'], equals(true));
      expect(json['strictPermissions'], equals(false));
    });
  });

  group('UserConfig Integration Tests', () {
    test('should create complete UserConfig with all components', () {
      const userConfig = UserConfig(
        user: UserInfo(
          name: '完整测试用户',
          email: 'complete@test.com',
          company: '测试公司',
        ),
        preferences: UserPreferences(
          defaultTemplate: 'enterprise',
          autoUpdateCheck: false,
          verboseLogging: true,
          preferredIde: 'idea',
        ),
        defaults: UserDefaults(
          author: '测试作者',
          license: 'Apache-2.0',
          dartVersion: '^3.3.0',
          description: '完整测试模块',
        ),
        security: SecuritySettings(
          encryptedCredentials: true,
        ),
      );

      expect(userConfig.user.name, equals('完整测试用户'));
      expect(userConfig.preferences.defaultTemplate, equals('enterprise'));
      expect(userConfig.defaults.license, equals('Apache-2.0'));
      expect(userConfig.security?.encryptedCredentials, equals(true));
    });

    test('should create UserConfig with defaults', () {
      final userConfig = UserConfig.defaultConfig();

      expect(userConfig.user.name, equals('开发者名称'));
      expect(userConfig.preferences.defaultTemplate, equals('basic'));
      expect(userConfig.defaults.license, equals('MIT'));
      expect(userConfig.security?.encryptedCredentials, equals(false));
    });

    test('should perform complete JSON roundtrip', () {
      const original = UserConfig(
        user: UserInfo(
          name: 'JSON测试用户',
          email: 'json@test.com',
          company: 'JSON公司',
        ),
        preferences: UserPreferences(
          defaultTemplate: 'team',
          coloredOutput: false,
        ),
        defaults: UserDefaults(
          author: 'JSON作者',
          license: 'GPL-3.0',
          dartVersion: '^3.2.5',
          description: 'JSON序列化测试模块',
        ),
        security: SecuritySettings(
          
        ),
      );

      // 序列化到JSON
      final jsonString = jsonEncode(original.toJson());

      // 从JSON反序列化
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final deserialized = UserConfig.fromJson(jsonData);

      // 验证所有字段
      expect(deserialized.user.name, equals(original.user.name));
      expect(deserialized.user.email, equals(original.user.email));
      expect(deserialized.user.company, equals(original.user.company));

      expect(deserialized.preferences.defaultTemplate,
          equals(original.preferences.defaultTemplate),);
      expect(deserialized.preferences.coloredOutput,
          equals(original.preferences.coloredOutput),);
      expect(deserialized.preferences.autoUpdateCheck,
          equals(original.preferences.autoUpdateCheck),);
      expect(deserialized.preferences.verboseLogging,
          equals(original.preferences.verboseLogging),);
      expect(deserialized.preferences.preferredIde,
          equals(original.preferences.preferredIde),);

      expect(deserialized.defaults.author, equals(original.defaults.author));
      expect(deserialized.defaults.license, equals(original.defaults.license));
      expect(deserialized.defaults.dartVersion,
          equals(original.defaults.dartVersion),);
      expect(deserialized.defaults.description,
          equals(original.defaults.description),);

      expect(deserialized.security?.encryptedCredentials,
          equals(original.security?.encryptedCredentials),);
      expect(deserialized.security?.strictPermissions,
          equals(original.security?.strictPermissions),);
    });

    test('should support copyWith for complete config updates', () {
      final original = UserConfig.defaultConfig();

      final updated = original.copyWith(
        user: const UserInfo(name: '更新用户'),
        preferences: const UserPreferences(defaultTemplate: 'enterprise'),
      );

      expect(updated.user.name, equals('更新用户'));
      expect(updated.preferences.defaultTemplate, equals('enterprise'));
      // 其他字段保持默认值
      expect(updated.defaults.license, equals('MIT'));
      expect(updated.security?.encryptedCredentials, equals(false));
    });

    test('should handle malformed JSON gracefully', () {
      // 测试部分JSON数据
      final partialJson = {
        'user': {'name': '部分用户'},
        'preferences': {'defaultTemplate': 'basic'},
        // 缺少defaults和security
      };

      final userConfig = UserConfig.fromJson(partialJson);

      expect(userConfig.user.name, equals('部分用户'));
      expect(userConfig.preferences.defaultTemplate, equals('basic'));
      expect(userConfig.defaults.license, equals('MIT')); // 应该使用默认值
      expect(
          userConfig.security?.encryptedCredentials, isNull,); // security字段为null
    });

    test('should handle empty JSON gracefully', () {
      final emptyJson = <String, dynamic>{};

      final userConfig = UserConfig.fromJson(emptyJson);

      // 所有字段都应该使用默认值
      expect(userConfig.user.name, isNotNull);
      expect(userConfig.preferences.defaultTemplate, isNotNull);
      expect(userConfig.defaults.license, isNotNull);
      expect(userConfig.security, isNull); // security字段可能为null
    });
  });

  group('UserConfig Edge Cases', () {
    test('should handle null values in JSON', () {
      final jsonWithNulls = {
        'user': null,
        'preferences': {'defaultTemplate': null},
        'defaults': {'license': null},
        'security': null,
      };

      final userConfig = UserConfig.fromJson(jsonWithNulls);

      // 应该优雅地处理null值，使用默认值或null
      expect(userConfig.user.name, isNotNull);
      expect(userConfig.preferences.defaultTemplate, isNotNull);
      expect(userConfig.defaults.license, isNotNull);
      expect(userConfig.security, isNull);
    });

    test('should validate configuration consistency', () {
      const config = UserConfig(
        user: UserInfo(name: 'TestUser'),
        preferences: UserPreferences(),
        defaults: UserDefaults(
            author: 'TestUser', license: 'MIT', dartVersion: '^3.2.0',),
      );

      expect(config.user.name, equals('TestUser'));
      expect(config.defaults.author, equals('TestUser'));
    });

    test('should support configuration templates integration', () {
      // 测试与配置模板的集成
      const basicConfig = UserConfig(
        user: UserInfo(name: 'BasicUser'),
        preferences: UserPreferences(),
        defaults: UserDefaults(
            author: 'BasicUser', license: 'MIT', dartVersion: '^3.2.0',),
      );

      const enterpriseConfig = UserConfig(
        user: UserInfo(name: 'EnterpriseUser'),
        preferences: UserPreferences(defaultTemplate: 'enterprise'),
        defaults: UserDefaults(
            author: 'EnterpriseUser', license: 'MIT', dartVersion: '^3.2.0',),
        security: SecuritySettings(),
      );

      expect(basicConfig.preferences.defaultTemplate, equals('basic'));
      expect(
          enterpriseConfig.preferences.defaultTemplate, equals('enterprise'),);
      expect(enterpriseConfig.security?.strictPermissions, equals(true));
    });
  });
}
