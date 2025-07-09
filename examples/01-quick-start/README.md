# 快速开始教程

## 🎯 学习目标

在这个5分钟的快速教程中，你将学会：
- 安装和配置 Ming Status CLI
- 创建你的第一个工作空间
- 生成一个基础模块
- 验证项目结构

## ⏱️ 预计时间
**5-10分钟**

## 📋 前置条件
- 安装了 Dart SDK 3.2.0+
- 基本的命令行操作知识

## 🚀 开始教程

### 步骤 1: 安装 Ming Status CLI

```bash
# 使用 Dart pub 全局安装
dart pub global activate ming_status_cli

# 验证安装
ming --version
```

**预期输出:**
```
Ming Status CLI version 1.0.0
```

### 步骤 2: 创建工作空间

```bash
# 创建一个新的工作空间
ming init my-first-project

# 进入项目目录
cd my-first-project
```

**预期结果:**
- 创建了 `my-first-project` 目录
- 生成了 `ming_status.yaml` 配置文件

### 步骤 3: 配置用户信息

```bash
# 设置用户信息
ming config --set user.name="Your Name"
ming config --set user.email="your@email.com"

# 查看配置
ming config --list
```

**预期输出:**
```
user.name=Your Name
user.email=your@email.com
```

### 步骤 4: 创建第一个模块

```bash
# 创建一个基础模块
ming create hello-world --template basic

# 查看生成的文件
ls -la hello-world/
```

**预期结果:**
```
hello-world/
├── lib/
│   └── hello_world.dart
├── test/
│   └── hello_world_test.dart
├── pubspec.yaml
└── README.md
```

### 步骤 5: 验证项目

```bash
# 验证项目结构
ming validate

# 查看详细验证信息
ming validate --verbose
```

**预期输出:**
```
✅ 项目验证通过
✅ 配置文件格式正确
✅ 模块结构完整
```

## 🎉 恭喜！

你已经成功完成了第一个 Ming CLI 项目！

### 你学到了什么：
- ✅ 如何安装和验证 Ming CLI
- ✅ 如何创建工作空间
- ✅ 如何配置用户信息
- ✅ 如何生成模块
- ✅ 如何验证项目

### 生成的项目结构：
```
my-first-project/
├── ming_status.yaml      # 工作空间配置
└── hello-world/          # 生成的模块
    ├── lib/
    │   └── hello_world.dart
    ├── test/
    │   └── hello_world_test.dart
    ├── pubspec.yaml
    └── README.md
```

## 🔍 深入了解

### 查看生成的代码

**lib/hello_world.dart:**
```dart
/// A simple hello world library
library hello_world;

/// Says hello to the world
String sayHello([String? name]) {
  return 'Hello, ${name ?? 'World'}!';
}
```

**test/hello_world_test.dart:**
```dart
import 'package:test/test.dart';
import 'package:hello_world/hello_world.dart';

void main() {
  group('Hello World Tests', () {
    test('should say hello to world', () {
      expect(sayHello(), equals('Hello, World!'));
    });

    test('should say hello to specific name', () {
      expect(sayHello('Ming'), equals('Hello, Ming!'));
    });
  });
}
```

### 运行测试

```bash
# 进入模块目录
cd hello-world

# 安装依赖
dart pub get

# 运行测试
dart test
```

**预期输出:**
```
✓ should say hello to world
✓ should say hello to specific name

All tests passed!
```

## 🚀 下一步

现在你已经掌握了基础操作，可以继续学习：

1. **[基础项目创建](../02-basic-project/)** - 学习更复杂的项目结构
2. **[模板使用指南](../03-template-usage/)** - 掌握不同类型的模板
3. **[多模块项目](../04-multi-module/)** - 管理复杂的多模块项目

## 🛠️ 故障排除

### 常见问题

#### 问题 1: 命令未找到
```bash
ming: command not found
```

**解决方案:**
```bash
# 检查 PATH 配置
echo $PATH | grep -o '[^:]*\.pub-cache[^:]*'

# 重新安装
dart pub global deactivate ming_status_cli
dart pub global activate ming_status_cli
```

#### 问题 2: 权限错误
```bash
Permission denied
```

**解决方案:**
```bash
# 检查目录权限
ls -la

# 使用正确的权限创建目录
mkdir -p ~/projects
cd ~/projects
ming init my-project
```

#### 问题 3: 配置文件错误
```bash
Invalid configuration format
```

**解决方案:**
```bash
# 检查配置文件
ming config --list

# 重置配置
ming config --reset

# 重新设置
ming config --set user.name="Your Name"
```

## 📚 相关资源

- [用户手册](../../docs/user_manual.md) - 完整的用户指南
- [命令参考](../../docs/user_manual.md#命令参考) - 所有命令的详细说明
- [配置管理](../../docs/user_manual.md#配置管理) - 配置选项详解
- [故障排除](../../docs/user_manual.md#故障排除) - 常见问题解决方案

## 💬 获取帮助

如果遇到问题，可以：
- 查看 [常见问题](../../docs/user_manual.md#常见问题)
- 在 [GitHub](https://github.com/ming-cli/ming_status_cli/issues) 提交问题
- 加入 [Discord 社区](https://discord.gg/ming-cli)

---

**🎉 恭喜完成快速开始教程！** 

你现在已经掌握了 Ming CLI 的基础操作，可以开始创建自己的项目了！

*教程版本: 1.0.0 | 最后更新: 2025-07-08*
