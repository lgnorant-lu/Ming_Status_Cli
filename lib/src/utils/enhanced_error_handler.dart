/*
---------------------------------------------------------------
File name:          enhanced_error_handler.dart
Author:             lgnorant-lu
Date created:       2025-07-08
Last modified:      2025-07-08
Dart Version:       3.2+
Description:        Task 50.1 - 增强的错误处理和用户体验
                    提供更友好的错误信息和智能建议
---------------------------------------------------------------
Change History:
    2025-07-08: Initial creation - 增强错误处理系统;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:ming_status_cli/src/utils/progress_indicator.dart';

/// 错误严重程度
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// 错误类别
enum ErrorCategory {
  usage,           // 用法错误
  fileSystem,      // 文件系统错误
  network,         // 网络错误
  permission,      // 权限错误
  configuration,   // 配置错误
  template,        // 模板错误
  validation,      // 验证错误
  system,          // 系统错误
}

/// 错误恢复策略
enum RecoveryStrategy {
  automatic,       // 自动恢复
  interactive,     // 交互式恢复
  manual,          // 手动恢复
  impossible,      // 无法恢复
}

/// 增强的错误信息
class EnhancedError {
  const EnhancedError({
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    this.context,
    this.suggestions = const [],
    this.quickFixes = const [],
    this.docLink,
    this.recoveryStrategy = RecoveryStrategy.manual,
    this.technicalDetails,
  });

  final String title;
  final String description;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final String? context;
  final List<String> suggestions;
  final List<QuickFix> quickFixes;
  final String? docLink;
  final RecoveryStrategy recoveryStrategy;
  final Object? technicalDetails;
}

/// 快速修复选项
class QuickFix {
  const QuickFix({
    required this.description,
    required this.action,
    this.isDestructive = false,
    this.requiresConfirmation = false,
  });

  final String description;
  final Future<bool> Function() action;
  final bool isDestructive;
  final bool requiresConfirmation;
}

/// 增强的错误处理器
class EnhancedErrorHandler {
  static const String baseDocUrl = 'https://ming-status-cli.docs.com';
  
  /// 处理增强错误
  static Future<void> handleEnhancedError(EnhancedError error) async {
    _displayError(error);
    
    if (error.quickFixes.isNotEmpty) {
      await _offerQuickFixes(error);
    }
    
    _showAdditionalHelp(error);
  }

  /// 显示错误信息
  static void _displayError(EnhancedError error) {
    final icon = _getSeverityIcon(error.severity);
    final coloredTitle = _colorizeTitle(error.title, error.severity);
    
    Logger.newLine();
    stderr.writeln('$icon $coloredTitle');
    stderr.writeln('   ${error.description}');
    
    if (error.context != null) {
      Logger.newLine();
      Logger.info('📍 上下文: ${error.context}');
    }
    
    if (error.suggestions.isNotEmpty) {
      Logger.newLine();
      Logger.info('💡 建议解决方案:');
      for (var i = 0; i < error.suggestions.length; i++) {
        Logger.listItem(error.suggestions[i]);
      }
    }
  }

  /// 提供快速修复选项
  static Future<void> _offerQuickFixes(EnhancedError error) async {
    if (error.quickFixes.isEmpty) return;
    
    Logger.newLine();
    Logger.info('🔧 快速修复选项:');
    
    final options = <String>[];
    for (var i = 0; i < error.quickFixes.length; i++) {
      final fix = error.quickFixes[i];
      final destructiveWarning = fix.isDestructive ? ' ⚠️' : '';
      options.add('${fix.description}$destructiveWarning');
    }
    options.add('跳过修复');
    
    final choice = UserInteraction.choice(
      '选择修复方式:',
      options,
    );
    
    if (choice != null && choice < error.quickFixes.length) {
      final selectedFix = error.quickFixes[choice];
      await _executeQuickFix(selectedFix);
    }
  }

  /// 执行快速修复
  static Future<void> _executeQuickFix(QuickFix fix) async {
    if (fix.requiresConfirmation || fix.isDestructive) {
      final confirmed = UserInteraction.confirm(
        '确定要执行此修复吗？${fix.isDestructive ? ' (此操作不可撤销)' : ''}',
        defaultValue: !fix.isDestructive,
      );
      
      if (!confirmed) {
        Logger.info('已取消修复操作');
        return;
      }
    }
    
    final progress = ProgressIndicator(
      title: '正在执行修复',
      config: const ProgressConfig(type: ProgressType.spinner),
    );
    
    progress.start();
    
    try {
      final success = await fix.action();
      
      if (success) {
        progress.complete(message: '修复成功');
      } else {
        progress.fail(message: '修复失败');
      }
    } catch (e) {
      progress.fail(message: '修复过程中发生错误: $e');
    }
  }

  /// 显示额外帮助信息
  static void _showAdditionalHelp(EnhancedError error) {
    if (error.docLink != null) {
      Logger.newLine();
      Logger.info('📚 详细文档: ${error.docLink}');
    }
    
    _showCategorySpecificHelp(error.category);
  }

  /// 显示类别特定的帮助
  static void _showCategorySpecificHelp(ErrorCategory category) {
    Logger.newLine();
    
    switch (category) {
      case ErrorCategory.usage:
        Logger.info('💬 命令帮助:');
        Logger.listItem('使用 "ming help" 查看所有命令');
        Logger.listItem('使用 "ming help <command>" 查看具体命令用法');
        Logger.listItem('使用 --verbose 获取详细信息');
        
      case ErrorCategory.fileSystem:
        Logger.info('📁 文件系统帮助:');
        Logger.listItem('检查文件路径是否正确');
        Logger.listItem('确认文件权限设置');
        Logger.listItem('检查磁盘空间是否充足');
        
      case ErrorCategory.network:
        Logger.info('🌐 网络帮助:');
        Logger.listItem('检查网络连接');
        Logger.listItem('确认代理设置');
        Logger.listItem('尝试使用 --offline 模式');
        
      case ErrorCategory.permission:
        Logger.info('🔐 权限帮助:');
        Logger.listItem('使用管理员权限运行');
        Logger.listItem('检查文件夹访问权限');
        Logger.listItem('确认用户组设置');
        
      case ErrorCategory.configuration:
        Logger.info('⚙️ 配置帮助:');
        Logger.listItem('运行 "ming doctor" 检查配置');
        Logger.listItem('使用 "ming config --list" 查看当前配置');
        Logger.listItem('重置配置: "ming config --reset"');
        
      case ErrorCategory.template:
        Logger.info('🎨 模板帮助:');
        Logger.listItem('检查模板名称是否正确');
        Logger.listItem('确认模板文件完整性');
        Logger.listItem('尝试重新下载模板');
        
      case ErrorCategory.validation:
        Logger.info('✅ 验证帮助:');
        Logger.listItem('使用 "ming validate --fix" 自动修复');
        Logger.listItem('查看详细验证报告');
        Logger.listItem('调整验证级别');
        
      case ErrorCategory.system:
        Logger.info('🖥️ 系统帮助:');
        Logger.listItem('重启终端或IDE');
        Logger.listItem('检查系统环境变量');
        Logger.listItem('更新到最新版本');
    }
  }

  /// 获取严重程度图标
  static String _getSeverityIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return 'ℹ️';
      case ErrorSeverity.warning:
        return '⚠️';
      case ErrorSeverity.error:
        return '❌';
      case ErrorSeverity.critical:
        return '🚨';
    }
  }

  /// 着色标题
  static String _colorizeTitle(String title, ErrorSeverity severity) {
    if (!stdout.supportsAnsiEscapes) return title;
    
    switch (severity) {
      case ErrorSeverity.info:
        return '\x1B[36m$title\x1B[0m'; // 青色
      case ErrorSeverity.warning:
        return '\x1B[33m$title\x1B[0m'; // 黄色
      case ErrorSeverity.error:
        return '\x1B[31m$title\x1B[0m'; // 红色
      case ErrorSeverity.critical:
        return '\x1B[91m\x1B[1m$title\x1B[0m'; // 亮红色加粗
    }
  }

  /// 创建常见错误的快速修复
  static List<QuickFix> createCommonQuickFixes(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.fileSystem:
        return [
          QuickFix(
            description: '创建缺失的目录',
            action: () async {
              // 实现目录创建逻辑
              return true;
            },
          ),
          QuickFix(
            description: '修复文件权限',
            action: () async {
              // 实现权限修复逻辑
              return true;
            },
            requiresConfirmation: true,
          ),
        ];
        
      case ErrorCategory.configuration:
        return [
          QuickFix(
            description: '重置配置到默认值',
            action: () async {
              // 实现配置重置逻辑
              return true;
            },
            isDestructive: true,
            requiresConfirmation: true,
          ),
          QuickFix(
            description: '重新生成配置文件',
            action: () async {
              // 实现配置重新生成逻辑
              return true;
            },
          ),
        ];
        
      case ErrorCategory.template:
        return [
          QuickFix(
            description: '重新下载模板',
            action: () async {
              // 实现模板重新下载逻辑
              return true;
            },
          ),
          QuickFix(
            description: '清除模板缓存',
            action: () async {
              // 实现缓存清除逻辑
              return true;
            },
          ),
        ];
        
      default:
        return [];
    }
  }
}
