/*
---------------------------------------------------------------
File name:          config_manager_test.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        配置管理器单元测试 (Config manager unit tests)
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/ming_status_cli.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigManager', () {
    late Directory tempDir;
    late ConfigManager configManager;

    setUp(() async {
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_status_test_');
      configManager = ConfigManager(workingDirectory: tempDir.path);
    });

    tearDown(() async {
      // 清理临时目录
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should detect uninitialized workspace', () {
      expect(configManager.isWorkspaceInitialized(), isFalse);
    });

    test('should initialize workspace successfully', () async {
      final result = await configManager.initializeWorkspace(
        workspaceName: 'test_workspace',
        description: 'Test workspace description',
        author: 'Test Author',
      );

      expect(result, isTrue);
      expect(configManager.isWorkspaceInitialized(), isTrue);
    });

    test('should load workspace config after initialization', () async {
      // 先初始化工作空间
      await configManager.initializeWorkspace(
        workspaceName: 'test_workspace',
        description: 'Test description',
        author: 'Test Author',
      );

      // 加载配置
      final config = await configManager.loadWorkspaceConfig();

      expect(config, isNotNull);
      expect(config!.workspace.name, equals('test_workspace'));
      expect(config.workspace.description, equals('Test description'));
      expect(config.defaults.author, equals('Test Author'));
    });

    test('should handle missing config file gracefully', () async {
      final config = await configManager.loadWorkspaceConfig();
      expect(config, isNull);
    });

    test('should clear cache correctly', () {
      // 这主要测试方法不会抛出异常
      expect(() => configManager.clearCache(), returnsNormally);
    });
  });
}
