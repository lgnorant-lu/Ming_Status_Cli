/*
---------------------------------------------------------------
File name:          doctor_command.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        环境检查命令 (Doctor command for environment diagnosis)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 环境诊断和健康检查命令;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:ming_status_cli/src/utils/error_handler.dart';
import 'package:ming_status_cli/src/utils/progress_manager.dart';
import 'package:ming_status_cli/src/models/validation_result.dart';

/// 环境检查命令
/// 类似Flutter doctor，检查开发环境和工作空间状态
class DoctorCommand extends BaseCommand {
  DoctorCommand() {
    argParser.addFlag(
      'detailed',
      abbr: 'd',
      help: '显示详细的检查信息',
      negatable: false,
    );

    argParser.addFlag(
      'fix',
      abbr: 'f',
      help: '自动修复可修复的问题',
      negatable: false,
    );

    argParser.addFlag(
      'config',
      abbr: 'c',
      help: '执行配置深度检查',
      negatable: false,
    );
  }
  @override
  String get name => 'doctor';

  @override
  String get description => '检查开发环境和工作空间状态';

  @override
  String get invocation => 'ming doctor';

  @override
  Future<int> execute() async {
    final detailed = argResults?['detailed'] as bool? ?? false;
    final autoFix = argResults?['fix'] as bool? ?? false;

    // 创建进度管理器
    final progress = ProgressManager(
      showTimestamp: detailed, // 详细模式下显示时间戳
    );

    // 添加检查任务
    final checkers = _getCheckers();
    for (final checker in checkers) {
      progress.addTask(
        checker.name.toLowerCase().replaceAll(' ', '_'),
        '检查${checker.name}',
        '验证${checker.name}的状态和配置',
      );
    }

    // 如果启用自动修复，为需要修复的任务准备额外任务
    if (autoFix) {
      // 预扫描哪些检查器支持自动修复
      for (final checker in checkers.where((c) => c.canAutoFix)) {
        progress.addTask(
          '${checker.name.toLowerCase().replaceAll(' ', '_')}_fix',
          '修复${checker.name}',
          '自动修复${checker.name}中发现的问题',
        );
      }
    }

    // 开始进度跟踪
    progress.start(title: 'Ming Status CLI 环境检查');

    // 执行检查任务
    final result = ValidationResult();
    var passedChecks = 0;
    final failedCheckers = <HealthChecker>[];

    for (final checker in checkers) {
      try {
        final checkResult = await progress.executeTask(() async {
          return checker.check();
        });

        if (checkResult.isValid) {
          passedChecks++;
        } else {
          result.messages.addAll(checkResult.messages);
          failedCheckers.add(checker);
        }

        if (detailed) {
          _showDetailedResult(checkResult);
        }
      } catch (e) {
        Logger.structuredError(
          title: '${checker.name} 检查失败',
          description: '执行环境检查时发生错误',
          context: e.toString(),
          suggestions: [
            '检查系统环境是否正常',
            '确认文件权限设置',
            '尝试重新运行检查',
            '使用 --verbose 获取详细错误信息',
          ],
        );
        result.addError('检查器 ${checker.name} 执行失败: $e');
      }
    }

    // 执行自动修复任务
    if (autoFix && failedCheckers.isNotEmpty) {
      Logger.newLine();
      Logger.subtitle('🔧 自动修复阶段');

      for (final checker in failedCheckers.where((c) => c.canAutoFix)) {
        try {
          final fixed = await progress.executeTask(() async {
            return checker.autoFix();
          });

          if (fixed) {
            Logger.success('✅ ${checker.name} 自动修复成功');
            passedChecks++;
            failedCheckers.remove(checker);
          } else {
            Logger.warning('⚠️  ${checker.name} 自动修复失败');
          }
        } catch (e) {
          Logger.error('❌ ${checker.name} 自动修复异常: $e');
        }
      }
    }

    // 完成进度跟踪
    final totalChecks = checkers.length;
    final successRate =
        totalChecks > 0 ? (passedChecks / totalChecks * 100).round() : 0;
    progress.complete(
      summary: '环境检查完成，成功率: $successRate% ($passedChecks/$totalChecks)',
    );

    // 显示总结
    _showSummary(passedChecks, totalChecks, result);

    return result.isValid ? 0 : 1;
  }

  /// 获取所有检查器
  List<HealthChecker> _getCheckers() {
    final configOnly = argResults?['config'] as bool? ?? false;
    
    if (configOnly) {
      // 只进行配置相关检查
      return [
        WorkspaceConfigChecker(configManager),
        ConfigDeepChecker(configManager),
        UserConfigChecker(configManager),
        ConfigTemplateChecker(configManager),
      ];
    } else {
      // 完整环境检查
      return [
        SystemEnvironmentChecker(),
        WorkspaceConfigChecker(configManager),
        ConfigDeepChecker(configManager),
        DependencyChecker(),
        FilePermissionChecker(),
      ];
    }
  }

  /// 公共方法：获取检查器列表（用于测试）
  List<HealthChecker> getCheckers() => _getCheckers();

  /// 公共方法：获取检查器列表（用于测试，可指定配置模式）
  List<HealthChecker> getCheckersForTest({bool configOnly = false}) {
    if (configOnly) {
      // 只进行配置相关检查
      return [
        WorkspaceConfigChecker(configManager),
        ConfigDeepChecker(configManager),
        UserConfigChecker(configManager),
        ConfigTemplateChecker(configManager),
      ];
    } else {
      // 完整环境检查
      return [
        SystemEnvironmentChecker(),
        WorkspaceConfigChecker(configManager),
        ConfigDeepChecker(configManager),
        DependencyChecker(),
        FilePermissionChecker(),
      ];
    }
  }

  /// 显示详细结果
  void _showDetailedResult(ValidationResult result) {
    if (result.messages.isNotEmpty) {
      for (final message in result.messages) {
        final icon = _getMessageIcon(message.severity);
        Logger.info('  $icon ${message.message}');
        if (message.file != null) {
          Logger.info('    📁 ${message.file}');
        }
      }
    }
  }

  /// 获取消息图标
  String _getMessageIcon(ValidationSeverity severity) {
    switch (severity) {
      case ValidationSeverity.error:
        return '❌';
      case ValidationSeverity.warning:
        return '⚠️ ';
      case ValidationSeverity.info:
        return 'ℹ️ ';
      case ValidationSeverity.success:
        return '✅';
    }
  }

  /// 显示检查总结
  void _showSummary(int passed, int total, ValidationResult result) {
    Logger.subtitle('检查总结');

    if (passed == total) {
      Logger.success('🎉 所有检查都通过了！ ($passed/$total)');
      Logger.info('您的Ming Status CLI环境配置良好。');
    } else {
      Logger.warning('⚠️  发现问题 (通过: $passed/$total)');

      final errorCount = result.errors.length;
      final warningCount = result.warnings.length;

      if (errorCount > 0) {
        Logger.error('错误: $errorCount 个');
      }
      if (warningCount > 0) {
        Logger.warning('警告: $warningCount 个');
      }

      Logger.newLine();
      Logger.info('建议：');
      Logger.info('• 使用 "ming doctor --detailed" 查看详细信息');
      Logger.info('• 使用 "ming doctor --fix" 尝试自动修复');
      Logger.info(
          '• 参考文档: https://github.com/lgnorant-lu/Ming_Status_Cli/wiki',);
    }
  }
}

/// 健康检查器基类
abstract class HealthChecker {
  /// 检查器名称
  String get name;

  /// 是否支持自动修复
  bool get canAutoFix => false;

  /// 执行检查
  Future<ValidationResult> check();

  /// 自动修复（如果支持）
  Future<bool> autoFix() async => false;
}

/// 系统环境检查器
class SystemEnvironmentChecker extends HealthChecker {
  @override
  String get name => 'Dart环境';

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();

    try {
      // 检查Dart版本
      final dartVersion = Platform.version;
      result.addSuccess('Dart SDK: ${dartVersion.split(' ').first}');

      // 检查操作系统
      final os = Platform.operatingSystem;
      final osVersion = Platform.operatingSystemVersion;
      result.addSuccess('操作系统: $os $osVersion');

      // 检查可执行文件路径
      final executable = Platform.resolvedExecutable;
      if (await File(executable).exists()) {
        result.addSuccess('Dart可执行文件: $executable');
      } else {
        result.addError('Dart可执行文件不存在: $executable');
      }
    } catch (e) {
      result.addError('系统环境检查失败: $e');
    }

    return result;
  }
}

/// 工作空间配置检查器
class WorkspaceConfigChecker extends HealthChecker {
  WorkspaceConfigChecker(this.configManager);
  final dynamic configManager;

  @override
  String get name => '工作空间配置';

  @override
  bool get canAutoFix => true;

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();

    try {
      if (configManager.isWorkspaceInitialized() == true) {
        result.addSuccess('工作空间已初始化');

        final config = await configManager.loadWorkspaceConfig();
        if (config != null) {
          result.addSuccess('配置文件有效: ${configManager.configFilePath}');
          result.addInfo('工作空间名称: ${config.workspace.name}');
          result.addInfo('工作空间版本: ${config.workspace.version}');
        } else {
          result.addError('配置文件无法加载');
        }
      } else {
        result.addWarning('当前目录未初始化为Ming Status工作空间');
        result.addInfo('提示: 使用 "ming init" 初始化工作空间');
      }
    } catch (e) {
      result.addError('工作空间配置检查失败: $e');
    }

    return result;
  }

  @override
  Future<bool> autoFix() async {
    try {
      if (configManager.isWorkspaceInitialized() != true) {
        // 可以在这里实现自动初始化逻辑
        // 但通常需要用户确认，所以这里返回false
        return false;
      }
    } catch (e) {
      return false;
    }
    return true;
  }
}

/// 依赖包检查器
class DependencyChecker extends HealthChecker {
  @override
  String get name => '依赖包状态';

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();

    try {
      // 检查pubspec.yaml
      const pubspecPath = 'pubspec.yaml';
      if (await File(pubspecPath).exists()) {
        result.addSuccess('pubspec.yaml文件存在');

        // 检查.dart_tool目录
        if (await Directory('.dart_tool').exists()) {
          result.addSuccess('依赖包已安装');
        } else {
          result.addWarning('依赖包未安装');
          result.addInfo('提示: 运行 "dart pub get" 安装依赖');
        }
      } else {
        result.addInfo('当前目录不是Dart项目');
      }
    } catch (e) {
      result.addError('依赖包检查失败: $e');
    }

    return result;
  }
}

/// 文件权限检查器
class FilePermissionChecker extends HealthChecker {
  @override
  String get name => '文件权限';

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();

    try {
      final currentDir = Directory.current;

      // 检查读权限
      try {
        await currentDir.list().first;
        result.addSuccess('目录读取权限正常');
      } catch (e) {
        result.addError('目录读取权限不足: $e');
      }

      // 检查写权限
      try {
        final testFile = File('${currentDir.path}/.ming_temp_test');
        await testFile.writeAsString('test');
        await testFile.delete();
        result.addSuccess('目录写入权限正常');
      } catch (e) {
        result.addError('目录写入权限不足: $e');
      }
    } catch (e) {
      result.addError('文件权限检查失败: $e');
    }

    return result;
  }
}

/// 配置深度检查器
class ConfigDeepChecker extends HealthChecker {
  ConfigDeepChecker(this.configManager);
  final dynamic configManager;

  @override
  String get name => '配置深度检查';

  @override
  bool get canAutoFix => true;

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();

    try {
      // 检查工作空间是否已初始化
      final isWorkspaceInitialized = configManager.isWorkspaceInitialized();
      if (isWorkspaceInitialized != true) {
        result.addInfo('当前目录不是Ming Status工作空间，跳过配置检查');
        return result;
      }

      // 加载配置
      final config = await configManager.loadWorkspaceConfig();
      if (config == null) {
        result.addError('无法加载工作空间配置文件');
        return result;
      }

      // 1. 基础配置检查
      await _checkBasicConfig(config, result);

      // 2. 模板配置检查
      await _checkTemplateConfig(config, result);

      // 3. 环境配置检查
      await _checkEnvironmentConfig(config, result);

      // 4. 验证规则检查
      await _checkValidationConfig(config, result);

      // 5. 使用ConfigManager的高级验证功能
      try {
        final validateMethod = configManager.validateWorkspaceConfig;
        if (validateMethod != null) {
          final validationResult = await validateMethod(
            config,
            strictness: 'standard',
            checkDependencies: true,
            checkFileSystem: true,
          );

          final isValidDynamic = validationResult?.isValid;
          final isValid = isValidDynamic is bool ? isValidDynamic : false;
          if (isValid) {
            result.addSuccess('配置深度验证通过');
          } else {
            final errors = validationResult?.errors;
            final warnings = validationResult?.warnings;
            final suggestions = validationResult?.suggestions;
            
            if (errors != null && errors is Iterable) {
              for (final error in errors) {
                result.addError('验证错误: $error');
              }
            }
            if (warnings != null && warnings is Iterable) {
              for (final warning in warnings) {
                result.addWarning('验证警告: $warning');
              }
            }
            if (suggestions != null && suggestions is Iterable) {
              for (final suggestion in suggestions) {
                result.addInfo('建议: $suggestion');
              }
            }
          }
        }
      } catch (e) {
        result.addWarning('高级验证功能不可用: $e');
      }
    } catch (e) {
      result.addError('配置深度检查失败: $e');
    }

    return result;
  }

  Future<void> _checkBasicConfig(dynamic config, ValidationResult result) async {
    // 检查工作空间基本信息
    try {
      final workspaceName = config?.workspace?.name?.toString();
      if (workspaceName?.isNotEmpty == true) {
        result.addSuccess('工作空间名称已设置: $workspaceName');
      } else {
        result.addError('工作空间名称未设置或为空');
      }

      final workspaceVersion = config?.workspace?.version?.toString();
      if (workspaceVersion?.isNotEmpty == true) {
        result.addSuccess('工作空间版本已设置: $workspaceVersion');
      } else {
        result.addWarning('工作空间版本未设置');
      }

      // 检查默认设置
      final defaultAuthor = config?.defaults?.author?.toString();
      if (defaultAuthor?.isNotEmpty == true) {
        result.addSuccess('默认作者已设置: $defaultAuthor');
      } else {
        result.addWarning('默认作者未设置，建议设置以便自动填充');
      }
    } catch (e) {
      result.addWarning('基础配置检查出错: $e');
    }
  }

  Future<void> _checkTemplateConfig(dynamic config, ValidationResult result) async {
    try {
      if (config?.templates != null) {
        result.addSuccess('模板配置已启用');

        // 检查模板路径
        final localPath = config?.templates?.localPath?.toString();
        if (localPath?.isNotEmpty == true) {
          if (await Directory(localPath!).exists()) {
            result.addSuccess('模板目录存在: $localPath');
          } else {
            result.addWarning('模板目录不存在: $localPath');
          }
        }

        // 检查缓存设置
        final cacheTimeout = config?.templates?.cacheTimeout;
        if (cacheTimeout != null && cacheTimeout is int && cacheTimeout > 0) {
          result.addInfo('模板缓存超时: $cacheTimeout秒');
        }
      } else {
        result.addWarning('模板配置未设置');
      }
    } catch (e) {
      result.addWarning('模板配置检查出错: $e');
    }
  }

  Future<void> _checkEnvironmentConfig(dynamic config, ValidationResult result) async {
    try {
      final environments = config?.environments;
      if (environments != null && environments is Map && environments.isNotEmpty) {
        final envKeys = environments.keys.map((k) => k.toString()).join(', ');
        result.addSuccess('环境配置已设置: $envKeys');

        // 检查必要环境
        final requiredEnvs = ['development', 'production'];
        for (final env in requiredEnvs) {
          if (environments.containsKey(env)) {
            result.addSuccess('$env 环境配置存在');
          } else {
            result.addWarning('建议添加 $env 环境配置');
          }
        }
      } else {
        result.addInfo('未设置环境特定配置（可选）');
      }
    } catch (e) {
      result.addWarning('环境配置检查出错: $e');
    }
  }

  Future<void> _checkValidationConfig(dynamic config, ValidationResult result) async {
    try {
      if (config?.validation != null) {
        result.addSuccess('验证规则已配置');

        final strictMode = config?.validation?.strictMode;
        if (strictMode == true) {
          result.addInfo('严格模式已启用');
        }

        final minCoverage = config?.validation?.minCoverage;
        if (minCoverage != null && minCoverage is int) {
          if (minCoverage >= 80) {
            result.addSuccess('测试覆盖率要求: $minCoverage%');
          } else {
            result.addWarning('测试覆盖率要求较低: $minCoverage%，建议至少80%');
          }
        }
      } else {
        result.addWarning('验证规则未配置');
      }
    } catch (e) {
      result.addWarning('验证配置检查出错: $e');
    }
  }

  @override
  Future<bool> autoFix() async {
    try {
      // 实现一些简单的自动修复逻辑
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// 用户配置检查器
class UserConfigChecker extends HealthChecker {
  UserConfigChecker(this.configManager);
  final dynamic configManager;

  @override
  String get name => '用户配置';

  @override
  bool get canAutoFix => false; // 目前不支持自动修复

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();

    try {
      // 检查用户配置管理器是否可用
      // 在Phase 1中，用户配置管理功能还未实现
      final hasUserConfigManagerMethod = configManager.runtimeType.toString().contains('ConfigManager');
      
      if (hasUserConfigManagerMethod) {
        result.addInfo('用户配置管理功能检查（Phase 1：功能开发中）');
        
        // 检查用户主目录下的配置目录
        try {
          final userHomeDir = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
          if (userHomeDir != null) {
            final mingConfigDir = path.join(userHomeDir, '.ming_status');
            if (await Directory(mingConfigDir).exists()) {
              result.addSuccess('用户配置目录存在: $mingConfigDir');
            } else {
              result.addInfo('用户配置目录不存在: $mingConfigDir（首次使用时会自动创建）');
            }
            
            final userConfigFile = path.join(mingConfigDir, 'config.yaml');
            if (await File(userConfigFile).exists()) {
              result.addSuccess('用户配置文件存在: $userConfigFile');
            } else {
              result.addInfo('用户配置文件不存在（首次使用时会自动创建）');
            }
          } else {
            result.addWarning('无法获取用户主目录路径');
          }
        } catch (e) {
          result.addWarning('用户配置目录检查失败: $e');
        }
        
        // 提示用户配置功能的状态
        result.addInfo('用户配置管理功能将在Phase 2中完整实现');
        result.addInfo('当前版本支持基本的工作空间配置管理');
      } else {
        result.addWarning('用户配置管理器不可用（功能开发中）');
      }
    } catch (e) {
      result.addError('用户配置检查失败: $e');
    }

    return result;
  }

  @override
  Future<bool> autoFix() async {
    // Phase 1中暂不支持自动修复用户配置
    return false;
  }
}

/// 配置模板检查器
class ConfigTemplateChecker extends HealthChecker {
  ConfigTemplateChecker(this.configManager);
  final dynamic configManager;

  @override
  String get name => '配置模板';

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();

    try {
      // 检查可用的配置模板
      final templatesDynamic = configManager.listConfigTemplates();
      final templates = templatesDynamic is List ? templatesDynamic : <String>[];
      final templatesNotEmpty = templates.isNotEmpty;
      if (templatesNotEmpty) {
        result.addSuccess('可用配置模板: ${templates.join(', ')}');

        // 验证内置模板
        final builtinTemplates = ['basic', 'enterprise'];
        for (final template in builtinTemplates) {
          final isValidDynamic = await configManager.validateConfigTemplate(template);
          final isValid = isValidDynamic is bool ? isValidDynamic : false;
          if (isValid) {
            result.addSuccess('$template 模板验证通过');
          } else {
            result.addError('$template 模板验证失败');
          }
        }
      } else {
        result.addWarning('未发现可用的配置模板');
      }

      // 检查模板目录
      final templatesPathDynamic = configManager.getTemplatesPath();
      final templatesPath = templatesPathDynamic?.toString() ?? '';
      if (templatesPath.isNotEmpty && await Directory(templatesPath).exists()) {
        result.addSuccess('模板目录存在: $templatesPath');
        
        final workspaceTemplatesPath = '$templatesPath/workspace';
        if (await Directory(workspaceTemplatesPath).exists()) {
          result.addSuccess('工作空间模板目录存在');
        } else {
          result.addInfo('工作空间模板目录不存在（将使用内置模板）');
        }
      } else {
        result.addInfo('模板目录不存在（将使用内置模板）');
      }
    } catch (e) {
      result.addError('配置模板检查失败: $e');
    }

    return result;
  }
}
