# Pet App V3 插件模板

**版本**: 1.0.0  
**作者**: Pet App Team  
**最后更新**: 2025-07-24

## 概述

这是一个专为Pet App V3设计的插件项目模板，提供完整的插件开发生命周期支持。该模板遵循Pet App V3插件系统规范，集成了Creative Workshop功能，支持多平台部署。

## 特性

- ✅ **完整的插件架构** - 基于Pet App V3插件系统设计
- ✅ **多平台支持** - Android、iOS、Web、Desktop全平台兼容
- ✅ **权限管理** - 细粒度权限控制和声明
- ✅ **UI组件支持** - 可选的UI组件和服务层
- ✅ **测试覆盖** - 完整的单元测试和集成测试
- ✅ **示例应用** - 开箱即用的示例应用
- ✅ **代码质量** - 集成代码分析和格式化
- ✅ **文档完整** - 详细的开发文档和API说明

## 生成的项目结构

```
my_plugin/
├── plugin.yaml                      # 插件清单文件
├── pubspec.yaml                     # Dart包配置
├── README.md                        # 项目文档
├── CHANGELOG.md                     # 变更日志
├── analysis_options.yaml            # 代码分析配置
├── .gitignore                       # Git忽略文件
├── lib/                             # 插件源码
│   ├── my_plugin.dart               # 插件导出文件
│   └── src/                         # 插件实现
│       ├── my_plugin_plugin.dart    # 插件主实现
│       ├── widgets/                 # UI组件 (可选)
│       │   └── my_plugin_widget.dart
│       └── services/                # 服务层 (可选)
│           └── my_plugin_service.dart
├── test/                            # 测试文件
│   ├── my_plugin_test.dart          # 主测试文件
│   └── src/                         # 测试实现
│       └── my_plugin_plugin_test.dart
├── example/                         # 示例应用 (可选)
│   ├── lib/
│   │   └── main.dart                # 示例应用主文件
│   └── pubspec.yaml                 # 示例应用配置
└── assets/                          # 资源文件 (可选)
    └── .gitkeep
```

## 模板变量

### 核心变量

| 变量名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| `plugin_name` | string | - | 插件名称 (snake_case格式) |
| `plugin_display_name` | string | - | 插件显示名称 |
| `plugin_type` | enum | tool | 插件类型 (tool/game/theme/service/widget/ui/system) |
| `description` | string | - | 插件描述 |
| `author` | string | Pet App Developer | 插件作者 |
| `version` | string | 1.0.0 | 初始版本号 |

### 平台支持

| 变量名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| `support_android` | boolean | true | 支持Android平台 |
| `support_ios` | boolean | true | 支持iOS平台 |
| `support_web` | boolean | true | 支持Web平台 |
| `support_desktop` | boolean | true | 支持桌面平台 |

### 权限配置

| 变量名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| `need_file_system` | boolean | false | 需要文件系统权限 |
| `need_network` | boolean | false | 需要网络权限 |
| `need_camera` | boolean | false | 需要摄像头权限 |
| `need_microphone` | boolean | false | 需要麦克风权限 |
| `need_location` | boolean | false | 需要位置权限 |
| `need_notifications` | boolean | false | 需要通知权限 |

### 功能配置

| 变量名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| `include_ui_components` | boolean | true | 包含UI组件 |
| `include_services` | boolean | false | 包含服务层 |
| `include_example` | boolean | true | 包含示例应用 |
| `include_tests` | boolean | true | 包含测试文件 |
| `include_assets` | boolean | false | 包含资源目录 |

## 使用方法

### 通过Ming CLI创建插件

```bash
# 基础插件创建
ming create my_awesome_plugin --template=plugin

# 指定插件类型
ming create my_tool --template=plugin --plugin_type=tool

# 游戏插件
ming create my_game --template=plugin --plugin_type=game --include_assets=true

# 主题插件
ming create my_theme --template=plugin --plugin_type=theme --include_ui_components=true

# 交互式创建
ming create --template=plugin --interactive
```

### 通过Mason直接使用

```bash
# 添加模板
mason add plugin --path ./templates/plugin

# 生成插件
mason make plugin

# 指定变量生成
mason make plugin --plugin_name my_plugin --author "Your Name"
```

## 开发工作流

### 1. 创建插件项目

```bash
ming create my_plugin --template=plugin --plugin_type=tool
cd my_plugin
```

### 2. 开发插件

```bash
# 安装依赖
dart pub get

# 运行测试
flutter test

# 代码分析
dart analyze

# 格式化代码
dart format .
```

### 3. 验证插件

```bash
# 验证插件结构和清单
ming plugin validate

# 构建插件
ming plugin build

# 运行示例应用
cd example
flutter run
```

### 4. 发布插件

```bash
# 发布到本地注册表
ming plugin publish --registry=local

# 发布到pub.dev
flutter pub publish
```

## 插件类型说明

| 类型 | 说明 | 适用场景 |
|------|------|----------|
| `tool` | 工具插件 | 画笔工具、形状工具、编辑工具 |
| `game` | 游戏插件 | 小游戏、娱乐功能 |
| `theme` | 主题插件 | 界面主题、配色方案 |
| `service` | 服务插件 | 后台服务、数据同步 |
| `widget` | 小部件插件 | 桌面小部件、UI组件 |
| `ui` | UI组件插件 | 自定义控件、界面元素 |
| `system` | 系统插件 | 系统工具、性能监控 |

## 最佳实践

### 1. 命名规范

- **插件名称**: 使用snake_case格式，如 `my_awesome_tool`
- **类名**: 使用PascalCase格式，如 `MyAwesomeToolPlugin`
- **文件名**: 使用snake_case格式，如 `my_awesome_tool_plugin.dart`

### 2. 权限声明

- 只声明插件实际需要的权限
- 在插件文档中说明权限用途
- 遵循最小权限原则

### 3. 平台兼容性

- 测试所有声明支持的平台
- 处理平台特定的功能差异
- 提供平台特定的实现

### 4. 测试覆盖

- 为所有公共API编写测试
- 包含单元测试和集成测试
- 测试不同平台的兼容性

## 故障排除

### 常见问题

1. **插件无法加载**
   - 检查plugin.yaml格式是否正确
   - 确认插件ID唯一性
   - 验证依赖版本兼容性

2. **权限被拒绝**
   - 检查权限声明是否完整
   - 确认权限请求时机
   - 处理权限拒绝情况

3. **平台兼容性问题**
   - 检查平台特定代码
   - 验证依赖包平台支持
   - 测试目标平台功能

### 获取帮助

- 查看Pet App V3插件开发文档
- 访问Creative Workshop开发指南
- 在GitHub Issues中报告问题

## 更新日志

### v1.0.0 (2025-07-24)
- 初始版本发布
- 支持Pet App V3插件系统
- 集成Creative Workshop功能
- 多平台支持
- 完整的开发工具链

---

*该模板由Ming Status CLI v1.0.0生成，专为Pet App V3插件系统设计*
