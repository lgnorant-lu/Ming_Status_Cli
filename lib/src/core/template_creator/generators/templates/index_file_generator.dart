/*
---------------------------------------------------------------
File name:          index_file_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        Index文件生成器 (Index File Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Initial creation - Index文件生成器;
---------------------------------------------------------------
*/
import 'dart:io';

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/config/scaffold_config.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:path/path.dart' as path;

/// Index.dart 文件生成器
///
/// 专门负责生成各种 index.dart 文件
class IndexFileGenerator {
  /// 生成所有必要的 index.dart 文件
  Future<List<String>> generateIndexFiles(ScaffoldConfig config) async {
    final libPath = path.join(config.outputPath, config.templateName, 'lib');
    final generatedFiles = <String>[];

    // 根据模板类型和复杂度生成对应的 index.dart 文件
    switch (config.templateType) {
      case TemplateType.basic:
        generatedFiles.addAll(await _generateBasicIndexFiles(libPath, config));
      case TemplateType.ui:
        generatedFiles.addAll(await _generateUIIndexFiles(libPath, config));
      case TemplateType.service:
        generatedFiles
            .addAll(await _generateServiceIndexFiles(libPath, config));
      case TemplateType.data:
        generatedFiles.addAll(await _generateDataIndexFiles(libPath, config));
      case TemplateType.full:
        generatedFiles.addAll(await _generateFullIndexFiles(libPath, config));
      default:
        generatedFiles.addAll(await _generateBasicIndexFiles(libPath, config));
    }

    return generatedFiles;
  }

  /// 生成基础模板的 index.dart 文件
  Future<List<String>> _generateBasicIndexFiles(
    String libPath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 生成核心 index.dart 文件
    files.addAll(await _generateCoreIndexFiles(libPath, config));

    // 根据复杂度生成额外的 index.dart 文件
    switch (config.complexity) {
      case TemplateComplexity.simple:
        // Simple 只需要基础文件
        break;
      case TemplateComplexity.medium:
        files
            .addAll(await _generateMediumComplexityIndexFiles(libPath, config));
      case TemplateComplexity.complex:
        files
            .addAll(await _generateMediumComplexityIndexFiles(libPath, config));
      case TemplateComplexity.enterprise:
        files.addAll(await _generateEnterpriseIndexFiles(libPath, config));
    }

    return files;
  }

  /// 生成核心 index.dart 文件（所有模板都需要）
  Future<List<String>> _generateCoreIndexFiles(
    String libPath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 生成 src/core/index.dart
    final coreIndexContent = _generateCoreIndexContent(config);
    await _writeFile(
      path.join(libPath, 'src', 'core'),
      'index.dart',
      coreIndexContent,
    );
    files.add('lib/src/core/index.dart');

    // 生成core子目录的index文件 - 只为需要的模板类型生成
    final coreSubdirectories = <String, String>{};

    // 只有UI和Full模板才需要providers、router、theme
    if (config.templateType == TemplateType.ui ||
        config.templateType == TemplateType.full) {
      coreSubdirectories.addAll({
        'providers': _generateProvidersIndexContent(config),
        'router': _generateRouterIndexContent(config),
        'theme': _generateThemeIndexContent(config),
      });
    }

    for (final entry in coreSubdirectories.entries) {
      await _writeFile(
        path.join(libPath, 'src', 'core', entry.key),
        'index.dart',
        entry.value,
      );
      files.add('lib/src/core/${entry.key}/index.dart');
    }

    // 生成 src/utils/index.dart
    final utilsIndexContent = _generateUtilsIndexContent(config);
    await _writeFile(
      path.join(libPath, 'src', 'utils'),
      'index.dart',
      utilsIndexContent,
    );
    files.add('lib/src/utils/index.dart');

    // 所有模板都专注于模块化开发，不需要平台特定目录
    // 平台特定功能应该由基础的flutter create提供
    // Full模板也应该是模块化的，专注于三层架构的完整组合
    // if (config.templateType == TemplateType.full &&
    //     (config.platform == TemplatePlatform.mobile ||
    //         config.platform == TemplatePlatform.crossPlatform)) {
    //   final mobileIndexContent = _generateMobileIndexContent(config);
    //   await _writeFile(
    //     path.join(libPath, 'src', 'mobile'),
    //     'index.dart',
    //     mobileIndexContent,
    //   );
    //   files.add('lib/src/mobile/index.dart');
    // }

    return files;
  }

  /// 生成中等复杂度的 index.dart 文件
  Future<List<String>> _generateMediumComplexityIndexFiles(
    String libPath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 只有service、full模板才生成 src/services/index.dart
    // Data模板专注于数据持久层，不需要业务服务层
    if (config.templateType == TemplateType.service ||
        config.templateType == TemplateType.full) {
      final servicesIndexContent = _generateServicesIndexContent(config);
      await _writeFile(
        path.join(libPath, 'src', 'services'),
        'index.dart',
        servicesIndexContent,
      );
      files.add('lib/src/services/index.dart');
    }

    return files;
  }

  /// 生成企业级的 index.dart 文件
  Future<List<String>> _generateEnterpriseIndexFiles(
    String libPath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 包含中等复杂度的文件
    files.addAll(await _generateMediumComplexityIndexFiles(libPath, config));

    // 生成企业级特定的 index.dart 文件
    final enterpriseIndexFiles = {
      'security': _generateSecurityIndexContent(config),
      'monitoring': _generateMonitoringIndexContent(config),
      'logging': _generateLoggingIndexContent(config),
      'configuration': _generateConfigurationIndexContent(config),
    };

    for (final entry in enterpriseIndexFiles.entries) {
      await _writeFile(
        path.join(libPath, 'src', entry.key),
        'index.dart',
        entry.value,
      );
      files.add('lib/src/${entry.key}/index.dart');
    }

    return files;
  }

  /// 生成其他模板类型的 index.dart 文件
  Future<List<String>> _generateUIIndexFiles(
    String libPath,
    ScaffoldConfig config,
  ) async {
    final files = await _generateBasicIndexFiles(libPath, config);

    // UI 特定的 index.dart 文件
    final uiIndexFiles = {
      'widgets': _generateUIComponentsIndexContent(config),
      'themes': _generateThemesIndexContent(config),
      'styles': _generateStylesIndexContent(config),
      'screens': _generateScreensIndexContent(config),
    };

    for (final entry in uiIndexFiles.entries) {
      await _writeFile(
        path.join(libPath, 'src', entry.key),
        'index.dart',
        entry.value,
      );
      files.add('lib/src/${entry.key}/index.dart');
    }

    // Flutter 特定的 widgets index.dart
    final flutterWidgetsIndexContent =
        _generateFlutterWidgetsIndexContent(config);
    await _writeFile(
      path.join(libPath, 'src', 'widgets', 'flutter'),
      'index.dart',
      flutterWidgetsIndexContent,
    );
    files.add('lib/src/widgets/flutter/index.dart');

    return files;
  }

  Future<List<String>> _generateServiceIndexFiles(
    String libPath,
    ScaffoldConfig config,
  ) async {
    final files = await _generateBasicIndexFiles(libPath, config);

    // Service 特定的 index.dart 文件（只生成实际需要的目录）
    final serviceIndexFiles = {
      'api': _generateAPIIndexContent(config),
      'repositories': _generateRepositoriesIndexContent(config),
      'providers': _generateProvidersIndexContent(config),
      'models': _generateModelsIndexContent(config),
      'core': _generateCoreIndexContent(config),
      'utils': _generateUtilsIndexContent(config),
      'services': _generateServicesIndexContent(config),
    };

    // 生成core子目录的index文件
    final coreSubdirIndexFiles = {
      'core/providers': _generateCoreProvidersIndexContent(config),
      'core/router': _generateCoreRouterIndexContent(config),
      'core/theme': _generateCoreThemeIndexContent(config),
    };

    for (final entry in serviceIndexFiles.entries) {
      await _writeFile(
        path.join(libPath, 'src', entry.key),
        'index.dart',
        entry.value,
      );
      files.add('lib/src/${entry.key}/index.dart');
    }

    // 生成core子目录的index文件
    for (final entry in coreSubdirIndexFiles.entries) {
      await _writeFile(
        path.join(libPath, 'src', entry.key),
        'index.dart',
        entry.value,
      );
      files.add('lib/src/${entry.key}/index.dart');
    }

    return files;
  }

  Future<List<String>> _generateDataIndexFiles(
    String libPath,
    ScaffoldConfig config,
  ) async {
    final files = await _generateBasicIndexFiles(libPath, config);

    // Data 特定的 index.dart 文件
    final dataIndexFiles = {
      'models': _generateModelsIndexContent(config),
      'entities': _generateEntitiesIndexContent(config),
      'datasources': _generateDatasourcesIndexContent(config),
      'mappers': _generateMappersIndexContent(config),
      'cache': _generateCacheIndexContent(config),
    };

    for (final entry in dataIndexFiles.entries) {
      await _writeFile(
        path.join(libPath, 'src', entry.key),
        'index.dart',
        entry.value,
      );
      files.add('lib/src/${entry.key}/index.dart');
    }

    return files;
  }

  Future<List<String>> _generateFullIndexFiles(
    String libPath,
    ScaffoldConfig config,
  ) async {
    // Full 模板包含所有类型的 index.dart 文件
    final files = <String>[];

    // 生成基础文件（只调用一次）
    files.addAll(await _generateBasicIndexFiles(libPath, config));

    // Full 模板包含所有特定类型的文件
    final fullIndexFiles = {
      'widgets': _generateUIComponentsIndexContent(config),
      'api': _generateAPIIndexContent(config),
      'models': _generateModelsIndexContent(config),
      'providers': _generateProvidersIndexContent(config),
      'repositories': _generateRepositoriesIndexContent(config),
      'screens': _generateScreensIndexContent(config),
      'themes': _generateThemesIndexContent(config),
    };

    for (final entry in fullIndexFiles.entries) {
      await _writeFile(
        path.join(libPath, 'src', entry.key),
        'index.dart',
        entry.value,
      );
      files.add('lib/src/${entry.key}/index.dart');
    }

    return files;
  }

  // ========== 内容生成方法 ==========

  String _generateCoreIndexContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    buffer.writeln('''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        核心功能模块导出文件
---------------------------------------------------------------
*/

// 核心功能导出''');

    // 只有UI和Full模板才导出providers、router、theme
    if (config.templateType == TemplateType.ui ||
        config.templateType == TemplateType.full) {
      buffer.writeln("export 'providers/index.dart';");
      buffer.writeln("export 'router/index.dart';");
      buffer.writeln("export 'theme/index.dart';");
    } else {
      buffer.writeln('// Basic模板只包含基础核心功能');
    }

    return buffer.toString();
  }

  String _generateUtilsIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        工具函数模块导出文件
---------------------------------------------------------------
*/

// 工具函数导出
export '${config.templateName}_utils.dart';
''';
  }

  String _generateMobileIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        移动平台特定功能导出文件
---------------------------------------------------------------
*/

// 移动平台特定功能导出
// export 'platform_specific.dart';
// export 'native_bridge.dart';

// 暂时为空，等待具体功能实现
''';
  }

  String _generateServicesIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        服务模块导出文件
---------------------------------------------------------------
*/

// 服务模块导出
export '${config.templateName}_service.dart';
''';
  }

  String _generateSecurityIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        安全模块导出文件
---------------------------------------------------------------
*/

// 安全相关功能导出
// export 'authentication.dart';
// export 'authorization.dart';
// export 'encryption.dart';
// export 'security_utils.dart';

// 暂时为空，等待具体功能实现
''';
  }

  String _generateMonitoringIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        监控模块导出文件
---------------------------------------------------------------
*/

// 监控相关功能导出
// export 'performance_monitor.dart';
// export 'error_tracker.dart';
// export 'analytics.dart';
// export 'metrics.dart';

// 暂时为空，等待具体功能实现
''';
  }

  String _generateLoggingIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        日志模块导出文件
---------------------------------------------------------------
*/

// 日志相关功能导出
// export 'logger.dart';
// export 'log_formatter.dart';
// export 'log_appender.dart';
// export 'log_filter.dart';

// 暂时为空，等待具体功能实现
''';
  }

  String _generateConfigurationIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        配置模块导出文件
---------------------------------------------------------------
*/

// 配置相关功能导出
// export 'app_config.dart';
// export 'environment_config.dart';
// export 'feature_flags.dart';
// export 'config_manager.dart';

// 暂时为空，等待具体功能实现
''';
  }

  // 其他内容生成方法...
  String _generateUIComponentsIndexContent(ScaffoldConfig config) {
    return '''
// UI组件导出
// export 'common_widgets.dart';
// export 'custom_buttons.dart';
// export 'form_widgets.dart';
''';
  }

  String _generateAPIIndexContent(ScaffoldConfig config) {
    return '''
// API服务导出
// export 'api_client.dart';
// export 'endpoints.dart';
// export 'interceptors.dart';
''';
  }

  String _generateModelsIndexContent(ScaffoldConfig config) {
    return '''
// 数据模型导出
// export 'user_model.dart';
// export 'response_model.dart';
// export 'request_model.dart';
''';
  }

  // UI 特定的内容生成方法
  String _generateThemesIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        主题模块导出文件
---------------------------------------------------------------
*/

// 主题相关导出
// export 'app_theme.dart';
// export 'color_scheme.dart';
// export 'text_theme.dart';
// export 'theme_extensions.dart';

// 暂时为空，等待具体功能实现
''';
  }

  String _generateStylesIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        样式模块导出文件
---------------------------------------------------------------
*/

// 样式相关导出
// export 'app_styles.dart';
// export 'text_styles.dart';
// export 'button_styles.dart';
// export 'input_styles.dart';

// 暂时为空，等待具体功能实现
''';
  }

  String _generateScreensIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        页面模块导出文件
---------------------------------------------------------------
*/

// 页面相关导出
// export 'home_screen.dart';
// export 'settings_screen.dart';
// export 'profile_screen.dart';

// 暂时为空，等待具体功能实现
''';
  }

  String _generateFlutterWidgetsIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        Flutter特定组件导出文件
---------------------------------------------------------------
*/

// Flutter特定组件导出
// export 'flutter_widgets.dart';
// export 'material_widgets.dart';
// export 'cupertino_widgets.dart';

// 暂时为空，等待具体功能实现
''';
  }

  // Service 特定的内容生成方法
  String _generateRepositoriesIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        数据仓库模块导出文件
---------------------------------------------------------------
*/

// 数据仓库导出
// export 'user_repository.dart';
// export 'auth_repository.dart';
// export 'data_repository.dart';
// export 'cache_repository.dart';

// 暂时为空，等待具体功能实现
''';
  }

  String _generateProvidersIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        状态提供者模块导出文件
---------------------------------------------------------------
*/

// 状态提供者导出
// export 'auth_provider.dart';
// export 'user_provider.dart';
// export 'app_provider.dart';
// export 'theme_provider.dart';

// 暂时为空，等待具体功能实现
''';
  }

  /// 生成跨平台模块index内容
  String _generateCrossPlatformIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        跨平台模块导出文件
---------------------------------------------------------------
*/

// 跨平台功能导出
// export 'platform_detector.dart';
// export 'platform_services.dart';
// export 'platform_widgets.dart';

// 暂时为空，等待具体功能实现
''';
  }

  /// 生成core/providers目录index内容
  String _generateCoreProvidersIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        核心状态提供者导出文件
---------------------------------------------------------------
*/

// 核心状态提供者导出
// export 'app_provider.dart';
// export 'theme_provider.dart';
// export 'auth_provider.dart';

// 暂时为空，等待具体功能实现
''';
  }

  /// 生成core/router目录index内容
  String _generateCoreRouterIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        核心路由导出文件
---------------------------------------------------------------
*/

// 核心路由导出
// export 'app_router.dart';
// export 'route_config.dart';
// export 'route_guards.dart';

// 暂时为空，等待具体功能实现
''';
  }

  /// 生成core/theme目录index内容
  String _generateCoreThemeIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        核心主题导出文件
---------------------------------------------------------------
*/

// 核心主题导出
// export 'app_theme.dart';
// export 'color_scheme.dart';
// export 'text_theme.dart';

// 暂时为空，等待具体功能实现
''';
  }

  String _generateRouterIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        路由配置模块导出文件
---------------------------------------------------------------
*/

// 路由配置导出
// export 'app_router.dart';
// export 'route_names.dart';
// export 'route_guards.dart';

// 暂时为空，等待具体功能实现
''';
  }

  String _generateThemeIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        主题配置模块导出文件
---------------------------------------------------------------
*/

// 主题配置导出
// export 'app_theme.dart';
// export 'color_scheme.dart';
// export 'text_theme.dart';

// 暂时为空，等待具体功能实现
''';
  }

  /// 生成entities目录index内容
  String _generateEntitiesIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        实体模型导出文件
---------------------------------------------------------------
*/

// 实体模型导出
// export 'user_entity.dart';
// export 'product_entity.dart';
// export 'base_entity.dart';

// 暂时为空，等待具体功能实现
''';
  }

  /// 生成datasources目录index内容
  String _generateDatasourcesIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        数据源导出文件
---------------------------------------------------------------
*/

// 数据源导出
// export 'local_datasource.dart';
// export 'remote_datasource.dart';
// export 'database_datasource.dart';

// 暂时为空，等待具体功能实现
''';
  }

  /// 生成mappers目录index内容
  String _generateMappersIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        数据映射器导出文件
---------------------------------------------------------------
*/

// 数据映射器导出
// export 'user_mapper.dart';
// export 'product_mapper.dart';
// export 'base_mapper.dart';

// 暂时为空，等待具体功能实现
''';
  }

  /// 生成cache目录index内容
  String _generateCacheIndexContent(ScaffoldConfig config) {
    return '''
/*
---------------------------------------------------------------
File name:          index.dart
Author:             ${config.author ?? 'Unknown'}
Date created:       ${DateTime.now().toString().split(' ')[0]}
Last modified:      ${DateTime.now().toString().split(' ')[0]}
Dart Version:       3.2+
Description:        缓存管理导出文件
---------------------------------------------------------------
*/

// 缓存管理导出
// export 'cache_manager.dart';
// export 'memory_cache.dart';
// export 'disk_cache.dart';

// 暂时为空，等待具体功能实现
''';
  }

  /// 写入文件的辅助方法
  Future<void> _writeFile(
    String dirPath,
    String fileName,
    String content,
  ) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    final file = File(path.join(dirPath, fileName));
    await file.writeAsString(content);
  }
}
