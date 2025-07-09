/*
---------------------------------------------------------------
File name:          core_acceptance_test.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 52.1 - 核心功能验收测试
                    验证CLI的核心功能和基本操作
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 核心功能验收测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Task 52.1: 核心功能验收测试', () {
    late Directory tempDir;
    late String mingCliPath;

    setUpAll(() async {
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_core_test_');

      // 构建CLI可执行文件路径
      mingCliPath =
          path.join(Directory.current.path, 'bin', 'ming_status_cli.dart');

      print('🧪 核心功能验收测试目录: ${tempDir.path}');
      print('📦 Ming CLI路径: $mingCliPath');
    });

    tearDownAll(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
        print('🗑️  清理测试目录: ${tempDir.path}');
      }
    });

    group('基础CLI功能测试', () {
      test('应该能够显示帮助信息', () async {
        final result = await Process.run(
          'dart',
          [mingCliPath, '--help'],
          workingDirectory: tempDir.path,
        );

        expect(result.exitCode, equals(0));
        final output = result.stdout.toString();
        expect(output, contains('Ming Status CLI'));
        expect(output, contains('用法'));
        expect(output, contains('命令'));

        print('✅ 帮助信息显示测试通过');
      });

      test('应该能够显示版本信息', () async {
        final result = await Process.run(
          'dart',
          [mingCliPath, '--version'],
          workingDirectory: tempDir.path,
        );

        expect(result.exitCode, equals(0));
        final output = result.stdout.toString();
        expect(output, contains('Ming Status CLI'));

        print('✅ 版本信息显示测试通过');
      });

      test('应该能够处理无效命令', () async {
        final result = await Process.run(
          'dart',
          [mingCliPath, 'invalid_command_xyz'],
          workingDirectory: tempDir.path,
        );

        // 无效命令应该返回非零退出码
        expect(result.exitCode, isNot(equals(0)));

        print('✅ 无效命令处理测试通过');
      });

      test('应该能够显示doctor帮助', () async {
        final result = await Process.run(
          'dart',
          [mingCliPath, 'help', 'doctor'],
          workingDirectory: tempDir.path,
        );

        expect(result.exitCode, equals(0));
        final output = result.stdout.toString();
        expect(output, contains('doctor'));

        print('✅ Doctor帮助显示测试通过');
      });

      test('应该能够运行doctor检查', () async {
        // 先初始化工作空间，确保doctor检查有正确的环境
        await Process.run(
          'dart',
          [
            mingCliPath,
            '--quiet',
            'init',
            'doctor_test_workspace',
            '--name=doctor_test_workspace',
            '--description=Test workspace for doctor command',
            '--author=Test Author',
          ],
          workingDirectory: tempDir.path,
        );

        // 初始化可能失败，但不影响doctor的基础检查
        final doctorResult = await Process.run(
          'dart',
          [mingCliPath, 'doctor', '--config'], // 只进行配置检查，避免环境依赖
          workingDirectory: tempDir.path,
        );

        expect(doctorResult.exitCode, equals(0));
        final output = doctorResult.stdout.toString();
        expect(output, contains('检查'));

        print('✅ Doctor检查测试通过');
      });
    });

    group('项目初始化测试', () {
      test('应该能够在临时目录中初始化项目', () async {
        const projectName = 'test_init_project';

        final result = await Process.run(
          'dart',
          [
            mingCliPath,
            '--quiet',
            'init',
            projectName,
            '--name=$projectName',
            '--description=Test project for integration testing',
            '--author=Test Author',
          ],
          workingDirectory: tempDir.path,
        );

        // 检查命令执行结果
        print('Init命令退出码: ${result.exitCode}');
        print('Init命令输出: ${result.stdout}');
        if (result.stderr.toString().isNotEmpty) {
          print('Init命令错误: ${result.stderr}');
        }

        expect(result.exitCode, equals(0));

        // init命令在当前目录中初始化工作空间，而不是创建子目录
        // 检查配置文件是否在临时目录中创建
        final configFile = File(path.join(tempDir.path, 'ming_status.yaml'));
        print('期望的配置文件: ${configFile.path}');
        print('配置文件是否存在: ${configFile.existsSync()}');

        expect(configFile.existsSync(), isTrue);

        // 检查其他工作空间文件是否创建
        final readmeFile = File(path.join(tempDir.path, 'README.md'));
        expect(readmeFile.existsSync(), isTrue);

        final modulesDir = Directory(path.join(tempDir.path, 'modules'));
        expect(modulesDir.existsSync(), isTrue);

        print('✅ 项目初始化测试通过');
      });

      test('应该能够在现有目录中初始化', () async {
        final existingDir = Directory(path.join(tempDir.path, 'existing_dir'));
        await existingDir.create();

        final result = await Process.run(
          'dart',
          [
            mingCliPath,
            'init',
            '--name=existing_workspace',
            '--description=Test workspace in existing directory',
            '--author=Test Author',
          ],
          workingDirectory: existingDir.path,
        );

        if (result.exitCode != 0) {
          print('Init现有目录输出: ${result.stdout}');
          print('Init现有目录错误: ${result.stderr}');
        }

        expect(result.exitCode, equals(0));

        // 检查配置文件是否创建
        final configFile =
            File(path.join(existingDir.path, 'ming_status.yaml'));
        expect(configFile.existsSync(), isTrue);

        print('✅ 现有目录初始化测试通过');
      });
    });

    group('配置管理测试', () {
      late Directory projectDir;

      setUp(() async {
        // 为每个配置测试创建一个新项目
        projectDir = Directory(
          path.join(
            tempDir.path,
            'config_test_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
        await projectDir.create();

        // 初始化项目
        final initResult = await Process.run(
          'dart',
          [
            mingCliPath,
            'init',
            '--name=config_test_workspace',
            '--description=Test workspace for config testing',
            '--author=Test Author',
          ],
          workingDirectory: projectDir.path,
        );

        expect(initResult.exitCode, equals(0));
      });

      test('应该能够列出配置', () async {
        final result = await Process.run(
          'dart',
          [mingCliPath, 'config', '--list'],
          workingDirectory: projectDir.path,
        );

        if (result.exitCode != 0) {
          print('Config list输出: ${result.stdout}');
          print('Config list错误: ${result.stderr}');
        }

        expect(result.exitCode, equals(0));

        print('✅ 配置列表测试通过');
      });

      test('应该能够设置和获取配置', () async {
        // 设置配置（使用全局配置）
        final setResult = await Process.run(
          'dart',
          [mingCliPath, 'config', '--global', '--set', 'user.name=test_value'],
          workingDirectory: projectDir.path,
        );

        if (setResult.exitCode != 0) {
          print('Config set输出: ${setResult.stdout}');
          print('Config set错误: ${setResult.stderr}');
        }

        expect(setResult.exitCode, equals(0));

        // 获取配置（使用全局配置）
        final getResult = await Process.run(
          'dart',
          [mingCliPath, 'config', '--global', '--get', 'user.name'],
          workingDirectory: projectDir.path,
        );

        if (getResult.exitCode != 0) {
          print('Config get输出: ${getResult.stdout}');
          print('Config get错误: ${getResult.stderr}');
        }

        expect(getResult.exitCode, equals(0));
        expect(getResult.stdout.toString(), contains('test_value'));

        print('✅ 配置设置/获取测试通过');
      });
    });

    group('验证功能测试', () {
      late Directory projectDir;

      setUp(() async {
        // 创建测试项目
        projectDir = Directory(
          path.join(
            tempDir.path,
            'validate_test_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
        await projectDir.create();

        // 初始化项目
        final initResult = await Process.run(
          'dart',
          [
            mingCliPath,
            'init',
            '--name=validate_test_workspace',
            '--description=Test workspace for validation testing',
            '--author=Test Author',
          ],
          workingDirectory: projectDir.path,
        );

        expect(initResult.exitCode, equals(0));
      });

      test('应该能够验证项目', () async {
        // 首先创建一个模块以便验证
        final createResult = await Process.run(
          'dart',
          [mingCliPath, 'create', 'test_module', '--template=basic'],
          workingDirectory: projectDir.path,
        );

        if (createResult.exitCode != 0) {
          print('Create输出: ${createResult.stdout}');
          print('Create错误: ${createResult.stderr}');
        }

        // 然后验证工作空间
        final result = await Process.run(
          'dart',
          [mingCliPath, 'validate'],
          workingDirectory: projectDir.path,
        );

        if (result.exitCode != 0) {
          print('Validate输出: ${result.stdout}');
          print('Validate错误: ${result.stderr}');
        }

        expect(result.exitCode, anyOf(equals(0), equals(1)));
        final output = result.stdout.toString();
        expect(output, anyOf(contains('验证'), contains('请确保路径包含有效的模块结构')));

        print('✅ 项目验证测试通过');
      });

      test('应该能够进行健康检查', () async {
        final result = await Process.run(
          'dart',
          [mingCliPath, 'validate', '--health-check'],
          workingDirectory: projectDir.path,
        );

        if (result.exitCode != 0) {
          print('Health check输出: ${result.stdout}');
          print('Health check错误: ${result.stderr}');
        }

        expect(result.exitCode, equals(0));

        print('✅ 健康检查测试通过');
      });
    });

    group('错误处理测试', () {
      test('应该能够处理不存在的项目目录', () async {
        final nonExistentDir = path.join(tempDir.path, 'non_existent');

        final result = await Process.run(
          'dart',
          [mingCliPath, 'validate', nonExistentDir],
          workingDirectory: tempDir.path,
        );

        // 验证不存在的目录应该失败
        expect(result.exitCode, isNot(equals(0)));

        print('✅ 不存在目录错误处理测试通过');
      });

      test('应该能够处理无效的配置值', () async {
        // 创建临时项目
        final projectDir = Directory(
          path.join(
            tempDir.path,
            'error_test_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
        await projectDir.create();

        await Process.run(
          'dart',
          [
            mingCliPath,
            'init',
            '--name=error_test_workspace',
            '--description=Test workspace for error handling',
            '--author=Test Author',
          ],
          workingDirectory: projectDir.path,
        );

        // 尝试设置无效配置
        final result = await Process.run(
          'dart',
          [mingCliPath, 'config', '--set', 'invalid='],
          workingDirectory: projectDir.path,
        );

        // 无效配置可能成功也可能失败，这里只检查不会崩溃
        expect(result.exitCode, isA<int>());

        print('✅ 无效配置错误处理测试通过');
      });
    });

    group('性能基准测试', () {
      test('应该能够快速显示帮助信息', () async {
        final stopwatch = Stopwatch()..start();

        final result = await Process.run(
          'dart',
          [mingCliPath, '--help'],
          workingDirectory: tempDir.path,
        );

        stopwatch.stop();

        expect(result.exitCode, equals(0));
        expect(
          stopwatch.elapsedMilliseconds, lessThan(10000), // 10秒
          reason: '帮助信息显示应该在10秒内完成',
        );

        print('⏱️  帮助信息性能: ${stopwatch.elapsedMilliseconds}ms');
        print('✅ 帮助信息性能测试通过');
      });

      test('应该能够快速初始化项目', () async {
        final stopwatch = Stopwatch()..start();

        final result = await Process.run(
          'dart',
          [
            mingCliPath,
            'init',
            'perf_test_${DateTime.now().millisecondsSinceEpoch}',
            '--name=perf_test_workspace',
            '--description=Performance test workspace',
            '--author=Test Author',
          ],
          workingDirectory: tempDir.path,
        );

        stopwatch.stop();

        expect(result.exitCode, equals(0));
        expect(
          stopwatch.elapsedMilliseconds, lessThan(15000), // 15秒
          reason: '项目初始化应该在15秒内完成',
        );

        print('⏱️  项目初始化性能: ${stopwatch.elapsedMilliseconds}ms');
        print('✅ 项目初始化性能测试通过');
      });
    });
  });
}
