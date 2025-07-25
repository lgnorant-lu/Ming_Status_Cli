/*
---------------------------------------------------------------
File name:          index.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件系统核心模块导出 (Plugin system core module exports)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 插件系统核心模块统一导出;
---------------------------------------------------------------
*/

/// 插件系统核心模块
///
/// 提供完整的插件开发、管理和发布功能，与Pet App V3插件系统完全兼容。
///
/// ## 核心组件
/// - [PluginValidator] - 插件验证器
/// - [PluginBuilder] - 插件构建器（待实现）
/// - [PluginPublisher] - 插件发布器（待实现）
/// - [LocalRegistry] - 本地插件注册表（待实现）
/// - [PluginManager] - 插件管理器（待实现）
///
/// ## 使用示例
/// ```dart
/// import 'package:ming_status_cli/src/core/plugin_system/index.dart';
///
/// // 验证插件
/// final validator = PluginValidator();
/// final result = await validator.validatePlugin('./my_plugin');
///
/// // 构建插件
/// final builder = PluginBuilder();
/// await builder.buildPlugin('./my_plugin', './dist');
/// ```
library plugin_system;

// 核心验证器
export 'plugin_validator.dart';

// 核心构建器
export 'plugin_builder.dart';

// 核心发布器
export 'plugin_publisher.dart';

// 本地注册表
export 'local_registry.dart';

// Pet App V3桥接层
export 'pet_app_bridge.dart';

// 依赖解析器
export 'dependency_resolver.dart';

// TODO: 添加其他核心组件的导出
// export 'plugin_manager.dart';
