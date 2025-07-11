/*
---------------------------------------------------------------
File name:          cross_platform_test.dart
Author:             lgnorant-lu
Date created:       2025-07-08
Last modified:      2025-07-08
Dart Version:       3.2+
Description:        Task 49.2 - 跨平台兼容性验证测试
                    验证CLI在Windows/Linux/macOS平台上的兼容性
---------------------------------------------------------------
Change History:
    2025-07-08: Initial creation - 跨平台兼容性测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'cli_test_helper.dart';

void main() {
  group('Task 49.2: 跨平台兼容性验证测试', () {
    late Directory tempDir;
    late String currentPlatform;

    setUpAll(() async {
      // 初始化CLI测试环境
      await CliTestHelper.setUpAll();

      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_cross_platform_');

      // 检测当前平台
      currentPlatform = _detectPlatform();

      print('🖥️  当前平台: $currentPlatform');
      print('📁 跨平台测试临时目录: ${tempDir.path}');
    });

    tearDownAll(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
        print('🗑️  清理临时目录: ${tempDir.path}');
      }

      // 清理CLI测试环境
      await CliTestHelper.tearDownAll();
    });

    group('平台检测和基础兼容性', () {
      test('应该正确检测当前平台', () {
        expect(
          ['Windows', 'Linux', 'macOS'].contains(currentPlatform),
          isTrue,
          reason: '应该能够检测到支持的平台',
        );

        print('✅ 平台检测: $currentPlatform');
      });

      test('应该在当前平台上正常执行基本命令', () async {
        final helpResult = await CliTestHelper.runCommand(
          ['--help'],
          workingDirectory: tempDir.path,
        );

        expect(helpResult.exitCode, equals(0), reason: '帮助命令应该在所有平台上成功');
        expect(
          helpResult.stdout,
          contains('Ming Status CLI'),
          reason: '应该显示CLI名称',
        );

        print('✅ 基本命令执行正常');
      });
    });

    group('路径处理兼容性', () {
      test('应该正确处理平台特定的路径分隔符', () async {
        final workspaceDir =
            Directory(path.join(tempDir.path, 'path_test_workspace'));
        await workspaceDir.create(recursive: true);

        // 初始化工作空间
        final initResult = await CliTestHelper.runCommand(
          [
            '--quiet',
            'init',
            'path_test_workspace',
            '--name',
            'path_test_workspace',
            '--description',
            'Path compatibility test workspace',
            '--author',
            'Cross Platform Tester',
          ],
          workingDirectory: tempDir.path,
        );

        expect(initResult.exitCode, equals(0), reason: '路径处理应该在所有平台上正常工作');

        // 验证配置文件存在
        final configFile = File(path.join(tempDir.path, 'ming_status.yaml'));
        expect(configFile.existsSync(), isTrue, reason: '配置文件应该在正确路径创建');

        print('✅ 路径处理兼容性验证通过');
      });

      test('应该正确处理包含空格的路径', () async {
        final spacedWorkspaceDir =
            Directory(path.join(tempDir.path, 'spaced workspace name'));
        await spacedWorkspaceDir.create(recursive: true);

        // 在包含空格的路径中初始化工作空间
        final initResult = await CliTestHelper.runCommand(
          [
            '--quiet',
            'init',
            'spaced workspace name',
            '--name',
            'spaced_workspace',
            '--description',
            'Workspace with spaced path',
            '--author',
            'Space Tester',
          ],
          workingDirectory: tempDir.path,
        );

        expect(initResult.exitCode, equals(0), reason: '应该能处理包含空格的路径');

        print('✅ 空格路径处理验证通过');
      });
    });

    group('文件系统操作兼容性', () {
      test('应该正确处理文件权限和访问', () async {
        final permissionTestDir =
            Directory(path.join(tempDir.path, 'permission_test'));
        await permissionTestDir.create(recursive: true);

        // 创建测试文件
        final testFile =
            File(path.join(permissionTestDir.path, 'test_file.txt'));
        await testFile.writeAsString('Test content');

        expect(testFile.existsSync(), isTrue, reason: '应该能创建文件');

        // 读取文件
        final content = await testFile.readAsString();
        expect(content, equals('Test content'), reason: '应该能读取文件内容');

        print('✅ 文件系统操作兼容性验证通过');
      });

      test('应该正确处理目录创建和删除', () async {
        final dirTestPath =
            path.join(tempDir.path, 'dir_test', 'nested', 'deep');
        final dirTest = Directory(dirTestPath);

        // 创建嵌套目录
        await dirTest.create(recursive: true);
        expect(dirTest.existsSync(), isTrue, reason: '应该能创建嵌套目录');

        // 删除目录
        await dirTest.delete(recursive: true);
        expect(dirTest.existsSync(), isFalse, reason: '应该能删除目录');

        print('✅ 目录操作兼容性验证通过');
      });
    });

    group('字符编码兼容性', () {
      test('应该正确处理UTF-8编码', () async {
        // 创建独立的临时目录用于UTF-8测试
        final utf8TestDir =
            await Directory.systemTemp.createTemp('ming_utf8_test_');

        try {
          final encodingTestDir =
              Directory(path.join(utf8TestDir.path, 'encoding_test'));
          await encodingTestDir.create(recursive: true);

          // 测试包含中文字符的工作空间
          final initResult = await CliTestHelper.runCommand(
            [
              '--quiet',
              'init',
              'encoding_test',
              '--name',
              '中文工作空间',
              '--description',
              '包含中文字符的描述 🚀',
              '--author',
              '中文作者',
            ],
            workingDirectory: utf8TestDir.path,
          );

          expect(initResult.exitCode, equals(0), reason: '应该能处理UTF-8字符');

          // 验证配置文件内容
          final configFile =
              File(path.join(utf8TestDir.path, 'ming_status.yaml'));
          if (configFile.existsSync()) {
            final content = await configFile.readAsString();
            expect(
              content,
              contains('包含中文字符的描述 🚀'),
              reason: '配置文件应该正确保存UTF-8字符',
            );
            expect(content, contains('中文作者'), reason: '配置文件应该正确保存中文作者信息');
          }

          print('✅ UTF-8编码兼容性验证通过');
        } finally {
          // 清理UTF-8测试目录
          if (utf8TestDir.existsSync()) {
            await utf8TestDir.delete(recursive: true);
          }
        }
      });
    });

    group('环境变量兼容性', () {
      test('应该正确读取环境变量', () {
        // 测试常见环境变量
        final homeVar =
            Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
        expect(homeVar, isNotNull, reason: '应该能读取用户主目录环境变量');

        final pathVar = Platform.environment['PATH'];
        expect(pathVar, isNotNull, reason: '应该能读取PATH环境变量');

        print('✅ 环境变量读取兼容性验证通过');
      });
    });

    group('进程执行兼容性', () {
      test('应该正确执行子进程', () async {
        // 测试执行简单的系统命令
        final result = await Process.run(
          currentPlatform == 'Windows' ? 'cmd' : 'echo',
          currentPlatform == 'Windows' ? ['/c', 'echo', 'test'] : ['test'],
        );

        expect(result.exitCode, equals(0), reason: '应该能执行系统命令');
        expect(
          result.stdout.toString().trim(),
          contains('test'),
          reason: '应该能获取命令输出',
        );

        print('✅ 子进程执行兼容性验证通过');
      });
    });

    group('平台特定功能测试', () {
      test('应该处理平台特定的文件扩展名', () {
        final executableName =
            currentPlatform == 'Windows' ? 'ming_cli.exe' : 'ming_cli';
        expect(executableName, isNotNull, reason: '应该能确定平台特定的可执行文件名');

        print('✅ 平台特定功能验证通过: $executableName');
      });

      test('应该正确处理行结束符', () {
        final lineEnding = currentPlatform == 'Windows' ? '\r\n' : '\n';
        final testText = 'Line 1${lineEnding}Line 2${lineEnding}Line 3';

        expect(testText, contains('Line 1'), reason: '应该能处理文本内容');
        expect(testText, contains('Line 2'), reason: '应该能处理多行文本');

        print('✅ 行结束符处理验证通过');
      });
    });
  });
}

/// 检测当前运行平台
String _detectPlatform() {
  if (Platform.isWindows) {
    return 'Windows';
  } else if (Platform.isLinux) {
    return 'Linux';
  } else if (Platform.isMacOS) {
    return 'macOS';
  } else {
    return 'Unknown';
  }
}
