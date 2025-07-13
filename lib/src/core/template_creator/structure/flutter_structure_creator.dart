/*
---------------------------------------------------------------
File name:          flutter_structure_creator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        Flutter项目目录结构创建器 (Flutter Project Directory Structure Creator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/structure/directory_creator.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// Flutter项目目录结构创建器
///
/// 负责创建Flutter项目的标准目录结构
class FlutterStructureCreator extends DirectoryCreator {
  /// 创建Flutter项目目录结构创建器实例
  const FlutterStructureCreator();

  @override
  List<String> getDirectories(ScaffoldConfig config) {
    final directories = <String>[];

    // 添加基础Flutter目录
    directories.addAll(_getBaseDirectories());

    // 根据平台添加特定目录
    directories.addAll(_getPlatformDirectories(config.platform));

    // 根据模板类型添加特定目录
    directories.addAll(_getTemplateTypeDirectories(config.templateType));

    // 根据复杂度添加目录
    directories.addAll(_getComplexityDirectories(config.complexity));

    // 添加可选功能目录
    if (config.includeTests) {
      directories.addAll(_getTestDirectories());
    }

    if (config.includeDocumentation) {
      directories.addAll(_getDocumentationDirectories());
    }

    if (config.includeExamples) {
      directories.addAll(_getExampleDirectories());
    }

    return directories.toSet().toList()..sort();
  }

  /// 获取基础目录结构
  List<String> _getBaseDirectories() {
    return [
      // 核心源码目录
      'lib',
      'lib/src',
      'lib/src/models',
      'lib/src/services',
      'lib/src/utils',
      'lib/src/constants',
      'lib/src/providers',
      'lib/src/core',
      'lib/generated', // flutter_gen生成的文件

      // 资源目录
      'assets',
      'assets/images',
      'assets/icons',

      // 国际化目录
      'l10n',

      // 模板目录
      'templates',
      'config',
    ];
  }

  /// 获取平台特定目录
  List<String> _getPlatformDirectories(TemplatePlatform platform) {
    final directories = <String>[];

    switch (platform) {
      case TemplatePlatform.mobile:
        directories.addAll([
          'android',
          'android/app',
          'android/app/src',
          'android/app/src/main',
          'android/app/src/main/kotlin',
          'ios',
          'ios/Runner',
        ]);

      case TemplatePlatform.web:
        directories.addAll([
          'web',
        ]);

      case TemplatePlatform.desktop:
        directories.addAll([
          'windows',
          'macos',
          'linux',
        ]);

      case TemplatePlatform.crossPlatform:
        directories.addAll([
          // 移动端
          'android',
          'android/app',
          'android/app/src',
          'android/app/src/main',
          'android/app/src/main/kotlin',
          'ios',
          'ios/Runner',
          // Web
          'web',
          // 桌面端
          'windows',
          'macos',
          'linux',
        ]);

      case TemplatePlatform.cloud:
        // 云平台通常不需要额外目录
        break;
      case TemplatePlatform.server:
        // 服务器平台通常不需要额外目录
        break;
    }

    return directories;
  }

  /// 获取模板类型特定目录
  List<String> _getTemplateTypeDirectories(TemplateType templateType) {
    final directories = <String>[];

    switch (templateType) {
      case TemplateType.ui:
        directories.addAll([
          'lib/src/components',
          'lib/src/layouts',
          'lib/src/animations',
          'lib/src/styles',
        ]);

      case TemplateType.service:
        directories.addAll([
          'lib/src/api',
          'lib/src/data',
          'lib/src/domain',
          'lib/src/infrastructure',
        ]);

      case TemplateType.data:
        directories.addAll([
          'lib/src/entities',
          'lib/src/datasources',
          'lib/src/mappers',
          'lib/src/cache',
        ]);

      case TemplateType.full:
        directories.addAll([
          // UI相关
          'lib/src/components',
          'lib/src/layouts',
          'lib/src/animations',
          'lib/src/styles',
          // Service相关
          'lib/src/api',
          'lib/src/data',
          'lib/src/domain',
          'lib/src/infrastructure',
          // Data相关
          'lib/src/entities',
          'lib/src/datasources',
          'lib/src/mappers',
          'lib/src/cache',
          // 额外功能
          'lib/src/features',
          'lib/src/shared',
        ]);

      case TemplateType.system:
        directories.addAll([
          'lib/src/system',
          'lib/src/monitoring',
          'lib/src/logging',
          'lib/src/performance',
        ]);

      case TemplateType.basic:
      case TemplateType.micro:
      case TemplateType.plugin:
      case TemplateType.infrastructure:
        // 使用基础目录结构
        break;
    }

    return directories;
  }

  /// 获取复杂度特定目录
  List<String> _getComplexityDirectories(TemplateComplexity complexity) {
    final directories = <String>[];

    switch (complexity) {
      case TemplateComplexity.simple:
        // 简单项目只需要基础目录
        break;

      case TemplateComplexity.medium:
        directories.addAll([
          'lib/src/config',
          'lib/src/extensions',
          'lib/src/repositories',
          'lib/src/dialogs',
          'lib/src/core/router',
          'lib/src/core/theme',
          'lib/src/core/providers',
          'assets/fonts',
          'assets/colors',
        ]);

      case TemplateComplexity.complex:
        directories.addAll([
          'lib/src/config',
          'lib/src/extensions',
          'lib/src/repositories',
          'lib/src/dialogs',
          'lib/src/middleware',
          'lib/src/interceptors',
          'lib/src/validators',
          'lib/src/core/router',
          'lib/src/core/theme',
          'lib/src/core/providers',
          'assets/fonts',
          'assets/colors',
        ]);

      case TemplateComplexity.enterprise:
        directories.addAll([
          'lib/src/config',
          'lib/src/extensions',
          'lib/src/repositories',
          'lib/src/dialogs',
          'lib/src/middleware',
          'lib/src/interceptors',
          'lib/src/validators',
          'lib/src/security',
          'lib/src/monitoring',
          'lib/src/analytics',
          'lib/src/localization',
          'lib/src/accessibility',
          'lib/src/core/router',
          'lib/src/core/theme',
          'lib/src/core/providers',
          'assets/fonts',
          'assets/colors',
        ]);
    }

    return directories;
  }

  /// 获取测试目录
  List<String> _getTestDirectories() {
    return [
      'test',
      'test/unit',
      'test/unit/models',
      'test/unit/services',
      'test/unit/repositories',
      'test/unit/providers',
      'test/widget',
      'test/widget/screens',
      'test/widget/widgets',
      'test/widget/components',
      'test/integration',
      'test/mocks',
      'test/fixtures',
      'test/helpers',
      'integration_test',
    ];
  }

  /// 获取文档目录
  List<String> _getDocumentationDirectories() {
    return [
      'docs',
      'docs/api',
      'docs/guides',
      'docs/tutorials',
      'docs/architecture',
      'docs/deployment',
    ];
  }

  /// 获取示例目录
  List<String> _getExampleDirectories() {
    return [
      'example',
      'example/lib',
      'example/lib/src',
      'example/assets',
      'example/test',
    ];
  }

  /// 获取目录描述
  Map<String, String> getDirectoryDescriptions() {
    return {
      'lib': 'Dart源代码主目录',
      'lib/src': '应用程序源代码',
      'lib/src/models': '数据模型类',
      'lib/src/services': '业务逻辑服务',
      'lib/src/widgets': '自定义Widget组件',
      'lib/src/screens': '应用程序页面',
      'lib/src/utils': '工具类和辅助函数',
      'lib/src/constants': '常量定义',
      'lib/src/providers': '状态管理Provider',
      'lib/src/repositories': '数据仓库层',
      'lib/src/core': '核心功能模块',
      'lib/src/core/router': '路由配置',
      'lib/src/core/theme': '主题配置',
      'lib/src/core/providers': '核心Provider',
      'lib/generated': 'flutter_gen生成的资源文件',
      'assets': '静态资源文件',
      'assets/images': '图片资源',
      'assets/icons': '图标资源',
      'assets/fonts': '字体资源',
      'assets/colors': '颜色资源',
      'l10n': '国际化文件',
      'test': '测试文件',
      'test/unit': '单元测试',
      'test/widget': 'Widget测试',
      'integration_test': '集成测试',
      'docs': '项目文档',
      'example': '示例代码',
      'templates': '代码模板',
      'config': '配置文件',
      'android': 'Android平台代码',
      'ios': 'iOS平台代码',
      'web': 'Web平台代码',
      'windows': 'Windows平台代码',
      'macos': 'macOS平台代码',
      'linux': 'Linux平台代码',
    };
  }

  /// 获取目录创建优先级
  ///
  /// 返回目录创建的优先级顺序，数字越小优先级越高
  Map<String, int> getDirectoryPriorities() {
    return {
      'lib': 1,
      'lib/src': 2,
      'assets': 3,
      'l10n': 4,
      'test': 5,
      'docs': 6,
      'example': 7,
      'templates': 8,
      'config': 9,
      'android': 10,
      'ios': 10,
      'web': 10,
      'windows': 10,
      'macos': 10,
      'linux': 10,
    };
  }
}
