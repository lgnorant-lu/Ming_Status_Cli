/*
---------------------------------------------------------------
File name:          config_advanced_features_test.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        高级配置功能测试 (Advanced configuration features test)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 配置继承、环境配置、配置合并等高级功能测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/config_manager.dart';
import 'package:ming_status_cli/src/models/workspace_config.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('ConfigManager 高级配置功能测试', () {
    late ConfigManager configManager;
    late Directory tempDir;

    setUp(() async {
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_test_advanced_');
      configManager = ConfigManager(workingDirectory: tempDir.path);
    });

    tearDown(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('配置继承功能测试', () {
      test('应该能够加载具有继承功能的配置', () async {
        // 创建基础配置
        await configManager.initializeWorkspace(
          workspaceName: 'test_workspace',
          description: '测试工作空间',
          author: '测试作者',
          templateType: 'basic',
        );

        // 测试加载具有继承功能的配置
        final config = await configManager.loadWorkspaceConfigWithInheritance();

        expect(config, isNotNull);
        expect(config!.workspace.name, equals('test_workspace'));
      });

      test('应该能够获取可用环境列表', () async {
        // 初始化工作空间
        await configManager.initializeWorkspace(
          workspaceName: 'test_workspace',
          templateType: 'basic',
        );

        final environments = await configManager.getAvailableEnvironments();

        expect(environments, isNotEmpty);
        expect(environments,
            containsAll(['development', 'testing', 'production']));
      });

      test('应该能够清除配置缓存', () {
        configManager.clearConfigCache();

        final cacheStatus = configManager.getCacheStatus();
        expect(cacheStatus['cacheSize'], equals(0));
        expect(cacheStatus['cachedKeys'], isEmpty);
      });
    });

    group('环境配置测试', () {
      test('应该能够创建开发环境配置', () {
        final devConfig = EnvironmentConfig.development();

        expect(devConfig.description, contains('开发环境'));
        expect(devConfig.debug, isTrue);
        expect(devConfig.hotReload, isTrue);
        expect(devConfig.optimize, isFalse);
        expect(devConfig.buildMode, equals(BuildMode.debug));
      });

      test('应该能够创建测试环境配置', () {
        final testConfig = EnvironmentConfig.testing();

        expect(testConfig.description, contains('测试环境'));
        expect(testConfig.debug, isFalse);
        expect(testConfig.optimize, isTrue);
        expect(testConfig.buildMode, equals(BuildMode.profile));
        expect(testConfig.validationOverrides?.strictMode, isTrue);
      });

      test('应该能够创建生产环境配置', () {
        final prodConfig = EnvironmentConfig.production();

        expect(prodConfig.description, contains('生产环境'));
        expect(prodConfig.debug, isFalse);
        expect(prodConfig.optimize, isTrue);
        expect(prodConfig.minify, isTrue);
        expect(prodConfig.buildMode, equals(BuildMode.release));
        expect(prodConfig.validationOverrides?.minCoverage, equals(90));
      });

      test('应该能够创建环境特定配置', () async {
        // 初始化工作空间
        await configManager.initializeWorkspace(
          workspaceName: 'test_workspace',
          templateType: 'basic',
        );

        // 创建自定义环境配置
        final customEnvConfig = EnvironmentConfig(
          description: '自定义测试环境',
          debug: true,
          hotReload: false,
          buildMode: BuildMode.debug,
          validationOverrides: ValidationOverrideConfig(
            strictMode: false,
            minCoverage: 60,
            allowWarnings: true,
          ),
        );

        final success = await configManager.createEnvironmentConfig(
          'custom',
          customEnvConfig,
        );

        expect(success, isTrue);

        // 验证环境已创建
        final environments = await configManager.getAvailableEnvironments();
        expect(environments, contains('custom'));
      });
    });

    group('配置合并策略测试', () {
      test('应该能够进行覆盖式合并', () {
        final baseConfig = WorkspaceConfig.defaultConfig();
        final otherConfig = WorkspaceConfig.enterpriseConfig();

        final merged = baseConfig.mergeWith(otherConfig,
            strategy: ConfigMergeStrategy.override);

        expect(merged.workspace.type, equals(WorkspaceType.enterprise));
        expect(merged.workspace.name, equals(otherConfig.workspace.name));
      });

      test('应该能够进行深度合并', () {
        final baseConfig = WorkspaceConfig.defaultConfig();
        final otherConfig = WorkspaceConfig.enterpriseConfig();

        final merged = baseConfig.mergeWith(otherConfig,
            strategy: ConfigMergeStrategy.merge);

        // 验证默认设置合并
        expect(merged.defaults.author, isNotEmpty);
        expect(merged.validation.strictMode, isTrue); // 企业级配置的严格模式
      });

      test('应该能够进行保留式合并', () {
        final baseConfig = WorkspaceConfig.defaultConfig();
        final otherConfig = WorkspaceConfig.enterpriseConfig();

        final merged = baseConfig.mergeWith(otherConfig,
            strategy: ConfigMergeStrategy.preserve);

        // 验证原有值被保留
        expect(merged.workspace.name, equals(baseConfig.workspace.name));
        expect(merged.workspace.type, equals(baseConfig.workspace.type));
      });
    });

    group('环境配置应用测试', () {
      test('应该能够获取特定环境的配置', () {
        final config = WorkspaceConfig.defaultConfig();

        // 应用开发环境配置
        final devConfig = config.getEnvironmentConfig('development');
        expect(devConfig, isNotNull);

        // 应用生产环境配置
        final prodConfig = config.getEnvironmentConfig('production');
        expect(prodConfig, isNotNull);

        // 验证环境配置影响了验证规则
        expect(devConfig.validation.minCoverage,
            lessThan(prodConfig.validation.minCoverage));
      });

      test('应该能够处理不存在的环境', () {
        final config = WorkspaceConfig.defaultConfig();

        final unknownEnvConfig = config.getEnvironmentConfig('unknown');

        // 应该返回原配置
        expect(unknownEnvConfig.workspace.name, equals(config.workspace.name));
      });
    });

    group('配置继承设置测试', () {
      test('应该能够创建配置继承设置', () {
        final inheritance = ConfigInheritance(
          baseConfig: './base-config.yaml',
          inheritsFrom: ['./parent1.yaml', './parent2.yaml'],
          mergeStrategy: ConfigMergeStrategy.merge,
          overrides: {
            'workspace': {
              'name': 'override-name',
            },
          },
        );

        expect(inheritance.baseConfig, equals('./base-config.yaml'));
        expect(inheritance.inheritsFrom, hasLength(2));
        expect(inheritance.mergeStrategy, equals(ConfigMergeStrategy.merge));
        expect(inheritance.overrides, isNotNull);
      });

      test('应该支持不同的合并策略', () {
        final strategies = [
          ConfigMergeStrategy.override,
          ConfigMergeStrategy.merge,
          ConfigMergeStrategy.preserve,
        ];

        for (final strategy in strategies) {
          final inheritance = ConfigInheritance(
            mergeStrategy: strategy,
          );

          expect(inheritance.mergeStrategy, equals(strategy));
        }
      });
    });

    group('性能设置测试', () {
      test('应该能够创建性能设置', () {
        final settings = PerformanceSettings(
          parallelBuild: true,
          cacheEnabled: true,
          maxMemoryUsage: 4096,
          buildTimeout: 600,
          optimizationLevel: OptimizationLevel.advanced,
        );

        expect(settings.parallelBuild, isTrue);
        expect(settings.cacheEnabled, isTrue);
        expect(settings.maxMemoryUsage, equals(4096));
        expect(settings.buildTimeout, equals(600));
        expect(settings.optimizationLevel, equals(OptimizationLevel.advanced));
      });

      test('应该支持不同的优化级别', () {
        final levels = [
          OptimizationLevel.none,
          OptimizationLevel.basic,
          OptimizationLevel.advanced,
          OptimizationLevel.maximum,
        ];

        for (final level in levels) {
          final settings = PerformanceSettings(optimizationLevel: level);
          expect(settings.optimizationLevel, equals(level));
        }
      });
    });

    group('模板覆盖配置测试', () {
      test('应该能够创建模板覆盖配置', () {
        final override = TemplateOverrideConfig(
          templatePath: './custom-template',
          customVariables: {
            'APP_NAME': 'MyApp',
            'VERSION': '1.0.0',
          },
          excludeFiles: ['.DS_Store', '*.tmp'],
          includeFiles: ['src/**/*.dart'],
        );

        expect(override.templatePath, equals('./custom-template'));
        expect(override.customVariables, hasLength(2));
        expect(override.excludeFiles, hasLength(2));
        expect(override.includeFiles, hasLength(1));
      });
    });

    group('验证规则覆盖测试', () {
      test('应该能够创建验证规则覆盖', () {
        final override = ValidationOverrideConfig(
          strictMode: true,
          minCoverage: 95,
          allowWarnings: false,
          customRules: ['rule1', 'rule2'],
        );

        expect(override.strictMode, isTrue);
        expect(override.minCoverage, equals(95));
        expect(override.allowWarnings, isFalse);
        expect(override.customRules, hasLength(2));
      });
    });
  });
}
