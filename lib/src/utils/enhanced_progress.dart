/*
---------------------------------------------------------------
File name:          enhanced_progress.dart
Author:             lgnorant-lu
Date created:       2025-07-08
Last modified:      2025-07-08
Dart Version:       3.2+
Description:        Task 50.1 - 增强的进度指示系统
                    提供更丰富的进度反馈和用户体验
---------------------------------------------------------------
Change History:
    2025-07-08: Initial creation - 增强进度指示系统;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:io';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 进度阶段
enum ProgressPhase {
  initializing,
  processing,
  finalizing,
  completed,
  failed,
}

/// 进度样式
enum ProgressStyle {
  minimal, // 最简样式
  standard, // 标准样式
  detailed, // 详细样式
  animated, // 动画样式
}

/// 增强的进度配置
class EnhancedProgressConfig {
  const EnhancedProgressConfig({
    this.style = ProgressStyle.standard,
    this.showPercentage = true,
    this.showElapsedTime = true,
    this.showETA = true,
    this.showThroughput = false,
    this.animationSpeed = 200,
    this.width = 40,
    this.enableColors = true,
  });

  final ProgressStyle style;
  final bool showPercentage;
  final bool showElapsedTime;
  final bool showETA;
  final bool showThroughput;
  final int animationSpeed;
  final int width;
  final bool enableColors;
}

/// 进度步骤
class ProgressStep {
  ProgressStep({
    required this.name,
    required this.weight,
    this.description,
  });

  final String name;
  final double weight;
  final String? description;
  bool isCompleted = false;
  bool isFailed = false;
  DateTime? startTime;
  DateTime? endTime;
  String? errorMessage;
}

/// 增强的进度指示器
class EnhancedProgressIndicator {
  EnhancedProgressIndicator({
    required this.title,
    this.config = const EnhancedProgressConfig(),
    this.steps = const [],
  }) : _startTime = DateTime.now();

  final String title;
  final EnhancedProgressConfig config;
  final List<ProgressStep> steps;
  final DateTime _startTime;

  bool _isActive = false;
  Timer? _animationTimer;
  int _animationFrame = 0;
  double _progress = 0;
  ProgressPhase _phase = ProgressPhase.initializing;
  String? _currentStatus;
  int _currentStepIndex = 0;
  final List<Duration> _stepDurations = [];

  /// 获取当前步骤索引
  int get currentStepIndex => _currentStepIndex;

  /// 开始进度指示
  void start() {
    if (_isActive) return;

    _isActive = true;
    _phase = ProgressPhase.initializing;
    _progress = 0.0;

    if (config.style == ProgressStyle.animated) {
      _startAnimation();
    }

    _displayProgress();
  }

  /// 更新进度
  void updateProgress(double progress, {String? status}) {
    if (!_isActive) return;

    _progress = progress.clamp(0.0, 1.0);
    _currentStatus = status;

    if (_progress > 0 && _phase == ProgressPhase.initializing) {
      _phase = ProgressPhase.processing;
    }

    _displayProgress();
  }

  /// 开始步骤
  void startStep(int stepIndex, {String? customName}) {
    if (!_isActive || stepIndex >= steps.length) return;

    _currentStepIndex = stepIndex;
    final step = steps[stepIndex];
    step.startTime = DateTime.now();

    final stepName = customName ?? step.name;
    _currentStatus = stepName;

    // 计算基于步骤的进度
    final completedWeight = steps
        .take(stepIndex)
        .where((s) => s.isCompleted)
        .fold<double>(0, (sum, s) => sum + s.weight);

    final totalWeight = steps.fold<double>(0, (sum, s) => sum + s.weight);
    _progress = totalWeight > 0 ? completedWeight / totalWeight : 0.0;

    _displayProgress();
  }

  /// 完成步骤
  void completeStep(int stepIndex, {String? message}) {
    if (!_isActive || stepIndex >= steps.length) return;

    final step = steps[stepIndex];
    step.isCompleted = true;
    step.endTime = DateTime.now();

    if (step.startTime != null) {
      _stepDurations.add(step.endTime!.difference(step.startTime!));
    }

    // 重新计算进度
    final completedWeight = steps
        .where((s) => s.isCompleted)
        .fold<double>(0, (sum, s) => sum + s.weight);

    final totalWeight = steps.fold<double>(0, (sum, s) => sum + s.weight);
    _progress = totalWeight > 0 ? completedWeight / totalWeight : 1.0;

    if (config.style == ProgressStyle.detailed) {
      Logger.success('✅ ${step.name}${message != null ? ' - $message' : ''}');
    }

    _displayProgress();
  }

  /// 步骤失败
  void failStep(int stepIndex, String errorMessage) {
    if (!_isActive || stepIndex >= steps.length) return;

    final step = steps[stepIndex];
    step.isFailed = true;
    step.endTime = DateTime.now();
    step.errorMessage = errorMessage;

    _phase = ProgressPhase.failed;

    if (config.style == ProgressStyle.detailed) {
      Logger.error('❌ ${step.name} - $errorMessage');
    }

    _displayProgress();
  }

  /// 完成进度
  void complete({String? message}) {
    if (!_isActive) return;

    _isActive = false;
    _animationTimer?.cancel();
    _progress = 1.0;
    _phase = ProgressPhase.completed;

    _clearCurrentLine();

    final completedMessage = message ?? '$title 完成';
    final elapsed = DateTime.now().difference(_startTime);

    if (config.showElapsedTime) {
      Logger.success('✅ $completedMessage (${_formatDuration(elapsed)})');
    } else {
      Logger.success('✅ $completedMessage');
    }

    if (config.style == ProgressStyle.detailed) {
      _showSummary();
    }
  }

  /// 失败完成
  void fail({String? message}) {
    if (!_isActive) return;

    _isActive = false;
    _animationTimer?.cancel();
    _phase = ProgressPhase.failed;

    _clearCurrentLine();

    final failedMessage = message ?? '$title 失败';
    Logger.error('❌ $failedMessage');

    if (config.style == ProgressStyle.detailed) {
      _showFailureSummary();
    }
  }

  /// 显示进度
  void _displayProgress() {
    if (!_isActive) return;

    switch (config.style) {
      case ProgressStyle.minimal:
        _displayMinimalProgress();
      case ProgressStyle.standard:
        _displayStandardProgress();
      case ProgressStyle.detailed:
        _displayDetailedProgress();
      case ProgressStyle.animated:
        _displayAnimatedProgress();
    }
  }

  /// 显示最简进度
  void _displayMinimalProgress() {
    final percentage = (_progress * 100).toInt();
    stdout.write('\r$title... $percentage%');
  }

  /// 显示标准进度
  void _displayStandardProgress() {
    final progressBar = _buildProgressBar();
    final percentage =
        config.showPercentage ? ' ${(_progress * 100).toInt()}%' : '';
    final elapsed = config.showElapsedTime ? ' (${_getElapsedString()})' : '';
    final eta = config.showETA ? ' ETA: ${_getETAString()}' : '';
    final status = _currentStatus != null ? ' - $_currentStatus' : '';

    stdout.write('\r\x1B[2K$progressBar$percentage $title$elapsed$eta$status');
  }

  /// 显示详细进度
  void _displayDetailedProgress() {
    // 详细模式不使用单行更新，而是输出多行信息
    if (_currentStatus != null) {
      Logger.info('🔄 $_currentStatus');
    }
  }

  /// 显示动画进度
  void _displayAnimatedProgress() {
    final spinner = _getSpinnerFrame();
    final progressBar = _buildProgressBar();
    final percentage =
        config.showPercentage ? ' ${(_progress * 100).toInt()}%' : '';
    final status = _currentStatus != null ? ' - $_currentStatus' : '';

    stdout.write('\r\x1B[2K$spinner $progressBar$percentage $title$status');
  }

  /// 构建进度条
  String _buildProgressBar() {
    final completedWidth = (_progress * config.width).round();
    final remainingWidth = config.width - completedWidth;

    if (config.enableColors && stdout.supportsAnsiEscapes) {
      final completed = '\x1B[42m \x1B[0m' * completedWidth;
      final remaining = '\x1B[47m \x1B[0m' * remainingWidth;
      return '[$completed$remaining]';
    } else {
      final completed = '█' * completedWidth;
      final remaining = '░' * remainingWidth;
      return '[$completed$remaining]';
    }
  }

  /// 获取旋转器帧
  String _getSpinnerFrame() {
    const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    return frames[_animationFrame % frames.length];
  }

  /// 开始动画
  void _startAnimation() {
    _animationTimer = Timer.periodic(
      Duration(milliseconds: config.animationSpeed),
      (timer) {
        _animationFrame++;
        if (_isActive) {
          _displayProgress();
        } else {
          timer.cancel();
        }
      },
    );
  }

  /// 获取已用时间字符串
  String _getElapsedString() {
    final elapsed = DateTime.now().difference(_startTime);
    return _formatDuration(elapsed);
  }

  /// 获取预计剩余时间字符串
  String _getETAString() {
    if (_progress <= 0) return '未知';

    final elapsed = DateTime.now().difference(_startTime);
    final totalEstimated = Duration(
      milliseconds: (elapsed.inMilliseconds / _progress).round(),
    );
    final remaining = totalEstimated - elapsed;

    return remaining.inSeconds > 0 ? _formatDuration(remaining) : '即将完成';
  }

  /// 格式化持续时间
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// 清除当前行
  void _clearCurrentLine() {
    stdout.write('\r\x1B[2K');
  }

  /// 显示总结
  void _showSummary() {
    Logger.newLine();
    Logger.info('📊 执行总结:');

    final totalElapsed = DateTime.now().difference(_startTime);
    Logger.listItem('总耗时: ${_formatDuration(totalElapsed)}');
    Logger.listItem(
        '完成步骤: ${steps.where((s) => s.isCompleted).length}/${steps.length}');

    if (_stepDurations.isNotEmpty) {
      final avgDuration = Duration(
        milliseconds: _stepDurations
                .map((d) => d.inMilliseconds)
                .reduce((a, b) => a + b) ~/
            _stepDurations.length,
      );
      Logger.listItem('平均步骤耗时: ${_formatDuration(avgDuration)}');
    }
  }

  /// 显示失败总结
  void _showFailureSummary() {
    Logger.newLine();
    Logger.error('💥 执行失败总结:');

    final failedSteps = steps.where((s) => s.isFailed).toList();
    for (final step in failedSteps) {
      Logger.listItem('${step.name}: ${step.errorMessage ?? '未知错误'}');
    }

    final completedSteps = steps.where((s) => s.isCompleted).length;
    Logger.listItem('已完成步骤: $completedSteps/${steps.length}');
  }
}
