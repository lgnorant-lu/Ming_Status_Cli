# Ming Status CLI 用户手册

## 目录

1. [快速开始](#快速开始)
2. [安装指南](#安装指南)
3. [基础概念](#基础概念)
4. [命令参考](#命令参考)
5. [工作流程](#工作流程)
6. [配置管理](#配置管理)
7. [模板系统](#模板系统)
8. [故障排除](#故障排除)
9. [最佳实践](#最佳实践)
10. [常见问题](#常见问题)

## 快速开始

### 5分钟上手指南

Ming Status CLI 是一个强大的项目管理和代码生成工具，帮助开发者快速创建和管理项目结构。

#### 第一步：安装
```bash
# 使用 Dart 包管理器安装
dart pub global activate ming_status_cli

# 或者从源码安装
git clone https://github.com/your-org/ming_status_cli.git
cd ming_status_cli
dart pub get
dart compile exe bin/ming_status_cli.dart -o ming
```

#### 第二步：验证安装
```bash
ming --help
ming version
```

#### 第三步：创建第一个项目
```bash
# 初始化工作空间
ming init my-first-project

# 进入项目目录
cd my-first-project

# 配置用户信息
ming config --set user.name="Your Name"
ming config --set user.email="your@email.com"

# 创建第一个模块
ming create hello-world --template basic

# 验证项目结构
ming validate
```

#### 第四步：查看结果
```bash
# 查看生成的文件结构
tree hello-world/

# 查看配置
ming config --list
```

## 安装指南

### 系统要求

- **操作系统**: Windows 10+, macOS 10.14+, Linux (Ubuntu 18.04+)
- **Dart SDK**: 3.2.0 或更高版本
- **内存**: 最少 512MB RAM
- **磁盘空间**: 100MB 可用空间

### 安装方式

#### 方式一：Dart Pub 全局安装（推荐）
```bash
# 安装最新版本
dart pub global activate ming_status_cli

# 验证安装
ming --version
```

#### 方式二：从源码编译
```bash
# 克隆仓库
git clone https://github.com/your-org/ming_status_cli.git
cd ming_status_cli

# 安装依赖
dart pub get

# 编译可执行文件
dart compile exe bin/ming_status_cli.dart -o ming

# 添加到 PATH（可选）
export PATH="$PATH:$(pwd)"
```

#### 方式三：预编译二进制文件
```bash
# 下载对应平台的二进制文件
# Windows
curl -L -o ming.exe https://github.com/your-org/ming_status_cli/releases/latest/download/ming-windows.exe

# macOS
curl -L -o ming https://github.com/your-org/ming_status_cli/releases/latest/download/ming-macos

# Linux
curl -L -o ming https://github.com/your-org/ming_status_cli/releases/latest/download/ming-linux

# 设置执行权限（macOS/Linux）
chmod +x ming
```

### 环境配置

#### 配置 PATH
```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
export PATH="$PATH:$HOME/.pub-cache/bin"

# 重新加载配置
source ~/.bashrc
```

#### 验证安装
```bash
# 检查版本
ming --version

# 检查环境
ming doctor

# 查看帮助
ming --help
```

## 基础概念

### 工作空间（Workspace）
工作空间是 Ming CLI 管理的顶级目录，包含：
- 配置文件 (`ming_status.yaml`)
- 模块目录
- 模板缓存
- 构建输出

### 模块（Module）
模块是可重用的代码单元，具有：
- 独立的目录结构
- 配置文件 (`pubspec.yaml`)
- 源代码文件
- 测试文件
- 文档文件

### 模板（Template）
模板定义了模块的结构和内容：
- 文件结构模板
- 变量替换规则
- 生成逻辑
- 依赖关系

### 配置（Configuration）
配置管理工具的行为：
- 用户信息
- 默认设置
- 模板路径
- 构建选项

## 命令参考

### 全局选项
```bash
--help, -h          显示帮助信息
--version, -v       显示版本信息
--verbose           启用详细输出
--quiet, -q         静默模式
--no-color          禁用颜色输出
```

### init - 初始化工作空间
```bash
ming init <workspace-name> [options]

选项:
  --name <name>           工作空间名称
  --description <desc>    工作空间描述
  --author <author>       作者信息
  --template <template>   使用的模板

示例:
  ming init my-project
  ming init my-project --name "My Project" --author "John Doe"
```

### create - 创建模块
```bash
ming create <module-name> [options]

选项:
  --template <template>   使用的模板 (默认: basic)
  --var <key=value>      设置模板变量
  --output <path>        输出目录
  --force                强制覆盖已存在的文件

示例:
  ming create my-module
  ming create my-module --template flutter
  ming create my-module --var author="John Doe" --var version="1.0.0"
```

### config - 配置管理
```bash
ming config [key] [value] [options]

选项:
  --list              列出所有配置
  --set <key=value>   设置配置值
  --unset <key>       删除配置
  --reset             重置所有配置

示例:
  ming config --list
  ming config --set user.name="John Doe"
  ming config user.name
  ming config --unset user.email
```

### validate - 验证项目
```bash
ming validate [module] [options]

选项:
  --fix               自动修复问题
  --level <level>     验证级别 (error|warning|info)
  --format <format>   输出格式 (text|json|xml)
  --output <file>     输出到文件

示例:
  ming validate
  ming validate my-module
  ming validate --fix --level warning
```

### doctor - 环境诊断
```bash
ming doctor [options]

选项:
  --detailed          显示详细信息
  --fix               尝试自动修复问题

示例:
  ming doctor
  ming doctor --detailed
  ming doctor --fix
```

### help - 获取帮助
```bash
ming help [command]

示例:
  ming help
  ming help init
  ming help create
```

## 工作流程

### 典型开发流程

#### 1. 项目初始化
```bash
# 创建新项目
ming init my-awesome-project
cd my-awesome-project

# 配置项目信息
ming config --set user.name="Your Name"
ming config --set user.email="your@email.com"
ming config --set project.license="MIT"
```

#### 2. 创建核心模块
```bash
# 创建主应用模块
ming create app --template flutter_app \
  --var app_name="My Awesome App" \
  --var package_name="com.example.awesome"

# 创建共享库模块
ming create shared --template dart_package \
  --var package_name="awesome_shared" \
  --var description="Shared utilities and models"
```

#### 3. 添加功能模块
```bash
# 创建用户认证模块
ming create auth --template feature_module \
  --var feature_name="Authentication" \
  --var use_bloc="true"

# 创建数据层模块
ming create data --template data_layer \
  --var use_dio="true" \
  --var use_hive="true"
```

#### 4. 验证和构建
```bash
# 验证项目结构
ming validate

# 修复发现的问题
ming validate --fix

# 检查环境
ming doctor
```

### 团队协作流程

#### 1. 项目设置
```bash
# 克隆项目
git clone <project-url>
cd <project-name>

# 安装依赖
ming doctor --fix

# 验证环境
ming validate
```

#### 2. 添加新功能
```bash
# 创建功能分支
git checkout -b feature/new-feature

# 创建功能模块
ming create new-feature --template feature_module

# 开发和测试
# ...

# 验证代码质量
ming validate --level warning
```

#### 3. 代码审查和合并
```bash
# 最终验证
ming validate --fix
ming doctor

# 提交代码
git add .
git commit -m "Add new feature module"
git push origin feature/new-feature

# 创建 Pull Request
# ...
```

## 配置管理

### 配置文件位置

#### 全局配置
- **Windows**: `%APPDATA%\ming_cli\config.yaml`
- **macOS**: `~/Library/Application Support/ming_cli/config.yaml`
- **Linux**: `~/.config/ming_cli/config.yaml`

#### 项目配置
- `<workspace>/ming_status.yaml`

### 配置选项

#### 用户信息
```yaml
user:
  name: "Your Name"
  email: "your@email.com"
  organization: "Your Organization"
```

#### 项目设置
```yaml
project:
  name: "My Project"
  description: "Project description"
  version: "1.0.0"
  license: "MIT"
```

#### 模板设置
```yaml
templates:
  default: "basic"
  search_paths:
    - "~/.ming_cli/templates"
    - "./templates"
  remote_repositories:
    - "https://github.com/ming-cli/templates.git"
```

#### 构建设置
```yaml
build:
  output_directory: "build"
  clean_before_build: true
  parallel_jobs: 4
```

### 配置命令示例

```bash
# 查看所有配置
ming config --list

# 设置用户信息
ming config --set user.name="John Doe"
ming config --set user.email="john@example.com"

# 设置项目信息
ming config --set project.license="Apache-2.0"
ming config --set project.version="2.0.0"

# 查看特定配置
ming config user.name
ming config project.license

# 删除配置
ming config --unset user.organization

# 重置所有配置
ming config --reset
```

## 模板系统

### 模板结构

Ming CLI 使用基于目录的模板系统：

```
templates/
├── basic/
│   ├── template.yaml          # 模板配置
│   ├── {{module_name}}/       # 模块目录模板
│   │   ├── lib/
│   │   │   └── {{module_name}}.dart
│   │   ├── test/
│   │   │   └── {{module_name}}_test.dart
│   │   └── pubspec.yaml
│   └── hooks/                 # 生成钩子
│       ├── pre_generate.dart
│       └── post_generate.dart
```

### 模板配置文件

`template.yaml` 定义模板的元数据和变量：

```yaml
name: "Basic Dart Package"
description: "A basic Dart package template"
version: "1.0.0"
author: "Ming CLI Team"

variables:
  module_name:
    type: string
    description: "The name of the module"
    required: true
    pattern: "^[a-z][a-z0-9_]*$"

  author:
    type: string
    description: "Package author"
    default: "{{user.name}}"

  description:
    type: string
    description: "Package description"
    default: "A new Dart package"

  version:
    type: string
    description: "Initial version"
    default: "0.1.0"
    pattern: "^\\d+\\.\\d+\\.\\d+$"

dependencies:
  - dart: ">=3.0.0 <4.0.0"

files:
  - path: "lib/{{module_name}}.dart"
    template: true
  - path: "test/{{module_name}}_test.dart"
    template: true
  - path: "pubspec.yaml"
    template: true
  - path: "README.md"
    template: true

hooks:
  pre_generate: "hooks/pre_generate.dart"
  post_generate: "hooks/post_generate.dart"
```

### 变量替换

模板支持多种变量替换语法：

#### 基本变量
```dart
// 在文件内容中
library {{module_name}};

class {{module_name|pascal_case}} {
  // ...
}
```

#### 条件语句
```dart
{{#if use_bloc}}
import 'package:flutter_bloc/flutter_bloc.dart';
{{/if}}

{{#unless is_library}}
void main() {
  // ...
}
{{/unless}}
```

#### 循环语句
```dart
{{#each dependencies}}
import 'package:{{this}}/{{this}}.dart';
{{/each}}
```

#### 过滤器
```dart
// 支持的过滤器
{{module_name|snake_case}}     // my_module
{{module_name|camel_case}}     // myModule
{{module_name|pascal_case}}    // MyModule
{{module_name|kebab_case}}     // my-module
{{module_name|upper_case}}     // MY_MODULE
{{module_name|lower_case}}     // my_module
```

### 自定义模板

#### 创建模板
```bash
# 创建模板目录
mkdir -p ~/.ming_cli/templates/my_template

# 创建模板配置
cat > ~/.ming_cli/templates/my_template/template.yaml << EOF
name: "My Custom Template"
description: "A custom template for my projects"
version: "1.0.0"

variables:
  project_name:
    type: string
    required: true
  use_tests:
    type: boolean
    default: true
EOF

# 创建模板文件
mkdir -p ~/.ming_cli/templates/my_template/{{project_name}}
echo "# {{project_name}}" > ~/.ming_cli/templates/my_template/{{project_name}}/README.md
```

#### 使用自定义模板
```bash
ming create my-project --template my_template
```

## 故障排除

### 常见问题和解决方案

#### 1. 命令未找到
```bash
# 错误: ming: command not found

# 解决方案:
# 1. 检查安装
dart pub global list

# 2. 检查 PATH
echo $PATH | grep -o '[^:]*\.pub-cache[^:]*'

# 3. 重新安装
dart pub global deactivate ming_status_cli
dart pub global activate ming_status_cli
```

#### 2. 权限错误
```bash
# 错误: Permission denied

# 解决方案:
# 1. 检查文件权限
ls -la

# 2. 修改权限
chmod +x ming

# 3. 使用管理员权限 (Windows)
# 以管理员身份运行命令提示符
```

#### 3. 模板未找到
```bash
# 错误: Template 'my_template' not found

# 解决方案:
# 1. 列出可用模板
ming template list

# 2. 检查模板路径
ming config templates.search_paths

# 3. 添加模板路径
ming config --set templates.search_paths="~/.ming_cli/templates"
```

#### 4. 验证失败
```bash
# 错误: Validation failed with errors

# 解决方案:
# 1. 查看详细错误
ming validate --verbose

# 2. 自动修复
ming validate --fix

# 3. 检查环境
ming doctor --detailed
```

### 诊断工具

#### 环境检查
```bash
# 完整环境诊断
ming doctor --detailed

# 检查特定组件
ming doctor --check dart
ming doctor --check templates
ming doctor --check config
```

#### 日志和调试
```bash
# 启用详细日志
ming --verbose <command>

# 启用调试模式
export MING_DEBUG=true
ming <command>

# 查看日志文件
# Windows: %TEMP%\ming_cli\logs\
# macOS/Linux: /tmp/ming_cli/logs/
```

## 最佳实践

### 项目组织

#### 1. 目录结构
```
my-project/
├── ming_status.yaml           # 工作空间配置
├── modules/                   # 模块目录
│   ├── app/                   # 主应用
│   ├── shared/                # 共享库
│   └── features/              # 功能模块
│       ├── auth/
│       ├── profile/
│       └── settings/
├── templates/                 # 项目模板
├── scripts/                   # 构建脚本
└── docs/                      # 文档
```

#### 2. 命名约定
```bash
# 模块名称：使用 snake_case
ming create user_profile
ming create payment_gateway

# 包名称：使用点分隔
--var package_name="com.company.app.feature"

# 类名称：使用 PascalCase
--var class_name="UserProfileService"
```

### 团队协作

#### 1. 共享配置
```yaml
# .ming_cli/team_config.yaml
team:
  templates:
    - "git+https://github.com/company/ming-templates.git"
  coding_standards:
    - "dart_style"
    - "effective_dart"
  required_tools:
    - "dart"
    - "flutter"
```

#### 2. CI/CD 集成
```yaml
# .github/workflows/ming_cli.yml
name: Ming CLI Validation
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - name: Install Ming CLI
        run: dart pub global activate ming_status_cli
      - name: Validate project
        run: ming validate --level error
      - name: Check environment
        run: ming doctor
```

### 性能优化

#### 1. 模板缓存
```bash
# 启用模板缓存
ming config --set templates.cache_enabled=true

# 清理缓存
ming cache clear

# 预加载常用模板
ming template preload basic flutter_app
```

#### 2. 并行处理
```bash
# 启用并行验证
ming config --set validation.parallel=true

# 设置并行任务数
ming config --set build.parallel_jobs=4
```

## 常见问题

### Q: 如何更新 Ming CLI？
```bash
# 更新到最新版本
dart pub global activate ming_status_cli

# 检查版本
ming --version
```

### Q: 如何备份和恢复配置？
```bash
# 备份配置
ming config export > ming_config_backup.yaml

# 恢复配置
ming config import ming_config_backup.yaml
```

### Q: 如何创建私有模板仓库？
```bash
# 添加私有仓库
ming config --set templates.repositories="git+ssh://git@github.com/company/private-templates.git"

# 使用私有模板
ming create my-module --template private_template
```

### Q: 如何在离线环境中使用？
```bash
# 下载所有依赖
ming cache download-all

# 启用离线模式
ming config --set offline_mode=true

# 验证离线功能
ming validate --offline
```

### Q: 如何集成到现有项目？
```bash
# 在现有项目中初始化
cd existing-project
ming init . --existing

# 验证现有结构
ming validate --fix
```

---

## 获取帮助

- **在线文档**: https://ming-cli.docs.com
- **GitHub 仓库**: https://github.com/ming-cli/ming_status_cli
- **问题报告**: https://github.com/ming-cli/ming_status_cli/issues
- **社区讨论**: https://discord.gg/ming-cli
- **邮件支持**: support@ming-cli.com

---

*本手册版本: 1.0.0 | 最后更新: 2025-07-08*
