/*
---------------------------------------------------------------
File name:          string_utils.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        字符串处理工具类 (String processing utilities)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 基础字符串处理功能;
---------------------------------------------------------------
*/

/// 字符串处理工具类
/// 提供常用的字符串操作和格式化方法
class StringUtils {
  /// 将字符串转换为 snake_case 格式
  static String toSnakeCase(String input) {
    if (input.isEmpty) return input;

    return input
        .replaceAllMapped(
            RegExp('[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceAll(RegExp('^_'), '')
        .replaceAll(RegExp('[^a-z0-9_]'), '_')
        .replaceAll(RegExp('_+'), '_')
        .toLowerCase();
  }

  /// 将字符串转换为 kebab-case 格式
  static String toKebabCase(String input) {
    return toSnakeCase(input).replaceAll('_', '-');
  }

  /// 将字符串转换为 camelCase 格式
  static String toCamelCase(String input) {
    if (input.isEmpty) return input;

    final parts = input.split(RegExp(r'[_\-\s]+'));
    if (parts.isEmpty) return input;

    final first = parts.first.toLowerCase();
    final rest = parts.skip(1).map((part) => capitalize(part.toLowerCase()));

    return first + rest.join();
  }

  /// 将字符串转换为 PascalCase 格式
  static String toPascalCase(String input) {
    if (input.isEmpty) return input;

    final parts = input.split(RegExp(r'[_\-\s]+'));
    return parts.map((part) => capitalize(part.toLowerCase())).join();
  }

  /// 首字母大写
  static String capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  /// 首字母小写
  static String uncapitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toLowerCase() + input.substring(1);
  }

  /// 检查字符串是否为空或只包含空白字符
  static bool isBlank(String? input) {
    return input == null || input.trim().isEmpty;
  }

  /// 检查字符串是否不为空且包含非空白字符
  static bool isNotBlank(String? input) {
    return !isBlank(input);
  }

  /// 移除字符串前后的空白字符，null安全
  static String? trimSafe(String? input) {
    return input?.trim();
  }

  /// 截断字符串到指定长度
  static String truncate(String input, int maxLength, {String suffix = '...'}) {
    if (input.length <= maxLength) return input;

    final truncateLength = maxLength - suffix.length;
    if (truncateLength <= 0) return suffix.substring(0, maxLength);

    return input.substring(0, truncateLength) + suffix;
  }

  /// 将字符串填充到指定长度
  static String padLeft(String input, int width, [String padding = ' ']) {
    return input.padLeft(width, padding);
  }

  /// 将字符串右填充到指定长度
  static String padRight(String input, int width, [String padding = ' ']) {
    return input.padRight(width, padding);
  }

  /// 将字符串居中填充到指定长度
  static String padCenter(String input, int width, [String padding = ' ']) {
    if (input.length >= width) return input;

    final totalPadding = width - input.length;
    final leftPadding = totalPadding ~/ 2;
    final rightPadding = totalPadding - leftPadding;

    return padding * leftPadding + input + padding * rightPadding;
  }

  /// 重复字符串指定次数
  static String repeat(String input, int count) {
    if (count <= 0) return '';
    return input * count;
  }

  /// 反转字符串
  static String reverse(String input) {
    return input.split('').reversed.join();
  }

  /// 检查字符串是否只包含字母
  static bool isAlpha(String input) {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(input);
  }

  /// 检查字符串是否只包含数字
  static bool isNumeric(String input) {
    return RegExp(r'^[0-9]+$').hasMatch(input);
  }

  /// 检查字符串是否只包含字母和数字
  static bool isAlphaNumeric(String input) {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(input);
  }

  /// 检查字符串是否是有效的标识符
  static bool isValidIdentifier(String input) {
    return RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(input);
  }

  /// 检查字符串是否是有效的包名
  static bool isValidPackageName(String input) {
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(input);
  }

  /// 检查字符串是否是有效的类名
  static bool isValidClassName(String input) {
    return RegExp(r'^[A-Z][a-zA-Z0-9_]*$').hasMatch(input);
  }

  /// 移除字符串中的所有空白字符
  static String removeWhitespace(String input) {
    return input.replaceAll(RegExp(r'\s+'), '');
  }

  /// 规范化空白字符（将多个连续空白字符替换为单个空格）
  static String normalizeWhitespace(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 计算字符串的字节长度（UTF-8）
  static int getByteLength(String input) {
    return input.codeUnits.length;
  }

  /// 安全地获取子字符串
  static String substring(String input, int start, [int? end]) {
    final length = input.length;
    final safeStart = start.clamp(0, length);
    final safeEnd = (end ?? length).clamp(safeStart, length);
    return input.substring(safeStart, safeEnd);
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];

    if (bytes == 0) return '0 B';

    final unitIndex = (bytes.bitLength - 1) ~/ 10;
    final size = bytes / (1 << (unitIndex * 10));

    if (unitIndex < units.length) {
      return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[unitIndex]}';
    } else {
      return '$bytes B';
    }
  }

  /// 格式化持续时间
  static String formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final parts = <String>[];

    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0) parts.add('${seconds}s');

    return parts.isEmpty ? '0s' : parts.join(' ');
  }

  /// 创建随机字符串
  static String randomString(int length,
      {String chars =
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'}) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final result = StringBuffer();

    for (var i = 0; i < length; i++) {
      final index = (random + i) % chars.length;
      result.write(chars[index]);
    }

    return result.toString();
  }
}
