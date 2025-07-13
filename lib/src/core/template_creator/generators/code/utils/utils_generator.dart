/*
---------------------------------------------------------------
File name:          utils_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        工具类Utils文件生成器
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 工具类Utils文件生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/base/base_code_generator.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 工具类Utils文件生成器
///
/// 生成常用工具类和辅助函数
class UtilsGenerator extends BaseCodeGenerator {
  /// 创建Utils生成器实例
  const UtilsGenerator();

  @override
  String getFileName(ScaffoldConfig config) {
    return '${config.templateName}_utils.dart';
  }

  @override
  String getRelativePath(ScaffoldConfig config) {
    return 'lib/src/utils';
  }

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();
    
    // 添加文件头部注释
    buffer.write(generateFileHeader(
      getFileName(config),
      config,
      '${config.templateName}工具类和辅助函数',
    ),);

    final imports = _getImports(config);
    buffer.write(generateImports(imports));
    
    // 生成验证器类
    _generateValidatorClass(buffer, config);
    
    // 生成格式化器类
    _generateFormatterClass(buffer, config);
    
    // 生成辅助函数类
    _generateHelperClass(buffer, config);
    
    // 生成扩展方法
    _generateExtensions(buffer, config);

    return buffer.toString();
  }

  /// 获取导入
  List<String> _getImports(ScaffoldConfig config) {
    final imports = <String>[
      'dart:convert',
      'dart:math',
    ];
    
    if (config.complexity != TemplateComplexity.simple) {
      imports.addAll([
        'dart:io',
        'package:crypto/crypto.dart',
      ]);
    }
    
    if (config.framework == TemplateFramework.flutter) {
      imports.addAll([
        'package:flutter/material.dart',
        'package:flutter/services.dart',
      ]);
    }
    
    return imports;
  }

  /// 生成验证器类
  void _generateValidatorClass(StringBuffer buffer, ScaffoldConfig config) {
    final className = '${_getCapitalizedName(config)}Validator';
    
    buffer.write(generateClassDocumentation(
      className,
      '${config.templateName}数据验证器',
      examples: [
        '$className.isValidEmail("test@example.com")',
        '$className.isValidPassword("password123")',
        '$className.validateRequired("value", "字段名")',
      ],
    ),);

    buffer.writeln('class $className {');
    buffer.writeln('  /// 私有构造函数，防止实例化');
    buffer.writeln('  $className._();');
    buffer.writeln();
    
    // 邮箱验证
    buffer.writeln('  /// 验证邮箱格式');
    buffer.writeln('  static bool isValidEmail(String email) {');
    buffer.writeln('    final emailRegex = RegExp(');
    buffer.writeln(r"      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',");
    buffer.writeln('    );');
    buffer.writeln('    return emailRegex.hasMatch(email);');
    buffer.writeln('  }');
    buffer.writeln();
    
    // 密码验证
    buffer.writeln('  /// 验证密码强度');
    buffer.writeln('  static bool isValidPassword(String password, {int minLength = 8}) {');
    buffer.writeln('    if (password.length < minLength) return false;');
    buffer.writeln('    ');
    buffer.writeln('    // 至少包含一个数字和一个字母');
    buffer.writeln("    final hasNumber = RegExp(r'[0-9]').hasMatch(password);");
    buffer.writeln("    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);");
    buffer.writeln('    ');
    buffer.writeln('    return hasNumber && hasLetter;');
    buffer.writeln('  }');
    buffer.writeln();
    
    // 必填验证
    buffer.writeln('  /// 验证必填字段');
    buffer.writeln('  static String? validateRequired(String? value, String fieldName) {');
    buffer.writeln('    if (value == null || value.trim().isEmpty) {');
    buffer.writeln(r"      return '$fieldName不能为空';");
    buffer.writeln('    }');
    buffer.writeln('    return null;');
    buffer.writeln('  }');
    buffer.writeln();
    
    // 长度验证
    buffer.writeln('  /// 验证字符串长度');
    buffer.writeln('  static String? validateLength(');
    buffer.writeln('    String? value,');
    buffer.writeln('    String fieldName, {');
    buffer.writeln('    int? minLength,');
    buffer.writeln('    int? maxLength,');
    buffer.writeln('  }) {');
    buffer.writeln('    if (value == null) return null;');
    buffer.writeln('    ');
    buffer.writeln('    if (minLength != null && value.length < minLength) {');
    buffer.writeln(r"      return '$fieldName长度不能少于$minLength个字符';");
    buffer.writeln('    }');
    buffer.writeln('    ');
    buffer.writeln('    if (maxLength != null && value.length > maxLength) {');
    buffer.writeln(r"      return '$fieldName长度不能超过$maxLength个字符';");
    buffer.writeln('    }');
    buffer.writeln('    ');
    buffer.writeln('    return null;');
    buffer.writeln('  }');
    buffer.writeln();
    
    if (config.complexity != TemplateComplexity.simple) {
      // URL验证
      buffer.writeln('  /// 验证URL格式');
      buffer.writeln('  static bool isValidUrl(String url) {');
      buffer.writeln('    try {');
      buffer.writeln('      final uri = Uri.parse(url);');
      buffer.writeln('      return uri.hasScheme && uri.hasAuthority;');
      buffer.writeln('    } catch (e) {');
      buffer.writeln('      return false;');
      buffer.writeln('    }');
      buffer.writeln('  }');
      buffer.writeln();
      
      // 手机号验证
      buffer.writeln('  /// 验证手机号格式（中国大陆）');
      buffer.writeln('  static bool isValidPhoneNumber(String phone) {');
      buffer.writeln(r"    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');");
      buffer.writeln('    return phoneRegex.hasMatch(phone);');
      buffer.writeln('  }');
      buffer.writeln();
    }
    
    buffer.writeln('}');
    buffer.writeln();
  }

  /// 生成格式化器类
  void _generateFormatterClass(StringBuffer buffer, ScaffoldConfig config) {
    final className = '${_getCapitalizedName(config)}Formatter';
    
    buffer.write(generateClassDocumentation(
      className,
      '${config.templateName}数据格式化器',
      examples: [
        '$className.formatDate(DateTime.now())',
        '$className.formatFileSize(1024)',
        '$className.formatCurrency(99.99)',
      ],
    ),);

    buffer.writeln('class $className {');
    buffer.writeln('  /// 私有构造函数，防止实例化');
    buffer.writeln('  $className._();');
    buffer.writeln();
    
    // 日期格式化
    buffer.writeln('  /// 格式化日期');
    buffer.writeln("  static String formatDate(DateTime date, {String pattern = 'yyyy-MM-dd'}) {");
    buffer.writeln('    switch (pattern) {');
    buffer.writeln("      case 'yyyy-MM-dd':");
    buffer.writeln(r"        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';");
    buffer.writeln("      case 'yyyy-MM-dd HH:mm:ss':");
    buffer.writeln(r"        return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';");
    buffer.writeln("      case 'MM/dd/yyyy':");
    buffer.writeln(r"        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';");
    buffer.writeln('      default:');
    buffer.writeln('        return date.toIso8601String();');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
    
    // 文件大小格式化
    buffer.writeln('  /// 格式化文件大小');
    buffer.writeln('  static String formatFileSize(int bytes) {');
    buffer.writeln(r"    if (bytes < 1024) return '$bytes B';");
    buffer.writeln(r"    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';");
    buffer.writeln(r"    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';");
    buffer.writeln(r"    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';");
    buffer.writeln('  }');
    buffer.writeln();
    
    // 货币格式化
    buffer.writeln('  /// 格式化货币');
    buffer.writeln("  static String formatCurrency(double amount, {String symbol = '¥'}) {");
    buffer.writeln(r"    return '$symbol${amount.toStringAsFixed(2)}';");
    buffer.writeln('  }');
    buffer.writeln();
    
    // 数字格式化
    buffer.writeln('  /// 格式化数字（添加千分位分隔符）');
    buffer.writeln('  static String formatNumber(num number) {');
    buffer.writeln("    final parts = number.toString().split('.');");
    buffer.writeln('    final integerPart = parts[0];');
    buffer.writeln(r"    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';");
    buffer.writeln('    ');
    buffer.writeln('    final formatted = integerPart.replaceAllMapped(');
    buffer.writeln(r"      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),");
    buffer.writeln(r"      (match) => '${match[1]},',");
    buffer.writeln('    );');
    buffer.writeln('    ');
    buffer.writeln('    return formatted + decimalPart;');
    buffer.writeln('  }');
    buffer.writeln();
    
    if (config.complexity != TemplateComplexity.simple) {
      // 相对时间格式化
      buffer.writeln('  /// 格式化相对时间');
      buffer.writeln('  static String formatRelativeTime(DateTime dateTime) {');
      buffer.writeln('    final now = DateTime.now();');
      buffer.writeln('    final difference = now.difference(dateTime);');
      buffer.writeln('    ');
      buffer.writeln('    if (difference.inDays > 0) {');
      buffer.writeln(r"      return '${difference.inDays}天前';");
      buffer.writeln('    } else if (difference.inHours > 0) {');
      buffer.writeln(r"      return '${difference.inHours}小时前';");
      buffer.writeln('    } else if (difference.inMinutes > 0) {');
      buffer.writeln(r"      return '${difference.inMinutes}分钟前';");
      buffer.writeln('    } else {');
      buffer.writeln("      return '刚刚';");
      buffer.writeln('    }');
      buffer.writeln('  }');
      buffer.writeln();
    }
    
    buffer.writeln('}');
    buffer.writeln();
  }

  /// 生成辅助函数类
  void _generateHelperClass(StringBuffer buffer, ScaffoldConfig config) {
    final className = '${_getCapitalizedName(config)}Helper';
    
    buffer.write(generateClassDocumentation(
      className,
      '${config.templateName}辅助函数集合',
      examples: [
        '$className.generateId()',
        '$className.debounce(() => print("执行"), Duration(seconds: 1))',
        '$className.retry(() async => await someOperation(), maxAttempts: 3)',
      ],
    ),);

    buffer.writeln('class $className {');
    buffer.writeln('  /// 私有构造函数，防止实例化');
    buffer.writeln('  $className._();');
    buffer.writeln();
    
    // ID生成
    buffer.writeln('  /// 生成唯一ID');
    buffer.writeln('  static String generateId() {');
    buffer.writeln('    final timestamp = DateTime.now().millisecondsSinceEpoch;');
    buffer.writeln('    final random = Random().nextInt(999999);');
    buffer.writeln(r"    return '$timestamp$random';");
    buffer.writeln('  }');
    buffer.writeln();
    
    if (config.complexity != TemplateComplexity.simple) {
      // UUID生成
      buffer.writeln('  /// 生成UUID');
      buffer.writeln('  static String generateUuid() {');
      buffer.writeln('    final random = Random();');
      buffer.writeln('    final bytes = List<int>.generate(16, (i) => random.nextInt(256));');
      buffer.writeln('    ');
      buffer.writeln('    // 设置版本号和变体');
      buffer.writeln('    bytes[6] = (bytes[6] & 0x0f) | 0x40; // 版本4');
      buffer.writeln('    bytes[8] = (bytes[8] & 0x3f) | 0x80; // 变体');
      buffer.writeln('    ');
      buffer.writeln("    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();");
      buffer.writeln(r"    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';");
      buffer.writeln('  }');
      buffer.writeln();
      
      // 防抖函数
      buffer.writeln('  /// 防抖函数');
      buffer.writeln('  static Timer? _debounceTimer;');
      buffer.writeln('  static void debounce(VoidCallback callback, Duration duration) {');
      buffer.writeln('    _debounceTimer?.cancel();');
      buffer.writeln('    _debounceTimer = Timer(duration, callback);');
      buffer.writeln('  }');
      buffer.writeln();
      
      // 重试函数
      buffer.writeln('  /// 重试函数');
      buffer.writeln('  static Future<T> retry<T>(');
      buffer.writeln('    Future<T> Function() operation, {');
      buffer.writeln('    int maxAttempts = 3,');
      buffer.writeln('    Duration delay = const Duration(seconds: 1),');
      buffer.writeln('  }) async {');
      buffer.writeln('    for (int attempt = 1; attempt <= maxAttempts; attempt++) {');
      buffer.writeln('      try {');
      buffer.writeln('        return await operation();');
      buffer.writeln('      } catch (e) {');
      buffer.writeln('        if (attempt == maxAttempts) rethrow;');
      buffer.writeln('        await Future.delayed(delay * attempt);');
      buffer.writeln('      }');
      buffer.writeln('    }');
      buffer.writeln("    throw StateError('Unreachable code');");
      buffer.writeln('  }');
      buffer.writeln();
      
      // 深拷贝
      buffer.writeln('  /// 深拷贝Map');
      buffer.writeln('  static Map<String, dynamic> deepCopyMap(Map<String, dynamic> original) {');
      buffer.writeln('    return jsonDecode(jsonEncode(original));');
      buffer.writeln('  }');
      buffer.writeln();
    }
    
    buffer.writeln('}');
    buffer.writeln();
  }

  /// 生成扩展方法
  void _generateExtensions(StringBuffer buffer, ScaffoldConfig config) {
    // String扩展
    buffer.writeln('/// String扩展方法');
    buffer.writeln('extension ${_getCapitalizedName(config)}StringExtension on String {');
    buffer.writeln('  /// 首字母大写');
    buffer.writeln('  String get capitalize {');
    buffer.writeln('    if (isEmpty) return this;');
    buffer.writeln('    return this[0].toUpperCase() + substring(1);');
    buffer.writeln('  }');
    buffer.writeln();
    
    buffer.writeln('  /// 是否为空或只包含空白字符');
    buffer.writeln('  bool get isBlank => trim().isEmpty;');
    buffer.writeln();
    
    buffer.writeln('  /// 是否不为空且不只包含空白字符');
    buffer.writeln('  bool get isNotBlank => !isBlank;');
    buffer.writeln();
    
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('  /// 转换为驼峰命名');
      buffer.writeln('  String get toCamelCase {');
      buffer.writeln(r"    final words = split(RegExp(r'[\s_-]+'));");
      buffer.writeln('    if (words.isEmpty) return this;');
      buffer.writeln('    ');
      buffer.writeln('    final first = words.first.toLowerCase();');
      buffer.writeln('    final rest = words.skip(1).map((word) => word.capitalize);');
      buffer.writeln('    ');
      buffer.writeln('    return first + rest.join();');
      buffer.writeln('  }');
      buffer.writeln();
      
      buffer.writeln('  /// 转换为蛇形命名');
      buffer.writeln('  String get toSnakeCase {');
      buffer.writeln('    return replaceAllMapped(');
      buffer.writeln("      RegExp(r'[A-Z]'),");
      buffer.writeln(r"      (match) => '_${match.group(0)!.toLowerCase()}',");
      buffer.writeln(r"    ).replaceFirst(RegExp(r'^\_'), '');");
      buffer.writeln('  }');
      buffer.writeln();
    }
    
    buffer.writeln('}');
    buffer.writeln();
    
    // DateTime扩展
    buffer.writeln('/// DateTime扩展方法');
    buffer.writeln('extension ${_getCapitalizedName(config)}DateTimeExtension on DateTime {');
    buffer.writeln('  /// 是否为今天');
    buffer.writeln('  bool get isToday {');
    buffer.writeln('    final now = DateTime.now();');
    buffer.writeln('    return year == now.year && month == now.month && day == now.day;');
    buffer.writeln('  }');
    buffer.writeln();
    
    buffer.writeln('  /// 是否为昨天');
    buffer.writeln('  bool get isYesterday {');
    buffer.writeln('    final yesterday = DateTime.now().subtract(const Duration(days: 1));');
    buffer.writeln('    return year == yesterday.year && month == yesterday.month && day == yesterday.day;');
    buffer.writeln('  }');
    buffer.writeln();
    
    buffer.writeln('  /// 格式化为友好的时间显示');
    buffer.writeln('  String get toFriendlyString {');
    buffer.writeln(r"    if (isToday) return '今天 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';");
    buffer.writeln(r"    if (isYesterday) return '昨天 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';");
    buffer.writeln(r"    return '${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';");
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  /// 获取首字母大写的名称
  String _getCapitalizedName(ScaffoldConfig config) {
    final name = config.templateName;
    return name[0].toUpperCase() + name.substring(1);
  }
}
