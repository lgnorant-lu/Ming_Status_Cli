/*
---------------------------------------------------------------
File name:          cli_integration_test.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        CLI集成测试套件 (CLI integration test suite)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - CLI基础功能集成测试;
---------------------------------------------------------------
*/

import 'package:test/test.dart';
import 'cli_test_helper.dart';

void main() {
  group('CLI集成测试', () {
    setUpAll(() async {
      await CliTestHelper.setUpAll();
    });

    tearDownAll(() async {
      await CliTestHelper.tearDownAll();
    });

    group('基础CLI功能', () {
      test('应该显示帮助信息', () async {
        final result = await CliTestHelper.runCommand(['--help']);

        CliTestHelper.expectSuccess(result);
        CliTestHelper.expectOutput(result, 'Ming Status CLI');
        // 系统级UTF-8设置已生效，现在可以正确匹配中文字符串
        CliTestHelper.expectOutput(result, '可用命令'); // 检查中文帮助标题
        // 功能性测试：检查帮助内容的关键元素
        CliTestHelper.expectOutput(result, 'doctor'); // 检查doctor命令存在
        CliTestHelper.expectOutput(result, 'init'); // 检查init命令存在
        CliTestHelper.expectOutput(result, 'version'); // 检查version命令存在
        CliTestHelper.expectOutput(result, '--help'); // 检查help选项说明
        CliTestHelper.expectOutput(result, '--verbose'); // 检查verbose选项说明
        CliTestHelper.expectDuration(result, const Duration(seconds: 6));
      });

      test('应该显示版本信息', () async {
        final result = await CliTestHelper.runCommand(['--version']);

        CliTestHelper.expectSuccess(result);
        CliTestHelper.expectOutput(result, 'Ming Status CLI 1.0.0');
        CliTestHelper.expectDuration(result, const Duration(seconds: 6));
      });

      test('应该处理未知命令', () async {
        final result = await CliTestHelper.runCommand(['unknown-command']);

        CliTestHelper.expectFailure(result);
        CliTestHelper.expectOutput(result, 'Could not find a command named');
      });
    });

    group('命令测试', () {
      test('help命令应该工作正常', () async {
        final result = await CliTestHelper.runCommand(['help']);

        CliTestHelper.expectSuccess(result);
        // 系统级UTF-8设置已生效，现在可以正确匹配中文字符串
        CliTestHelper.expectOutput(result, '可用命令'); // 检查中文帮助标题
        // 功能性测试：验证help命令显示所有核心命令
        CliTestHelper.expectOutput(result, 'doctor');
        CliTestHelper.expectOutput(result, 'init');
        CliTestHelper.expectOutput(result, 'version');
        CliTestHelper.expectOutput(result, 'help'); // help命令本身也应该列出
      });

      test('version命令应该工作正常', () async {
        final result = await CliTestHelper.runCommand(['version']);

        CliTestHelper.expectSuccess(result);
        CliTestHelper.expectOutput(result, 'Ming Status CLI 1.0.0');
      });

      test('version --detailed应该显示详细信息', () async {
        final result =
            await CliTestHelper.runCommand(['version', '--detailed']);

        CliTestHelper.expectSuccess(result);
        CliTestHelper.expectOutput(result, 'Ming Status CLI');
        // 系统级UTF-8设置已生效，现在可以正确匹配中文字符串
        CliTestHelper.expectOutput(result, 'Dart版本'); // 检查中文版本信息标签
        // 功能性测试：检查详细版本信息的关键元素
        CliTestHelper.expectOutput(result, 'Dart'); // 应该显示Dart相关信息
        CliTestHelper.expectOutput(result, 'windows'); // 应该显示操作系统信息
        CliTestHelper.expectOutput(result, '1.0.0'); // 应该显示版本号
      });

      test('doctor命令应该工作正常', () async {
        final result = await CliTestHelper.runCommand(['doctor']);

        CliTestHelper.expectSuccess(result);
        CliTestHelper.expectOutput(result, 'Ming Status CLI');
        CliTestHelper.expectOutput(result, '(5/5)');
      });

      test('doctor --detailed应该显示详细检查', () async {
        final result = await CliTestHelper.runCommand(['doctor', '--detailed']);

        CliTestHelper.expectSuccess(result);
        CliTestHelper.expectOutput(result, 'Dart SDK:');
        CliTestHelper.expectOutput(result, 'pubspec.yaml');
        CliTestHelper.expectOutput(result, 'windows');
      });
    });

    group('性能测试', () {
      test('help命令应该快速响应', () async {
        final result = await CliTestHelper.runCommand(['help']);

        CliTestHelper.expectSuccess(result);
        CliTestHelper.expectDuration(result, const Duration(seconds: 6));
      });

      test('version命令应该快速响应', () async {
        final result = await CliTestHelper.runCommand(['version']);

        CliTestHelper.expectSuccess(result);
        CliTestHelper.expectDuration(result, const Duration(seconds: 6));
      });

      test('doctor命令应该在合理时间内完成', () async {
        final result = await CliTestHelper.runCommand(['doctor']);

        CliTestHelper.expectSuccess(result);
        CliTestHelper.expectDuration(result, const Duration(seconds: 10));
      });
    });

    group('错误处理', () {
      test('应该处理无效参数', () async {
        final result =
            await CliTestHelper.runCommand(['version', '--invalid-flag']);

        CliTestHelper.expectFailure(result);
      });

      test('应该提供有用的错误信息', () async {
        final result =
            await CliTestHelper.runCommand(['init', '--invalid-option']);

        CliTestHelper.expectFailure(result);
        CliTestHelper.expectOutput(result, 'Could not find an option named');
      });
    });
  });
}
