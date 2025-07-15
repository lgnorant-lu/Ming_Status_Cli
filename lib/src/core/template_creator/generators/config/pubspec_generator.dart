/*
---------------------------------------------------------------
File name:          pubspec_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        pubspec.yaml配置文件生成器 (Pubspec.yaml Configuration Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/config/config_generator_base.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/dependencies/flutter_dependency_manager.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// pubspec.yaml配置文件生成器
///
/// 负责生成Flutter/Dart项目的pubspec.yaml配置文件
class PubspecGenerator extends ConfigGeneratorBase {
  /// 创建pubspec.yaml生成器实例
  const PubspecGenerator();

  @override
  String getFileName() => 'pubspec.yaml';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 基本信息
    buffer.writeln('name: ${config.templateName}');
    buffer.writeln('description: ${config.description}');
    buffer.writeln('version: ${config.version}');
    buffer.writeln();

    // 环境配置
    buffer.writeln('environment:');
    buffer.writeln('  sdk: ">=3.2.0 <4.0.0"');

    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('  flutter: ">=3.16.0"');
    }
    buffer.writeln();

    // 依赖配置
    buffer.writeln('dependencies:');

    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('  flutter:');
      buffer.writeln('    sdk: flutter');
      buffer.writeln();

      // Flutter特定依赖
      _addFlutterDependencies(buffer, config);
    } else {
      // 纯Dart依赖
      _addDartDependencies(buffer, config);
    }

    // 自定义依赖
    for (final dependency in config.dependencies) {
      buffer.writeln('  $dependency');
    }
    buffer.writeln();

    // 开发依赖
    buffer.writeln('dev_dependencies:');

    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('  flutter_test:');
      buffer.writeln('    sdk: flutter');
      buffer.writeln();

      _addFlutterDevDependencies(buffer, config);
    } else {
      _addDartDevDependencies(buffer, config);
    }
    buffer.writeln();

    // Flutter特定配置
    if (config.framework == TemplateFramework.flutter) {
      _addFlutterConfiguration(buffer, config);
    }

    return buffer.toString();
  }

  /// 添加Flutter依赖
  void _addFlutterDependencies(StringBuffer buffer, ScaffoldConfig config) {
    // 使用FlutterDependencyManager获取智能依赖
    const dependencyManager = FlutterDependencyManager();
    final dependencies = dependencyManager.getDependencies(config);

    // 过滤掉Flutter SDK依赖，这些会在基础部分处理
    final filteredDeps = Map<String, String>.from(dependencies);
    filteredDeps.removeWhere(
      (key, value) =>
          key == 'flutter' ||
          key == 'flutter_localizations' ||
          value == 'sdk: flutter',
    );

    // 按类别组织依赖
    final categorizedDeps = _categorizeDependencies(filteredDeps);

    // 状态管理
    if (categorizedDeps['state_management']?.isNotEmpty ?? false) {
      buffer.writeln('  # 状态管理');
      for (final entry in categorizedDeps['state_management']!.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln();
    }

    // 路由管理
    if (categorizedDeps['routing']?.isNotEmpty ?? false) {
      buffer.writeln('  # 路由管理');
      for (final entry in categorizedDeps['routing']!.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln();
    }

    // 数据序列化
    if (categorizedDeps['serialization']?.isNotEmpty ?? false) {
      buffer.writeln('  # 数据序列化');
      for (final entry in categorizedDeps['serialization']!.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln();
    }

    // 网络请求
    if (categorizedDeps['networking']?.isNotEmpty ?? false) {
      buffer.writeln('  # 网络请求');
      for (final entry in categorizedDeps['networking']!.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln();
    }

    // 本地存储
    if (categorizedDeps['storage']?.isNotEmpty ?? false) {
      buffer.writeln('  # 本地存储');
      for (final entry in categorizedDeps['storage']!.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln();
    }

    // UI组件
    if (categorizedDeps['ui']?.isNotEmpty ?? false) {
      buffer.writeln('  # UI组件');
      for (final entry in categorizedDeps['ui']!.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln();
    }

    // 工具库
    if (categorizedDeps['utils']?.isNotEmpty ?? false) {
      buffer.writeln('  # 工具库');
      for (final entry in categorizedDeps['utils']!.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln();
    }

    // Firebase
    if (categorizedDeps['firebase']?.isNotEmpty ?? false) {
      buffer.writeln('  # Firebase');
      for (final entry in categorizedDeps['firebase']!.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln();
    }
  }

  /// 按类别组织依赖
  Map<String, Map<String, String>> _categorizeDependencies(
    Map<String, String> dependencies,
  ) {
    final categorized = <String, Map<String, String>>{
      'state_management': {},
      'routing': {},
      'serialization': {},
      'networking': {},
      'storage': {},
      'ui': {},
      'utils': {},
      'firebase': {},
    };

    for (final entry in dependencies.entries) {
      final packageName = entry.key;
      final version = entry.value;

      // 状态管理
      if ([
        'flutter_riverpod',
        'riverpod_annotation',
        'provider',
        'bloc',
        'flutter_bloc'
      ].contains(packageName)) {
        categorized['state_management']![packageName] = version;
      }
      // 路由管理
      else if (['go_router', 'auto_route', 'fluro'].contains(packageName)) {
        categorized['routing']![packageName] = version;
      }
      // 数据序列化
      else if ([
        'freezed_annotation',
        'json_annotation',
        'built_value',
        'equatable'
      ].contains(packageName)) {
        categorized['serialization']![packageName] = version;
      }
      // 网络请求
      else if (['dio', 'retrofit', 'http', 'chopper'].contains(packageName)) {
        categorized['networking']![packageName] = version;
      }
      // 本地存储
      else if ([
        'shared_preferences',
        'hive',
        'hive_flutter',
        'sqflite',
        'drift',
        'path',
      ].contains(packageName)) {
        categorized['storage']![packageName] = version;
      }
      // UI组件
      else if ([
        'flutter_svg',
        'cached_network_image',
        'shimmer',
        'google_fonts',
        'flutter_gen',
      ].contains(packageName)) {
        categorized['ui']![packageName] = version;
      }
      // Firebase
      else if (packageName.startsWith('firebase_') ||
          packageName.startsWith('cloud_firestore')) {
        categorized['firebase']![packageName] = version;
      }
      // 工具库 (包括crypto、uuid、logger等)
      else {
        categorized['utils']![packageName] = version;
      }
    }

    return categorized;
  }

  /// 添加Dart依赖
  void _addDartDependencies(StringBuffer buffer, ScaffoldConfig config) {
    // 数据序列化
    buffer.writeln('  # 数据序列化');
    buffer.writeln(
      '  freezed_annotation: ${TemplateConstants.defaultDependencyVersions['freezed_annotation']}',
    );
    buffer.writeln(
      '  json_annotation: ${TemplateConstants.defaultDependencyVersions['json_annotation']}',
    );
    buffer.writeln();

    // 网络（如果需要）
    if (_needsNetworking(config)) {
      buffer.writeln('  # 网络请求');
      buffer.writeln(
        '  dio: ${TemplateConstants.defaultDependencyVersions['dio']}',
      );
      buffer.writeln();
    }

    // 工具库
    buffer.writeln('  # 工具库');
    buffer.writeln(
      '  intl: ${TemplateConstants.defaultDependencyVersions['intl']}',
    );
    buffer.writeln(
      '  equatable: ${TemplateConstants.defaultDependencyVersions['equatable']}',
    );
    buffer.writeln(
      '  uuid: ${TemplateConstants.defaultDependencyVersions['uuid']}',
    );
    buffer.writeln();
  }

  /// 添加Flutter开发依赖
  void _addFlutterDevDependencies(StringBuffer buffer, ScaffoldConfig config) {
    // 代码生成
    buffer.writeln('  # 代码生成');
    buffer.writeln(
      '  build_runner: ${TemplateConstants.defaultDevDependencyVersions['build_runner']}',
    );
    buffer.writeln(
      '  freezed: ${TemplateConstants.defaultDevDependencyVersions['freezed']}',
    );
    buffer.writeln(
      '  json_serializable: ${TemplateConstants.defaultDevDependencyVersions['json_serializable']}',
    );
    buffer.writeln(
      '  riverpod_generator: ${TemplateConstants.defaultDevDependencyVersions['riverpod_generator']}',
    );

    if (_needsNetworking(config)) {
      buffer.writeln(
        '  retrofit_generator: ${TemplateConstants.defaultDevDependencyVersions['retrofit_generator']}',
      );
    }
    buffer.writeln();

    // 资源生成
    buffer.writeln('  # 资源生成');
    buffer.writeln(
      '  flutter_gen_runner: ${TemplateConstants.defaultDevDependencyVersions['flutter_gen_runner']}',
    );
    buffer.writeln();

    // 测试
    if (config.includeTests) {
      buffer.writeln('  # 测试');
      buffer.writeln(
        '  mockito: ${TemplateConstants.defaultDevDependencyVersions['mockito']}',
      );
      buffer.writeln(
        '  build_verify: ${TemplateConstants.defaultDevDependencyVersions['build_verify']}',
      );
      buffer.writeln();
    }

    // 代码质量
    buffer.writeln('  # 代码质量');
    buffer.writeln(
      '  flutter_lints: ${TemplateConstants.defaultDevDependencyVersions['flutter_lints']}',
    );
    buffer.writeln(
      '  very_good_analysis: ${TemplateConstants.defaultDevDependencyVersions['very_good_analysis']}',
    );
    buffer.writeln();

    // 工具
    buffer.writeln('  # 工具');
    buffer.writeln(
      '  flutter_launcher_icons: ${TemplateConstants.defaultDevDependencyVersions['flutter_launcher_icons']}',
    );
    buffer.writeln(
      '  flutter_native_splash: ${TemplateConstants.defaultDevDependencyVersions['flutter_native_splash']}',
    );

    // 企业级工具 (仅在企业级复杂度时添加)
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln();
      buffer.writeln('  # Monorepo管理');
      buffer.writeln(
        '  melos: ${TemplateConstants.defaultDevDependencyVersions['melos']}',
      );
    }
  }

  /// 添加Dart开发依赖
  void _addDartDevDependencies(StringBuffer buffer, ScaffoldConfig config) {
    // 代码生成
    buffer.writeln('  # 代码生成');
    buffer.writeln(
      '  build_runner: ${TemplateConstants.defaultDevDependencyVersions['build_runner']}',
    );
    buffer.writeln(
      '  freezed: ${TemplateConstants.defaultDevDependencyVersions['freezed']}',
    );
    buffer.writeln(
      '  json_serializable: ${TemplateConstants.defaultDevDependencyVersions['json_serializable']}',
    );
    buffer.writeln();

    // 测试
    if (config.includeTests) {
      buffer.writeln('  # 测试');
      buffer.writeln('  test: ^1.24.0');
      buffer.writeln(
        '  mockito: ${TemplateConstants.defaultDevDependencyVersions['mockito']}',
      );
      buffer.writeln();
    }

    // 代码质量
    buffer.writeln('  # 代码质量');
    buffer.writeln('  lints: ^3.0.0');
    buffer.writeln(
      '  very_good_analysis: ${TemplateConstants.defaultDevDependencyVersions['very_good_analysis']}',
    );
  }

  /// 添加Flutter配置
  void _addFlutterConfiguration(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('flutter:');
    buffer.writeln('  uses-material-design: true');
    buffer.writeln('  generate: true');
    buffer.writeln();

    // 资源配置
    buffer.writeln('  # 资源文件');
    buffer.writeln('  assets:');
    buffer.writeln('    - assets/images/');
    buffer.writeln('    - assets/icons/');

    // 根据复杂度添加额外的资源路径
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('    - assets/colors/');
      buffer.writeln('    - assets/fonts/');
    }

    buffer.writeln('    # l10n 文件由 flutter gen-l10n 自动处理，不需要在这里声明');
    buffer.writeln();

    // 字体配置
    buffer.writeln('  # 字体配置');
    buffer.writeln('  # fonts:');
    buffer.writeln('  #   - family: CustomFont');
    buffer.writeln('  #     fonts:');
    buffer.writeln('  #       - asset: assets/fonts/CustomFont-Regular.ttf');
    buffer.writeln('  #       - asset: assets/fonts/CustomFont-Bold.ttf');
    buffer.writeln('  #         weight: 700');
    buffer.writeln();

    // 国际化配置
    buffer.writeln('# 国际化配置');
    buffer.writeln('flutter_intl:');
    buffer.writeln('  enabled: true');
    buffer.writeln('  class_name: S');
    buffer.writeln('  main_locale: en');
    buffer.writeln('  arb_dir: l10n');
    buffer.writeln('  output_dir: lib/generated/l10n');
  }

  /// 判断是否需要网络功能
  bool _needsNetworking(ScaffoldConfig config) {
    return config.templateType == TemplateType.service ||
        config.templateType == TemplateType.full ||
        config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise;
  }

  /// 判断是否需要存储功能
  bool _needsStorage(ScaffoldConfig config) {
    return config.templateType == TemplateType.data ||
        config.templateType == TemplateType.full ||
        config.complexity == TemplateComplexity.medium ||
        config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise;
  }

  /// 判断是否需要UI组件
  bool _needsUIComponents(ScaffoldConfig config) {
    return config.templateType == TemplateType.ui ||
        config.templateType == TemplateType.full ||
        config.framework == TemplateFramework.flutter;
  }

  /// 判断是否需要Firebase
  bool _needsFirebase(ScaffoldConfig config) {
    return config.complexity == TemplateComplexity.enterprise ||
        config.tags.contains('firebase') ||
        config.tags.contains('backend');
  }
}
