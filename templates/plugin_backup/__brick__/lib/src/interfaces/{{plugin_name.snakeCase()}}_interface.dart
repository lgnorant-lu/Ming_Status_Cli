/*
---------------------------------------------------------------
File name:          {{plugin_name.snakeCase()}}_interface.dart
Author:             {{author}}{{#author_email}}
Email:              {{author_email}}{{/author_email}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       {{dart_version}}
Description:        {{plugin_name.titleCase()}}插件接口定义
---------------------------------------------------------------
Change History:
    {{generated_date}}: Initial creation - 插件接口定义;
---------------------------------------------------------------
*/

import 'dart:async';
import '../types/{{plugin_name.snakeCase()}}_types.dart';

/// {{plugin_name.titleCase()}}插件接口
/// 
/// 定义插件的核心功能接口，确保插件实现的一致性和可扩展性
abstract class {{plugin_name.pascalCase()}}Interface {
  /// 获取插件当前状态
  {{plugin_name.pascalCase()}}State get currentState;
  
  /// 获取插件配置
  {{plugin_name.pascalCase()}}ConfigData get config;
  
  /// 状态变化流
  Stream<{{plugin_name.pascalCase()}}State> get stateChanges;
  
  /// 事件流
  Stream<{{plugin_name.pascalCase()}}Event> get events;

  /// 初始化插件
  /// 
  /// 执行插件的初始化操作，包括配置加载、资源准备等
  /// 
  /// 返回初始化结果
  Future<{{plugin_name.pascalCase()}}Result<void>> initialize();

  /// 启动插件
  /// 
  /// 启动插件的核心功能
  /// 
  /// 返回启动结果
  Future<{{plugin_name.pascalCase()}}Result<void>> start();

  /// 暂停插件
  /// 
  /// 暂停插件的运行，保持状态但停止处理
  /// 
  /// 返回暂停结果
  Future<{{plugin_name.pascalCase()}}Result<void>> pause();

  /// 恢复插件
  /// 
  /// 从暂停状态恢复插件运行
  /// 
  /// 返回恢复结果
  Future<{{plugin_name.pascalCase()}}Result<void>> resume();

  /// 停止插件
  /// 
  /// 停止插件运行并清理资源
  /// 
  /// 返回停止结果
  Future<{{plugin_name.pascalCase()}}Result<void>> stop();

  /// 重启插件
  /// 
  /// 停止并重新启动插件
  /// 
  /// 返回重启结果
  Future<{{plugin_name.pascalCase()}}Result<void>> restart();

  /// 更新配置
  /// 
  /// [newConfig] 新的配置数据
  /// 
  /// 返回更新结果
  Future<{{plugin_name.pascalCase()}}Result<void>> updateConfig(
    {{plugin_name.pascalCase()}}ConfigData newConfig,
  );

  /// 获取插件状态信息
  /// 
  /// 返回包含详细状态信息的Map
  Map<String, dynamic> getStatusInfo();

  /// 执行自定义操作
  /// 
  /// [action] 操作名称
  /// [parameters] 操作参数
  /// 
  /// 返回操作结果
  Future<{{plugin_name.pascalCase()}}Result<dynamic>> executeAction(
    String action,
    Map<String, dynamic> parameters,
  );

  /// 验证插件配置
  /// 
  /// [config] 要验证的配置
  /// 
  /// 返回验证结果
  {{plugin_name.pascalCase()}}Result<void> validateConfig(
    {{plugin_name.pascalCase()}}ConfigData config,
  );

  /// 获取插件能力信息
  /// 
  /// 返回插件支持的功能和能力列表
  List<String> getCapabilities();

  /// 检查插件健康状态
  /// 
  /// 返回健康检查结果
  Future<{{plugin_name.pascalCase()}}Result<Map<String, dynamic>>> healthCheck();
}{{#include_ui_components}}

/// {{plugin_name.titleCase()}}UI接口
/// 
/// 定义插件UI相关的接口
abstract class {{plugin_name.pascalCase()}}UIInterface {
  /// 获取主界面组件
  Object getMainWidget();

  /// 获取配置界面组件
  Object? getConfigWidget();

  /// 获取状态指示器组件
  Object? getStatusWidget();

  /// 更新UI主题
  /// 
  /// [themeData] 主题数据
  void updateTheme(Map<String, dynamic> themeData);

  /// 显示通知
  /// 
  /// [message] 通知消息
  /// [type] 通知类型
  void showNotification(String message, String type);

  /// 隐藏UI
  void hideUI();

  /// 显示UI
  void showUI();

  /// 检查UI是否可见
  bool get isUIVisible;
}{{/include_ui_components}}{{#include_services}}

/// {{plugin_name.titleCase()}}服务接口
/// 
/// 定义插件服务层的接口
abstract class {{plugin_name.pascalCase()}}ServiceInterface {
  /// 初始化服务
  Future<{{plugin_name.pascalCase()}}Result<void>> initializeService();

  /// 启动服务
  Future<{{plugin_name.pascalCase()}}Result<void>> startService();

  /// 停止服务
  Future<{{plugin_name.pascalCase()}}Result<void>> stopService();

  /// 获取服务状态
  Map<String, dynamic> getServiceStatus();

  /// 处理服务请求
  /// 
  /// [request] 请求数据
  /// 
  /// 返回处理结果
  Future<{{plugin_name.pascalCase()}}Result<dynamic>> handleRequest(
    Map<String, dynamic> request,
  );

  /// 注册服务监听器
  /// 
  /// [listener] 监听器函数
  void registerListener(Function({{plugin_name.pascalCase()}}Event) listener);

  /// 取消注册服务监听器
  /// 
  /// [listener] 监听器函数
  void unregisterListener(Function({{plugin_name.pascalCase()}}Event) listener);
}{{/include_services}}

/// {{plugin_name.titleCase()}}数据接口
/// 
/// 定义插件数据操作的接口
abstract class {{plugin_name.pascalCase()}}DataInterface {
  /// 保存数据
  /// 
  /// [key] 数据键
  /// [value] 数据值
  /// 
  /// 返回保存结果
  Future<{{plugin_name.pascalCase()}}Result<void>> saveData(
    String key,
    dynamic value,
  );

  /// 加载数据
  /// 
  /// [key] 数据键
  /// 
  /// 返回加载的数据
  Future<{{plugin_name.pascalCase()}}Result<dynamic>> loadData(String key);

  /// 删除数据
  /// 
  /// [key] 数据键
  /// 
  /// 返回删除结果
  Future<{{plugin_name.pascalCase()}}Result<void>> deleteData(String key);

  /// 清空所有数据
  /// 
  /// 返回清空结果
  Future<{{plugin_name.pascalCase()}}Result<void>> clearAllData();

  /// 检查数据是否存在
  /// 
  /// [key] 数据键
  /// 
  /// 返回是否存在
  Future<bool> hasData(String key);

  /// 获取所有数据键
  /// 
  /// 返回所有键的列表
  Future<List<String>> getAllKeys();
}

/// {{plugin_name.titleCase()}}事件接口
/// 
/// 定义插件事件处理的接口
abstract class {{plugin_name.pascalCase()}}EventInterface {
  /// 发送事件
  /// 
  /// [event] 要发送的事件
  void sendEvent({{plugin_name.pascalCase()}}Event event);

  /// 注册事件监听器
  /// 
  /// [eventType] 事件类型
  /// [listener] 监听器函数
  void addEventListener(
    {{plugin_name.pascalCase()}}EventType eventType,
    Function({{plugin_name.pascalCase()}}Event) listener,
  );

  /// 移除事件监听器
  /// 
  /// [eventType] 事件类型
  /// [listener] 监听器函数
  void removeEventListener(
    {{plugin_name.pascalCase()}}EventType eventType,
    Function({{plugin_name.pascalCase()}}Event) listener,
  );

  /// 清空所有事件监听器
  void clearAllEventListeners();

  /// 获取事件历史
  /// 
  /// [limit] 限制数量
  /// 
  /// 返回事件历史列表
  List<{{plugin_name.pascalCase()}}Event> getEventHistory({int? limit});
}
