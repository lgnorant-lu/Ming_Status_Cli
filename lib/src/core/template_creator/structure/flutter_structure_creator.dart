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
    directories.addAll(_getBaseDirectories(config));

    // 所有模板都专注于模块化开发，不需要平台目录
    // 平台目录应该由基础的flutter create提供
    // Full模板也应该是模块化的，专注于三层架构的完整组合
    // if (config.templateType == TemplateType.full) {
    //   directories.addAll(_getPlatformDirectories(config.platform));
    // }

    // 根据模板类型添加特定目录
    directories.addAll(_getTemplateTypeDirectories(config.templateType));

    // 根据复杂度添加目录
    directories.addAll(
        _getComplexityDirectories(config.complexity, config.templateType));

    // 添加可选功能目录
    if (config.includeTests) {
      directories.addAll(_getTestDirectories(config));
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
  List<String> _getBaseDirectories(ScaffoldConfig config) {
    final directories = [
      // 核心源码目录
      'lib',
      'lib/src',
      'lib/src/models',
      'lib/src/utils',
      'lib/src/constants',
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

    // 根据模板类型添加特定基础目录
    switch (config.templateType) {
      case TemplateType.ui:
        // UI模板添加UI相关基础目录
        directories.addAll([
          'lib/src/components',
          'lib/src/pages',
          'lib/src/providers', // UI模板需要状态管理
        ]);
      case TemplateType.service:
        // Service模板添加服务相关基础目录
        directories.addAll([
          'lib/src/services',
          'lib/src/providers', // Service模板需要状态管理
        ]);
      case TemplateType.data:
        // Data模板添加数据相关基础目录 - 不包含services和providers
        // Data模板专注于数据持久层，不需要业务服务层和状态管理层
        break;
      case TemplateType.full:
        // Full模板包含所有基础目录
        directories.addAll([
          'lib/src/components',
          'lib/src/pages',
          'lib/src/services',
          'lib/src/providers',
        ]);
      case TemplateType.system:
      case TemplateType.basic:
      case TemplateType.micro:
      case TemplateType.plugin:
      case TemplateType.infrastructure:
        // 其他模板类型根据需要添加特定目录
        // 目前保持基础目录即可
        break;
    }

    return directories;
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
          'lib/src/widgets',
          'lib/src/themes',
          'lib/src/styles',
        ]);

      case TemplateType.service:
        directories.addAll([
          'lib/src/api',
          'lib/src/repositories',
          'lib/src/services',
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
        // Basic模板：最小化基础结构，适合快速原型
        directories.addAll([
          'lib/src/core',
        ]);

      case TemplateType.infrastructure:
        // Infrastructure模板：专注于基础设施和系统级功能
        directories.addAll([
          'lib/src/infrastructure',
          'lib/src/config',
          'lib/src/logging',
          'lib/src/monitoring',
          'lib/src/security',
          'lib/src/networking',
          'lib/src/storage',
        ]);

      case TemplateType.micro:
        // Micro模板：微服务架构组件，轻量级服务
        directories.addAll([
          'lib/src/handlers',
          'lib/src/middleware',
          'lib/src/routes',
          'lib/src/dto',
          'lib/src/adapters',
          'lib/src/ports',
        ]);

      case TemplateType.plugin:
        // Plugin模板：可扩展插件系统
        directories.addAll([
          'lib/src/plugins',
          'lib/src/extensions',
          'lib/src/hooks',
          'lib/src/interfaces',
          'lib/src/registry',
          'lib/src/loaders',
        ]);
    }

    return directories;
  }

  /// 获取复杂度特定目录
  List<String> _getComplexityDirectories(
    TemplateComplexity complexity,
    TemplateType templateType,
  ) {
    final directories = <String>[];

    switch (complexity) {
      case TemplateComplexity.simple:
        // 简单项目只需要基础目录
        break;

      case TemplateComplexity.medium:
        directories.addAll([
          'lib/src/config',
          'lib/src/utils',
          'assets/fonts',
          'assets/colors',
        ]);

        // 只有UI和Full模板才需要路由、主题和状态管理
        if (templateType == TemplateType.ui ||
            templateType == TemplateType.full) {
          directories.addAll([
            'lib/src/core/router',
            'lib/src/core/theme',
            'lib/src/core/providers',
          ]);
        }

      case TemplateComplexity.complex:
        directories.addAll([
          'lib/src/config',
          'lib/src/extensions',
          'lib/src/validators',
          'assets/fonts',
          'assets/colors',
        ]);

        // 只有UI和Full模板才需要对话框、路由、主题和状态管理
        if (templateType == TemplateType.ui ||
            templateType == TemplateType.full) {
          directories.addAll([
            'lib/src/dialogs',
            'lib/src/core/router',
            'lib/src/core/theme',
            'lib/src/core/providers',
          ]);
        }

        // 只有service、data、full模板才添加这些目录
        if (templateType == TemplateType.service ||
            templateType == TemplateType.data ||
            templateType == TemplateType.full) {
          directories.addAll([
            'lib/src/repositories',
            'lib/src/middleware',
            'lib/src/interceptors',
          ]);
        }

      case TemplateComplexity.enterprise:
        directories.addAll([
          'lib/src/config',
          'lib/src/extensions',
          'lib/src/validators',
          'lib/src/security',
          'lib/src/monitoring',
          'lib/src/analytics',
          'lib/src/localization',
          'assets/fonts',
          'assets/colors',
        ]);

        // 只有UI和Full模板才需要对话框、无障碍、路由、主题和状态管理
        if (templateType == TemplateType.ui ||
            templateType == TemplateType.full) {
          directories.addAll([
            'lib/src/dialogs',
            'lib/src/accessibility',
            'lib/src/core/router',
            'lib/src/core/theme',
            'lib/src/core/providers',
          ]);
        }

        // 只有service、data、full模板才添加这些目录
        if (templateType == TemplateType.service ||
            templateType == TemplateType.data ||
            templateType == TemplateType.full) {
          directories.addAll([
            'lib/src/repositories',
            'lib/src/middleware',
            'lib/src/interceptors',
          ]);
        }
    }

    return directories;
  }

  /// 获取测试目录
  List<String> _getTestDirectories(ScaffoldConfig config) {
    final directories = ['test'];

    // 根据模板类型和复杂度决定测试目录结构
    if (config.templateType == TemplateType.service) {
      // service类型只需要基础测试目录
      directories.addAll([
        'test/unit',
        'test/mocks',
      ]);
    } else {
      // 其他类型需要更完整的测试结构
      directories.addAll([
        'test/unit',
        'test/unit/models',
        'test/unit/services',
        'test/unit/repositories',
        'test/unit/providers',
        'test/widget',
        'test/integration',
        'test/mocks',
        'test/fixtures',
        'test/helpers',
        'integration_test',
      ]);
    }

    return directories;
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
