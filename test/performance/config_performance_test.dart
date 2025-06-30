/*
---------------------------------------------------------------
File name:          config_performance_test.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        配置系统性能测试 (Configuration system performance tests)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 配置系统性能NFR验证测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/config_manager.dart';
import 'package:ming_status_cli/src/core/user_config_manager.dart';
import 'package:ming_status_cli/src/models/user_config.dart';
import 'package:ming_status_cli/src/models/workspace_config.dart';
import 'package:test/test.dart';

void main() {
  group('配置系统性能测试', () {
    late Directory tempDir;
    late ConfigManager configManager;
    late UserConfigManager userConfigManager;

    setUp(() async {
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_perf_test_');
      
      // 初始化配置管理器
      configManager = ConfigManager(workingDirectory: tempDir.path);
      userConfigManager = UserConfigManager();
      
      // 预先初始化工作空间
      await configManager.initializeWorkspace(
        workspaceName: 'performance_test_workspace',
        description: 'Performance test workspace',
        author: 'Performance Tester',
      );
    });

    tearDown(() async {
      // 清理临时目录
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('工作空间配置性能测试', () {
      test('工作空间配置读取应小于500ms', () async {
        const maxDuration = Duration(milliseconds: 500);
        
        // 预热（避免首次IO开销影响测试结果）
        await configManager.loadWorkspaceConfig();
        
        // 执行性能测试
        final stopwatch = Stopwatch()..start();
        
        // 执行多次读取操作以获得平均性能
        for (var i = 0; i < 10; i++) {
          final config = await configManager.loadWorkspaceConfig();
          expect(config, isNotNull);
        }
        
        stopwatch.stop();
        final averageDuration = Duration(
          microseconds: stopwatch.elapsed.inMicroseconds ~/ 10,
        );
        
        print('工作空间配置平均读取时间: ${averageDuration.inMilliseconds}ms');
        expect(averageDuration, lessThan(maxDuration));
      });

      test('工作空间配置写入应小于500ms', () async {
        const maxDuration = Duration(milliseconds: 500);
        
        // 获取基础配置
        final baseConfig = await configManager.loadWorkspaceConfig();
        expect(baseConfig, isNotNull);
        
        // 执行性能测试
        final stopwatch = Stopwatch()..start();
        
        // 执行多次写入操作
        for (var i = 0; i < 5; i++) {
          final updatedConfig = baseConfig!.copyWith(
            workspace: WorkspaceInfo(
              name: '${baseConfig.workspace.name}_$i',
              version: baseConfig.workspace.version,
              description: '${baseConfig.workspace.description} - Updated $i',
              type: baseConfig.workspace.type,
            ),
          );
          
          final success = await configManager.saveWorkspaceConfig(updatedConfig);
          expect(success, isTrue);
        }
        
        stopwatch.stop();
        final averageDuration = Duration(
          microseconds: stopwatch.elapsed.inMicroseconds ~/ 5,
        );
        
        print('工作空间配置平均写入时间: ${averageDuration.inMilliseconds}ms');
        expect(averageDuration, lessThan(maxDuration));
      });

      test('配置更新操作应小于500ms', () async {
        const maxDuration = Duration(milliseconds: 500);
        
        // 执行性能测试
        final stopwatch = Stopwatch()..start();
        
        // 执行多次配置更新操作
        for (var i = 0; i < 5; i++) {
          final success = await configManager.updateWorkspaceConfig((config) {
            return config.copyWith(
              workspace: WorkspaceInfo(
                name: config.workspace.name,
                version: '1.0.$i',
                description: config.workspace.description,
                type: config.workspace.type,
              ),
            );
          });
          expect(success, isTrue);
        }
        
        stopwatch.stop();
        final averageDuration = Duration(
          microseconds: stopwatch.elapsed.inMicroseconds ~/ 5,
        );
        
        print('配置更新平均时间: ${averageDuration.inMilliseconds}ms');
        expect(averageDuration, lessThan(maxDuration));
      });
    });

    group('用户配置性能测试', () {
      test('用户配置读取应小于500ms', () async {
        const maxDuration = Duration(milliseconds: 500);
        
        // 预先初始化用户配置
        await userConfigManager.initializeUserConfig();
        
        // 预热
        await userConfigManager.loadUserConfig();
        
        // 执行性能测试
        final stopwatch = Stopwatch()..start();
        
        // 执行多次读取操作
        for (var i = 0; i < 10; i++) {
          final config = await userConfigManager.loadUserConfig();
          expect(config, isNotNull);
        }
        
        stopwatch.stop();
        final averageDuration = Duration(
          microseconds: stopwatch.elapsed.inMicroseconds ~/ 10,
        );
        
        print('用户配置平均读取时间: ${averageDuration.inMilliseconds}ms');
        expect(averageDuration, lessThan(maxDuration));
      });

      test('用户配置写入应小于500ms', () async {
        const maxDuration = Duration(milliseconds: 500);
        
        // 预先初始化用户配置
        await userConfigManager.initializeUserConfig();
        final baseConfig = await userConfigManager.loadUserConfig();
        expect(baseConfig, isNotNull);
        
        // 执行性能测试
        final stopwatch = Stopwatch()..start();
        
        // 执行多次写入操作
        for (var i = 0; i < 5; i++) {
          final updatedConfig = baseConfig!.copyWith(
            user: UserInfo(
              name: '性能测试用户_$i',
              email: 'perf_test_$i@example.com',
              company: baseConfig.user.company,
            ),
          );
          
          final success = await userConfigManager.saveUserConfig(updatedConfig);
          expect(success, isTrue);
        }
        
        stopwatch.stop();
        final averageDuration = Duration(
          microseconds: stopwatch.elapsed.inMicroseconds ~/ 5,
        );
        
        print('用户配置平均写入时间: ${averageDuration.inMilliseconds}ms');
        expect(averageDuration, lessThan(maxDuration));
      });
    });

    group('配置验证性能测试', () {
      test('配置验证应小于500ms', () async {
        const maxDuration = Duration(milliseconds: 500);
        
        final config = await configManager.loadWorkspaceConfig();
        expect(config, isNotNull);
        
        // 执行性能测试
        final stopwatch = Stopwatch()..start();
        
        // 执行多次验证操作
        for (var i = 0; i < 5; i++) {
          final validationResult = await configManager.validateWorkspaceConfig(
            config!,
            checkDependencies: false, // 关闭依赖检查以专注于配置验证性能
            checkFileSystem: false,   // 关闭文件系统检查以专注于配置验证性能
          );
          expect(validationResult, isNotNull);
        }
        
        stopwatch.stop();
        final averageDuration = Duration(
          microseconds: stopwatch.elapsed.inMicroseconds ~/ 5,
        );
        
        print('配置验证平均时间: ${averageDuration.inMilliseconds}ms');
        expect(averageDuration, lessThan(maxDuration));
      });

      test('模板验证应小于500ms', () async {
        const maxDuration = Duration(milliseconds: 500);
        
        // 执行性能测试
        final stopwatch = Stopwatch()..start();
        
        // 测试内置模板验证
        for (final templateType in ['basic', 'enterprise']) {
          for (var i = 0; i < 3; i++) {
            final isValid = await configManager.validateConfigTemplate(templateType);
            expect(isValid, isTrue);
          }
        }
        
        stopwatch.stop();
        final averageDuration = Duration(
          microseconds: stopwatch.elapsed.inMicroseconds ~/ 6,
        );
        
        print('模板验证平均时间: ${averageDuration.inMilliseconds}ms');
        expect(averageDuration, lessThan(maxDuration));
      });
    });

    group('并发配置操作性能测试', () {
      test('并发配置读取应保持良好性能', () async {
        const maxDuration = Duration(milliseconds: 1000); // 并发操作允许更长时间
        
        // 执行并发性能测试
        final stopwatch = Stopwatch()..start();
        
        final futures = <Future>[];
        
        // 创建10个并发读取操作
        for (var i = 0; i < 10; i++) {
          futures.add(configManager.loadWorkspaceConfig());
        }
        
        // 等待所有操作完成
        final results = await Future.wait(futures);
        
        stopwatch.stop();
        
        // 验证所有操作都成功
        for (final result in results) {
          expect(result, isNotNull);
        }
        
        print('并发配置读取总时间: ${stopwatch.elapsed.inMilliseconds}ms');
        expect(stopwatch.elapsed, lessThan(maxDuration));
      });
    });

    group('缓存性能测试', () {
      test('配置缓存应显著提升性能', () async {
        // 清除缓存，测试首次读取时间
        configManager.clearCache();
        
        final stopwatchFirst = Stopwatch()..start();
        final firstLoad = await configManager.loadWorkspaceConfig(useCache: false);
        stopwatchFirst.stop();
        
        expect(firstLoad, isNotNull);
        print('首次配置读取时间: ${stopwatchFirst.elapsed.inMilliseconds}ms');
        
        // 测试缓存读取时间
        final stopwatchCached = Stopwatch()..start();
        final cachedLoad = await configManager.loadWorkspaceConfig();
        stopwatchCached.stop();
        
        expect(cachedLoad, isNotNull);
        print('缓存配置读取时间: ${stopwatchCached.elapsed.inMilliseconds}ms');
        
        // 缓存读取应该明显更快（至少快50%）
        expect(
          stopwatchCached.elapsed.inMicroseconds * 2, 
          lessThan(stopwatchFirst.elapsed.inMicroseconds),
          reason: '缓存读取应该比首次读取快至少50%',
        );
      });
    });

    group('大型配置性能测试', () {
      test('大型配置文件应保持良好性能', () async {
        const maxDuration = Duration(milliseconds: 2000); // 大型配置允许更长时间
        
        // 创建大型配置（包含多个环境）
        final baseConfig = await configManager.loadWorkspaceConfig();
        expect(baseConfig, isNotNull);
        
        final largeEnvironments = <String, EnvironmentConfig>{};
        
        // 添加50个环境配置
        for (var i = 0; i < 50; i++) {
          largeEnvironments['env_$i'] = EnvironmentConfig(
            description: '环境配置 $i - 用于性能测试的大型配置',
            debug: i % 2 == 0,
            hotReload: i % 3 == 0,
            optimize: i % 4 == 0,
            minify: i % 5 == 0,
          );
        }
        
        final largeConfig = baseConfig!.copyWith(environments: largeEnvironments);
        
        // 执行性能测试
        final stopwatch = Stopwatch()..start();
        
        // 保存大型配置
        final saveSuccess = await configManager.saveWorkspaceConfig(largeConfig);
        expect(saveSuccess, isTrue);
        
        // 读取大型配置
        final loadedConfig = await configManager.loadWorkspaceConfig(useCache: false);
        expect(loadedConfig, isNotNull);
        expect(loadedConfig!.environments?.length, equals(50));
        
        stopwatch.stop();
        
        print('大型配置读写时间: ${stopwatch.elapsed.inMilliseconds}ms');
        expect(stopwatch.elapsed, lessThan(maxDuration));
      });
    });
  });
}

/// 性能测试结果摘要
/// 
/// 预期性能目标：
/// - 常规配置读写: < 500ms
/// - 大型配置处理: < 2s  
/// - 配置验证: < 500ms
/// - 并发操作: < 1s
/// - 缓存效果: 至少50%性能提升
/// 
/// 测试覆盖：
/// ✅ 工作空间配置读写性能
/// ✅ 用户配置读写性能
/// ✅ 配置验证性能
/// ✅ 模板验证性能
/// ✅ 并发操作性能
/// ✅ 缓存性能效果
/// ✅ 大型配置处理性能 
