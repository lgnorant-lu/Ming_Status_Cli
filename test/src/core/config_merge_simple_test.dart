/*
* ---------------------------------------------------------------
* File name:          config_merge_simple_test.dart
* Author:             lgnorant-lu
* Date created:       2025/06/29
* Last modified:      2025/06/29
* Dart Version:       3.2+
* Description:        简化的配置合并测试用例 - 专注于验证基本功能
* ---------------------------------------------------------------
* Change History:
*     2025/06/29: Initial creation;
* ---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/core/config_manager.dart';
import 'package:ming_status_cli/src/core/user_config_manager.dart';
import 'package:ming_status_cli/src/models/user_config.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// 专门的测试用户配置管理器，使用临时目录
class TestUserConfigManagerSimple extends UserConfigManager {
  TestUserConfigManagerSimple(this._testDir);
  final String _testDir;

  @override
  String get userConfigDir => _testDir;
}

void main() {
  group('简化配置合并测试', () {
    late Directory tempDir;
    late TestUserConfigManagerSimple userConfigManager;
    late ConfigManager configManager;
    late String workspaceDir;

    setUp(() async {
      // 创建临时目录
      tempDir =
          await Directory.systemTemp.createTemp('ming_config_simple_test_');

      // 设置测试目录结构
      workspaceDir = path.join(tempDir.path, 'workspace');
      await Directory(workspaceDir).create();

      // 初始化管理器
      userConfigManager = TestUserConfigManagerSimple(tempDir.path);
      configManager = ConfigManager(workingDirectory: workspaceDir);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('基础功能验证', () {
      test('用户配置基本读写', () async {
        // 创建用户配置
        const userConfig = UserConfig(
          user: UserInfo(
            name: 'Test User',
            email: 'test@example.com',
          ),
          preferences: UserPreferences(),
          defaults: UserDefaults(
            author: 'Test Author',
            license: 'MIT',
            dartVersion: '^3.2.0',
          ),
        );

        // 保存用户配置
        await userConfigManager.saveUserConfig(userConfig);

        // 验证可以正确加载
        final loadedConfig = await userConfigManager.loadUserConfig();
        expect(loadedConfig, isNotNull);
        expect(loadedConfig!.user.name, equals('Test User'));
        expect(loadedConfig.preferences.defaultTemplate, equals('basic'));
        expect(loadedConfig.defaults.author, equals('Test Author'));
      });

      test('工作空间配置基本初始化', () async {
        // 使用ConfigManager的初始化方法
        final success = await configManager.initializeWorkspace(
          workspaceName: 'Test Workspace',
          description: 'Test Description',
          author: 'Test Author',
        );

        expect(success, isTrue);

        // 验证可以加载工作空间配置
        final loadedConfig = await configManager.loadWorkspaceConfig();
        expect(loadedConfig, isNotNull);
        expect(loadedConfig!.workspace.name, equals('Test Workspace'));
        expect(loadedConfig.defaults.author, equals('Test Author'));
      });

      test('用户配置值获取', () async {
        // 创建用户配置
        const userConfig = UserConfig(
          user: UserInfo(name: 'Test User'),
          preferences: UserPreferences(),
          defaults: UserDefaults(
            author: 'Test Author',
            license: 'MIT',
            dartVersion: '^3.2.0',
          ),
        );

        await userConfigManager.saveUserConfig(userConfig);

        // 测试配置值获取
        expect(
          await userConfigManager.getConfigValue('user.name'),
          equals('Test User'),
        );
        expect(
          await userConfigManager.getConfigValue('preferences.defaultTemplate'),
          equals('basic'),
        );
        expect(
          await userConfigManager.getConfigValue('defaults.author'),
          equals('Test Author'),
        );
        expect(
          await userConfigManager.getConfigValue('defaults.license'),
          equals('MIT'),
        );
        expect(
          await userConfigManager.getConfigValue('nonexistent.key'),
          isNull,
        );
      });

      test('用户配置值设置', () async {
        // 创建基础用户配置
        const userConfig = UserConfig(
          user: UserInfo(name: 'Original User'),
          preferences: UserPreferences(),
          defaults: UserDefaults(
            author: 'Original Author',
            license: 'MIT',
            dartVersion: '^3.2.0',
          ),
        );

        await userConfigManager.saveUserConfig(userConfig);

        // 设置新值
        await userConfigManager.setConfigValue('user.name', 'Updated User');
        await userConfigManager.setConfigValue(
          'defaults.author',
          'Updated Author',
        );

        // 验证设置生效
        expect(
          await userConfigManager.getConfigValue('user.name'),
          equals('Updated User'),
        );
        expect(
          await userConfigManager.getConfigValue('defaults.author'),
          equals('Updated Author'),
        );

        // 验证其他值不受影响
        expect(
          await userConfigManager.getConfigValue('defaults.license'),
          equals('MIT'),
        );
      });
    });

    group('配置优先级基础验证', () {
      test('用户配置和工作空间配置共存', () async {
        // 1. 创建用户配置
        const userConfig = UserConfig(
          user: UserInfo(name: 'User Name'),
          preferences: UserPreferences(),
          defaults: UserDefaults(
            author: 'User Author',
            license: 'MIT',
            dartVersion: '^3.2.0',
          ),
        );
        await userConfigManager.saveUserConfig(userConfig);

        // 2. 创建工作空间配置
        final workspaceSuccess = await configManager.initializeWorkspace(
          workspaceName: 'Workspace Name',
          description: 'Workspace Description',
          author: 'Workspace Author',
        );
        expect(workspaceSuccess, isTrue);

        // 3. 验证两个配置都可以独立加载
        final loadedUserConfig = await userConfigManager.loadUserConfig();
        final loadedWorkspaceConfig = await configManager.loadWorkspaceConfig();

        expect(loadedUserConfig, isNotNull);
        expect(loadedWorkspaceConfig, isNotNull);

        // 4. 验证配置内容正确
        expect(loadedUserConfig!.user.name, equals('User Name'));
        expect(loadedUserConfig.defaults.author, equals('User Author'));

        expect(loadedWorkspaceConfig!.workspace.name, equals('Workspace Name'));
        expect(
          loadedWorkspaceConfig.defaults.author,
          equals('Workspace Author'),
        );
      });
    });

    group('边界条件测试', () {
      test('处理空用户配置', () async {
        // 不存在配置文件时的默认行为
        final loadedConfig = await userConfigManager.loadUserConfig();
        expect(loadedConfig, isNotNull);
        // 应该返回默认配置
        expect(loadedConfig!.user.name, isNotEmpty);
        expect(loadedConfig.defaults.author, isNotEmpty);
      });

      test('处理损坏的用户配置文件', () async {
        // 创建损坏的JSON文件
        final userConfigPath = path.join(tempDir.path, 'user_config.json');
        await File(userConfigPath).writeAsString('{"invalid": json}');

        // 应该能够处理损坏的文件并返回默认配置
        final loadedConfig = await userConfigManager.loadUserConfig();
        expect(loadedConfig, isNotNull);
        expect(loadedConfig!.user.name, isNotEmpty);
      });
    });
  });
}
