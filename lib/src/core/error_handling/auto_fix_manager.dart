/*
---------------------------------------------------------------
File name:          auto_fix_manager.dart
Author:             Ignorant-lu
Date created:       2025/07/04
Last modified:      2025/07/04
Dart Version:       3.32.4
Description:        自动修复管理器 - 集中管理所有自动修复功能
---------------------------------------------------------------
Change History:
    2025/07/04: Initial creation - 自动修复管理器实现;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 修复结果类型
enum FixResultType {
  /// 修复成功
  success,

  /// 修复失败
  failed,

  /// 跳过修复
  skipped,

  /// 不支持自动修复
  unsupported,
}

/// 修复结果
class FixResult {
  /// 创建修复结果
  const FixResult({
    required this.type,
    required this.message,
    this.details,
    this.command,
  });

  /// 结果类型
  final FixResultType type;

  /// 结果消息
  final String message;

  /// 详细信息
  final String? details;

  /// 执行的命令
  final String? command;

  /// 是否成功
  bool get isSuccess => type == FixResultType.success;

  /// 是否失败
  bool get isFailed => type == FixResultType.failed;

  /// 是否跳过
  bool get isSkipped => type == FixResultType.skipped;
}

/// 修复统计信息
class FixStatistics {
  /// 创建修复统计信息
  FixStatistics({
    this.totalIssues = 0,
    this.successCount = 0,
    this.failedCount = 0,
    this.skippedCount = 0,
    this.unsupportedCount = 0,
  });

  /// 问题总数
  int totalIssues;

  /// 修复成功数量
  int successCount;

  /// 修复失败数量
  int failedCount;

  /// 跳过修复数量
  int skippedCount;

  /// 不支持修复数量
  int unsupportedCount;

  /// 修复率
  double get fixRate => totalIssues > 0 ? successCount / totalIssues : 0.0;

  /// 成功率（在尝试修复的问题中）
  double get successRate {
    final attempted = successCount + failedCount;
    return attempted > 0 ? successCount / attempted : 0.0;
  }
}

/// 自动修复管理器
/// 负责管理和执行所有类型的自动修复功能
class AutoFixManager {
  /// 创建自动修复管理器
  AutoFixManager({
    this.workingDirectory = '.',
    this.continueOnError = false,
    this.excludePatterns = const [],
  });

  /// 工作目录
  final String workingDirectory;

  /// 遇到错误时是否继续
  final bool continueOnError;

  /// 排除模式
  final List<String> excludePatterns;

  /// 修复统计信息
  final FixStatistics _statistics = FixStatistics();

  /// 获取修复统计信息
  FixStatistics get statistics => _statistics;

  /// 执行自动修复
  ///
  /// [result] 验证结果
  /// [targetPath] 目标路径
  Future<FixStatistics> performAutoFix(
    ValidationResult result,
    String targetPath,
  ) async {
    Logger.info('🔧 AutoFixManager: 开始自动修复流程');

    final autoFixableMessages = result.autoFixableMessages;
    _statistics.totalIssues = autoFixableMessages.length;

    if (autoFixableMessages.isEmpty) {
      Logger.info('没有可自动修复的问题');
      return _statistics;
    }

    Logger.info('发现 ${autoFixableMessages.length} 个可自动修复的问题');

    for (final message in autoFixableMessages) {
      final fixResult = await _processFixableMessage(message, targetPath);
      _updateStatistics(fixResult);

      // 记录修复结果
      _logFixResult(message, fixResult);

      // 如果修复失败且不继续错误，则停止
      if (fixResult.isFailed && !continueOnError) {
        Logger.warning('修复失败，停止自动修复流程');
        break;
      }
    }

    _logFinalStatistics();
    return _statistics;
  }

  /// 处理可修复消息
  Future<FixResult> _processFixableMessage(
    ValidationMessage message,
    String targetPath,
  ) async {
    // 检查是否应该跳过此文件
    if (_shouldSkipFile(message.file)) {
      return FixResult(
        type: FixResultType.skipped,
        message: '文件被排除: ${message.file}',
      );
    }

    // 根据修复建议类型执行修复
    final fixSuggestion = message.fixSuggestion;
    if (fixSuggestion == null) {
      return const FixResult(
        type: FixResultType.unsupported,
        message: '没有修复建议',
      );
    }

    switch (fixSuggestion.fixabilityLevel) {
      case FixabilityLevel.automatic:
        return _performAutomaticFix(message, targetPath);
      case FixabilityLevel.suggested:
        return _performSuggestedFix(message, targetPath);
      case FixabilityLevel.manual:
        return _performManualGuidance(message);
      case FixabilityLevel.unfixable:
        return const FixResult(
          type: FixResultType.unsupported,
          message: '无法修复的问题类型',
        );
    }
  }

  /// 执行自动修复
  Future<FixResult> _performAutomaticFix(
    ValidationMessage message,
    String targetPath,
  ) async {
    final fixSuggestion = message.fixSuggestion!;

    // 优先执行命令修复
    if (fixSuggestion.command != null) {
      return _executeFixCommand(
        fixSuggestion.command!,
        message.message,
        targetPath,
      );
    }

    // 尝试基于问题类型的智能修复
    return _performIntelligentFix(message, targetPath);
  }

  /// 执行建议修复
  Future<FixResult> _performSuggestedFix(
    ValidationMessage message,
    String targetPath,
  ) async {
    final fixSuggestion = message.fixSuggestion!;

    // 对于建议级别的修复，提供详细信息但不自动执行
    if (fixSuggestion.codeExample != null) {
      Logger.info('💡 修复建议: ${message.message}');
      Logger.info('📝 代码示例: ${fixSuggestion.codeExample}');

      if (fixSuggestion.documentation != null) {
        Logger.info('📖 参考文档: ${fixSuggestion.documentation}');
      }
    }

    return FixResult(
      type: FixResultType.skipped,
      message: '建议级修复，已提供修复指导',
      details: fixSuggestion.codeExample,
    );
  }

  /// 提供手动指导
  FixResult _performManualGuidance(ValidationMessage message) {
    final fixSuggestion = message.fixSuggestion!;

    Logger.info('🔧 手动修复指导: ${message.message}');
    if (fixSuggestion.description.isNotEmpty) {
      Logger.info('📋 修复说明: ${fixSuggestion.description}');
    }

    if (fixSuggestion.documentation != null) {
      Logger.info('📖 参考文档: ${fixSuggestion.documentation}');
    }

    return FixResult(
      type: FixResultType.skipped,
      message: '手动修复，已提供指导信息',
      details: fixSuggestion.description,
    );
  }

  /// 执行智能修复
  Future<FixResult> _performIntelligentFix(
    ValidationMessage message,
    String targetPath,
  ) async {
    // 基于问题描述和文件类型执行智能修复
    final problemType = _identifyProblemType(message.message);

    switch (problemType) {
      case 'formatting':
        return _fixFormatting(message, targetPath);
      case 'imports':
        return _fixImportSorting(message, targetPath);
      case 'configuration':
        return _fixConfiguration(message, targetPath);
      case 'documentation':
        return _fixDocumentation(message, targetPath);
      default:
        return const FixResult(
          type: FixResultType.unsupported,
          message: '未识别的问题类型，无法自动修复',
        );
    }
  }

  /// 识别问题类型
  String _identifyProblemType(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('format') ||
        lowerMessage.contains('缩进') ||
        lowerMessage.contains('行长度') ||
        lowerMessage.contains('trailing whitespace')) {
      return 'formatting';
    }

    if (lowerMessage.contains('import') ||
        lowerMessage.contains('导入') ||
        lowerMessage.contains('unused import')) {
      return 'imports';
    }

    if (lowerMessage.contains('pubspec') ||
        lowerMessage.contains('analysis_options') ||
        lowerMessage.contains('配置')) {
      return 'configuration';
    }

    if (lowerMessage.contains('documentation') ||
        lowerMessage.contains('文档') ||
        lowerMessage.contains('comment')) {
      return 'documentation';
    }

    return 'unknown';
  }

  /// 修复代码格式
  Future<FixResult> _fixFormatting(
    ValidationMessage message,
    String targetPath,
  ) async {
    final file = message.file;
    if (file == null || !file.endsWith('.dart')) {
      return const FixResult(
        type: FixResultType.unsupported,
        message: '非Dart文件，无法执行格式化',
      );
    }

    return _executeFixCommand(
      'dart format "$file"',
      '格式化文件: $file',
      targetPath,
    );
  }

  /// 修复导入排序
  Future<FixResult> _fixImportSorting(
    ValidationMessage message,
    String targetPath,
  ) async {
    final file = message.file;
    if (file == null || !file.endsWith('.dart')) {
      return const FixResult(
        type: FixResultType.unsupported,
        message: '非Dart文件，无法排序导入',
      );
    }

    // 尝试使用dart fix命令
    return _executeFixCommand(
      'dart fix --apply "$file"',
      '修复导入排序: $file',
      targetPath,
    );
  }

  /// 修复配置文件
  Future<FixResult> _fixConfiguration(
    ValidationMessage message,
    String targetPath,
  ) async {
    final file = message.file;
    if (file == null) {
      return const FixResult(
        type: FixResultType.unsupported,
        message: '没有指定文件，无法修复配置',
      );
    }

    // 根据文件类型执行不同的修复策略
    if (file.endsWith('pubspec.yaml')) {
      return _fixPubspecConfiguration(file, targetPath);
    } else if (file.endsWith('analysis_options.yaml')) {
      return _fixAnalysisOptionsConfiguration(file, targetPath);
    }

    return FixResult(
      type: FixResultType.unsupported,
      message: '不支持的配置文件类型: $file',
    );
  }

  /// 修复pubspec.yaml配置
  Future<FixResult> _fixPubspecConfiguration(
    String file,
    String targetPath,
  ) async {
    // 执行pub get来修复依赖问题
    return _executeFixCommand(
      'dart pub get',
      '更新依赖配置: $file',
      targetPath,
    );
  }

  /// 修复analysis_options.yaml配置
  Future<FixResult> _fixAnalysisOptionsConfiguration(
    String file,
    String targetPath,
  ) async {
    // 对于分析选项，通常需要手动修复
    return const FixResult(
      type: FixResultType.skipped,
      message: 'analysis_options.yaml需要手动修复',
      details: '请根据项目需求手动调整linter规则',
    );
  }

  /// 修复文档
  Future<FixResult> _fixDocumentation(
    ValidationMessage message,
    String targetPath,
  ) async {
    // 文档修复通常需要手动处理
    return const FixResult(
      type: FixResultType.skipped,
      message: '文档问题需要手动修复',
      details: '请为相关类和方法添加适当的文档注释',
    );
  }

  /// 执行修复命令
  Future<FixResult> _executeFixCommand(
    String command,
    String description,
    String workingDirectory,
  ) async {
    try {
      Logger.debug('执行修复命令: $command');

      // 跨平台命令执行
      final processResult = Platform.isWindows
          ? await Process.run(
              'cmd',
              ['/c', command],
              workingDirectory: workingDirectory,
            )
          : await Process.run(
              'sh',
              ['-c', command],
              workingDirectory: workingDirectory,
            );

      if (processResult.exitCode == 0) {
        return FixResult(
          type: FixResultType.success,
          message: description,
          command: command,
        );
      } else {
        return FixResult(
          type: FixResultType.failed,
          message: '修复失败: $description',
          details: processResult.stderr.toString(),
          command: command,
        );
      }
    } catch (e) {
      return FixResult(
        type: FixResultType.failed,
        message: '修复命令执行异常: $description',
        details: e.toString(),
        command: command,
      );
    }
  }

  /// 检查是否应该跳过文件
  bool _shouldSkipFile(String? filePath) {
    if (filePath == null) return false;

    for (final pattern in excludePatterns) {
      if (filePath.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  /// 更新统计信息
  void _updateStatistics(FixResult result) {
    switch (result.type) {
      case FixResultType.success:
        _statistics.successCount++;
      case FixResultType.failed:
        _statistics.failedCount++;
      case FixResultType.skipped:
        _statistics.skippedCount++;
      case FixResultType.unsupported:
        _statistics.unsupportedCount++;
    }
  }

  /// 记录修复结果
  void _logFixResult(ValidationMessage message, FixResult result) {
    switch (result.type) {
      case FixResultType.success:
        Logger.success('✅ ${result.message}');
      case FixResultType.failed:
        Logger.warning('❌ ${result.message}');
        if (result.details != null) {
          Logger.debug('错误详情: ${result.details}');
        }
      case FixResultType.skipped:
        Logger.info('⏭️  ${result.message}');
      case FixResultType.unsupported:
        Logger.debug('❓ ${result.message}');
    }
  }

  /// 记录最终统计信息
  void _logFinalStatistics() {
    Logger.info('\n🎉 自动修复完成统计:');
    Logger.info('  总问题数: ${_statistics.totalIssues}');
    Logger.info('  修复成功: ${_statistics.successCount}');
    Logger.info('  修复失败: ${_statistics.failedCount}');
    Logger.info('  跳过修复: ${_statistics.skippedCount}');
    Logger.info('  不支持修复: ${_statistics.unsupportedCount}');

    if (_statistics.totalIssues > 0) {
      Logger.info('  修复率: ${(_statistics.fixRate * 100).toStringAsFixed(1)}%');

      final attempted = _statistics.successCount + _statistics.failedCount;
      if (attempted > 0) {
        Logger.info(
          '  成功率: ${(_statistics.successRate * 100).toStringAsFixed(1)}%',
        );
      }
    }
  }

  /// 重置统计信息
  void resetStatistics() {
    _statistics.totalIssues = 0;
    _statistics.successCount = 0;
    _statistics.failedCount = 0;
    _statistics.skippedCount = 0;
    _statistics.unsupportedCount = 0;
  }
}
