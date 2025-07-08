/*
---------------------------------------------------------------
File name:          hook_implementations.dart
Author:             lgnorant-lu
Date created:       2025/07/02
Last modified:      2025/07/02
Dart Version:       3.2+
Description:        钩子实现 (Hook implementations)
---------------------------------------------------------------
Change History:
    2025/07/02: Initial creation - 钩子实现功能;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/core/template_models.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 脚本执行钩子配置
class ScriptHookConfig {
  /// 创建脚本钩子配置实例
  const ScriptHookConfig({
    required this.scriptPath,
    this.arguments = const [],
    this.environment,
    this.description = '',
    this.condition,
    this.timeout = 30000,
    this.ignoreErrors = false,
    this.workingDirectory,
  });

  /// 从Map创建配置
  factory ScriptHookConfig.fromMap(Map<String, dynamic> map) {
    return ScriptHookConfig(
      scriptPath:
          map['script_path'] as String? ?? map['script'] as String? ?? '',
      arguments: (map['arguments'] as List<dynamic>?)?.cast<String>() ?? [],
      environment:
          (map['environment'] as Map<String, dynamic>?)?.cast<String, String>(),
      description: map['description'] as String? ?? '',
      condition: map['condition'] as String?,
      timeout: map['timeout'] as int? ?? 30000,
      ignoreErrors: map['ignore_errors'] as bool? ?? false,
      workingDirectory: map['working_directory'] as String?,
    );
  }

  /// 脚本路径
  final String scriptPath;

  /// 参数列表
  final List<String> arguments;

  /// 环境变量
  final Map<String, String>? environment;

  /// 钩子描述
  final String description;

  /// 执行条件
  final String? condition;

  /// 超时时间（毫秒）
  final int timeout;

  /// 是否忽略错误
  final bool ignoreErrors;

  /// 工作目录
  final String? workingDirectory;
}

/// 脚本执行钩子
class ScriptExecutionHook extends TemplateHook {
  /// 创建脚本执行钩子实例
  ScriptExecutionHook({
    required super.name,
    required this.config,
    required this.hookType,
    this.hookPriority = 100,
  });

  /// 脚本钩子配置
  final ScriptHookConfig config;

  /// 钩子类型
  final HookType hookType;

  /// 钩子优先级
  final int hookPriority;

  @override
  HookType get type => hookType;

  @override
  int get priority => hookPriority;

  @override
  Future<HookResult> execute(HookContext context) async {
    try {
      // 检查执行条件
      if (config.condition != null &&
          !await _evaluateCondition(config.condition!, context)) {
        cli_logger.Logger.debug('钩子条件不满足，跳过执行: ${config.description}');
        return HookResult.successResult;
      }

      cli_logger.Logger.info('执行钩子: ${config.description}');

      // 处理脚本中的变量插值
      final processedScript =
          await _interpolateScript(config.scriptPath, context);

      // 执行脚本
      final result = await _executeScript(
        processedScript,
        context,
        config.workingDirectory ?? context.outputPath,
        config.timeout,
      );

      if (result.success || config.ignoreErrors) {
        cli_logger.Logger.success('钩子执行完成: ${config.description}');
        return HookResult(
          success: true,
          message: result.output,
        );
      } else {
        cli_logger.Logger.error(
          '钩子执行失败: ${config.description} - ${result.error}',
        );
        return HookResult.failure('脚本执行失败: ${result.error}');
      }
    } catch (e) {
      if (config.ignoreErrors) {
        cli_logger.Logger.warning('钩子执行异常(已忽略): ${config.description} - $e');
        return HookResult.successResult;
      } else {
        cli_logger.Logger.error('钩子执行异常: ${config.description}', error: e);
        return HookResult.failure('钩子执行异常: $e');
      }
    }
  }

  /// 评估条件表达式
  Future<bool> _evaluateCondition(String condition, HookContext context) async {
    try {
      // 简单的条件评估实现
      // 支持基本的布尔运算和变量替换
      var processedCondition = condition;

      // 替换变量
      for (final entry in context.variables.entries) {
        final value = entry.value;
        final valueStr = value is bool
            ? value.toString()
            : value is String
                ? '"$value"'
                : value?.toString() ?? 'null';
        processedCondition = processedCondition.replaceAll(
          '{{${entry.key}}}',
          valueStr,
        );
      }

      // 处理特殊关键字
      processedCondition = processedCondition
          .replaceAll('success', 'true')
          .replaceAll('true', 'true')
          .replaceAll('false', 'false');

      // 简单的布尔表达式评估
      if (processedCondition == 'true') return true;
      if (processedCondition == 'false') return false;

      // 更复杂的条件可以在这里扩展
      return processedCondition.isNotEmpty;
    } catch (e) {
      cli_logger.Logger.warning('条件评估失败，默认为true: $condition - $e');
      return true;
    }
  }

  /// 插值脚本中的变量
  Future<String> _interpolateScript(String script, HookContext context) async {
    var processedScript = script;

    // 替换模板变量
    for (final entry in context.variables.entries) {
      processedScript = processedScript.replaceAll(
        '{{${entry.key}}}',
        entry.value?.toString() ?? '',
      );
    }

    // 替换上下文变量
    return processedScript
        .replaceAll('{{template_name}}', context.templateName)
        .replaceAll('{{output_path}}', context.outputPath)
        .replaceAll('{{output.path}}', context.outputPath);
  }

  /// 执行脚本命令
  Future<ScriptExecutionResult> _executeScript(
    String script,
    HookContext context,
    String workingDirectory,
    int timeoutMs,
  ) async {
    try {
      // 设置工作目录
      final workDir = Directory(workingDirectory);
      if (!workDir.existsSync()) {
        workDir.createSync(recursive: true);
      }

      // 分解命令和参数
      final parts = script.split(' ');
      final command = parts.first;
      final arguments = parts.skip(1).toList();

      // 执行命令
      final process = await Process.start(
        command,
        arguments,
        workingDirectory: workingDirectory,
        environment: {
          ...Platform.environment,
          ...?config.environment,
        },
      );

      // 设置超时
      final timeout = Duration(milliseconds: timeoutMs);
      final exitCode = await process.exitCode.timeout(timeout);

      // 读取输出
      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();

      if (exitCode == 0) {
        return ScriptExecutionResult.createSuccess(stdout);
      } else {
        return ScriptExecutionResult.createFailure(
          stderr.isNotEmpty ? stderr : stdout,
        );
      }
    } on TimeoutException {
      return ScriptExecutionResult.createFailure('脚本执行超时 (${timeoutMs}ms)');
    } catch (e) {
      return ScriptExecutionResult.createFailure('脚本执行异常: $e');
    }
  }
}

/// 脚本执行结果
class ScriptExecutionResult {
  /// 创建脚本执行结果实例
  const ScriptExecutionResult({
    required this.success,
    this.output,
    this.error,
  });

  /// 创建成功结果
  ScriptExecutionResult.createSuccess(String output)
      : this(success: true, output: output);

  /// 创建失败结果
  ScriptExecutionResult.createFailure(String error)
      : this(success: false, error: error);

  /// 执行是否成功
  final bool success;

  /// 标准输出内容
  final String? output;

  /// 错误信息
  final String? error;
}
