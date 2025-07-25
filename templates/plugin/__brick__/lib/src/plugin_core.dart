/*
---------------------------------------------------------------
File name:          plugin_core.dart
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

import 'dart:async';
import 'dart:developer' as developer;

/// 插件类型枚举
enum PluginType {
  tool,
  game,
  utility,
  social,
  productivity,
  entertainment,
  education,
  business,
}

/// 插件权限枚举
enum PluginPermission {
  fileSystem,
  network,
  camera,
  microphone,
  location,
  storage,
}

/// 插件权限扩展
extension PluginPermissionExtension on PluginPermission {
  /// 获取权限的显示名称
  String get displayName {
    switch (this) {
      case PluginPermission.fileSystem:
        return '文件系统访问';
      case PluginPermission.network:
        return '网络访问';
      case PluginPermission.camera:
        return '摄像头访问';
      case PluginPermission.microphone:
        return '麦克风访问';
      case PluginPermission.location:
        return '位置访问';
      case PluginPermission.storage:
        return '存储访问';
    }
  }
}

/// 插件依赖
class PluginDependency {
  final String name;
  final String version;
  
  const PluginDependency({required this.name, required this.version});
}

/// 支持的平台枚举
enum SupportedPlatform {
  android,
  ios,
  web,
  windows,
  macos,
  linux,
}

/// 插件状态枚举
enum PluginState {
  uninitialized,
  initializing,
  initialized,
  starting,
  started,
  pausing,
  paused,
  resuming,
  stopping,
  stopped,
  disposing,
  disposed,
  unloaded,
  loaded,
  error,
}

/// Pet App V3 Plugin 基类 (模拟定义)
/// 在实际使用中，这应该从 package:plugin_system/plugin_system.dart 导入
abstract class Plugin {
  String get id;
  String get name;
  String get version;
  String get description;
  String get author;
  PluginType get category;
  List<PluginPermission> get requiredPermissions;
  List<PluginDependency> get dependencies;
  List<SupportedPlatform> get supportedPlatforms;

  Future<void> initialize();
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
  Object? getConfigWidget();
  Object? getMainWidget();
  Future<dynamic> handleMessage(String action, Map<String, dynamic> data);
  PluginState get currentState;
  Stream<PluginState> get stateChanges;
}

/// {{plugin_display_name}} 插件实现
class {{plugin_name.pascalCase()}}Plugin extends Plugin {
  // 状态管理
  PluginState _currentState = PluginState.uninitialized;
  final StreamController<PluginState> _stateController = StreamController<PluginState>.broadcast();

  @override
  String get id => '{{plugin_name}}';

  @override
  String get name => '{{plugin_display_name}}';

  @override
  String get version => '{{version}}';

  @override
  String get description => '{{description}}';

  @override
  String get author => '{{author}}';

  @override
  PluginType get category => PluginType.{{plugin_type}};

  @override
  List<PluginPermission> get requiredPermissions => [];

  @override
  List<PluginDependency> get dependencies => [
    const PluginDependency(name: 'pet_app_core', version: '^3.0.0'),
    const PluginDependency(name: 'plugin_system', version: '^1.0.0'),
  ];

  @override
  List<SupportedPlatform> get supportedPlatforms => [
    SupportedPlatform.android,
    SupportedPlatform.ios,
    SupportedPlatform.web,
    SupportedPlatform.windows,
    SupportedPlatform.macos,
    SupportedPlatform.linux,
  ];

  @override
  PluginState get currentState => _currentState;

  @override
  Stream<PluginState> get stateChanges => _stateController.stream;

  @override
  Future<void> initialize() async {
    _updateState(PluginState.initializing);
    
    try {
      developer.log('初始化插件: $name', name: name);
      
      // 在这里添加初始化逻辑
      await Future.delayed(const Duration(milliseconds: 100));
      
      _updateState(PluginState.initialized);
      developer.log('插件初始化完成', name: name);
    } catch (e) {
      _updateState(PluginState.error);
      developer.log('插件初始化失败: $e', name: name, level: 1000);
      rethrow;
    }
  }

  @override
  Future<void> start() async {
    if (_currentState != PluginState.initialized && _currentState != PluginState.stopped) {
      throw StateError('插件必须先初始化才能启动');
    }
    
    _updateState(PluginState.starting);
    
    try {
      developer.log('启动插件: $name', name: name);
      
      // 在这里添加启动逻辑
      await Future.delayed(const Duration(milliseconds: 100));
      
      _updateState(PluginState.started);
      developer.log('插件启动完成', name: name);
    } catch (e) {
      _updateState(PluginState.error);
      developer.log('插件启动失败: $e', name: name, level: 1000);
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    if (_currentState != PluginState.started) {
      throw StateError('只有运行中的插件才能暂停');
    }
    
    _updateState(PluginState.pausing);
    
    try {
      developer.log('暂停插件: $name', name: name);
      
      // 在这里添加暂停逻辑
      await Future.delayed(const Duration(milliseconds: 50));
      
      _updateState(PluginState.paused);
      developer.log('插件暂停完成', name: name);
    } catch (e) {
      _updateState(PluginState.error);
      developer.log('插件暂停失败: $e', name: name, level: 1000);
      rethrow;
    }
  }

  @override
  Future<void> resume() async {
    if (_currentState != PluginState.paused) {
      throw StateError('只有暂停的插件才能恢复');
    }
    
    _updateState(PluginState.resuming);
    
    try {
      developer.log('恢复插件: $name', name: name);
      
      // 在这里添加恢复逻辑
      await Future.delayed(const Duration(milliseconds: 50));
      
      _updateState(PluginState.started);
      developer.log('插件恢复完成', name: name);
    } catch (e) {
      _updateState(PluginState.error);
      developer.log('插件恢复失败: $e', name: name, level: 1000);
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    if (_currentState != PluginState.started && _currentState != PluginState.paused) {
      throw StateError('只有运行中或暂停的插件才能停止');
    }
    
    _updateState(PluginState.stopping);
    
    try {
      developer.log('停止插件: $name', name: name);
      
      // 在这里添加停止逻辑
      await Future.delayed(const Duration(milliseconds: 100));
      
      _updateState(PluginState.stopped);
      developer.log('插件停止完成', name: name);
    } catch (e) {
      _updateState(PluginState.error);
      developer.log('插件停止失败: $e', name: name, level: 1000);
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    _updateState(PluginState.disposing);
    
    try {
      developer.log('销毁插件: $name', name: name);
      
      // 在这里添加清理逻辑
      await Future.delayed(const Duration(milliseconds: 50));
      
      _updateState(PluginState.disposed);
      await _stateController.close();
      
      developer.log('插件销毁完成', name: name);
    } catch (e) {
      _updateState(PluginState.error);
      developer.log('插件销毁失败: $e', name: name, level: 1000);
      rethrow;
    }
  }

  @override
  Object? getConfigWidget() {
    // 返回配置界面Widget
    // 在实际实现中，这里应该返回一个Flutter Widget
    return null;
  }

  @override
  Object? getMainWidget() {
    // 返回主界面Widget
    // 在实际实现中，这里应该返回一个Flutter Widget
    return null; // 返回null，让example应用处理
  }

  @override
  Future<dynamic> handleMessage(String action, Map<String, dynamic> data) async {
    developer.log('处理消息: $action', name: name);
    
    switch (action) {
      case 'ping':
        return {
          'status': 'pong',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      
      case 'getInfo':
        return getInfo();
      
      case 'getState':
        return {
          'state': _currentState.toString(),
        };
      
      default:
        throw UnsupportedError('不支持的操作: $action');
    }
  }

  /// 获取插件信息
  Map<String, dynamic> getInfo() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'author': author,
      'category': category.toString(),
      'platforms': supportedPlatforms.map((p) => p.toString()).toList(),
      'state': _currentState.toString(),
    };
  }

  /// 更新插件状态
  void _updateState(PluginState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }
}
