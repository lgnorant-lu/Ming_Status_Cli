/*
---------------------------------------------------------------
File name:          doctor_command_test.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        Doctor命令单元测试 (Unit tests for doctor command)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - Doctor命令和配置深度检查功能测试;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:test/test.dart';
import 'package:ming_status_cli/src/commands/doctor_command.dart';
import 'package:ming_status_cli/src/core/config_manager.dart';
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:ming_status_cli/src/models/workspace_config.dart';
import 'package:ming_status_cli/src/utils/file_utils.dart';

void main() {
  group('DoctorCommand', () {
    late Directory tempDir;
    late ConfigManager configManager;
    late DoctorCommand doctorCommand;

    setUp(() async {
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_test_doctor_');
      
      // 初始化配置管理器
      configManager = ConfigManager(workingDirectory: tempDir.path);
      
      // 创建doctor命令实例
      doctorCommand = DoctorCommand();
      
      // 设置测试环境
      await _setupTestEnvironment(tempDir, configManager);
    });

    tearDown(() async {
      // 清理临时目录
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('基本功能测试', () {
      test('应该正确定义命令名称和描述', () {
        expect(doctorCommand.name, equals('doctor'));
        expect(doctorCommand.description, contains('检查开发环境'));
        expect(doctorCommand.invocation, equals('ming doctor'));
      });

      test('应该支持详细模式参数', () {
        final argParser = doctorCommand.argParser;
        expect(argParser.options.containsKey('detailed'), isTrue);
        expect(argParser.options.containsKey('fix'), isTrue);
        expect(argParser.options.containsKey('config'), isTrue);
      });
    });

    group('健康检查器测试', () {
      test('SystemEnvironmentChecker应该正常工作', () async {
        final checker = SystemEnvironmentChecker();
        expect(checker.name, equals('Dart环境'));
        expect(checker.canAutoFix, isFalse);

        final result = await checker.check();
        expect(result, isA<ValidationResult>());
        // Dart环境应该是可用的（在测试环境中）
        expect(result.messages.isNotEmpty, isTrue);
      });

      test('WorkspaceConfigChecker应该检查工作空间状态', () async {
        final checker = WorkspaceConfigChecker(configManager);
        expect(checker.name, equals('工作空间配置'));
        expect(checker.canAutoFix, isTrue);

        final result = await checker.check();
        expect(result, isA<ValidationResult>());
        
        // 应该检测到已初始化的工作空间
        final hasSuccessMessage = result.messages.any(
          (msg) => msg.message.contains('工作空间已初始化')
        );
        expect(hasSuccessMessage, isTrue);
      });

      test('DependencyChecker应该检查依赖状态', () async {
        final checker = DependencyChecker();
        expect(checker.name, equals('依赖包状态'));
        expect(checker.canAutoFix, isFalse);

        final result = await checker.check();
        expect(result, isA<ValidationResult>());
      });

      test('FilePermissionChecker应该检查文件权限', () async {
        final checker = FilePermissionChecker();
        expect(checker.name, equals('文件权限'));
        expect(checker.canAutoFix, isFalse);

        final result = await checker.check();
        expect(result, isA<ValidationResult>());
        
        // 应该有读写权限检查结果
        expect(result.messages.isNotEmpty, isTrue);
      });
    });

    group('配置深度检查器测试', () {
      test('ConfigDeepChecker应该执行配置深度验证', () async {
        final checker = ConfigDeepChecker(configManager);
        expect(checker.name, equals('配置深度检查'));
        expect(checker.canAutoFix, isTrue);

        final result = await checker.check();
        expect(result, isA<ValidationResult>());
        
        // 应该包含基础配置检查结果
        final hasConfigCheck = result.messages.any(
          (msg) => msg.message.contains('工作空间名称已设置') ||
                   msg.message.contains('模板配置已启用')
        );
        expect(hasConfigCheck, isTrue);
      });

      test('UserConfigChecker应该检查用户配置状态', () async {
        final checker = UserConfigChecker(configManager);
        expect(checker.name, equals('用户配置'));
        expect(checker.canAutoFix, isFalse);

        final result = await checker.check();
        expect(result, isA<ValidationResult>());
        
        // 应该包含用户配置功能状态信息
        final hasUserConfigInfo = result.messages.any(
          (msg) => msg.message.contains('用户配置管理功能') ||
                   msg.message.contains('Phase 1')
        );
        expect(hasUserConfigInfo, isTrue);
      });

      test('ConfigTemplateChecker应该检查配置模板', () async {
        final checker = ConfigTemplateChecker(configManager);
        expect(checker.name, equals('配置模板'));
        expect(checker.canAutoFix, isFalse);

        final result = await checker.check();
        expect(result, isA<ValidationResult>());
        
        // 应该检测到可用的配置模板
        final hasTemplateInfo = result.messages.any(
          (msg) => msg.message.contains('可用配置模板') ||
                   msg.message.contains('模板验证')
        );
        expect(hasTemplateInfo, isTrue);
      });
    });

    group('配置专用检查测试', () {
      test('--config参数应该只执行配置相关检查', () async {
        // 创建DoctorCommand实例
        final configDoctorCommand = DoctorCommand();
        
        // 使用测试专用方法获取配置专用检查器
        final checkers = configDoctorCommand.getCheckersForTest(configOnly: true);
        
        // 验证检查器数量和类型
        expect(checkers.length, equals(4), reason: '配置专用模式应该只有4个检查器');
        expect(checkers.any((c) => c.name == '工作空间配置'), isTrue);
        expect(checkers.any((c) => c.name == '配置深度检查'), isTrue);
        expect(checkers.any((c) => c.name == '用户配置'), isTrue);
        expect(checkers.any((c) => c.name == '配置模板'), isTrue);
        
        // 不应该包含系统环境检查器
        expect(checkers.any((c) => c.name == 'Dart环境'), isFalse);
        expect(checkers.any((c) => c.name == '依赖包状态'), isFalse);
        expect(checkers.any((c) => c.name == '文件权限'), isFalse);
      });

      test('默认模式应该执行完整环境检查', () async {
        // 创建DoctorCommand实例
        final defaultDoctorCommand = DoctorCommand();
        final checkers = defaultDoctorCommand.getCheckersForTest(configOnly: false);
        
        // 应该包含系统环境检查器
        expect(checkers.any((c) => c.name == 'Dart环境'), isTrue);
        expect(checkers.any((c) => c.name == '工作空间配置'), isTrue);
        expect(checkers.any((c) => c.name == '配置深度检查'), isTrue);
        expect(checkers.any((c) => c.name == '依赖包状态'), isTrue);
        expect(checkers.any((c) => c.name == '文件权限'), isTrue);
      });
    });

    group('自动修复功能测试', () {
      test('支持自动修复的检查器应该正确标识', () {
        final workspaceChecker = WorkspaceConfigChecker(configManager);
        expect(workspaceChecker.canAutoFix, isTrue);

        final configDeepChecker = ConfigDeepChecker(configManager);
        expect(configDeepChecker.canAutoFix, isTrue);

        final systemChecker = SystemEnvironmentChecker();
        expect(systemChecker.canAutoFix, isFalse);

        final dependencyChecker = DependencyChecker();
        expect(dependencyChecker.canAutoFix, isFalse);
      });

      test('WorkspaceConfigChecker自动修复应该处理未初始化状态', () async {
        // 创建未初始化的临时目录
        final uninitDir = await Directory.systemTemp.createTemp('ming_uninit_');
        final uninitConfigManager = ConfigManager(workingDirectory: uninitDir.path);
        
        try {
          final checker = WorkspaceConfigChecker(uninitConfigManager);
          final canFix = await checker.autoFix();
          
          // 对于未初始化的工作空间，自动修复应该返回false（需要用户确认）
          expect(canFix, isFalse);
        } finally {
          if (await uninitDir.exists()) {
            await uninitDir.delete(recursive: true);
          }
        }
      });
    });

    group('错误处理测试', () {
      test('配置文件损坏时应该优雅处理', () async {
        // 创建损坏的配置文件
        final configFile = File('${tempDir.path}/ming_status.yaml');
        await configFile.writeAsString('invalid: yaml: content: [');
        
        final checker = WorkspaceConfigChecker(configManager);
        final result = await checker.check();
        
        // 应该包含错误信息但不应该崩溃
        expect(result, isA<ValidationResult>());
      });

      test('权限不足时应该优雅处理', () async {
        final checker = FilePermissionChecker();
        final result = await checker.check();
        
        // 应该完成检查而不崩溃
        expect(result, isA<ValidationResult>());
      });
    });

    group('消息图标测试', () {
      test('应该为不同严重级别返回正确图标', () {
        final result = ValidationResult();
        result.addError('错误信息');
        result.addWarning('警告信息');
        result.addInfo('信息');
        result.addSuccess('成功信息');
        
        expect(result.errors.length, equals(1));
        expect(result.warnings.length, equals(1));
        expect(result.infos.length, equals(1));
        expect(result.successes.length, equals(1));
      });
    });
  });
}

/// 设置测试环境
Future<void> _setupTestEnvironment(Directory tempDir, ConfigManager configManager) async {
  // 初始化工作空间配置
  await configManager.initializeWorkspace(
    workspaceName: 'test_workspace',
    templateType: 'basic',
    description: 'Test workspace for doctor command',
    author: 'Test Author',
  );
  
  // 创建必要的目录结构
  await Directory('${tempDir.path}/templates').create(recursive: true);
  await Directory('${tempDir.path}/modules').create(recursive: true);
  await Directory('${tempDir.path}/output').create(recursive: true);
  
  // 创建模板文件
  await Directory('${tempDir.path}/templates/workspace').create(recursive: true);
  
  // 创建基础配置模板文件
  final basicTemplate = '''
workspace:
  name: "test_basic"
  version: "1.0.0"
  description: "基础测试配置"
  type: "basic"

templates:
  source: "local"
  localPath: "./templates"
  cacheTimeout: 3600
  autoUpdate: false

defaults:
  author: "Test Author"
  license: "MIT"
  dartVersion: "^3.2.0"
  description: "A test module"

validation:
  strictMode: false
  requireTests: true
  minCoverage: 80
''';
  
  await File('${tempDir.path}/templates/workspace/ming_workspace_basic.yaml')
      .writeAsString(basicTemplate);
} 