# {{plugin_display_name}} 开发者指南

## 开发环境设置

### 前置要求

- **Dart SDK**: {{dart_version}}
- **Pet App V3**: 最新版本
- **IDE**: VS Code 或 IntelliJ IDEA
- **Git**: 版本控制

### 环境配置

1. **克隆项目**
   ```bash
   git clone {{repository_url}}
   cd {{plugin_name}}
   ```

2. **安装依赖**
   ```bash
   dart pub get
   ```

3. **运行测试**
   ```bash
   dart test
   ```

4. **代码分析**
   ```bash
   dart analyze
   ```

## 项目结构

```
{{plugin_name}}/
├── lib/
│   ├── plugin_main.dart          # 主入口文件
│   └── src/
│       ├── plugin_core.dart      # 核心插件实现
{{#include_ui_components}}
│       ├── ui/                   # UI组件
{{/include_ui_components}}
{{#include_services}}
│       ├── services/             # 服务层
{{/include_services}}
{{#include_models}}
│       ├── models/               # 数据模型
{{/include_models}}
{{#include_utils}}
│       ├── utils/                # 工具类
{{/include_utils}}
{{#include_l10n}}
│       └── l10n/                 # 国际化
{{/include_l10n}}
├── test/
│   ├── plugin_core_test.dart     # 核心测试
│   ├── unit/                     # 单元测试
{{#include_ui_components}}
│   ├── widget/                   # Widget测试
{{/include_ui_components}}
│   └── integration/              # 集成测试
├── docs/                         # 文档
├── plugin.yaml                   # 插件清单
├── pubspec.yaml                  # 项目配置
├── analysis_options.yaml         # 代码分析配置
├── CHANGELOG.md                  # 更新日志
└── LICENSE                       # 许可证
```

## 核心概念

### Pet App V3 插件系统

#### Plugin 基类
所有插件必须继承 `Plugin` 抽象基类：

```dart
abstract class Plugin {
  // 基本属性
  String get id;
  String get name;
  String get version;
  String get description;
  String get author;
  PluginType get category;
  
  // 平台和权限
  List<PluginPermission> get requiredPermissions;
  List<PluginDependency> get dependencies;
  List<SupportedPlatform> get supportedPlatforms;
  
  // 生命周期方法
  Future<void> initialize();
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
  
  // UI接口
  Object? getConfigWidget();
  Object getMainWidget();
  
  // 消息处理
  Future<dynamic> handleMessage(String action, Map<String, dynamic> data);
  
  // 状态管理
  PluginState get currentState;
  Stream<PluginState> get stateChanges;
}
```

#### 插件状态
插件具有以下状态：

```dart
enum PluginState {
  uninitialized,    // 未初始化
  initializing,     // 初始化中
  initialized,      // 已初始化
  starting,         // 启动中
  started,          // 已启动
  pausing,          // 暂停中
  paused,           // 已暂停
  resuming,         // 恢复中
  stopping,         // 停止中
  stopped,          // 已停止
  disposing,        // 销毁中
  disposed,         // 已销毁
  error             // 错误状态
}
```

## 开发指南

### 1. 实现插件核心逻辑

#### 基本信息配置
```dart
@override
String get id => '{{plugin_name}}';

@override
String get name => '{{plugin_display_name}}';

@override
String get version => '{{version}}';

@override
PluginType get category => PluginType.{{plugin_type}};
```

#### 生命周期实现
```dart
@override
Future<void> initialize() async {
  _updateState(PluginState.initializing);
  
  try {
    // 初始化逻辑
    await _loadConfiguration();
    await _setupResources();
    
    _updateState(PluginState.initialized);
  } catch (e) {
    _updateState(PluginState.error);
    rethrow;
  }
}
```

#### 状态管理
```dart
void _updateState(PluginState newState) {
  if (_currentState != newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
}
```

### 2. 消息处理

#### 实现消息处理器
```dart
@override
Future<dynamic> handleMessage(String action, Map<String, dynamic> data) async {
  switch (action) {
    case 'ping':
      return {'status': 'pong', 'timestamp': DateTime.now().millisecondsSinceEpoch};
    
    case 'getInfo':
      return getInfo();
    
    case 'customAction':
      return await _handleCustomAction(data);
    
    default:
      throw UnsupportedError('不支持的操作: $action');
  }
}
```

#### 自定义消息处理
```dart
Future<Map<String, dynamic>> _handleCustomAction(Map<String, dynamic> data) async {
  // 处理自定义消息
  final result = await _processCustomLogic(data);
  return {'success': true, 'result': result};
}
```

{{#include_ui_components}}
### 3. UI开发

#### 配置界面
```dart
@override
Object? getConfigWidget() {
  return {{plugin_name.pascalCase()}}ConfigWidget(plugin: this);
}
```

#### 主界面
```dart
@override
Object getMainWidget() {
  return {{plugin_name.pascalCase()}}MainWidget(plugin: this);
}
```
{{/include_ui_components}}

{{#include_services}}
### 4. 服务层开发

#### 创建服务类
```dart
// lib/src/services/my_service.dart
class MyService {
  Future<void> initialize() async {
    // 服务初始化
  }
  
  Future<String> processData(String input) async {
    // 数据处理逻辑
    return processedData;
  }
}
```

#### 在插件中使用服务
```dart
class {{plugin_name.pascalCase()}}Plugin extends Plugin {
  late final MyService _myService;
  
  @override
  Future<void> initialize() async {
    _myService = MyService();
    await _myService.initialize();
    // ...
  }
}
```
{{/include_services}}

{{#include_models}}
### 5. 数据模型

#### 定义数据模型
```dart
// lib/src/models/plugin_config.dart
class PluginConfig {
  final String name;
  final bool autoStart;
  final Map<String, dynamic> settings;
  
  const PluginConfig({
    required this.name,
    required this.autoStart,
    required this.settings,
  });
  
  factory PluginConfig.fromJson(Map<String, dynamic> json) {
    return PluginConfig(
      name: json['name'] as String,
      autoStart: json['autoStart'] as bool,
      settings: json['settings'] as Map<String, dynamic>,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'autoStart': autoStart,
      'settings': settings,
    };
  }
}
```
{{/include_models}}

## 测试开发

### 单元测试

#### 测试插件核心功能
```dart
// test/unit/plugin_core_test.dart
void main() {
  group('{{plugin_name.pascalCase()}}Plugin', () {
    late {{plugin_name.pascalCase()}}Plugin plugin;
    
    setUp(() {
      plugin = {{plugin_name.pascalCase()}}Plugin();
    });
    
    test('should initialize correctly', () async {
      await plugin.initialize();
      expect(plugin.currentState, equals(PluginState.initialized));
    });
    
    test('should handle messages', () async {
      await plugin.initialize();
      final result = await plugin.handleMessage('ping', {});
      expect(result['status'], equals('pong'));
    });
  });
}
```

{{#include_ui_components}}
### Widget测试

#### 测试UI组件
```dart
// test/widget/plugin_widget_test.dart
void main() {
  testWidgets('{{plugin_name.pascalCase()}}Widget should display correctly', (tester) async {
    final plugin = {{plugin_name.pascalCase()}}Plugin();
    await plugin.initialize();
    
    await tester.pumpWidget(
      MaterialApp(
        home: {{plugin_name.pascalCase()}}Widget(plugin: plugin),
      ),
    );
    
    expect(find.text('{{plugin_display_name}}'), findsOneWidget);
  });
}
```
{{/include_ui_components}}

### 集成测试

#### 测试完整流程
```dart
// test/integration/full_lifecycle_test.dart
void main() {
  test('complete plugin lifecycle', () async {
    final plugin = {{plugin_name.pascalCase()}}Plugin();
    
    // 测试完整生命周期
    await plugin.initialize();
    await plugin.start();
    await plugin.pause();
    await plugin.resume();
    await plugin.stop();
    await plugin.dispose();
    
    expect(plugin.currentState, equals(PluginState.disposed));
  });
}
```

## 调试和日志

### 日志记录
```dart
import 'dart:developer' as developer;

void _logInfo(String message) {
  developer.log(message, name: name, level: 800);
}

void _logError(String message, Object? error) {
  developer.log(message, name: name, level: 1000, error: error);
}
```

### 调试技巧

1. **使用断点**: 在关键位置设置断点
2. **状态监控**: 监听状态变化流
3. **消息跟踪**: 记录所有消息处理
4. **性能分析**: 使用 Dart DevTools

## 性能优化

### 内存管理
```dart
@override
Future<void> dispose() async {
  // 清理资源
  await _stateController.close();
  _myService?.dispose();
  _subscriptions?.forEach((s) => s.cancel());
}
```

### 异步处理
```dart
// 使用 Future.wait 并行处理
await Future.wait([
  _initializeService1(),
  _initializeService2(),
  _initializeService3(),
]);
```

### 缓存策略
```dart
class CacheManager {
  final Map<String, dynamic> _cache = {};
  
  T? get<T>(String key) => _cache[key] as T?;
  
  void set<T>(String key, T value) {
    _cache[key] = value;
  }
  
  void clear() => _cache.clear();
}
```

## 发布和部署

### 版本管理
1. 更新 `pubspec.yaml` 中的版本号
2. 更新 `plugin.yaml` 中的版本信息
3. 更新 `CHANGELOG.md`
4. 创建 Git 标签

### 构建发布包
```bash
# 运行测试
dart test

# 代码分析
dart analyze

# 构建包
dart pub publish --dry-run
```

### 插件清单
确保 `plugin.yaml` 包含正确信息：
```yaml
id: "{{plugin_name}}"
name: "{{plugin_display_name}}"
version: "{{version}}"
description: "{{description}}"
author: "{{author}}"
category: "{{plugin_type}}"
platforms:
  - "android"
  - "ios"
  - "web"
  - "windows"
  - "macos"
  - "linux"
permissions: []
dependencies: []
```

## 最佳实践

1. **遵循 Dart 编码规范**
2. **编写全面的测试**
3. **提供详细的文档**
4. **处理所有异常情况**
5. **优化性能和内存使用**
6. **保持向后兼容性**
7. **及时更新依赖**

## 常见问题

### Q: 如何调试插件？
A: 使用 VS Code 的调试功能，设置断点并启动调试模式。

### Q: 如何处理插件间通信？
A: 通过 Pet App V3 的消息系统，使用 `handleMessage` 方法。

### Q: 如何优化插件性能？
A: 使用异步处理、合理的缓存策略和及时的资源清理。

### Q: 如何确保插件兼容性？
A: 严格遵循 Pet App V3 的插件接口规范，进行充分测试。

---

更多详细信息请参考 [API文档](../api/plugin_api.md) 和 [架构文档](../architecture/system_architecture.md)。
