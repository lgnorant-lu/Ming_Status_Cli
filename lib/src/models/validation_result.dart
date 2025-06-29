/*
---------------------------------------------------------------
File name:          validation_result.dart
Author:             Ignorant-lu
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

  /// 是否严格模式
  final bool strictMode;

  /// 验证开始时间
  final DateTime startTime;

  /// 验证结束时间
  DateTime? endTime;

  /// 验证耗时（毫秒）
  int? get durationMs => endTime?.difference(startTime).inMilliseconds;

  /// 添加错误消息
  void addError(String message, {String? code, String? file, int? line}) {
    messages.add(
      ValidationMessage(
        severity: ValidationSeverity.error,
        message: message,
        code: code,
        file: file,
        line: line,
      ),
    );
  }

  /// 添加警告消息
  void addWarning(String message, {String? code, String? file, int? line}) {
    messages.add(
      ValidationMessage(
        severity: ValidationSeverity.warning,
        message: message,
        code: code,
        file: file,
        line: line,
      ),
    );
  }

  /// 添加信息消息
  void addInfo(String message, {String? code, String? file, int? line}) {
    messages.add(
      ValidationMessage(
        severity: ValidationSeverity.info,
        message: message,
        code: code,
        file: file,
        line: line,
      ),
    );
  }

  /// 添加成功消息
  void addSuccess(String message, {String? code, String? file, int? line}) {
    messages.add(
      ValidationMessage(
        severity: ValidationSeverity.success,
        message: message,
        code: code,
        file: file,
        line: line,
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
  String formatOutput({bool includeSuccesses = false}) {
    final buffer = StringBuffer();

    // 添加错误
    for (final error in errors) {
      buffer.writeln('❌ ERROR: ${error.message}');
      if (error.file != null) {
        buffer.writeln(
            '   📁 ${error.file}${error.line != null ? ':${error.line}' : ''}');
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
            '   📁 ${warning.file}${warning.line != null ? ':${warning.line}' : ''}');
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
    buffer.writeln('\n📊 验证总结:');
    buffer.writeln('   状态: ${isValid ? '✅ 通过' : '❌ 失败'}');
    buffer.writeln('   错误: ${summary.errorCount}');
    buffer.writeln('   警告: ${summary.warningCount}');
    if (summary.durationMs > 0) {
      buffer.writeln('   耗时: ${summary.durationMs}ms');
    }

    return buffer.toString();
  }
}

/// 验证消息类
class ValidationMessage {
  ValidationMessage({
    required this.severity,
    required this.message,
    this.code,
    this.file,
    this.line,
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

  /// 时间戳
  final DateTime timestamp;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${severity.name.toUpperCase()}] $message');
    if (file != null) {
      buffer.write(' ($file');
      if (line != null) buffer.write(':$line');
      buffer.write(')');
    }
    if (code != null) buffer.write(' [$code]');
    return buffer.toString();
  }
}

/// 验证消息严重程度
enum ValidationSeverity {
  error, // 错误：必须修复
  warning, // 警告：建议修复
  info, // 信息：仅供参考
  success, // 成功：验证通过
}

/// 验证总结信息
class ValidationSummary {
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
