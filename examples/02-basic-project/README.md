# 基础项目创建教程

## 🎯 学习目标

在这个教程中，你将学会：
- 创建不同类型的项目结构
- 理解工作空间和模块的关系
- 使用不同的模板类型
- 管理项目配置和依赖

## ⏱️ 预计时间
**15-20分钟**

## 📋 前置条件
- 完成 [快速开始教程](../01-quick-start/)
- 熟悉基本的 Ming CLI 命令

## 🏗️ 项目类型介绍

Ming CLI 支持多种项目类型：

### 📦 Dart 包项目
适用于创建可重用的 Dart 库

### 📱 Flutter 应用项目
适用于移动应用开发

### 🌐 Web 应用项目
适用于 Web 前端开发

### 🔧 工具项目
适用于命令行工具开发

## 🚀 实践教程

### 项目 1: 创建 Dart 包项目

#### 步骤 1: 初始化工作空间
```bash
# 创建新的工作空间
ming init dart-utils-workspace
cd dart-utils-workspace

# 配置项目信息
ming config --set project.name="Dart Utilities"
ming config --set project.description="A collection of useful Dart utilities"
ming config --set project.license="MIT"
```

#### 步骤 2: 创建核心工具包
```bash
# 创建字符串工具包
ming create string-utils --template dart_package \
  --var package_name="string_utils" \
  --var description="String manipulation utilities" \
  --var author="Your Name"

# 创建数学工具包
ming create math-utils --template dart_package \
  --var package_name="math_utils" \
  --var description="Mathematical utility functions" \
  --var author="Your Name"
```

#### 步骤 3: 验证项目结构
```bash
# 查看生成的结构
tree . -I 'node_modules|.git'

# 验证项目
ming validate
```

**预期结构:**
```
dart-utils-workspace/
├── ming_status.yaml
├── string-utils/
│   ├── lib/
│   │   └── string_utils.dart
│   ├── test/
│   │   └── string_utils_test.dart
│   ├── pubspec.yaml
│   └── README.md
└── math-utils/
    ├── lib/
    │   └── math_utils.dart
    ├── test/
    │   └── math_utils_test.dart
    ├── pubspec.yaml
    └── README.md
```

### 项目 2: 创建 Flutter 应用项目

#### 步骤 1: 创建新工作空间
```bash
# 创建 Flutter 应用工作空间
ming init todo-app-workspace
cd todo-app-workspace

# 配置应用信息
ming config --set project.name="Todo App"
ming config --set project.description="A simple todo application"
ming config --set project.type="flutter"
```

#### 步骤 2: 创建应用模块
```bash
# 创建主应用
ming create todo-app --template flutter_app \
  --var app_name="Todo App" \
  --var package_name="com.example.todo_app" \
  --var description="A simple and elegant todo application"

# 创建共享模块
ming create shared --template dart_package \
  --var package_name="todo_shared" \
  --var description="Shared models and utilities"
```

#### 步骤 3: 添加功能模块
```bash
# 创建任务管理模块
ming create tasks --template feature_module \
  --var feature_name="Tasks" \
  --var use_bloc="true" \
  --var use_repository="true"

# 创建用户界面模块
ming create ui --template ui_module \
  --var module_name="UI Components" \
  --var use_material="true"
```

### 项目 3: 创建 Web 应用项目

#### 步骤 1: 初始化 Web 项目
```bash
# 创建 Web 应用工作空间
ming init blog-website
cd blog-website

# 配置 Web 项目
ming config --set project.name="Personal Blog"
ming config --set project.type="web"
ming config --set project.framework="dart_web"
```

#### 步骤 2: 创建前端模块
```bash
# 创建主 Web 应用
ming create frontend --template web_app \
  --var app_name="Personal Blog" \
  --var use_router="true" \
  --var use_sass="true"

# 创建组件库
ming create components --template component_library \
  --var library_name="Blog Components" \
  --var use_storybook="true"
```

## 🔧 高级配置

### 自定义模板变量

创建模块时可以使用更多变量：

```bash
ming create advanced-module --template dart_package \
  --var package_name="advanced_module" \
  --var description="An advanced module with custom configuration" \
  --var author="Your Name" \
  --var email="your@email.com" \
  --var homepage="https://github.com/yourname/advanced-module" \
  --var version="0.1.0" \
  --var dart_sdk=">=3.0.0 <4.0.0" \
  --var use_lints="true" \
  --var use_coverage="true"
```

### 工作空间配置文件

查看和编辑 `ming_status.yaml`:

```yaml
name: "My Project"
description: "A sample project"
version: "1.0.0"
author: "Your Name"

modules:
  - name: "core"
    path: "./core"
    type: "dart_package"
  - name: "ui"
    path: "./ui"
    type: "flutter_module"

dependencies:
  dart: ">=3.0.0 <4.0.0"

dev_dependencies:
  test: ^1.21.0
  lints: ^2.0.0

scripts:
  test: "dart test"
  analyze: "dart analyze"
  format: "dart format ."
```

### 依赖管理

```bash
# 添加依赖到特定模块
cd string-utils
dart pub add http
dart pub add --dev test

# 更新所有模块的依赖
ming deps update

# 检查依赖冲突
ming deps check
```

## 📊 项目验证

### 基础验证
```bash
# 验证整个工作空间
ming validate

# 验证特定模块
ming validate string-utils

# 详细验证报告
ming validate --verbose --format json > validation_report.json
```

### 代码质量检查
```bash
# 代码分析
ming analyze

# 格式检查
ming format --check

# 测试覆盖率
ming test --coverage
```

## 🎨 最佳实践

### 1. 项目命名约定
```bash
# 工作空间：kebab-case
my-awesome-project

# 模块：snake_case
user_authentication
data_persistence

# 包名：snake_case
my_awesome_package
```

### 2. 目录结构规范
```
workspace/
├── ming_status.yaml      # 工作空间配置
├── modules/              # 模块目录（可选）
│   ├── core/
│   ├── ui/
│   └── shared/
├── tools/                # 工具脚本
├── docs/                 # 文档
└── scripts/              # 构建脚本
```

### 3. 版本管理
```bash
# 设置版本策略
ming config --set versioning.strategy="semantic"
ming config --set versioning.auto_increment="patch"

# 版本标记
ming version bump patch
ming version bump minor
ming version bump major
```

## 🧪 测试你的项目

### 运行测试
```bash
# 运行所有测试
ming test

# 运行特定模块测试
ming test string-utils

# 生成测试报告
ming test --reporter html --output test_report.html
```

### 性能测试
```bash
# 基准测试
ming benchmark

# 内存使用分析
ming profile memory

# 启动时间分析
ming profile startup
```

## 🚀 下一步

完成这个教程后，你可以继续学习：

1. **[模板使用指南](../03-template-usage/)** - 深入了解模板系统
2. **[多模块项目](../04-multi-module/)** - 管理复杂项目
3. **[自定义模板](../05-custom-templates/)** - 创建自己的模板

## 🛠️ 故障排除

### 常见问题

#### 模块创建失败
```bash
# 检查模板是否存在
ming template list

# 重新安装模板
ming template install dart_package

# 清除缓存
ming cache clear
```

#### 依赖冲突
```bash
# 检查依赖树
ming deps tree

# 解决冲突
ming deps resolve

# 强制更新
ming deps update --force
```

## 📚 相关资源

- [模板系统文档](../../docs/user_manual.md#模板系统)
- [配置管理指南](../../docs/user_manual.md#配置管理)
- [最佳实践](../../docs/user_manual.md#最佳实践)

---

**🎉 恭喜完成基础项目创建教程！**

你现在已经掌握了创建不同类型项目的技能，可以开始构建更复杂的应用了！

*教程版本: 1.0.0 | 最后更新: 2025-07-08*
