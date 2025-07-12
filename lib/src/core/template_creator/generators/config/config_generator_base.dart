/*
---------------------------------------------------------------
File name:          config_generator_base.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        配置文件生成器基类 (Configuration File Generator Base)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:path/path.dart' as path;

/// 配置文件生成器基类
///
/// 定义生成配置文件的通用接口和基础功能
abstract class ConfigGeneratorBase {
  /// 创建配置文件生成器实例
  const ConfigGeneratorBase();

  /// 获取配置文件名称
  ///
  /// 子类需要实现此方法，返回配置文件的名称
  String getFileName();

  /// 生成配置内容
  ///
  /// 子类需要实现此方法，返回配置文件的内容
  /// [config] 脚手架配置
  String generateContent(ScaffoldConfig config);

  /// 生成配置文件
  ///
  /// [templatePath] 模板根路径
  /// [config] 脚手架配置
  /// 返回生成的文件路径
  Future<String> generateFile(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final fileName = getFileName();
    final content = generateContent(config);
    final filePath = path.join(templatePath, fileName);
    
    try {
      final file = File(filePath);
      await file.writeAsString(content);
      return filePath;
    } catch (e) {
      throw ConfigGenerationException(
        'Failed to generate config file: $fileName',
        originalException: e,
      );
    }
  }

  /// 验证配置文件
  ///
  /// [templatePath] 模板根路径
  /// [config] 脚手架配置
  /// 返回验证结果
  Future<ConfigValidationResult> validateFile(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final fileName = getFileName();
    final filePath = path.join(templatePath, fileName);
    final file = File(filePath);
    
    if (!await file.exists()) {
      return ConfigValidationResult.missing(fileName);
    }

    try {
      final content = await file.readAsString();
      final expectedContent = generateContent(config);
      
      if (content.trim() == expectedContent.trim()) {
        return ConfigValidationResult.valid(fileName);
      } else {
        return ConfigValidationResult.outdated(fileName);
      }
    } catch (e) {
      return ConfigValidationResult.error(fileName, e.toString());
    }
  }

  /// 更新配置文件
  ///
  /// [templatePath] 模板根路径
  /// [config] 脚手架配置
  /// [force] 是否强制更新
  /// 返回是否更新成功
  Future<bool> updateFile(
    String templatePath,
    ScaffoldConfig config, {
    bool force = false,
  }) async {
    final validation = await validateFile(templatePath, config);
    
    if (validation.isValid && !force) {
      return false; // 文件已是最新，无需更新
    }

    try {
      await generateFile(templatePath, config);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 备份配置文件
  ///
  /// [templatePath] 模板根路径
  /// 返回备份文件路径，如果文件不存在返回null
  Future<String?> backupFile(String templatePath) async {
    final fileName = getFileName();
    final filePath = path.join(templatePath, fileName);
    final file = File(filePath);
    
    if (!await file.exists()) {
      return null;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '$filePath.backup.$timestamp';
    
    try {
      await file.copy(backupPath);
      return backupPath;
    } catch (e) {
      throw ConfigGenerationException(
        'Failed to backup config file: $fileName',
        originalException: e,
      );
    }
  }

  /// 恢复配置文件
  ///
  /// [templatePath] 模板根路径
  /// [backupPath] 备份文件路径
  /// 返回是否恢复成功
  Future<bool> restoreFile(String templatePath, String backupPath) async {
    final fileName = getFileName();
    final filePath = path.join(templatePath, fileName);
    final backupFile = File(backupPath);
    
    if (!await backupFile.exists()) {
      return false;
    }

    try {
      await backupFile.copy(filePath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取配置文件信息
  ///
  /// [templatePath] 模板根路径
  /// 返回配置文件信息
  Future<ConfigFileInfo> getFileInfo(String templatePath) async {
    final fileName = getFileName();
    final filePath = path.join(templatePath, fileName);
    final file = File(filePath);
    
    if (!await file.exists()) {
      return ConfigFileInfo(
        fileName: fileName,
        filePath: filePath,
        exists: false,
        size: 0,
      );
    }

    try {
      final stat = await file.stat();
      return ConfigFileInfo(
        fileName: fileName,
        filePath: filePath,
        exists: true,
        size: stat.size,
        lastModified: stat.modified,
      );
    } catch (e) {
      return ConfigFileInfo(
        fileName: fileName,
        filePath: filePath,
        exists: false,
        size: 0,
      );
    }
  }
}

/// 配置验证结果
class ConfigValidationResult {
  /// 创建配置验证结果实例
  const ConfigValidationResult({
    required this.fileName,
    required this.status,
    this.errorMessage,
  });

  /// 创建有效结果
  factory ConfigValidationResult.valid(String fileName) {
    return ConfigValidationResult(
      fileName: fileName,
      status: ConfigValidationStatus.valid,
    );
  }

  /// 创建缺失结果
  factory ConfigValidationResult.missing(String fileName) {
    return ConfigValidationResult(
      fileName: fileName,
      status: ConfigValidationStatus.missing,
    );
  }

  /// 创建过期结果
  factory ConfigValidationResult.outdated(String fileName) {
    return ConfigValidationResult(
      fileName: fileName,
      status: ConfigValidationStatus.outdated,
    );
  }

  /// 创建错误结果
  factory ConfigValidationResult.error(String fileName, String errorMessage) {
    return ConfigValidationResult(
      fileName: fileName,
      status: ConfigValidationStatus.error,
      errorMessage: errorMessage,
    );
  }

  /// 文件名称
  final String fileName;

  /// 验证状态
  final ConfigValidationStatus status;

  /// 错误消息
  final String? errorMessage;

  /// 是否有效
  bool get isValid => status == ConfigValidationStatus.valid;

  /// 是否缺失
  bool get isMissing => status == ConfigValidationStatus.missing;

  /// 是否过期
  bool get isOutdated => status == ConfigValidationStatus.outdated;

  /// 是否有错误
  bool get hasError => status == ConfigValidationStatus.error;

  @override
  String toString() {
    return 'ConfigValidationResult('
        'fileName: $fileName, '
        'status: $status'
        '${errorMessage != null ? ', error: $errorMessage' : ''}'
        ')';
  }
}

/// 配置验证状态
enum ConfigValidationStatus {
  /// 有效
  valid,
  /// 缺失
  missing,
  /// 过期
  outdated,
  /// 错误
  error,
}

/// 配置文件信息
class ConfigFileInfo {
  /// 创建配置文件信息实例
  const ConfigFileInfo({
    required this.fileName,
    required this.filePath,
    required this.exists,
    required this.size,
    this.lastModified,
  });

  /// 文件名称
  final String fileName;

  /// 文件路径
  final String filePath;

  /// 是否存在
  final bool exists;

  /// 文件大小（字节）
  final int size;

  /// 最后修改时间
  final DateTime? lastModified;

  /// 格式化的文件大小
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// 格式化的最后修改时间
  String get formattedLastModified {
    if (lastModified == null) return 'Unknown';
    return lastModified!.toIso8601String().split('T')[0];
  }

  @override
  String toString() {
    return 'ConfigFileInfo('
        'fileName: $fileName, '
        'exists: $exists, '
        'size: $formattedSize'
        '${lastModified != null ? ', modified: $formattedLastModified' : ''}'
        ')';
  }
}

/// 配置生成异常
class ConfigGenerationException implements Exception {
  /// 创建配置生成异常实例
  const ConfigGenerationException(
    this.message, {
    this.originalException,
  });

  /// 错误消息
  final String message;

  /// 原始异常
  final Object? originalException;

  @override
  String toString() {
    if (originalException != null) {
      return 'ConfigGenerationException: $message\nCaused by: $originalException';
    }
    return 'ConfigGenerationException: $message';
  }
}
