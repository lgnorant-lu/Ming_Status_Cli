# Ming Status CLI 示例项目和教程

欢迎来到 Ming Status CLI 的示例项目和教程中心！这里包含了从基础到高级的完整学习路径。

## 📚 学习路径

### 🌟 新手入门
1. [快速开始教程](./01-quick-start/) - 5分钟上手指南
2. [基础项目创建](./02-basic-project/) - 创建你的第一个项目
3. [模板使用指南](./03-template-usage/) - 掌握模板系统

### 🚀 进阶应用
4. [多模块项目](./04-multi-module/) - 复杂项目结构管理
5. [自定义模板](./05-custom-templates/) - 创建专属模板
6. [CI/CD集成](./06-cicd-integration/) - 持续集成最佳实践

### 🏆 高级技巧
7. [性能优化](./07-performance/) - 大型项目性能调优
8. [扩展开发](./08-extensions/) - 插件和扩展开发
9. [企业部署](./09-enterprise/) - 企业级部署方案

## 🎯 示例项目

### 基础示例
- **hello-world**: 最简单的入门项目
- **dart-package**: 标准Dart包项目
- **flutter-app**: Flutter应用项目

### 实际应用
- **blog-system**: 博客系统项目
- **api-server**: REST API服务器
- **mobile-app**: 移动应用项目

### 企业级示例
- **microservices**: 微服务架构
- **monorepo**: 单仓库多项目
- **enterprise-app**: 企业级应用

## 🛠️ 工具和资源

### 开发工具
- [VS Code扩展配置](./tools/vscode/)
- [IntelliJ IDEA配置](./tools/intellij/)
- [命令行工具](./tools/cli/)

### 模板库
- [官方模板](./templates/official/)
- [社区模板](./templates/community/)
- [企业模板](./templates/enterprise/)

### 最佳实践
- [项目结构规范](./best-practices/structure/)
- [命名约定](./best-practices/naming/)
- [版本管理](./best-practices/versioning/)

## 📖 教程格式说明

每个教程都包含以下部分：

### 📋 教程结构
```
tutorial-name/
├── README.md          # 教程说明
├── setup.md           # 环境准备
├── steps/             # 分步指南
│   ├── step-01.md
│   ├── step-02.md
│   └── ...
├── code/              # 示例代码
├── assets/            # 图片和资源
└── troubleshooting.md # 故障排除
```

### 🎯 学习目标
每个教程都明确定义：
- 学习目标和预期成果
- 所需时间和难度级别
- 前置知识和依赖

### 📝 实践练习
- 动手实践环节
- 练习题和挑战
- 扩展思考问题

## 🚀 快速开始

### 1. 选择适合的教程
根据你的经验水平选择合适的起点：

- **完全新手**: 从 [快速开始教程](./01-quick-start/) 开始
- **有经验用户**: 直接查看 [多模块项目](./04-multi-module/)
- **开发者**: 参考 [扩展开发](./08-extensions/)

### 2. 准备环境
确保你已经安装了 Ming Status CLI：

```bash
# 安装 Ming CLI
dart pub global activate ming_status_cli

# 验证安装
ming --version
```

### 3. 克隆示例项目
```bash
# 克隆整个示例库
git clone https://github.com/ming-cli/examples.git
cd examples

# 或者只下载特定教程
ming template install examples/01-quick-start
```

## 📊 教程统计

| 类别 | 教程数量 | 难度级别 | 预计时间 |
|------|----------|----------|----------|
| 新手入门 | 3 | ⭐ | 2-3小时 |
| 进阶应用 | 3 | ⭐⭐ | 4-6小时 |
| 高级技巧 | 3 | ⭐⭐⭐ | 6-10小时 |
| **总计** | **9** | - | **12-19小时** |

## 🤝 贡献指南

### 如何贡献教程

1. **选择主题**
   - 查看 [教程需求列表](./CONTRIBUTING.md#needed-tutorials)
   - 提出新的教程想法

2. **创建教程**
   - 遵循 [教程模板](./templates/tutorial-template/)
   - 包含完整的代码示例

3. **测试验证**
   - 确保所有步骤可重现
   - 在不同环境中测试

4. **提交贡献**
   - 创建 Pull Request
   - 参与代码审查

### 质量标准
- ✅ 清晰的步骤说明
- ✅ 完整的代码示例
- ✅ 错误处理指导
- ✅ 最佳实践建议

## 📞 获取帮助

### 支持渠道
- 📖 [官方文档](../docs/)
- 💬 [社区讨论](https://github.com/ming-cli/ming_status_cli/discussions)
- 🐛 [问题报告](https://github.com/ming-cli/ming_status_cli/issues)
- 📧 [邮件支持](mailto:support@ming-cli.com)

### 常见问题
- [安装问题](../docs/user_manual.md#故障排除)
- [配置问题](../docs/user_manual.md#配置管理)
- [模板问题](../docs/user_manual.md#模板系统)

## 🔄 更新日志

### 最新更新 (2025-07-08)
- ✅ 新增快速开始教程
- ✅ 完善多模块项目示例
- ✅ 添加CI/CD集成指南
- ✅ 更新最佳实践文档

### 计划更新
- 🔄 Vue.js项目模板
- 🔄 Docker部署教程
- 🔄 Kubernetes集成指南
- 🔄 性能监控教程

---

**开始你的 Ming CLI 学习之旅吧！** 🚀

选择一个教程，跟随步骤，在实践中掌握 Ming Status CLI 的强大功能。

*示例项目版本: 1.0.0 | 最后更新: 2025-07-08*
