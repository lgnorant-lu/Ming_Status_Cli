/*
---------------------------------------------------------------
File name:          scaffold_config_test.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        ScaffoldConfig类测试文件 (ScaffoldConfig Class Tests)
---------------------------------------------------------------
Change History:
    2025/07/12: Initial creation - 配置类测试;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:test/test.dart';

void main() {
  group('ScaffoldConfig', () {
    late ScaffoldConfig config;

    setUp(() {
      config = const ScaffoldConfig(
        templateName: 'test_project',
        templateType: TemplateType.full,
        author: 'Test Author',
        description: 'Test Description',
        framework: TemplateFramework.flutter,
        complexity: TemplateComplexity.medium,
      );
    });

    test('should create config with required parameters', () {
      expect(config.templateName, equals('test_project'));
      expect(config.templateType, equals(TemplateType.full));
      expect(config.author, equals('Test Author'));
      expect(config.description, equals('Test Description'));
    });

    test('should have default values for optional parameters', () {
      expect(config.version, equals('1.0.0'));
      expect(config.outputPath, equals('.'));
      expect(config.includeTests, isTrue);
      expect(config.includeDocumentation, isTrue);
      expect(config.includeExamples, isTrue);
      expect(config.enableGitInit, isTrue);
    });

    test('should create copy with modified parameters', () {
      final newConfig = config.copyWith(
        templateName: 'new_project',
        version: '2.0.0',
        includeTests: false,
      );

      expect(newConfig.templateName, equals('new_project'));
      expect(newConfig.version, equals('2.0.0'));
      expect(newConfig.includeTests, isFalse);
      // 其他参数应该保持不变
      expect(newConfig.author, equals('Test Author'));
      expect(newConfig.description, equals('Test Description'));
      expect(newConfig.includeDocumentation, isTrue);
    });

    test('should convert to map correctly', () {
      final map = config.toMap();

      expect(map['templateName'], equals('test_project'));
      expect(map['templateType'], equals('full'));
      expect(map['author'], equals('Test Author'));
      expect(map['description'], equals('Test Description'));
      expect(map['version'], equals('1.0.0'));
      expect(map['platform'], equals('crossPlatform'));
      expect(map['framework'], equals('flutter'));
      expect(map['complexity'], equals('medium'));
      expect(map['maturity'], equals('development'));
    });

    test('should create from map correctly', () {
      final map = {
        'templateName': 'map_project',
        'templateType': 'basic',
        'author': 'Map Author',
        'description': 'Map Description',
        'version': '3.0.0',
        'platform': 'mobile',
        'framework': 'dart',
        'complexity': 'simple',
        'maturity': 'stable',
        'includeTests': false,
        'includeDocumentation': false,
      };

      final configFromMap = ScaffoldConfig.fromMap(map);

      expect(configFromMap.templateName, equals('map_project'));
      expect(configFromMap.templateType, equals(TemplateType.basic));
      expect(configFromMap.author, equals('Map Author'));
      expect(configFromMap.description, equals('Map Description'));
      expect(configFromMap.version, equals('3.0.0'));
      expect(configFromMap.platform, equals(TemplatePlatform.mobile));
      expect(configFromMap.framework, equals(TemplateFramework.dart));
      expect(configFromMap.complexity, equals(TemplateComplexity.simple));
      expect(configFromMap.maturity, equals(TemplateMaturity.stable));
      expect(configFromMap.includeTests, isFalse);
      expect(configFromMap.includeDocumentation, isFalse);
    });

    test('should handle equality correctly', () {
      const config1 = ScaffoldConfig(
        templateName: 'test',
        templateType: TemplateType.basic,
        author: 'Author',
        description: 'Description',
      );

      const config2 = ScaffoldConfig(
        templateName: 'test',
        templateType: TemplateType.basic,
        author: 'Author',
        description: 'Description',
      );

      const config3 = ScaffoldConfig(
        templateName: 'different',
        templateType: TemplateType.basic,
        author: 'Author',
        description: 'Description',
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should have meaningful toString', () {
      final str = config.toString();
      expect(str, contains('ScaffoldConfig'));
      expect(str, contains('test_project'));
      expect(str, contains('full'));
      expect(str, contains('flutter'));
      expect(str, contains('crossPlatform'));
    });
  });
}
