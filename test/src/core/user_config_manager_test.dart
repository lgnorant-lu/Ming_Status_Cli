/*
---------------------------------------------------------------
File name:          user_config_manager_test.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        用户配置管理器的完整单元测试
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 用户配置管理器单元测试;
---------------------------------------------------------------
*/

import 'package:test/test.dart';
import 'package:ming_status_cli/src/core/user_config_manager.dart';
import 'package:ming_status_cli/src/models/user_config.dart';
import 'package:ming_status_cli/src/models/workspace_config.dart';
import 'dart:io';

void main() {
  group('UserConfigManager Tests', () {
    late UserConfigManager manager;
    late Directory tempDir;
    late String testConfigDir;

    setUp(() async {
      // 创建临时目录用于测试
      tempDir = await Directory.systemTemp.createTemp('ming_test_');
      testConfigDir = '${tempDir.path}/.ming';

      // 创建使用临时目录的管理器
      manager = TestUserConfigManager(testConfigDir);
    });

    tearDown(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Initialization Tests', () {
      test('should have proper config directory structure', () async {
        // 初始化用户配置
        final result = await manager.initializeUserConfig(
          userName: '测试用户',
          userEmail: 'test@example.com',
          company: '测试公司',
        );

        expect(result, isTrue);
        expect(Directory(testConfigDir).existsSync(), isTrue);
        expect(File('$testConfigDir/config.json').existsSync(), isTrue);
      });

      test('should return false when not initialized', () {
        expect(manager.isUserConfigInitialized(), isFalse);
      });

      test('should return true when initialized', () async {
        await manager.initializeUserConfig();
        expect(manager.isUserConfigInitialized(), isTrue);
      });
    });

    group('Configuration File Operations', () {
      test('should save and load user config correctly', () async {
        final testConfig = UserConfig(
          user: const UserInfo(
            name: '测试用户',
            email: 'test@example.com',
            company: '测试公司',
          ),
          preferences: const UserPreferences(
            defaultTemplate: 'advanced',
            coloredOutput: false,
            verboseLogging: true,
          ),
          defaults: const UserDefaults(
            author: '测试用户',
            license: 'Apache-2.0',
            dartVersion: '^3.3.0',
          ),
        );

        // 保存配置
        final saveResult = await manager.saveUserConfig(testConfig);
        expect(saveResult, isTrue);

        // 清理缓存
        manager.clearCache();

        // 加载配置
        final loadedConfig = await manager.loadUserConfig(useCache: false);
        expect(loadedConfig, isNotNull);
        expect(loadedConfig!.user.name, equals('测试用户'));
        expect(loadedConfig.preferences.defaultTemplate, equals('advanced'));
        expect(loadedConfig.defaults.license, equals('Apache-2.0'));
      });

      test('should create default config when file does not exist', () async {
        // 确保没有配置文件
        expect(manager.isUserConfigInitialized(), isFalse);

        // 尝试加载配置
        final config = await manager.loadUserConfig();
        expect(config, isNotNull);
        expect(config!.user.name, equals('开发者名称'));
        expect(config.preferences.defaultTemplate, equals('basic'));
      });

      test('should update user config using update function', () async {
        // 初始化配置
        await manager.initializeUserConfig(userName: '原始用户');

        // 更新配置
        final updateResult = await manager.updateUserConfig((config) {
          return config.copyWith(
            user: config.user.copyWith(name: '更新用户'),
          );
        });

        expect(updateResult, isTrue);

        // 验证更新
        final updatedConfig = await manager.loadUserConfig(useCache: false);
        expect(updatedConfig!.user.name, equals('更新用户'));
      });
    });

    group('Configuration Management', () {
      test('should get configuration value by key path', () async {
        await manager.initializeUserConfig(userName: '测试用户');

        final value = await manager.getConfigValue('user.name');
        expect(value, equals('测试用户'));
      });

      test('should set configuration value by key path', () async {
        await manager.initializeUserConfig();

        final result = await manager.setConfigValue('user.name', '新用户名');
        expect(result, isTrue);

        final value = await manager.getConfigValue('user.name');
        expect(value, equals('新用户名'));
      });

      test('should reset user config to defaults', () async {
        // 先设置一些自定义值
        await manager.initializeUserConfig(userName: '自定义用户');
        await manager.setConfigValue('user.name', '修改后的用户名');

        // 重置配置
        final resetResult = await manager.resetUserConfig();
        expect(resetResult, isTrue);

        // 验证重置后的值
        final config = await manager.loadUserConfig(useCache: false);
        expect(config!.user.name, equals('开发者名称'));
      });

      test('should list all configuration values', () async {
        await manager.initializeUserConfig(userName: '列表测试用户');

        final allConfig = await manager.listAllConfig();
        expect(allConfig, isNotEmpty);
        expect(allConfig['user'], isNotNull);
        expect(allConfig['preferences'], isNotNull);
        expect(allConfig['defaults'], isNotNull);
      });
    });

    group('Configuration Merging', () {
      test('should merge user config with workspace config correctly',
          () async {
        await manager.initializeUserConfig(
          userName: '用户作者',
        );

        const workspaceConfig = WorkspaceConfig(
          workspace: WorkspaceInfo(name: '工作空间项目', version: '1.0.0'),
          templates: TemplateConfig(source: TemplateSource.local),
          defaults: DefaultSettings(
            author: '工作空间作者',
            license: 'Apache-2.0',
            dartVersion: '^3.3.0',
            description: '工作空间描述',
          ),
          validation: ValidationConfig(
            strictMode: false,
            requireTests: true,
            minCoverage: 80,
          ),
        );

        final merged = await manager.mergeWithWorkspaceConfig(workspaceConfig);
        expect(merged, isNotNull);

        // 工作空间配置应该覆盖用户配置
        expect(merged!.defaults.author, equals('工作空间作者'));
        expect(merged.defaults.license, equals('Apache-2.0'));
        expect(merged.defaults.dartVersion, equals('^3.3.0'));
      });

      test('should handle command line overrides in merge', () async {
        await manager.initializeUserConfig(userName: '用户作者');

        const workspaceConfig = WorkspaceConfig(
          workspace: WorkspaceInfo(name: '测试工作空间', version: '1.0.0'),
          templates: TemplateConfig(source: TemplateSource.local),
          defaults: DefaultSettings(
            author: '工作空间作者',
            license: 'MIT',
            dartVersion: '^3.2.0',
          ),
          validation: ValidationConfig(
            strictMode: false,
            requireTests: true,
            minCoverage: 80,
          ),
        );

        final overrides = {
          'author': '命令行作者',
          'license': 'GPL-3.0',
        };

        final merged = await manager.mergeWithWorkspaceConfig(
          workspaceConfig,
          overrides: overrides,
        );

        expect(merged!.defaults.author, equals('命令行作者'));
        expect(merged.defaults.license, equals('GPL-3.0'));
        expect(merged.defaults.dartVersion, equals('^3.2.0')); // 来自工作空间
      });
    });

    group('Caching Mechanism', () {
      test('should cache loaded configuration', () async {
        await manager.initializeUserConfig(userName: '缓存测试用户');

        // 第一次加载（从文件）
        final config1 = await manager.loadUserConfig();
        expect(config1!.user.name, equals('缓存测试用户'));

        // 第二次加载（从缓存）
        final config2 = await manager.loadUserConfig(useCache: true);
        expect(config2!.user.name, equals('缓存测试用户'));

        // 验证是同一个对象（从缓存加载）
        expect(identical(config1, config2), isTrue);
      });

      test('should invalidate cache when config is saved', () async {
        await manager.initializeUserConfig(userName: '缓存失效测试');

        // 加载配置到缓存
        final config1 = await manager.loadUserConfig();
        expect(config1!.user.name, equals('缓存失效测试'));

        // 更新配置（应该清除缓存）
        final newConfig = config1.copyWith(
          user: config1.user.copyWith(name: '更新缓存测试'),
        );
        await manager.saveUserConfig(newConfig);

        // 重新加载（应该从文件而不是缓存）
        final config2 = await manager.loadUserConfig();
        expect(config2!.user.name, equals('更新缓存测试'));
      });
    });

    group('Configuration Summary', () {
      test('should provide config summary when not initialized', () {
        final summary = manager.getUserConfigSummary();
        expect(summary['initialized'], isFalse);
      });

      test('should provide detailed config summary when initialized', () async {
        await manager.initializeUserConfig(
          userName: '摘要测试用户',
          userEmail: 'summary@test.com',
        );

        final summary = manager.getUserConfigSummary();
        expect(summary['initialized'], isTrue);
        expect(summary['user_name'], equals('摘要测试用户'));
        expect(summary['user_email'], equals('summary@test.com'));
        expect(summary['default_template'], equals('basic'));
        expect(summary['preferred_ide'], equals('vscode'));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle invalid key paths gracefully in setConfigValue',
          () async {
        await manager.initializeUserConfig();

        // 测试无效的键路径
        final result =
            await manager.setConfigValue('invalid.deep.path', 'value');
        expect(result, isFalse);
      });

      test('should handle boolean values in setConfigValue', () async {
        await manager.initializeUserConfig();

        // 设置布尔值
        final result =
            await manager.setConfigValue('preferences.coloredOutput', 'true');
        expect(result, isTrue);

        final value = await manager.getConfigValue('preferences.coloredOutput');
        expect(value, equals('true'));
      });

      test('should handle missing user config in merge operation', () async {
        // 不初始化用户配置
        const workspaceConfig = WorkspaceConfig(
          workspace: WorkspaceInfo(name: '测试工作空间', version: '1.0.0'),
          templates: TemplateConfig(source: TemplateSource.local),
          defaults: DefaultSettings(
            author: '工作空间作者',
            license: 'MIT',
            dartVersion: '^3.2.0',
          ),
          validation: ValidationConfig(
            strictMode: false,
            requireTests: true,
            minCoverage: 80,
          ),
        );

        final merged = await manager.mergeWithWorkspaceConfig(workspaceConfig);
        expect(merged, isNotNull);
        expect(merged!.defaults.author, equals('工作空间作者'));
      });
    });

    group('Performance Tests', () {
      test('should load configuration within acceptable time', () async {
        await manager.initializeUserConfig();

        final stopwatch = Stopwatch()..start();
        await manager.loadUserConfig();
        stopwatch.stop();

        // 配置加载应该在100ms内完成
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should save configuration within acceptable time', () async {
        final config = UserConfig.defaultConfig();

        final stopwatch = Stopwatch()..start();
        await manager.saveUserConfig(config);
        stopwatch.stop();

        // 配置保存应该在500ms内完成
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });
  });
}

/// 测试专用的UserConfigManager，支持自定义配置目录
class TestUserConfigManager extends UserConfigManager {
  final String _testConfigDir;

  TestUserConfigManager(this._testConfigDir);

  @override
  String get userConfigDir => _testConfigDir;
}
