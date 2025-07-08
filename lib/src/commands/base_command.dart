/*
---------------------------------------------------------------
File name:          base_command.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        基础命令类 (Base command class)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - CLI命令基础类;
    2025/06/29: Performance optimization - 延迟初始化服务，提升启动性能;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/config_manager.dart';
import 'package:ming_status_cli/src/core/module_validator.dart';
import 'package:ming_status_cli/src/core/template_engine.dart';
import 'package:ming_status_cli/src/models/workspace_config.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 基础命令类
/// 为所有CLI命令提供通用功能和依赖注入
abstract class BaseCommand extends Command<int> {
  /// 创建基础命令实例，初始化通用选项
  BaseCommand() {
    _setupCommonOptions();
  }

  /// 配置管理器（延迟初始化）
  ConfigManager? _configManager;

  /// 模板引擎（延迟初始化）
  TemplateEngine? _templateEngine;

  /// 模块验证器（延迟初始化）
  ModuleValidator? _moduleValidator;

  /// 当前工作目录
  String get workingDirectory => Directory.current.path;

  /// 是否启用详细输出
  bool get verbose => globalResults?['verbose'] == true;

  /// 是否启用安静模式
  bool get quiet => globalResults?['quiet'] == true;

  /// 获取配置管理器（延迟初始化）
  ConfigManager get configManager {
    return _configManager ??= ConfigManager(workingDirectory: workingDirectory);
  }

  /// 获取模板引擎（延迟初始化）
  TemplateEngine get templateEngine {
    return _templateEngine ??=
        TemplateEngine(workingDirectory: workingDirectory);
  }

  /// 获取模块验证器（延迟初始化）
  ModuleValidator get moduleValidator {
    return _moduleValidator ??= ModuleValidator();
  }

  /// 设置通用选项
  void _setupCommonOptions() {
    // 子类可以重写此方法来添加特定选项
  }

  /// 执行前的准备工作
  Future<void> preExecute() async {
    // 设置日志级别
    if (verbose) {
      Logger.verbose = true;
      Logger.minLevel = LogLevel.debug;
    } else if (quiet) {
      Logger.minLevel = LogLevel.error;
    }

    Logger.debug('当前工作目录: $workingDirectory');
    Logger.debug('命令: $name');
  }

  /// 执行后的清理工作
  Future<void> postExecute() async {
    // 只清理已初始化的服务
    _templateEngine?.clearCache();
    _configManager?.clearCache();

    Logger.debug('命令执行完成: $name');
  }

  /// 检查工作空间是否已初始化
  bool checkWorkspaceInitialized({bool showError = true}) {
    final isInitialized = configManager.isWorkspaceInitialized();

    if (!isInitialized && showError) {
      Logger.error('工作空间未初始化');
      Logger.info('请先运行 "ming init" 命令初始化工作空间');
    }

    return isInitialized;
  }

  /// 获取工作空间配置
  Future<WorkspaceConfig?> getWorkspaceConfig() async {
    if (!checkWorkspaceInitialized()) {
      return null;
    }

    return configManager.loadWorkspaceConfig();
  }

  /// 显示命令帮助信息
  void showHelp() {
    Logger.info(usage);
  }

  /// 显示错误信息并退出
  Never exitWithError(String message, {int exitCode = 1}) {
    Logger.error(message);
    exit(exitCode);
  }

  /// 显示成功信息并退出
  Never exitWithSuccess(String message, {int exitCode = 0}) {
    Logger.success(message);
    exit(exitCode);
  }

  /// 确认用户操作
  bool confirmAction(String message, {bool defaultValue = false}) {
    if (quiet) {
      return defaultValue;
    }

    final defaultText = defaultValue ? 'Y/n' : 'y/N';
    stdout.write('$message [$defaultText]: ');

    final input = stdin.readLineSync()?.trim().toLowerCase();

    if (input == null || input.isEmpty) {
      return defaultValue;
    }

    return input == 'y' || input == 'yes' || input == '是';
  }

  /// 获取用户输入
  String? getUserInput(
    String prompt, {
    String? defaultValue,
    bool required = false,
  }) {
    if (quiet && defaultValue != null) {
      return defaultValue;
    }

    final defaultText = defaultValue != null ? ' (默认: $defaultValue)' : '';
    stdout.write('$prompt$defaultText: ');

    final input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) {
      if (required && defaultValue == null) {
        Logger.error('此项为必填项');
        return getUserInput(
          prompt,
          defaultValue: defaultValue,
          required: required,
        );
      }
      return defaultValue;
    }

    return input;
  }

  /// 验证模块路径
  Future<bool> validateModulePath(
    String modulePath, {
    bool showDetails = false,
  }) async {
    final isValid = await moduleValidator.quickValidate(modulePath);

    if (!isValid && showDetails) {
      Logger.error('模块路径无效: $modulePath');
      Logger.info('请确保路径包含有效的模块结构');
    }

    return isValid;
  }

  /// 格式化文件大小
  String formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];

    if (bytes == 0) return '0 B';

    final unitIndex = (bytes.bitLength - 1) ~/ 10;
    final size = bytes / (1 << (unitIndex * 10));

    if (unitIndex < units.length) {
      return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[unitIndex]}';
    } else {
      return '$bytes B';
    }
  }

  /// 执行命令的模板方法
  @override
  Future<int> run() async {
    try {
      // 前置处理
      await preExecute();

      // 执行具体命令
      final result = await execute();

      // 后置处理
      await postExecute();

      return result;
    } catch (e) {
      Logger.error('命令执行失败: $e');
      await postExecute();
      return 1;
    }
  }

  /// 具体命令的执行逻辑（子类必须实现）
  Future<int> execute();
}
