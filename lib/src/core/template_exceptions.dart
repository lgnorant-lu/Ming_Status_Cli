/*
---------------------------------------------------------------
File name:          template_exceptions.dart
Author:             lgnorant-lu
Date created:       2025/07/02
Last modified:      2025/07/02
Dart Version:       3.2+
Description:        模板异常 (Template exceptions)
---------------------------------------------------------------
Change History:
    2025/07/02: Initial creation - 模板异常功能;
---------------------------------------------------------------
*/

import 'dart:io';

/// 模板引擎错误类型枚举
enum TemplateEngineErrorType {
  /// 模板不存在
  templateNotFound,
  /// 模板格式无效
  invalidTemplateFormat,
  /// 变量验证失败
  variableValidationFailed,
  /// 输出路径冲突
  outputPathConflict,
  /// 文件系统错误
  fileSystemError,
  /// Mason包错误
  masonError,
  /// 钩子执行错误
  hookExecutionError,
  /// 网络错误
  networkError,
  /// 权限错误
  permissionError,
  /// 版本兼容性错误
  versionCompatibilityError,
  /// 依赖兼容性错误
  dependencyCompatibilityError,
  /// 平台兼容性错误
  platformCompatibilityError,
  /// 模板标准合规性错误
  templateComplianceError,
  /// 未知错误
  unknown,
}

/// 模板引擎异常类
class TemplateEngineException implements Exception {
  /// 创建模板引擎异常
  /// 
  /// 参数：
  /// - [type] 错误类型
  /// - [message] 错误消息
  /// - [details] 错误详情
  /// - [innerException] 内部异常
  /// - [recovery] 恢复建议
  const TemplateEngineException({
    required this.type,
    required this.message,
    this.details,
    this.innerException,
    this.recovery,
  });

  /// 创建模板不存在错误
  TemplateEngineException.templateNotFound(
    String templateName, {
    String? recovery,
  }) : this(
      type: TemplateEngineErrorType.templateNotFound,
      message: '模板不存在: $templateName',
      details: {'templateName': templateName},
      recovery: recovery ?? 
          '请检查模板名称是否正确，或使用 ming template list 查看可用模板',
    );

  /// 创建Mason包错误
  TemplateEngineException.masonError(
    String operation,
    dynamic error, {
    String? recovery,
  }) : this(
      type: TemplateEngineErrorType.masonError,
      message: 'Mason包操作失败: $operation',
      details: {'operation': operation},
      innerException: error,
      recovery: recovery ?? '请检查模板格式是否正确，或尝试重新安装模板',
    );

  /// 创建文件系统错误
  TemplateEngineException.fileSystemError(
    String operation,
    String path,
    dynamic error, {
    String? recovery,
  }) : this(
      type: TemplateEngineErrorType.fileSystemError,
      message: '文件系统操作失败: $operation',
      details: {'operation': operation, 'path': path},
      innerException: error,
      recovery: recovery ?? '请检查文件路径和权限是否正确',
    );

  /// 创建变量验证错误
  TemplateEngineException.variableValidationError(
    Map<String, String> validationErrors, {
    String? recovery,
  }) : this(
      type: TemplateEngineErrorType.variableValidationFailed,
      message: '模板变量验证失败',
      details: {'validationErrors': validationErrors},
      recovery: recovery ?? '请检查并修正模板变量值',
    );

  /// 错误类型
  final TemplateEngineErrorType type;
  /// 错误消息
  final String message;
  /// 错误详情
  final Map<String, dynamic>? details;
  /// 内部异常
  final dynamic innerException;
  /// 恢复建议
  final String? recovery;

  @override
  String toString() {
    var result = 'TemplateEngineException: $message';
    if (details != null && details!.isNotEmpty) {
      result += '\nDetails: $details';
    }
    if (recovery != null) {
      result += '\nRecovery: $recovery';
    }
    if (innerException != null) {
      result += '\nCaused by: $innerException';
    }
    return result;
  }
}

/// 错误恢复结果
class ErrorRecoveryResult {
  /// 创建错误恢复结果
  /// 
  /// 参数：
  /// - [success] 恢复是否成功
  /// - [message] 恢复消息
  /// - [recoveredValue] 恢复后的值
  const ErrorRecoveryResult({
    required this.success,
    this.message,
    this.recoveredValue,
  });

  /// 成功恢复
  ErrorRecoveryResult.createSuccess({String? message, dynamic value}) 
    : this(
      success: true,
      message: message,
      recoveredValue: value,
    );

  /// 恢复失败
  ErrorRecoveryResult.createFailure(String message)
    : this(
      success: false,
      message: message,
    );

  /// 恢复是否成功
  final bool success;
  /// 恢复消息
  final String? message;
  /// 恢复后的值
  final dynamic recoveredValue;
}

/// 错误恢复策略接口
abstract class ErrorRecoveryStrategy {
  /// 尝试恢复错误
  Future<ErrorRecoveryResult> recover(TemplateEngineException error);
  
  /// 是否可以处理该类型的错误
  bool canHandle(TemplateEngineErrorType errorType);
}

/// 模板不存在错误恢复策略
class TemplateNotFoundRecoveryStrategy implements ErrorRecoveryStrategy {
  /// 创建模板不存在错误恢复策略
  /// 
  /// 参数：
  /// - [templateEngine] 模板引擎实例
  const TemplateNotFoundRecoveryStrategy(this.templateEngine);
  
  /// 模板引擎实例引用（使用动态类型避免循环依赖）
  final dynamic templateEngine;

  @override
  bool canHandle(TemplateEngineErrorType errorType) {
    return errorType == TemplateEngineErrorType.templateNotFound;
  }

  @override
  Future<ErrorRecoveryResult> recover(TemplateEngineException error) async {
    try {
      // 尝试查找相似的模板名称
      final availableTemplates = await templateEngine.getAvailableTemplates();
      final targetTemplate = error.details?['templateName'] as String?;
      
      if (targetTemplate != null) {
        // 转换动态类型到具体类型
        final templates = (availableTemplates as List<dynamic>).cast<String>();
        if (templates.isNotEmpty) {
          // 简单的相似性匹配
          final suggestions = templates
              .where((String template) => 
                  template.toLowerCase().contains(targetTemplate.toLowerCase()) ||
                  targetTemplate.toLowerCase().contains(template.toLowerCase()),)
              .toList();
              
          if (suggestions.isNotEmpty) {
            return ErrorRecoveryResult.createSuccess(
              message: '找到相似模板: ${suggestions.join(", ")}',
              value: suggestions,
            );
          }
        }
      }
      
      final templates = (availableTemplates as List<dynamic>).cast<String>();
      return ErrorRecoveryResult.createSuccess(
        message: '可用模板: ${templates.join(", ")}',
        value: templates,
      );
    } catch (e) {
      return ErrorRecoveryResult.createFailure('无法获取模板列表: $e');
    }
  }
}

/// 文件系统错误恢复策略
class FileSystemErrorRecoveryStrategy implements ErrorRecoveryStrategy {
  @override
  bool canHandle(TemplateEngineErrorType errorType) {
    return errorType == TemplateEngineErrorType.fileSystemError ||
           errorType == TemplateEngineErrorType.permissionError;
  }

  @override
  Future<ErrorRecoveryResult> recover(TemplateEngineException error) async {
    try {
      final operation = error.details?['operation'] as String?;
      final path = error.details?['path'] as String?;
      
      if (operation == 'createDirectory' && path != null) {
        // 尝试创建父目录
        final parentDir = Directory(path).parent;
        if (!parentDir.existsSync()) {
          parentDir.createSync(recursive: true);
          await Directory(path).create();
          return ErrorRecoveryResult.createSuccess(
            message: '成功创建目录: $path',
          );
        }
      }
      
      if (operation == 'writeFile' && path != null) {
        // 检查父目录是否存在
        final file = File(path);
        final parentDir = file.parent;
        if (!parentDir.existsSync()) {
          parentDir.createSync(recursive: true);
          return ErrorRecoveryResult.createSuccess(
            message: '成功创建父目录: ${parentDir.path}',
          );
        }
      }
      
      return ErrorRecoveryResult.createFailure('无法自动恢复文件系统错误');
    } catch (e) {
      return ErrorRecoveryResult.createFailure('恢复过程中发生错误: $e');
    }
  }
}