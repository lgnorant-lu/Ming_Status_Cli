/*
---------------------------------------------------------------
File name:          flutter_dependency_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        Flutter依赖管理器 (Flutter Dependency Manager)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加Flutter特定依赖验证
    - [ ] 支持Flutter版本兼容性检查
    - [ ] 添加平台特定依赖管理
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/dependencies/dependency_manager_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// Flutter依赖管理器
///
/// 负责管理Flutter项目的依赖包
class FlutterDependencyManager extends DependencyManagerBase {
  /// 创建Flutter依赖管理器实例
  const FlutterDependencyManager();

  @override
  DependencyType get dependencyType => DependencyType.production;

  @override
  List<TemplateFramework> get supportedFrameworks =>
      [TemplateFramework.flutter];

  @override
  Map<String, String> getDependencies(ScaffoldConfig config) {
    final dependencies = <String, String>{};

    // 基础Flutter依赖
    _addBaseDependencies(dependencies, config);

    // 根据复杂度添加不同的依赖
    switch (config.complexity) {
      case TemplateComplexity.simple:
        _addSimpleDependencies(dependencies, config);
      case TemplateComplexity.medium:
        _addMediumDependencies(dependencies, config);
      case TemplateComplexity.complex:
        _addComplexDependencies(dependencies, config);
      case TemplateComplexity.enterprise:
        _addEnterpriseDependencies(dependencies, config);
    }

    // 根据平台添加特定依赖
    _addPlatformSpecificDependencies(dependencies, config);

    // 根据模板类型添加依赖
    _addTemplateTypeDependencies(dependencies, config);

    return dependencies;
  }

  @override
  Map<String, String> getDevDependencies(ScaffoldConfig config) {
    final devDependencies = <String, String>{};

    // 基础开发依赖
    _addBaseDevDependencies(devDependencies, config);

    // 根据复杂度添加开发依赖
    switch (config.complexity) {
      case TemplateComplexity.simple:
        _addSimpleDevDependencies(devDependencies, config);
      case TemplateComplexity.medium:
        _addMediumDevDependencies(devDependencies, config);
      case TemplateComplexity.complex:
        _addComplexDevDependencies(devDependencies, config);
      case TemplateComplexity.enterprise:
        _addEnterpriseDevDependencies(devDependencies, config);
    }

    return devDependencies;
  }

  /// 添加基础依赖
  void _addBaseDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'flutter': 'sdk: flutter',
      'flutter_localizations': 'sdk: flutter',
      'intl': '^0.19.0',
    });
  }

  /// 添加简单依赖 (使用优化后的版本)
  void _addSimpleDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'flutter_riverpod':
          TemplateConstants.defaultDependencyVersions['flutter_riverpod']!,
      'go_router': TemplateConstants.defaultDependencyVersions['go_router']!,
    });
  }

  /// 添加中等复杂度依赖 (使用优化后的版本)
  void _addMediumDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'flutter_riverpod':
          TemplateConstants.defaultDependencyVersions['flutter_riverpod']!,
      'riverpod_annotation':
          TemplateConstants.defaultDependencyVersions['riverpod_annotation']!,
      'provider': '^6.1.2', // 添加provider支持
      'go_router': TemplateConstants.defaultDependencyVersions['go_router']!,
      'shared_preferences':
          TemplateConstants.defaultDependencyVersions['shared_preferences']!,
      'freezed_annotation':
          TemplateConstants.defaultDependencyVersions['freezed_annotation']!,
      'json_annotation':
          TemplateConstants.defaultDependencyVersions['json_annotation']!,
      'dio': TemplateConstants.defaultDependencyVersions['dio']!, // 添加dio支持
      'equatable': TemplateConstants
          .defaultDependencyVersions['equatable']!, // 添加equatable支持
    });

    // 为service类型添加必要的依赖（V1验证发现的缺失依赖）
    if (config.templateType == TemplateType.service) {
      dependencies.addAll({
        'flutter_bloc': '^8.1.3',
        'provider': '^6.1.1',
        'sqflite': '^2.3.0',
        'crypto': '^3.0.3',
        'path': '^1.8.3',
        'dio': '^5.4.0',
        'retrofit': '^4.0.3',
        'hive': '^2.2.3',
        'hive_flutter': '^1.1.0',
        'uuid': '^4.2.1',
        'logger': '^2.0.2+1',
        'equatable': '^2.0.5', // 数据模型相等性比较
      });
    }
  }

  /// 添加复杂依赖 (使用优化后的版本)
  void _addComplexDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'flutter_riverpod':
          TemplateConstants.defaultDependencyVersions['flutter_riverpod']!,
      'riverpod_annotation':
          TemplateConstants.defaultDependencyVersions['riverpod_annotation']!,
      'provider': TemplateConstants.defaultDependencyVersions['provider']!,
      'go_router': TemplateConstants.defaultDependencyVersions['go_router']!,
      'shared_preferences':
          TemplateConstants.defaultDependencyVersions['shared_preferences']!,
      'freezed_annotation':
          TemplateConstants.defaultDependencyVersions['freezed_annotation']!,
      'json_annotation':
          TemplateConstants.defaultDependencyVersions['json_annotation']!,
      'equatable': TemplateConstants.defaultDependencyVersions['equatable']!,
      'dio': TemplateConstants.defaultDependencyVersions['dio']!,
      'cached_network_image':
          TemplateConstants.defaultDependencyVersions['cached_network_image']!,
      'flutter_svg':
          TemplateConstants.defaultDependencyVersions['flutter_svg']!,
      'google_fonts': '^6.1.0',
      'flutter_gen': '^5.4.0',
    });
  }

  /// 添加企业级依赖
  void _addEnterpriseDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    // 根据模板类型智能添加依赖
    switch (config.templateType) {
      case TemplateType.basic:
        // 基础模板只添加核心依赖
        _addBasicEnterpriseDependencies(dependencies, config);
      case TemplateType.full:
        // 完整模板添加所有企业级依赖
        _addFullEnterpriseDependencies(dependencies, config);
      case TemplateType.ui:
        // UI模板添加UI相关依赖
        _addUIEnterpriseDependencies(dependencies, config);
      case TemplateType.service:
        // 服务模板添加服务相关依赖
        _addServiceEnterpriseDependencies(dependencies, config);
      case TemplateType.data:
      case TemplateType.system:
      case TemplateType.micro:
      case TemplateType.plugin:
      case TemplateType.infrastructure:
        // 其他类型使用基础企业级依赖
        _addBasicEnterpriseDependencies(dependencies, config);
    }
  }

  /// 添加基础企业级依赖 (使用优化后的版本)
  void _addBasicEnterpriseDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      // 核心状态管理
      'flutter_riverpod':
          TemplateConstants.defaultDependencyVersions['flutter_riverpod']!,
      'riverpod_annotation':
          TemplateConstants.defaultDependencyVersions['riverpod_annotation']!,
      'provider': TemplateConstants.defaultDependencyVersions['provider']!,
      // 路由管理
      'go_router': TemplateConstants.defaultDependencyVersions['go_router']!,
      // 数据序列化
      'freezed_annotation':
          TemplateConstants.defaultDependencyVersions['freezed_annotation']!,
      'json_annotation':
          TemplateConstants.defaultDependencyVersions['json_annotation']!,
      // 数据库支持
      'sqflite': '^2.4.2',
      // 基础工具
      'intl': '^0.19.0',
      'equatable': '^2.0.5',
    });
  }

  /// 添加完整企业级依赖
  void _addFullEnterpriseDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    // 包含所有企业级功能
    _addBasicEnterpriseDependencies(dependencies, config);

    dependencies.addAll({
      // 状态管理 (Enterprise级别需要多种状态管理方案)
      'flutter_bloc':
          TemplateConstants.defaultDependencyVersions['flutter_bloc'] ??
              '^8.1.6',
      'provider': TemplateConstants.defaultDependencyVersions['provider']!,

      // 网络请求 (基础企业级依赖已包含状态管理、路由、序列化)
      'dio': TemplateConstants.defaultDependencyVersions['dio']!,
      'retrofit': TemplateConstants.defaultDependencyVersions['retrofit']!,

      // 本地存储
      'shared_preferences':
          TemplateConstants.defaultDependencyVersions['shared_preferences']!,
      'hive': TemplateConstants.defaultDependencyVersions['hive']!,
      'hive_flutter':
          TemplateConstants.defaultDependencyVersions['hive_flutter']!,
      'sqflite': '^2.4.2',
      'path': '^1.9.1',

      // UI组件
      'flutter_svg': '^2.0.9',
      'cached_network_image': '^3.3.0',
      'shimmer': '^3.0.0',

      // 工具库
      'uuid': '^4.2.1',

      // Firebase (可选)
      'firebase_core': '^2.24.2',
      'firebase_auth': '^4.15.3',
      'cloud_firestore': '^4.13.6',
      'firebase_storage': '^11.5.6',
    });
  }

  /// 添加UI企业级依赖
  void _addUIEnterpriseDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    _addBasicEnterpriseDependencies(dependencies, config);

    dependencies.addAll({
      // 状态管理 (UI Enterprise级别需要多种状态管理方案)
      'flutter_bloc':
          TemplateConstants.defaultDependencyVersions['flutter_bloc'] ??
              '^8.1.6',
      'provider': TemplateConstants.defaultDependencyVersions['provider']!,

      // 网络请求
      'dio': TemplateConstants.defaultDependencyVersions['dio']!,
      'retrofit': TemplateConstants.defaultDependencyVersions['retrofit']!,

      // 本地存储
      'shared_preferences':
          TemplateConstants.defaultDependencyVersions['shared_preferences']!,
      'hive': TemplateConstants.defaultDependencyVersions['hive']!,
      'hive_flutter':
          TemplateConstants.defaultDependencyVersions['hive_flutter']!,
      'sqflite': '^2.4.2',
      'path': '^1.9.1',

      // UI相关依赖
      'flutter_svg': '^2.0.9',
      'cached_network_image': '^3.3.0',
      'shimmer': '^3.0.0',
      'google_fonts': '^6.1.0',

      // 工具库
      'uuid': TemplateConstants.defaultDependencyVersions['uuid']!,
      'url_launcher': '^6.2.2',
      'share_plus': '^7.2.1',
      'path_provider': '^2.1.1',
    });
  }

  /// 添加服务企业级依赖
  void _addServiceEnterpriseDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    _addBasicEnterpriseDependencies(dependencies, config);

    dependencies.addAll({
      // 网络和服务相关依赖
      'dio': '^5.4.0',
      'retrofit': '^4.0.3',
      'json_annotation': '^4.8.1',
      'freezed_annotation': '^2.4.1',

      // V1验证发现的缺失依赖
      'flutter_bloc': '^8.1.3',
      'provider': '^6.1.1',
      'sqflite': '^2.3.0',
      'crypto': '^3.0.3',
      'path': '^1.8.3',

      // 本地存储和数据库
      'shared_preferences': '^2.2.2',
      'hive': '^2.2.3',
      'hive_flutter': '^1.1.0',

      // 工具库
      'uuid': '^4.2.1',
      'logger': '^2.0.2+1',
    });
  }

  /// 添加基础开发依赖
  void _addBaseDevDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'flutter_test': 'sdk: flutter',
      'flutter_lints': '^3.0.1',
    });
  }

  /// 添加简单开发依赖
  void _addSimpleDevDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    // 简单项目只需要基础开发依赖
  }

  /// 添加中等复杂度开发依赖
  void _addMediumDevDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'build_runner': '^2.4.7',
      'freezed': '^2.4.6',
      'json_serializable': '^6.7.1',
      'riverpod_generator': '^2.3.9',
    });

    // 为service类型添加必要的开发依赖
    if (config.templateType == TemplateType.service) {
      dependencies.addAll({
        'hive_generator': '^2.0.1',
        'retrofit_generator': '^7.0.8',
        'bloc_test': '^9.1.5',
        'mockito': '^5.4.4',
        'very_good_analysis': '^5.1.0',
      });
    }
  }

  /// 添加复杂开发依赖
  void _addComplexDevDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'build_runner': '^2.4.7',
      'freezed': '^2.4.6',
      'json_serializable': '^6.7.1',
      'riverpod_generator': '^2.3.9',
      'mockito': '^5.4.4',
      'flutter_gen_runner': '^5.4.0',
    });
  }

  /// 添加企业级开发依赖
  void _addEnterpriseDevDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      // 代码生成工具
      'build_runner': '^2.4.7',
      'freezed': '^2.4.6',
      'json_serializable': '^6.7.1',
      'riverpod_generator': '^2.3.9',
      'flutter_gen_runner': '^5.4.0',

      // 测试工具
      'mockito': '^5.4.4',
      'integration_test': 'sdk: flutter',
      'flutter_driver': 'sdk: flutter',
      'test': '^1.24.9',
      'coverage': '^1.7.1',

      // 代码质量工具
      'dart_code_metrics': '^5.7.6',
      'import_sorter': '^4.6.0',
      'very_good_analysis': '^5.1.0',

      // V1验证发现需要的额外工具
      'hive_generator': '^2.0.1',
      'retrofit_generator': '^7.0.8',
      'bloc_test': '^9.1.5',
    });
  }

  /// 添加平台特定依赖
  void _addPlatformSpecificDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    switch (config.platform) {
      case TemplatePlatform.mobile:
        _addMobileDependencies(dependencies, config);
      case TemplatePlatform.web:
        _addWebDependencies(dependencies, config);
      case TemplatePlatform.desktop:
        _addDesktopDependencies(dependencies, config);
      case TemplatePlatform.crossPlatform:
        _addCrossPlatformDependencies(dependencies, config);
      case TemplatePlatform.server:
        // Flutter不支持服务器平台，跳过
        break;
      case TemplatePlatform.cloud:
        // Flutter云平台依赖
        _addCrossPlatformDependencies(dependencies, config);
    }
  }

  /// 添加移动端依赖
  void _addMobileDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      dependencies.addAll({
        'camera': '^0.10.6',
        'image_picker': '^1.1.2',
        'geolocator': '^12.0.0',
        'url_launcher': '^6.3.0',
        'share_plus': '^10.0.2',
      });
    }
  }

  /// 添加Web依赖
  void _addWebDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      dependencies.addAll({
        'universal_html': '^2.2.4',
        'js': '^0.6.7',
      });
    }
  }

  /// 添加桌面端依赖
  void _addDesktopDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      dependencies.addAll({
        'window_manager': '^0.3.7',
        'file_picker': '^6.1.1',
        'path_provider': '^2.1.1',
      });
    }
  }

  /// 添加跨平台依赖
  void _addCrossPlatformDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    // 添加所有平台的通用依赖
    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      dependencies.addAll({
        'url_launcher': '^6.2.2',
        'share_plus': '^7.2.1',
        'path_provider': '^2.1.1',
      });
    }
  }

  /// 添加模板类型特定依赖
  void _addTemplateTypeDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    // 企业级复杂度已经在 _addEnterpriseDependencies 中智能处理了依赖
    // 避免重复添加
    if (config.complexity == TemplateComplexity.enterprise) {
      return;
    }

    switch (config.templateType) {
      case TemplateType.ui:
        _addUIDependencies(dependencies, config);
      case TemplateType.service:
        _addServiceDependencies(dependencies, config);
      case TemplateType.full:
        _addFullDependencies(dependencies, config);
      case TemplateType.data:
        // 数据模板依赖
        _addDataDependencies(dependencies, config);
      case TemplateType.system:
        // 系统模板依赖
        _addSystemDependencies(dependencies, config);
      case TemplateType.basic:
        // 基础模板依赖
        _addBasicDependencies(dependencies, config);
      case TemplateType.micro:
        // 微服务模板依赖
        _addMicroDependencies(dependencies, config);
      case TemplateType.plugin:
        // 插件模板依赖
        _addPluginDependencies(dependencies, config);
      case TemplateType.infrastructure:
        // 基础设施模板依赖
        _addInfrastructureDependencies(dependencies, config);
    }
  }

  /// 添加UI模板依赖
  void _addUIDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'flutter_staggered_grid_view': '^0.7.0',
      'animations': '^2.0.8',
      'lottie': '^2.7.0',
    });
  }

  /// 添加服务模板依赖
  void _addServiceDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'retrofit': '^4.0.3',
      'logger': '^2.0.2+1',
      'pretty_dio_logger': '^1.3.1',
    });
  }

  /// 添加完整模板依赖
  void _addFullDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    // 包含UI和服务的所有依赖
    _addUIDependencies(dependencies, config);
    _addServiceDependencies(dependencies, config);
  }

  @override
  String getRecommendedVersion(String packageName, ScaffoldConfig config) {
    // Flutter特定的版本推荐逻辑
    final flutterSpecificVersions = {
      'flutter': 'sdk: flutter',
      'flutter_test': 'sdk: flutter',
      'flutter_localizations': 'sdk: flutter',
      'integration_test': 'sdk: flutter',
      'flutter_driver': 'sdk: flutter',
    };

    if (flutterSpecificVersions.containsKey(packageName)) {
      return flutterSpecificVersions[packageName]!;
    }

    return super.getRecommendedVersion(packageName, config);
  }

  /// 添加数据模板依赖
  void _addDataDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'sqflite': '^2.3.0',
      'hive': '^2.2.3',
      'hive_flutter': '^1.1.0',
      'drift': '^2.14.1',
    });
  }

  /// 添加系统模板依赖
  void _addSystemDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'device_info_plus': '^9.1.1',
      'package_info_plus': '^8.3.0', // 修复与cached_network_image的版本冲突
      'connectivity_plus': '^5.0.2',
      'battery_plus': '^5.0.2',
    });
  }

  /// 添加基础模板依赖 (使用优化后的版本)
  void _addBasicDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    // 基础模板只需要最基本的依赖
    dependencies.addAll({
      'flutter_riverpod':
          TemplateConstants.defaultDependencyVersions['flutter_riverpod']!,
    });
  }

  /// 添加微服务模板依赖
  void _addMicroDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'grpc': '^3.2.4',
      'protobuf': '^3.1.0',
      'fixnum': '^1.1.0',
    });
  }

  /// 添加插件模板依赖
  void _addPluginDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'plugin_platform_interface': '^2.1.7',
      'flutter_plugin_android_lifecycle': '^2.0.17',
    });
  }

  /// 添加基础设施模板依赖
  void _addInfrastructureDependencies(
    Map<String, String> dependencies,
    ScaffoldConfig config,
  ) {
    dependencies.addAll({
      'firebase_core': '^2.24.2',
      'cloud_firestore': '^4.13.6',
      'firebase_storage': '^11.5.6',
      'firebase_messaging': '^14.7.10',
    });
  }
}
