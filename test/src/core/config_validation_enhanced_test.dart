/*
---------------------------------------------------------------
File name:          config_validation_enhanced_test.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        增强配置验证功能测试 (Enhanced config validation tests)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 配置验证增强功能测试;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/core/config_manager.dart';
import 'package:ming_status_cli/src/models/workspace_config.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// 测试用的临时配置管理器，使用隔离的临时目录
class TestConfigManagerForValidation extends ConfigManager {
  TestConfigManagerForValidation(this.testWorkingDirectory)
      : super(workingDirectory: testWorkingDirectory);
  final String testWorkingDirectory;
}

void main() {
  group('ConfigManager增强验证功能测试', () {
    late TestConfigManagerForValidation configManager;
    late Directory tempDir;

    setUp(() async {
      // 创建临时测试目录
      tempDir =
          await Directory.systemTemp.createTemp('ming_config_validation_test_');
      configManager = TestConfigManagerForValidation(tempDir.path);

      // 创建基础目录结构
      await Directory(path.join(tempDir.path, 'templates')).create();
      await Directory(path.join(tempDir.path, 'modules')).create();
      await Directory(path.join(tempDir.path, 'output')).create();
    });

    tearDown(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('工作空间配置验证测试', () {
      test('基础验证 - 正常配置', () async {
        final config = WorkspaceConfig.defaultConfig();

        final result = await configManager.validateWorkspaceConfig(
          config,
          strictness: ValidationStrictness.basic,
        );

        expect(result.isValid, isTrue, reason: '默认配置应该通过基础验证');
        expect(result.errors, isEmpty, reason: '默认配置不应有错误');
      });

      test('基础验证 - 空名称配置', () async {
        final config = WorkspaceConfig.defaultConfig().copyWith(
          workspace: const WorkspaceInfo(
            name: '',
            version: '1.0.0',
            description: '测试工作空间',
          ),
        );

        final result = await configManager.validateWorkspaceConfig(
          config,
          strictness: ValidationStrictness.basic,
        );

        expect(result.isValid, isFalse, reason: '空名称配置应该验证失败');
        expect(result.errors, contains('工作空间名称不能为空'));
      });

      test('标准验证 - 版本格式检查', () async {
        final config = WorkspaceConfig.defaultConfig().copyWith(
          workspace: const WorkspaceInfo(
            name: '测试工作空间',
            version: 'invalid-version',
            description: '测试工作空间',
          ),
        );

        final result = await configManager.validateWorkspaceConfig(
          config,
        );

        expect(result.isValid, isTrue, reason: '仅版本格式警告不影响整体验证通过');
        expect(
          result.warnings,
          contains(
            predicate<String>(
              (warning) => warning.contains('版本号建议使用语义版本格式'),
            ),
          ),
        );
      });

      test('严格验证 - 语义约束检查', () async {
        final config = WorkspaceConfig.defaultConfig().copyWith(
          workspace: const WorkspaceInfo(
            name: '测试工作空间',
            version: '1.0.0',
            description: '测试工作空间',
          ),
          templates: const TemplateConfig(
            source: TemplateSource.remote,
            localPath: 'templates',
          ),
        );

        final result = await configManager.validateWorkspaceConfig(
          config,
          strictness: ValidationStrictness.strict,
        );

        expect(result.isValid, isFalse, reason: '语义约束违反应该导致验证失败');
        expect(result.errors, contains('使用远程模板源时必须配置远程注册表地址'));
      });

      test('企业级验证 - 安全检查', () async {
        final config = WorkspaceConfig.defaultConfig().copyWith(
          workspace: const WorkspaceInfo(
            name: '测试工作空间',
            version: '1.0.0',
            description: '测试工作空间',
            type: WorkspaceType.enterprise,
          ),
          templates: const TemplateConfig(
            source: TemplateSource.remote,
            localPath: 'templates',
            remoteRegistry: 'http://insecure.example.com', // 使用HTTP协议
          ),
        );

        final result = await configManager.validateWorkspaceConfig(
          config,
          strictness: ValidationStrictness.enterprise,
        );

        expect(result.isValid, isTrue, reason: '安全警告不影响整体验证通过');
        expect(
          result.warnings,
          contains(
            predicate<String>(
              (warning) => warning.contains('HTTP协议，存在安全风险'),
            ),
          ),
        );
      });
    });

    group('配置模板验证测试', () {
      test('内置模板验证 - basic', () async {
        final result = await configManager.validateConfigTemplateEnhanced(
          'basic',
        );

        expect(result.isValid, isTrue, reason: 'basic内置模板应该验证通过');
        expect(result.errors, isEmpty, reason: 'basic模板不应有错误');
      });

      test('内置模板验证 - enterprise', () async {
        final result = await configManager.validateConfigTemplateEnhanced(
          'enterprise',
        );

        expect(result.isValid, isTrue, reason: 'enterprise内置模板应该验证通过');
        expect(result.errors, isEmpty, reason: 'enterprise模板不应有错误');
      });

      test('不存在模板验证', () async {
        final result = await configManager.validateConfigTemplateEnhanced(
          'non_existent_template',
        );

        expect(result.isValid, isFalse, reason: '不存在的模板应该验证失败');
        expect(result.errors, contains('模板基础验证失败: non_existent_template'));
      });
    });

    group('配置完整性检查测试', () {
      test('未初始化工作空间检查', () async {
        final result = await configManager.checkConfigIntegrity(
          checkModules: false,
          checkTemplates: false,
        );

        expect(result.warnings, contains('工作空间尚未初始化'));
        expect(result.suggestions, contains('运行 "ming init" 初始化工作空间'));
      });

      test('已初始化工作空间检查', () async {
        // 先初始化工作空间
        await configManager.initializeWorkspace(
          workspaceName: '测试工作空间',
        );

        final result = await configManager.checkConfigIntegrity();

        expect(result.isValid, isTrue, reason: '已初始化的工作空间完整性检查应该通过');
        expect(result.suggestions, contains('模块目录为空，可以使用 "ming create" 创建新模块'));
      });
    });

    group('ValidationStrictness级别测试', () {
      late WorkspaceConfig testConfig;

      setUp(() {
        testConfig = WorkspaceConfig.defaultConfig().copyWith(
          workspace: const WorkspaceInfo(
            name: 'test',
            version: 'invalid',
            description: '测试工作空间',
          ),
          templates: const TemplateConfig(
            source: TemplateSource.remote,
            localPath: 'templates',
          ),
        );
      });

      test('基础验证级别', () async {
        final result = await configManager.validateWorkspaceConfig(
          testConfig,
          strictness: ValidationStrictness.basic,
        );

        // 基础验证只检查最基本的字段
        expect(result.warnings.length, lessThan(5), reason: '基础验证警告较少');
      });

      test('标准验证级别', () async {
        final result = await configManager.validateWorkspaceConfig(
          testConfig,
        );

        // 标准验证检查更多字段
        expect(
          result.warnings.length,
          greaterThanOrEqualTo(1),
          reason: '标准验证应该有更多警告',
        );
      });

      test('严格验证级别', () async {
        final result = await configManager.validateWorkspaceConfig(
          testConfig,
          strictness: ValidationStrictness.strict,
        );

        // 严格验证包含语义检查，应该有错误
        expect(result.isValid, isFalse, reason: '严格验证应该发现语义错误');
        expect(result.errors, contains('使用远程模板源时必须配置远程注册表地址'));
      });

      test('企业级验证级别', () async {
        // 企业级验证需要单独的配置来触发安全检查
        final enterpriseTestConfig = WorkspaceConfig.defaultConfig().copyWith(
          workspace: const WorkspaceInfo(
            name: 'test',
            version: 'invalid',
            description: '测试工作空间',
          ),
          templates: const TemplateConfig(
            source: TemplateSource.remote,
            localPath: 'templates',
            remoteRegistry: 'http://insecure.example.com', // 使用HTTP协议触发安全警告
          ),
        );

        final result = await configManager.validateWorkspaceConfig(
          enterpriseTestConfig,
          strictness: ValidationStrictness.enterprise,
        );

        // 企业级验证包含安全检查
        expect(
          result.warnings,
          contains(
            predicate<String>(
              (warning) => warning.contains('HTTP协议，存在安全风险'),
            ),
          ),
        );
      });
    });

    group('ConfigValidationResult功能测试', () {
      test('成功结果创建', () {
        final result = ConfigValidationResult.success(
          warnings: ['测试警告'],
          suggestions: ['测试建议'],
        );

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.warnings, equals(['测试警告']));
        expect(result.suggestions, equals(['测试建议']));
        expect(result.hasIssues, isTrue, reason: '有警告就算有问题');
      });

      test('失败结果创建', () {
        final result = ConfigValidationResult.failure(
          errors: ['测试错误'],
          warnings: ['测试警告'],
          suggestions: ['测试建议'],
        );

        expect(result.isValid, isFalse);
        expect(result.errors, equals(['测试错误']));
        expect(result.warnings, equals(['测试警告']));
        expect(result.suggestions, equals(['测试建议']));
        expect(result.hasIssues, isTrue);
      });

      test('摘要格式化', () {
        final result = ConfigValidationResult.failure(
          errors: ['错误1', '错误2'],
          warnings: ['警告1'],
          suggestions: ['建议1'],
        );

        final summary = result.summary;
        expect(summary, contains('错误 (2):'));
        expect(summary, contains('警告 (1):'));
        expect(summary, contains('建议 (1):'));
        expect(summary, contains('- 错误1'));
        expect(summary, contains('- 警告1'));
        expect(summary, contains('- 建议1'));
      });
    });
  });
}
