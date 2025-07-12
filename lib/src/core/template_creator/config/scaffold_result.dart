/*
---------------------------------------------------------------
File name:          scaffold_result.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        模板脚手架生成结果类 (Template Scaffold Generation Result)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
*/

/// 脚手架生成结果
///
/// 包含脚手架生成的结果信息
class ScaffoldResult {
  /// 创建脚手架生成结果实例
  const ScaffoldResult({
    required this.success,
    required this.templatePath,
    this.generatedFiles = const [],
    this.errors = const [],
    this.warnings = const [],
    this.metadata,
  });

  /// 从Map创建结果
  factory ScaffoldResult.fromMap(Map<String, dynamic> map) {
    return ScaffoldResult(
      success: map['success'] as bool,
      templatePath: map['templatePath'] as String,
      generatedFiles: List<String>.from(map['generatedFiles'] as List),
      errors: List<String>.from(map['errors'] as List),
      warnings: List<String>.from(map['warnings'] as List),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 创建成功结果
  factory ScaffoldResult.success({
    required String templatePath,
    required List<String> generatedFiles,
    List<String> warnings = const [],
    Map<String, dynamic>? metadata,
  }) {
    return ScaffoldResult(
      success: true,
      templatePath: templatePath,
      generatedFiles: generatedFiles,
      warnings: warnings,
      metadata: metadata,
    );
  }

  /// 创建失败结果
  factory ScaffoldResult.failure({
    required List<String> errors,
    String templatePath = '',
    List<String> warnings = const [],
    Map<String, dynamic>? metadata,
  }) {
    return ScaffoldResult(
      success: false,
      templatePath: templatePath,
      errors: errors,
      warnings: warnings,
      metadata: metadata,
    );
  }

  /// 创建部分成功结果
  factory ScaffoldResult.partial({
    required String templatePath,
    required List<String> generatedFiles,
    required List<String> errors,
    List<String> warnings = const [],
    Map<String, dynamic>? metadata,
  }) {
    return ScaffoldResult(
      success: generatedFiles.isNotEmpty,
      templatePath: templatePath,
      generatedFiles: generatedFiles,
      errors: errors,
      warnings: warnings,
      metadata: metadata,
    );
  }

  /// 是否成功
  final bool success;

  /// 模板路径
  final String templatePath;

  /// 生成的文件列表
  final List<String> generatedFiles;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;

  /// 额外的元数据信息
  final Map<String, dynamic>? metadata;

  /// 是否有错误
  bool get hasErrors => errors.isNotEmpty;

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;

  /// 是否完全成功（无错误无警告）
  bool get isCompleteSuccess => success && !hasErrors && !hasWarnings;

  /// 是否部分成功（有生成文件但有错误或警告）
  bool get isPartialSuccess => success && (hasErrors || hasWarnings);

  /// 生成文件数量
  int get fileCount => generatedFiles.length;

  /// 错误数量
  int get errorCount => errors.length;

  /// 警告数量
  int get warningCount => warnings.length;

  /// 合并另一个结果
  ScaffoldResult merge(ScaffoldResult other) {
    return ScaffoldResult(
      success: success && other.success,
      templatePath: templatePath.isNotEmpty ? templatePath : other.templatePath,
      generatedFiles: [...generatedFiles, ...other.generatedFiles],
      errors: [...errors, ...other.errors],
      warnings: [...warnings, ...other.warnings],
      metadata: {
        ...?metadata,
        ...?other.metadata,
      },
    );
  }

  /// 添加生成的文件
  ScaffoldResult addGeneratedFile(String file) {
    return ScaffoldResult(
      success: success,
      templatePath: templatePath,
      generatedFiles: [...generatedFiles, file],
      errors: errors,
      warnings: warnings,
      metadata: metadata,
    );
  }

  /// 添加生成的文件列表
  ScaffoldResult addGeneratedFiles(List<String> files) {
    return ScaffoldResult(
      success: success,
      templatePath: templatePath,
      generatedFiles: [...generatedFiles, ...files],
      errors: errors,
      warnings: warnings,
      metadata: metadata,
    );
  }

  /// 添加错误
  ScaffoldResult addError(String error) {
    return ScaffoldResult(
      success: false,
      templatePath: templatePath,
      generatedFiles: generatedFiles,
      errors: [...errors, error],
      warnings: warnings,
      metadata: metadata,
    );
  }

  /// 添加警告
  ScaffoldResult addWarning(String warning) {
    return ScaffoldResult(
      success: success,
      templatePath: templatePath,
      generatedFiles: generatedFiles,
      errors: errors,
      warnings: [...warnings, warning],
      metadata: metadata,
    );
  }

  /// 设置元数据
  ScaffoldResult setMetadata(String key, dynamic value) {
    final newMetadata = Map<String, dynamic>.from(metadata ?? {});
    newMetadata[key] = value;
    return ScaffoldResult(
      success: success,
      templatePath: templatePath,
      generatedFiles: generatedFiles,
      errors: errors,
      warnings: warnings,
      metadata: newMetadata,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'templatePath': templatePath,
      'generatedFiles': generatedFiles,
      'errors': errors,
      'warnings': warnings,
      'metadata': metadata,
      'fileCount': fileCount,
      'errorCount': errorCount,
      'warningCount': warningCount,
      'isCompleteSuccess': isCompleteSuccess,
      'isPartialSuccess': isPartialSuccess,
    };
  }

  /// 生成摘要报告
  String generateSummary() {
    final buffer = StringBuffer()
      ..writeln('=== 脚手架生成结果摘要 ===')
      ..writeln('状态: ${success ? '成功' : '失败'}')
      ..writeln('模板路径: $templatePath')
      ..writeln('生成文件数: $fileCount');

    if (hasErrors) {
      buffer.writeln('错误数: $errorCount');
    }

    if (hasWarnings) {
      buffer.writeln('警告数: $warningCount');
    }

    if (generatedFiles.isNotEmpty) {
      buffer.writeln('\n生成的文件:');
      for (final file in generatedFiles) {
        buffer.writeln('  ✓ $file');
      }
    }

    if (hasErrors) {
      buffer.writeln('\n错误信息:');
      for (final error in errors) {
        buffer.writeln('  ✗ $error');
      }
    }

    if (hasWarnings) {
      buffer.writeln('\n警告信息:');
      for (final warning in warnings) {
        buffer.writeln('  ⚠ $warning');
      }
    }

    return buffer.toString();
  }

  @override
  String toString() {
    return 'ScaffoldResult('
        'success: $success, '
        'templatePath: $templatePath, '
        'fileCount: $fileCount, '
        'errorCount: $errorCount, '
        'warningCount: $warningCount'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScaffoldResult &&
        other.success == success &&
        other.templatePath == templatePath &&
        other.generatedFiles.length == generatedFiles.length &&
        other.errors.length == errors.length &&
        other.warnings.length == warnings.length;
  }

  @override
  int get hashCode {
    return Object.hash(
      success,
      templatePath,
      generatedFiles.length,
      errors.length,
      warnings.length,
    );
  }
}
