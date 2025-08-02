/*
---------------------------------------------------------------
File name:          plugin_main.dart
Author:             {{author}}
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       {{dart_version}}
Description:        {{plugin_display_name}} - {{description}}
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - {{description}};
---------------------------------------------------------------
*/

/// {{plugin_display_name}} Plugin Library
///
/// {{description}}
///
/// 这是一个为Pet App V3设计的{{plugin_type}}插件，提供以下功能：
/// - 插件核心功能实现
{{#include_ui_components}}
/// - UI组件和界面元素
{{/include_ui_components}}
/// - 多平台兼容性支持
///
/// ## 使用方法
///
/// ```dart
/// import 'package:{{plugin_name}}/{{plugin_name}}.dart';
///
/// final plugin = {{plugin_name.pascalCase()}}Plugin();
/// await plugin.initialize();
/// ```
///
/// ## 权限要求
///
///
/// ## 平台支持
///
/// - ✅ Android
/// - ✅ iOS
/// - ✅ Web
/// - ✅ Desktop (Windows/macOS/Linux)

library {{plugin_name}};

// 导出Pet App V3插件系统
export 'package:plugin_system/plugin_system.dart';

// 导出核心插件类
export 'src/plugin_core.dart';
