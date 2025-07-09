# Ming Status CLI

🚀 **现代化的企业级模块化脚手架工具** - 专为提升开发效率和项目质量而设计

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/pet-app/ming_status_cli/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](#支持平台)

## 🎯 项目概述

**Ming Status CLI v1.0.0** 是一个功能完整、质量可靠的企业级模块化脚手架工具。经过Phase 1的完整开发，现已达到生产就绪状态，为开发者提供智能化的项目初始化、多层级验证、企业级配置管理等核心功能。

### ✨ 核心特性

- 🔧 **智能项目初始化** - 自动识别项目类型，生成最佳实践结构
- 🔍 **多层级验证系统** - 结构/内容/依赖全方位验证
- ⚙️ **企业级配置管理** - 用户/工作空间/项目三级配置
- 🏥 **智能健康检查** - 环境检测和依赖验证
- 📋 **模板管理系统** - 丰富的项目模板库
- 🛡️ **安全性保障** - 输入验证、文件安全、依赖安全
- ⚡ **性能优化** - 智能缓存、并行处理、内存优化
- 🌐 **跨平台支持** - Windows/Linux/macOS完整兼容

## 🚀 快速开始

### 📦 安装

#### 方式1: 下载可执行文件
```bash
# 下载最新版本 (v1.0.0)
wget https://github.com/ming_status_cli/releases/download/v1.0.0/ming_status_cli_v1.0.0.exe

# Windows: 添加到PATH
move ming_status_cli_v1.0.0.exe C:\tools\ming.exe

# Linux/macOS: 添加到PATH
sudo mv ming_status_cli_v1.0.0.exe /usr/local/bin/ming
chmod +x /usr/local/bin/ming
```

#### 方式2: 从源码构建
```bash
# 克隆仓库
git clone https://github.com/pet-app/ming_status_cli.git
cd ming_status_cli

# 安装依赖
dart pub get

# 编译可执行文件
dart compile exe bin/ming_status_cli.dart -o ming

# 验证安装
./ming --version
```

### 🎯 基本使用

```bash
# 1. 查看版本信息
ming --version

# 2. 初始化新项目
ming init my-awesome-project

# 3. 进入项目目录
cd my-awesome-project

# 4. 验证项目结构
ming validate

# 5. 检查环境健康
ming doctor

# 6. 查看配置
ming config list

# 7. 查看可用模板
ming template list

# 8. 获取帮助
ming help
```

### 🎨 高级使用示例

```bash
# 使用特定模板初始化项目
ming init my-flutter-app --template flutter_clean_architecture

# 企业级验证
ming validate --level enterprise --output json

# 配置管理
ming config set validation.level enterprise
ming config set template.default flutter_clean_architecture

# 导出配置
ming config export --output my-config.yaml

# 性能诊断
ming doctor --verbose --check-performance
```

## 📋 核心功能

### 🔧 项目初始化 (`ming init`)
- **智能检测**: 自动识别项目类型和环境
- **模板选择**: 多种预设项目模板
- **配置生成**: 自动生成最佳实践配置
- **依赖管理**: 智能依赖安装和管理

### 🔍 项目验证 (`ming validate`)
- **结构验证**: 项目结构完整性检查
- **内容验证**: 文件内容和格式验证
- **依赖验证**: 依赖完整性和安全性检查
- **详细报告**: 结构化验证报告和修复建议

### ⚙️ 配置管理 (`ming config`)
- **分层配置**: 用户/工作空间/项目三级配置
- **动态更新**: 实时配置更新和验证
- **类型安全**: 强类型配置验证和错误检查
- **备份恢复**: 配置导入导出和版本管理

### 🏥 健康检查 (`ming doctor`)
- **环境检测**: 开发环境完整性检查
- **依赖验证**: 依赖版本和兼容性验证
- **性能诊断**: 系统性能分析和优化建议
- **修复建议**: 智能问题诊断和解决方案

### 📋 模板管理 (`ming template`)
- **模板列表**: 可用模板展示和筛选
- **模板详情**: 详细模板信息和使用说明
- **自定义模板**: 用户自定义模板支持
- **模板验证**: 模板完整性和兼容性检查

## 🏗️ 技术架构

### 核心技术栈
- **语言**: Dart 3.2+
- **CLI框架**: args package
- **配置管理**: yaml package
- **模板引擎**: mustache_template
- **测试框架**: test package
- **日志系统**: logging package

### 架构设计
```
Ming_Status_Cli/
├── lib/src/
│   ├── commands/          # CLI命令实现 (8个核心命令)
│   ├── core/             # 核心系统组件 (25+模块)
│   │   ├── config_manager.dart      # 配置管理器
│   │   ├── template_engine.dart     # 模板引擎
│   │   ├── validation_system.dart   # 验证系统
│   │   ├── cache_manager.dart       # 缓存管理器
│   │   ├── exception_handler.dart   # 异常处理器
│   │   ├── performance_monitor.dart # 性能监控器
│   │   ├── extension_manager.dart   # 扩展管理器
│   │   └── compatibility_manager.dart # 兼容性管理器
│   ├── models/           # 数据模型定义
│   ├── utils/            # 工具类和辅助函数
│   ├── validators/       # 验证器实现 (15+验证器)
│   └── interfaces/       # 扩展接口定义 (6大扩展接口)
├── templates/            # 项目模板 (10+模板)
├── test/                # 测试套件 (100+测试)
└── docs/                # 项目文档 (15+文档)
```

### 🛡️ 企业级特性
- **安全性保障**: 输入验证、文件安全、依赖安全检查
- **性能优化**: 智能缓存、并行处理、内存优化
- **错误处理**: 异常捕获、自动恢复、详细诊断
- **监控诊断**: 性能监控、资源管理、健康检查

## 🌐 支持平台

### 操作系统
- ✅ **Windows** (Windows 10/11)
- ✅ **macOS** (macOS 10.15+)
- ✅ **Linux** (Ubuntu 18.04+, CentOS 7+)

### 兼容性
- ✅ **Dart SDK**: 3.2.0+
- ✅ **Flutter**: 3.0.0+ (可选)
- ✅ **Node.js**: 16.0.0+ (可选)
- ✅ **Git**: 2.20.0+

## 📚 完整文档

### 📖 用户文档
- **[快速开始](docs/QUICK_START.md)** - 5分钟上手指南
- **[用户手册](docs/USER_GUIDE.md)** - 完整功能说明
- **[最佳实践](docs/BEST_PRACTICES.md)** - 企业级使用最佳实践
- **[故障排除](docs/TROUBLESHOOTING.md)** - 常见问题解决

### 🔧 开发者文档
- **[API文档](docs/API_REFERENCE.md)** - 完整API参考
- **[架构设计](docs/ARCHITECTURE.md)** - 系统架构说明
- **[扩展开发](docs/EXTENSION_DEVELOPMENT.md)** - 插件开发指南
- **[贡献指南](docs/CONTRIBUTING.md)** - 开源贡献指南

### 📋 示例项目
- **[基础示例](examples/basic/)** - 简单项目示例
- **[高级示例](examples/advanced/)** - 复杂项目示例
- **[CI/CD示例](examples/cicd/)** - 集成示例
- **[自定义示例](examples/custom/)** - 自定义扩展示例

## 🧪 质量保证

### 测试覆盖
- ✅ **单元测试**: 100+ 测试用例，覆盖核心逻辑
- ✅ **集成测试**: 50+ 测试场景，验证系统集成
- ✅ **端到端测试**: 完整用户流程验证
- ✅ **性能测试**: 企业级性能基准验证

### 代码质量
- ✅ **静态分析**: Dart Analyzer 0警告
- ✅ **代码风格**: 统一代码风格规范
- ✅ **类型安全**: 100% 强类型覆盖
- ✅ **文档覆盖**: 完整API文档覆盖

## 📊 项目统计

- **总代码行数**: 50,000+ 行
- **核心模块数**: 25+ 个
- **测试文件数**: 30+ 个
- **文档文件数**: 15+ 个
- **CLI命令数**: 8个核心命令
- **验证规则数**: 15+ 个验证器
- **项目模板数**: 10+ 个模板
- **配置选项数**: 50+ 个配置项

## 🔮 Phase 2 预览

### 即将到来的功能
- 🎨 **高级模板系统**: 多层级模板架构 (UI/Service/Data/Full/System)
- 🌐 **远程模板库**: 模板市场和发现机制
- 👥 **团队协作**: 企业集成和权限管理
- 🤖 **AI辅助**: 智能推荐和代码生成
- 🔌 **插件生态**: 完整的插件市场

### 扩展接口
v1.0.0已为Phase 2预留了完整的扩展接口：
- **Template Extension**: 模板扩展接口
- **Validator Extension**: 验证器扩展接口
- **Generator Extension**: 生成器扩展接口
- **Command Extension**: 命令扩展接口
- **Provider Extension**: 提供者扩展接口
- **Middleware Extension**: 中间件扩展接口

## 🤝 贡献

我们欢迎所有形式的贡献！

### 如何贡献
1. **Fork** 本仓库
2. **创建** 功能分支 (`git checkout -b feature/amazing-feature`)
3. **提交** 更改 (`git commit -m 'Add amazing feature'`)
4. **推送** 到分支 (`git push origin feature/amazing-feature`)
5. **创建** Pull Request

### 贡献类型
- 🐛 **Bug修复** - 帮助修复问题
- ✨ **新功能** - 提议和实现新功能
- 📚 **文档改进** - 完善文档和示例
- 🧪 **测试增强** - 增加测试覆盖率
- 🎨 **代码优化** - 性能和代码质量提升

## 📞 支持和反馈

### 获取帮助
- 📖 **文档**: [docs/](docs/)
- 🐛 **问题报告**: [GitHub Issues](https://github.com/pet-app/ming_status_cli/issues)
- 💬 **讨论**: [GitHub Discussions](https://github.com/pet-app/ming_status_cli/discussions)
- 📧 **邮件**: support@pet-app.com

### 社区
- 🌟 **Star** 本项目支持我们
- 👀 **Watch** 获取最新更新
- 🍴 **Fork** 开始贡献代码

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

## 🙏 致谢

感谢所有为Ming Status CLI做出贡献的开发者、测试者和用户！
