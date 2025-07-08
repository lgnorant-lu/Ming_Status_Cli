/*
---------------------------------------------------------------
File name:          error_recovery_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/02
Last modified:      2025/07/02
Dart Version:       3.2+
Description:        错误恢复管理器 (Error recovery manager)
---------------------------------------------------------------
Change History:
    2025/07/02: Initial creation - 错误恢复管理器功能;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_exceptions.dart';
import 'package:ming_status_cli/src/core/template_models.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 错误恢复管理器
class ErrorRecoveryManager {
  /// 创建错误恢复管理器
  ///
  /// 参数：
  /// - [templateEngine] 模板引擎实例
  ErrorRecoveryManager(this.templateEngine) {
    // 注册默认恢复策略
    _strategies.addAll([
      TemplateNotFoundRecoveryStrategy(templateEngine),
      FileSystemErrorRecoveryStrategy(),
    ]);
  }

  /// 模板引擎实例引用，用于错误恢复策略（使用动态类型避免循环依赖）
  final dynamic templateEngine;
  final List<ErrorRecoveryStrategy> _strategies = [];

  /// 注册恢复策略
  void registerStrategy(ErrorRecoveryStrategy strategy) {
    _strategies.add(strategy);
  }

  /// 尝试恢复错误
  Future<ErrorRecoveryResult> tryRecover(TemplateEngineException error) async {
    for (final strategy in _strategies) {
      if (strategy.canHandle(error.type)) {
        try {
          final result = await strategy.recover(error);
          if (result.success) {
            cli_logger.Logger.info('错误恢复成功: ${result.message}');
            return result;
          }
        } catch (e) {
          cli_logger.Logger.warning('恢复策略执行失败: $e');
        }
      }
    }

    return ErrorRecoveryResult.createFailure('无可用的恢复策略');
  }
}

/// 智能错误恢复管理器
class IntelligentErrorRecoveryManager {
  /// 创建智能错误恢复管理器实例
  IntelligentErrorRecoveryManager(this.templateEngine);

  /// 模板引擎实例引用（使用动态类型避免循环依赖）
  final dynamic templateEngine;

  /// 错误恢复历史记录
  final List<ErrorRecoveryRecord> _recoveryHistory = [];

  /// 错误模式分析器
  final ErrorPatternAnalyzer _patternAnalyzer = ErrorPatternAnalyzer();

  /// 智能错误恢复
  Future<ErrorRecoveryResult> intelligentRecover(
    TemplateEngineException error,
    HookContext? context,
  ) async {
    try {
      cli_logger.Logger.info('开始智能错误恢复: ${error.type}');

      // 1. 记录错误
      final record = ErrorRecoveryRecord(
        error: error,
        timestamp: DateTime.now(),
        context: context,
      );
      _recoveryHistory.add(record);

      // 2. 分析错误模式
      final pattern =
          await _patternAnalyzer.analyzeError(error, _recoveryHistory);

      // 3. 选择恢复策略
      final strategy = await _selectRecoveryStrategy(error, pattern, context);

      // 4. 执行恢复
      final result = await strategy.recover(error);

      // 5. 更新恢复记录
      record
        ..recoveryResult = result
        ..recoveryStrategy = strategy.runtimeType.toString();

      if (result.success) {
        cli_logger.Logger.info('智能错误恢复成功: ${result.message}');
      } else {
        cli_logger.Logger.warning('智能错误恢复失败: ${result.message}');
      }

      return result;
    } catch (e) {
      cli_logger.Logger.error('智能错误恢复过程异常', error: e);
      return ErrorRecoveryResult.createFailure('恢复过程异常: $e');
    }
  }

  /// 获取错误恢复统计
  Map<String, dynamic> getRecoveryStatistics() {
    if (_recoveryHistory.isEmpty) {
      return <String, dynamic>{
        'total_attempts': 0,
        'success_rate': 0.0,
        'common_errors': <Map<String, dynamic>>[],
        'recovery_trends': <String, dynamic>{},
      };
    }

    final totalAttempts = _recoveryHistory.length;
    final successfulRecoveries = _recoveryHistory
        .where((r) => r.recoveryResult?.success ?? false)
        .length;

    final errorTypeCounts = <String, int>{};
    final strategySuccess = <String, int>{};

    for (final record in _recoveryHistory) {
      final errorType = record.error.type.toString();
      errorTypeCounts[errorType] = (errorTypeCounts[errorType] ?? 0) + 1;

      if ((record.recoveryResult?.success ?? false) &&
          record.recoveryStrategy != null) {
        final strategy = record.recoveryStrategy!;
        strategySuccess[strategy] = (strategySuccess[strategy] ?? 0) + 1;
      }
    }

    return <String, dynamic>{
      'total_attempts': totalAttempts,
      'successful_recoveries': successfulRecoveries,
      'success_rate': successfulRecoveries / totalAttempts,
      'common_errors': errorTypeCounts.entries
          .map((e) => <String, dynamic>{'type': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count']! as int).compareTo(a['count']! as int)),
      'strategy_effectiveness': strategySuccess,
      'recent_recovery_trend': _getRecentRecoveryTrend(),
    };
  }

  /// 清理恢复历史
  void cleanupHistory({int maxRecords = 1000}) {
    if (_recoveryHistory.length > maxRecords) {
      final removeCount = _recoveryHistory.length - maxRecords;
      _recoveryHistory.removeRange(0, removeCount);
      cli_logger.Logger.debug('清理错误恢复历史: 移除了 $removeCount 条记录');
    }
  }

  // 私有方法

  /// 选择恢复策略
  Future<ErrorRecoveryStrategy> _selectRecoveryStrategy(
    TemplateEngineException error,
    ErrorPattern pattern,
    HookContext? context,
  ) async {
    // 根据错误类型和模式选择最佳策略
    switch (error.type) {
      case TemplateEngineErrorType.templateNotFound:
        return TemplateNotFoundRecoveryStrategy(templateEngine);

      case TemplateEngineErrorType.fileSystemError:
      case TemplateEngineErrorType.permissionError:
        return FileSystemErrorRecoveryStrategy();

      case TemplateEngineErrorType.invalidTemplateFormat:
      case TemplateEngineErrorType.variableValidationFailed:
      case TemplateEngineErrorType.outputPathConflict:
      case TemplateEngineErrorType.masonError:
      case TemplateEngineErrorType.hookExecutionError:
      case TemplateEngineErrorType.networkError:
      case TemplateEngineErrorType.versionCompatibilityError:
      case TemplateEngineErrorType.dependencyCompatibilityError:
      case TemplateEngineErrorType.platformCompatibilityError:
      case TemplateEngineErrorType.templateComplianceError:
      case TemplateEngineErrorType.unknown:
        return FileSystemErrorRecoveryStrategy(); // 默认策略
    }
  }

  /// 获取最近恢复趋势
  List<Map<String, dynamic>> _getRecentRecoveryTrend() {
    final recentRecords = _recoveryHistory
        .where((r) => DateTime.now().difference(r.timestamp).inDays <= 7)
        .toList();

    final dailyStats = <String, Map<String, int>>{};

    for (final record in recentRecords) {
      final day = record.timestamp.toIso8601String().substring(0, 10);
      dailyStats[day] ??= <String, int>{'attempts': 0, 'successes': 0};
      dailyStats[day]!['attempts'] = dailyStats[day]!['attempts']! + 1;

      if (record.recoveryResult?.success ?? false) {
        dailyStats[day]!['successes'] = dailyStats[day]!['successes']! + 1;
      }
    }

    return dailyStats.entries
        .map(
          (e) => <String, dynamic>{
            'date': e.key,
            'attempts': e.value['attempts'],
            'successes': e.value['successes'],
            'success_rate': e.value['attempts']! > 0
                ? e.value['successes']! / e.value['attempts']!
                : 0.0,
          },
        )
        .toList()
      ..sort((a, b) => (a['date']! as String).compareTo(b['date']! as String));
  }
}

/// 错误恢复记录
class ErrorRecoveryRecord {
  /// 创建错误恢复记录实例
  ErrorRecoveryRecord({
    required this.error,
    required this.timestamp,
    this.context,
  });

  /// 错误异常信息
  final TemplateEngineException error;

  /// 错误发生时间戳
  final DateTime timestamp;

  /// 钩子上下文（可选）
  final HookContext? context;

  /// 恢复结果（可选）
  ErrorRecoveryResult? recoveryResult;

  /// 恢复策略名称（可选）
  String? recoveryStrategy;
}

/// 错误模式分析器
class ErrorPatternAnalyzer {
  /// 分析错误模式
  Future<ErrorPattern> analyzeError(
    TemplateEngineException error,
    List<ErrorRecoveryRecord> history,
  ) async {
    final recentSimilarErrors = history
        .where((r) => r.error.type == error.type)
        .where((r) => DateTime.now().difference(r.timestamp).inMinutes <= 30)
        .toList();

    final frequency = recentSimilarErrors.length;
    final recentSuccessRate = recentSimilarErrors.isEmpty
        ? 0.0
        : recentSimilarErrors
                .where((r) => r.recoveryResult?.success ?? false)
                .length /
            recentSimilarErrors.length;

    return ErrorPattern(
      errorType: error.type,
      frequency: frequency,
      recentSuccessRate: recentSuccessRate,
      isRecurring: frequency > 2,
    );
  }
}

/// 错误模式数据类
class ErrorPattern {
  /// 创建错误模式
  const ErrorPattern({
    required this.errorType,
    required this.frequency,
    required this.recentSuccessRate,
    required this.isRecurring,
  });

  /// 错误类型
  final TemplateEngineErrorType errorType;

  /// 频率
  final int frequency;

  /// 最近成功率
  final double recentSuccessRate;

  /// 是否重复发生
  final bool isRecurring;
}
