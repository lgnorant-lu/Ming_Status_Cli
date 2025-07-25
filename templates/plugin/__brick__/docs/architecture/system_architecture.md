# {{plugin_display_name}} 系统架构文档

## 架构概述

{{plugin_display_name}} 采用分层架构设计，完全兼容 Pet App V3 插件系统，提供清晰的职责分离和良好的可扩展性。

## 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Pet App V3 主应用                        │
├─────────────────────────────────────────────────────────────┤
│                   Plugin System Layer                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Plugin API    │  │ Plugin Manager  │  │ Plugin UI   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                {{plugin_display_name}}                      │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                Plugin Core Layer                       │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │ │
│  │  │ Plugin Main │  │Plugin Core  │  │ State Manager   │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
{{#include_services}}
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                Service Layer                           │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │ │
│  │  │  Services   │  │   Models    │  │     Utils       │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
{{/include_services}}
{{#include_ui_components}}
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 UI Layer                               │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │ │
│  │  │   Widgets   │  │    Pages    │  │     Themes      │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
{{/include_ui_components}}
└─────────────────────────────────────────────────────────────┘
```

## 核心组件

### 1. Plugin Core Layer (插件核心层)

#### {{plugin_name.pascalCase()}}Plugin
- **职责**: 插件主入口，实现Pet App V3 Plugin接口
- **位置**: `lib/src/plugin_core.dart`
- **关键功能**:
  - 插件生命周期管理
  - 状态管理和通知
  - 消息处理和路由
  - 与Pet App V3系统集成

#### State Manager (状态管理器)
- **职责**: 管理插件状态和状态变化通知
- **实现**: 内置在 `{{plugin_name.pascalCase()}}Plugin` 中
- **状态流**: `StreamController<PluginState>`
- **状态安全**: 防止在已关闭的流中添加事件

{{#include_services}}
### 2. Service Layer (服务层)

#### Services (服务目录)
- **位置**: `lib/src/services/` (预留)
- **用途**: 业务逻辑服务、API调用、数据处理

#### Models (模型目录)
- **位置**: `lib/src/models/` (预留)
- **用途**: 数据模型定义、序列化/反序列化

#### Utils (工具目录)
- **位置**: `lib/src/utils/` (预留)
- **用途**: 工具函数、常量定义、辅助类
{{/include_services}}

{{#include_ui_components}}
### 3. UI Layer (UI层)

#### Widgets (组件目录)
- **位置**: `lib/src/ui/widgets/` (预留)
- **用途**: 可复用的UI组件

#### Pages (页面目录)
- **位置**: `lib/src/ui/pages/` (预留)
- **用途**: 完整的页面组件

#### Themes (主题目录)
- **位置**: `lib/src/ui/themes/` (预留)
- **用途**: 主题配置、样式定义
{{/include_ui_components}}

## 设计原则

### 1. 单一职责原则 (SRP)
每个类和模块都有明确的单一职责：
- `{{plugin_name.pascalCase()}}Plugin`: 插件生命周期管理
- 状态管理器: 状态跟踪和通知
{{#include_services}}
- 服务层: 业务逻辑处理
{{/include_services}}
{{#include_ui_components}}
- UI层: 用户界面展示
{{/include_ui_components}}

### 2. 开闭原则 (OCP)
- 通过继承Pet App V3的Plugin基类实现扩展
{{#include_services}}
- 预留服务层和UI层目录支持功能扩展
{{/include_services}}
- 消息处理机制支持自定义消息类型

### 3. 依赖倒置原则 (DIP)
- 依赖Pet App V3的抽象Plugin接口
- 使用枚举类型而非硬编码字符串
- 通过接口而非具体实现进行交互

### 4. 接口隔离原则 (ISP)
- 实现Pet App V3要求的最小接口集合
- 可选功能通过独立方法提供
- UI接口与核心逻辑分离

## 数据流

### 1. 插件生命周期数据流
```
Pet App V3 → Plugin Manager → {{plugin_name.pascalCase()}}Plugin
                                    ↓
                              State Manager
                                    ↓
                            State Change Stream
                                    ↓
                              UI Components
```

### 2. 消息处理数据流
```
External Message → handleMessage() → Message Router → Handler
                                                          ↓
                                                    Response
```

### 3. 状态管理数据流
```
Lifecycle Method → _updateState() → StreamController → Listeners
```

## 扩展点

{{#include_services}}
### 1. 自定义服务
在 `lib/src/services/` 中添加业务逻辑服务：
```dart
// lib/src/services/my_service.dart
class MyService {
  Future<void> doSomething() async {
    // 自定义业务逻辑
  }
}
```
{{/include_services}}

{{#include_ui_components}}
### 2. 自定义UI组件
在 `lib/src/ui/widgets/` 中添加UI组件：
```dart
// lib/src/ui/widgets/my_widget.dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 自定义UI
  }
}
```
{{/include_ui_components}}

### 3. 自定义消息处理
扩展 `handleMessage()` 方法：
```dart
@override
Future<dynamic> handleMessage(String action, Map<String, dynamic> data) async {
  switch (action) {
    case 'customAction':
      return await handleCustomAction(data);
    default:
      return await super.handleMessage(action, data);
  }
}
```

## 性能考虑

### 1. 状态管理性能
- 使用 `StreamController.broadcast()` 支持多个监听器
- 状态变化时进行去重检查
- 及时关闭流避免内存泄漏

### 2. 生命周期性能
- 异步方法避免阻塞主线程
- 错误处理确保状态一致性
- 资源及时释放

### 3. 内存管理
- 在 `dispose()` 中关闭所有流
- 清理事件监听器和定时器
- 释放大对象引用

## 安全考虑

### 1. 状态安全
- 状态变化原子性操作
- 错误状态的恢复机制
- 并发访问保护

### 2. 消息安全
- 消息类型验证
- 参数安全检查
- 异常处理和日志记录

## 测试策略

### 1. 单元测试
- 核心逻辑测试: `test/unit/`
- 状态管理测试
- 消息处理测试

{{#include_ui_components}}
### 2. Widget测试
- UI组件测试: `test/widget/`
- 用户交互测试
{{/include_ui_components}}

### 3. 集成测试
- 完整生命周期测试: `test/integration/`
- Pet App V3集成测试

## 部署架构

插件作为独立包部署，通过Pet App V3的插件管理器加载：

```
Pet App V3 Plugin Directory
├── {{plugin_name}}/
│   ├── plugin.yaml          # 插件清单
│   ├── lib/                 # 插件代码
│   └── assets/              # 插件资源
```

## 版本兼容性

- **Pet App V3**: 完全兼容
- **Dart SDK**: {{dart_version}}
- **Flutter**: 支持所有LTS版本

## 未来规划

1. **Phase 1**: 核心功能完善
{{#include_ui_components}}
2. **Phase 2**: UI组件开发
{{/include_ui_components}}
3. **Phase 3**: 高级功能扩展
4. **Phase 4**: 性能优化和稳定性提升
