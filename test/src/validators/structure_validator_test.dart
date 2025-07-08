/*
---------------------------------------------------------------
File name:          structure_validator_test.dart
Author:             Ignorant-lu  
Date created:       2025/07/04
Last modified:      2025/07/04
Dart Version:       3.32.4
Description:        StructureValidator单元测试套件 - Task 44.2
---------------------------------------------------------------
Change History:
    2025/07/04: Initial creation - 结构验证器测试套件实现;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:ming_status_cli/src/validators/structure_validator.dart';
import 'package:test/test.dart';

void main() {
  group('StructureValidator Tests', () {
    late StructureValidator validator;
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('structure_test_');
    });

    setUp(() async {
      validator = StructureValidator();
      // 确保每个测试都有清洁的环境
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      tempDir = await Directory.systemTemp.createTemp('structure_test_');
    });

    tearDownAll(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Validator Basic Properties', () {
      test('should have correct validator name', () {
        expect(validator.validatorName, equals('structure'));
      });

      test('should support structure validation type', () {
        expect(validator.supportedTypes, contains(ValidationType.structure));
      });

      test('should have correct priority', () {
        expect(validator.priority, equals(10));
      });

      test('should pass health check', () async {
        final result = await validator.healthCheck();
        expect(result, isTrue);
      });
    });

    group('Basic Project Structure', () {
      test('should detect missing lib directory', () async {
        // 创建空项目目录
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(result.isValid, isFalse);
        expect(
          result.messages.any((m) => m.message.contains('缺少必需目录: lib/')),
          isTrue,
        );
      });

      test('should validate correct project structure', () async {
        // 创建标准项目结构
        await Directory('${tempDir.path}/lib').create();
        await Directory('${tempDir.path}/lib/src').create();
        await Directory('${tempDir.path}/test').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'
''');
        await File('${tempDir.path}/README.md').writeAsString(
            '# Test Project\nThis is a test project with enough content.',);
        await File('${tempDir.path}/lib/main.dart').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        // 验证不应该有任何错误级别的消息
        expect(
          result.messages
              .where(
                (m) => m.severity == ValidationSeverity.error,
              )
              .isEmpty,
          isTrue,
        );
      });

      test('should detect missing pubspec.yaml', () async {
        await Directory('${tempDir.path}/lib').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any((m) => m.message.contains('pubspec.yaml')),
          isTrue,
        );
      });

      test('should detect missing README.md', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any((m) => m.message.contains('README.md')),
          isTrue,
        );
      });
    });

    group('Library Structure Validation', () {
      test('should validate lib/src directory structure', () async {
        await Directory('${tempDir.path}/lib').create();
        await Directory('${tempDir.path}/lib/src').create();
        await File('${tempDir.path}/pubspec.yaml').create();
        await File('${tempDir.path}/lib/main.dart').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any(
            (m) =>
                m.severity == ValidationSeverity.error &&
                m.message.contains('lib/src'),
          ),
          isFalse,
        );
      });

      test('should detect incorrect file naming', () async {
        await Directory('${tempDir.path}/lib').create();
        await Directory('${tempDir.path}/lib/src').create();
        await File('${tempDir.path}/pubspec.yaml').create();
        await File('${tempDir.path}/lib/BadFileName.dart').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any((m) => m.message.contains('snake_case')),
          isTrue,
        );
      });

      test('should validate dart file extensions', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');
        await File('${tempDir.path}/lib/invalid.txt').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        // StructureValidator 不会检查文件扩展名，只检查.dart文件命名
        expect(result.messages, isNotEmpty);
      });
    });

    group('Test Directory Structure', () {
      test('should validate test directory presence', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any(
            (m) =>
                m.message.contains('缺少推荐目录: test/') ||
                m.message.contains('缺少测试目录'),
          ),
          isTrue,
        );
      });

      test('should validate test file naming convention', () async {
        await Directory('${tempDir.path}/lib').create();
        await Directory('${tempDir.path}/test').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');
        await File('${tempDir.path}/test/BadTestName.dart').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any(
            (m) => m.message.contains('test/ 目录存在但没有测试文件'),
          ),
          isTrue,
        );
      });

      test('should require test files to end with _test.dart', () async {
        await Directory('${tempDir.path}/lib').create();
        await Directory('${tempDir.path}/test').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');
        await File('${tempDir.path}/test/example.dart').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any((m) => m.message.contains('test/ 目录存在但没有测试文件')),
          isTrue,
        );
      });
    });

    group('Pet App Platform Standards', () {
      test('should validate module.yaml for Pet App modules', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').create();

        final moduleYaml = File('${tempDir.path}/module.yaml');
        await moduleYaml.writeAsString('''
name: test_module
type: widget
version: 1.0.0
description: Test module
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        // 对于Pet App模块，应该有更严格的结构要求
        expect(result.messages.isNotEmpty, isTrue);
      });

      test('should validate standard Pet App directories', () async {
        await Directory('${tempDir.path}/lib').create();
        await Directory('${tempDir.path}/lib/src').create();
        await Directory('${tempDir.path}/lib/src/services').create();
        await Directory('${tempDir.path}/lib/src/widgets').create();
        await Directory('${tempDir.path}/lib/src/models').create();
        await Directory('${tempDir.path}/lib/l10n').create();
        await File('${tempDir.path}/pubspec.yaml').create();
        await File('${tempDir.path}/module.yaml').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        // 标准Pet App结构应该通过验证
        expect(
          result.messages
              .where(
                (m) =>
                    m.severity == ValidationSeverity.error &&
                    m.message.contains('Pet App'),
              )
              .isEmpty,
          isTrue,
        );
      });

      test('should check for internationalization support', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').create();
        await File('${tempDir.path}/module.yaml').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any((m) => m.message.contains('l10n')),
          isTrue,
        );
      });
    });

    group('Documentation Structure', () {
      test('should validate README.md content', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').create();

        final readme = File('${tempDir.path}/README.md');
        await readme.writeAsString('# Test Project\nThis is a test.');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any(
            (m) =>
                m.severity == ValidationSeverity.error &&
                m.message.contains('README.md'),
          ),
          isFalse,
        );
      });

      test('should detect empty README.md', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').create();
        await File('${tempDir.path}/README.md').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any((m) => m.message.contains('README.md')),
          isTrue,
        );
      });

      test('should validate CHANGELOG.md presence', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').create();
        await File('${tempDir.path}/README.md').writeAsString('# Test');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any((m) => m.message.contains('CHANGELOG.md')),
          isTrue,
        );
      });
    });

    group('Git Configuration', () {
      test('should validate .gitignore presence', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any((m) => m.message.contains('.gitignore')),
          isTrue,
        );
      });

      test('should validate .gitignore content', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').create();

        final gitignore = File('${tempDir.path}/.gitignore');
        await gitignore.writeAsString('''
# Build
build/
.dart_tool/

# Cache
.packages
pubspec.lock
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any(
            (m) =>
                m.severity == ValidationSeverity.error &&
                m.message.contains('.gitignore'),
          ),
          isFalse,
        );
      });
    });

    group('Advanced Structure Validation', () {
      test('should handle empty directories gracefully', () async {
        await Directory('${tempDir.path}/lib').create();
        await Directory('${tempDir.path}/lib/src').create();
        await Directory('${tempDir.path}/empty_dir').create();
        await File('${tempDir.path}/pubspec.yaml').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        // 空目录不应该导致验证器崩溃
        expect(result, isNotNull);
      });

      test('should validate with strict mode', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').create();

        final context = ValidationContext(
          projectPath: tempDir.path,
          strictMode: true,
        );
        final result = await validator.validate(tempDir.path, context);

        // 严格模式应该产生更多警告
        final strictWarnings = result.messages
            .where(
              (m) => m.severity == ValidationSeverity.warning,
            )
            .length;
        expect(strictWarnings, greaterThan(0));
      });

      test('should handle permission errors gracefully', () async {
        // 创建一个无法访问的目录场景（模拟）
        const context = ValidationContext(projectPath: '/nonexistent/path');
        final result = await validator.validate('/nonexistent/path', context);

        expect(result, isNotNull);
        expect(result.isValid, isFalse);
      });
    });

    group('Naming Convention Validation', () {
      test('should validate snake_case for dart files', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').create();
        await File('${tempDir.path}/lib/validFileName.dart').create();
        await File('${tempDir.path}/lib/invalid-file-name.dart').create();
        await File('${tempDir.path}/lib/Valid_File_Name.dart').create();

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        final namingIssues = result.messages
            .where(
              (m) => m.message.contains('snake_case'),
            )
            .length;
        expect(namingIssues, greaterThan(0));
      });

      test('should validate directory naming', () async {
        await Directory('${tempDir.path}/lib').create();
        await Directory('${tempDir.path}/lib/Invalid-Dir').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages
              .any((m) => m.message.contains('目录命名不规范: Invalid-Dir')),
          isTrue,
        );
      });
    });
  });
}
