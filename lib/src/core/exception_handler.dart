/*
---------------------------------------------------------------
File name:          exception_handler.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.1 - 增强异常处理中间件
                    统一异常处理、错误报告和用户友好的错误信息
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 增强异常处理中间件;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/core/diagnostic_system.dart';
import 'package:ming_status_cli/src/core/error_recovery_system.dart';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:path/path.dart' as path;

/// 异常类型
enum ExceptionType {
  validation, // 验证错误
  fileSystem, // 文件系统错误
  network, // 网络错误
  permission, // 权限错误
  configuration, // 配置错误
  template, // 模板错误
  dependency, // 依赖错误
  runtime, // 运行时错误
  unknown, // 未知错误
}

/// 增强的异常基类
abstract class MingException implements Exception {
  String get message;
  ExceptionType get type;
  String? get context;
  Map<String, dynamic> get metadata;
  List<String> get suggestions;
  bool get isRecoverable;

  @override
  String toString() => 'MingException: $message';
}

/// 验证异常
class ValidationException extends MingException {
  ValidationException(
    this.message, {
    this.context,
    this.metadata = const {},
    this.violations = const [],
  });
  @override
  final String message;
  @override
  final String? context;
  @override
  final Map<String, dynamic> metadata;
  final List<String> violations;

  @override
  ExceptionType get type => ExceptionType.validation;

  @override
  List<String> get suggestions => [
        '检查输入数据的格式和内容',
        '运行 "ming validate" 查看详细验证信息',
        '参考文档了解正确的配置格式',
      ];

  @override
  bool get isRecoverable => true;
}

/// 文件系统异常
class FileSystemException extends MingException {
  FileSystemException(
    this.message, {
    this.context,
    this.metadata = const {},
    this.filePath,
    this.operation,
  });
  @override
  final String message;
  @override
  final String? context;
  @override
  final Map<String, dynamic> metadata;
  final String? filePath;
  final String? operation;

  @override
  ExceptionType get type => ExceptionType.fileSystem;

  @override
  List<String> get suggestions {
    final suggestions = <String>[];

    if (operation == 'read') {
      suggestions.addAll([
        '确认文件路径是否正确',
        '检查文件是否存在',
        '验证文件读取权限',
      ]);
    } else if (operation == 'write') {
      suggestions.addAll([
        '检查目录写入权限',
        '确认磁盘空间是否充足',
        '验证文件路径的有效性',
      ]);
    } else {
      suggestions.addAll([
        '检查文件和目录权限',
        '确认路径是否正确',
        '验证磁盘空间',
      ]);
    }

    return suggestions;
  }

  @override
  bool get isRecoverable => true;
}

/// 配置异常
class ConfigurationException extends MingException {
  ConfigurationException(
    this.message, {
    this.context,
    this.metadata = const {},
    this.configKey,
    this.configFile,
  });
  @override
  final String message;
  @override
  final String? context;
  @override
  final Map<String, dynamic> metadata;
  final String? configKey;
  final String? configFile;

  @override
  ExceptionType get type => ExceptionType.configuration;

  @override
  List<String> get suggestions => [
        '运行 "ming config --list" 查看当前配置',
        '使用 "ming config --set <key>=<value>" 设置配置',
        '运行 "ming doctor" 检查配置问题',
        '参考文档了解配置选项',
      ];

  @override
  bool get isRecoverable => true;
}

/// 模板异常
class TemplateException extends MingException {
  TemplateException(
    this.message, {
    this.context,
    this.metadata = const {},
    this.templateName,
    this.templatePath,
  });
  @override
  final String message;
  @override
  final String? context;
  @override
  final Map<String, dynamic> metadata;
  final String? templateName;
  final String? templatePath;

  @override
  ExceptionType get type => ExceptionType.template;

  @override
  List<String> get suggestions => [
        '运行 "ming template list" 查看可用模板',
        '使用 "ming template install <name>" 安装模板',
        '检查模板配置文件格式',
        '验证模板变量设置',
      ];

  @override
  bool get isRecoverable => true;
}

/// 异常处理器
class ExceptionHandler {
  factory ExceptionHandler() => _instance;
  ExceptionHandler._internal();
  static final ExceptionHandler _instance = ExceptionHandler._internal();

  // Logger是静态类，不需要实例化
  final ErrorRecoverySystem _recoverySystem = ErrorRecoverySystem();
  final DiagnosticSystem _diagnosticSystem = DiagnosticSystem();

  /// 获取诊断系统实例 (Phase 2使用)
  DiagnosticSystem get diagnosticSystem => _diagnosticSystem;

  bool _isInitialized = false;
  String? _crashReportDirectory;

  /// 初始化异常处理器
  Future<void> initialize({String? crashReportDirectory}) async {
    if (_isInitialized) return;

    _crashReportDirectory = crashReportDirectory ??
        path.join(Directory.systemTemp.path, 'ming_cli_crashes');

    final dir = Directory(_crashReportDirectory!);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    // 设置全局异常处理
    _setupGlobalExceptionHandling();

    await _recoverySystem.initialize();

    _isInitialized = true;
    Logger.info('异常处理器已初始化');
  }

  /// 处理异常
  Future<int> handleException(Object exception, StackTrace? stackTrace) async {
    try {
      if (exception is MingException) {
        return await _handleMingException(exception, stackTrace);
      } else {
        return await _handleGenericException(exception, stackTrace);
      }
    } catch (e) {
      // 异常处理器本身出错，记录并返回通用错误码
      Logger.error('异常处理器内部错误: $e');
      print('❌ 发生了意外错误，请联系技术支持');
      return 1;
    }
  }

  /// 处理 Ming 异常
  Future<int> _handleMingException(
    MingException exception,
    StackTrace? stackTrace,
  ) async {
    Logger.error('Ming异常: ${exception.message}');

    // 显示用户友好的错误信息
    _displayUserFriendlyError(exception);

    // 如果异常可恢复，尝试恢复
    if (exception.isRecoverable) {
      final recovered = await _attemptRecovery(exception);
      if (recovered) {
        print('✅ 问题已自动解决');
        return 0;
      }
    }

    // 生成崩溃报告
    await _generateCrashReport(exception, stackTrace);

    // 根据异常类型返回相应的退出码
    return _getExitCodeForException(exception);
  }

  /// 处理通用异常
  Future<int> _handleGenericException(
    Object exception,
    StackTrace? stackTrace,
  ) async {
    Logger.error('未处理的异常: $exception');

    // 尝试分析异常类型
    final exceptionType = _analyzeExceptionType(exception);

    print('\n❌ 发生了意外错误:');
    print('   $exception');

    // 提供通用建议
    _displayGenericSuggestions(exceptionType);

    // 生成崩溃报告
    await _generateCrashReport(exception, stackTrace);

    return 1;
  }

  /// 显示用户友好的错误信息
  void _displayUserFriendlyError(MingException exception) {
    final icon = _getExceptionIcon(exception.type);

    print('\n$icon ${exception.message}');

    if (exception.context != null) {
      print('   上下文: ${exception.context}');
    }

    if (exception.suggestions.isNotEmpty) {
      print('\n💡 建议解决方案:');
      for (final suggestion in exception.suggestions) {
        print('   • $suggestion');
      }
    }

    // 显示相关的诊断信息
    _displayRelevantDiagnostics(exception.type);
  }

  /// 显示相关诊断信息
  void _displayRelevantDiagnostics(ExceptionType type) {
    switch (type) {
      case ExceptionType.configuration:
        print('\n🔍 快速诊断:');
        print('   运行 "ming doctor" 进行全面检查');
      case ExceptionType.fileSystem:
        print('\n🔍 快速诊断:');
        print('   检查当前目录权限和磁盘空间');
      case ExceptionType.template:
        print('\n🔍 快速诊断:');
        print('   运行 "ming template list" 查看可用模板');
      default:
        break;
    }
  }

  /// 尝试自动恢复
  Future<bool> _attemptRecovery(MingException exception) async {
    final recoveryActions = _createRecoveryActions(exception);

    if (recoveryActions.isEmpty) return false;

    final recoverableError = RecoverableError(
      message: exception.message,
      severity: _mapToErrorSeverity(exception.type),
      strategy: RecoveryStrategy.automatic,
      context: exception.metadata,
      recoveryActions: recoveryActions,
    );

    return _recoverySystem.handleRecoverableError(recoverableError);
  }

  /// 创建恢复操作
  List<RecoveryAction> _createRecoveryActions(MingException exception) {
    switch (exception.type) {
      case ExceptionType.configuration:
        return [
          RecoveryAction(
            name: '重置配置',
            description: '重置配置到默认值',
            action: () async {
              // 实现配置重置逻辑
              return false; // 暂时返回false
            },
            isDestructive: true,
          ),
        ];

      case ExceptionType.fileSystem:
        return [
          RecoveryAction(
            name: '创建目录',
            description: '创建缺失的目录',
            action: () async {
              // 实现目录创建逻辑
              return false; // 暂时返回false
            },
          ),
        ];

      default:
        return [];
    }
  }

  /// 生成崩溃报告
  Future<void> _generateCrashReport(
    Object exception,
    StackTrace? stackTrace,
  ) async {
    if (_crashReportDirectory == null) return;

    try {
      final timestamp = DateTime.now();
      final reportId = timestamp.millisecondsSinceEpoch.toString();
      final reportFile =
          File(path.join(_crashReportDirectory!, 'crash_$reportId.json'));

      final report = {
        'timestamp': timestamp.toIso8601String(),
        'reportId': reportId,
        'platform': Platform.operatingSystem,
        'dartVersion': Platform.version,
        'exception': {
          'type': exception.runtimeType.toString(),
          'message': exception.toString(),
          'stackTrace': stackTrace?.toString(),
        },
        'environment': Platform.environment,
        'workingDirectory': Directory.current.path,
      };

      await reportFile.writeAsString(jsonEncode(report));

      print('\n📄 崩溃报告已保存: ${reportFile.path}');
      print('   报告ID: $reportId');
    } catch (e) {
      Logger.warning('无法生成崩溃报告: $e');
    }
  }

  /// 设置全局异常处理
  void _setupGlobalExceptionHandling() {
    // 处理未捕获的异步异常
    runZonedGuarded(
      () {
        // 这里可以设置全局的异步异常处理
      },
      handleException,
    );
  }

  /// 分析异常类型
  ExceptionType _analyzeExceptionType(Object exception) {
    final exceptionString = exception.toString().toLowerCase();

    if (exceptionString.contains('file') ||
        exceptionString.contains('directory')) {
      return ExceptionType.fileSystem;
    } else if (exceptionString.contains('permission') ||
        exceptionString.contains('access')) {
      return ExceptionType.permission;
    } else if (exceptionString.contains('network') ||
        exceptionString.contains('socket')) {
      return ExceptionType.network;
    } else if (exceptionString.contains('config')) {
      return ExceptionType.configuration;
    } else {
      return ExceptionType.unknown;
    }
  }

  /// 显示通用建议
  void _displayGenericSuggestions(ExceptionType type) {
    print('\n💡 建议:');

    switch (type) {
      case ExceptionType.fileSystem:
        print('   • 检查文件路径和权限');
        print('   • 确认磁盘空间充足');
      case ExceptionType.permission:
        print('   • 使用管理员权限运行');
        print('   • 检查文件和目录权限');
      case ExceptionType.network:
        print('   • 检查网络连接');
        print('   • 确认代理设置');
      case ExceptionType.configuration:
        print('   • 运行 "ming doctor" 检查配置');
        print('   • 重置配置文件');
      default:
        print('   • 运行 "ming doctor" 进行诊断');
        print('   • 查看日志文件获取更多信息');
        print('   • 联系技术支持');
    }
  }

  /// 获取异常图标
  String _getExceptionIcon(ExceptionType type) {
    switch (type) {
      case ExceptionType.validation:
        return '⚠️';
      case ExceptionType.fileSystem:
        return '📁';
      case ExceptionType.network:
        return '🌐';
      case ExceptionType.permission:
        return '🔐';
      case ExceptionType.configuration:
        return '⚙️';
      case ExceptionType.template:
        return '🎨';
      case ExceptionType.dependency:
        return '📦';
      case ExceptionType.runtime:
        return '⚡';
      case ExceptionType.unknown:
        return '❓';
    }
  }

  /// 获取异常对应的退出码
  int _getExitCodeForException(MingException exception) {
    switch (exception.type) {
      case ExceptionType.validation:
        return 2;
      case ExceptionType.fileSystem:
        return 3;
      case ExceptionType.network:
        return 4;
      case ExceptionType.permission:
        return 5;
      case ExceptionType.configuration:
        return 6;
      case ExceptionType.template:
        return 7;
      case ExceptionType.dependency:
        return 8;
      case ExceptionType.runtime:
        return 9;
      case ExceptionType.unknown:
        return 1;
    }
  }

  /// 映射到错误严重程度
  ErrorSeverity _mapToErrorSeverity(ExceptionType type) {
    switch (type) {
      case ExceptionType.validation:
      case ExceptionType.configuration:
        return ErrorSeverity.medium;
      case ExceptionType.fileSystem:
      case ExceptionType.template:
        return ErrorSeverity.high;
      case ExceptionType.permission:
      case ExceptionType.runtime:
        return ErrorSeverity.critical;
      default:
        return ErrorSeverity.medium;
    }
  }

  /// 清理崩溃报告
  Future<void> cleanupCrashReports({
    Duration maxAge = const Duration(days: 30),
  }) async {
    if (_crashReportDirectory == null) return;

    final dir = Directory(_crashReportDirectory!);
    if (!dir.existsSync()) return;

    final cutoffTime = DateTime.now().subtract(maxAge);
    final files = dir.listSync().whereType<File>();

    var deletedCount = 0;
    for (final file in files) {
      final stat = await file.stat();
      if (stat.modified.isBefore(cutoffTime)) {
        await file.delete();
        deletedCount++;
      }
    }

    if (deletedCount > 0) {
      Logger.info('清理了 $deletedCount 个过期的崩溃报告');
    }
  }
}
