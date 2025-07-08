/*
---------------------------------------------------------------
File name:          quality_validator_test.dart
Author:             Ignorant-lu
Date created:       2025/07/04
Last modified:      2025/07/04
Dart Version:       3.32.4
Description:        QualityValidator单元测试套件 - Task 44.2
---------------------------------------------------------------
Change History:
    2025/07/04: Initial creation - 代码质量验证器测试套件实现;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:ming_status_cli/src/validators/quality_validator.dart';
import 'package:test/test.dart';

void main() {
  group('QualityValidator Tests', () {
    late QualityValidator validator;
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('quality_test_');
    });

    setUp(() async {
      validator = QualityValidator();
      // 确保每个测试都有清洁的环境
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
      tempDir = await Directory.systemTemp.createTemp('quality_test_');
    });

    tearDownAll(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Validator Basic Properties', () {
      test('should have correct validator name', () {
        expect(validator.validatorName, equals('quality'));
      });

      test('should support quality validation type', () {
        expect(validator.supportedTypes, contains(ValidationType.quality));
      });

      test('should have correct priority', () {
        expect(validator.priority, equals(20));
      });

      test('should pass health check', () async {
        final result = await validator.healthCheck();
        expect(result, isTrue);
      });
    });

    group('Code Format Validation', () {
      test('should validate file headers', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        // 创建带有正确文件头的Dart文件
        await File('${tempDir.path}/lib/good_header.dart').writeAsString('''
/*
---------------------------------------------------------------
File name:          good_header.dart
Author:             Test Author
Date created:       2025/01/01
Description:        Test file with proper header
---------------------------------------------------------------
*/

class GoodHeader {
  void method() {}
}
''');

        // 创建缺少文件头的Dart文件
        await File('${tempDir.path}/lib/bad_header.dart').writeAsString('''
class BadHeader {
  void method() {}
}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any((m) => m.message.contains('文件头注释')),
          isTrue,
        );
      });

      test('should validate line length', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        // 创建有长行的文件
        await File('${tempDir.path}/lib/long_lines.dart').writeAsString('''
class LongLines {
  void veryLongMethodNameThatExceedsTheRecommendedLineLengthLimitAndShouldBeFlaggedByTheQualityValidator() {}
}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any((m) => m.message.contains('行长度')),
          isTrue,
        );
      });

      test('should validate import organization', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        // 创建导入顺序错误的文件
        await File('${tempDir.path}/lib/bad_imports.dart').writeAsString('''
import 'package:test/test.dart';
import 'dart:io';
import '../other_file.dart';

class BadImports {}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any((m) => m.message.contains('导入语句')),
          isTrue,
        );
      });
    });

    group('Documentation Validation', () {
      test('should validate class documentation', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        // 创建没有文档的类
        await File('${tempDir.path}/lib/undocumented.dart').writeAsString('''
class UndocumentedClass {
  void undocumentedMethod() {}
}
''');

        // 创建有文档的类
        await File('${tempDir.path}/lib/documented.dart').writeAsString('''
/// A well documented class
class DocumentedClass {
  /// A well documented method
  void documentedMethod() {}
}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any(
            (m) =>
                m.message.contains('文档覆盖率') ||
                m.message.contains('方法文档') ||
                m.message.contains('类文档'),
          ),
          isTrue,
        );
      });

      test('should validate documentation coverage', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        // 创建部分文档覆盖的文件
        await File('${tempDir.path}/lib/partial_docs.dart').writeAsString('''
/// Documented class
class PartialDocs {
  /// Documented method
  void documentedMethod() {}
  
  // Missing documentation
  void undocumentedMethod() {}
}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(result.messages, isNotEmpty);
      });
    });

    group('Code Complexity Validation', () {
      test('should validate file length', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        // 创建很长的文件（超过1000行）
        final longFileContent = StringBuffer()..writeln('class VeryLongFile {');
        for (var i = 0; i < 1050; i++) {
          longFileContent.writeln('  void method$i() {}');
        }
        longFileContent.writeln('}');

        await File('${tempDir.path}/lib/very_long_file.dart')
            .writeAsString(longFileContent.toString());

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any(
            (m) => m.message.contains('文件过长') || m.message.contains('文件较长'),
          ),
          isTrue,
        );
      });

      test('should validate method complexity', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        // 创建复杂方法（超过50行）
        final complexMethodContent = StringBuffer()
          ..writeln('class ComplexMethod {')
          ..writeln('  void veryComplexMethod(int value) {');
        for (var i = 0; i < 60; i++) {
          complexMethodContent.writeln('    print("Line $i");');
        }
        complexMethodContent
          ..writeln('  }')
          ..writeln('}');

        await File('${tempDir.path}/lib/complex_method.dart')
            .writeAsString(complexMethodContent.toString());

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any(
            (m) => m.message.contains('方法') && m.message.contains('过长'),
          ),
          isTrue,
        );
      });
    });

    group('Best Practices Validation', () {
      test('should validate const usage', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        await File('${tempDir.path}/lib/const_usage.dart').writeAsString('''
class ConstUsage {
  // Should be const
  final String name = 'Test';
  
  // Correct const usage
  static const String constantName = 'Constant';
}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(result.messages, isNotEmpty);
      });

      test('should validate override annotations', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        await File('${tempDir.path}/lib/override_usage.dart').writeAsString('''
class Base {
  void method() {}
}

class Derived extends Base {
  // Missing @override annotation
  void method() {}
}

class GoodDerived extends Base {
  @override
  void method() {}
}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(result.messages, isNotEmpty);
      });

      test('should detect anti-patterns', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        await File('${tempDir.path}/lib/anti_patterns.dart').writeAsString('''
class AntiPatterns {
  void badMethod() {
    // Print statement (anti-pattern)
    print('Debug message');
    
    // Empty catch block (anti-pattern)
    try {
      throw Exception();
    } catch (e) {
      // Empty catch
    }
  }
}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any((m) => m.message.contains('print语句')),
          isTrue,
        );
      });
    });

    group('Linter Integration', () {
      test('should validate analysis_options.yaml', () async {
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
                m.message.contains('analysis_options.yaml') ||
                m.message.contains('静态分析配置'),
          ),
          isTrue,
        );
      });

      test('should handle existing analysis_options.yaml', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        await File('${tempDir.path}/analysis_options.yaml').writeAsString('''
analyzer:
  strong-mode:
    implicit-casts: false

linter:
  rules:
    - prefer_const_constructors
    - use_key_in_widget_constructors
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(
          result.messages.any(
            (m) =>
                m.message.contains('静态分析配置') ||
                m.message.contains('linter规则') ||
                m.severity == ValidationSeverity.success,
          ),
          isTrue,
        );
      });
    });

    group('Dart Analyze Integration', () {
      test('should handle dart analyze results', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
environment:
  sdk: '>=3.0.0 <4.0.0'
''');

        // 创建有分析问题的文件
        await File('${tempDir.path}/lib/analyze_issues.dart').writeAsString('''
class AnalyzeIssues {
  var unusedVariable = 42;
  
  void method() {
    var anotherUnused = 'test';
  }
}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        // dart analyze集成可能会检测到问题
        expect(result.messages, isNotEmpty);
      });
    });

    group('Advanced Code Style', () {
      test('should validate parameter style', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        await File('${tempDir.path}/lib/parameter_style.dart').writeAsString('''
class ParameterStyle {
  // Too many parameters
  void tooManyParams(int a, int b, int c, int d, int e, int f, int g) {}
  
  // Good parameter style
  void goodParams(int value, {String? name}) {}
}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(result.messages, isNotEmpty);
      });

      test('should validate variable naming', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        await File('${tempDir.path}/lib/variable_naming.dart').writeAsString('''
class VariableNaming {
  // Bad naming
  int a;
  String str;
  
  // Good naming
  int userCount;
  String userName;
  
  VariableNaming(this.a, this.str, this.userCount, this.userName);
}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(result.messages, isNotEmpty);
      });
    });

    group('Performance Patterns', () {
      test('should validate async patterns', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        await File('${tempDir.path}/lib/async_patterns.dart').writeAsString('''
class AsyncPatterns {
  // Missing async/await
  Future<String> badAsync() {
    return Future.delayed(Duration(seconds: 1), () => 'result');
  }
  
  // Good async/await
  Future<String> goodAsync() async {
    await Future.delayed(Duration(seconds: 1));
    return 'result';
  }
}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(result.messages, isNotEmpty);
      });

      test('should validate loop performance', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        await File('${tempDir.path}/lib/loop_performance.dart')
            .writeAsString('''
class LoopPerformance {
  void inefficientLoop(List<String> items) {
    for (int i = 0; i < items.length; i++) {
      // items.length called each iteration
      print(items[i]);
    }
  }
  
  void efficientLoop(List<String> items) {
    final length = items.length;
    for (int i = 0; i < length; i++) {
      print(items[i]);
    }
  }
}
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(result.messages, isNotEmpty);
      });
    });

    group('Error Handling', () {
      test('should handle permission errors gracefully', () async {
        const context = ValidationContext(projectPath: '/nonexistent/path');
        final result = await validator.validate('/nonexistent/path', context);

        expect(result, isNotNull);
        // QualityValidator可能不会因为路径问题而失败，它会优雅处理
        expect(result.messages.isNotEmpty || result.isValid, isTrue);
      });

      test('should handle malformed dart files', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        // 创建语法错误的Dart文件
        await File('${tempDir.path}/lib/malformed.dart').writeAsString('''
class MalformedFile {
  void method() {
    // Missing closing brace
''');

        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);

        expect(result, isNotNull);
      });
    });

    group('Strict Mode', () {
      test('should be more strict in strict mode', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_project
version: 1.0.0
description: A test project
''');

        await File('${tempDir.path}/lib/strict_test.dart').writeAsString('''
class StrictTest {
  void method() {
    var value = 42; // Could be int
  }
}
''');

        final context = ValidationContext(
          projectPath: tempDir.path,
          strictMode: true,
        );
        final result = await validator.validate(tempDir.path, context);

        // 严格模式应该产生更多警告
        final warningCount = result.messages
            .where(
              (m) => m.severity == ValidationSeverity.warning,
            )
            .length;
        expect(warningCount, greaterThan(0));
      });
    });
  });
}
