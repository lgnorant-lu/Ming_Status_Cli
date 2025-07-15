/*
---------------------------------------------------------------
File name:          platform_constants_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/15
Last modified:      2025/07/15
Dart Version:       3.2+
Description:        平台常量生成器 (Platform Constants Generator)
---------------------------------------------------------------
Change History:
    2025/07/15: Initial creation - 平台常量生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/scaffold_config.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/base/base_code_generator.dart';

/// PlatformConstants平台常量文件生成器
///
/// 生成平台常量文件
class PlatformConstantsGenerator extends BaseCodeGenerator {
  /// 创建PlatformConstants生成器实例
  const PlatformConstantsGenerator();

  @override
  String getFileName(ScaffoldConfig config) {
    return 'platform_constants.dart';
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
        '${config.templateName}平台常量定义',
      ),
    );

    // 生成平台常量类
    _generatePlatformConstants(buffer, config);

    return buffer.toString();
  }

  /// 生成平台常量类
  void _generatePlatformConstants(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('/// 平台相关常量定义');
    buffer.writeln('class PlatformConstants {');
    buffer.writeln('  /// 私有构造函数');
    buffer.writeln('  PlatformConstants._();');
    buffer.writeln();

    buffer.writeln('  /// 支持的平台列表');
    buffer.writeln('  static const List<String> supportedPlatforms = [');
    buffer.writeln('    \'android\',');
    buffer.writeln('    \'ios\',');
    buffer.writeln('    \'web\',');
    buffer.writeln('    \'windows\',');
    buffer.writeln('    \'macos\',');
    buffer.writeln('    \'linux\',');
    buffer.writeln('  ];');
    buffer.writeln();

    buffer.writeln('  /// 移动平台列表');
    buffer.writeln('  static const List<String> mobilePlatforms = [');
    buffer.writeln('    \'android\',');
    buffer.writeln('    \'ios\',');
    buffer.writeln('  ];');
    buffer.writeln();

    buffer.writeln('  /// 桌面平台列表');
    buffer.writeln('  static const List<String> desktopPlatforms = [');
    buffer.writeln('    \'windows\',');
    buffer.writeln('    \'macos\',');
    buffer.writeln('    \'linux\',');
    buffer.writeln('  ];');
    buffer.writeln();

    buffer.writeln('  /// 平台特定配置');
    buffer.writeln('  static const Map<String, Map<String, dynamic>> platformConfigs = {');
    buffer.writeln('    \'android\': {');
    buffer.writeln('      \'minSdkVersion\': 21,');
    buffer.writeln('      \'targetSdkVersion\': 34,');
    buffer.writeln('      \'compileSdkVersion\': 34,');
    buffer.writeln('    },');
    buffer.writeln('    \'ios\': {');
    buffer.writeln('      \'deploymentTarget\': \'12.0\',');
    buffer.writeln('      \'swiftVersion\': \'5.0\',');
    buffer.writeln('    },');
    buffer.writeln('    \'web\': {');
    buffer.writeln('      \'renderer\': \'canvaskit\',');
    buffer.writeln('      \'buildMode\': \'release\',');
    buffer.writeln('    },');
    buffer.writeln('  };');
    buffer.writeln('}');
  }
}
