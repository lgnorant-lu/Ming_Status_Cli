/*
---------------------------------------------------------------
File name:          ux_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/02
Last modified:      2025/07/02
Dart Version:       3.2+
Description:        用户体验管理器 (User experience manager)
---------------------------------------------------------------
Change History:
    2025/07/02: Initial creation - 用户体验管理器功能;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/template_exceptions.dart';
import 'package:ming_status_cli/src/core/template_models.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

// ==================== Task 36.4: 用户体验优化和反馈改进 ====================

/// 用户体验优化管理器
class UserExperienceManager {
  UserExperienceManager(this.templateEngine);

  final dynamic templateEngine;
  
  /// 进度反馈回调
  void Function(ProgressUpdate)? onProgressUpdate;
  
  /// 用户交互历史
  final List<UserInteraction> _interactionHistory = [];
  
  /// 性能指标收集器
  final PerformanceMetricsCollector _metricsCollector = PerformanceMetricsCollector();

  /// 增强的模板生成（带用户体验优化）
  Future<GenerationResult> generateWithEnhancedUX({
    required String templateName,
    required String outputPath,
    required Map<String, dynamic> variables,
    bool overwrite = false,
    List<TemplateHook>? hooks,
    TemplateInheritance? inheritance,
  }) async {
    final interaction = UserInteraction(
      action: 'generate_template',
      templateName: templateName,
      timestamp: DateTime.now(),
    );
    _interactionHistory.add(interaction);

    try {
      // 1. 预处理和验证（带进度反馈）
      _updateProgress('正在验证模板和变量...', 0.1);
      
      final validationResult = await _validateWithFeedback(templateName, variables);
      if (!validationResult.success) {
        interaction.result = 'validation_failed';
        interaction.error = validationResult.message;
        return GenerationResult.failure(validationResult.message!, outputPath: outputPath);
      }

      // 2. 智能预处理变量
      _updateProgress('正在预处理变量...', 0.2);
      final processedVariables = await _intelligentVariableProcessing(
        templateName,
        variables,
      );

      // 3. 预估生成时间
      _updateProgress('正在分析模板复杂度...', 0.3);
      final estimatedDuration = await _estimateGenerationTime(templateName);
      _updateProgress(
        '预计生成时间: ${estimatedDuration.inMilliseconds}ms',
        0.4,
      );

      // 4. 执行生成（带详细进度）
      _updateProgress('正在生成模板...', 0.5);
      
      final stopwatch = Stopwatch()..start();
      final dynamic resultDynamic = await templateEngine.generateWithHooks(
        templateName: templateName,
        outputPath: outputPath,
        variables: processedVariables,
        overwrite: overwrite,
        additionalHooks: hooks,
        inheritance: inheritance,
      );
      final result = resultDynamic as GenerationResult;
      stopwatch.stop();

      // 5. 后处理和反馈
      final isSuccess = result.success as bool? ?? false;
      if (isSuccess) {
        _updateProgress('正在验证生成结果...', 0.8);
        await _postGenerationValidation(outputPath);
        
        _updateProgress('正在收集性能指标...', 0.9);
        await _collectPerformanceMetrics(templateName, stopwatch.elapsed);
        
        _updateProgress('生成完成!', 1);
        
        interaction.result = 'success';
        interaction.duration = stopwatch.elapsed;
        
        // 生成用户友好的成功消息
        final enhancedResult = await _enhanceSuccessResult(result, stopwatch.elapsed);
        return enhancedResult;
      } else {
        interaction.result = 'failed';
        interaction.error = result.message?.toString();
        
        // 提供智能的失败恢复建议
        final enhancedResult = await _enhanceFailureResult(result);
        return enhancedResult;
      }

    } catch (e) {
      interaction.result = 'error';
      interaction.error = e.toString();
      
      _updateProgress('生成过程中发生异常', 0);
      
      return GenerationResult.failure(
        '生成过程异常: $e',
        outputPath: outputPath,
      );
    }
  }

  /// 智能模板推荐
  Future<List<TemplateRecommendation>> getIntelligentRecommendations({
    String? context,
    Map<String, dynamic>? userPreferences,
  }) async {
    try {
      final recommendations = <TemplateRecommendation>[];
      final dynamic templatesResult = await templateEngine.getAvailableTemplates();
      final availableTemplates = (templatesResult as List<dynamic>).cast<String>();

      for (final templateName in availableTemplates) {
        final score = await _calculateRecommendationScore(
          templateName,
          context,
          userPreferences,
        );
        
        if (score > 0.3) {
          final dynamic templateInfoResult = await templateEngine.getTemplateInfo(templateName);
          final templateInfo = (templateInfoResult as Map<String, dynamic>?) ?? <String, dynamic>{};
          final recommendation = TemplateRecommendation(
            templateName: templateName,
            score: score,
            reason: await _generateRecommendationReason(templateName, score),
            metadata: templateInfo,
            estimatedComplexity: await _estimateTemplateComplexity(templateName),
          );
          recommendations.add(recommendation);
        }
      }

      // 按评分排序
      recommendations.sort((a, b) => b.score.compareTo(a.score));
      
      return recommendations.take(5).toList();

    } catch (e) {
      cli_logger.Logger.error('生成模板推荐失败', error: e);
      return [];
    }
  }

  /// 获取用户体验报告
  Map<String, dynamic> getUserExperienceReport() {
    final totalInteractions = _interactionHistory.length;
    if (totalInteractions == 0) {
      return {
        'summary': '暂无用户交互记录',
        'recommendations': ['开始使用模板引擎以获得个性化体验建议'],
      };
    }

    final successfulInteractions = _interactionHistory
        .where((i) => i.result == 'success')
        .length;
    
    final averageDuration = _interactionHistory
        .where((i) => i.duration != null)
        .map((i) => i.duration!.inMilliseconds)
        .fold(0, (a, b) => a + b) / totalInteractions;

    final commonTemplates = <String, int>{};
    for (final interaction in _interactionHistory) {
      if (interaction.templateName != null) {
        commonTemplates[interaction.templateName!] = 
            (commonTemplates[interaction.templateName!] ?? 0) + 1;
      }
    }

    final performanceReport = _metricsCollector.generateReport();

    return {
      'summary': {
        'total_interactions': totalInteractions,
        'success_rate': totalInteractions > 0 ? successfulInteractions / totalInteractions : 0.0,
        'average_duration_ms': averageDuration,
      },
      'usage_patterns': {
        'most_used_templates': commonTemplates.entries
            .map((e) => {'template': e.key, 'usage_count': e.value})
            .toList()
          ..sort((a, b) => (b['usage_count']! as int).compareTo(a['usage_count']! as int)),
        'peak_usage_hours': _analyzePeakUsageHours(),
      },
      'performance_metrics': performanceReport,
      'recommendations': _generateUXRecommendations(),
    };
  }

  /// 设置进度回调
  void setProgressCallback(void Function(ProgressUpdate) callback) {
    onProgressUpdate = callback;
  }

  // 私有方法

  /// 更新进度
  void _updateProgress(String message, double progress) {
    final update = ProgressUpdate(
      message: message,
      progress: progress,
      timestamp: DateTime.now(),
    );
    
    onProgressUpdate?.call(update);
    cli_logger.Logger.info('进度更新: $message (${(progress * 100).toStringAsFixed(1)}%)');
  }

  /// 验证并提供反馈
  Future<TemplateValidationResult> _validateWithFeedback(
    String templateName,
    Map<String, dynamic> variables,
  ) async {
    try {
      // 1. 检查模板存在性
      final dynamic availabilityResult = templateEngine.isTemplateAvailable(templateName);
      final isAvailable = availabilityResult as bool? ?? false;
      if (!isAvailable) {
        try {
          final dynamic suggestionsResult = await templateEngine.errorRecoveryManager
              .tryRecover(TemplateEngineException.templateNotFound(templateName));
          final successValue = suggestionsResult?.success as bool? ?? false;
          final messageValue = suggestionsResult?.message?.toString() ?? '';
          
          return TemplateValidationResult(
            success: false,
            message: successValue
                ? '模板不存在，建议使用: $messageValue'
                : '模板不存在: $templateName',
          );
        } catch (e) {
          return TemplateValidationResult(
            success: false,
            message: '模板不存在: $templateName',
          );
        }
      }

      // 2. 验证变量
      try {
        final dynamic validationResult = templateEngine.validateTemplateVariables(
          templateName: templateName,
          variables: variables,
        );
        final variableErrors = (validationResult as Map<String, dynamic>?) ?? <String, String>{};
        
        if (variableErrors.isNotEmpty) {
          final errorMessages = variableErrors.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(', ');
          
          return TemplateValidationResult(
            success: false,
            message: '变量验证失败: $errorMessages',
            suggestions: await _generateVariableFixSuggestions(variableErrors.cast<String, String>()),
          );
        }
      } catch (e) {
        // 验证失败时的默认处理
        return TemplateValidationResult(
          success: false,
          message: '变量验证过程出错: $e',
        );
      }

      return const TemplateValidationResult(success: true);

    } catch (e) {
      return TemplateValidationResult(
        success: false,
        message: '验证过程异常: $e',
      );
    }
  }

  /// 智能变量处理
  Future<Map<String, dynamic>> _intelligentVariableProcessing(
    String templateName,
    Map<String, dynamic> variables,
  ) async {
    try {
      // 1. 基础预处理
      final dynamic preprocessResult = templateEngine.preprocessVariables(variables);
      var processed = (preprocessResult as Map<String, dynamic>?) ?? variables;

      // 2. 智能补全缺失变量
      final dynamic templateInfoResult = await templateEngine.getTemplateInfo(templateName);
      final templateInfo = templateInfoResult as Map<String, dynamic>?;
      final hasVars = templateInfo != null && (templateInfo.containsKey('vars') as bool? ?? false);
      if (hasVars) {
        final templateVars = Map<String, dynamic>.from(templateInfo!['vars'] as Map? ?? {});
        
        for (final entry in templateVars.entries) {
          final varName = entry.key;
          final varConfig = Map<String, dynamic>.from(entry.value as Map? ?? {});
          
          final processedHasVar = processed.containsKey(varName) as bool? ?? false;
          final configHasDefault = varConfig.containsKey('default') as bool? ?? false;
          if (!processedHasVar && configHasDefault) {
            processed[varName] = varConfig['default'];
            cli_logger.Logger.debug('自动补全变量 $varName: ${varConfig['default']}');
          }
        }
      }

      // 3. 智能类型转换
      processed = await _smartTypeConversion(processed);

      return processed;

    } catch (e) {
      cli_logger.Logger.warning('智能变量处理失败，使用原始变量: $e');
      final dynamic fallbackResult = templateEngine.preprocessVariables(variables);
      return (fallbackResult as Map<String, dynamic>?) ?? variables;
    }
  }

  /// 智能类型转换
  Future<Map<String, dynamic>> _smartTypeConversion(Map<String, dynamic> variables) async {
    final converted = <String, dynamic>{};

    for (final entry in variables.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String) {
        // 尝试智能转换字符串
        if (value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
          converted[key] = value.toLowerCase() == 'true';
        } else if (RegExp(r'^\d+$').hasMatch(value)) {
          converted[key] = int.tryParse(value) ?? value;
        } else if (RegExp(r'^\d+\.\d+$').hasMatch(value)) {
          converted[key] = double.tryParse(value) ?? value;
        } else {
          converted[key] = value;
        }
      } else {
        converted[key] = value;
      }
    }

    return converted;
  }

  /// 预估生成时间
  Future<Duration> _estimateGenerationTime(String templateName) async {
    try {
      // 基于历史数据和模板复杂度估算
      final complexity = await _estimateTemplateComplexity(templateName);
      final baseTime = Duration(milliseconds: 100 + (complexity.index * 50));
      
      return baseTime;
        } catch (e) {
      return const Duration(milliseconds: 150);
    }
  }

  /// 后生成验证
  Future<void> _postGenerationValidation(String outputPath) async {
    try {
      // 验证生成的文件结构
      if (!Directory(outputPath).existsSync()) {
        throw Exception('输出目录不存在');
      }
      
      // 基本的文件完整性检查
      final files = await Directory(outputPath).list().toList();
      cli_logger.Logger.debug('生成了 ${files.length} 个文件/目录');
      
    } catch (e) {
      cli_logger.Logger.warning('后生成验证失败: $e');
    }
  }

  /// 收集性能指标
  Future<void> _collectPerformanceMetrics(String templateName, Duration duration) async {
    try {
      _metricsCollector.recordGeneration(templateName, duration);
    } catch (e) {
      cli_logger.Logger.warning('收集性能指标失败: $e');
    }
  }

  /// 增强成功结果
  Future<GenerationResult> _enhanceSuccessResult(GenerationResult result, Duration duration) async {
    try {
      final enhancedMessage = '✅ 生成成功! 耗时: ${duration.inMilliseconds}ms';
      return GenerationResult(
        success: true,
        outputPath: result.outputPath,
        generatedFiles: result.generatedFiles,
        message: enhancedMessage,
        duration: duration,
        metadata: {
          ...result.metadata,
          'enhanced': true,
          'user_friendly': true,
        },
      );
    } catch (e) {
      return result; // 返回原始结果
    }
  }

  /// 增强失败结果
  Future<GenerationResult> _enhanceFailureResult(GenerationResult result) async {
    try {
      final enhancedMessage = '❌ ${result.message}\n💡 建议: 检查模板变量和输出路径';
      return GenerationResult(
        success: false,
        outputPath: result.outputPath,
        message: enhancedMessage,
        metadata: {
          ...result.metadata,
          'enhanced': true,
          'has_suggestions': true,
        },
      );
    } catch (e) {
      return result;
    }
  }

  /// 计算推荐评分
  Future<double> _calculateRecommendationScore(
    String templateName,
    String? context,
    Map<String, dynamic>? userPreferences,
  ) async {
    try {
      var score = 0.5; // 基础分数
      
      // 基于使用历史
      final usageCount = _interactionHistory
          .where((i) => i.templateName == templateName)
          .length;
      score += (usageCount * 0.1).clamp(0.0, 0.3);
      
      // 基于成功率
      final successfulUsage = _interactionHistory
          .where((i) => i.templateName == templateName && i.result == 'success')
          .length;
      if (usageCount > 0) {
        final successRate = successfulUsage / usageCount;
        score += successRate * 0.3;
      }
      
      // 基于上下文匹配
      if (context != null && templateName.toLowerCase().contains(context.toLowerCase())) {
        score += 0.2;
      }
      
      return score.clamp(0.0, 1.0);
    } catch (e) {
      return 0.5;
    }
  }

  /// 生成推荐理由
  Future<String> _generateRecommendationReason(String templateName, double score) async {
    try {
      if (score > 0.8) return '高度推荐: 使用频率高且成功率高';
      if (score > 0.6) return '推荐: 适合当前需求';
      if (score > 0.4) return '可选: 可能符合需求';
      return '备选: 基础评分';
    } catch (e) {
      return '评分: ${score.toStringAsFixed(2)}';
    }
  }

  /// 估算模板复杂度
  Future<TemplateComplexity> _estimateTemplateComplexity(String templateName) async {
    try {
      final templateInfo = await templateEngine.getTemplateInfo(templateName);
      if (templateInfo == null) return TemplateComplexity.low;
      
      final varsCount = (templateInfo['vars'] as Map?)?.length ?? 0;
      
      if (varsCount > 10) return TemplateComplexity.high;
      if (varsCount > 5) return TemplateComplexity.medium;
      return TemplateComplexity.low;
    } catch (e) {
      return TemplateComplexity.medium;
    }
  }

  /// 生成变量修复建议
  Future<List<String>> _generateVariableFixSuggestions(Map<String, String> errors) async {
    final suggestions = <String>[];
    
    for (final entry in errors.entries) {
      final varName = entry.key;
      final error = entry.value;
      
      if (error.contains('空') || error.contains('empty')) {
        suggestions.add('为 $varName 提供有效值');
      } else if (error.contains('格式') || error.contains('format')) {
        suggestions.add('检查 $varName 的格式要求');
      } else {
        suggestions.add('修复 $varName: $error');
      }
    }
    
    return suggestions;
  }

  /// 分析高峰使用时间
  List<int> _analyzePeakUsageHours() {
    final hourCounts = <int, int>{};
    
    for (final interaction in _interactionHistory) {
      final hour = interaction.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedHours.take(3).map((e) => e.key).toList();
  }

  /// 生成用户体验建议
  List<String> _generateUXRecommendations() {
    final recommendations = <String>[];
    
    if (_interactionHistory.isEmpty) {
      recommendations.add('开始使用模板引擎以获得个性化建议');
      return recommendations;
    }
    
    final recentErrors = _interactionHistory
        .where((i) => i.result != 'success')
        .take(5)
        .toList();
    
    if (recentErrors.length > 2) {
      recommendations.add('最近错误较多，建议检查模板变量配置');
    }
    
    final avgDuration = _interactionHistory
        .where((i) => i.duration != null)
        .map((i) => i.duration!.inMilliseconds)
        .fold(0, (a, b) => a + b) / _interactionHistory.length;
    
    if (avgDuration > 1000) {
      recommendations.add('生成时间较长，建议使用缓存预热功能');
    }
    
    return recommendations;
  }
}

// ==================== 支持类和数据结构 ====================

/// 进度更新数据结构
class ProgressUpdate {
  const ProgressUpdate({
    required this.message,
    required this.progress,
    required this.timestamp,
  });

  final String message;
  final double progress; // 0.0 到 1.0
  final DateTime timestamp;
}

/// 用户交互记录
class UserInteraction {
  UserInteraction({
    required this.action,
    required this.timestamp, this.templateName,
  });

  final String action;
  final String? templateName;
  final DateTime timestamp;
  String? result;
  Duration? duration;
  String? error;
}

/// 性能指标收集器
class PerformanceMetricsCollector {
  final List<GenerationMetric> _metrics = [];

  /// 记录生成指标
  void recordGeneration(String templateName, Duration duration) {
    _metrics.add(GenerationMetric(
      templateName: templateName,
      duration: duration,
      timestamp: DateTime.now(),
    ),);
    
    // 保持最近1000条记录
    if (_metrics.length > 1000) {
      _metrics.removeAt(0);
    }
  }

  /// 生成性能报告
  Map<String, dynamic> generateReport() {
    if (_metrics.isEmpty) {
      return {
        'total_generations': 0,
        'average_duration_ms': 0,
        'fastest_generation_ms': 0,
        'slowest_generation_ms': 0,
      };
    }

    final durations = _metrics.map((m) => m.duration.inMilliseconds).toList();
    durations.sort();

    return {
      'total_generations': _metrics.length,
      'average_duration_ms': durations.fold(0, (a, b) => a + b) / durations.length,
      'fastest_generation_ms': durations.first,
      'slowest_generation_ms': durations.last,
      'median_duration_ms': durations[durations.length ~/ 2],
    };
  }
}

/// 生成指标
class GenerationMetric {
  const GenerationMetric({
    required this.templateName,
    required this.duration,
    required this.timestamp,
  });

  final String templateName;
  final Duration duration;
  final DateTime timestamp;
}

/// 模板推荐
class TemplateRecommendation {
  const TemplateRecommendation({
    required this.templateName,
    required this.score,
    required this.reason,
    required this.metadata,
    required this.estimatedComplexity,
  });

  final String templateName;
  final double score;
  final String reason;
  final Map<String, dynamic> metadata;
  final TemplateComplexity estimatedComplexity;
}

/// 模板复杂度枚举
enum TemplateComplexity { low, medium, high }

/// 模板验证结果
class TemplateValidationResult {
  const TemplateValidationResult({
    required this.success,
    this.message,
    this.suggestions,
  });

  final bool success;
  final String? message;
  final List<String>? suggestions;
}


