/*
---------------------------------------------------------------
File name:          template_generator_base.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        模板文件生成器基类 (Template File Generator Base)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加模板变量替换引擎
    - [ ] 支持条件模板生成
    - [ ] 添加模板继承机制
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:path/path.dart' as path;

/// 模板文件生成器基类
///
/// 定义生成模板文件的通用接口和基础功能
abstract class TemplateGeneratorBase {
  /// 创建模板文件生成器实例
  const TemplateGeneratorBase();

  /// 获取模板文件名称
  ///
  /// 子类需要实现此方法，返回模板文件的名称
  String getTemplateFileName();

  /// 获取输出文件名称
  ///
  /// 子类需要实现此方法，返回输出文件的名称
  String getOutputFileName(ScaffoldConfig config);

  /// 生成模板内容
  ///
  /// 子类需要实现此方法，返回模板文件的内容
  /// [config] 脚手架配置
  String generateContent(ScaffoldConfig config);

  /// 获取模板变量
  ///
  /// 子类可以重写此方法，返回模板中使用的变量
  Map<String, String> getTemplateVariables(ScaffoldConfig config) {
    return {
      'templateName': config.templateName,
      'author': config.author,
      'description': config.description,
      'version': config.version,
      'currentDate': TemplateConstants.currentDate,
      'currentYear': TemplateConstants.currentYear,
      'packageName': _toPackageName(config.templateName),
      'className': _toClassName(config.templateName),
      'camelCaseName': _toCamelCase(config.templateName),
    };
  }

  /// 生成模板文件
  ///
  /// [templatePath] 模板根路径
  /// [config] 脚手架配置
  /// 返回生成的文件路径
  Future<String> generateFile(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final fileName = getOutputFileName(config);
    final content = generateContent(config);
    final filePath = path.join(templatePath, 'templates', fileName);
    
    try {
      // 确保目录存在
      final directory = Directory(path.dirname(filePath));
      await directory.create(recursive: true);
      
      final file = File(filePath);
      await file.writeAsString(content);
      return filePath;
    } catch (e) {
      throw TemplateGenerationException(
        'Failed to generate template file: $fileName',
        originalException: e,
      );
    }
  }

  /// 替换模板变量
  ///
  /// [content] 模板内容
  /// [variables] 变量映射
  /// 返回替换后的内容
  String replaceTemplateVariables(String content, Map<String, String> variables) {
    var result = content;
    for (final entry in variables.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  /// 验证模板文件
  ///
  /// [templatePath] 模板根路径
  /// [config] 脚手架配置
  /// 返回验证结果
  Future<TemplateValidationResult> validateFile(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final fileName = getOutputFileName(config);
    final filePath = path.join(templatePath, 'templates', fileName);
    final file = File(filePath);
    
    if (!await file.exists()) {
      return TemplateValidationResult.missing(fileName);
    }

    try {
      final content = await file.readAsString();
      final expectedContent = generateContent(config);
      
      if (content.trim() == expectedContent.trim()) {
        return TemplateValidationResult.valid(fileName);
      } else {
        return TemplateValidationResult.outdated(fileName);
      }
    } catch (e) {
      return TemplateValidationResult.error(fileName, e.toString());
    }
  }

  /// 获取模板文件信息
  ///
  /// [templatePath] 模板根路径
  /// [config] 脚手架配置
  /// 返回模板文件信息
  Future<TemplateFileInfo> getFileInfo(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final fileName = getOutputFileName(config);
    final filePath = path.join(templatePath, 'templates', fileName);
    final file = File(filePath);
    
    if (!await file.exists()) {
      return TemplateFileInfo(
        fileName: fileName,
        filePath: filePath,
        exists: false,
        size: 0,
      );
    }

    try {
      final stat = await file.stat();
      return TemplateFileInfo(
        fileName: fileName,
        filePath: filePath,
        exists: true,
        size: stat.size,
        lastModified: stat.modified,
      );
    } catch (e) {
      return TemplateFileInfo(
        fileName: fileName,
        filePath: filePath,
        exists: false,
        size: 0,
      );
    }
  }

  /// 生成文件头部注释
  ///
  /// [fileName] 文件名
  /// [config] 脚手架配置
  /// [description] 文件描述
  /// 返回头部注释
  String generateFileHeader(
    String fileName,
    ScaffoldConfig config,
    String description,
  ) {
    return TemplateConstants.generateFileHeader(
      fileName: fileName,
      author: config.author,
      description: description,
    );
  }

  /// 转换为包名格式
  String _toPackageName(String name) {
    return name.toLowerCase().replaceAll(RegExp('[^a-z0-9_]'), '_');
  }

  /// 转换为类名格式
  String _toClassName(String name) {
    return name
        .split(RegExp('[^a-zA-Z0-9]'))
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }

  /// 转换为驼峰命名格式
  String _toCamelCase(String name) {
    final className = _toClassName(name);
    return className.isEmpty ? '' : className[0].toLowerCase() + className.substring(1);
  }
}

/// 模板验证结果
class TemplateValidationResult {
  /// 创建模板验证结果实例
  const TemplateValidationResult({
    required this.fileName,
    required this.status,
    this.errorMessage,
  });

  /// 创建有效结果
  factory TemplateValidationResult.valid(String fileName) {
    return TemplateValidationResult(
      fileName: fileName,
      status: TemplateValidationStatus.valid,
    );
  }

  /// 创建缺失结果
  factory TemplateValidationResult.missing(String fileName) {
    return TemplateValidationResult(
      fileName: fileName,
      status: TemplateValidationStatus.missing,
    );
  }

  /// 创建过期结果
  factory TemplateValidationResult.outdated(String fileName) {
    return TemplateValidationResult(
      fileName: fileName,
      status: TemplateValidationStatus.outdated,
    );
  }

  /// 创建错误结果
  factory TemplateValidationResult.error(String fileName, String errorMessage) {
    return TemplateValidationResult(
      fileName: fileName,
      status: TemplateValidationStatus.error,
      errorMessage: errorMessage,
    );
  }

  /// 文件名称
  final String fileName;

  /// 验证状态
  final TemplateValidationStatus status;

  /// 错误消息
  final String? errorMessage;

  /// 是否有效
  bool get isValid => status == TemplateValidationStatus.valid;

  /// 是否缺失
  bool get isMissing => status == TemplateValidationStatus.missing;

  /// 是否过期
  bool get isOutdated => status == TemplateValidationStatus.outdated;

  /// 是否有错误
  bool get hasError => status == TemplateValidationStatus.error;

  @override
  String toString() {
    return 'TemplateValidationResult('
        'fileName: $fileName, '
        'status: $status'
        '${errorMessage != null ? ', error: $errorMessage' : ''}'
        ')';
  }
}

/// 模板验证状态
enum TemplateValidationStatus {
  /// 有效
  valid,
  /// 缺失
  missing,
  /// 过期
  outdated,
  /// 错误
  error,
}

/// 模板文件信息
class TemplateFileInfo {
  /// 创建模板文件信息实例
  const TemplateFileInfo({
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

  @override
  String toString() {
    return 'TemplateFileInfo('
        'fileName: $fileName, '
        'exists: $exists, '
        'size: $formattedSize'
        ')';
  }
}

/// 模板生成异常
class TemplateGenerationException implements Exception {
  /// 创建模板生成异常实例
  const TemplateGenerationException(
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
      return 'TemplateGenerationException: $message\nCaused by: $originalException';
    }
    return 'TemplateGenerationException: $message';
  }
}
