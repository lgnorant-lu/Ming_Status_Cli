/*
---------------------------------------------------------------
File name:          cross_platform_index_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/15
Last modified:      2025/07/15
Dart Version:       3.2+
Description:        跨平台支持模块索引生成器 (Cross Platform Index Generator)
---------------------------------------------------------------
Change History:
    2025/07/15: Initial creation - 跨平台支持模块索引生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/scaffold_config.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/base/base_code_generator.dart';

/// CrossPlatformIndex跨平台模块索引文件生成器
///
/// 生成跨平台模块索引文件
class CrossPlatformIndexGenerator extends BaseCodeGenerator {
  /// 创建CrossPlatformIndex生成器实例
  const CrossPlatformIndexGenerator();

  @override
  String getFileName(ScaffoldConfig config) {
    return 'index.dart';
  }

  @override
  String getRelativePath(ScaffoldConfig config) {
    return 'lib/src/cross_platform';
  }

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.write(
      generateFileHeader(
        getFileName(config),
        config,
        '${config.templateName}跨平台支持模块导出文件',
      ),
    );

    // 生成导出语句
    _generateExports(buffer, config);

    return buffer.toString();
  }

  /// 生成导出语句
  void _generateExports(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('/// ${config.templateName}跨平台支持模块');
    buffer.writeln('///');
    buffer.writeln('/// 提供跨平台功能支持，包括：');
    buffer.writeln('/// - 平台检测');
    buffer.writeln('/// - 平台特定功能');
    buffer.writeln('/// - 跨平台兼容性处理');
    buffer.writeln();

    // 基础导出
    buffer.writeln('// 平台检测');
    buffer.writeln('export \'platform_detector.dart\';');
    buffer.writeln();

    buffer.writeln('// 平台常量');
    buffer.writeln('export \'platform_constants.dart\';');
  }
}
