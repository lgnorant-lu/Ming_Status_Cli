/*
---------------------------------------------------------------
File name:          test_result.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        测试结果模型 (Test Result Model)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 企业级模板配置管理系统;
---------------------------------------------------------------
*/
import 'package:ming_status_cli/src/core/configuration_management/models/configuration_set.dart';

/// 测试状态枚举
enum TestStatus {
  /// 未开始
  notStarted,
  /// 运行中
  running,
  /// 成功
  success,
  /// 失败
  failed,
  /// 跳过
  skipped,
  /// 超时
  timeout,
}

/// 测试错误类型枚举
enum TestErrorType {
  /// 依赖冲突
  dependencyConflict,
  /// 版本不兼容
  versionIncompatible,
  /// 编译错误
  compilationError,
  /// 运行时错误
  runtimeError,
  /// 网络错误
  networkError,
  /// 超时错误
  timeoutError,
  /// 未知错误
  unknownError,
}

/// 测试结果模型
/// 
/// 包含配置测试的详细结果信息
class TestResult {
  
  /// 创建测试结果实例
  const TestResult({
    required this.testId,
    required this.configurationSet,
    required this.status,
    required this.startTime,
    required this.isSuccess, this.endTime,
    this.durationMs,
    this.errorMessage,
    this.errorType,
    this.stackTrace,
    this.layerResults = const {},
    this.logs = const [],
    this.metrics = const {},
    this.environment = const {},
  });
  
  /// 创建成功的测试结果
  factory TestResult.success({
    required String testId,
    required ConfigurationSet configurationSet,
    required DateTime startTime,
    DateTime? endTime,
    Map<TestLayer, bool> layerResults = const {},
    List<String> logs = const [],
    Map<String, dynamic> metrics = const {},
    Map<String, String> environment = const {},
  }) {
    final end = endTime ?? DateTime.now();
    return TestResult(
      testId: testId,
      configurationSet: configurationSet,
      status: TestStatus.success,
      startTime: startTime,
      endTime: end,
      durationMs: end.difference(startTime).inMilliseconds,
      isSuccess: true,
      layerResults: layerResults,
      logs: logs,
      metrics: metrics,
      environment: environment,
    );
  }
  
  /// 创建失败的测试结果
  factory TestResult.failure({
    required String testId,
    required ConfigurationSet configurationSet,
    required DateTime startTime,
    required String errorMessage, DateTime? endTime,
    TestErrorType? errorType,
    String? stackTrace,
    Map<TestLayer, bool> layerResults = const {},
    List<String> logs = const [],
    Map<String, dynamic> metrics = const {},
    Map<String, String> environment = const {},
  }) {
    final end = endTime ?? DateTime.now();
    return TestResult(
      testId: testId,
      configurationSet: configurationSet,
      status: TestStatus.failed,
      startTime: startTime,
      endTime: end,
      durationMs: end.difference(startTime).inMilliseconds,
      isSuccess: false,
      errorMessage: errorMessage,
      errorType: errorType,
      stackTrace: stackTrace,
      layerResults: layerResults,
      logs: logs,
      metrics: metrics,
      environment: environment,
    );
  }
  
  /// 创建跳过的测试结果
  factory TestResult.skipped({
    required String testId,
    required ConfigurationSet configurationSet,
    required DateTime startTime,
    required String reason,
    Map<String, String> environment = const {},
  }) {
    return TestResult(
      testId: testId,
      configurationSet: configurationSet,
      status: TestStatus.skipped,
      startTime: startTime,
      endTime: startTime,
      durationMs: 0,
      isSuccess: false,
      errorMessage: 'Skipped: $reason',
      environment: environment,
    );
  }
  
  /// 从JSON创建测试结果实例
  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      testId: json['testId'] as String,
      configurationSet: ConfigurationSet.fromJson(json['configurationSet'] as Map<String, dynamic>),
      status: TestStatus.values.byName(json['status'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      durationMs: json['durationMs'] as int?,
      isSuccess: json['isSuccess'] as bool,
      errorMessage: json['errorMessage'] as String?,
      errorType: json['errorType'] != null ? TestErrorType.values.byName(json['errorType'] as String) : null,
      stackTrace: json['stackTrace'] as String?,
      layerResults: _parseLayerResults(json['layerResults'] as Map<String, dynamic>?),
      logs: List<String>.from(json['logs'] as List? ?? []),
      metrics: Map<String, dynamic>.from(json['metrics'] as Map? ?? {}),
      environment: Map<String, String>.from(json['environment'] as Map? ?? {}),
    );
  }
  /// 测试ID
  final String testId;
  
  /// 被测试的配置集合
  final ConfigurationSet configurationSet;
  
  /// 测试状态
  final TestStatus status;
  
  /// 测试开始时间
  final DateTime startTime;
  
  /// 测试结束时间
  final DateTime? endTime;
  
  /// 测试持续时间（毫秒）
  final int? durationMs;
  
  /// 测试是否成功
  final bool isSuccess;
  
  /// 错误信息
  final String? errorMessage;
  
  /// 错误类型
  final TestErrorType? errorType;
  
  /// 错误堆栈
  final String? stackTrace;
  
  /// 测试层级结果
  final Map<TestLayer, bool> layerResults;
  
  /// 详细测试日志
  final List<String> logs;
  
  /// 性能指标
  final Map<String, dynamic> metrics;
  
  /// 测试环境信息
  final Map<String, String> environment;
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'configurationSet': configurationSet.toJson(),
      'status': status.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMs': durationMs,
      'isSuccess': isSuccess,
      'errorMessage': errorMessage,
      'errorType': errorType?.name,
      'stackTrace': stackTrace,
      'layerResults': _layerResultsToJson(layerResults),
      'logs': logs,
      'metrics': metrics,
      'environment': environment,
    };
  }
  
  /// 创建副本
  TestResult copyWith({
    String? testId,
    ConfigurationSet? configurationSet,
    TestStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMs,
    bool? isSuccess,
    String? errorMessage,
    TestErrorType? errorType,
    String? stackTrace,
    Map<TestLayer, bool>? layerResults,
    List<String>? logs,
    Map<String, dynamic>? metrics,
    Map<String, String>? environment,
  }) {
    return TestResult(
      testId: testId ?? this.testId,
      configurationSet: configurationSet ?? this.configurationSet,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMs: durationMs ?? this.durationMs,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      errorType: errorType ?? this.errorType,
      stackTrace: stackTrace ?? this.stackTrace,
      layerResults: layerResults ?? this.layerResults,
      logs: logs ?? this.logs,
      metrics: metrics ?? this.metrics,
      environment: environment ?? this.environment,
    );
  }
  
  /// 添加日志
  TestResult addLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';
    return copyWith(logs: [...logs, logEntry]);
  }
  
  /// 添加指标
  TestResult addMetric(String key, dynamic value) {
    final newMetrics = Map<String, dynamic>.from(metrics);
    newMetrics[key] = value;
    return copyWith(metrics: newMetrics);
  }
  
  /// 设置层级测试结果
  TestResult setLayerResult(TestLayer layer, bool success) {
    final newLayerResults = Map<TestLayer, bool>.from(layerResults);
    newLayerResults[layer] = success;
    return copyWith(layerResults: newLayerResults);
  }
  
  /// 获取测试持续时间（秒）
  double? get durationSeconds {
    return durationMs != null ? durationMs! / 1000.0 : null;
  }
  
  /// 获取成功的层级数量
  int get successfulLayers {
    return layerResults.values.where((success) => success).length;
  }
  
  /// 获取失败的层级数量
  int get failedLayers {
    return layerResults.values.where((success) => !success).length;
  }
  
  /// 获取层级成功率
  double get layerSuccessRate {
    if (layerResults.isEmpty) return 0;
    return successfulLayers / layerResults.length;
  }
  
  /// 是否为部分成功
  bool get isPartialSuccess {
    return !isSuccess && successfulLayers > 0;
  }
  
  /// 获取错误摘要
  String get errorSummary {
    if (isSuccess) return 'Success';
    if (errorMessage != null) return errorMessage!;
    if (errorType != null) return errorType!.name;
    return 'Unknown error';
  }
  
  /// 生成测试报告
  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Test Result Report ===');
    buffer.writeln('Test ID: $testId');
    buffer.writeln('Configuration: ${configurationSet.name}');
    buffer.writeln('Status: ${status.name}');
    buffer.writeln('Success: $isSuccess');
    buffer.writeln('Duration: ${durationSeconds?.toStringAsFixed(2)}s');
    
    if (layerResults.isNotEmpty) {
      buffer.writeln('\nLayer Results:');
      for (final entry in layerResults.entries) {
        final status = entry.value ? '✅' : '❌';
        buffer.writeln('  ${entry.key.name}: $status');
      }
    }
    
    if (!isSuccess && errorMessage != null) {
      buffer.writeln('\nError: $errorMessage');
    }
    
    if (logs.isNotEmpty) {
      buffer.writeln('\nLogs:');
      for (final log in logs.take(10)) { // 只显示前10条日志
        buffer.writeln('  $log');
      }
      if (logs.length > 10) {
        buffer.writeln('  ... and ${logs.length - 10} more logs');
      }
    }
    
    return buffer.toString();
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestResult && other.testId == testId;
  }
  
  @override
  int get hashCode => testId.hashCode;
  
  @override
  String toString() {
    return 'TestResult(testId: $testId, status: ${status.name}, '
           'isSuccess: $isSuccess, duration: ${durationSeconds}s)';
  }
  
  /// 解析层级结果
  static Map<TestLayer, bool> _parseLayerResults(Map<String, dynamic>? json) {
    if (json == null) return {};
    
    return json.map((key, value) {
      return MapEntry(TestLayer.values.byName(key), value as bool);
    });
  }
  
  /// 层级结果转JSON
  static Map<String, bool> _layerResultsToJson(Map<TestLayer, bool> layerResults) {
    return layerResults.map((key, value) {
      return MapEntry(key.name, value);
    });
  }
}
