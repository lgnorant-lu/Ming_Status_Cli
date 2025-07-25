/*
---------------------------------------------------------------
File name:          {{plugin_name.snakeCase()}}_extensions.dart
Author:             {{author}}{{#author_email}}
Email:              {{author_email}}{{/author_email}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       {{dart_version}}
Description:        {{plugin_name.titleCase()}}插件扩展方法
---------------------------------------------------------------
Change History:
    {{generated_date}}: Initial creation - 插件扩展方法;
---------------------------------------------------------------
*/

import '../types/{{plugin_name.snakeCase()}}_types.dart';

/// String扩展方法
extension {{plugin_name.pascalCase()}}StringExtensions on String {
  /// 转换为插件状态
  {{plugin_name.pascalCase()}}State? toPluginState() {
    for (final state in {{plugin_name.pascalCase()}}State.values) {
      if (state.name == this) return state;
    }
    return null;
  }

  /// 转换为日志级别
  {{plugin_name.pascalCase()}}LogLevel? toLogLevel() {
    for (final level in {{plugin_name.pascalCase()}}LogLevel.values) {
      if (level.name == this) return level;
    }
    return null;
  }

  /// 转换为事件类型
  {{plugin_name.pascalCase()}}EventType? toEventType() {
    for (final type in {{plugin_name.pascalCase()}}EventType.values) {
      if (type.name == this) return type;
    }
    return null;
  }

  /// 验证是否为有效的插件名称
  bool get isValidPluginName {
    if (isEmpty || length > 50) return false;
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
    return regex.hasMatch(this);
  }

  /// 验证是否为有效的版本号
  bool get isValidVersion {
    if (isEmpty) return false;
    final regex = RegExp(r'^\d+\.\d+\.\d+$');
    return regex.hasMatch(this);
  }

  /// 转换为驼峰命名
  String get toCamelCase {
    if (isEmpty) return this;
    
    final words = split('_');
    if (words.length == 1) return this;
    
    final buffer = StringBuffer(words.first);
    for (int i = 1; i < words.length; i++) {
      final word = words[i];
      if (word.isNotEmpty) {
        buffer.write(word[0].toUpperCase());
        if (word.length > 1) {
          buffer.write(word.substring(1));
        }
      }
    }
    return buffer.toString();
  }

  /// 转换为帕斯卡命名
  String get toPascalCase {
    if (isEmpty) return this;
    
    final camelCase = toCamelCase;
    if (camelCase.isEmpty) return camelCase;
    
    return camelCase[0].toUpperCase() + camelCase.substring(1);
  }

  /// 转换为蛇形命名
  String get toSnakeCase {
    if (isEmpty) return this;
    
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }

  /// 转换为短横线命名
  String get toKebabCase {
    return toSnakeCase.replaceAll('_', '-');
  }

  /// 截断字符串
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// 移除所有空白字符
  String get removeAllWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// 首字母大写
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// 反转字符串
  String get reverse {
    return split('').reversed.join('');
  }
}

/// DateTime扩展方法
extension {{plugin_name.pascalCase()}}DateTimeExtensions on DateTime {
  /// 转换为友好的时间格式
  String get toFriendlyString {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 转换为ISO格式字符串
  String get toIsoString {
    return toIso8601String();
  }

  /// 转换为本地化格式
  String get toLocalizedString {
    return '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} '
           '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }

  /// 是否为今天
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// 是否为昨天
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
}

/// Duration扩展方法
extension {{plugin_name.pascalCase()}}DurationExtensions on Duration {
  /// 转换为友好的时间格式
  String get toFriendlyString {
    if (inDays > 0) {
      return '${inDays}天 ${inHours % 24}小时';
    } else if (inHours > 0) {
      return '${inHours}小时 ${inMinutes % 60}分钟';
    } else if (inMinutes > 0) {
      return '${inMinutes}分钟 ${inSeconds % 60}秒';
    } else {
      return '${inSeconds}秒';
    }
  }

  /// 转换为精确格式
  String get toPreciseString {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = (inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// 是否为短时间（小于1分钟）
  bool get isShort => inMinutes < 1;

  /// 是否为长时间（大于1小时）
  bool get isLong => inHours > 1;
}

/// Map扩展方法
extension {{plugin_name.pascalCase()}}MapExtensions on Map<String, dynamic> {
  /// 安全获取字符串值
  String? getString(String key) {
    final value = this[key];
    return value is String ? value : null;
  }

  /// 安全获取整数值
  int? getInt(String key) {
    final value = this[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 安全获取布尔值
  bool? getBool(String key) {
    final value = this[key];
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return null;
  }

  /// 安全获取双精度值
  double? getDouble(String key) {
    final value = this[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// 安全获取列表值
  List<T>? getList<T>(String key) {
    final value = this[key];
    if (value is List) {
      try {
        return value.cast<T>();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 安全获取Map值
  Map<String, dynamic>? getMap(String key) {
    final value = this[key];
    return value is Map<String, dynamic> ? value : null;
  }

  /// 深度合并Map
  Map<String, dynamic> deepMerge(Map<String, dynamic> other) {
    final result = Map<String, dynamic>.from(this);
    
    for (final entry in other.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (result.containsKey(key) && 
          result[key] is Map<String, dynamic> && 
          value is Map<String, dynamic>) {
        result[key] = (result[key] as Map<String, dynamic>).deepMerge(value);
      } else {
        result[key] = value;
      }
    }
    
    return result;
  }

  /// 移除空值
  Map<String, dynamic> removeNulls() {
    final result = <String, dynamic>{};
    
    for (final entry in entries) {
      if (entry.value != null) {
        result[entry.key] = entry.value;
      }
    }
    
    return result;
  }
}

/// List扩展方法
extension {{plugin_name.pascalCase()}}ListExtensions<T> on List<T> {
  /// 安全获取元素
  T? safeGet(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }

  /// 分块处理
  List<List<T>> chunk(int size) {
    if (size <= 0) return [this];
    
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      final end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }

  /// 去重
  List<T> unique() {
    return toSet().toList();
  }

  /// 查找第一个匹配的元素
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

/// 插件状态扩展方法
extension {{plugin_name.pascalCase()}}StateExtensions on {{plugin_name.pascalCase()}}State {
  /// 是否为活跃状态
  bool get isActive {
    return this == {{plugin_name.pascalCase()}}State.running ||
           this == {{plugin_name.pascalCase()}}State.initializing;
  }

  /// 是否为错误状态
  bool get isError {
    return this == {{plugin_name.pascalCase()}}State.error;
  }

  /// 是否为终止状态
  bool get isTerminal {
    return this == {{plugin_name.pascalCase()}}State.stopped ||
           this == {{plugin_name.pascalCase()}}State.error;
  }

  /// 转换为显示文本
  String get displayText {
    switch (this) {
      case {{plugin_name.pascalCase()}}State.uninitialized:
        return '未初始化';
      case {{plugin_name.pascalCase()}}State.initializing:
        return '初始化中';
      case {{plugin_name.pascalCase()}}State.initialized:
        return '已初始化';
      case {{plugin_name.pascalCase()}}State.running:
        return '运行中';
      case {{plugin_name.pascalCase()}}State.paused:
        return '已暂停';
      case {{plugin_name.pascalCase()}}State.stopping:
        return '停止中';
      case {{plugin_name.pascalCase()}}State.stopped:
        return '已停止';
      case {{plugin_name.pascalCase()}}State.error:
        return '错误';
    }
  }
}

/// 日志级别扩展方法
extension {{plugin_name.pascalCase()}}LogLevelExtensions on {{plugin_name.pascalCase()}}LogLevel {
  /// 获取级别权重
  int get weight {
    switch (this) {
      case {{plugin_name.pascalCase()}}LogLevel.debug:
        return 0;
      case {{plugin_name.pascalCase()}}LogLevel.info:
        return 1;
      case {{plugin_name.pascalCase()}}LogLevel.warning:
        return 2;
      case {{plugin_name.pascalCase()}}LogLevel.error:
        return 3;
      case {{plugin_name.pascalCase()}}LogLevel.fatal:
        return 4;
    }
  }

  /// 是否应该记录日志
  bool shouldLog({{plugin_name.pascalCase()}}LogLevel currentLevel) {
    return weight >= currentLevel.weight;
  }

  /// 转换为显示文本
  String get displayText {
    switch (this) {
      case {{plugin_name.pascalCase()}}LogLevel.debug:
        return '调试';
      case {{plugin_name.pascalCase()}}LogLevel.info:
        return '信息';
      case {{plugin_name.pascalCase()}}LogLevel.warning:
        return '警告';
      case {{plugin_name.pascalCase()}}LogLevel.error:
        return '错误';
      case {{plugin_name.pascalCase()}}LogLevel.fatal:
        return '严重';
    }
  }
}
