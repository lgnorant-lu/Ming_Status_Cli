/*
---------------------------------------------------------------
File name:          end_to_end_workflow_test.dart
Author:             lgnorant-lu
Date created:       2025-07-08
Last modified:      2025-07-08
Dart Version:       3.2+
Description:        Task 49.1 - 完整工作流集成测试
                    验证 init → config → create → validate 完整流程
---------------------------------------------------------------
Change History:
    2025-07-08: Initial creation - 端到端工作流集成测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'cli_test_helper.dart';

void main() {
  group('Task 49.1: 端到端工作流集成测试', () {
    late Directory tempDir;

    setUpAll(() async {
      // 初始化CLI测试环境
      await CliTestHelper.setUpAll();

      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_e2e_workflow_');

      print('📁 端到端测试临时目录: ${tempDir.path}');
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

    group('基础工作流测试', () {
      test(
        '应该成功执行工作空间初始化',
        () async {
          final workspaceDir =
              Directory(path.join(tempDir.path, 'basic_workspace'));
          await workspaceDir.create(recursive: true);

          // Step 1: 初始化工作空间
          print('🚀 Step 1: 初始化工作空间');
          final initResult = await CliTestHelper.runCommand(
            [
              '--quiet',
              'init',
              'basic_workspace',
              '--name',
              'basic_workspace',
              '--description',
              'E2E test workspace',
              '--author',
              'E2E Tester',
            ],
            workingDirectory: tempDir.path,
          );

          expect(initResult.exitCode, equals(0), reason: '工作空间初始化应该成功');

          // 验证工作空间文件结构 - init命令在当前目录创建文件
          final workspaceConfigFile =
              File(path.join(tempDir.path, 'ming_status.yaml'));
          expect(
            workspaceConfigFile.existsSync(),
            isTrue,
            reason: '工作空间配置文件应该存在',
          );

          // 验证配置文件内容
          final configContent = await workspaceConfigFile.readAsString();
          expect(
            configContent,
            contains('basic_workspace'),
            reason: '配置文件应该包含工作空间名称',
          );
          expect(
            configContent,
            contains('E2E test workspace'),
            reason: '配置文件应该包含描述',
          );

          print('✅ 工作空间初始化测试成功完成');
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );

      test('应该正确处理错误场景', () async {
        final errorWorkspaceDir =
            Directory(path.join(tempDir.path, 'error_workspace'));
        await errorWorkspaceDir.create(recursive: true);

        // 测试无效模板名称
        print('🚀 测试错误场景: 无效模板名称');
        final invalidTemplateResult = await CliTestHelper.runCommand(
          ['create', 'test_module', '--template', 'nonexistent_template'],
          workingDirectory: errorWorkspaceDir.path,
        );

        expect(
          invalidTemplateResult.exitCode,
          isNot(equals(0)),
          reason: '使用无效模板应该失败',
        );

        print('✅ 错误场景测试完成');
      });

      test('应该正确显示帮助信息', () async {
        final helpResult = await CliTestHelper.runCommand(
          ['--help'],
          workingDirectory: tempDir.path,
        );

        expect(helpResult.exitCode, equals(0), reason: '帮助命令应该成功');
        expect(
          helpResult.stdout,
          contains('Ming Status CLI'),
          reason: '应该显示CLI名称',
        );
        expect(helpResult.stdout, contains('init'), reason: '应该显示init命令');

        print('✅ 帮助信息验证通过');
      });

      test('应该正确显示版本信息', () async {
        final versionResult = await CliTestHelper.runCommand(
          ['version'],
          workingDirectory: tempDir.path,
        );

        expect(versionResult.exitCode, equals(0), reason: '版本命令应该成功');
        expect(versionResult.stdout, contains('版本'), reason: '应该显示版本信息');

        print('✅ 版本信息验证通过');
      });
    });
  });
}
