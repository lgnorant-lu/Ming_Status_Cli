/*
---------------------------------------------------------------
File name:          template_creator_acceptance_test.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        模板创建器模块验收测试 (Template Creator Module Acceptance Test)
---------------------------------------------------------------
Change History:
    2025/07/12: Initial creation - 完整的模块验收测试;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import 'package:ming_status_cli/src/core/template_creator/template_scaffold.dart';
import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

void main() {
  group('模板创建器模块验收测试', () {
    late Directory tempDir;
    late String testOutputPath;

    setUpAll(() async {
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('template_creator_test_');
      testOutputPath = tempDir.path;
      print('测试输出目录: $testOutputPath');
    });

    tearDownAll(() async {
      // 清理测试目录
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('基础功能测试', () {
      test('应该能够创建简单的Flutter模板', () async {
        // Arrange
        final config = ScaffoldConfig(
          templateName: 'test_flutter_simple',
          templateType: TemplateType.basic,
          author: 'Test Author',
          description: '简单Flutter模板测试',
          outputPath: testOutputPath,
          framework: TemplateFramework.flutter,
          platform: TemplatePlatform.mobile,
        );

        final scaffold = TemplateScaffold();

        // Act
        final result = await scaffold.generateScaffold(config);

        // Assert
        expect(result.success, isTrue, reason: '模板生成应该成功');
        expect(result.errors, isEmpty, reason: '不应该有错误');
        expect(result.generatedFiles, isNotEmpty, reason: '应该生成文件');

        // 验证关键文件存在
        final templatePath = path.join(testOutputPath, 'test_flutter_simple');
        expect(await File(path.join(templatePath, 'pubspec.yaml')).exists(), isTrue);
        expect(await File(path.join(templatePath, '.gitignore')).exists(), isTrue);
        expect(await File(path.join(templatePath, 'analysis_options.yaml')).exists(), isTrue);
        expect(await File(path.join(templatePath, 'README.md')).exists(), isTrue);

        print('✅ 简单Flutter模板生成成功: ${result.generatedFiles.length}个文件');
      });

      test('应该能够创建复杂的Dart模板', () async {
        // Arrange
        final config = ScaffoldConfig(
          templateName: 'test_dart_complex',
          templateType: TemplateType.full,
          author: 'Test Author',
          description: '复杂Dart模板测试',
          outputPath: testOutputPath,
          framework: TemplateFramework.dart,
          platform: TemplatePlatform.server,
          complexity: TemplateComplexity.complex,
        );

        final scaffold = TemplateScaffold();

        // Act
        final result = await scaffold.generateScaffold(config);

        // Assert
        expect(result.success, isTrue, reason: '模板生成应该成功');
        expect(result.errors, isEmpty, reason: '不应该有错误');
        expect(result.generatedFiles, isNotEmpty, reason: '应该生成文件');

        // 验证关键文件存在
        final templatePath = path.join(testOutputPath, 'test_dart_complex');
        expect(await File(path.join(templatePath, 'pubspec.yaml')).exists(), isTrue);
        expect(await File(path.join(templatePath, 'template.yaml')).exists(), isTrue);

        print('✅ 复杂Dart模板生成成功: ${result.generatedFiles.length}个文件');
      });

      test('应该能够创建企业级模板', () async {
        // Arrange
        final config = ScaffoldConfig(
          templateName: 'test_enterprise',
          templateType: TemplateType.full,
          author: 'Enterprise Team',
          description: '企业级模板测试',
          outputPath: testOutputPath,
          framework: TemplateFramework.flutter,
          complexity: TemplateComplexity.enterprise,
          tags: ['enterprise', 'production', 'scalable'],
          dependencies: ['riverpod', 'go_router', 'dio'],
        );

        final scaffold = TemplateScaffold();

        // Act
        final result = await scaffold.generateScaffold(config);

        // Assert
        expect(result.success, isTrue, reason: '企业级模板生成应该成功');
        expect(result.errors, isEmpty, reason: '不应该有错误');
        expect(result.generatedFiles.length, greaterThan(10), reason: '企业级模板应该生成更多文件');

        // 验证企业级特定文件
        final templatePath = path.join(testOutputPath, 'test_enterprise');
        expect(await File(path.join(templatePath, 'melos.yaml')).exists(), isTrue);
        expect(await File(path.join(templatePath, 'shorebird.yaml')).exists(), isTrue);

        print('✅ 企业级模板生成成功: ${result.generatedFiles.length}个文件');
      });
    });

    group('配置验证测试', () {
      test('应该验证必需的配置参数', () {
        // 测试配置验证
        expect(() => const ScaffoldConfig(
          templateName: '',  // 空名称应该被验证
          templateType: TemplateType.basic,
          author: 'Test',
          description: 'Test',
        ), throwsA(isA<ArgumentError>()),);
      });

      test('应该处理无效的输出路径', () async {
        const config = ScaffoldConfig(
          templateName: 'test_invalid_path',
          templateType: TemplateType.basic,
          author: 'Test Author',
          description: '无效路径测试',
          outputPath: '/invalid/path/that/does/not/exist',
          framework: TemplateFramework.dart,
        );

        final scaffold = TemplateScaffold();
        final result = await scaffold.generateScaffold(config);

        // 应该优雅地处理错误
        expect(result.success, isFalse, reason: '无效路径应该导致失败');
        expect(result.errors, isNotEmpty, reason: '应该有错误信息');

        print('✅ 无效路径错误处理正确');
      });
    });

    group('模块化架构测试', () {
      test('应该能够独立使用配置生成器', () async {
        const config = ScaffoldConfig(
          templateName: 'test_config_only',
          templateType: TemplateType.basic,
          author: 'Test Author',
          description: '配置生成器测试',
          framework: TemplateFramework.flutter,
        );

        // 测试各个生成器模块
        final pubspecGenerator = PubspecGenerator();
        final pubspecContent = pubspecGenerator.generateContent(config);
        
        expect(pubspecContent, contains('name: test_config_only'));
        expect(pubspecContent, contains('flutter:'));
        
        print('✅ 配置生成器模块独立工作正常');
      });

      test('应该能够独立使用结构生成器', () async {
        const config = ScaffoldConfig(
          templateName: 'test_structure',
          templateType: TemplateType.basic,
          author: 'Test Author',
          description: '结构生成器测试',
          framework: TemplateFramework.flutter,
        );

        final structureGenerator = FlutterStructureCreator();
        final directories = structureGenerator.getDirectories(config);
        
        expect(directories, isNotEmpty);
        expect(directories, contains('lib'));
        expect(directories, contains('test'));
        
        print('✅ 结构生成器模块独立工作正常');
      });

      test('应该能够独立使用文档生成器', () async {
        const config = ScaffoldConfig(
          templateName: 'test_docs',
          templateType: TemplateType.basic,
          author: 'Test Author',
          description: '文档生成器测试',
          framework: TemplateFramework.flutter,
        );

        final readmeGenerator = ReadmeGenerator();
        final readmeContent = readmeGenerator.generateContent(config);
        
        expect(readmeContent, contains('# test_docs'));
        expect(readmeContent, contains('Test Author'));
        expect(readmeContent, contains('文档生成器测试'));
        
        print('✅ 文档生成器模块独立工作正常');
      });
    });

    group('性能测试', () {
      test('应该在合理时间内生成模板', () async {
        final config = ScaffoldConfig(
          templateName: 'test_performance',
          templateType: TemplateType.full,
          author: 'Performance Test',
          description: '性能测试模板',
          outputPath: testOutputPath,
          framework: TemplateFramework.flutter,
          complexity: TemplateComplexity.complex,
        );

        final scaffold = TemplateScaffold();
        final stopwatch = Stopwatch()..start();

        // Act
        final result = await scaffold.generateScaffold(config);
        stopwatch.stop();

        // Assert
        expect(result.success, isTrue);
        expect(stopwatch.elapsed.inSeconds, lessThan(30), 
               reason: '模板生成应该在30秒内完成',);

        print('✅ 性能测试通过: ${stopwatch.elapsed.inMilliseconds}ms');
      });
    });

    group('错误处理测试', () {
      test('应该优雅地处理文件系统错误', () async {
        // 创建一个只读目录来模拟权限错误
        final readOnlyDir = Directory(path.join(tempDir.path, 'readonly'));
        await readOnlyDir.create();
        
        // 在Windows上设置只读属性可能需要不同的方法
        // 这里我们简单地测试一个不存在的路径
        const config = ScaffoldConfig(
          templateName: 'test_error_handling',
          templateType: TemplateType.basic,
          author: 'Error Test',
          description: '错误处理测试',
          outputPath: '/root/forbidden',  // 通常无权限的路径
          framework: TemplateFramework.dart,
        );

        final scaffold = TemplateScaffold();
        final result = await scaffold.generateScaffold(config);

        // 应该返回失败结果而不是抛出异常
        expect(result.success, isFalse);
        expect(result.errors, isNotEmpty);

        print('✅ 错误处理测试通过');
      });
    });
  });
}
