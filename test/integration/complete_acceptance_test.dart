/*
---------------------------------------------------------------
File name:          complete_acceptance_test.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 52.1 - 完整功能验收测试
                    验证所有核心功能和用户场景
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 完整功能验收测试;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Task 52.1: 完整功能验收测试', () {
    late Directory tempDir;
    late String mingCliPath;

    setUpAll(() async {
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_acceptance_test_');

      // 构建CLI可执行文件路径
      mingCliPath =
          path.join(Directory.current.path, 'bin', 'ming_status_cli.dart');

      print('🧪 完整功能验收测试目录: ${tempDir.path}');
      print('📦 Ming CLI路径: $mingCliPath');
    });

    tearDownAll(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
        print('🗑️  清理测试目录: ${tempDir.path}');
      }
    });

    group('核心功能验收测试', () {
      test('应该能够显示帮助信息', () async {
        final result = await Process.run(
          'dart',
          [mingCliPath, '--help'],
          workingDirectory: tempDir.path,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout.toString(), contains('Ming Status CLI'));
        expect(result.stdout.toString(), contains('用法'));
        expect(result.stdout.toString(), contains('命令'));

        print('✅ 帮助信息显示测试通过');
      });

      test('应该能够显示版本信息', () async {
        final result = await Process.run(
          'dart',
          [mingCliPath, '--version'],
          workingDirectory: tempDir.path,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout.toString(), contains('Ming Status CLI'));
        // 版本信息可能是开发版本，所以只检查包含CLI名称

        print('✅ 版本信息显示测试通过');
      });

      test('应该能够初始化新项目', () async {
        final projectDir = path.join(tempDir.path, 'test_project');

        final result = await Process.run(
          'dart',
          [mingCliPath, 'init', 'test_project'],
          workingDirectory: tempDir.path,
        );

        expect(result.exitCode, equals(0));
        expect(Directory(projectDir).existsSync(), isTrue);
        expect(File(path.join(projectDir, 'ming_status.yaml')).existsSync(),
            isTrue,);

        print('✅ 项目初始化测试通过');
      });

      test('应该能够配置项目设置', () async {
        final projectDir = path.join(tempDir.path, 'config_project');

        // 先初始化项目
        await Process.run(
          'dart',
          [mingCliPath, 'init', 'config_project'],
          workingDirectory: tempDir.path,
        );

        // 配置用户信息
        final configResult = await Process.run(
          'dart',
          [mingCliPath, 'config', '--set', 'user.name=Test User'],
          workingDirectory: projectDir,
        );

        expect(configResult.exitCode, equals(0));

        // 验证配置
        final listResult = await Process.run(
          'dart',
          [mingCliPath, 'config', '--list'],
          workingDirectory: projectDir,
        );

        expect(listResult.exitCode, equals(0));
        expect(listResult.stdout.toString(), contains('user.name'));

        print('✅ 项目配置测试通过');
      });

      test('应该能够创建模块', () async {
        final projectDir = path.join(tempDir.path, 'module_project');

        // 初始化项目
        await Process.run(
          'dart',
          [mingCliPath, 'init', 'module_project'],
          workingDirectory: tempDir.path,
        );

        // 创建模块
        final createResult = await Process.run(
          'dart',
          [mingCliPath, 'create', 'test_module', '--type=dart'],
          workingDirectory: projectDir,
        );

        expect(createResult.exitCode, equals(0));
        expect(
            Directory(path.join(projectDir, 'modules', 'test_module'))
                .existsSync(),
            isTrue,);

        print('✅ 模块创建测试通过');
      });

      test('应该能够验证项目', () async {
        final projectDir = path.join(tempDir.path, 'validate_project');

        // 初始化项目
        await Process.run(
          'dart',
          [mingCliPath, 'init', 'validate_project'],
          workingDirectory: tempDir.path,
        );

        // 验证项目
        final validateResult = await Process.run(
          'dart',
          [mingCliPath, 'validate'],
          workingDirectory: projectDir,
        );

        expect(validateResult.exitCode, equals(0));
        expect(validateResult.stdout.toString(), contains('验证'));

        print('✅ 项目验证测试通过');
      });
    });

    group('工作流集成测试', () {
      test('应该能够完成完整的项目创建工作流', () async {
        final workflowDir = path.join(tempDir.path, 'workflow_test');

        // 1. 初始化项目
        var result = await Process.run(
          'dart',
          [mingCliPath, 'init', 'workflow_test'],
          workingDirectory: tempDir.path,
        );
        expect(result.exitCode, equals(0));

        // 2. 配置项目
        result = await Process.run(
          'dart',
          [mingCliPath, 'config', '--set', 'user.name=Workflow Test'],
          workingDirectory: workflowDir,
        );
        expect(result.exitCode, equals(0));

        // 3. 创建多个模块
        final moduleTypes = ['dart', 'flutter', 'web'];
        for (final type in moduleTypes) {
          result = await Process.run(
            'dart',
            [mingCliPath, 'create', '${type}_module', '--type=$type'],
            workingDirectory: workflowDir,
          );
          expect(result.exitCode, equals(0));
        }

        // 4. 验证整个项目
        result = await Process.run(
          'dart',
          [mingCliPath, 'validate'],
          workingDirectory: workflowDir,
        );
        expect(result.exitCode, equals(0));

        // 5. 检查项目结构
        expect(
            Directory(path.join(workflowDir, 'modules')).existsSync(), isTrue,);
        expect(
            Directory(path.join(workflowDir, 'modules', 'dart_module'))
                .existsSync(),
            isTrue,);
        expect(
            Directory(path.join(workflowDir, 'modules', 'flutter_module'))
                .existsSync(),
            isTrue,);
        expect(
            Directory(path.join(workflowDir, 'modules', 'web_module'))
                .existsSync(),
            isTrue,);

        print('✅ 完整工作流测试通过');
      });

      test('应该能够处理错误场景', () async {
        // 测试无效命令
        var result = await Process.run(
          'dart',
          [mingCliPath, 'invalid_command'],
          workingDirectory: tempDir.path,
        );
        expect(result.exitCode, isNot(equals(0)));

        // 测试无效参数
        result = await Process.run(
          'dart',
          [mingCliPath, 'init', '--invalid-flag'],
          workingDirectory: tempDir.path,
        );
        expect(result.exitCode, isNot(equals(0)));

        // 测试在非项目目录中执行项目命令
        result = await Process.run(
          'dart',
          [mingCliPath, 'create', 'test_module'],
          workingDirectory: tempDir.path,
        );
        expect(result.exitCode, isNot(equals(0)));

        print('✅ 错误场景处理测试通过');
      });
    });

    group('用户场景验收测试', () {
      test('新用户首次使用场景', () async {
        final newUserDir = path.join(tempDir.path, 'new_user_scenario');

        // 1. 查看帮助
        var result = await Process.run(
          'dart',
          [mingCliPath, '--help'],
          workingDirectory: tempDir.path,
        );
        expect(result.exitCode, equals(0));

        // 2. 创建第一个项目
        result = await Process.run(
          'dart',
          [mingCliPath, 'init', 'my_first_project'],
          workingDirectory: tempDir.path,
        );
        expect(result.exitCode, equals(0));

        final projectDir = path.join(tempDir.path, 'my_first_project');

        // 3. 配置基本信息
        result = await Process.run(
          'dart',
          [mingCliPath, 'config', '--set', 'user.name=New User'],
          workingDirectory: projectDir,
        );
        expect(result.exitCode, equals(0));

        // 4. 创建第一个模块
        result = await Process.run(
          'dart',
          [mingCliPath, 'create', 'hello_world', '--type=dart'],
          workingDirectory: projectDir,
        );
        expect(result.exitCode, equals(0));

        // 5. 验证项目
        result = await Process.run(
          'dart',
          [mingCliPath, 'validate'],
          workingDirectory: projectDir,
        );
        expect(result.exitCode, equals(0));

        print('✅ 新用户首次使用场景测试通过');
      });

      test('开发者日常使用场景', () async {
        final devDir = path.join(tempDir.path, 'developer_scenario');

        // 1. 快速创建项目
        var result = await Process.run(
          'dart',
          [mingCliPath, 'init', 'daily_project'],
          workingDirectory: tempDir.path,
        );
        expect(result.exitCode, equals(0));

        final projectDir = path.join(tempDir.path, 'daily_project');

        // 2. 批量创建模块
        final modules = ['auth', 'api', 'ui', 'utils'];
        for (final module in modules) {
          result = await Process.run(
            'dart',
            [mingCliPath, 'create', module, '--type=dart'],
            workingDirectory: projectDir,
          );
          expect(result.exitCode, equals(0));
        }

        // 3. 检查配置
        result = await Process.run(
          'dart',
          [mingCliPath, 'config', '--list'],
          workingDirectory: projectDir,
        );
        expect(result.exitCode, equals(0));

        // 4. 验证所有模块
        result = await Process.run(
          'dart',
          [mingCliPath, 'validate'],
          workingDirectory: projectDir,
        );
        expect(result.exitCode, equals(0));

        print('✅ 开发者日常使用场景测试通过');
      });

      test('团队协作场景', () async {
        final teamDir = path.join(tempDir.path, 'team_scenario');

        // 1. 团队负责人创建项目
        var result = await Process.run(
          'dart',
          [mingCliPath, 'init', 'team_project'],
          workingDirectory: tempDir.path,
        );
        expect(result.exitCode, equals(0));

        final projectDir = path.join(tempDir.path, 'team_project');

        // 2. 设置团队配置
        result = await Process.run(
          'dart',
          [mingCliPath, 'config', '--set', 'team.name=Development Team'],
          workingDirectory: projectDir,
        );
        expect(result.exitCode, equals(0));

        // 3. 创建项目结构
        final components = ['frontend', 'backend', 'shared'];
        for (final component in components) {
          result = await Process.run(
            'dart',
            [mingCliPath, 'create', component, '--type=dart'],
            workingDirectory: projectDir,
          );
          expect(result.exitCode, equals(0));
        }

        // 4. 验证项目结构
        result = await Process.run(
          'dart',
          [mingCliPath, 'validate'],
          workingDirectory: projectDir,
        );
        expect(result.exitCode, equals(0));

        print('✅ 团队协作场景测试通过');
      });
    });

    group('性能和稳定性验收', () {
      test('应该能够处理大量模块创建', () async {
        final perfDir = path.join(tempDir.path, 'performance_test');

        // 初始化项目
        var result = await Process.run(
          'dart',
          [mingCliPath, 'init', 'performance_test'],
          workingDirectory: tempDir.path,
        );
        expect(result.exitCode, equals(0));

        final projectDir = path.join(tempDir.path, 'performance_test');

        // 创建多个模块
        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 10; i++) {
          result = await Process.run(
            'dart',
            [mingCliPath, 'create', 'module_$i', '--type=dart'],
            workingDirectory: projectDir,
          );
          expect(result.exitCode, equals(0));
        }

        stopwatch.stop();

        // 验证性能
        expect(stopwatch.elapsedMilliseconds, lessThan(30000), // 30秒
            reason: '创建10个模块应该在30秒内完成',);

        // 验证所有模块都创建成功
        for (var i = 0; i < 10; i++) {
          expect(
              Directory(path.join(projectDir, 'modules', 'module_$i'))
                  .existsSync(),
              isTrue,);
        }

        print('⏱️  性能测试: 创建10个模块用时 ${stopwatch.elapsedMilliseconds}ms');
        print('✅ 大量模块创建性能测试通过');
      });

      test('应该能够处理并发操作', () async {
        final concurrentDir = path.join(tempDir.path, 'concurrent_test');

        // 初始化项目
        final result = await Process.run(
          'dart',
          [mingCliPath, 'init', 'concurrent_test'],
          workingDirectory: tempDir.path,
        );
        expect(result.exitCode, equals(0));

        final projectDir = path.join(tempDir.path, 'concurrent_test');

        // 并发执行多个配置命令
        final futures = <Future<ProcessResult>>[];
        for (var i = 0; i < 5; i++) {
          futures.add(Process.run(
            'dart',
            [mingCliPath, 'config', '--set', 'test.key$i=value$i'],
            workingDirectory: projectDir,
          ),);
        }

        final results = await Future.wait(futures);

        // 验证所有操作都成功
        for (final result in results) {
          expect(result.exitCode, equals(0));
        }

        print('✅ 并发操作测试通过');
      });
    });

    group('跨平台兼容性验收', () {
      test('应该能够在当前平台正常运行', () async {
        final platformDir = path.join(tempDir.path, 'platform_test');

        // 测试基本功能在当前平台的兼容性
        var result = await Process.run(
          'dart',
          [mingCliPath, 'init', 'platform_test'],
          workingDirectory: tempDir.path,
        );
        expect(result.exitCode, equals(0));

        final projectDir = path.join(tempDir.path, 'platform_test');

        // 测试路径处理
        result = await Process.run(
          'dart',
          [mingCliPath, 'create', 'path_test', '--type=dart'],
          workingDirectory: projectDir,
        );
        expect(result.exitCode, equals(0));

        // 验证文件系统操作
        expect(
            Directory(path.join(projectDir, 'modules', 'path_test'))
                .existsSync(),
            isTrue,);

        print('✅ 当前平台 (${Platform.operatingSystem}) 兼容性测试通过');
      });
    });
  });
}
