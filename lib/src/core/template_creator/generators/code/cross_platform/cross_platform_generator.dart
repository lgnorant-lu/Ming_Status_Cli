/*
---------------------------------------------------------------
File name:          cross_platform_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/15
Last modified:      2025/07/15
Dart Version:       3.2+
Description:        跨平台支持生成器 (Cross Platform Generator)
---------------------------------------------------------------
Change History:
    2025/07/15: Initial creation - 跨平台支持生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/scaffold_config.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/base/base_code_generator.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:ming_status_cli/src/utils/string_utils.dart';

/// CrossPlatform跨平台支持文件生成器
///
/// 生成跨平台支持文件
class CrossPlatformGenerator extends BaseCodeGenerator {
  /// 创建CrossPlatform生成器实例
  const CrossPlatformGenerator();

  @override
  String getFileName(ScaffoldConfig config) {
    return 'platform_detector.dart';
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
        '${config.templateName}跨平台支持模块',
      ),
    );

    // 生成平台检测类
    _generatePlatformDetector(buffer, config);

    return buffer.toString();
  }

  /// 生成平台检测类
  void _generatePlatformDetector(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('/// ${config.templateName}跨平台支持模块');
    buffer.writeln('///');
    buffer.writeln('/// 提供跨平台功能支持，包括：');
    buffer.writeln('/// - 平台检测');
    buffer.writeln('/// - 平台特定功能');
    buffer.writeln('/// - 跨平台兼容性处理');
    buffer.writeln();

    buffer.writeln('import \'dart:io\' show Platform;');
    buffer.writeln('import \'package:flutter/foundation.dart\' show kIsWeb;');
    buffer.writeln();

    buffer.writeln('/// 平台检测工具类');
    buffer.writeln('class PlatformDetector {');
    buffer.writeln('  /// 私有构造函数');
    buffer.writeln('  PlatformDetector._();');
    buffer.writeln();

    buffer.writeln('  /// 是否为Web平台');
    buffer.writeln('  static bool get isWeb => kIsWeb;');
    buffer.writeln();

    buffer.writeln('  /// 是否为移动平台');
    buffer.writeln('  static bool get isMobile => isAndroid || isIOS;');
    buffer.writeln();

    buffer.writeln('  /// 是否为桌面平台');
    buffer.writeln(
        '  static bool get isDesktop => isWindows || isMacOS || isLinux;');
    buffer.writeln();

    buffer.writeln('  /// 是否为Android平台');
    buffer.writeln(
        '  static bool get isAndroid => !kIsWeb && Platform.isAndroid;');
    buffer.writeln();

    buffer.writeln('  /// 是否为iOS平台');
    buffer.writeln('  static bool get isIOS => !kIsWeb && Platform.isIOS;');
    buffer.writeln();

    buffer.writeln('  /// 是否为Windows平台');
    buffer.writeln(
        '  static bool get isWindows => !kIsWeb && Platform.isWindows;');
    buffer.writeln();

    buffer.writeln('  /// 是否为macOS平台');
    buffer.writeln('  static bool get isMacOS => !kIsWeb && Platform.isMacOS;');
    buffer.writeln();

    buffer.writeln('  /// 是否为Linux平台');
    buffer.writeln('  static bool get isLinux => !kIsWeb && Platform.isLinux;');
    buffer.writeln();

    buffer.writeln('  /// 获取当前平台名称');
    buffer.writeln('  static String get platformName {');
    buffer.writeln('    if (kIsWeb) return \'web\';');
    buffer.writeln('    if (Platform.isAndroid) return \'android\';');
    buffer.writeln('    if (Platform.isIOS) return \'ios\';');
    buffer.writeln('    if (Platform.isWindows) return \'windows\';');
    buffer.writeln('    if (Platform.isMacOS) return \'macos\';');
    buffer.writeln('    if (Platform.isLinux) return \'linux\';');
    buffer.writeln('    return \'unknown\';');
    buffer.writeln('  }');
    buffer.writeln('}');
  }
}
