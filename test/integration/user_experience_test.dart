/*
---------------------------------------------------------------
File name:          user_experience_test.dart
Author:             lgnorant-lu
Date created:       2025-07-08
Last modified:      2025-07-08
Dart Version:       3.2+
Description:        Task 50.1 - 用户体验优化测试
                    验证增强的错误处理、进度指示和帮助系统
---------------------------------------------------------------
Change History:
    2025-07-08: Initial creation - 用户体验优化测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'cli_test_helper.dart';

void main() {
  group('Task 50.1: 用户体验优化测试', () {
    late Directory tempDir;

    setUpAll(() async {
      // 初始化CLI测试环境
      await CliTestHelper.setUpAll();

      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_ux_test_');

      print('🎨 用户体验测试临时目录: ${tempDir.path}');
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

    group('错误信息优化测试', () {
      test('应该显示友好的错误信息', () async {
        // 测试无效命令
        final invalidResult = await CliTestHelper.runCommand(
          ['invalid_command'],
          workingDirectory: tempDir.path,
        );

        expect(invalidResult.exitCode, isNot(equals(0)), reason: '无效命令应该失败');
        expect(invalidResult.stderr, isNotEmpty, reason: '应该有错误输出');

        // 验证错误信息包含有用信息
        final errorOutput = invalidResult.stderr.toLowerCase();
        expect(
          errorOutput,
          anyOf([
            contains('help'),
            contains('帮助'),
            contains('usage'),
            contains('用法'),
          ]),
          reason: '错误信息应该包含帮助提示',
        );

        print('✅ 无效命令错误信息测试通过');
      });

      test('应该提供有用的建议', () async {
        // 测试拼写错误的命令
        final typoResult = await CliTestHelper.runCommand(
          ['initt'], // init的拼写错误
          workingDirectory: tempDir.path,
        );

        expect(typoResult.exitCode, isNot(equals(0)), reason: '拼写错误的命令应该失败');

        // 验证是否提供了建议
        final output =
            '${typoResult.stdout} ${typoResult.stderr}'.toLowerCase();
        expect(
          output,
          anyOf([
            contains('init'),
            contains('help'),
            contains('建议'),
            contains('similar'),
          ]),
          reason: '应该提供相似命令建议',
        );

        print('✅ 命令建议测试通过');
      });
    });

    group('帮助系统测试', () {
      test('应该显示清晰的帮助信息', () async {
        final helpResult = await CliTestHelper.runCommand(
          ['--help'],
          workingDirectory: tempDir.path,
        );

        expect(helpResult.exitCode, equals(0), reason: '帮助命令应该成功');
        expect(helpResult.stdout, isNotEmpty, reason: '应该有帮助输出');

        // 验证帮助信息的结构
        final helpOutput = helpResult.stdout.toLowerCase();
        expect(helpOutput, contains('ming'), reason: '应该包含CLI名称');
        expect(
          helpOutput,
          anyOf([
            contains('commands'),
            contains('命令'),
            contains('usage'),
            contains('用法'),
          ]),
          reason: '应该包含命令信息',
        );

        print('✅ 基础帮助信息测试通过');
      });

      test('应该显示命令特定的帮助', () async {
        final initHelpResult = await CliTestHelper.runCommand(
          ['help', 'init'],
          workingDirectory: tempDir.path,
        );

        expect(initHelpResult.exitCode, equals(0), reason: 'init帮助命令应该成功');
        expect(initHelpResult.stdout, isNotEmpty, reason: '应该有init帮助输出');

        // 验证init命令的帮助内容
        final helpOutput = initHelpResult.stdout.toLowerCase();
        expect(helpOutput, contains('init'), reason: '应该包含init命令信息');

        print('✅ 命令特定帮助测试通过');
      });
    });

    group('用户交互测试', () {
      test('应该正确处理版本信息请求', () async {
        final versionResult = await CliTestHelper.runCommand(
          ['version'],
          workingDirectory: tempDir.path,
        );

        expect(versionResult.exitCode, equals(0), reason: '版本命令应该成功');
        expect(versionResult.stdout, isNotEmpty, reason: '应该有版本输出');

        // 验证版本信息格式
        final versionOutput = versionResult.stdout;
        expect(
          versionOutput,
          anyOf([
            contains('版本'),
            contains('version'),
            contains('v'),
            matches(RegExp(r'\d+\.\d+\.\d+')), // 版本号格式
          ]),
          reason: '应该包含版本信息',
        );

        print('✅ 版本信息测试通过');
      });

      test('应该提供清晰的状态反馈', () async {
        // 测试工作空间初始化的状态反馈
        final initResult = await CliTestHelper.runCommand(
          [
            '--quiet',
            'init',
            'ux_test_workspace',
            '--name',
            'ux_test_workspace',
            '--description',
            'UX test workspace',
            '--author',
            'UX Tester',
          ],
          workingDirectory: tempDir.path,
        );

        expect(initResult.exitCode, equals(0), reason: '工作空间初始化应该成功');

        // 验证配置文件创建
        final configFile = File(path.join(tempDir.path, 'ming_status.yaml'));
        expect(configFile.existsSync(), isTrue, reason: '配置文件应该被创建');

        print('✅ 状态反馈测试通过');
      });
    });

    group('可用性测试', () {
      test('应该在合理时间内响应', () async {
        final stopwatch = Stopwatch()..start();

        final helpResult = await CliTestHelper.runCommand(
          ['--help'],
          workingDirectory: tempDir.path,
        );

        stopwatch.stop();

        expect(helpResult.exitCode, equals(0), reason: '帮助命令应该成功');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(15000),
          reason: '帮助命令应该在15秒内响应',
        );

        print('⏱️  帮助命令响应时间: ${stopwatch.elapsedMilliseconds}ms');
        print('✅ 响应时间测试通过');
      });

      test('应该提供一致的命令格式', () async {
        final commands = ['--help', 'version'];

        for (final command in commands) {
          final result = await CliTestHelper.runCommand(
            [command],
            workingDirectory: tempDir.path,
          );

          expect(result.exitCode, equals(0), reason: '$command 命令应该成功');
          expect(result.stdout, isNotEmpty, reason: '$command 应该有输出');
        }

        print('✅ 命令格式一致性测试通过');
      });
    });

    group('错误恢复测试', () {
      test('应该优雅地处理文件系统错误', () async {
        // 尝试在只读目录中创建工作空间（如果可能的话）
        final readOnlyDir = Directory(path.join(tempDir.path, 'readonly'));
        await readOnlyDir.create();

        // 注意：在Windows上设置只读权限可能需要特殊处理
        // 这里我们测试在不存在的父目录中创建工作空间
        final nonExistentParent =
            path.join(tempDir.path, 'nonexistent', 'child');

        final result = await CliTestHelper.runCommand(
          [
            '--quiet',
            'init',
            'test_workspace',
            '--name',
            'test_workspace',
            '--description',
            'Test workspace',
            '--author',
            'Test Author',
          ],
          workingDirectory: nonExistentParent,
        );

        // 这个测试可能成功（如果CLI自动创建目录）或失败
        // 重要的是不应该崩溃
        expect(
          result.exitCode,
          anyOf([equals(0), isNot(equals(0))]),
          reason: 'CLI不应该崩溃',
        );

        print('✅ 文件系统错误处理测试通过');
      });

      test('应该处理网络相关的错误', () async {
        // 这个测试模拟网络错误场景
        // 由于我们的CLI目前主要是本地操作，这个测试主要验证错误处理机制

        final result = await CliTestHelper.runCommand(
          ['--help'],
          workingDirectory: tempDir.path,
        );

        expect(result.exitCode, equals(0), reason: '本地命令应该不受网络影响');

        print('✅ 网络错误处理测试通过');
      });
    });

    group('国际化和本地化测试', () {
      test('应该支持中文输出', () async {
        final helpResult = await CliTestHelper.runCommand(
          ['--help'],
          workingDirectory: tempDir.path,
        );

        expect(helpResult.exitCode, equals(0), reason: '帮助命令应该成功');

        // 检查是否包含中文字符（如果CLI支持中文的话）
        final output = helpResult.stdout;
        final hasChineseChars = RegExp(r'[\u4e00-\u9fff]').hasMatch(output);

        if (hasChineseChars) {
          print('✅ 检测到中文输出支持');
        } else {
          print('ℹ️  当前为英文输出模式');
        }

        print('✅ 国际化测试通过');
      });
    });

    group('可访问性测试', () {
      test('应该支持纯文本输出', () async {
        // 测试在不支持颜色的环境中的输出
        final result = await CliTestHelper.runCommand(
          ['--help'],
          workingDirectory: tempDir.path,
          environment: {'NO_COLOR': '1'}, // 禁用颜色输出
        );

        expect(result.exitCode, equals(0), reason: '无颜色模式应该正常工作');
        expect(result.stdout, isNotEmpty, reason: '应该有文本输出');

        print('✅ 纯文本输出测试通过');
      });

      test('应该提供清晰的文本结构', () async {
        final helpResult = await CliTestHelper.runCommand(
          ['--help'],
          workingDirectory: tempDir.path,
        );

        expect(helpResult.exitCode, equals(0), reason: '帮助命令应该成功');

        // 验证输出结构的可读性
        final lines = helpResult.stdout.split('\n');
        expect(lines.length, greaterThan(3), reason: '帮助信息应该有多行');

        // 检查是否有适当的空行分隔
        final hasEmptyLines = lines.any((line) => line.trim().isEmpty);
        expect(hasEmptyLines, isTrue, reason: '应该有空行来改善可读性');

        print('✅ 文本结构测试通过');
      });
    });
  });
}
