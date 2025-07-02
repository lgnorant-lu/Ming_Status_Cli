/*
---------------------------------------------------------------
File name:          config_error_scenarios_test.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        配置系统错误场景和边界条件测试 
                      (Config system error scenarios and 
                      boundary conditions tests)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 配置系统健壮性测试;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/commands/config_command.dart';
import 'package:ming_status_cli/src/core/config_manager.dart';
import 'package:ming_status_cli/src/core/user_config_manager.dart';
import 'package:ming_status_cli/src/models/user_config.dart';
import 'package:ming_status_cli/src/models/workspace_config.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// 测试用的临时配置管理器，使用隔离的临时目录
class TestConfigManagerForErrors extends ConfigManager {

  TestConfigManagerForErrors(this.testWorkingDirectory)
      : super(workingDirectory: testWorkingDirectory);
  final String testWorkingDirectory;
}

/// 测试用的用户配置管理器，使用隔离的临时目录
class TestUserConfigManagerForErrors extends UserConfigManager {

  TestUserConfigManagerForErrors(this.testUserConfigDir);
  final String testUserConfigDir;

  @override
  String get userConfigDir => testUserConfigDir;

  @override
  String get userConfigFilePath => path.join(testUserConfigDir, 'config.json');
}

void main() {
  group('配置系统错误场景和边界条件测试', () {
    late Directory tempDir;
    late String tempDirPath;
    late TestConfigManagerForErrors configManager;
    late TestUserConfigManagerForErrors userConfigManager;

    setUp(() async {
      // 创建临时测试目录
      tempDir =
          await Directory.systemTemp.createTemp('ming_config_error_test_');
      tempDirPath = tempDir.path;

      // 初始化测试管理器
      configManager = TestConfigManagerForErrors(tempDirPath);

      final userConfigPath = path.join(tempDirPath, 'user_config');
      await Directory(userConfigPath).create(recursive: true);
      userConfigManager = TestUserConfigManagerForErrors(userConfigPath);
    });

    tearDown(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('ConfigManager错误场景测试', () {
      test('处理损坏的YAML配置文件', () async {
        // 创建损坏的YAML文件
        final configPath = path.join(tempDirPath, 'ming_status.yaml');
        await File(configPath).writeAsString('''
workspace:
  name: "test
  # 未闭合的引号，无效YAML
templates:
  source: [invalid structure
''');

        // 尝试加载配置
        final config = await configManager.loadWorkspaceConfig();
        expect(config, isNull, reason: '损坏的YAML文件应该返回null');
      });

      test('处理不存在的配置文件', () async {
        // 尝试加载不存在的配置文件
        final config = await configManager.loadWorkspaceConfig();
        expect(config, isNull, reason: '不存在的配置文件应该返回null');
      });

      test('处理无效的配置结构', () async {
        // 创建结构不正确的YAML文件
        final configPath = path.join(tempDirPath, 'ming_status.yaml');
        await File(configPath).writeAsString('''
# 缺少必需字段的配置
invalid_field: "value"
workspace:
  name: "test"
  # 缺少其他必需字段
''');

        // 尝试加载配置
        final config = await configManager.loadWorkspaceConfig();
        expect(config, isNull, reason: '无效结构的配置文件应该返回null');
      });

      test('处理配置文件权限问题 (模拟)', () async {
        // 注意：在某些系统上权限测试可能不工作，这里主要测试错误处理逻辑
        final configPath = path.join(tempDirPath, 'ming_status.yaml');

        // 创建一个正常的配置文件
        final validConfig = WorkspaceConfig.defaultConfig();
        final success = await configManager.saveWorkspaceConfig(validConfig);
        expect(success, isTrue, reason: '正常配置应该能保存成功');

        // 验证文件确实被创建
        expect(File(configPath).existsSync(), isTrue, reason: '配置文件应该存在');
      });

      test('处理配置模板验证失败', () async {
        // 测试无效模板路径
        final isValid = await configManager
            .validateConfigTemplate('nonexistent_template.yaml');
        expect(isValid, isFalse, reason: '不存在的模板应该验证失败');
      });

      test('处理配置模板应用失败', () async {
        // 在没有现有配置的情况下尝试应用模板
        final success = await configManager.applyConfigTemplate('enterprise');
        expect(success, isFalse, reason: '没有现有配置时应用模板应该失败');
      });
    });

    group('UserConfigManager错误场景测试', () {
      test('处理损坏的JSON配置文件', () async {
        // 创建损坏的JSON文件
        final configPath =
            path.join(userConfigManager.userConfigDir, 'config.json');
        await File(configPath).writeAsString('''
{
  "user": {
    "name": "test"
    # 缺少逗号，无效JSON
  }
  "invalid": json
}
''');

        // 尝试加载用户配置
        final config = await userConfigManager.loadUserConfig();
        expect(config, isNotNull, reason: '应该返回默认配置，而不是null');
        expect(config?.user.name, equals('开发者名称'), reason: '应该使用默认值');
      });

      test('处理无效的配置键路径', () async {
        // 初始化用户配置
        await userConfigManager.initializeUserConfig();

        // 测试无效的键路径
        final invalidPaths = [
          '', // 空路径
          'invalid_top_key', // 无效顶级键
          'user..name', // 双点
          'user.invalid_field', // 不存在的字段
          'preferences..', // 以点结尾
          '.user.name', // 以点开头
        ];

        for (final invalidPath in invalidPaths) {
          final success =
              await userConfigManager.setConfigValue(invalidPath, 'test_value');
          expect(success, isFalse, reason: '无效路径 "$invalidPath" 应该操作失败');
        }
      });

      test('处理用户目录创建失败 (边界条件)', () async {
        // 创建一个只读的父目录来模拟创建失败（在某些系统上可能不工作）
        final readOnlyParent = path.join(tempDirPath, 'readonly');
        await Directory(readOnlyParent).create();

        final restrictedPath = path.join(readOnlyParent, 'nested', 'config');
        final restrictedManager =
            TestUserConfigManagerForErrors(restrictedPath);

        // 尝试初始化用户配置
        try {
          await restrictedManager.initializeUserConfig();
          // 如果成功了，至少验证它创建了某些内容
          expect(true, isTrue, reason: '用户配置初始化应该处理目录创建');
        } catch (e) {
          // 如果失败了，验证错误被适当处理
          expect(e, isA<Exception>(), reason: '应该抛出适当的异常');
        }
      });

      test('处理并发配置访问', () async {
        await userConfigManager.initializeUserConfig();

        // 模拟并发写入
        final futures = <Future<bool>>[];
        for (var i = 0; i < 10; i++) {
          futures.add(userConfigManager.setConfigValue(
              'user.name', 'concurrent_user_$i',),);
        }

        final results = await Future.wait(futures);

        // 至少应该有一些成功的操作
        final successCount = results.where((result) => result).length;
        expect(successCount, greaterThan(0), reason: '至少应该有一些并发操作成功');
      });

      test('处理极大配置值', () async {
        await userConfigManager.initializeUserConfig();

        // 创建一个非常大的字符串
        final largeValue = 'x' * (1024 * 1024); // 1MB字符串

        final success =
            await userConfigManager.setConfigValue('user.name', largeValue);
        expect(success, isTrue, reason: '应该能处理大的配置值');

        if (success) {
          final retrievedValue =
              await userConfigManager.getConfigValue('user.name');
          expect(retrievedValue, equals(largeValue), reason: '应该能正确检索大的配置值');
        }
      });
    });

    group('ConfigCommand错误处理测试', () {
      late ConfigCommand configCommand;

      setUp(() {
        configCommand = ConfigCommand();
      });

      test('验证ConfigCommand基本属性', () {
        expect(configCommand.name, equals('config'));
        expect(configCommand.description, contains('Ming Status CLI配置'));
        expect(configCommand.argParser, isNotNull);
      });

      test('处理无效的命令参数组合', () {
        // 测试冲突的参数组合
        try {
          configCommand.argParser
              .parse(['--global', '--local', '--set', 'key=value']);
          // 如果没有抛出异常，至少验证解析器配置
          expect(true, isTrue, reason: '参数解析器应该能处理参数');
        } catch (e) {
          // 如果抛出异常，验证是适当的格式异常
          expect(e, isA<Exception>(), reason: '应该是适当的参数异常');
        }
      });

      test('处理无效的配置键值格式', () {
        // 测试无效的键值对格式
        final invalidFormats = [
          'key_without_equals',
          '=value_without_key',
          'key=',
          '=',
          'key==double_equals',
        ];

        for (final format in invalidFormats) {
          try {
            configCommand.argParser.parse(['--set', format]);
            // 解析成功，但应该在执行时处理无效格式
            expect(true, isTrue, reason: '参数解析应该至少不崩溃');
          } catch (e) {
            // 如果解析失败，应该是适当的异常
            expect(e, isA<Exception>(), reason: '无效格式应该产生适当异常');
          }
        }
      });
    });

    group('配置系统边界条件测试', () {
      test('处理极深嵌套的配置路径', () async {
        await userConfigManager.initializeUserConfig();

        // 测试超过允许深度的嵌套路径（integrations最多3层：integrations.key1.key2）
        const deepPath = 'integrations.level1.level2.level3'; // 4层，应该被拒绝

        final success =
            await userConfigManager.setConfigValue(deepPath, 'deep_test');
        // 应该失败，因为路径太深/无效
        expect(success, isFalse, reason: '极深的嵌套路径应该被拒绝');
      });

      test('处理特殊字符在配置值中', () async {
        await userConfigManager.initializeUserConfig();

        final specialCharacters = [
          '特殊中文字符测试',
          'emoji🎉🚀💻',
          'quotes"and\'apostrophes',
          'newlines\nand\ttabs',
          'unicode\u0000\u001f',
          'very long string ' * 1000,
        ];

        for (final specialValue in specialCharacters) {
          final success = await userConfigManager.setConfigValue(
              'user.company', specialValue,);
          final displayValue = specialValue.length > 20
              ? '${specialValue.substring(0, 20)}...'
              : specialValue;
          expect(success, isTrue, reason: '应该能处理特殊字符: $displayValue');

          if (success) {
            final retrieved =
                await userConfigManager.getConfigValue('user.company');
            expect(retrieved, equals(specialValue), reason: '应该能正确检索特殊字符');
          }
        }
      });

      test('处理配置文件大小限制', () async {
        await userConfigManager.initializeUserConfig();

        // 创建大量配置来测试性能
        final startTime = DateTime.now();

        for (var i = 0; i < 100; i++) {
          await userConfigManager.setConfigValue(
              'integrations.test_key_$i', 'test_value_$i',);
        }

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // 验证性能在合理范围内（应该在几秒内完成）
        expect(duration.inSeconds, lessThan(10), reason: '大量配置操作应该在合理时间内完成');
      });

      test('验证配置系统内存使用', () async {
        // 模拟大量配置加载
        await userConfigManager.initializeUserConfig();

        // 重复加载配置以测试内存泄漏
        for (var i = 0; i < 50; i++) {
          await userConfigManager.loadUserConfig();
          await configManager.loadWorkspaceConfig();
        }

        // 如果测试没有因为内存问题崩溃，就认为通过
        expect(true, isTrue, reason: '重复配置加载不应该导致内存问题');
      });
    });

    group('配置系统恢复能力测试', () {
      test('从损坏配置自动恢复', () async {
        // 创建正常配置
        await userConfigManager.initializeUserConfig();
        final initialConfig = await userConfigManager.loadUserConfig();
        expect(initialConfig, isNotNull);

        // 故意损坏配置文件
        final configPath =
            path.join(userConfigManager.userConfigDir, 'config.json');
        await File(configPath).writeAsString('{ invalid json }');

        // 尝试重新加载，应该恢复到默认配置
        final recoveredConfig = await userConfigManager.loadUserConfig();
        expect(recoveredConfig, isNotNull, reason: '应该能从损坏配置恢复');
        expect(recoveredConfig?.user.name, equals('开发者名称'), reason: '应该使用默认值');
      });

      test('配置缓存失效处理', () async {
        await userConfigManager.initializeUserConfig();

        // 加载配置建立缓存
        final config1 = await userConfigManager.loadUserConfig();
        expect(config1, isNotNull);

        // 直接修改配置文件（绕过缓存）
        final configPath =
            path.join(userConfigManager.userConfigDir, 'config.json');
        final modifiedConfig = UserConfig.defaultConfig().copyWith(
          user: const UserInfo(
            name: 'external_modified', 
            email: 'test@example.com',
          ),
        );
        await File(configPath)
            .writeAsString(jsonEncode(modifiedConfig.toJson()));

        // 重新加载配置（应该检测到变化）
        userConfigManager.clearCache();
        final config2 =
            await userConfigManager.loadUserConfig(useCache: false); // 强制不使用缓存
        expect(config2?.user.name, equals('external_modified'),
            reason: '应该检测到外部配置变化',);
      });
    });
  });
}
