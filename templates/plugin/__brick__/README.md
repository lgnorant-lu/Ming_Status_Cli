# {{plugin_name}}

{{description}}

**版本**: {{version}}  
**作者**: {{author}}  
**邮箱**: {{author_email}}  
**类型**: {{plugin_type}}  
**许可证**: {{license}}

## 概述

{{plugin_name}}是一个为Pet App V3设计的{{plugin_type}}插件。

## 平台支持

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Desktop

{{#include_ui_components}}

## 功能特性

- ✅ UI组件支持
{{/include_ui_components}}

{{#include_services}}
- ✅ 服务层架构
{{/include_services}}

{{#include_models}}
- ✅ 数据模型管理
{{/include_models}}

{{#include_utils}}
- ✅ 工具类支持
{{/include_utils}}

{{#include_l10n}}
- ✅ 国际化支持
{{/include_l10n}}

## 安装

```bash
flutter pub add {{plugin_name}}
```

## 使用

```dart
import 'package:{{plugin_name}}/{{plugin_name}}.dart';

// 使用插件
final plugin = {{plugin_name.pascalCase()}}Plugin();
```

## 开发

```bash
# 获取依赖
flutter pub get

# 运行测试
flutter test

# 代码分析
flutter analyze
```

## 许可证

{{license}}
