/*
---------------------------------------------------------------
File name:          default_hooks.dart
Author:             lgnorant-lu
Date created:       2025/07/03
Last modified:      2025/07/03
Dart Version:       3.2+
Description:        默认钩子实现 (Default hooks implementation)
---------------------------------------------------------------
Change History:
    2025/07/02: Initial creation - 默认钩子实现功能;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_engine/template_models.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:ming_status_cli/src/utils/string_utils.dart';

/// 默认验证钩子
class DefaultValidationHook extends TemplateHook {
  DefaultValidationHook() : super(name: 'default_validation');

  @override
  HookType get type => HookType.preGeneration;

  @override
  int get priority => 10; // 高优先级，优先执行

  @override
  Future<HookResult> execute(HookContext context) async {
    try {
      // 验证必需变量
      final requiredVars = ['module_id', 'module_name'];
      for (final varName in requiredVars) {
        if (!context.variables.containsKey(varName) ||
            StringUtils.isBlank(context.variables[varName]?.toString())) {
          return HookResult.failure('必需变量缺失: $varName');
        }
      }

      // 验证输出路径
      if (StringUtils.isBlank(context.outputPath)) {
        return HookResult.failure('输出路径不能为空');
      }

      return HookResult.successResult;
    } catch (e) {
      return HookResult.failure('验证过程中发生异常: $e');
    }
  }
}

/// 默认日志钩子
class DefaultLoggingHook extends TemplateHook {
  DefaultLoggingHook() : super(name: 'default_logging');

  @override
  HookType get type => HookType.postGeneration;

  @override
  int get priority => 900; // 低优先级，最后执行

  @override
  Future<HookResult> execute(HookContext context) async {
    try {
      final metadata = context.metadata;
      final duration =
          metadata.containsKey('startTime') && metadata.containsKey('endTime')
              ? DateTime.parse(metadata['endTime'] as String)
                  .difference(DateTime.parse(metadata['startTime'] as String))
              : null;

      cli_logger.Logger.success(
        '模板生成完成: ${context.templateName} -> ${context.outputPath}',
      );

      if (duration != null) {
        cli_logger.Logger.debug('生成耗时: ${duration.inMilliseconds}ms');
      }

      if (metadata.containsKey('generatedFiles')) {
        final files = metadata['generatedFiles'] as List<String>? ?? [];
        cli_logger.Logger.debug('生成文件数量: ${files.length}');
      }

      return HookResult.successResult;
    } catch (e) {
      // 日志钩子失败不应该影响整体流程
      cli_logger.Logger.warning('日志钩子执行异常: $e');
      return HookResult.successResult;
    }
  }
}
