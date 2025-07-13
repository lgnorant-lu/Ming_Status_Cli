/*
---------------------------------------------------------------
File name:          base_code_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        代码文件生成器基类
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 代码文件生成器基类;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:path/path.dart' as path;

/// 代码文件生成器基类
///
/// 为生成实际可用的代码文件提供基础功能
abstract class BaseCodeGenerator {
  /// 创建代码文件生成器实例
  const BaseCodeGenerator();

  /// 获取生成的文件名
  String getFileName(ScaffoldConfig config);

  /// 获取文件相对路径（相对于lib目录）
  String getRelativePath(ScaffoldConfig config);

  /// 生成文件内容
  String generateContent(ScaffoldConfig config);

  /// 生成文件头部注释
  String generateFileHeader(
    String fileName,
    ScaffoldConfig config,
    String description,
  ) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return '''
/*
---------------------------------------------------------------
File name:          $fileName
Author:             ${config.author ?? 'Unknown'}
Date created:       $dateStr
Last modified:      $dateStr
Dart Version:       3.2+
Description:        $description
---------------------------------------------------------------
Change History:
    $dateStr: Initial creation - $description;
---------------------------------------------------------------
*/

''';
  }

  /// 生成代码文件
  ///
  /// [templatePath] 模板根路径
  /// [config] 脚手架配置
  /// 返回生成的文件相对路径
  Future<String> generateFile(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final fileName = getFileName(config);
    final relativePath = getRelativePath(config);
    final content = generateContent(config);
    final fullPath = path.join(templatePath, relativePath, fileName);

    try {
      // 确保目录存在
      final directory = Directory(path.dirname(fullPath));
      await directory.create(recursive: true);

      final file = File(fullPath);
      await file.writeAsString(content);

      return path.join(relativePath, fileName);
    } catch (e) {
      throw Exception('Failed to generate code file: $fileName - $e');
    }
  }

  /// 生成导入语句
  String generateImports(List<String> imports) {
    if (imports.isEmpty) return '';

    final buffer = StringBuffer();

    // Dart 核心库导入
    final dartImports = imports.where((i) => i.startsWith('dart:')).toList();
    if (dartImports.isNotEmpty) {
      for (final import in dartImports) {
        buffer.writeln("import '$import';");
      }
      buffer.writeln();
    }

    // Flutter 导入
    final flutterImports =
        imports.where((i) => i.startsWith('package:flutter')).toList();
    if (flutterImports.isNotEmpty) {
      for (final import in flutterImports) {
        buffer.writeln("import '$import';");
      }
      buffer.writeln();
    }

    // 第三方包导入
    final packageImports = imports
        .where(
            (i) => i.startsWith('package:') && !i.startsWith('package:flutter'),)
        .toList();
    if (packageImports.isNotEmpty) {
      for (final import in packageImports) {
        buffer.writeln("import '$import';");
      }
      buffer.writeln();
    }

    // 相对导入
    final relativeImports = imports
        .where((i) => !i.startsWith('dart:') && !i.startsWith('package:'))
        .toList();
    if (relativeImports.isNotEmpty) {
      for (final import in relativeImports) {
        buffer.writeln("import '$import';");
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// 生成类文档注释
  String generateClassDocumentation(
    String className,
    String description, {
    List<String> examples = const [],
    List<String> seeAlso = const [],
  }) {
    final buffer = StringBuffer();

    buffer.writeln('/// $description');
    buffer.writeln('///');

    if (examples.isNotEmpty) {
      buffer.writeln('/// ## 使用示例');
      buffer.writeln('///');
      for (final example in examples) {
        buffer.writeln('/// ```dart');
        buffer.writeln('/// $example');
        buffer.writeln('/// ```');
        buffer.writeln('///');
      }
    }

    if (seeAlso.isNotEmpty) {
      buffer.writeln('/// ## 相关类');
      buffer.writeln('///');
      for (final see in seeAlso) {
        buffer.writeln('/// * [$see]');
      }
      buffer.writeln('///');
    }

    return buffer.toString();
  }

  /// 将模板名称转换为正确的类名格式
  String formatClassName(String templateName, String suffix) {
    // 将下划线分隔的名称转换为驼峰命名
    final parts = templateName.split('_');
    final capitalizedParts = parts.map((part) =>
        part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : part,);
    return capitalizedParts.join() + suffix;
  }
}
