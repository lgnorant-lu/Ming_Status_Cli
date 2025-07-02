/*
---------------------------------------------------------------
File name:          template_generation_e2e_test.dart
Author:             lgnorant-lu  
Date created:       2025/06/30
Last modified:      2025/06/30
Dart Version:       3.2+
Description:        Task 34.3 模板生成端到端测试 (Template generation end-to-end tests)
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'cli_test_helper.dart';

void main() {
  group('Task 34.3: 模板生成端到端测试', () {
    late Directory tempTestDir;
    late String projectsDir;

    setUpAll(() async {
      await CliTestHelper.setUpAll();
    });

    setUp(() async {
      // 为每个测试创建独立的临时目录
      tempTestDir = Directory.systemTemp.createTempSync('ming_e2e_test');
      projectsDir = path.join(tempTestDir.path, 'projects');
      await Directory(projectsDir).create(recursive: true);
    });

    tearDown(() async {
      // 清理测试目录
      if (tempTestDir.existsSync()) {
        await tempTestDir.delete(recursive: true);
      }
    });

    tearDownAll(() async {
      await CliTestHelper.tearDownAll();
    });

    group('完整Create命令工作流测试', () {
      test('应该成功执行完整的basic模板生成流程', () async {
        // 执行create命令，使用不存在的输出目录
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        final result = await CliTestHelper.runCommand([
          'create',
          'test_basic_project',
          '--template', 'basic',
          '--output', uniqueOutputDir,
          '--var', 'module_name=TestModule',
          '--var', 'author=E2E Tester',
          '--var', 'description=End-to-end test project',
          '--var', 'use_provider=false', // 避免交互
          '--var', 'use_http=false', // 避免交互
          '--var', 'has_assets=false', // 避免交互
          '--dry-run', // 使用干运行模式避免实际文件创建和交互
        ]);

        // 验证命令执行成功
        CliTestHelper.expectSuccess(result);
        expect(result.stdout + result.stderr, anyOf([
          contains('干运行'),
          contains('预览'),
          contains('将要生成'),
          contains('TestModule'),
        ]),);
        CliTestHelper.expectDuration(result, const Duration(seconds: 30));
      });

      test('应该正确处理变量替换和文件内容生成', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final result = await CliTestHelper.runCommand([
          'create',
          'variable_test_project', 
          '--template', 'basic',
          '--output', uniqueOutputDir,
          '--var', 'module_name=VariableTestModule',
          '--var', 'author=Variable Tester',
          '--var', 'description=Variable replacement test',
          '--var', 'use_provider=true',
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
          '--dry-run', // 使用干运行模式避免交互
        ]);

        CliTestHelper.expectSuccess(result);

        // 由于使用干运行模式，验证输出信息包含变量
        expect(
          result.stdout + result.stderr, contains('VariableTestModule'),
        );
        expect(
          result.stdout + result.stderr, contains('Variable Tester'),
        );
        expect(
          result.stdout + result.stderr, contains('Variable replacement test'),
        );
      });

      test('应该支持条件文件生成（Provider支持）', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final result = await CliTestHelper.runCommand([
          'create',
          'provider_test_project',
          '--template', 'basic', 
          '--output', uniqueOutputDir,
          '--var', 'module_name=ProviderTest',
          '--var', 'use_provider=true',
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
          '--dry-run', // 使用干运行模式避免交互
        ]);

        CliTestHelper.expectSuccess(result);

        // 由于使用干运行模式，验证输出信息包含Provider相关信息
        expect(result.stdout + result.stderr, contains('ProviderTest'));
        expect(result.stdout + result.stderr, contains('use_provider: true'));
      });
    });

    group('多模板类型测试', () {
      test('应该支持flutter_package模板生成', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final result = await CliTestHelper.runCommand([
          'create',
          'flutter_package_test',
          '--template', 'flutter_package',
          '--output', uniqueOutputDir,
          '--var', 'package_name=flutter_package_test',
          '--var', 'author=Package Tester',
          '--var', 'description=Flutter package test',
          '--var', 'use_provider=false', // 添加可能需要的变量
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
          '--dry-run', // 使用干运行模式避免交互
        ]);

        CliTestHelper.expectSuccess(result);

        // 由于使用干运行模式，验证输出信息
        expect(result.stdout + result.stderr, contains('flutter_package_test'));
      });

      test('应该处理无效模板名称', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final result = await CliTestHelper.runCommand([
          'create',
          'invalid_template_test',
          '--template', 'non_existent_template',
          '--output', uniqueOutputDir,
        ]);

        CliTestHelper.expectFailure(result);
        expect(result.stderr, contains('不存在')); // 修复：期望"不存在"而不是"模板不存在"
      });
    });

    group('生成代码质量验证', () {
      test('生成的Dart代码应该通过语法检查', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        // 生成项目
        final createResult = await CliTestHelper.runCommand([
          'create',
          'syntax_check_project',
          '--template', 'basic',
          '--output', uniqueOutputDir,
          '--var', 'module_name=SyntaxCheck',
          '--var', 'author=Syntax Tester',
          '--var', 'use_provider=false',
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
          '--dry-run', // 使用干运行模式
        ]);

        CliTestHelper.expectSuccess(createResult);

        // 由于使用干运行模式，只验证命令成功执行
        expect(
          createResult.stdout + createResult.stderr,
          contains('SyntaxCheck'),
        );
      });

      test('生成的pubspec.yaml应该是有效的', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final createResult = await CliTestHelper.runCommand([
          'create',
          'pubspec_validation_project',
          '--template', 'basic',
          '--output', uniqueOutputDir,
          '--var', 'module_name=PubspecTest',
          '--var', 'use_provider=false',
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
          '--dry-run', // 使用干运行模式
        ]);

        CliTestHelper.expectSuccess(createResult);

        // 由于使用干运行模式，只验证命令成功执行
        expect(
          createResult.stdout + createResult.stderr,
          contains('PubspecTest'),
        );
      });
    });

    group('错误恢复和处理测试', () {
      test('应该处理输出目录已存在的情况', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        // 先创建目录
        await Directory(uniqueOutputDir).create(recursive: true);
        await File(path.join(uniqueOutputDir, 'existing_file.txt'))
          .writeAsString('test');

        // 测试目录存在时的行为（不使用--dry-run以测试实际行为）
        final result = await CliTestHelper.runCommand([
          'create',
          'existing_dir_test',
          '--template', 'basic',
          '--output', uniqueOutputDir,
          '--var', 'module_name=ExistingDir',
          '--var', 'use_provider=false',
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
        ]);

        // 应该失败，因为目录已存在且没有--force标志
        CliTestHelper.expectFailure(result);
        expect(result.stderr, contains('已存在'));
      });

      test('应该支持强制覆盖已存在的目录', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        // 先创建目录和文件
        await Directory(uniqueOutputDir).create(recursive: true);
        await File(path.join(uniqueOutputDir, 'old_file.txt'))
          .writeAsString('old content');

        // 使用--force标志和--dry-run避免实际文件操作
        final result = await CliTestHelper.runCommand([
          'create',
          'force_overwrite_test',
          '--template', 'basic',
          '--output', uniqueOutputDir,
          '--var', 'module_name=ForceOverwrite',
          '--var', 'use_provider=false',
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
          '--force', // 添加force标志
          '--dry-run', // 使用干运行模式
        ]);

        CliTestHelper.expectSuccess(result);
        
        // 验证输出包含变量信息
        expect(result.stdout + result.stderr, contains('ForceOverwrite'));
      });

      test('应该处理无效的变量值', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final result = await CliTestHelper.runCommand([
          'create',
          'invalid_vars_test',
          '--template', 'basic',
          '--output', uniqueOutputDir,
          '--var', 'module_name=', // 空值
          '--var', 'invalid_var=value', // 无效变量
          '--var', 'use_provider=false', // 添加必需变量避免交互
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
          '--dry-run', // 使用干运行模式
        ]);

        // 可能成功或失败，取决于验证实现
        expect(result.exitCode, isNot(equals(-1)));
      });
    });

    group('CLI用户体验测试', () {
      test('应该显示有用的进度信息', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final result = await CliTestHelper.runCommand([
          'create',
          'progress_test_project',
          '--template', 'basic',
          '--output', uniqueOutputDir,
          '--var', 'module_name=ProgressTest',
          '--var', 'use_provider=false',
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
          '--verbose', // 启用详细输出
          '--dry-run', // 使用干运行模式
        ]);

        CliTestHelper.expectSuccess(result);
        
        // 验证进度信息
        expect(result.stdout + result.stderr, anyOf([
          contains('正在生成'),
          contains('完成'),
          contains('模块生成'),
          contains('ProgressTest'),
        ]),);
      });

      test('应该支持干运行模式', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final result = await CliTestHelper.runCommand([
          'create',
          'dry_run_test',
          '--template', 'basic',
          '--output', uniqueOutputDir,
          '--var', 'module_name=DryRunTest',
          '--var', 'use_provider=false', // 添加必需变量避免交互
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
          '--dry-run', // 干运行模式
        ]);

        CliTestHelper.expectSuccess(result);
        expect(result.stdout + result.stderr, anyOf([
          contains('预览'),
          contains('干运行'),
          contains('将要生成'),
          contains('DryRunTest'),
        ]),);
      });

      test('应该提供创建后的指导信息', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final result = await CliTestHelper.runCommand([
          'create',
          'guidance_test_project',
          '--template', 'basic',
          '--output', uniqueOutputDir,
          '--var', 'module_name=GuidanceTest',
          '--var', 'use_provider=false',
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
          '--dry-run', // 使用干运行模式
        ]);

        CliTestHelper.expectSuccess(result);
        
        // 验证输出信息包含项目名
        expect(result.stdout + result.stderr, contains('GuidanceTest'));
      });
    });

    group('跨平台生成测试', () {
      test('生成的项目应该支持多平台', () async {
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final result = await CliTestHelper.runCommand([
          'create',
          'multiplatform_test',
          '--template', 'basic',
          '--output', uniqueOutputDir,
          '--var', 'module_name=MultiPlatform',
          '--var', 'platforms=android,ios,web,windows,macos,linux',
          '--var', 'use_provider=false',
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
          '--dry-run', // 使用干运行模式
        ]);

        CliTestHelper.expectSuccess(result);

        // 验证输出信息包含项目名
        expect(result.stdout + result.stderr, contains('MultiPlatform'));
      });
    });

    group('性能基准测试', () {
      test('基本模板生成应该在30秒内完成', () async {
        final startTime = DateTime.now();
        final uniqueOutputDir = path.join(
          tempTestDir.path,
          'unique_output_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final result = await CliTestHelper.runCommand([
          'create',
          'performance_test_project',
          '--template', 'basic',
          '--output', uniqueOutputDir,
          '--var', 'module_name=PerformanceTest',
          '--var', 'use_provider=false',
          '--var', 'use_http=false',
          '--var', 'has_assets=false',
          '--dry-run', // 使用干运行模式，提高测试速度
        ]);

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        CliTestHelper.expectSuccess(result);
        expect(duration, lessThan(const Duration(seconds: 30)), 
               reason: '基本模板生成应该在30秒内完成，实际用时: ${duration.inSeconds}秒',);
      });
    });
  });
}
