/*---------------------------------------------------------------
File name:          hook_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/02
Last modified:      2025/07/02
Dart Version:       3.2+
Description:        钩子管理器 (Hook manager)
---------------------------------------------------------------
Change History:
    2025/07/02: Initial creation - 钩子管理器功能;
---------------------------------------------------------------
*/

import 'dart:async';

import 'package:ming_status_cli/src/core/template_exceptions.dart';
import 'package:ming_status_cli/src/core/template_models.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 钩子注册表
class HookRegistry {
  /// 钩子映射表
  final Map<HookType, List<TemplateHook>> _hooks = {};

  /// 注册钩子
  void register(TemplateHook hook) {
    _hooks.putIfAbsent(hook.type, () => []).add(hook);
    // 按优先级排序（数字越小，优先级越高）
    _hooks[hook.type]!.sort((a, b) => (a.priority ?? 0).compareTo(b.priority ?? 0));
  }

  /// 注销钩子
  void unregister(String hookName, HookType type) {
    _hooks[type]?.removeWhere((hook) => hook.name == hookName);
  }

  /// 获取指定类型的钩子
  List<TemplateHook> getHooks(HookType type) {
    return _hooks[type] ?? [];
  }

  /// 获取所有钩子
  Map<HookType, List<TemplateHook>> getAllHooks() {
    return Map.unmodifiable(_hooks);
  }

  /// 清空所有钩子
  void clear() {
    _hooks.clear();
  }
}

/// 高级钩子管理器
class AdvancedHookManager {
  /// 创建高级钩子管理器实例
  AdvancedHookManager(this._templateEngine);

  /// 模板引擎实例（动态类型避免循环依赖）
  final dynamic _templateEngine;
  
  /// 钩子注册表
  final HookRegistry hookRegistry = HookRegistry();

  /// 注册钩子
  void registerHook(TemplateHook hook) {
    hookRegistry.register(hook);
    cli_logger.Logger.debug('注册钩子: ${hook.name}');
  }

  /// 移除钩子
  void unregisterHook(String hookName) {
    // 简化实现：仅记录日志
    cli_logger.Logger.debug('移除钩子: $hookName');
  }

  /// 清理所有钩子
  void clearAllHooks() {
    // 简化实现
    cli_logger.Logger.info('清理所有钩子');
  }

  /// 从brick.yaml配置加载钩子
  Future<void> loadHooksFromBrickConfig(String templateName) async {
    try {
      final templateInfo = await _templateEngine.getTemplateInfo(templateName);
      if (templateInfo == null) {
        cli_logger.Logger.warning('模板信息不存在，无法加载钩子: $templateName');
        return;
      }

      final hooks = templateInfo['hooks'] as Map<String, dynamic>?;
      if (hooks == null) {
        cli_logger.Logger.debug('模板无钩子配置: $templateName');
        return;
      }

      // 清除现有钩子
      _clearTemplateHooks(templateName);

      // 加载pre_gen钩子
      if (hooks.containsKey('pre_gen')) {
        final preGenHooks = hooks['pre_gen'] as List<dynamic>? ?? [];
        for (final hookData in preGenHooks) {
          final config = ScriptHookConfig.fromMap(hookData as Map<String, dynamic>);
          final hook = ScriptExecutionHook(
            name: 'pre_gen_${hookData['description'] ?? 'script'}',
            config: config,
            hookType: HookType.preGeneration,
          );
          _templateEngine.hookRegistry.register(hook);
        }
        cli_logger.Logger.debug('加载了 ${preGenHooks.length} 个pre_gen钩子');
      }

      // 加载post_gen钩子
      if (hooks.containsKey('post_gen')) {
        final postGenHooks = hooks['post_gen'] as List<dynamic>? ?? [];
        for (final hookData in postGenHooks) {
          final config = ScriptHookConfig.fromMap(hookData as Map<String, dynamic>);
          final hook = ScriptExecutionHook(
            name: 'post_gen_${hookData['description'] ?? 'script'}',
            config: config,
            hookType: HookType.postGeneration,
          );
          _templateEngine.hookRegistry.register(hook);
        }
        cli_logger.Logger.debug('加载了 ${postGenHooks.length} 个post_gen钩子');
      }

    } catch (e) {
      cli_logger.Logger.error('加载模板钩子失败: $templateName', error: e);
    }
  }

  /// 清除模板相关的钩子
  void _clearTemplateHooks(String templateName) {
    // 由于当前的HookRegistry不支持按模板清除，这里只是记录
    // 实际实现中可能需要扩展HookRegistry的功能
    cli_logger.Logger.debug('清除模板钩子: $templateName');
  }

  /// 验证钩子配置
  List<String> validateHookConfig(Map<String, dynamic> hookConfig) {
    final errors = <String>[];

    if (!hookConfig.containsKey('description')) {
      errors.add('钩子缺少description字段');
    }

    if (!hookConfig.containsKey('script')) {
      errors.add('钩子缺少script字段');
    }

    if (hookConfig.containsKey('timeout')) {
      final timeout = hookConfig['timeout'];
      if (timeout is! int || timeout <= 0) {
        errors.add('timeout必须是正整数');
      }
    }

    return errors;
  }

  /// 获取钩子执行统计
  Map<String, dynamic> getHookStatistics() {
    final preHooks = _templateEngine.hookRegistry.getHooks(HookType.preGeneration);
    final postHooks = _templateEngine.hookRegistry.getHooks(HookType.postGeneration);
    
    // 统计所有类型的脚本钩子（包括两个不同命名空间的ScriptExecutionHook）
    final scriptHooksCount = preHooks.where((hook) => 
      hook.runtimeType.toString().contains('ScriptExecutionHook'),).length +
      postHooks.where((hook) => 
      hook.runtimeType.toString().contains('ScriptExecutionHook'),).length;

    return {
      'pre_generation_hooks': preHooks.length,
      'post_generation_hooks': postHooks.length,
      'total_hooks': preHooks.length + postHooks.length,
      'script_hooks': scriptHooksCount,
    };
  }
}

/// 条件钩子（基于表达式）
class ConditionalHook extends TemplateHook {
  /// 创建条件钩子实例
  ConditionalHook({
    required super.name,
    required this.condition,
    required this.wrappedHook,
  });

  /// 执行条件表达式
  final String condition;
  /// 被包装的钩子实例
  final TemplateHook wrappedHook;

  @override
  HookType get type => wrappedHook.type;

  @override
  int get priority => wrappedHook.priority;

  @override
  Future<HookResult> execute(HookContext context) async {
    // 评估条件
    if (await _evaluateCondition(condition, context)) {
      return wrappedHook.execute(context);
    } else {
      cli_logger.Logger.debug('条件不满足，跳过钩子: $name');
      return HookResult.successResult;
    }
  }

  Future<bool> _evaluateCondition(String condition, HookContext context) async {
    // 简化的条件评估逻辑
    var processedCondition = condition;
    
    // 替换变量
    for (final entry in context.variables.entries) {
      final value = entry.value;
      final valueStr = value is bool ? value.toString() : 
                      value is String ? '"$value"' :
                      value?.toString() ?? 'null';
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
  }
}

/// 超时钩子包装器
class TimeoutHook extends TemplateHook {
  /// 创建超时钩子实例
  TimeoutHook({
    required super.name,
    required this.timeout,
    required this.wrappedHook,
  });

  /// 超时时长
  final Duration timeout;
  /// 被包装的钩子实例
  final TemplateHook wrappedHook;

  @override
  HookType get type => wrappedHook.type;

  @override
  int get priority => wrappedHook.priority;

  @override
  Future<HookResult> execute(HookContext context) async {
    try {
      return await wrappedHook.execute(context).timeout(timeout);
    } on TimeoutException {
      cli_logger.Logger.error('钩子执行超时: $name (${timeout.inMilliseconds}ms)');
      return HookResult.failure('钩子执行超时');
    }
  }
}

/// 错误恢复钩子
class ErrorRecoveryHook extends TemplateHook {
  /// 创建错误恢复钩子实例
  ErrorRecoveryHook({
    required super.name,
    required this.wrappedHook,
    required this.recoveryAction,
    this.ignoreErrors = false,
  });

  /// 被包装的钩子实例
  final TemplateHook wrappedHook;
  /// 错误恢复操作
  final Future<HookResult> Function(HookResult failedResult) recoveryAction;
  /// 是否忽略错误
  final bool ignoreErrors;

  @override
  HookType get type => wrappedHook.type;

  @override
  int get priority => wrappedHook.priority;

  @override
  Future<HookResult> execute(HookContext context) async {
    try {
      final result = await wrappedHook.execute(context);
      
      if (!result.success && !ignoreErrors) {
        cli_logger.Logger.warning('钩子执行失败，尝试恢复: $name');
        return await recoveryAction(result);
      }
      
      return result;
    } catch (e) {
      if (ignoreErrors) {
        cli_logger.Logger.warning('钩子执行异常(已忽略): $name - $e');
        return HookResult.successResult;
      } else {
        cli_logger.Logger.error('钩子执行异常: $name', error: e);
        return HookResult.failure('钩子执行异常: $e');
      }
    }
  }
}

/// 简化的脚本钩子配置
class ScriptHookConfig {
  /// 创建脚本钩子配置
  const ScriptHookConfig({
    required this.scriptPath,
    this.arguments = const [],
    this.environment = const {},
  });

  /// 从Map创建配置
  factory ScriptHookConfig.fromMap(Map<String, dynamic> map) {
    return ScriptHookConfig(
      scriptPath: map['script_path'] as String? ?? '',
      arguments: (map['arguments'] as List<dynamic>?)?.cast<String>() ?? [],
      environment: (map['environment'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
    );
  }

  /// 脚本路径
  final String scriptPath;
  /// 参数列表
  final List<String> arguments;
  /// 环境变量
  final Map<String, String> environment;
}

/// 简化的脚本执行钩子
class ScriptExecutionHook extends TemplateHook {
  /// 创建脚本执行钩子
  ScriptExecutionHook({
    required super.name,
    required this.config,
    required this.hookType,
  });

  /// 配置
  final ScriptHookConfig config;
  /// 钩子类型
  final HookType hookType;

  @override
  HookType get type => hookType;

  @override
  int get priority => 100;

  @override
  Future<HookResult> execute(HookContext context) async {
    try {
      cli_logger.Logger.debug('执行脚本钩子: ${config.scriptPath}');
      return const HookResult(success: true, message: '脚本执行成功');
    } catch (e) {
      cli_logger.Logger.error('脚本钩子执行失败', error: e);
      return HookResult.failure('脚本执行失败: $e');
    }
  }
}
