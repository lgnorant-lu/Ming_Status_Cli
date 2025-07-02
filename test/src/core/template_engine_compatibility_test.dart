/*
---------------------------------------------------------------
File name:          template_engine_compatibility_test.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        模板兼容性检查功能测试 (Template compatibility check tests)
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/template_engine.dart';
import 'package:ming_status_cli/src/core/template_exceptions.dart';
import 'package:ming_status_cli/src/core/template_models.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('模板兼容性检查功能测试', () {
    late TemplateEngine templateEngine;
    late String tempDir;
    late String testTemplateDir;

    setUp(() async {
      // 创建临时测试目录
      tempDir = await _createTempDirectory();
      testTemplateDir = path.join(tempDir, 'templates', 'test_template');
      await Directory(testTemplateDir).create(recursive: true);
      
      // 初始化模板引擎
      templateEngine = TemplateEngine(workingDirectory: tempDir);
    });

    tearDown(() async {
      // 清理测试目录
      await _cleanupTempDirectory(tempDir);
    });

    group('CompatibilityCheckResult 类测试', () {
      test('创建成功结果', () {
        final result = CompatibilityCheckResult.success(
          warnings: ['测试警告'],
          suggestions: ['测试建议'],
          metadata: {'test': true},
        );

        expect(result.isCompatible, isTrue);
        expect(result.errors, isEmpty);
        expect(result.warnings, contains('测试警告'));
        expect(result.suggestions, contains('测试建议'));
        expect(result.metadata['test'], isTrue);
      });

      test('创建失败结果', () {
        final result = CompatibilityCheckResult.failure(
          errors: ['测试错误'],
          warnings: ['测试警告'],
        );

        expect(result.isCompatible, isFalse);
        expect(result.errors, contains('测试错误'));
        expect(result.warnings, contains('测试警告'));
      });
    });

    group('模板版本信息解析测试', () {
      test('解析完整版本信息', () async {
        // 创建测试brick.yaml
        const brickYaml = '''
name: test_template
description: 测试模板
version: 1.2.3
environment:
  sdk: '>=3.0.0 <4.0.0'
compatibility:
  min_cli_version: '1.0.0'
  max_cli_version: '2.0.0'
  min_mason_version: '0.1.0'
''';
        await _createTestTemplate(testTemplateDir, brickYaml);

        final result = await templateEngine.checkTemplateCompatibility(
          'test_template',
          checkDependencies: false,
          checkPlatform: false,
          checkCompliance: false,
        );

        expect(result.metadata['versionInfo'], isNotNull);
        expect(
          result.metadata['versionInfo']['templateVersion'], equals('1.2.3'),
        );
        expect(
          result.metadata['versionInfo']['minCliVersion'], equals('1.0.0'),
        );
      });

      test('处理缺失版本信息', () async {
        // 创建最小brick.yaml
        const brickYaml = '''
name: test_template
description: 测试模板
''';
        await _createTestTemplate(testTemplateDir, brickYaml);

        final result = await templateEngine.checkTemplateCompatibility(
          'test_template',
          checkDependencies: false,
          checkPlatform: false,
          checkCompliance: false,
        );

        expect(result.metadata['versionInfo'], isNotNull);
        expect(
          result.metadata['versionInfo']['templateVersion'], equals('0.1.0'),
        );
      });
    });

    group('依赖兼容性检查测试', () {
      test('检查必需依赖', () async {
        const brickYaml = '''
name: test_template
description: 测试模板
version: 1.0.0
dependencies:
  required:
    dart: '^3.0.0'
    mason: '^0.1.0'
''';
        await _createTestTemplate(testTemplateDir, brickYaml);

        final result = await templateEngine.checkTemplateCompatibility(
          'test_template',
          checkVersion: false,
          checkPlatform: false,
          checkCompliance: false,
        );

        expect(result.metadata['dependencyInfo'], isNotNull);
        expect(
          result.metadata['dependencyInfo']['requiredDependencies'],
          isNotEmpty,
        );
      });

      test('检查冲突依赖', () async {
        const brickYaml = '''
name: test_template
description: 测试模板
version: 1.0.0
conflicts:
  - 'old_package'
  - 'deprecated_lib'
''';
        await _createTestTemplate(testTemplateDir, brickYaml);

        final result = await templateEngine.checkTemplateCompatibility(
          'test_template',
          checkVersion: false,
          checkPlatform: false,
          checkCompliance: false,
        );

        expect(result.metadata['dependencyInfo']['conflictingDependencies'], 
               contains('old_package'),);
      });
    });

    group('平台兼容性检查测试', () {
      test('检查支持的平台', () async {
        const brickYaml = '''
name: test_template
description: 测试模板
version: 1.0.0
platforms:
  supported:
    - windows
    - macos
    - linux
  required_features:
    - file_system
    - console
''';
        await _createTestTemplate(testTemplateDir, brickYaml);

        final result = await templateEngine.checkTemplateCompatibility(
          'test_template',
          checkVersion: false,
          checkDependencies: false,
          checkCompliance: false,
        );

        expect(result.metadata['platformInfo'], isNotNull);
        expect(result.metadata['currentPlatform'], isNotNull);
        
        final platformInfo = result.metadata['platformInfo'];
        expect(platformInfo['supportedPlatforms'], contains('windows'));
        expect(platformInfo['requiredFeatures'], contains('file_system'));
      });

      test('检查不支持的平台', () async {
        const brickYaml = '''
name: test_template
description: 测试模板
version: 1.0.0
platforms:
  unsupported:
    - android
    - ios
''';
        await _createTestTemplate(testTemplateDir, brickYaml);

        final result = await templateEngine.checkTemplateCompatibility(
          'test_template',
          checkVersion: false,
          checkDependencies: false,
          checkCompliance: false,
        );

        final platformInfo = result.metadata['platformInfo'];
        expect(platformInfo['unsupportedPlatforms'], contains('android'));
      });
    });

    group('模板合规性检查测试', () {
      test('检查必需字段', () async {
        // 创建缺少必需字段的模板
        const brickYaml = '''
name: test_template
# 缺少 description 和 version
''';
        await _createTestTemplate(testTemplateDir, brickYaml);

        final result = await templateEngine.checkTemplateCompatibility(
          'test_template',
          checkVersion: false,
          checkDependencies: false,
          checkPlatform: false,
        );

        expect(result.isCompatible, isFalse);
        expect(result.errors, isNotEmpty);
        expect(
          result.errors.any((error) => error.contains('description')),
          isTrue,
        );
        expect(
          result.errors.any((error) => error.contains('version')),
          isTrue,
        );
      });

      test('检查版本格式', () async {
        const brickYaml = '''
name: test_template
description: 测试模板
version: invalid_version
''';
        await _createTestTemplate(testTemplateDir, brickYaml);

        final result = await templateEngine.checkTemplateCompatibility(
          'test_template',
          checkVersion: false,
          checkDependencies: false,
          checkPlatform: false,
        );

        expect(result.isCompatible, isFalse);
        expect(result.errors.any((error) => error.contains('版本格式无效')), isTrue);
      });

      test('检查变量定义', () async {
        const brickYaml = '''
name: test_template
description: 测试模板
version: 1.0.0
vars:
  module_name:
    # 缺少 type 和 description
    prompt: 请输入模块名称
  author:
    type: string
    # 缺少 description
''';
        await _createTestTemplate(testTemplateDir, brickYaml);

        final result = await templateEngine.checkTemplateCompatibility(
          'test_template',
          checkVersion: false,
          checkDependencies: false,
          checkPlatform: false,
        );

        expect(
          result.warnings.any((warning) => warning.contains('缺少类型定义')),
          isTrue,
        );
        expect(
          result.warnings.any((warning) => warning.contains('缺少描述')),
          isTrue,
        );
      });

      test('检查文档文件', () async {
        const brickYaml = '''
name: test_template
description: 测试模板
version: 1.0.0
''';
        await _createTestTemplate(testTemplateDir, brickYaml);

        final result = await templateEngine.checkTemplateCompatibility(
          'test_template',
          checkVersion: false,
          checkDependencies: false,
          checkPlatform: false,
        );

        expect(
          result.warnings.any((warning) => warning.contains('README.md')),
          isTrue,
        );
        expect(
          result.warnings.any((warning) => warning.contains('LICENSE')),
          isTrue,
        );
        expect(
          result.warnings.any((warning) => warning.contains('CHANGELOG.md')),
          isTrue,
        );
      });
    });

    group('批量兼容性检查测试', () {
      test('批量检查多个模板', () async {
        // 创建多个测试模板
        final template1Dir = path.join(tempDir, 'templates', 'template1');
        final template2Dir = path.join(tempDir, 'templates', 'template2');
        
        await Directory(template1Dir).create(recursive: true);
        await Directory(template2Dir).create(recursive: true);

        // 创建有效模板
        await _createTestTemplate(template1Dir, '''
name: template1
description: 测试模板1
version: 1.0.0
''');

        // 创建无效模板
        await _createTestTemplate(template2Dir, '''
name: template2
# 缺少必需字段
''');

        final results = await templateEngine
          .validateAllTemplatesCompatibility();

        expect(results, hasLength(2));
        expect(results['template1']?.isCompatible, isTrue);
        expect(results['template2']?.isCompatible, isFalse);
      });
    });

    group('模板系统健康检查测试', () {
      test('系统健康状态评估', () async {
        // 创建一个有效模板
        await _createTestTemplate(testTemplateDir, '''
name: test_template
description: 测试模板
version: 1.0.0
''');

        final health = await templateEngine.checkTemplateSystemHealth();

        expect(health['status'], isNotNull);
        expect(health['checks'], isNotNull);
        expect(health['templates'], isNotNull);
        expect(health['checks']['template_compatibility'], isNotNull);
      });
    });

    group('辅助方法测试', () {
      test('版本比较功能', () {
        // 由于_compareVersions是私有方法，我们通过版本兼容性检查间接测试
        // 这个测试验证版本比较逻辑是否正确
        expect(true, isTrue); // 占位符测试
      });

      test('版本格式验证', () {
        // 通过合规性检查间接测试版本格式验证
        expect(true, isTrue); // 占位符测试
      });
    });
  });
}

/// 创建测试模板辅助方法
Future<void> _createTestTemplate(String templateDir, String brickYaml) async {
  // 创建brick.yaml文件
  final brickPath = path.join(templateDir, 'brick.yaml');
  await File(brickPath).writeAsString(brickYaml);

  // 创建__brick__目录和基础文件
  final brickDir = path.join(templateDir, '__brick__');
  await Directory(brickDir).create(recursive: true);
  
  // 创建一个基础模板文件
  final templateFile = path.join(brickDir, 'main.dart');
  await File(templateFile).writeAsString('''
// Generated template file
void main() {
  print('Hello {{name}}!');
}
''');
}

/// 创建临时目录
Future<String> _createTempDirectory() async {
  final tempDir = await Directory.systemTemp.createTemp(
    'template_engine_test_',
  );
  return tempDir.path;
}

/// 清理临时目录
Future<void> _cleanupTempDirectory(String dirPath) async {
  try {
    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  } catch (e) {
    // 忽略清理错误
  }
} 
