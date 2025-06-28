/*
---------------------------------------------------------------
File name:          module_config.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        模块配置数据模型 (Module configuration data model)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 基础模块配置模型;
---------------------------------------------------------------
*/

/// 模块配置类
/// 管理单个模块的配置信息和元数据
class ModuleConfig {
  /// 模块基本信息
  final ModuleInfo module;
  
  /// 模块类型和分类
  final ModuleClassification classification;
  
  /// 依赖关系
  final ModuleDependencies dependencies;
  
  /// 权限声明
  final List<String> permissions;
  
  /// 导出声明
  final ModuleExports exports;

  const ModuleConfig({
    required this.module,
    required this.classification,
    required this.dependencies,
    required this.permissions,
    required this.exports,
  });

  /// 创建默认配置
  factory ModuleConfig.defaultConfig({
    required String id,
    required String name,
    String? description,
  }) {
    return ModuleConfig(
      module: ModuleInfo(
        id: id,
        name: name,
        version: '1.0.0',
        description: description ?? '模块描述',
        author: '开发者名称',
      ),
      classification: ModuleClassification(
        type: ModuleType.business,
        categories: ['productivity'],
      ),
      dependencies: ModuleDependencies(
        required: ['com.petapp.core'],
        optional: [],
      ),
      permissions: ['storage.read', 'storage.write'],
      exports: ModuleExports(
        services: [],
        widgets: [],
      ),
    );
  }
}

/// 模块基本信息
class ModuleInfo {
  /// 模块唯一标识符
  final String id;
  
  /// 显示名称
  final String name;
  
  /// 版本号
  final String version;
  
  /// 描述
  final String description;
  
  /// 作者
  final String author;

  const ModuleInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
  });
}

/// 模块分类信息
class ModuleClassification {
  /// 模块类型
  final ModuleType type;
  
  /// 类别标签
  final List<String> categories;

  const ModuleClassification({
    required this.type,
    required this.categories,
  });
}

/// 模块类型枚举
enum ModuleType {
  core,        // 核心模块
  business,    // 业务模块
  system,      // 系统模块
  extension,   // 扩展模块
  theme,       // 主题模块
}

/// 模块依赖关系
class ModuleDependencies {
  /// 必需依赖
  final List<String> required;
  
  /// 可选依赖
  final List<String> optional;

  const ModuleDependencies({
    required this.required,
    required this.optional,
  });
}

/// 模块导出信息
class ModuleExports {
  /// 导出的服务
  final List<ExportedService> services;
  
  /// 导出的组件
  final List<ExportedWidget> widgets;

  const ModuleExports({
    required this.services,
    required this.widgets,
  });
}

/// 导出的服务信息
class ExportedService {
  /// 服务名称
  final String name;
  
  /// 接口名称
  final String? interface;

  const ExportedService({
    required this.name,
    this.interface,
  });
}

/// 导出的组件信息
class ExportedWidget {
  /// 组件名称
  final String name;
  
  /// 组件描述
  final String? description;

  const ExportedWidget({
    required this.name,
    this.description,
  });
} 