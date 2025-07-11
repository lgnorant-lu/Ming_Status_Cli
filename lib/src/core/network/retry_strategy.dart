/*
---------------------------------------------------------------
File name:          retry_strategy.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        重试策略 (Retry Strategy)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.5 网络通信和离线支持;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:math';

/// 重试策略类型枚举
enum RetryStrategyType {
  /// 固定间隔
  fixed,

  /// 线性退避
  linear,

  /// 指数退避
  exponential,

  /// 随机退避
  random,

  /// 自定义
  custom,
}

/// 重试条件枚举
enum RetryCondition {
  /// 网络错误
  networkError,

  /// 超时错误
  timeout,

  /// 服务器错误 (5xx)
  serverError,

  /// 限流错误 (429)
  rateLimited,

  /// 临时不可用 (503)
  serviceUnavailable,

  /// 所有错误
  allErrors,
}

/// 断路器状态枚举
enum CircuitBreakerState {
  /// 关闭 (正常)
  closed,

  /// 打开 (熔断)
  open,

  /// 半开 (试探)
  halfOpen,
}

/// 重试配置
class RetryConfig {

  const RetryConfig({
    this.maxRetries = 3,
    this.strategyType = RetryStrategyType.exponential,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.jitterFactor = 0.1,
    this.retryConditions = const {
      RetryCondition.networkError,
      RetryCondition.timeout,
      RetryCondition.serverError,
    },
    this.customRetryCondition,
  });
  /// 最大重试次数
  final int maxRetries;

  /// 重试策略类型
  final RetryStrategyType strategyType;

  /// 基础延迟时间
  final Duration baseDelay;

  /// 最大延迟时间
  final Duration maxDelay;

  /// 退避倍数 (指数退避)
  final double backoffMultiplier;

  /// 随机抖动因子
  final double jitterFactor;

  /// 重试条件
  final Set<RetryCondition> retryConditions;

  /// 自定义重试判断函数
  final bool Function(Exception)? customRetryCondition;
}

/// 断路器配置
class CircuitBreakerConfig {

  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.successThreshold = 3,
    this.timeout = const Duration(minutes: 1),
    this.monitoringWindow = 100,
    this.minimumRequests = 10,
  });
  /// 失败阈值
  final int failureThreshold;

  /// 成功阈值 (半开状态)
  final int successThreshold;

  /// 超时时间
  final Duration timeout;

  /// 监控窗口大小
  final int monitoringWindow;

  /// 最小请求数
  final int minimumRequests;
}

/// 重试统计
class RetryStats {
  /// 总重试次数
  int totalRetries = 0;

  /// 成功重试次数
  int successfulRetries = 0;

  /// 失败重试次数
  int failedRetries = 0;

  /// 平均重试次数
  double averageRetries = 0;

  /// 最大重试次数
  int maxRetriesUsed = 0;

  /// 重试延迟统计
  final List<Duration> retryDelays = [];

  /// 重试原因统计
  final Map<String, int> retryReasons = {};

  /// 重置统计
  void reset() {
    totalRetries = 0;
    successfulRetries = 0;
    failedRetries = 0;
    averageRetries = 0.0;
    maxRetriesUsed = 0;
    retryDelays.clear();
    retryReasons.clear();
  }

  /// 更新统计
  void updateStats(
      int retryCount, Duration totalDelay, String reason, bool success,) {
    totalRetries += retryCount;
    if (success) {
      successfulRetries++;
    } else {
      failedRetries++;
    }

    maxRetriesUsed = max(maxRetriesUsed, retryCount);
    retryDelays.add(totalDelay);
    retryReasons[reason] = (retryReasons[reason] ?? 0) + 1;

    // 计算平均重试次数
    final totalAttempts = successfulRetries + failedRetries;
    if (totalAttempts > 0) {
      averageRetries = totalRetries / totalAttempts;
    }
  }

  /// 获取统计摘要
  Map<String, dynamic> getSummary() {
    final totalAttempts = successfulRetries + failedRetries;
    final successRate =
        totalAttempts > 0 ? successfulRetries / totalAttempts : 0.0;

    final avgDelay = retryDelays.isNotEmpty
        ? retryDelays.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
            retryDelays.length
        : 0.0;

    return {
      'totalRetries': totalRetries,
      'successfulRetries': successfulRetries,
      'failedRetries': failedRetries,
      'successRate': successRate,
      'averageRetries': averageRetries,
      'maxRetriesUsed': maxRetriesUsed,
      'averageDelayMs': avgDelay,
      'retryReasons': Map.from(retryReasons),
    };
  }
}

/// 断路器
class CircuitBreaker {

  /// 构造函数
  CircuitBreaker(this._config);
  /// 配置
  final CircuitBreakerConfig _config;

  /// 当前状态
  CircuitBreakerState _state = CircuitBreakerState.closed;

  /// 失败计数
  int _failureCount = 0;

  /// 成功计数 (半开状态)
  int _successCount = 0;

  /// 最后失败时间
  DateTime? _lastFailureTime;

  /// 请求历史 (用于监控窗口)
  final List<bool> _requestHistory = [];

  /// 当前状态
  CircuitBreakerState get state => _state;

  /// 是否允许请求
  bool get allowRequest {
    switch (_state) {
      case CircuitBreakerState.closed:
        return true;
      case CircuitBreakerState.open:
        return _shouldAttemptReset();
      case CircuitBreakerState.halfOpen:
        return true;
    }
  }

  /// 记录成功
  void recordSuccess() {
    _resetFailureCount();
    _addToHistory(true);

    if (_state == CircuitBreakerState.halfOpen) {
      _successCount++;
      if (_successCount >= _config.successThreshold) {
        _state = CircuitBreakerState.closed;
        _successCount = 0;
      }
    }
  }

  /// 记录失败
  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    _addToHistory(false);

    if (_state == CircuitBreakerState.halfOpen) {
      _state = CircuitBreakerState.open;
      _successCount = 0;
    } else if (_state == CircuitBreakerState.closed) {
      if (_shouldTrip()) {
        _state = CircuitBreakerState.open;
      }
    }
  }

  /// 获取统计信息
  Map<String, dynamic> getStats() {
    final recentRequests = _requestHistory.length;
    final recentFailures = _requestHistory.where((success) => !success).length;
    final failureRate =
        recentRequests > 0 ? recentFailures / recentRequests : 0.0;

    return {
      'state': _state.name,
      'failureCount': _failureCount,
      'successCount': _successCount,
      'recentRequests': recentRequests,
      'recentFailures': recentFailures,
      'failureRate': failureRate,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
    };
  }

  /// 重置断路器
  void reset() {
    _state = CircuitBreakerState.closed;
    _resetFailureCount();
    _successCount = 0;
    _requestHistory.clear();
  }

  /// 是否应该尝试重置
  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;

    final timeSinceLastFailure = DateTime.now().difference(_lastFailureTime!);
    if (timeSinceLastFailure >= _config.timeout) {
      _state = CircuitBreakerState.halfOpen;
      return true;
    }

    return false;
  }

  /// 是否应该熔断
  bool _shouldTrip() {
    if (_requestHistory.length < _config.minimumRequests) {
      return false;
    }

    return _failureCount >= _config.failureThreshold;
  }

  /// 重置失败计数
  void _resetFailureCount() {
    _failureCount = 0;
    _lastFailureTime = null;
  }

  /// 添加到历史记录
  void _addToHistory(bool success) {
    _requestHistory.add(success);

    // 保持监控窗口大小
    if (_requestHistory.length > _config.monitoringWindow) {
      _requestHistory.removeAt(0);
    }
  }
}

/// 重试策略
class RetryStrategy {

  /// 构造函数
  RetryStrategy({
    RetryConfig? config,
    CircuitBreakerConfig? circuitBreakerConfig,
  })  : _config = config ?? const RetryConfig(),
        _circuitBreaker = circuitBreakerConfig != null
            ? CircuitBreaker(circuitBreakerConfig)
            : null;
  /// 重试配置
  final RetryConfig _config;

  /// 断路器
  final CircuitBreaker? _circuitBreaker;

  /// 重试统计
  final RetryStats _stats = RetryStats();

  /// 随机数生成器
  final Random _random = Random();

  /// 执行带重试的操作
  Future<T> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    final operationId =
        operationName ?? 'operation_${DateTime.now().millisecondsSinceEpoch}';

    // 检查断路器
    if (_circuitBreaker != null && !_circuitBreaker.allowRequest) {
      throw const CircuitBreakerOpenException('Circuit breaker is open');
    }

    var attemptCount = 0;
    var totalDelay = Duration.zero;
    Exception? lastException;

    while (attemptCount <= _config.maxRetries) {
      try {
        final result = await operation();

        // 记录成功
        _circuitBreaker?.recordSuccess();

        if (attemptCount > 0) {
          _stats.updateStats(attemptCount, totalDelay, 'success', true);
        }

        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attemptCount++;

        // 记录失败
        _circuitBreaker?.recordFailure();

        // 检查是否应该重试
        if (attemptCount > _config.maxRetries || !_shouldRetry(lastException)) {
          _stats.updateStats(attemptCount - 1, totalDelay,
              _getExceptionReason(lastException), false,);
          rethrow;
        }

        // 计算延迟时间
        final delay = _calculateDelay(attemptCount);
        totalDelay += delay;

        // 等待重试
        await Future.delayed(delay);
      }
    }

    // 如果到这里，说明重试次数用完了
    _stats.updateStats(_config.maxRetries, totalDelay,
        _getExceptionReason(lastException!), false,);
    throw lastException;
  }

  /// 获取重试统计
  RetryStats get stats => _stats;

  /// 获取断路器统计
  Map<String, dynamic>? getCircuitBreakerStats() {
    return _circuitBreaker?.getStats();
  }

  /// 重置统计
  void resetStats() {
    _stats.reset();
    _circuitBreaker?.reset();
  }

  /// 判断是否应该重试
  bool _shouldRetry(Exception exception) {
    // 自定义重试条件
    if (_config.customRetryCondition != null) {
      return _config.customRetryCondition!(exception);
    }

    // 根据异常类型判断
    final exceptionType = _getExceptionType(exception);
    return _config.retryConditions.contains(exceptionType) ||
        _config.retryConditions.contains(RetryCondition.allErrors);
  }

  /// 获取异常类型
  RetryCondition _getExceptionType(Exception exception) {
    final message = exception.toString().toLowerCase();

    if (message.contains('timeout')) {
      return RetryCondition.timeout;
    } else if (message.contains('network') || message.contains('connection')) {
      return RetryCondition.networkError;
    } else if (message.contains('429') || message.contains('rate limit')) {
      return RetryCondition.rateLimited;
    } else if (message.contains('503') ||
        message.contains('service unavailable')) {
      return RetryCondition.serviceUnavailable;
    } else if (message.contains('5')) {
      return RetryCondition.serverError;
    } else {
      return RetryCondition.allErrors;
    }
  }

  /// 获取异常原因
  String _getExceptionReason(Exception exception) {
    return _getExceptionType(exception).name;
  }

  /// 计算延迟时间
  Duration _calculateDelay(int attemptCount) {
    Duration delay;

    switch (_config.strategyType) {
      case RetryStrategyType.fixed:
        delay = _config.baseDelay;

      case RetryStrategyType.linear:
        delay = Duration(
          milliseconds: _config.baseDelay.inMilliseconds * attemptCount,
        );

      case RetryStrategyType.exponential:
        final exponentialDelay = _config.baseDelay.inMilliseconds *
            pow(_config.backoffMultiplier, attemptCount - 1);
        delay = Duration(milliseconds: exponentialDelay.round());

      case RetryStrategyType.random:
        final randomDelay =
            _config.baseDelay.inMilliseconds * (0.5 + _random.nextDouble());
        delay = Duration(milliseconds: randomDelay.round());

      case RetryStrategyType.custom:
        // 可以在这里实现自定义策略
        delay = _config.baseDelay;
    }

    // 应用抖动
    if (_config.jitterFactor > 0) {
      final jitter = delay.inMilliseconds *
          _config.jitterFactor *
          (_random.nextDouble() - 0.5);
      delay = Duration(milliseconds: (delay.inMilliseconds + jitter).round());
    }

    // 限制最大延迟
    if (delay > _config.maxDelay) {
      delay = _config.maxDelay;
    }

    return delay;
  }
}

/// 断路器打开异常
class CircuitBreakerOpenException implements Exception {

  const CircuitBreakerOpenException(this.message);
  final String message;

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

/// 重试工具类
class RetryUtils {
  /// 创建网络重试策略
  static RetryStrategy createNetworkRetryStrategy() {
    return RetryStrategy(
      config: const RetryConfig(
        retryConditions: {
          RetryCondition.networkError,
          RetryCondition.timeout,
          RetryCondition.serverError,
          RetryCondition.serviceUnavailable,
        },
      ),
      circuitBreakerConfig: const CircuitBreakerConfig(
        
      ),
    );
  }

  /// 创建API重试策略
  static RetryStrategy createApiRetryStrategy() {
    return RetryStrategy(
      config: const RetryConfig(
        maxRetries: 5,
        baseDelay: Duration(milliseconds: 500),
        maxDelay: Duration(seconds: 60),
        backoffMultiplier: 1.5,
        jitterFactor: 0.2,
        retryConditions: {
          RetryCondition.rateLimited,
          RetryCondition.serverError,
          RetryCondition.serviceUnavailable,
        },
      ),
      circuitBreakerConfig: const CircuitBreakerConfig(
        failureThreshold: 10,
        successThreshold: 5,
        timeout: Duration(minutes: 2),
        monitoringWindow: 200,
        minimumRequests: 20,
      ),
    );
  }

  /// 创建文件操作重试策略
  static RetryStrategy createFileRetryStrategy() {
    return RetryStrategy(
      config: const RetryConfig(
        maxRetries: 2,
        strategyType: RetryStrategyType.fixed,
        baseDelay: Duration(milliseconds: 100),
        maxDelay: Duration(seconds: 5),
        retryConditions: {
          RetryCondition.allErrors,
        },
      ),
    );
  }

  /// 执行带重试的HTTP请求
  static Future<T> executeHttpRequest<T>(
    Future<T> Function() request, {
    RetryStrategy? strategy,
    String? operationName,
  }) async {
    final retryStrategy = strategy ?? createNetworkRetryStrategy();
    return retryStrategy.execute(request, operationName: operationName);
  }

  /// 执行带重试的API调用
  static Future<T> executeApiCall<T>(
    Future<T> Function() apiCall, {
    RetryStrategy? strategy,
    String? operationName,
  }) async {
    final retryStrategy = strategy ?? createApiRetryStrategy();
    return retryStrategy.execute(apiCall, operationName: operationName);
  }

  /// 执行带重试的文件操作
  static Future<T> executeFileOperation<T>(
    Future<T> Function() fileOperation, {
    RetryStrategy? strategy,
    String? operationName,
  }) async {
    final retryStrategy = strategy ?? createFileRetryStrategy();
    return retryStrategy.execute(fileOperation,
        operationName: operationName,);
  }
}
