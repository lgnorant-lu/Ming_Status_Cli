/*
---------------------------------------------------------------
File name:          {{plugin_name}}.dart
Author:             {{author}}
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       {{dart_version}}
Description:        {{plugin_display_name}} - {{description}} - 主入口文件
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - {{description}};
---------------------------------------------------------------
*/

/// {{plugin_display_name}} 插件库
/// 
/// 这是{{plugin_display_name}}插件的主入口文件，提供了插件的所有公共API。
/// 
/// 使用示例:
/// ```dart
/// import 'package:{{plugin_name}}/{{plugin_name}}.dart';
/// 
/// // 创建插件实例
/// final plugin = {{plugin_name.pascalCase()}}Plugin();
/// 
/// // 初始化并启动插件
/// await plugin.initialize();
/// await plugin.start();
/// ```
library {{plugin_name}};

// 导出核心插件类
export 'src/plugin_core.dart';

// 导出主入口
export 'plugin_main.dart';
