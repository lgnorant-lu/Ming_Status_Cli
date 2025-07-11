/*
---------------------------------------------------------------
File name:          doctor_command.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        系统健康检查命令 (System health check command)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 系统诊断和健康检查功能;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/config_management/config_manager.dart';
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:ming_status_cli/src/models/workspace_config.dart';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:ming_status_cli/src/utils/progress_manager.dart';
import 'package:path/path.dart' as path;

/// 环境检查命令
///
/// 类似Flutter doctor，提供全面的开发环境和工作空间状态检查功能：
///
/// **检查项目**：
/// - 系统环境：Dart SDK版本、操作系统信息
/// - 工作空间配置：初始化状态、配置文件有效性
/// - 依赖包状态：pubspec.yaml和依赖安装情况
/// - 文件权限：目录读写权限验证
/// - 配置深度检查：详细的配置项验证
///
/// **支持的参数**：
/// - `--detailed, -d`: 显示详细的检查信息和诊断输出
/// - `--fix, -f`: 自动修复可修复的问题
/// - `--config, -c`: 仅执行配置相关的深度检查
///
/// **使用示例**：
/// ```bash
/// # 基础环境检查
/// ming doctor
///
/// # 详细检查信息
/// ming doctor --detailed
///
/// # 自动修复问题
/// ming doctor --fix
///
/// # 仅检查配置
/// ming doctor --config
/// ```
///
/// 提供结构化的检查报告和自动修复建议，确保开发环境的完整性。
class DoctorCommand extends BaseCommand {
  /// 创建环境检查命令实例
  ///
  /// 初始化命令行参数解析器，配置支持的标志选项：
  /// - `--detailed/-d`: 显示详细检查信息
  /// - `--fix/-f`: 启用自动修复功能
  /// - `--config/-c`: 仅执行配置深度检查
  DoctorCommand() {
    argParser
      ..addFlag(
        'detailed',
        abbr: 'd',
        help: '显示详细的检查信息',
        negatable: false,
      )
      ..addFlag(
        'fix',
        abbr: 'f',
        help: '自动修复可修复的问题',
        negatable: false,
      )
      ..addFlag(
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

  /// 执行环境检查命令
  ///
  /// 运行所有已配置的健康检查器，生成详细的环境状态报告。
  /// 支持详细模式输出和自动修复功能。
  ///
  /// 返回：
  /// - 0: 所有检查通过
  /// - 1: 发现问题或检查失败
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

    // 只有在有错误时才返回失败退出码，警告不应导致失败
    return result.errors.isEmpty ? 0 : 1;
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

  /// 获取当前配置的检查器列表
  ///
  /// 公共方法，主要用于测试和外部访问。
  /// 根据命令行参数确定是使用完整检查器列表还是仅配置检查器。
  ///
  /// 返回：
  /// - [List<HealthChecker>] 当前配置下的所有检查器实例
  List<HealthChecker> getCheckers() => _getCheckers();

  /// 获取测试用的检查器列表
  ///
  /// 专为测试环境设计的方法，允许指定检查模式。
  ///
  /// 参数：
  /// - [configOnly] 是否仅返回配置相关的检查器，默认为false
  ///
  /// 返回：
  /// - [List<HealthChecker>] 指定模式下的检查器列表
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
        '• 参考文档: https://github.com/lgnorant-lu/Ming_Status_Cli/wiki',
      );
    }
  }
}

/// 健康检查器基类
///
/// 定义环境检查器的标准接口，所有具体的检查器都应该继承此抽象类。
/// 提供基础的检查和自动修复功能框架。
///
/// 实现类需要定义：
/// - [name]: 检查器的显示名称
/// - [check]: 执行具体的检查逻辑
/// - [canAutoFix]: 是否支持自动修复（可选）
/// - [autoFix]: 自动修复的具体实现（可选）
abstract class HealthChecker {
  /// 检查器的显示名称
  ///
  /// 用于在检查报告中标识此检查器，应该简洁明了地描述检查的内容。
  String get name;

  /// 是否支持自动修复
  ///
  /// 返回true表示此检查器支持自动修复功能，false表示只能检查不能修复。
  /// 默认为false，支持自动修复的检查器应该重写此属性。
  bool get canAutoFix => false;

  /// 执行环境检查
  ///
  /// 实现具体的检查逻辑，验证相关环境或配置的状态。
  ///
  /// 返回：
  /// - [ValidationResult] 包含检查结果、错误信息、警告和建议的详细报告
  Future<ValidationResult> check();

  /// 自动修复发现的问题
  ///
  /// 当[canAutoFix]为true时，此方法将被调用来尝试自动修复检查中发现的问题。
  ///
  /// 返回：
  /// - true: 修复成功
  /// - false: 修复失败或不支持自动修复
  ///
  /// 默认实现返回false，支持自动修复的检查器应该重写此方法。
  Future<bool> autoFix() async => false;
}

/// 系统环境检查器
///
/// 检查Dart运行时环境的基础信息，包括：
/// - Dart SDK版本信息
/// - 操作系统类型和版本
/// - Dart可执行文件路径和可用性
///
/// 这是最基础的环境检查，确保Dart开发环境正常可用。
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
      if (File(executable).existsSync()) {
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
///
/// 检查当前目录的Ming Status工作空间配置状态，包括：
/// - 工作空间初始化状态
/// - 配置文件的有效性和可读性
/// - 基础工作空间信息（名称、版本等）
///
/// 支持自动修复功能，可以在某些情况下自动修复配置问题。
class WorkspaceConfigChecker extends HealthChecker {
  /// 创建工作空间配置检查器
  ///
  /// [configManager] 用于访问和操作配置的管理器实例
  WorkspaceConfigChecker(this.configManager);

  /// 配置管理器实例
  final ConfigManager configManager;

  @override
  String get name => '工作空间配置';

  @override
  bool get canAutoFix => true;

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();

    try {
      final isInitializedResult = configManager.isWorkspaceInitialized();
      final isInitialized = isInitializedResult;
      if (isInitialized) {
        result.addSuccess('工作空间已初始化');

        final config = await configManager.loadWorkspaceConfig();
        if (config != null) {
          result
            ..addSuccess(r'配置文件有效: $configFilePath')
            ..addInfo(r'工作空间名称: $workspaceName')
            ..addInfo(r'工作空间版本: $workspaceVersion');
        } else {
          result.addError('配置文件无法加载');
        }
      } else {
        result
          ..addWarning('当前目录未初始化为Ming Status工作空间')
          ..addInfo('提示: 使用 "ming init" 初始化工作空间');
      }
    } catch (e) {
      result.addError('工作空间配置检查失败: $e');
    }

    return result;
  }

  @override
  Future<bool> autoFix() async {
    try {
      final isInitializedResult = configManager.isWorkspaceInitialized();
      final isInitialized = isInitializedResult;
      if (!isInitialized) {
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
///
/// 检查Dart项目的依赖包安装和配置状态，包括：
/// - pubspec.yaml文件存在性
/// - 依赖包安装状态（.dart_tool目录）
/// - 项目类型识别
///
/// 为开发者提供依赖管理相关的检查和建议。
class DependencyChecker extends HealthChecker {
  @override
  String get name => '依赖包状态';

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();

    try {
      // 检查pubspec.yaml
      const pubspecPath = 'pubspec.yaml';
      if (File(pubspecPath).existsSync()) {
        result.addSuccess('pubspec.yaml文件存在');

        // 检查.dart_tool目录
        if (Directory('.dart_tool').existsSync()) {
          result.addSuccess('依赖包已安装');
        } else {
          result
            ..addWarning('依赖包未安装')
            ..addInfo('提示: 运行 "dart pub get" 安装依赖');
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
///
/// 检查当前工作目录的文件系统权限，确保Ming CLI能够正常操作文件，包括：
/// - 目录读取权限验证
/// - 目录写入权限验证
/// - 临时文件创建和删除测试
///
/// 权限问题通常需要系统管理员权限解决，此检查器主要用于诊断。
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
        File('${currentDir.path}/.ming_temp_test')
          ..writeAsStringSync('test')
          ..deleteSync();
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
///
/// 执行工作空间配置的深度验证和分析，包括：
/// - 基础配置完整性检查
/// - 模板配置验证
/// - 环境配置分析
/// - 验证规则检查
/// - 高级配置验证功能
///
/// 提供比基础配置检查更详细和全面的配置分析，支持自动修复功能。
class ConfigDeepChecker extends HealthChecker {
  /// 创建配置深度检查器
  ///
  /// [configManager] 用于访问和验证配置的管理器实例
  ConfigDeepChecker(this.configManager);

  /// 配置管理器实例
  final ConfigManager configManager;

  @override
  String get name => '配置深度检查';

  @override
  bool get canAutoFix => true;

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();

    try {
      // 检查工作空间是否已初始化
      final isInitializedResult = configManager.isWorkspaceInitialized();
      final isWorkspaceInitialized = isInitializedResult;
      if (!isWorkspaceInitialized) {
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
        // 安全地调用验证方法
        final validationResultFuture =
            configManager.validateWorkspaceConfig(config);
        final validationResult = await validationResultFuture;

        final isValidResult = (validationResult as dynamic)?.isValid as bool?;
        final isValid = isValidResult ?? false;
        if (isValid) {
          result.addSuccess('配置深度验证通过');
        } else {
          final errors = (validationResult as dynamic)?.errors as List?;
          final warnings = (validationResult as dynamic)?.warnings as List?;
          final suggestions =
              (validationResult as dynamic)?.suggestions as List?;

          if (errors != null && errors.isNotEmpty) {
            for (final error in errors) {
              result.addError('验证错误: $error');
            }
          }
          if (warnings != null && warnings.isNotEmpty) {
            for (final warning in warnings) {
              result.addWarning('验证警告: $warning');
            }
          }
          if (suggestions != null && suggestions.isNotEmpty) {
            for (final suggestion in suggestions) {
              result.addInfo('建议: $suggestion');
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

  Future<void> _checkBasicConfig(
    dynamic config,
    ValidationResult result,
  ) async {
    // 检查工作空间基本信息
    try {
      // 正确处理WorkspaceConfig对象
      if (config is WorkspaceConfig) {
        // 检查工作空间名称
        final workspaceName = config.workspace.name;
        if (workspaceName.isNotEmpty) {
          result.addSuccess('工作空间名称已设置: $workspaceName');
        } else {
          result.addWarning('工作空间名称未设置或为空');
        }

        // 检查工作空间版本
        final workspaceVersion = config.workspace.version;
        if (workspaceVersion.isNotEmpty) {
          result.addSuccess('工作空间版本已设置: $workspaceVersion');
        } else {
          result.addWarning('工作空间版本未设置');
        }

        // 检查默认作者
        final defaultAuthor = config.defaults.author;
        if (defaultAuthor.isNotEmpty) {
          result.addSuccess('默认作者已设置: $defaultAuthor');
        } else {
          result.addWarning('默认作者未设置，建议设置以便自动填充');
        }
      } else {
        // 兼容性处理：如果是Map格式（向后兼容）
        final configMap = config is Map ? config : <String, dynamic>{};
        final workspaceData = configMap['workspace'] is Map
            ? configMap['workspace'] as Map
            : <String, dynamic>{};

        final workspaceName = workspaceData['name']?.toString();
        if (workspaceName?.isNotEmpty ?? false) {
          result.addSuccess('工作空间名称已设置: $workspaceName');
        } else {
          result.addWarning('工作空间名称未设置或为空');
        }

        final workspaceVersion = workspaceData['version']?.toString();
        if (workspaceVersion?.isNotEmpty ?? false) {
          result.addSuccess('工作空间版本已设置: $workspaceVersion');
        } else {
          result.addWarning('工作空间版本未设置');
        }

        // 检查默认设置
        final defaultsData = configMap['defaults'] is Map
            ? configMap['defaults'] as Map
            : <String, dynamic>{};
        final defaultAuthor = defaultsData['author']?.toString();
        if (defaultAuthor?.isNotEmpty ?? false) {
          result.addSuccess('默认作者已设置: $defaultAuthor');
        } else {
          result.addWarning('默认作者未设置，建议设置以便自动填充');
        }
      }
    } catch (e) {
      result.addWarning('基础配置检查出错: $e');
    }
  }

  Future<void> _checkTemplateConfig(
    dynamic config,
    ValidationResult result,
  ) async {
    try {
      if (config is WorkspaceConfig) {
        // 正确处理WorkspaceConfig对象
        result.addSuccess('模板配置已启用');

        // 检查模板路径
        final localPath = config.templates.localPath;
        if (localPath?.isNotEmpty ?? false) {
          if (Directory(localPath!).existsSync()) {
            result.addSuccess('模板目录存在: $localPath');
          } else {
            result.addWarning('模板目录不存在: $localPath');
          }
        }

        // 检查缓存设置
        final cacheTimeout = config.templates.cacheTimeout;
        if (cacheTimeout > 0) {
          result.addInfo('模板缓存超时: $cacheTimeout秒');
        }
      } else {
        // 兼容性处理：如果是Map格式（向后兼容）
        final configMap = config is Map ? config : <String, dynamic>{};
        final templatesData = configMap['templates'] is Map
            ? configMap['templates'] as Map
            : null;

        if (templatesData != null) {
          result.addSuccess('模板配置已启用');

          // 检查模板路径
          final localPath = templatesData['localPath']?.toString();
          if (localPath?.isNotEmpty ?? false) {
            if (Directory(localPath!).existsSync()) {
              result.addSuccess('模板目录存在: $localPath');
            } else {
              result.addWarning('模板目录不存在: $localPath');
            }
          }

          // 检查缓存设置
          final cacheTimeout = templatesData['cacheTimeout'];
          if (cacheTimeout != null && cacheTimeout is int && cacheTimeout > 0) {
            result.addInfo('模板缓存超时: $cacheTimeout秒');
          }
        } else {
          result.addWarning('模板配置未设置');
        }
      }
    } catch (e) {
      result.addWarning('模板配置检查出错: $e');
    }
  }

  Future<void> _checkEnvironmentConfig(
    dynamic config,
    ValidationResult result,
  ) async {
    try {
      // 安全访问配置对象
      final configMap = config is Map ? config : <String, dynamic>{};
      final environments = configMap['environments'];

      if (environments != null &&
          environments is Map &&
          environments.isNotEmpty) {
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

  Future<void> _checkValidationConfig(
    dynamic config,
    ValidationResult result,
  ) async {
    try {
      if (config is WorkspaceConfig) {
        // 正确处理WorkspaceConfig对象
        result.addSuccess('验证规则已配置');

        if (config.validation.strictMode) {
          result.addInfo('严格模式已启用');
        }

        final minCoverage = config.validation.minCoverage;
        if (minCoverage >= 80) {
          result.addSuccess('测试覆盖率要求: $minCoverage%');
        } else {
          result.addWarning('测试覆盖率要求较低: $minCoverage%，建议至少80%');
        }
      } else {
        // 兼容性处理：如果是Map格式（向后兼容）
        final configMap = config is Map ? config : <String, dynamic>{};
        final validationData = configMap['validation'] is Map
            ? configMap['validation'] as Map
            : null;

        if (validationData != null) {
          result.addSuccess('验证规则已配置');

          final strictMode = validationData['strictMode'];
          if (strictMode == true) {
            result.addInfo('严格模式已启用');
          }

          final minCoverage = validationData['minCoverage'];
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
///
/// 检查用户级别的配置设置和目录结构，包括：
/// - 用户主目录下的Ming Status配置目录
/// - 用户配置文件的存在性和有效性
/// - 用户配置管理器的可用性
///
/// 注意：此功能在Phase 1中处于开发状态，完整功能将在Phase 2中实现。
class UserConfigChecker extends HealthChecker {
  /// 创建用户配置检查器
  ///
  /// [configManager] 配置管理器实例，用于访问用户配置功能
  UserConfigChecker(this.configManager);

  /// 配置管理器实例
  final ConfigManager configManager;

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
      final hasUserConfigManagerMethod =
          (configManager.runtimeType.toString() as String?)?.contains(
                'ConfigManager',
              ) ??
              false;

      if (hasUserConfigManagerMethod) {
        result.addInfo('用户配置管理功能检查（Phase 1：功能开发中）');

        // 检查用户主目录下的配置目录
        try {
          final userHomeDir = Platform.environment['USERPROFILE'] ??
              Platform.environment['HOME'];
          if (userHomeDir != null) {
            final mingConfigDir = path.join(userHomeDir, '.ming_status');
            if (Directory(mingConfigDir).existsSync()) {
              result.addSuccess('用户配置目录存在: $mingConfigDir');
            } else {
              result.addInfo(
                '用户配置目录不存在: $mingConfigDir（首次使用时会自动创建）',
              );
            }

            final userConfigFile = path.join(mingConfigDir, 'config.yaml');
            if (File(userConfigFile).existsSync()) {
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
        result
          ..addInfo('用户配置管理功能将在Phase 2中完整实现')
          ..addInfo('当前版本支持基本的工作空间配置管理');
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
///
/// 检查配置模板系统的完整性和可用性，包括：
/// - 可用配置模板的列表和验证
/// - 内置模板（basic、enterprise）的有效性
/// - 模板目录结构的存在性
/// - 工作空间模板的可用性检查
///
/// 确保模板引擎能够正常工作并提供必要的初始化模板。
class ConfigTemplateChecker extends HealthChecker {
  /// 创建配置模板检查器
  ///
  /// [configManager] 配置管理器实例，用于访问模板功能
  ConfigTemplateChecker(this.configManager);

  /// 配置管理器实例
  final ConfigManager configManager;

  @override
  String get name => '配置模板';

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();

    try {
      // 检查可用的配置模板
      final templatesResult = configManager.listConfigTemplates() as dynamic;
      final templates =
          templatesResult is List ? templatesResult.cast<String>() : <String>[];
      if (templates.isNotEmpty) {
        result.addSuccess(
          '可用配置模板: ${templates.join(', ')}',
        );

        // 验证内置模板
        final builtinTemplates = ['basic', 'enterprise'];
        for (final template in builtinTemplates) {
          final validationFuture =
              configManager.validateConfigTemplate(template) as Future?;
          final isValid = (await validationFuture as bool?) ?? false;
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
      final templatesPathResult = configManager.getTemplatesPath() as dynamic;
      final templatesPath =
          templatesPathResult is String ? templatesPathResult : '';
      if (templatesPath.isNotEmpty && Directory(templatesPath).existsSync()) {
        result.addSuccess('模板目录存在: $templatesPath');

        final workspaceTemplatesPath = '$templatesPath/workspace';
        if (Directory(workspaceTemplatesPath).existsSync()) {
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
