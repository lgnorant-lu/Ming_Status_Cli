/*
---------------------------------------------------------------
File name:          {{plugin_name.snakeCase()}}.dart
Author:             {{author}}
{{#author_email}}Email:              {{author_email}}
{{/author_email}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       {{dart_version}}
Description:        {{plugin_name.titleCase()}} - {{description}}
---------------------------------------------------------------
Change History:
    {{generated_date}}: Initial creation - {{description}};
---------------------------------------------------------------
*/

/// {{plugin_name.titleCase()}} Plugin Library
/// 
/// {{description}}
/// 
/// 这是一个为Pet App V3设计的{{plugin_type}}插件，提供以下功能：
/// - 插件核心功能实现
{{#include_ui_components}}/// - UI组件和界面元素
{{/include_ui_components}}{{#include_services}}/// - 后台服务和数据处理
{{/include_services}}
/// - 多平台兼容性支持
/// - 完整的生命周期管理
/// 
/// ## 使用方法
/// 
/// ```dart
/// import 'package:{{plugin_name}}/{{plugin_name}}.dart';
/// 
/// // 创建插件实例
/// final plugin = {{plugin_name.pascalCase()}}Plugin();
/// 
/// // 初始化插件
/// await plugin.initialize();
/// 
/// // 启动插件
/// await plugin.start();{{#include_ui_components}}
/// 
/// // 获取插件UI组件
/// final widget = plugin.getMainWidget();{{/include_ui_components}}
/// ```
/// 
/// ## 权限要求
/// {{#need_file_system}}
/// - 文件系统访问权限{{/need_file_system}}{{#need_network}}
/// - 网络访问权限{{/need_network}}{{#need_camera}}
/// - 摄像头访问权限{{/need_camera}}{{#need_microphone}}
/// - 麦克风访问权限{{/need_microphone}}{{#need_location}}
/// - 位置信息访问权限{{/need_location}}{{#need_notifications}}
/// - 系统通知权限{{/need_notifications}}
/// 
/// ## 平台支持
/// {{#support_android}}
/// - ✅ Android{{/support_android}}{{#support_ios}}
/// - ✅ iOS{{/support_ios}}{{#support_web}}
/// - ✅ Web{{/support_web}}{{#support_desktop}}
/// - ✅ Windows
/// - ✅ macOS
/// - ✅ Linux{{/support_desktop}}
/// 
/// ## 作者信息
/// 
/// **作者**: {{author}}{{#author_email}}  
/// **邮箱**: {{author_email}}{{/author_email}}  
/// **版本**: {{version}}  
/// **许可证**: {{license}}
library {{plugin_name}};

// 导出插件核心类
export 'src/{{plugin_name.snakeCase()}}_plugin.dart';

// 导出插件接口和类型定义
export 'src/types/{{plugin_name.snakeCase()}}_types.dart';
export 'src/interfaces/{{plugin_name.snakeCase()}}_interface.dart';{{#include_ui_components}}

// 导出UI组件
export 'src/widgets/{{plugin_name.snakeCase()}}_widget.dart';{{/include_ui_components}}{{#include_services}}

// 导出服务类
export 'src/services/{{plugin_name.snakeCase()}}_service.dart';{{/include_services}}

// 导出工具类和扩展
export 'src/utils/{{plugin_name.snakeCase()}}_utils.dart';
export 'src/extensions/{{plugin_name.snakeCase()}}_extensions.dart';

// 导出常量和配置
export 'src/constants/{{plugin_name.snakeCase()}}_constants.dart';
export 'src/config/{{plugin_name.snakeCase()}}_config.dart';

// 导出异常类
export 'src/exceptions/{{plugin_name.snakeCase()}}_exceptions.dart';
