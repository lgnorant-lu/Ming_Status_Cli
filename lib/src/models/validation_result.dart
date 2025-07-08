/*
---------------------------------------------------------------
File name:          validation_result.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        验证结果数据模型 (Validation result data model)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 基础验证结果模型;
---------------------------------------------------------------
*/

/// 验证结果类
/// 存储模块验证过程的所有结果信息
class ValidationResult {
  /// 创建验证结果实例
  ValidationResult({this.strictMode = false}) : startTime = DateTime.now();

  /// 是否验证通过
  bool get isValid => errors.isEmpty && (warnings.isEmpty || !strictMode);

  /// 验证消息列表
  final List<ValidationMessage> messages = [];

  /// 错误消息列表
  List<ValidationMessage> get errors =>
      messages.where((m) => m.severity == ValidationSeverity.error).toList();

  /// 警告消息列表
  List<ValidationMessage> get warnings =>
      messages.where((m) => m.severity == ValidationSeverity.warning).toList();

  /// 信息消息列表
  List<ValidationMessage> get infos =>
      messages.where((m) => m.severity == ValidationSeverity.info).toList();

  /// 成功消息列表
  List<ValidationMessage> get successes =>
      messages.where((m) => m.severity == ValidationSeverity.success).toList();

  /// 获取指定类型的消息
  List<ValidationMessage> getMessagesByType(ValidationType type) =>
      messages.where((m) => m.validationType == type).toList();

  /// 获取可自动修复的消息
  List<ValidationMessage> get autoFixableMessages => messages
      .where(
        (m) => m.fixSuggestion?.fixabilityLevel == FixabilityLevel.automatic,
      )
      .toList();

  /// 获取有修复建议的消息
  List<ValidationMessage> get suggestedFixMessages => messages
      .where(
        (m) => m.fixSuggestion?.fixabilityLevel == FixabilityLevel.suggested,
      )
      .toList();

  /// 获取指定验证器的消息
  List<ValidationMessage> getMessagesByValidator(String validatorName) =>
      messages.where((m) => m.validatorName == validatorName).toList();

  /// 是否严格模式
  final bool strictMode;

  /// 验证开始时间
  final DateTime startTime;

  /// 验证结束时间
  DateTime? endTime;

  /// 验证耗时（毫秒）
  int? get durationMs => endTime?.difference(startTime).inMilliseconds;

  /// 添加错误消息
  void addError(
    String message, {
    String? code,
    String? file,
    int? line,
    ValidationType validationType = ValidationType.general,
    FixSuggestion? fixSuggestion,
    String? validatorName,
  }) {
    messages.add(
      ValidationMessage(
        severity: ValidationSeverity.error,
        message: message,
        code: code,
        file: file,
        line: line,
        validationType: validationType,
        fixSuggestion: fixSuggestion,
        validatorName: validatorName,
      ),
    );
  }

  /// 添加警告消息
  void addWarning(
    String message, {
    String? code,
    String? file,
    int? line,
    ValidationType validationType = ValidationType.general,
    FixSuggestion? fixSuggestion,
    String? validatorName,
  }) {
    messages.add(
      ValidationMessage(
        severity: ValidationSeverity.warning,
        message: message,
        code: code,
        file: file,
        line: line,
        validationType: validationType,
        fixSuggestion: fixSuggestion,
        validatorName: validatorName,
      ),
    );
  }

  /// 添加信息消息
  void addInfo(
    String message, {
    String? code,
    String? file,
    int? line,
    ValidationType validationType = ValidationType.general,
    FixSuggestion? fixSuggestion,
    String? validatorName,
  }) {
    messages.add(
      ValidationMessage(
        severity: ValidationSeverity.info,
        message: message,
        code: code,
        file: file,
        line: line,
        validationType: validationType,
        fixSuggestion: fixSuggestion,
        validatorName: validatorName,
      ),
    );
  }

  /// 添加成功消息
  void addSuccess(
    String message, {
    String? code,
    String? file,
    int? line,
    ValidationType validationType = ValidationType.general,
    FixSuggestion? fixSuggestion,
    String? validatorName,
  }) {
    messages.add(
      ValidationMessage(
        severity: ValidationSeverity.success,
        message: message,
        code: code,
        file: file,
        line: line,
        validationType: validationType,
        fixSuggestion: fixSuggestion,
        validatorName: validatorName,
      ),
    );
  }

  /// 标记验证完成
  void markCompleted() {
    endTime = DateTime.now();
  }

  /// 获取总结信息
  ValidationSummary getSummary() {
    return ValidationSummary(
      isValid: isValid,
      errorCount: errors.length,
      warningCount: warnings.length,
      infoCount: infos.length,
      successCount: successes.length,
      durationMs: durationMs ?? 0,
    );
  }

  /// 格式化输出验证结果
  String formatOutput({
    bool includeSuccesses = false,
    OutputFormat format = OutputFormat.console,
  }) {
    switch (format) {
      case OutputFormat.console:
        return _formatConsoleOutput(includeSuccesses: includeSuccesses);
      case OutputFormat.json:
        return _formatJsonOutput();
      case OutputFormat.junit:
        return _formatJUnitOutput();
      case OutputFormat.compact:
        return _formatCompactOutput();
    }
  }

  /// 格式化控制台输出
  String _formatConsoleOutput({bool includeSuccesses = false}) {
    final buffer = StringBuffer();

    // 添加错误
    for (final error in errors) {
      buffer.writeln('❌ ERROR: ${error.message}');
      if (error.file != null) {
        buffer.writeln(
          '   📁 ${error.file}'
          '${error.line != null ? ':${error.line}' : ''}',
        );
      }
      if (error.code != null) {
        buffer.writeln('   🔍 Code: ${error.code}');
      }
    }

    // 添加警告
    for (final warning in warnings) {
      buffer.writeln('⚠️  WARNING: ${warning.message}');
      if (warning.file != null) {
        buffer.writeln(
          '   📁 ${warning.file}'
          '${warning.line != null ? ':${warning.line}' : ''}',
        );
      }
    }

    // 添加成功信息（如果需要）
    if (includeSuccesses) {
      for (final success in successes) {
        buffer.writeln('✅ SUCCESS: ${success.message}');
      }
    }

    // 添加总结
    final summary = getSummary();
    buffer
      ..writeln('\n📊 验证总结:')
      ..writeln('   状态: ${isValid ? '✅ 通过' : '❌ 失败'}')
      ..writeln('   错误: ${summary.errorCount}')
      ..writeln('   警告: ${summary.warningCount}');
    if (summary.durationMs > 0) {
      buffer.writeln('   耗时: ${summary.durationMs}ms');
    }

    return buffer.toString();
  }

  /// 格式化JSON输出
  String _formatJsonOutput() {
    final data = {
      'isValid': isValid,
      'summary': {
        'errorCount': errors.length,
        'warningCount': warnings.length,
        'infoCount': infos.length,
        'successCount': successes.length,
        'durationMs': durationMs ?? 0,
      },
      'messages': messages
          .map(
            (m) => {
              'severity': m.severity.name,
              'type': m.validationType.name,
              'message': m.message,
              'code': m.code,
              'file': m.file,
              'line': m.line,
              'validator': m.validatorName,
              'fixSuggestion': m.fixSuggestion != null
                  ? {
                      'description': m.fixSuggestion!.description,
                      'fixabilityLevel': m.fixSuggestion!.fixabilityLevel.name,
                      'command': m.fixSuggestion!.command,
                      'codeExample': m.fixSuggestion!.codeExample,
                      'documentation': m.fixSuggestion!.documentation,
                    }
                  : null,
              'timestamp': m.timestamp.toIso8601String(),
            },
          )
          .toList(),
    };

    // 简单的JSON序列化（避免引入json包依赖）
    return _simpleJsonEncode(data);
  }

  /// 格式化JUnit XML输出
  String _formatJUnitOutput() {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<testsuite name="ValidationResult" '
          'tests="${messages.length}" '
          'failures="${errors.length}" '
          'errors="0" '
          'time="${(durationMs ?? 0) / 1000}">');

    for (final message in messages) {
      buffer.writeln('  <testcase classname="${message.validationType.name}" '
          'name="${message.validatorName ?? 'unknown'}" '
          'time="0">');

      if (message.severity == ValidationSeverity.error) {
        buffer.writeln(
            '    <failure type="${message.code ?? 'validation_error'}" '
            'message="${_escapeXml(message.message)}">');
        if (message.file != null) {
          buffer.writeln('      File: ${message.file}');
          if (message.line != null) {
            buffer.writeln('      Line: ${message.line}');
          }
        }
        buffer.writeln('    </failure>');
      } else if (message.severity == ValidationSeverity.warning) {
        buffer.writeln(
          '    <system-out>${_escapeXml(message.message)}</system-out>',
        );
      }

      buffer.writeln('  </testcase>');
    }

    buffer.writeln('</testsuite>');
    return buffer.toString();
  }

  /// 格式化紧凑输出
  String _formatCompactOutput() {
    final summary = getSummary();
    return '${isValid ? 'PASS' : 'FAIL'}: '
        '${summary.errorCount}E, ${summary.warningCount}W, '
        '${summary.successCount}S (${summary.durationMs}ms)';
  }

  /// 简单JSON编码
  String _simpleJsonEncode(dynamic obj) {
    if (obj == null) return 'null';
    if (obj is String) return '"${obj.replaceAll('"', r'\"')}"';
    if (obj is num || obj is bool) return obj.toString();
    if (obj is List) {
      return '[${obj.map(_simpleJsonEncode).join(',')}]';
    }
    if (obj is Map) {
      final entries = obj.entries
          .map((e) => '"${e.key}":${_simpleJsonEncode(e.value)}')
          .join(',');
      return '{$entries}';
    }
    return '"$obj"';
  }

  /// XML转义
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

/// 验证消息类
class ValidationMessage {
  /// 创建验证消息实例
  ValidationMessage({
    required this.severity,
    required this.message,
    this.code,
    this.file,
    this.line,
    this.validationType = ValidationType.general,
    this.fixSuggestion,
    this.validatorName,
  }) : timestamp = DateTime.now();

  /// 严重程度
  final ValidationSeverity severity;

  /// 消息内容
  final String message;

  /// 错误代码
  final String? code;

  /// 相关文件
  final String? file;

  /// 行号
  final int? line;

  /// 验证类型
  final ValidationType validationType;

  /// 修复建议
  final FixSuggestion? fixSuggestion;

  /// 验证器名称
  final String? validatorName;

  /// 时间戳
  final DateTime timestamp;

  @override
  String toString() {
    final buffer = StringBuffer()..write('[${severity.name.toUpperCase()}]');

    if (validatorName != null) {
      buffer.write(' [$validatorName]');
    }

    buffer.write(' $message');

    if (file != null) {
      buffer.write(' ($file');
      if (line != null) buffer.write(':$line');
      buffer.write(')');
    }

    if (code != null) buffer.write(' [$code]');

    if (fixSuggestion != null) {
      buffer.write(' [Fix: ${fixSuggestion!.fixabilityLevel.name}]');
    }

    return buffer.toString();
  }
}

/// 验证消息严重程度
enum ValidationSeverity {
  /// 错误：必须修复
  error,

  /// 警告：建议修复
  warning,

  /// 信息：仅供参考
  info,

  /// 成功：验证通过
  success,
}

/// 验证类型分类
enum ValidationType {
  /// 模块结构验证
  structure,

  /// 代码质量验证
  quality,

  /// 依赖关系验证
  dependency,

  /// 平台规范验证
  compliance,

  /// 配置验证
  configuration,

  /// 通用验证
  general,
}

/// 修复能力等级
enum FixabilityLevel {
  /// 可自动修复
  automatic,

  /// 有修复建议
  suggested,

  /// 需要手动修复
  manual,

  /// 无法修复
  unfixable,
}

/// 输出格式类型
enum OutputFormat {
  /// 控制台输出
  console,

  /// JSON格式
  json,

  /// JUnit XML格式
  junit,

  /// 简洁文本
  compact,
}

/// 修复建议
class FixSuggestion {
  /// 创建修复建议实例
  const FixSuggestion({
    required this.description,
    required this.fixabilityLevel,
    this.command,
    this.codeExample,
    this.documentation,
  });

  /// 建议描述
  final String description;

  /// 修复能力等级
  final FixabilityLevel fixabilityLevel;

  /// 修复命令
  final String? command;

  /// 代码示例
  final String? codeExample;

  /// 相关文档链接
  final String? documentation;
}

/// 验证上下文
class ValidationContext {
  /// 创建验证上下文实例
  const ValidationContext({
    required this.projectPath,
    this.strictMode = false,
    this.outputFormat = OutputFormat.console,
    this.enabledValidators = const [],
    this.configPath,
    this.customRules = const {},
  });

  /// 项目路径
  final String projectPath;

  /// 严格模式
  final bool strictMode;

  /// 输出格式
  final OutputFormat outputFormat;

  /// 启用的验证器
  final List<ValidationType> enabledValidators;

  /// 配置文件路径
  final String? configPath;

  /// 自定义规则
  final Map<String, dynamic> customRules;
}

/// 验证总结信息
class ValidationSummary {
  /// 创建验证总结信息实例
  const ValidationSummary({
    required this.isValid,
    required this.errorCount,
    required this.warningCount,
    required this.infoCount,
    required this.successCount,
    required this.durationMs,
  });

  /// 是否验证通过
  final bool isValid;

  /// 错误数量
  final int errorCount;

  /// 警告数量
  final int warningCount;

  /// 信息数量
  final int infoCount;

  /// 成功数量
  final int successCount;

  /// 验证耗时（毫秒）
  final int durationMs;

  @override
  String toString() {
    return 'ValidationSummary(valid: $isValid, errors: $errorCount, '
        'warnings: $warningCount, duration: ${durationMs}ms)';
  }
}
