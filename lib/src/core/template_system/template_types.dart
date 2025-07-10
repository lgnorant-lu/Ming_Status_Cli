/*
---------------------------------------------------------------
File name:          template_types.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板类型定义系统 (Enterprise Template Type System)
---------------------------------------------------------------
Change History:    
    2025/07/10: Initial creation - Phase 2.1 高级模板系统架构;
---------------------------------------------------------------
*/

/// 企业级模板类型枚举
/// 
/// 扩展的模板类型定义，支持企业级开发场景
enum TemplateType {
  // === 基础类型 (Phase 1 兼容) ===
  /// UI层模板 - 用户界面组件和页面
  ui,
  
  /// Service层模板 - 业务逻辑和服务
  service,
  
  /// Data层模板 - 数据访问和持久化
  data,
  
  /// Full模板 - 完整应用程序
  full,
  
  /// System模板 - 系统级配置和基础设施
  system,
  
  /// Basic模板 - 基础模板
  basic,
  
  // === 新增企业级类型 (Phase 2.1) ===
  /// Micro微服务模板 - 微服务架构组件
  micro,
  
  /// Plugin插件模板 - 可扩展插件系统
  plugin,
  
  /// Infrastructure基础设施模板 - 部署和运维
  infrastructure,
}

/// 模板子类型枚举
/// 
/// 为每个主要类型提供更细粒度的分类
enum TemplateSubType {
  // === UI子类型 ===
  /// 可重用UI组件
  component,
  
  /// 完整页面模板
  page,
  
  /// 主题和样式系统
  theme,
  
  /// 布局和导航结构
  layout,
  
  // === Service子类型 ===
  /// API服务层
  api,
  
  /// 业务逻辑层
  business,
  
  /// 第三方集成服务
  integration,
  
  // === Data子类型 ===
  /// 数据模型定义
  model,
  
  /// 数据仓库模式
  repository,
  
  /// 缓存系统
  cache,
  
  /// 数据库迁移
  migration,
  
  // === Full子类型 ===
  /// 完整应用程序
  app,
  
  /// 可重用包
  package,
  
  /// 库和框架
  library,
  
  // === System子类型 ===
  /// 配置管理
  config,
  
  /// 基础设施代码
  infrastructure,
  
  /// 部署和发布
  deployment,
  
  // === Micro子类型 ===
  /// 独立微服务
  standalone,
  
  /// 网关服务
  gateway,
  
  /// 消息队列服务
  messaging,
  
  // === Plugin子类型 ===
  /// 功能扩展插件
  extension,
  
  /// 中间件插件
  middleware,
  
  /// 工具插件
  utility,
  
  // === Infrastructure子类型 ===
  /// 容器化部署
  containerization,
  
  /// 监控和日志
  monitoring,
  
  /// 安全和认证
  security,
}

/// 模板复杂度等级
/// 
/// 用于评估模板的复杂程度和学习难度
enum TemplateComplexity {
  /// 简单模板 - 适合初学者
  simple,
  
  /// 中等复杂度 - 适合有经验的开发者
  medium,
  
  /// 复杂模板 - 适合高级开发者
  complex,
  
  /// 企业级复杂度 - 适合架构师和团队
  enterprise,
}

/// 模板成熟度等级
/// 
/// 表示模板的稳定性和生产就绪程度
enum TemplateMaturity {
  /// 实验性 - 仅用于概念验证
  experimental,
  
  /// 开发中 - 功能不完整
  development,
  
  /// 测试版 - 功能完整但可能有问题
  beta,
  
  /// 稳定版 - 生产就绪
  stable,
  
  /// 长期支持版 - 企业级稳定性
  lts,
  
  /// 已弃用 - 不推荐使用
  deprecated,
}

/// 模板平台支持
/// 
/// 定义模板支持的目标平台
enum TemplatePlatform {
  /// Web平台
  web,
  
  /// 移动平台 (iOS/Android)
  mobile,
  
  /// 桌面平台 (Windows/macOS/Linux)
  desktop,
  
  /// 服务器端
  server,
  
  /// 云原生
  cloud,
  
  /// 跨平台
  crossPlatform,
}

/// 模板框架支持
/// 
/// 定义模板支持的技术框架
enum TemplateFramework {
  /// Flutter框架
  flutter,
  
  /// Dart原生
  dart,
  
  /// React框架
  react,
  
  /// Vue.js框架
  vue,
  
  /// Angular框架
  angular,
  
  /// Node.js
  nodejs,
  
  /// Spring Boot
  springBoot,
  
  /// 框架无关
  agnostic,
}

/// 模板类型扩展方法
/// 
/// 为模板类型枚举提供便利方法
extension TemplateTypeExtension on TemplateType {
  /// 获取模板类型的显示名称
  String get displayName {
    switch (this) {
      case TemplateType.ui:
        return 'UI组件';
      case TemplateType.service:
        return '业务服务';
      case TemplateType.data:
        return '数据层';
      case TemplateType.full:
        return '完整应用';
      case TemplateType.system:
        return '系统配置';
      case TemplateType.basic:
        return '基础模板';
      case TemplateType.micro:
        return '微服务';
      case TemplateType.plugin:
        return '插件系统';
      case TemplateType.infrastructure:
        return '基础设施';
    }
  }
  
  /// 获取模板类型的描述
  String get description {
    switch (this) {
      case TemplateType.ui:
        return '用户界面组件、页面和交互元素';
      case TemplateType.service:
        return '业务逻辑、API服务和第三方集成';
      case TemplateType.data:
        return '数据模型、仓库模式和持久化层';
      case TemplateType.full:
        return '完整的应用程序、包和库';
      case TemplateType.system:
        return '系统配置、基础设施和部署脚本';
      case TemplateType.basic:
        return '基础模板和起始项目';
      case TemplateType.micro:
        return '微服务架构组件和分布式系统';
      case TemplateType.plugin:
        return '可扩展插件、中间件和工具';
      case TemplateType.infrastructure:
        return '容器化、监控、安全和运维工具';
    }
  }
  
  /// 获取支持的子类型列表
  List<TemplateSubType> get supportedSubTypes {
    switch (this) {
      case TemplateType.ui:
        return [
          TemplateSubType.component,
          TemplateSubType.page,
          TemplateSubType.theme,
          TemplateSubType.layout,
        ];
      case TemplateType.service:
        return [
          TemplateSubType.api,
          TemplateSubType.business,
          TemplateSubType.integration,
        ];
      case TemplateType.data:
        return [
          TemplateSubType.model,
          TemplateSubType.repository,
          TemplateSubType.cache,
          TemplateSubType.migration,
        ];
      case TemplateType.full:
        return [
          TemplateSubType.app,
          TemplateSubType.package,
          TemplateSubType.library,
        ];
      case TemplateType.system:
        return [
          TemplateSubType.config,
          TemplateSubType.infrastructure,
          TemplateSubType.deployment,
        ];
      case TemplateType.basic:
        return []; // 基础模板不需要子类型
      case TemplateType.micro:
        return [
          TemplateSubType.standalone,
          TemplateSubType.gateway,
          TemplateSubType.messaging,
        ];
      case TemplateType.plugin:
        return [
          TemplateSubType.extension,
          TemplateSubType.middleware,
          TemplateSubType.utility,
        ];
      case TemplateType.infrastructure:
        return [
          TemplateSubType.containerization,
          TemplateSubType.monitoring,
          TemplateSubType.security,
        ];
    }
  }
  
  /// 检查是否为企业级类型
  bool get isEnterpriseType {
    return [
      TemplateType.micro,
      TemplateType.plugin,
      TemplateType.infrastructure,
    ].contains(this);
  }
}

/// 模板子类型扩展方法
extension TemplateSubTypeExtension on TemplateSubType {
  /// 获取子类型的显示名称
  String get displayName {
    switch (this) {
      case TemplateSubType.component:
        return 'UI组件';
      case TemplateSubType.page:
        return '页面模板';
      case TemplateSubType.theme:
        return '主题样式';
      case TemplateSubType.layout:
        return '布局结构';
      case TemplateSubType.api:
        return 'API服务';
      case TemplateSubType.business:
        return '业务逻辑';
      case TemplateSubType.integration:
        return '第三方集成';
      case TemplateSubType.model:
        return '数据模型';
      case TemplateSubType.repository:
        return '数据仓库';
      case TemplateSubType.cache:
        return '缓存系统';
      case TemplateSubType.migration:
        return '数据迁移';
      case TemplateSubType.app:
        return '应用程序';
      case TemplateSubType.package:
        return '软件包';
      case TemplateSubType.library:
        return '库文件';
      case TemplateSubType.config:
        return '配置管理';
      case TemplateSubType.infrastructure:
        return '基础设施';
      case TemplateSubType.deployment:
        return '部署脚本';
      case TemplateSubType.standalone:
        return '独立服务';
      case TemplateSubType.gateway:
        return '网关服务';
      case TemplateSubType.messaging:
        return '消息服务';
      case TemplateSubType.extension:
        return '功能扩展';
      case TemplateSubType.middleware:
        return '中间件';
      case TemplateSubType.utility:
        return '工具插件';
      case TemplateSubType.containerization:
        return '容器化';
      case TemplateSubType.monitoring:
        return '监控日志';
      case TemplateSubType.security:
        return '安全认证';
    }
  }
}
