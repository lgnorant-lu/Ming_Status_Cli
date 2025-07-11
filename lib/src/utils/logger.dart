/*
---------------------------------------------------------------
File name:          logger.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        彩色日志工具类 (Colored logging utility)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 基础日志功能实现;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ansi_styles/ansi_styles.dart';

/// 日志级别枚举
/// 包含调试、信息、成功、警告和错误级别
enum LogLevel {
  /// 调试信息 - 灰色
  debug,

  /// 一般信息 - 蓝色
  info,

  /// 成功信息 - 绿色
  success,

  /// 警告信息 - 黄色
  warning,

  /// 错误信息 - 红色
  error,
}

/// 彩色日志工具类
/// 提供统一的日志输出接口，支持颜色和格式化
/// 包含调试、信息、成功、警告和错误级别
class Logger {
  /// 是否启用彩色输出（自动检测终端支持）
  /// 如果终端支持ANSI转义序列，则返回true
  static bool get _supportsColor => stdout.supportsAnsiEscapes;

  /// 是否启用详细模式
  /// 如果为true，则输出详细信息
  static bool verbose = false;

  /// 最小日志级别
  /// 默认情况下，只输出info级别及以上的日志
  static LogLevel minLevel = LogLevel.info;

  /// 输出调试信息
  /// 输出调试信息，通常用于开发和调试阶段
  static void debug(String message, {String? prefix}) {
    _log(LogLevel.debug, message, prefix: prefix);
  }

  /// 输出一般信息
  /// 输出一般信息，通常用于正常运行时的状态报告
  static void info(String message, {String? prefix}) {
    _log(LogLevel.info, message, prefix: prefix);
  }

  /// 输出成功信息
  /// 输出成功信息，通常用于表示操作成功
  static void success(String message, {String? prefix}) {
    _log(LogLevel.success, message, prefix: prefix);
  }

  /// 输出警告信息
  /// 输出警告信息，通常用于表示操作可能存在问题
  static void warning(String message, {String? prefix}) {
    _log(LogLevel.warning, message, prefix: prefix);
  }

  /// 输出错误信息
  /// 输出错误信息，通常用于表示操作失败
  static void error(String message, {String? prefix, Object? error}) {
    _log(LogLevel.error, message, prefix: prefix);
    if (error != null && verbose) {
      _log(LogLevel.error, 'Error details: $error');
    }
  }

  /// 输出进度信息
  /// 输出进度信息，通常用于表示操作正在进行
  static void progress(String message, {bool newLine = true}) {
    if (_shouldLog(LogLevel.info)) {
      final styled =
          _supportsColor ? AnsiStyles.blue('⏳ $message') : '⏳ $message';

      if (newLine) {
        stdout.writeln(styled);
      } else {
        stdout.write('\r$styled');
      }
    }
  }

  /// 输出完成信息
  /// 输出完成信息，通常用于表示操作完成
  static void complete(String message) {
    if (_shouldLog(LogLevel.success)) {
      final styled =
          _supportsColor ? AnsiStyles.green('✅ $message') : '✅ $message';
      stdout.writeln(styled);
    }
  }

  /// 输出分隔线
  static void separator({String char = '-', int length = 50}) {
    if (_shouldLog(LogLevel.info)) {
      stdout.writeln(char * length);
    }
  }

  /// 输出标题
  static void title(String title) {
    if (_shouldLog(LogLevel.info)) {
      separator();
      final styled = _supportsColor
          ? AnsiStyles.bold(AnsiStyles.cyan('🎯 $title'))
          : '🎯 $title';
      stdout.writeln(styled);
      separator();
    }
  }

  /// 输出子标题
  static void subtitle(String subtitle) {
    if (_shouldLog(LogLevel.info)) {
      final styled = _supportsColor
          ? AnsiStyles.bold(AnsiStyles.blue('📋 $subtitle'))
          : '📋 $subtitle';
      stdout.writeln(styled);
    }
  }

  /// 输出列表项
  static void listItem(String item, {int indent = 0}) {
    if (_shouldLog(LogLevel.info)) {
      final prefix = '  ' * indent + '• ';
      stdout.writeln('$prefix$item');
    }
  }

  /// 输出键值对
  static void keyValue(String key, String value, {int indent = 0}) {
    if (_shouldLog(LogLevel.info)) {
      final prefix = '  ' * indent;
      final styled = _supportsColor
          ? '$prefix${AnsiStyles.cyan(key)}: $value'
          : '$prefix$key: $value';
      stdout.writeln(styled);
    }
  }

  /// 输出空行
  static void newLine() {
    if (_shouldLog(LogLevel.info)) {
      stdout.writeln();
    }
  }

  /// 输出结构化错误信息
  static void structuredError({
    required String title,
    required String description,
    String? context,
    List<String>? suggestions,
    String? docLink,
    Object? technicalDetails,
  }) {
    if (!_shouldLog(LogLevel.error)) return;

    // 错误标题
    final styledTitle = _supportsColor
        ? AnsiStyles.red(AnsiStyles.bold('❌ $title'))
        : '❌ $title';
    stderr.writeln(styledTitle);

    // 错误描述
    final styledDesc =
        _supportsColor ? AnsiStyles.red('   $description') : '   $description';
    stderr.writeln(styledDesc);

    // 上下文信息
    if (context != null && context.isNotEmpty) {
      stderr.writeln();
      final styledContext = _supportsColor
          ? AnsiStyles.gray('   📍 上下文: $context')
          : '   📍 上下文: $context';
      stderr.writeln(styledContext);
    }

    // 建议解决方案
    if (suggestions != null && suggestions.isNotEmpty) {
      stderr.writeln();
      final suggestionHeader = _supportsColor
          ? AnsiStyles.yellow(AnsiStyles.bold('   💡 建议解决方案:'))
          : '   💡 建议解决方案:';
      stderr.writeln(suggestionHeader);

      for (var i = 0; i < suggestions.length; i++) {
        final suggestion = suggestions[i];
        final styledSuggestion = _supportsColor
            ? AnsiStyles.yellow('      ${i + 1}. $suggestion')
            : '      ${i + 1}. $suggestion';
        stderr.writeln(styledSuggestion);
      }
    }

    // 文档链接
    if (docLink != null && docLink.isNotEmpty) {
      stderr.writeln();
      final styledLink = _supportsColor
          ? AnsiStyles.blue('   📚 相关文档: $docLink')
          : '   📚 相关文档: $docLink';
      stderr.writeln(styledLink);
    }

    // 技术详情（仅在详细模式下显示）
    if (technicalDetails != null && verbose) {
      stderr.writeln();
      final styledDetails = _supportsColor
          ? AnsiStyles.gray('   🔧 技术详情: $technicalDetails')
          : '   🔧 技术详情: $technicalDetails';
      stderr.writeln(styledDetails);
    }

    stderr.writeln(); // 空行分隔
  }

  /// 输出结构化警告信息
  static void structuredWarning({
    required String title,
    required String description,
    String? context,
    List<String>? suggestions,
    String? docLink,
  }) {
    if (!_shouldLog(LogLevel.warning)) return;

    // 警告标题
    final styledTitle = _supportsColor
        ? AnsiStyles.yellow(AnsiStyles.bold('⚠️  $title'))
        : '⚠️  $title';
    stdout.writeln(styledTitle);

    // 警告描述
    final styledDesc = _supportsColor
        ? AnsiStyles.yellow('   $description')
        : '   $description';
    stdout.writeln(styledDesc);

    // 上下文信息
    if (context != null && context.isNotEmpty) {
      stdout.writeln();
      final styledContext = _supportsColor
          ? AnsiStyles.gray('   📍 上下文: $context')
          : '   📍 上下文: $context';
      stdout.writeln(styledContext);
    }

    // 建议
    if (suggestions != null && suggestions.isNotEmpty) {
      stdout.writeln();
      final suggestionHeader = _supportsColor
          ? AnsiStyles.cyan(AnsiStyles.bold('   💡 建议:'))
          : '   💡 建议:';
      stdout.writeln(suggestionHeader);

      for (var i = 0; i < suggestions.length; i++) {
        final suggestion = suggestions[i];
        final styledSuggestion = _supportsColor
            ? AnsiStyles.cyan('      ${i + 1}. $suggestion')
            : '      ${i + 1}. $suggestion';
        stdout.writeln(styledSuggestion);
      }
    }

    // 文档链接
    if (docLink != null && docLink.isNotEmpty) {
      stdout.writeln();
      final styledLink = _supportsColor
          ? AnsiStyles.blue('   📚 相关文档: $docLink')
          : '   📚 相关文档: $docLink';
      stdout.writeln(styledLink);
    }

    stdout.writeln(); // 空行分隔
  }

  /// 输出使用提示
  static void usageTip(String command, String description, {String? example}) {
    if (!_shouldLog(LogLevel.info)) return;

    final styledCmd =
        _supportsColor ? AnsiStyles.green(AnsiStyles.bold(command)) : command;

    stdout.writeln('💬 $styledCmd - $description');

    if (example != null) {
      final styledExample = _supportsColor
          ? AnsiStyles.gray('   示例: $example')
          : '   示例: $example';
      stdout.writeln(styledExample);
    }
  }

  /// 内部日志方法
  static void _log(LogLevel level, String message, {String? prefix}) {
    if (!_shouldLog(level)) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final levelIcon = _getLevelIcon(level);
    final formattedMessage = prefix != null ? '[$prefix] $message' : message;

    String output;
    if (verbose) {
      output = '[$timestamp] $levelIcon $formattedMessage';
    } else {
      output = '$levelIcon $formattedMessage';
    }

    if (_supportsColor) {
      output = _stylize(level, output);
    }

    // 错误输出到stderr，其他输出到stdout
    if (level == LogLevel.error) {
      stderr.writeln(output);
    } else {
      stdout.writeln(output);
    }
  }

  /// 检查是否应该输出日志
  static bool _shouldLog(LogLevel level) {
    return level.index >= minLevel.index;
  }

  /// 获取日志级别图标
  static String _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️ ';
      case LogLevel.success:
        return '✅';
      case LogLevel.warning:
        return '⚠️ ';
      case LogLevel.error:
        return '❌';
    }
  }

  /// 应用颜色样式
  static String _stylize(LogLevel level, String text) {
    switch (level) {
      case LogLevel.debug:
        return AnsiStyles.gray(text);
      case LogLevel.info:
        return AnsiStyles.blue(text);
      case LogLevel.success:
        return AnsiStyles.green(text);
      case LogLevel.warning:
        return AnsiStyles.yellow(text);
      case LogLevel.error:
        return AnsiStyles.red(text);
    }
  }
}
