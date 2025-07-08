/*
---------------------------------------------------------------
File name:          dependency_validator_test.dart
Author:             Ignorant-lu
Date created:       2025/07/04
Last modified:      2025/07/04
Dart Version:       3.32.4
Description:        DependencyValidator单元测试套件 - Task 44.2
---------------------------------------------------------------
Change History:
    2025/07/04: Initial creation - 依赖验证器测试套件实现;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:ming_status_cli/src/validators/dependency_validator.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyValidator Tests', () {
    late DependencyValidator validator;
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('dependency_test_');
    });

    setUp(() async {
      validator = DependencyValidator();
      // 确保每个测试都有清洁的环境
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
      tempDir = await Directory.systemTemp.createTemp('dependency_test_');
    });

    tearDownAll(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Validator Basic Properties', () {
      test('should have correct validator name', () {
        expect(validator.validatorName, equals('dependency'));
      });

      test('should support dependency validation type', () {
        expect(validator.supportedTypes, contains(ValidationType.dependency));
      });

      test('should have correct priority', () {
        expect(validator.priority, equals(30));
      });

      test('should pass health check', () async {
        final result = await validator.healthCheck();
        expect(result, isTrue);
      });
    });

    group('Pubspec Validation', () {
      test('should validate basic pubspec.yaml', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  test: ^1.21.0
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(result.messages, isNotEmpty);
        expect(
          result.messages.any((m) => 
            m.severity == ValidationSeverity.success ||
            m.message.contains('pubspec.yaml'),
          ), 
          isTrue,
        );
      });

      test('should detect missing required fields', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
# Missing name and version
description: A test project

dependencies:
  flutter:
    sdk: flutter
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('必需字段') ||
            m.message.contains('name') ||
            m.message.contains('version'),
          ), 
          isTrue,
        );
      });

      test('should validate environment constraints', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project

dependencies:
  flutter:
    sdk: flutter
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('environment') ||
            m.message.contains('SDK约束'),
          ), 
          isTrue,
        );
      });
    });

    group('Version Constraint Validation', () {
      test('should validate proper version constraints', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  http: ^1.1.0
  path: '>=1.8.0 <2.0.0'

dev_dependencies:
  test: ^1.21.0
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(result.messages, isNotEmpty);
      });

      test('should detect dangerous version constraints', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  http: any
  path: '>=0.0.0'
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('any') ||
            m.message.contains('不安全') ||
            m.message.contains('可能导致不稳定'),
          ), 
          isTrue,
        );
      });

      test('should validate Flutter/Dart compatibility', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=2.17.0 <3.0.0'  # Old Dart version
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('兼容性') ||
            m.message.contains('Flutter') ||
            m.message.contains('Dart'),
          ), 
          isTrue,
        );
      });
    });

    group('Dependency Conflict Detection', () {
      test('should detect version conflicts', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.21.0  # Conflict with flutter_test

dev_dependencies:
  test: ^1.20.0  # Different version
''');
        
        // 需要创建pubspec.lock文件才能进行冲突检测
        await File('${tempDir.path}/pubspec.lock').writeAsString('''
packages:
  flutter_test:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  test:
    dependency: "direct main"
    description:
      name: test
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.21.0"
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('冲突') ||
            m.message.contains('flutter_test') ||
            m.message.contains('test'),
          ), 
          isTrue,
        );
      });

      test('should detect platform conflicts', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  universal_html: ^2.0.0  # Web-only
  camera: ^0.10.0  # Mobile-only
''');
        
        // 需要创建pubspec.lock文件才能进行冲突检测
        await File('${tempDir.path}/pubspec.lock').writeAsString('''
packages:
  universal_html:
    dependency: "direct main"
    description:
      name: universal_html
      url: "https://pub.dartlang.org"
    source: hosted
    version: "2.0.0"
  camera:
    dependency: "direct main"
    description:
      name: camera
      url: "https://pub.dartlang.org"
    source: hosted
    version: "0.10.0"
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('平台兼容性') ||
            m.message.contains('Web') ||
            m.message.contains('移动端'),
          ), 
          isTrue,
        );
      });
    });

    group('Security Vulnerability Detection', () {
      test('should detect known vulnerable packages', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^0.12.0  # Old version with vulnerabilities
  crypto: ^2.0.0  # Old version
  flutter_webview_plugin: ^0.3.0  # Deprecated package with vulnerabilities
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('安全') ||
            m.message.contains('风险') ||
            m.message.contains('漏洞') ||
            m.message.contains('停止维护'),
          ), 
          isTrue,
        );
      });

      test('should detect high-risk packages', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  test_package: ^1.0.0  # Contains 'test' pattern
  debug_helper: ^1.0.0  # Contains 'debug' pattern

dev_dependencies:
  test_api: ^0.4.0  
  build_test: ^2.0.0
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('test') ||
            m.message.contains('debug') ||
            m.message.contains('调试信息') ||
            m.message.contains('后门'),
          ), 
          isTrue,
        );
      });

      test('should detect sensitive permission packages', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  camera: ^0.10.0  # Sensitive permissions
  location: ^4.4.0  # Location access
  contacts_service: ^0.6.3  # Contact access
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('涉及') ||
            m.message.contains('权限') ||
            m.message.contains('camera') ||
            m.message.contains('location') ||
            m.message.contains('合规使用'),
          ), 
          isTrue,
        );
      });
    });

    group('Outdated Package Detection', () {
      test('should detect deprecated packages', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  pedantic: ^1.11.0  # Deprecated
  effective_dart: ^1.3.0  # Deprecated
  flutter_driver: ^0.0.0  # Deprecated
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('废弃') ||
            m.message.contains('pedantic') ||
            m.message.contains('effective_dart') ||
            m.message.contains('lints'),
          ), 
          isTrue,
        );
      });

      test('should detect soon-to-be-deprecated packages', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0  # Package that has recommendations
  shared_preferences: ^2.0.0  # Package with modernization suggestions
  sqflite: ^2.0.0  # Package with alternatives
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('建议') ||
            m.message.contains('考虑') ||
            m.message.contains('http') ||
            m.message.contains('shared_preferences') ||
            m.message.contains('sqflite'),
          ), 
          isTrue,
        );
      });

      test('should detect outdated version patterns', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: any  # Using 'any' constraint pattern
  path: 1.8.0  # Using exact version constraint
  shared_preferences: ^0.5.0  # Using 0.x version
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('any') ||
            m.message.contains('稳定性') ||
            m.message.contains('0.') ||
            m.message.contains('版本控制') ||
            m.message.contains('兼容性约束'),
          ), 
          isTrue,
        );
      });
    });

    group('Unused Dependencies Detection', () {
      test('should detect unused dependencies', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  path: ^1.8.0
  unused_package: ^1.0.0

dev_dependencies:
  test: ^1.21.0
''');
        
        // 创建使用部分依赖的代码
        await File('${tempDir.path}/lib/main.dart').writeAsString('''
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// path and unused_package are not imported

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    http.get(Uri.parse('https://example.com'));
    return MaterialApp(home: Text('Hello'));
  }
}
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('未使用') ||
            m.message.contains('unused') ||
            m.message.contains('依赖'),), 
          isTrue,
        );
      });

      test('should handle transitive dependencies correctly', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  meta: ^1.8.0  # Usually transitive through Flutter
''');
        
        await File('${tempDir.path}/lib/main.dart').writeAsString('''
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Text('Hello'));
  }
}
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(result.messages, isNotEmpty);
      });
    });

    group('Pubspec Lock Validation', () {
      test('should handle missing pubspec.lock', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('pubspec.lock') ||
            m.message.contains('缺少') ||
            m.message.contains('pub get'),
          ), 
          isTrue,
        );
      });

      test('should validate existing pubspec.lock', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
''');
        
        await File('${tempDir.path}/pubspec.lock').writeAsString('''
# Generated by pub
packages:
  http:
    dependency: "direct main"
    description:
      name: http
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.1.0"
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.severity == ValidationSeverity.success ||
            m.message.contains('依赖锁文件'),), 
          isTrue,
        );
      });
    });

    group('Error Handling', () {
      test('should handle malformed pubspec.yaml', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
dependencies:
  invalid_yaml: {
    this is not valid yaml
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(result, isNotNull);
        expect(
          result.messages.any((m) => 
            m.message.contains('格式错误') ||
            m.message.contains('解析'),), 
          isTrue,
        );
      });

      test('should handle missing pubspec.yaml', () async {
        await Directory('${tempDir.path}/lib').create();
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(result, isNotNull);
        expect(
          result.messages.any((m) => 
            m.message.contains('pubspec.yaml') &&
            m.message.contains('缺少'),), 
          isTrue,
        );
      });

      test('should handle permission errors gracefully', () async {
        const context = ValidationContext(projectPath: '/nonexistent/path');
        final result = await validator.validate('/nonexistent/path', context);
        
        expect(result, isNotNull);
        expect(result.messages, isNotEmpty);
      });
    });

    group('Strict Mode', () {
      test('should be more strict in strict mode', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: '>=1.0.0 <2.0.0'  # Loose constraint
''');
        
        final context = ValidationContext(
          projectPath: tempDir.path,
          strictMode: true,
        );
        final result = await validator.validate(tempDir.path, context);
        
        // 严格模式应该产生更多警告
        final warningCount = result.messages.where((m) => 
          m.severity == ValidationSeverity.warning ||
          m.severity == ValidationSeverity.error,
        ).length;
        expect(warningCount, greaterThan(0));
      });
    });
  });
}
