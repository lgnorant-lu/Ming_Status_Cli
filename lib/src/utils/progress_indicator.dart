/*
---------------------------------------------------------------
File name:          progress_indicator.dart
Author:             lgnorant-lu
Date created:       2025/06/30
Last modified:      2025/06/30
Dart Version:       3.2+
Description:        进度指示器和用户交互工具 
                    (Progress indicator and user interaction utilities)
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 进度指示器类型
enum ProgressType {
  /// 旋转指示器
  spinner,
  /// 进度条
  progressBar,
  /// 简单状态
  simple,
}

/// 进度指示器配置
class ProgressConfig {
  /// 创建进度指示器配置实例
  const ProgressConfig({
    this.type = ProgressType.progressBar,
    this.showPercentage = true,
    this.showElapsedTime = true,
    this.width = 50,
    this.completedChar = '█',
    this.remainingChar = '░',
    this.spinnerChars = const [
      '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏',],
  });

  /// 进度指示器类型
  final ProgressType type;
  /// 是否显示百分比
  final bool showPercentage;
  /// 是否显示已用时间
  final bool showElapsedTime;
  /// 进度条宽度
  final int width;
  /// 已完成字符
  final String completedChar;
  /// 剩余字符
  final String remainingChar;
  /// 旋转指示器字符数组
  final List<String> spinnerChars;
}

/// 进度指示器
class ProgressIndicator {
  /// 创建进度指示器实例
  ProgressIndicator({
    required this.title,
    this.config = const ProgressConfig(),
  }) : _startTime = DateTime.now();

  /// 进度指示器标题
  final String title;
  /// 进度指示器配置
  final ProgressConfig config;
  final DateTime _startTime;
  
  bool _isActive = false;
  Timer? _spinnerTimer;
  int _spinnerIndex = 0;
  double _progress = 0;

  /// 开始进度指示
  void start() {
    if (_isActive) return;
    
    _isActive = true;
    _progress = 0.0;
    
    switch (config.type) {
      case ProgressType.spinner:
        _startSpinner();
      case ProgressType.progressBar:
        _showProgressBar();
      case ProgressType.simple:
        _showSimpleStatus();
    }
  }

  /// 更新进度
  void update(double progress, {String? status}) {
    if (!_isActive) return;
    
    _progress = progress.clamp(0.0, 1.0);
    
    switch (config.type) {
      case ProgressType.spinner:
        // Spinner会自动更新，只需要更新状态
        if (status != null) {
          _updateSpinnerStatus(status);
        }
      case ProgressType.progressBar:
        _showProgressBar(status: status);
      case ProgressType.simple:
        _showSimpleStatus(status: status);
    }
  }

  /// 完成进度指示
  void complete({String? message}) {
    if (!_isActive) return;
    
    _isActive = false;
    _spinnerTimer?.cancel();
    _progress = 1.0;
    
    // 清除当前行并显示完成消息
    stdout.write('\r\x1B[2K');
    
    final completedMessage = message ?? '$title 完成';
    final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
    
    if (config.showElapsedTime) {
      cli_logger.Logger.success('✅ $completedMessage (${elapsed}ms)');
    } else {
      cli_logger.Logger.success('✅ $completedMessage');
    }
  }

  /// 失败完成
  void fail({String? message}) {
    if (!_isActive) return;
    
    _isActive = false;
    _spinnerTimer?.cancel();
    
    // 清除当前行并显示失败消息
    stdout.write('\r\x1B[2K');
    
    final failedMessage = message ?? '$title 失败';
    cli_logger.Logger.error('❌ $failedMessage');
  }

  /// 开始旋转指示器
  void _startSpinner() {
    _spinnerTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isActive) return;
      
      final spinnerChar = config.spinnerChars[_spinnerIndex];
      _spinnerIndex = (_spinnerIndex + 1) % config.spinnerChars.length;
      
      final elapsed = DateTime.now().difference(_startTime);
      final elapsedStr = config.showElapsedTime 
          ? ' (${elapsed.inSeconds}s)'
          : '';
      
      stdout.write('\r\x1B[2K$spinnerChar $title$elapsedStr');
    });
  }

  /// 更新旋转指示器状态
  void _updateSpinnerStatus(String status) {
    // 状态更新会在下一次timer回调中体现
  }

  /// 显示进度条
  void _showProgressBar({String? status}) {
    final completedWidth = (_progress * config.width).round();
    final remainingWidth = config.width - completedWidth;
    
    final progressBar = config.completedChar * completedWidth +
                       config.remainingChar * remainingWidth;
    
    final percentage = config.showPercentage 
        ? ' ${(_progress * 100).toInt()}%'
        : '';
    
    final elapsed = DateTime.now().difference(_startTime);
    final elapsedStr = config.showElapsedTime 
        ? ' (${elapsed.inSeconds}s)'
        : '';
    
    final statusStr = status != null ? ' - $status' : '';
    
    stdout.write('\r\x1B[2K[$progressBar]$percentage $title'
        '$elapsedStr$statusStr');
  }

  /// 显示简单状态
  void _showSimpleStatus({String? status}) {
    final percentage = config.showPercentage 
        ? ' ${(_progress * 100).toInt()}%'
        : '';
    
    final elapsed = DateTime.now().difference(_startTime);
    final elapsedStr = config.showElapsedTime 
        ? ' (${elapsed.inSeconds}s)'
        : '';
    
    final statusStr = status != null ? ' - $status' : '';
    
    stdout.write('\r\x1B[2K🔄 $title$percentage$elapsedStr$statusStr');
  }
}

/// 用户交互工具
class UserInteraction {
  /// 获取用户确认
  static bool confirm(String message, {bool defaultValue = false}) {
    final defaultStr = defaultValue ? 'Y/n' : 'y/N';
    stdout.write('$message [$defaultStr]: ');
    
    final input = stdin.readLineSync()?.trim().toLowerCase();
    
    if (input == null || input.isEmpty) {
      return defaultValue;
    }
    
    return input == 'y' || input == 'yes' || input == '是';
  }

  /// 获取用户选择
  static int? choice(
      String message, List<String> options, {int? defaultValue,}) {
    cli_logger.Logger.info(message);
    
    for (var i = 0; i < options.length; i++) {
      final marker = (defaultValue != null && defaultValue == i) ? '●' : '○';
      cli_logger.Logger.info('  $marker ${i + 1}. ${options[i]}');
    }
    
    final defaultStr = defaultValue != null ? ' [${defaultValue + 1}]' : '';
    stdout.write('请选择$defaultStr: ');
    
    final input = stdin.readLineSync()?.trim();
    
    if (input == null || input.isEmpty) {
      return defaultValue;
    }
    
    final choice = int.tryParse(input);
    if (choice != null && choice >= 1 && choice <= options.length) {
      return choice - 1;
    }
    
    return null;
  }

  /// 获取用户输入
  static String? input(
      String message, {String? defaultValue, bool required = false,}) {
    final defaultStr = defaultValue != null ? ' [$defaultValue]' : '';
    stdout.write('$message$defaultStr: ');
    
    final input = stdin.readLineSync()?.trim();
    
    if (input == null || input.isEmpty) {
      if (required && defaultValue == null) {
        cli_logger.Logger.error('此字段为必需项');
        return UserInteraction.input(
          message, defaultValue: defaultValue, required: required,
        );
      }
      return defaultValue;
    }
    
    return input;
  }

  /// 获取密码输入（隐藏输入）
  static String? password(String message, {bool required = false}) {
    stdout.write('$message: ');
    
    // 注意：在命令行中隐藏密码输入需要特殊处理
    // 这里使用简化版本，实际项目中可能需要更复杂的实现
    stdin.echoMode = false;
    final password = stdin.readLineSync();
    stdin.echoMode = true;
    stdout.writeln(); // 换行
    
    if (required && (password == null || password.trim().isEmpty)) {
      cli_logger.Logger.error('密码为必需项');
      return UserInteraction.password(message, required: required);
    }
    
    return password?.trim();
  }

  /// 多选输入
  static List<int> multiChoice(
      String message, List<String> options, {List<int>? defaultValues,}) {
    cli_logger.Logger.info(message);
    cli_logger.Logger.info('（多选，使用逗号分隔，如：1,3,5）');
    
    for (var i = 0; i < options.length; i++) {
      final marker = (defaultValues?.contains(i) ?? false) ? '●' : '○';
      cli_logger.Logger.info('  $marker ${i + 1}. ${options[i]}');
    }
    
    final defaultStr = (defaultValues?.isNotEmpty ?? false) 
        ? ' [${defaultValues!.map((i) => i + 1).join(',')}]'
        : '';
    stdout.write('请选择$defaultStr: ');
    
    final input = stdin.readLineSync()?.trim();
    
    if (input == null || input.isEmpty) {
      return defaultValues ?? [];
    }
    
    final choices = <int>[];
    for (final part in input.split(',')) {
      final choice = int.tryParse(part.trim());
      if (choice != null && choice >= 1 && choice <= options.length) {
        choices.add(choice - 1);
      }
    }
    
    return choices;
  }
}

/// 错误恢复提示工具
class ErrorRecoveryPrompt {
  /// 显示错误并询问恢复选项
  static String? showErrorWithRecovery(
    String error,
    List<String> recoveryOptions, {
    String? suggestion,
  }) {
    cli_logger.Logger.error('❌ 错误: $error');
    
    if (suggestion != null) {
      cli_logger.Logger.info('💡 建议: $suggestion');
    }
    
    cli_logger.Logger.info('');
    cli_logger.Logger.info('🔧 恢复选项:');
    
    final choice = UserInteraction.choice(
      '请选择恢复方式:',
      [...recoveryOptions, '取消操作'],
    );
    
    if (choice == null || choice >= recoveryOptions.length) {
      return null; // 用户取消或无效选择
    }
    
    return recoveryOptions[choice];
  }

  /// 显示回滚确认
  static bool confirmRollback(String operation, List<String> affectedFiles) {
    cli_logger.Logger.warning('⚠️  操作失败: $operation');
    cli_logger.Logger.info('');
    cli_logger.Logger.info('📋 受影响的文件:');
    
    for (final file in affectedFiles.take(10)) {
      cli_logger.Logger.info('  • $file');
    }
    
    if (affectedFiles.length > 10) {
      cli_logger.Logger.info('  ... 还有 ${affectedFiles.length - 10} 个文件');
    }
    
    cli_logger.Logger.info('');
    return UserInteraction.confirm(
      '🔄 是否回滚所有更改？',
      defaultValue: true,
    );
  }
}

/// 状态消息格式化工具
class StatusFormatter {
  /// 格式化成功消息
  static void success(String message) {
    cli_logger.Logger.success('✅ $message');
  }

  /// 格式化警告消息
  static void warning(String message) {
    cli_logger.Logger.warning('⚠️  $message');
  }

  /// 格式化错误消息
  static void error(String message) {
    cli_logger.Logger.error('❌ $message');
  }

  /// 格式化信息消息
  static void info(String message) {
    cli_logger.Logger.info('ℹ️  $message');
  }

  /// 格式化步骤消息
  static void step(String message, {int? stepNumber, int? totalSteps}) {
    final stepInfo = stepNumber != null && totalSteps != null
        ? '[$stepNumber/$totalSteps] '
        : '';
    cli_logger.Logger.info('🔄 $stepInfo$message');
  }

  /// 格式化完成消息
  static void completed(String message, {Duration? duration}) {
    final timeInfo = duration != null 
        ? ' (${duration.inMilliseconds}ms)'
        : '';
    cli_logger.Logger.success('🎉 $message$timeInfo');
  }
} 
