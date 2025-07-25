# {{plugin_display_name}} API 文档

## 概述

{{plugin_display_name}} 是一个为 Pet App V3 设计的{{plugin_type}}插件，提供完整的插件生命周期管理和功能实现。

## 核心API

### {{plugin_name.pascalCase()}}Plugin 类

主要的插件实现类，继承自 Pet App V3 的 `Plugin` 基类。

#### 基本属性

```dart
String get id => '{{plugin_name}}';
String get name => '{{plugin_display_name}}';
String get version => '{{version}}';
String get description => '{{description}}';
String get author => '{{author}}';
PluginType get category => PluginType.{{plugin_type}};
```

#### 平台支持

```dart
List<SupportedPlatform> get supportedPlatforms => [
  SupportedPlatform.android,
  SupportedPlatform.ios,
  SupportedPlatform.web,
  SupportedPlatform.windows,
  SupportedPlatform.macos,
  SupportedPlatform.linux,
];
```

#### 生命周期方法

##### initialize()
```dart
Future<void> initialize()
```
初始化插件，设置基本配置和资源。

**状态变化**: `uninitialized` → `initializing` → `initialized`

##### start()
```dart
Future<void> start()
```
启动插件的主要功能。

**前置条件**: 插件必须已初始化
**状态变化**: `initialized` → `starting` → `started`

##### pause()
```dart
Future<void> pause()
```
暂停插件运行，保存当前状态。

**前置条件**: 插件必须正在运行
**状态变化**: `started` → `pausing` → `paused`

##### resume()
```dart
Future<void> resume()
```
从暂停状态恢复插件运行。

**前置条件**: 插件必须处于暂停状态
**状态变化**: `paused` → `resuming` → `started`

##### stop()
```dart
Future<void> stop()
```
停止插件运行，但保持初始化状态。

**前置条件**: 插件必须正在运行或暂停
**状态变化**: `started`/`paused` → `stopping` → `stopped`

##### dispose()
```dart
Future<void> dispose()
```
完全销毁插件，释放所有资源。

**状态变化**: 任何状态 → `disposing` → `disposed`

#### 状态管理

##### currentState
```dart
PluginState get currentState
```
获取插件当前状态。

**可能的状态**:
- `uninitialized` - 未初始化
- `initializing` - 初始化中
- `initialized` - 已初始化
- `starting` - 启动中
- `started` - 已启动
- `pausing` - 暂停中
- `paused` - 已暂停
- `resuming` - 恢复中
- `stopping` - 停止中
- `stopped` - 已停止
- `disposing` - 销毁中
- `disposed` - 已销毁
- `error` - 错误状态

##### stateChanges
```dart
Stream<PluginState> get stateChanges
```
监听插件状态变化的流。

#### 消息处理

##### handleMessage()
```dart
Future<dynamic> handleMessage(String action, Map<String, dynamic> data)
```
处理来自其他插件或系统的消息。

**支持的消息**:
- `ping` - 心跳检测，返回 `{status: 'pong', timestamp: int}`
- `getInfo` - 获取插件信息，返回插件基本信息Map
- `getState` - 获取当前状态，返回 `{state: string}`

#### UI接口

##### getConfigWidget()
```dart
Object? getConfigWidget()
```
返回插件配置界面Widget（当前返回null）。

##### getMainWidget()
```dart
Object getMainWidget()
```
返回插件主界面Widget（当前返回占位符字符串）。

## 使用示例

```dart
import 'package:{{plugin_name}}/{{plugin_name}}.dart';

void main() async {
  // 创建插件实例
  final plugin = {{plugin_name.pascalCase()}}Plugin();
  
  // 监听状态变化
  plugin.stateChanges.listen((state) {
    print('插件状态变化: $state');
  });
  
  // 初始化并启动插件
  await plugin.initialize();
  await plugin.start();
  
  // 发送消息
  final result = await plugin.handleMessage('ping', {});
  print('Ping结果: $result');
  
  // 停止并销毁插件
  await plugin.stop();
  await plugin.dispose();
}
```

## 错误处理

所有生命周期方法都会在发生错误时：
1. 将状态设置为 `error`
2. 记录错误日志
3. 重新抛出异常供调用者处理

## 扩展指南

要扩展插件功能，可以：
1. 重写生命周期方法添加自定义逻辑
2. 在 `handleMessage()` 中添加自定义消息处理
3. 实现 `getConfigWidget()` 和 `getMainWidget()` 提供UI界面
4. 添加自定义属性和方法

## 版本历史

- v{{version}} (2025-07-25): 初始版本，完整的Pet App V3插件系统兼容性
