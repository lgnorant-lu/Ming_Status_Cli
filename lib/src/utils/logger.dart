/*
---------------------------------------------------------------
File name:          logger.dart
Author:             Ignorant-lu
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
enum LogLevel {
  debug,    // 调试信息 - 灰色
  info,     // 一般信息 - 蓝色  
  success,  // 成功信息 - 绿色
  warning,  // 警告信息 - 黄色
  error,    // 错误信息 - 红色
}

/// 彩色日志工具类
/// 提供统一的日志输出接口，支持颜色和格式化
class Logger {
  /// 是否启用彩色输出（自动检测终端支持）
  static bool get _supportsColor => stdout.supportsAnsiEscapes;
  
  /// 是否启用详细模式
  static bool verbose = false;
  
  /// 最小日志级别
  static LogLevel minLevel = LogLevel.info;

  /// 输出调试信息
  static void debug(String message, {String? prefix}) {
    _log(LogLevel.debug, message, prefix: prefix);
  }

  /// 输出一般信息
  static void info(String message, {String? prefix}) {
    _log(LogLevel.info, message, prefix: prefix);
  }

  /// 输出成功信息
  static void success(String message, {String? prefix}) {
    _log(LogLevel.success, message, prefix: prefix);
  }

  /// 输出警告信息
  static void warning(String message, {String? prefix}) {
    _log(LogLevel.warning, message, prefix: prefix);
  }

  /// 输出错误信息
  static void error(String message, {String? prefix, Object? error}) {
    _log(LogLevel.error, message, prefix: prefix);
    if (error != null && verbose) {
      _log(LogLevel.error, 'Error details: $error');
    }
  }

  /// 输出进度信息
  static void progress(String message, {bool newLine = true}) {
    if (_shouldLog(LogLevel.info)) {
      final styled = _supportsColor 
          ? AnsiStyles.blue('⏳ $message')
          : '⏳ $message';
      
      if (newLine) {
        print(styled);
      } else {
        stdout.write('\r$styled');
      }
    }
  }

  /// 输出完成信息
  static void complete(String message) {
    if (_shouldLog(LogLevel.success)) {
      final styled = _supportsColor 
          ? AnsiStyles.green('✅ $message')
          : '✅ $message';
      print(styled);
    }
  }

  /// 输出分隔线
  static void separator({String char = '-', int length = 50}) {
    if (_shouldLog(LogLevel.info)) {
      print(char * length);
    }
  }

  /// 输出标题
  static void title(String title) {
    if (_shouldLog(LogLevel.info)) {
      separator();
      final styled = _supportsColor 
          ? AnsiStyles.bold(AnsiStyles.cyan('🎯 $title'))
          : '🎯 $title';
      print(styled);
      separator();
    }
  }

  /// 输出子标题
  static void subtitle(String subtitle) {
    if (_shouldLog(LogLevel.info)) {
      final styled = _supportsColor 
          ? AnsiStyles.bold(AnsiStyles.blue('📋 $subtitle'))
          : '📋 $subtitle';
      print(styled);
    }
  }

  /// 输出列表项
  static void listItem(String item, {int indent = 0}) {
    if (_shouldLog(LogLevel.info)) {
      final prefix = '  ' * indent + '• ';
      print('$prefix$item');
    }
  }

  /// 输出键值对
  static void keyValue(String key, String value, {int indent = 0}) {
    if (_shouldLog(LogLevel.info)) {
      final prefix = '  ' * indent;
      final styled = _supportsColor 
          ? '$prefix${AnsiStyles.cyan(key)}: $value'
          : '$prefix$key: $value';
      print(styled);
    }
  }

  /// 输出空行
  static void newLine() {
    if (_shouldLog(LogLevel.info)) {
      print('');
    }
  }

  /// 内部日志方法
  static void _log(LogLevel level, String message, {String? prefix}) {
    if (!_shouldLog(level)) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final levelIcon = _getLevelIcon(level);
    final formattedMessage = prefix != null 
        ? '[$prefix] $message' 
        : message;

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
      print(output);
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