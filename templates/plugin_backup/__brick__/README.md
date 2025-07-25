# {{plugin_name.titleCase()}}

{{description}}

**版本**: {{version}}  
**作者**: {{author}}{{#author_email}}  
**邮箱**: {{author_email}}{{/author_email}}  
**类型**: {{plugin_type}}  
**许可证**: {{license}}

## 概述

{{plugin_name.titleCase()}}是一个为Pet App V3设计的{{plugin_type}}插件，提供以下功能：

- ✅ 完整的插件生命周期管理
- ✅ 多平台兼容性支持{{#include_ui_components}}
- ✅ 丰富的UI组件{{/include_ui_components}}{{#include_services}}
- ✅ 后台服务支持{{/include_services}}
- ✅ 权限管理和安全控制
- ✅ 配置管理和持久化

## 平台支持

{{#support_android}}
- ✅ Android{{/support_android}}{{#support_ios}}
- ✅ iOS{{/support_ios}}{{#support_web}}
- ✅ Web{{/support_web}}{{#support_desktop}}
- ✅ Windows
- ✅ macOS
- ✅ Linux{{/support_desktop}}

## 权限要求

{{#need_file_system}}
- 📁 文件系统访问权限{{/need_file_system}}{{#need_network}}
- 🌐 网络访问权限{{/need_network}}{{#need_camera}}
- 📷 摄像头访问权限{{/need_camera}}{{#need_microphone}}
- 🎤 麦克风访问权限{{/need_microphone}}{{#need_location}}
- 📍 位置信息访问权限{{/need_location}}{{#need_notifications}}
- 🔔 系统通知权限{{/need_notifications}}

## 安装

将此插件添加到您的Pet App V3项目中：

```yaml
dependencies:
  {{plugin_name}}:
    path: path/to/{{plugin_name}}
```

然后运行：

```bash
flutter pub get
```

## 使用方法

### 基础使用

```dart
import 'package:{{plugin_name}}/{{plugin_name}}.dart';

// 创建插件实例
final plugin = {{plugin_name.pascalCase()}}Plugin();

// 初始化插件
await plugin.initialize();

// 启动插件
await plugin.start();{{#include_ui_components}}

// 获取插件UI组件
final widget = plugin.getMainWidget();{{/include_ui_components}}

// 停止插件
await plugin.stop();

// 销毁插件
await plugin.dispose();
```

### 监听状态变化

```dart
plugin.stateChanges.listen((state) {
  print('插件状态变更: $state');
});
```

### 处理插件消息

```dart
final result = await plugin.handleMessage('getStatus', {});
print('插件状态: $result');
```{{#include_ui_components}}

### 使用UI组件

```dart
class MyWidget extends StatelessWidget {
  final {{plugin_name.pascalCase()}}Plugin plugin;
  
  const MyWidget({required this.plugin});
  
  @override
  Widget build(BuildContext context) {
    return plugin.getMainWidget() as Widget;
  }
}
```{{/include_ui_components}}

## 配置

插件支持以下配置选项：

```dart
final config = {{plugin_name.pascalCase()}}ConfigData(
  enabled: true,
  autoStart: false,
  debugMode: false,
  logLevel: {{plugin_name.pascalCase()}}LogLevel.info,
  maxRetries: 3,
  timeout: Duration(seconds: 30),
  customSettings: {
    'key': 'value',
  },
);

await plugin.updateConfig(config);
```

## API 参考

### 主要类

- `{{plugin_name.pascalCase()}}Plugin` - 插件主类
- `{{plugin_name.pascalCase()}}ConfigData` - 配置数据类
- `{{plugin_name.pascalCase()}}Event` - 事件数据类
- `{{plugin_name.pascalCase()}}Result<T>` - 结果包装类

### 枚举

- `{{plugin_name.pascalCase()}}State` - 插件状态
- `{{plugin_name.pascalCase()}}LogLevel` - 日志级别
- `{{plugin_name.pascalCase()}}EventType` - 事件类型

### 异常

- `{{plugin_name.pascalCase()}}Exception` - 基础异常
- `{{plugin_name.pascalCase()}}InitializationException` - 初始化异常
- `{{plugin_name.pascalCase()}}ConfigurationException` - 配置异常{{#need_network}}
- `{{plugin_name.pascalCase()}}NetworkException` - 网络异常{{/need_network}}{{#need_file_system}}
- `{{plugin_name.pascalCase()}}FileSystemException` - 文件系统异常{{/need_file_system}}

## 示例

查看 `example/` 目录中的完整示例应用，了解如何使用此插件。

运行示例：

```bash
cd example
flutter run
```

## 开发

### 运行测试

```bash
flutter test
```

### 代码分析

```bash
dart analyze
```

### 格式化代码

```bash
dart format .
```

## 故障排除

### 常见问题

1. **插件无法初始化**
   - 检查权限是否正确声明
   - 确认平台兼容性
   - 查看日志输出

2. **状态转换失败**
   - 确保按正确顺序调用生命周期方法
   - 检查当前插件状态

3. **配置加载失败**
   - 验证配置文件格式
   - 检查文件权限

### 获取帮助

- 查看Pet App V3插件开发文档
- 在GitHub Issues中报告问题
- 联系插件作者

## 更新日志

### v{{version}} ({{generated_date}})
- 初始版本发布
- 基础插件功能实现
- 完整的生命周期管理{{#include_ui_components}}
- UI组件支持{{/include_ui_components}}{{#include_services}}
- 服务层支持{{/include_services}}

## 许可证

本项目采用 {{license}} 许可证。详情请参阅 LICENSE 文件。

## 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

---

*此插件由 Ming Status CLI 生成*
