/*
---------------------------------------------------------------
File name:          {{plugin_name.snakeCase()}}_types.dart
Author:             {{author}}{{#author_email}}
Email:              {{author_email}}{{/author_email}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       {{dart_version}}
Description:        {{plugin_name.titleCase()}}插件类型定义
---------------------------------------------------------------
Change History:
    {{generated_date}}: Initial creation - 插件类型定义;
---------------------------------------------------------------
*/

/// {{plugin_name.titleCase()}}插件类型定义
/// 
/// 定义插件使用的所有数据类型、枚举和常量

/// 插件状态枚举
enum {{plugin_name.pascalCase()}}State {
  /// 未初始化
  uninitialized,
  
  /// 初始化中
  initializing,
  
  /// 已初始化
  initialized,
  
  /// 运行中
  running,
  
  /// 暂停中
  paused,
  
  /// 停止中
  stopping,
  
  /// 已停止
  stopped,
  
  /// 错误状态
  error,
}

/// 日志级别枚举
enum {{plugin_name.pascalCase()}}LogLevel {
  /// 调试级别
  debug,
  
  /// 信息级别
  info,
  
  /// 警告级别
  warning,
  
  /// 错误级别
  error,
  
  /// 严重错误级别
  fatal,
}

/// 插件事件类型
enum {{plugin_name.pascalCase()}}EventType {
  /// 插件初始化事件
  initialized,
  
  /// 插件启动事件
  started,
  
  /// 插件暂停事件
  paused,
  
  /// 插件恢复事件
  resumed,
  
  /// 插件停止事件
  stopped,
  
  /// 插件错误事件
  error,
  
  /// 自定义事件
  custom,
}

/// 插件配置类型
class {{plugin_name.pascalCase()}}ConfigData {
  /// 创建插件配置数据实例
  const {{plugin_name.pascalCase()}}ConfigData({
    this.enabled = true,
    this.autoStart = false,
    this.debugMode = false,
    this.logLevel = {{plugin_name.pascalCase()}}LogLevel.info,
    this.maxRetries = 3,
    this.timeout = const Duration(seconds: 30),
    this.customSettings = const <String, dynamic>{},
  });

  /// 是否启用插件
  final bool enabled;
  
  /// 是否自动启动
  final bool autoStart;
  
  /// 是否启用调试模式
  final bool debugMode;
  
  /// 日志级别
  final {{plugin_name.pascalCase()}}LogLevel logLevel;
  
  /// 最大重试次数
  final int maxRetries;
  
  /// 超时时间
  final Duration timeout;
  
  /// 自定义设置
  final Map<String, dynamic> customSettings;

  /// 从Map创建配置数据
  factory {{plugin_name.pascalCase()}}ConfigData.fromMap(Map<String, dynamic> map) {
    return {{plugin_name.pascalCase()}}ConfigData(
      enabled: map['enabled'] as bool? ?? true,
      autoStart: map['autoStart'] as bool? ?? false,
      debugMode: map['debugMode'] as bool? ?? false,
      logLevel: {{plugin_name.pascalCase()}}LogLevel.values.firstWhere(
        (level) => level.name == map['logLevel'],
        orElse: () => {{plugin_name.pascalCase()}}LogLevel.info,
      ),
      maxRetries: map['maxRetries'] as int? ?? 3,
      timeout: Duration(
        milliseconds: map['timeoutMs'] as int? ?? 30000,
      ),
      customSettings: Map<String, dynamic>.from(
        map['customSettings'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'autoStart': autoStart,
      'debugMode': debugMode,
      'logLevel': logLevel.name,
      'maxRetries': maxRetries,
      'timeoutMs': timeout.inMilliseconds,
      'customSettings': customSettings,
    };
  }

  /// 复制并修改配置
  {{plugin_name.pascalCase()}}ConfigData copyWith({
    bool? enabled,
    bool? autoStart,
    bool? debugMode,
    {{plugin_name.pascalCase()}}LogLevel? logLevel,
    int? maxRetries,
    Duration? timeout,
    Map<String, dynamic>? customSettings,
  }) {
    return {{plugin_name.pascalCase()}}ConfigData(
      enabled: enabled ?? this.enabled,
      autoStart: autoStart ?? this.autoStart,
      debugMode: debugMode ?? this.debugMode,
      logLevel: logLevel ?? this.logLevel,
      maxRetries: maxRetries ?? this.maxRetries,
      timeout: timeout ?? this.timeout,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is {{plugin_name.pascalCase()}}ConfigData &&
        other.enabled == enabled &&
        other.autoStart == autoStart &&
        other.debugMode == debugMode &&
        other.logLevel == logLevel &&
        other.maxRetries == maxRetries &&
        other.timeout == timeout;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      autoStart,
      debugMode,
      logLevel,
      maxRetries,
      timeout,
    );
  }

  @override
  String toString() {
    return '{{plugin_name.pascalCase()}}ConfigData('
        'enabled: $enabled, '
        'autoStart: $autoStart, '
        'debugMode: $debugMode, '
        'logLevel: $logLevel, '
        'maxRetries: $maxRetries, '
        'timeout: $timeout)';
  }
}

/// 插件事件数据
class {{plugin_name.pascalCase()}}Event {
  /// 创建插件事件实例
  const {{plugin_name.pascalCase()}}Event({
    required this.type,
    required this.timestamp,
    this.data,
    this.message,
    this.error,
  });

  /// 事件类型
  final {{plugin_name.pascalCase()}}EventType type;
  
  /// 事件时间戳
  final DateTime timestamp;
  
  /// 事件数据
  final Map<String, dynamic>? data;
  
  /// 事件消息
  final String? message;
  
  /// 错误信息
  final Object? error;

  /// 创建初始化事件
  factory {{plugin_name.pascalCase()}}Event.initialized({String? message}) {
    return {{plugin_name.pascalCase()}}Event(
      type: {{plugin_name.pascalCase()}}EventType.initialized,
      timestamp: DateTime.now(),
      message: message,
    );
  }

  /// 创建启动事件
  factory {{plugin_name.pascalCase()}}Event.started({String? message}) {
    return {{plugin_name.pascalCase()}}Event(
      type: {{plugin_name.pascalCase()}}EventType.started,
      timestamp: DateTime.now(),
      message: message,
    );
  }

  /// 创建错误事件
  factory {{plugin_name.pascalCase()}}Event.error({
    required Object error,
    String? message,
  }) {
    return {{plugin_name.pascalCase()}}Event(
      type: {{plugin_name.pascalCase()}}EventType.error,
      timestamp: DateTime.now(),
      message: message,
      error: error,
    );
  }

  @override
  String toString() {
    return '{{plugin_name.pascalCase()}}Event('
        'type: $type, '
        'timestamp: $timestamp, '
        'message: $message)';
  }
}

/// 插件结果类型
class {{plugin_name.pascalCase()}}Result<T> {
  /// 创建插件结果实例
  const {{plugin_name.pascalCase()}}Result._({
    required this.isSuccess,
    this.data,
    this.error,
    this.message,
  });

  /// 是否成功
  final bool isSuccess;
  
  /// 结果数据
  final T? data;
  
  /// 错误信息
  final Object? error;
  
  /// 结果消息
  final String? message;

  /// 是否失败
  bool get isFailure => !isSuccess;

  /// 创建成功结果
  factory {{plugin_name.pascalCase()}}Result.success(T data, {String? message}) {
    return {{plugin_name.pascalCase()}}Result._(
      isSuccess: true,
      data: data,
      message: message,
    );
  }

  /// 创建失败结果
  factory {{plugin_name.pascalCase()}}Result.failure(Object error, {String? message}) {
    return {{plugin_name.pascalCase()}}Result._(
      isSuccess: false,
      error: error,
      message: message,
    );
  }

  @override
  String toString() {
    return '{{plugin_name.pascalCase()}}Result('
        'isSuccess: $isSuccess, '
        'data: $data, '
        'error: $error, '
        'message: $message)';
  }
}
