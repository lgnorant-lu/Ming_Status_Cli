/*
---------------------------------------------------------------
File name:          dart_dependency_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        Dart依赖管理器 (Dart Dependency Manager)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加Dart特定依赖验证
    - [ ] 支持Dart版本兼容性检查
    - [ ] 添加CLI工具依赖管理
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/dependencies/dependency_manager_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// Dart依赖管理器
///
/// 负责管理纯Dart项目的依赖包
class DartDependencyManager extends DependencyManagerBase {
  /// 创建Dart依赖管理器实例
  const DartDependencyManager();

  @override
  DependencyType get dependencyType => DependencyType.production;

  @override
  List<TemplateFramework> get supportedFrameworks => [TemplateFramework.dart];

  @override
  Map<String, String> getDependencies(ScaffoldConfig config) {
    final dependencies = <String, String>{};

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

  /// 添加简单依赖
  void _addSimpleDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'args': '^2.4.2',
      'meta': '^1.11.0',
    });
  }

  /// 添加中等复杂度依赖
  void _addMediumDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'args': '^2.4.2',
      'meta': '^1.11.0',
      'path': '^1.8.3',
      'io': '^1.0.4',
      'logging': '^1.2.0',
      'yaml': '^3.1.2',
      'json_annotation': '^4.8.1',
    });
  }

  /// 添加复杂依赖
  void _addComplexDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'args': '^2.4.2',
      'meta': '^1.11.0',
      'path': '^1.8.3',
      'io': '^1.0.4',
      'logging': '^1.2.0',
      'yaml': '^3.1.2',
      'json_annotation': '^4.8.1',
      'http': '^1.1.2',
      'dio': '^5.4.0',
      'freezed_annotation': '^2.4.1',
      'riverpod': '^2.4.9',
      'riverpod_annotation': '^2.3.3',
    });
  }

  /// 添加企业级依赖
  void _addEnterpriseDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'args': '^2.4.2',
      'meta': '^1.11.0',
      'path': '^1.8.3',
      'io': '^1.0.4',
      'logging': '^1.2.0',
      'yaml': '^3.1.2',
      'json_annotation': '^4.8.1',
      'http': '^1.1.2',
      'dio': '^5.4.0',
      'freezed_annotation': '^2.4.1',
      'riverpod': '^2.4.9',
      'riverpod_annotation': '^2.3.3',
      'shelf': '^1.4.1',
      'shelf_router': '^1.1.4',
      'shelf_cors_headers': '^0.1.5',
      'postgres': '^2.6.2',
      'redis': '^3.2.1',
      'crypto': '^3.0.3',
      'jwt_decode': '^0.3.1',
    });
  }

  /// 添加基础开发依赖
  void _addBaseDevDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'test': '^1.24.9',
      'lints': '^3.0.0',
    });
  }

  /// 添加简单开发依赖
  void _addSimpleDevDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    // 简单项目只需要基础开发依赖
  }

  /// 添加中等复杂度开发依赖
  void _addMediumDevDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'build_runner': '^2.4.7',
      'json_serializable': '^6.7.1',
    });
  }

  /// 添加复杂开发依赖
  void _addComplexDevDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'build_runner': '^2.4.7',
      'json_serializable': '^6.7.1',
      'freezed': '^2.4.6',
      'riverpod_generator': '^2.3.9',
      'mockito': '^5.4.4',
    });
  }

  /// 添加企业级开发依赖
  void _addEnterpriseDevDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'build_runner': '^2.4.7',
      'json_serializable': '^6.7.1',
      'freezed': '^2.4.6',
      'riverpod_generator': '^2.3.9',
      'mockito': '^5.4.4',
      'coverage': '^1.7.1',
      'dart_code_metrics': '^5.7.6',
      'import_sorter': '^4.6.0',
      'very_good_analysis': '^5.1.0',
    });
  }

  /// 添加模板类型特定依赖
  void _addTemplateTypeDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    switch (config.templateType) {
      case TemplateType.ui:
        _addUIDependencies(dependencies, config);
      case TemplateType.service:
        _addServiceDependencies(dependencies, config);
      case TemplateType.full:
        _addFullDependencies(dependencies, config);
      case TemplateType.data:
        _addDataDependencies(dependencies, config);
      case TemplateType.system:
        _addSystemDependencies(dependencies, config);
      case TemplateType.basic:
        _addBasicDependencies(dependencies, config);
      case TemplateType.micro:
        _addMicroDependencies(dependencies, config);
      case TemplateType.plugin:
        _addPluginDependencies(dependencies, config);
      case TemplateType.infrastructure:
        _addInfrastructureDependencies(dependencies, config);
    }
  }

  /// 添加UI模板依赖（对于Dart项目，主要是CLI UI）
  void _addUIDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'cli_util': '^0.4.0',
      'ansi_styles': '^0.3.2+1',
      'mason_logger': '^0.2.11',
    });
  }

  /// 添加服务模板依赖
  void _addServiceDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'shelf': '^1.4.1',
      'shelf_router': '^1.1.4',
      'shelf_cors_headers': '^0.1.5',
      'shelf_static': '^1.1.2',
      'shelf_web_socket': '^1.0.4',
    });

    // 根据复杂度添加数据库依赖
    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      dependencies.addAll({
        'postgres': '^2.6.2',
        'sqlite3': '^2.1.0',
        'redis': '^3.2.1',
      });
    }
  }

  /// 添加完整模板依赖
  void _addFullDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    // 包含UI和服务的所有依赖
    _addUIDependencies(dependencies, config);
    _addServiceDependencies(dependencies, config);

    // 添加额外的工具依赖
    dependencies.addAll({
      'watcher': '^1.1.0',
      'glob': '^2.1.2',
      'mustache_template': '^2.0.0',
    });
  }

  @override
  String getRecommendedVersion(String packageName, ScaffoldConfig config) {
    // Dart特定的版本推荐逻辑
    final dartSpecificVersions = {
      'meta': '^1.11.0',
      'test': '^1.24.9',
      'lints': '^3.0.0',
      'very_good_analysis': '^5.1.0',
    };

    if (dartSpecificVersions.containsKey(packageName)) {
      return dartSpecificVersions[packageName]!;
    }

    return super.getRecommendedVersion(packageName, config);
  }

  /// 获取CLI特定依赖
  ///
  /// [config] 脚手架配置
  /// 返回CLI工具依赖映射表
  Map<String, String> getCliDependencies(ScaffoldConfig config) {
    final dependencies = <String, String>{}

      // 基础CLI依赖
      ..addAll({
        'args': '^2.4.2',
        'cli_util': '^0.4.0',
        'mason_logger': '^0.2.11',
        'ansi_styles': '^0.3.2+1',
      });

    // 根据复杂度添加更多CLI工具
    if (config.complexity == TemplateComplexity.medium ||
        config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      dependencies.addAll({
        'interact': '^2.2.0',
        'cli_completion': '^0.4.0',
        'cli_script': '^0.3.0',
      });
    }

    // 企业级CLI工具
    if (config.complexity == TemplateComplexity.enterprise) {
      dependencies.addAll({
        'dcli': '^3.0.1',
        'mason': '^0.1.0-dev.51',
        'very_good_cli': '^0.16.1',
      });
    }

    return dependencies;
  }

  /// 获取服务器特定依赖
  ///
  /// [config] 脚手架配置
  /// 返回服务器依赖映射表
  Map<String, String> getServerDependencies(ScaffoldConfig config) {
    final dependencies = <String, String>{}

      // 基础服务器依赖
      ..addAll({
        'shelf': '^1.4.1',
        'shelf_router': '^1.1.4',
        'shelf_cors_headers': '^0.1.5',
        'shelf_static': '^1.1.2',
      });

    // 根据复杂度添加更多服务器功能
    if (config.complexity == TemplateComplexity.medium ||
        config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      dependencies.addAll({
        'shelf_web_socket': '^1.0.4',
        'shelf_proxy': '^1.0.4',
        'shelf_helmet': '^1.0.1',
        'shelf_rate_limiter': '^0.1.2',
      });
    }

    // 企业级服务器功能
    if (config.complexity == TemplateComplexity.enterprise) {
      dependencies.addAll({
        'conduit': '^4.3.3',
        'angel3_framework': '^8.0.0',
        'serverpod': '^1.2.6',
      });
    }

    return dependencies;
  }

  /// 添加数据模板依赖
  void _addDataDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'sqlite3': '^2.1.0',
      'postgres': '^2.6.2',
      'mongo_dart': '^0.9.3',
      'redis': '^3.2.1',
    });
  }

  /// 添加系统模板依赖
  void _addSystemDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'platform': '^3.1.3',
      'universal_io': '^2.2.2',
      'system_info2': '^4.0.0',
    });
  }

  /// 添加基础模板依赖
  void _addBasicDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'args': '^2.4.2',
      'meta': '^1.11.0',
    });
  }

  /// 添加微服务模板依赖
  void _addMicroDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'grpc': '^3.2.4',
      'protobuf': '^3.1.0',
      'fixnum': '^1.1.0',
      'shelf': '^1.4.1',
      'shelf_router': '^1.1.4',
    });
  }

  /// 添加插件模板依赖
  void _addPluginDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'pub_semver': '^2.1.4',
      'pubspec_parse': '^1.2.3',
      'package_config': '^2.1.0',
    });
  }

  /// 添加基础设施模板依赖
  void _addInfrastructureDependencies(
      Map<String, String> dependencies, ScaffoldConfig config,) {
    dependencies.addAll({
      'docker': '^0.1.0',
      'kubernetes': '^0.1.0',
      'terraform': '^0.1.0',
      'aws': '^0.1.0',
    });
  }
}
