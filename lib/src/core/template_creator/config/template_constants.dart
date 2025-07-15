/*
---------------------------------------------------------------
File name:          template_constants.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        模板脚手架常量定义 (Template Scaffold Constants)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
*/

/// 模板脚手架常量
class TemplateConstants {
  TemplateConstants._();

  /// 默认版本号
  static const String defaultVersion = '1.0.0';

  /// 默认输出路径
  static const String defaultOutputPath = '.';

  /// 默认作者
  static const String defaultAuthor = 'Ming Status CLI';

  /// 支持的文件扩展名
  static const List<String> supportedExtensions = [
    '.dart',
    '.yaml',
    '.yml',
    '.json',
    '.md',
    '.txt',
    '.xml',
    '.arb',
  ];

  /// Flutter项目目录结构
  static const List<String> flutterDirectories = [
    // 核心源码目录
    'lib',
    'lib/src',
    'lib/src/models',
    'lib/src/services',
    'lib/src/widgets',
    'lib/src/screens',
    'lib/src/utils',
    'lib/src/constants',
    'lib/src/providers',
    'lib/src/repositories',
    'lib/src/core',
    'lib/src/core/router',
    'lib/src/core/theme',
    'lib/src/core/providers',
    'lib/generated', // flutter_gen生成的文件

    // 测试目录
    'test',
    'test/unit',
    'test/widget',
    'integration_test',

    // 资源目录
    'assets',
    'assets/images',
    'assets/icons',
    'assets/fonts',
    'assets/colors',

    // 国际化目录
    'l10n',

    // 平台特定目录
    'android',
    'android/app',
    'android/app/src',
    'android/app/src/main',
    'android/app/src/main/kotlin',
    'ios',
    'ios/Runner',
    'web',
    'windows',
    'macos',
    'linux',

    // 文档和示例
    'docs',
    'example',

    // 模板特定目录
    'templates',
    'config',
  ];

  /// Dart项目目录结构
  static const List<String> dartDirectories = [
    // 核心源码目录
    'lib',
    'lib/src',

    // 测试目录
    'test',

    // 文档和示例
    'docs',
    'example',

    // 模板特定目录
    'templates',
    'config',
  ];

  /// 资源目录结构
  static const List<String> assetDirectories = [
    'assets',
    'assets/images',
    'assets/icons',
    'assets/fonts',
    'assets/colors',
    // 注意: l10n 目录在根目录下，不在 assets 中
  ];

  /// 配置文件名称
  static const Map<String, String> configFiles = {
    'pubspec': 'pubspec.yaml',
    'gitignore': '.gitignore',
    'analysis': 'analysis_options.yaml',
    'l10n': 'l10n.yaml',
    'build': 'build.yaml',
    'flutter_gen': 'flutter_gen.yaml',
    'melos': 'melos.yaml',
    'shorebird': 'shorebird.yaml',
    'readme': 'README.md',
    'changelog': 'CHANGELOG.md',
  };

  /// 模板文件名称
  static const Map<String, String> templateFiles = {
    'main': 'main.dart.template',
    'app': 'app.dart.template',
    'router': 'app_router.dart.template',
    'service': 'service.dart.template',
    'model': 'model.dart.template',
    'widget': 'widget.dart.template',
    'screen': 'screen.dart.template',
    'provider': 'provider.dart.template',
  };

  /// 测试文件名称
  static const Map<String, String> testFiles = {
    'template': 'template_test.dart',
    'unit': 'unit_test.dart',
    'widget': 'widget_test.dart',
    'integration': 'integration_test.dart',
  };

  /// 示例文件名称
  static const Map<String, String> exampleFiles = {
    'example': 'example.dart',
    'readme': 'README.md',
  };

  /// 国际化文件
  static const Map<String, String> l10nFiles = {
    'header': 'header.txt',
    'en_arb': 'app_en.arb',
    'zh_arb': 'app_zh.arb',
  };

  /// 支持的语言代码
  static const List<String> supportedLocales = [
    'en', // 英语
    'zh', // 中文
    'ja', // 日语
    'ko', // 韩语
    'es', // 西班牙语
    'fr', // 法语
    'de', // 德语
    'ru', // 俄语
    'ar', // 阿拉伯语
    'hi', // 印地语
  ];

  /// 默认依赖版本 (平衡策略 - 2025年7月优化)
  static const Map<String, String> defaultDependencyVersions = {
    // Flutter核心 - 使用稳定版本
    'flutter_riverpod': '^2.6.1',
    'riverpod_annotation': '^2.6.1',
    'provider': '^6.1.2', // 添加provider支持
    'flutter_bloc': '^8.1.6', // 添加flutter_bloc支持
    'go_router': '^14.8.1', // 避免v16的潜在问题
    'freezed_annotation': '^2.4.4',
    'json_annotation': '^4.8.1',

    // 网络和存储 - 经过验证的版本
    'dio': '^5.4.0',
    'retrofit': '^4.0.3',
    'shared_preferences': '^2.2.2',
    'hive': '^2.2.3',
    'hive_flutter': '^1.1.0',

    // UI组件
    'flutter_svg': '^2.0.10+1',
    'cached_network_image': '^3.4.1',
    'shimmer': '^3.0.0',

    // 工具库
    'intl': '^0.19.0',
    'equatable': '^2.0.5',
    'uuid': '^4.5.1',

    // Firebase
    'firebase_core': '^3.6.0',
    'firebase_auth': '^5.3.1',
    'cloud_firestore': '^5.4.3',
    'firebase_storage': '^12.3.2',
  };

  /// 默认开发依赖版本 (平衡策略 - 2025年7月优化)
  static const Map<String, String> defaultDevDependencyVersions = {
    // 代码生成 - 稳定版本
    'build_runner': '^2.4.7',
    'freezed': '^2.5.7',
    'json_serializable': '^6.9.0',
    'riverpod_generator': '^2.6.3',
    'retrofit_generator': '^8.2.1',

    // 资源生成
    'flutter_gen_runner': '^5.4.0',

    // 测试
    'mockito': '^5.4.4',
    'build_verify': '^3.1.0',

    // 代码质量 - 更新到兼容版本
    'flutter_lints': '^4.0.0',
    'very_good_analysis': '^6.0.0',

    // 工具
    'flutter_launcher_icons': '^0.14.1',
    'flutter_native_splash': '^2.4.1',

    // 企业级工具
    'melos': '^6.0.0',
  };

  /// 文件头部注释模板
  static const String fileHeaderTemplate = '''
/*
---------------------------------------------------------------
File name:          {fileName}
Author:             {author}
Date created:       {dateCreated}
Last modified:      {lastModified}
Dart Version:       3.2+
Description:        {description}
---------------------------------------------------------------
Change History:
    {dateCreated}: Initial creation - {description};
---------------------------------------------------------------
*/
''';

  /// Git忽略文件模板
  static const String gitignoreTemplate = '''
# Files and directories created by pub
.dart_tool/
.packages
build/
pubspec.lock

# IDE files
.vscode/
.idea/
*.iml

# OS files
.DS_Store
Thumbs.db

# Generated files
*.g.dart
*.freezed.dart
*.gr.dart
*.config.dart
*.mocks.dart
lib/generated/

# Coverage
coverage/

# Flutter/Dart specific
.flutter-plugins
.flutter-plugins-dependencies
.metadata

# Platform specific
android/.gradle/
android/app/debug/
android/app/profile/
android/app/release/
ios/Flutter/flutter_export_environment.sh
ios/Pods/
ios/.symlinks/
macos/Flutter/ephemeral/
windows/flutter/ephemeral/
linux/flutter/ephemeral/

# Web
web/favicon.png

# Shorebird
.shorebird/

# Melos
.melos_tool/
''';

  /// 许可证模板
  static const String mitLicenseTemplate = '''
MIT License

Copyright (c) {year} {author}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''';

  /// 获取当前日期字符串
  static String get currentDate =>
      DateTime.now().toIso8601String().split('T')[0];

  /// 获取当前年份
  static String get currentYear => DateTime.now().year.toString();

  /// 生成文件头部注释
  static String generateFileHeader({
    required String fileName,
    required String author,
    required String description,
    String? dateCreated,
    String? lastModified,
  }) {
    final now = currentDate;
    return fileHeaderTemplate
        .replaceAll('{fileName}', fileName)
        .replaceAll('{author}', author)
        .replaceAll('{dateCreated}', dateCreated ?? now)
        .replaceAll('{lastModified}', lastModified ?? now)
        .replaceAll('{description}', description);
  }

  /// 生成MIT许可证
  static String generateMitLicense({
    required String author,
    String? year,
  }) {
    return mitLicenseTemplate
        .replaceAll('{year}', year ?? currentYear)
        .replaceAll('{author}', author);
  }
}
