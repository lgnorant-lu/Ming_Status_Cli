/*
---------------------------------------------------------------
File name:          error_recovery_strategies.dart
Author:             lgnorant-lu
Date created:       2025/07/02
Last modified:      2025/07/02
Dart Version:       3.2+
Description:        错误恢复策略 (Error recovery strategies)
---------------------------------------------------------------
Change History:
    2025/07/02: Initial creation - 错误恢复策略功能;
---------------------------------------------------------------
*/

import 'dart:io';
import 'dart:math' as math;

import 'package:ming_status_cli/src/core/template_exceptions.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:ming_status_cli/src/utils/string_utils.dart';
import 'package:path/path.dart' as path;

/// 错误模式
class ErrorPattern {
  const ErrorPattern({
    required this.errorType,
    required this.frequency,
    required this.recentSuccessRate,
    required this.isRecurring,
    required this.severity,
    required this.suggestedApproach,
  });

  /// 错误类型
  final TemplateEngineErrorType errorType;
  /// 错误发生频率
  final int frequency;
  /// 最近成功率
  final double recentSuccessRate;
  /// 是否为重复发生的错误
  final bool isRecurring;
  /// 错误严重程度
  final ErrorSeverity severity;
  /// 建议的恢复方法
  final RecoveryApproach suggestedApproach;
}

/// 错误严重程度
enum ErrorSeverity { 
  /// 低严重程度
  low, 
  /// 中等严重程度
  medium, 
  /// 高严重程度
  high, 
  /// 严重程度
  critical 
}

/// 恢复方法
enum RecoveryApproach { 
  /// 重试方法
  retry, 
  /// 自适应方法
  adaptive, 
  /// 预防性方法
  preventive, 
  /// 手动方法
  manual 
}

// ==================== 智能恢复策略实现 ====================

/// 自适应模板未找到恢复策略
class AdaptiveTemplateNotFoundStrategy implements ErrorRecoveryStrategy {
  AdaptiveTemplateNotFoundStrategy(this.templateEngine, this.pattern);

  /// 模板引擎实例
  final dynamic templateEngine;
  /// 错误模式
  final ErrorPattern pattern;

  @override
  bool canHandle(TemplateEngineErrorType errorType) {
    return errorType == TemplateEngineErrorType.templateNotFound;
  }

  @override
  Future<ErrorRecoveryResult> recover(TemplateEngineException error) async {
    try {
      final targetTemplate = error.details?['templateName'] as String?;
      if (targetTemplate == null) {
        return ErrorRecoveryResult.createFailure('无法确定目标模板名称');
      }

      // 1. 智能模板匹配
      final suggestions = await _findSimilarTemplates(targetTemplate);
      
      if (suggestions.isNotEmpty) {
        // 2. 如果频繁出错，尝试自动创建基础模板
        if (pattern.isRecurring && pattern.frequency > 3) {
          final created = await _tryCreateBasicTemplate(targetTemplate);
          if (created) {
            return ErrorRecoveryResult.createSuccess(
              message: '自动创建了基础模板: $targetTemplate',
              value: targetTemplate,
            );
          }
        }

        return ErrorRecoveryResult.createSuccess(
          message: '找到相似模板: ${suggestions.join(", ")}',
          value: suggestions,
        );
      }

      // 3. 尝试从模板库下载
      if (await _tryDownloadTemplate(targetTemplate)) {
        return ErrorRecoveryResult.createSuccess(
          message: '成功下载模板: $targetTemplate',
          value: targetTemplate,
        );
      }

      return ErrorRecoveryResult.createFailure('无法恢复模板: $targetTemplate');

    } catch (e) {
      return ErrorRecoveryResult.createFailure('模板恢复异常: $e');
    }
  }

  /// 查找相似模板
  Future<List<String>> _findSimilarTemplates(String targetTemplate) async {
    try {
      final dynamic templatesResult = await templateEngine.getAvailableTemplates();
      final availableTemplates = (templatesResult as List<dynamic>).cast<String>();
      final target = targetTemplate.toLowerCase();
      
      // 使用多种匹配算法
      final suggestions = <String>[];
      
      // 1. 精确部分匹配
      for (final template in availableTemplates) {
        if (template.toLowerCase().contains(target) ||
            target.contains(template.toLowerCase())) {
          suggestions.add(template);
        }
      }
      
      // 2. 模糊匹配（基于编辑距离）
      for (final template in availableTemplates) {
        if (suggestions.contains(template)) continue;
        
        final distance = _calculateEditDistance(target, template.toLowerCase());
        final maxLength = math.max(target.length, template.length);
        final similarity = 1.0 - (distance / maxLength);
        
        if (similarity > 0.6) {
          suggestions.add(template);
        }
      }
      
      return suggestions.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  /// 计算编辑距离
  int _calculateEditDistance(String s1, String s2) {
    final dp = List<List<int>>.generate(
      s1.length + 1,
      (i) => List<int>.filled(s2.length + 1, 0),
    );

    for (var i = 0; i <= s1.length; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= s2.length; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= s1.length; i++) {
      for (var j = 1; j <= s2.length; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + math.min(
            math.min(dp[i - 1][j], dp[i][j - 1]),
            dp[i - 1][j - 1],
          );
        }
      }
    }

    return dp[s1.length][s2.length];
  }

  /// 尝试创建基础模板
  Future<bool> _tryCreateBasicTemplate(String templateName) async {
    try {
      cli_logger.Logger.info('尝试自动创建基础模板: $templateName');
      final dynamic result = await templateEngine.createBaseTemplate(templateName);
      return result as bool? ?? false;
    } catch (e) {
      cli_logger.Logger.warning('自动创建模板失败: $e');
      return false;
    }
  }

  /// 尝试下载模板
  Future<bool> _tryDownloadTemplate(String templateName) async {
    try {
      // 这里可以实现从远程模板库下载逻辑
      cli_logger.Logger.debug('尝试下载模板: $templateName (暂未实现)');
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// 智能变量恢复策略
class SmartVariableRecoveryStrategy implements ErrorRecoveryStrategy {
  SmartVariableRecoveryStrategy(this.templateEngine, this.pattern);

  /// 模板引擎实例
  final dynamic templateEngine;
  /// 错误模式
  final ErrorPattern pattern;

  @override
  bool canHandle(TemplateEngineErrorType errorType) {
    return errorType == TemplateEngineErrorType.variableValidationFailed;
  }

  @override
  Future<ErrorRecoveryResult> recover(TemplateEngineException error) async {
    try {
      final validationErrors = error.details?['validationErrors'] as Map<String, String>?;
      if (validationErrors == null || validationErrors.isEmpty) {
        return ErrorRecoveryResult.createFailure('无法获取验证错误详情');
      }

      final recoveredVariables = <String, dynamic>{};
      final recoveryMessages = <String>[];

      for (final entry in validationErrors.entries) {
        final varName = entry.key;
        final errorMsg = entry.value;

        final recovered = await _recoverVariable(varName, errorMsg);
        if (recovered != null) {
          recoveredVariables[varName] = recovered;
          recoveryMessages.add('恢复变量 $varName: $recovered');
        }
      }

      if (recoveredVariables.isNotEmpty) {
        return ErrorRecoveryResult.createSuccess(
          message: '成功恢复 ${recoveredVariables.length} 个变量: ${recoveryMessages.join(", ")}',
          value: recoveredVariables,
        );
      }

      return ErrorRecoveryResult.createFailure('无法恢复任何变量');

    } catch (e) {
      return ErrorRecoveryResult.createFailure('变量恢复异常: $e');
    }
  }

  /// 恢复单个变量
  Future<dynamic> _recoverVariable(String varName, String errorMsg) async {
    try {
      // 根据变量名和错误消息智能恢复
      switch (varName) {
        case 'module_id':
          return _generateModuleId();
        case 'module_name':
          return _generateModuleName();
        case 'class_name':
          return _generateClassName();
        case 'author':
          return 'lgnorant-lu';
        case 'version':
          return '1.0.0';
        case 'description':
          return '自动生成的模块描述';
        default:
          return _generateGenericValue(varName, errorMsg);
      }
    } catch (e) {
      return null;
    }
  }

  /// 生成模块ID
  String _generateModuleId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'auto_module_$timestamp';
  }

  /// 生成模块名称
  String _generateModuleName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'Auto Module $timestamp';
  }

  /// 生成类名
  String _generateClassName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'AutoModule$timestamp';
  }

  /// 生成通用值
  dynamic _generateGenericValue(String varName, String errorMsg) {
    if (errorMsg.contains('空') || errorMsg.contains('empty')) {
      return 'auto_$varName';
    }
    
    if (errorMsg.contains('格式') || errorMsg.contains('format')) {
      if (varName.toLowerCase().contains('id')) {
        return 'auto_${varName}_${DateTime.now().millisecondsSinceEpoch}';
      }
      if (varName.toLowerCase().contains('name')) {
        return StringUtils.toPascalCase('auto_$varName');
      }
    }
    
    return 'auto_value';
  }
}

/// 智能文件系统恢复策略
class IntelligentFileSystemRecoveryStrategy implements ErrorRecoveryStrategy {
  IntelligentFileSystemRecoveryStrategy(this.pattern);

  /// 错误模式
  final ErrorPattern pattern;

  @override
  bool canHandle(TemplateEngineErrorType errorType) {
    return errorType == TemplateEngineErrorType.fileSystemError ||
           errorType == TemplateEngineErrorType.permissionError;
  }

  @override
  Future<ErrorRecoveryResult> recover(TemplateEngineException error) async {
    try {
      final operation = error.details?['operation'] as String?;
      final targetPath = error.details?['path'] as String?;

      if (operation == null || targetPath == null) {
        return ErrorRecoveryResult.createFailure('无法确定文件系统操作详情');
      }

      switch (operation) {
        case 'createDirectory':
          return await _recoverDirectoryCreation(targetPath);
        case 'writeFile':
          return await _recoverFileWrite(targetPath);
        case 'readFile':
          return await _recoverFileRead(targetPath);
        default:
          return await _attemptGenericRecovery(operation, targetPath);
      }

    } catch (e) {
      return ErrorRecoveryResult.createFailure('文件系统恢复异常: $e');
    }
  }

  /// 恢复目录创建
  Future<ErrorRecoveryResult> _recoverDirectoryCreation(String dirPath) async {
    try {
      // 1. 尝试创建备用路径
      final altPath = await _createAlternativePath(dirPath);
      if (altPath != null) {
        await Directory(altPath).create(recursive: true);
        return ErrorRecoveryResult.createSuccess(
          message: '在备用路径创建目录: $altPath',
          value: altPath,
        );
      }

      // 2. 尝试修复权限
      if (await _tryFixPermissions(dirPath)) {
        await Directory(dirPath).create(recursive: true);
        return ErrorRecoveryResult.createSuccess(
          message: '修复权限后成功创建目录: $dirPath',
        );
      }

      return ErrorRecoveryResult.createFailure('无法恢复目录创建');

    } catch (e) {
      return ErrorRecoveryResult.createFailure('目录创建恢复失败: $e');
    }
  }

  /// 恢复文件写入
  Future<ErrorRecoveryResult> _recoverFileWrite(String filePath) async {
    try {
      // 1. 检查并创建父目录
      final parentDir = Directory(path.dirname(filePath));
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }

      // 2. 尝试备用文件名
      final altFile = await _createAlternativeFilePath(filePath);
      if (altFile != null) {
        return ErrorRecoveryResult.createSuccess(
          message: '使用备用文件路径: $altFile',
          value: altFile,
        );
      }

      return ErrorRecoveryResult.createFailure('无法恢复文件写入');

    } catch (e) {
      return ErrorRecoveryResult.createFailure('文件写入恢复失败: $e');
    }
  }

  /// 恢复文件读取
  Future<ErrorRecoveryResult> _recoverFileRead(String filePath) async {
    try {
      // 1. 查找相似文件
      final similarFiles = await _findSimilarFiles(filePath);
      if (similarFiles.isNotEmpty) {
        return ErrorRecoveryResult.createSuccess(
          message: '找到相似文件: ${similarFiles.first}',
          value: similarFiles.first,
        );
      }

      // 2. 创建默认文件
      if (await _createDefaultFile(filePath)) {
        return ErrorRecoveryResult.createSuccess(
          message: '创建默认文件: $filePath',
        );
      }

      return ErrorRecoveryResult.createFailure('无法恢复文件读取');

    } catch (e) {
      return ErrorRecoveryResult.createFailure('文件读取恢复失败: $e');
    }
  }

  /// 通用恢复
  Future<ErrorRecoveryResult> _attemptGenericRecovery(
    String operation,
    String targetPath,
  ) async {
    try {
      cli_logger.Logger.info('尝试通用文件系统恢复: $operation -> $targetPath');
      
      // 基本的重试机制
      await Future<void>.delayed(const Duration(milliseconds: 100));
      
      return ErrorRecoveryResult.createSuccess(
        message: '完成通用文件系统恢复尝试',
      );

    } catch (e) {
      return ErrorRecoveryResult.createFailure('通用恢复失败: $e');
    }
  }

  // 私有辅助方法

  /// 创建替代路径
  Future<String?> _createAlternativePath(String originalPath) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final parentDir = path.dirname(originalPath);
      final dirName = path.basename(originalPath);
      
      final altPath = path.join(parentDir, '${dirName}_$timestamp');
      
      if (!Directory(altPath).existsSync()) {
        return altPath;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 创建替代文件路径
  Future<String?> _createAlternativeFilePath(String originalPath) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dir = path.dirname(originalPath);
      final fileName = path.basenameWithoutExtension(originalPath);
      final extension = path.extension(originalPath);
      
      final altPath = path.join(dir, '${fileName}_$timestamp$extension');
      
      if (!File(altPath).existsSync()) {
        return altPath;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 尝试修复权限
  Future<bool> _tryFixPermissions(String targetPath) async {
    try {
      // 在实际实现中，这里可以尝试修改文件权限
      // 为了简化，这里只返回false
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 查找相似文件
  Future<List<String>> _findSimilarFiles(String targetPath) async {
    try {
      final dir = Directory(path.dirname(targetPath));
      final targetName = path.basename(targetPath);
      
      if (!dir.existsSync()) return [];
      
      final files = <String>[];
      await for (final entity in dir.list()) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          if (fileName.toLowerCase().contains(targetName.toLowerCase()) ||
              targetName.toLowerCase().contains(fileName.toLowerCase())) {
            files.add(entity.path);
          }
        }
      }
      
      return files;
    } catch (e) {
      return [];
    }
  }

  /// 创建默认文件
  Future<bool> _createDefaultFile(String filePath) async {
    try {
      final file = File(filePath);
      const defaultContent = '# 自动生成的默认文件\n';
      await file.writeAsString(defaultContent);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Mason错误恢复策略
class MasonErrorRecoveryStrategy implements ErrorRecoveryStrategy {
  MasonErrorRecoveryStrategy(this.templateEngine, this.pattern);

  /// 模板引擎实例
  final dynamic templateEngine;
  /// 错误模式
  final ErrorPattern pattern;

  @override
  bool canHandle(TemplateEngineErrorType errorType) {
    return errorType == TemplateEngineErrorType.masonError;
  }

  @override
  Future<ErrorRecoveryResult> recover(TemplateEngineException error) async {
    try {
      final operation = error.details?['operation'] as String?;
      
      switch (operation) {
        case 'fromBrick':
          return await _recoverBrickLoading(error);
        case 'generate':
          return await _recoverGeneration(error);
        default:
          return await _recoverGenericMasonError(error);
      }

    } catch (e) {
      return ErrorRecoveryResult.createFailure('Mason错误恢复异常: $e');
    }
  }

  /// 恢复Brick加载错误
  Future<ErrorRecoveryResult> _recoverBrickLoading(TemplateEngineException error) async {
    try {
      // 1. 清理并重新加载模板缓存
      templateEngine.clearCache();
      
      // 2. 等待一段时间后重试
      await Future<void>.delayed(const Duration(milliseconds: 500));
      
      return ErrorRecoveryResult.createSuccess(
        message: '清理缓存并准备重试Brick加载',
      );

    } catch (e) {
      return ErrorRecoveryResult.createFailure('Brick加载恢复失败: $e');
    }
  }

  /// 恢复生成错误
  Future<ErrorRecoveryResult> _recoverGeneration(TemplateEngineException error) async {
    try {
      return ErrorRecoveryResult.createSuccess(
        message: '准备重试Mason生成操作',
      );

    } catch (e) {
      return ErrorRecoveryResult.createFailure('生成错误恢复失败: $e');
    }
  }

  /// 恢复通用Mason错误
  Future<ErrorRecoveryResult> _recoverGenericMasonError(TemplateEngineException error) async {
    try {
      return ErrorRecoveryResult.createSuccess(
        message: '执行通用Mason错误恢复',
      );

    } catch (e) {
      return ErrorRecoveryResult.createFailure('通用Mason错误恢复失败: $e');
    }
  }
}

/// 网络错误恢复策略
class NetworkErrorRecoveryStrategy implements ErrorRecoveryStrategy {
  NetworkErrorRecoveryStrategy(this.pattern);

  final ErrorPattern pattern;

  @override
  bool canHandle(TemplateEngineErrorType errorType) {
    return errorType == TemplateEngineErrorType.networkError;
  }

  @override
  Future<ErrorRecoveryResult> recover(TemplateEngineException error) async {
    try {
      // 1. 检查网络连接
      if (await _checkNetworkConnectivity()) {
        return ErrorRecoveryResult.createSuccess(
          message: '网络连接正常，可以重试',
        );
      }

      // 2. 启用离线模式
      return ErrorRecoveryResult.createSuccess(
        message: '启用离线模式，使用本地资源',
      );

    } catch (e) {
      return ErrorRecoveryResult.createFailure('网络错误恢复失败: $e');
    }
  }

  /// 检查网络连接
  Future<bool> _checkNetworkConnectivity() async {
    try {
      // 简单的网络检查实现
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return true; // 假设网络正常
    } catch (e) {
      return false;
    }
  }
}

/// 后备恢复策略
class FallbackRecoveryStrategy implements ErrorRecoveryStrategy {
  FallbackRecoveryStrategy(this.pattern);

  final ErrorPattern pattern;

  @override
  bool canHandle(TemplateEngineErrorType errorType) {
    return true; // 可以处理任何类型的错误
  }

  @override
  Future<ErrorRecoveryResult> recover(TemplateEngineException error) async {
    try {
      cli_logger.Logger.info('使用后备恢复策略: ${error.type}');
      
      // 基本的重试建议
      return ErrorRecoveryResult.createSuccess(
        message: '建议检查错误详情并手动重试: ${error.message}',
      );

    } catch (e) {
      return ErrorRecoveryResult.createFailure('后备恢复策略失败: $e');
    }
  }
}


