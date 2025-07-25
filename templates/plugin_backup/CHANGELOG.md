# 插件模板变更日志

本文档记录了Pet App V3插件模板的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 计划中
- 添加更多插件类型模板
- 支持插件热重载开发
- 集成性能监控工具
- 添加国际化支持

## [1.0.0] - 2025-07-24

### 新增
- 🎉 初始版本发布
- ✨ 完整的Pet App V3插件项目模板
- ✨ 支持7种插件类型 (tool, game, theme, service, widget, ui, system)
- ✨ 多平台支持 (Android, iOS, Web, Desktop)
- ✨ 细粒度权限管理系统
- ✨ 可选的UI组件和服务层
- ✨ 完整的测试框架集成
- ✨ 示例应用模板
- ✨ 代码质量保障 (分析、格式化)
- ✨ 详细的开发文档
- ✨ Ming CLI集成支持
- ✨ Creative Workshop兼容性

### 技术特性
- 📦 基于Mason v0.1.1+模板引擎
- 🔧 Ming Status CLI扩展配置
- 🎯 Pet App V3插件系统规范
- 🧪 完整的测试覆盖
- 📝 自动生成文档
- 🔍 代码静态分析
- 🎨 自动代码格式化

### 模板变量
- `plugin_name` - 插件名称 (snake_case)
- `plugin_display_name` - 插件显示名称
- `plugin_type` - 插件类型 (7种类型)
- `description` - 插件描述
- `author` - 插件作者
- `version` - 初始版本号
- `support_*` - 平台支持配置 (4个平台)
- `need_*` - 权限需求配置 (6种权限)
- `include_*` - 功能包含配置 (5个功能)
- `dart_version` - Dart版本约束
- `flutter_version` - Flutter版本约束
- `use_analysis` - 代码分析开关
- `license` - 开源许可证

### 生成的文件结构
```
plugin_project/
├── plugin.yaml              # 插件清单
├── pubspec.yaml             # Dart包配置
├── README.md                # 项目文档
├── CHANGELOG.md             # 变更日志
├── analysis_options.yaml    # 代码分析配置
├── .gitignore              # Git忽略文件
├── lib/                    # 源码目录
├── test/                   # 测试目录
├── example/                # 示例应用 (可选)
└── assets/                 # 资源目录 (可选)
```

### 钩子功能
- **pre_gen** - 生成前环境验证
- **post_gen** - 生成后依赖安装和代码分析

### 质量保障
- ✅ 代码生成验证
- ✅ 依赖冲突检查
- ✅ 平台兼容性检查
- ✅ 插件清单验证
- ✅ Pet App集成检查

### 兼容性
- **Dart**: ^3.2.0
- **Flutter**: >=3.0.0
- **Mason**: >=0.1.0
- **Ming CLI**: >=1.0.0
- **Pet App V3**: >=1.0.0

### 文档
- 📖 完整的模板使用说明
- 📖 插件开发最佳实践
- 📖 故障排除指南
- 📖 API参考文档

---

## 版本说明

### 版本号格式
本项目使用语义化版本号 `MAJOR.MINOR.PATCH`：

- **MAJOR**: 不兼容的API变更
- **MINOR**: 向后兼容的功能新增
- **PATCH**: 向后兼容的问题修复

### 变更类型
- `新增` - 新功能
- `变更` - 现有功能的变更
- `弃用` - 即将移除的功能
- `移除` - 已移除的功能
- `修复` - 问题修复
- `安全` - 安全相关修复

### 发布周期
- **主要版本**: 根据Pet App V3发布周期
- **次要版本**: 每月发布新功能
- **补丁版本**: 根据需要发布修复

---

*该变更日志由Ming Status CLI自动维护*
