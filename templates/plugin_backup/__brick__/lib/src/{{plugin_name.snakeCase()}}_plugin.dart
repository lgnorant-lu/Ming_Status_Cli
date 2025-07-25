/*
---------------------------------------------------------------
File name:          {{plugin_name.snakeCase()}}_plugin.dart
Author:             {{author}}{{#author_email}}
Email:              {{author_email}}{{/author_email}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       {{dart_version}}
Description:        {{plugin_name.titleCase()}}插件主实现类
---------------------------------------------------------------
Change History:
    {{generated_date}}: Initial creation - 插件主实现类;
---------------------------------------------------------------
*/

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plugin_system/plugin_system.dart';

import 'types/{{plugin_name.snakeCase()}}_types.dart';
import 'interfaces/{{plugin_name.snakeCase()}}_interface.dart';{{#include_ui_components}}
import 'widgets/{{plugin_name.snakeCase()}}_widget.dart';{{/include_ui_components}}{{#include_services}}
import 'services/{{plugin_name.snakeCase()}}_service.dart';{{/include_services}}
import 'config/{{plugin_name.snakeCase()}}_config.dart';
import 'constants/{{plugin_name.snakeCase()}}_constants.dart';
import 'exceptions/{{plugin_name.snakeCase()}}_exceptions.dart';

/// {{plugin_name.titleCase()}}插件主实现类
/// 
/// 这是{{plugin_name.titleCase()}}插件的核心实现，继承自Pet App V3插件系统的Plugin基类。
/// 提供完整的插件生命周期管理和功能实现。
/// 
/// ## 功能特性
/// - 完整的插件生命周期管理
/// - 多平台兼容性支持{{#include_ui_components}}
/// - 丰富的UI组件{{/include_ui_components}}{{#include_services}}
/// - 后台服务支持{{/include_services}}
/// - 权限管理和安全控制
/// - 配置管理和持久化
/// 
/// ## 使用示例
/// ```dart
/// final plugin = {{plugin_name.pascalCase()}}Plugin();
/// await plugin.initialize();
/// await plugin.start();
/// ```
class {{plugin_name.pascalCase()}}Plugin extends Plugin implements {{plugin_name.pascalCase()}}Interface {
  /// 插件配置
  late final {{plugin_name.pascalCase()}}Config _config;
  
  /// 插件状态控制器
  final StreamController<PluginState> _stateController = StreamController<PluginState>.broadcast();
  
  /// 当前插件状态
  PluginState _currentState = PluginState.unloaded;{{#include_services}}
  
  /// 插件服务实例
  {{plugin_name.pascalCase()}}Service? _service;{{/include_services}}
  
  /// 是否已初始化
  bool _isInitialized = false;
  
  /// 创建{{plugin_name.titleCase()}}插件实例
  {{plugin_name.pascalCase()}}Plugin() {
    _config = {{plugin_name.pascalCase()}}Config();
  }

  // ============================================================================
  // Plugin基类必需实现的属性
  // ============================================================================

  @override
  String get id => {{plugin_name.pascalCase()}}Constants.pluginId;

  @override
  String get name => {{plugin_name.pascalCase()}}Constants.pluginName;

  @override
  String get version => {{plugin_name.pascalCase()}}Constants.pluginVersion;

  @override
  String get description => {{plugin_name.pascalCase()}}Constants.pluginDescription;

  @override
  String get author => {{plugin_name.pascalCase()}}Constants.pluginAuthor;

  @override
  PluginType get category => PluginType.{{plugin_type}};

  @override
  List<PluginPermission> get requiredPermissions => [{{#need_file_system}}
    PluginPermission.fileSystem,{{/need_file_system}}{{#need_network}}
    PluginPermission.network,{{/need_network}}{{#need_camera}}
    PluginPermission.camera,{{/need_camera}}{{#need_microphone}}
    PluginPermission.microphone,{{/need_microphone}}{{#need_location}}
    PluginPermission.location,{{/need_location}}{{#need_notifications}}
    PluginPermission.notifications,{{/need_notifications}}
  ];

  @override
  List<PluginDependency> get dependencies => [
    // 核心插件系统依赖
    const PluginDependency(
      pluginId: 'plugin_system',
      versionConstraint: '^1.0.0',
    ),
  ];

  @override
  List<SupportedPlatform> get supportedPlatforms => [{{#support_android}}
    SupportedPlatform.android,{{/support_android}}{{#support_ios}}
    SupportedPlatform.ios,{{/support_ios}}{{#support_web}}
    SupportedPlatform.web,{{/support_web}}{{#support_desktop}}
    SupportedPlatform.windows,
    SupportedPlatform.macos,
    SupportedPlatform.linux,{{/support_desktop}}
  ];

  @override
  PluginState get currentState => _currentState;

  @override
  Stream<PluginState> get stateChanges => _stateController.stream;

  // ============================================================================
  // Plugin基类必需实现的方法
  // ============================================================================

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[$name] 插件已经初始化，跳过重复初始化');
      return;
    }

    try {
      _updateState(PluginState.loaded);
      debugPrint('[$name] 开始初始化插件...');

      // 加载插件配置
      await _config.load();
      debugPrint('[$name] 配置加载完成');{{#include_services}}

      // 初始化服务
      _service = {{plugin_name.pascalCase()}}Service(_config);
      await _service!.initialize();
      debugPrint('[$name] 服务初始化完成');{{/include_services}}

      // 验证权限
      await _validatePermissions();
      debugPrint('[$name] 权限验证完成');

      // 执行平台特定初始化
      await _platformSpecificInitialization();
      debugPrint('[$name] 平台特定初始化完成');

      _isInitialized = true;
      _updateState(PluginState.initialized);
      debugPrint('[$name] 插件初始化完成');
    } catch (e, stackTrace) {
      _updateState(PluginState.error);
      debugPrint('[$name] 插件初始化失败: $e');
      debugPrint('[$name] 堆栈跟踪: $stackTrace');
      throw {{plugin_name.pascalCase()}}Exception('插件初始化失败: $e');
    }
  }

  @override
  Future<void> start() async {
    if (!_isInitialized) {
      throw {{plugin_name.pascalCase()}}Exception('插件未初始化，无法启动');
    }

    if (_currentState == PluginState.started) {
      debugPrint('[$name] 插件已经启动，跳过重复启动');
      return;
    }

    try {
      debugPrint('[$name] 开始启动插件...');{{#include_services}}

      // 启动服务
      await _service?.start();
      debugPrint('[$name] 服务启动完成');{{/include_services}}

      // 执行启动后的初始化工作
      await _postStartInitialization();

      _updateState(PluginState.started);
      debugPrint('[$name] 插件启动完成');
    } catch (e, stackTrace) {
      _updateState(PluginState.error);
      debugPrint('[$name] 插件启动失败: $e');
      debugPrint('[$name] 堆栈跟踪: $stackTrace');
      throw {{plugin_name.pascalCase()}}Exception('插件启动失败: $e');
    }
  }

  @override
  Future<void> pause() async {
    if (_currentState != PluginState.started) {
      debugPrint('[$name] 插件未启动，无法暂停');
      return;
    }

    try {
      debugPrint('[$name] 开始暂停插件...');{{#include_services}}

      // 暂停服务
      await _service?.pause();{{/include_services}}

      _updateState(PluginState.paused);
      debugPrint('[$name] 插件暂停完成');
    } catch (e, stackTrace) {
      debugPrint('[$name] 插件暂停失败: $e');
      debugPrint('[$name] 堆栈跟踪: $stackTrace');
      throw {{plugin_name.pascalCase()}}Exception('插件暂停失败: $e');
    }
  }

  @override
  Future<void> resume() async {
    if (_currentState != PluginState.paused) {
      debugPrint('[$name] 插件未暂停，无法恢复');
      return;
    }

    try {
      debugPrint('[$name] 开始恢复插件...');{{#include_services}}

      // 恢复服务
      await _service?.resume();{{/include_services}}

      _updateState(PluginState.started);
      debugPrint('[$name] 插件恢复完成');
    } catch (e, stackTrace) {
      debugPrint('[$name] 插件恢复失败: $e');
      debugPrint('[$name] 堆栈跟踪: $stackTrace');
      throw {{plugin_name.pascalCase()}}Exception('插件恢复失败: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (_currentState == PluginState.stopped || _currentState == PluginState.unloaded) {
      debugPrint('[$name] 插件已经停止，跳过重复停止');
      return;
    }

    try {
      debugPrint('[$name] 开始停止插件...');{{#include_services}}

      // 停止服务
      await _service?.stop();{{/include_services}}

      _updateState(PluginState.stopped);
      debugPrint('[$name] 插件停止完成');
    } catch (e, stackTrace) {
      debugPrint('[$name] 插件停止失败: $e');
      debugPrint('[$name] 堆栈跟踪: $stackTrace');
      throw {{plugin_name.pascalCase()}}Exception('插件停止失败: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      debugPrint('[$name] 开始销毁插件...');

      // 停止插件
      if (_currentState != PluginState.stopped && _currentState != PluginState.unloaded) {
        await stop();
      }{{#include_services}}

      // 销毁服务
      await _service?.dispose();
      _service = null;{{/include_services}}

      // 关闭状态控制器
      await _stateController.close();

      // 清理配置
      await _config.dispose();

      _isInitialized = false;
      _updateState(PluginState.unloaded);
      debugPrint('[$name] 插件销毁完成');
    } catch (e, stackTrace) {
      debugPrint('[$name] 插件销毁失败: $e');
      debugPrint('[$name] 堆栈跟踪: $stackTrace');
      throw {{plugin_name.pascalCase()}}Exception('插件销毁失败: $e');
    }
  }{{#include_ui_components}}

  @override
  Object? getConfigWidget() {
    // 返回插件配置界面
    return {{plugin_name.pascalCase()}}ConfigWidget(
      config: _config,
      onConfigChanged: (newConfig) async {
        await _config.update(newConfig);
      },
    );
  }

  @override
  Object getMainWidget() {
    // 返回插件主界面
    return {{plugin_name.pascalCase()}}Widget(
      plugin: this,
      config: _config,{{#include_services}}
      service: _service,{{/include_services}}
    );
  }{{/include_ui_components}}{{^include_ui_components}}

  @override
  Object? getConfigWidget() {
    // 该插件不提供配置界面
    return null;
  }

  @override
  Object getMainWidget() {
    // 该插件不提供UI界面，返回占位符
    return const Placeholder(
      child: Text('{{plugin_name.titleCase()}} Plugin'),
    );
  }{{/include_ui_components}}

  @override
  Future<dynamic> handleMessage(String action, Map<String, dynamic> data) async {
    try {
      debugPrint('[$name] 处理消息: $action');
      
      switch (action) {
        case 'getStatus':
          return {
            'state': _currentState.name,
            'initialized': _isInitialized,
            'version': version,
          };
        
        case 'getConfig':
          return _config.toMap();
        
        case 'updateConfig':
          await _config.update(data);
          return {'success': true};{{#include_services}}
        
        case 'getServiceStatus':
          return _service?.getStatus() ?? {'error': 'Service not available'};{{/include_services}}
        
        default:
          throw {{plugin_name.pascalCase()}}Exception('未知的消息动作: $action');
      }
    } catch (e, stackTrace) {
      debugPrint('[$name] 消息处理失败: $e');
      debugPrint('[$name] 堆栈跟踪: $stackTrace');
      return {'error': e.toString()};
    }
  }

  // ============================================================================
  // 私有辅助方法
  // ============================================================================

  /// 更新插件状态
  void _updateState(PluginState newState) {
    if (_currentState != newState) {
      final oldState = _currentState;
      _currentState = newState;
      _stateController.add(newState);
      debugPrint('[$name] 状态变更: ${oldState.name} -> ${newState.name}');
    }
  }

  /// 验证权限
  Future<void> _validatePermissions() async {
    // TODO: 实现权限验证逻辑
    // 这里应该检查所有必需的权限是否已授予
    for (final permission in requiredPermissions) {
      debugPrint('[$name] 验证权限: ${permission.displayName}');
      // 实际的权限检查逻辑
    }
  }

  /// 平台特定初始化
  Future<void> _platformSpecificInitialization() async {
    // TODO: 实现平台特定的初始化逻辑
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android特定初始化
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS特定初始化
    } else if (kIsWeb) {
      // Web特定初始化
    } else {
      // 桌面平台特定初始化
    }
  }

  /// 启动后初始化
  Future<void> _postStartInitialization() async {
    // TODO: 实现启动后的初始化工作
    debugPrint('[$name] 执行启动后初始化');
  }
}
