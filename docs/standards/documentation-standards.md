# Ming Status CLI 文档规范标准

## 📋 概述

本文档定义了 Ming Status CLI 项目的文档编写、组织和维护标准，确保文档的一致性、可读性和可维护性。

## 🎯 文档分类体系

### 1. 文档层级结构

```
docs/
├── standards/                 # 文档规范
│   ├── documentation-standards.md
│   ├── module-template.md
│   └── api-template.md
├── architecture/              # 架构文档
│   ├── overview.md           # 系统概览
│   ├── modules/              # 模块架构
│   │   ├── core-modules.md
│   │   └── extension-modules.md
│   └── decisions/            # 架构决策记录(ADR)
│       ├── adr-001-template-engine.md
│       └── adr-002-configuration-management.md
├── api/                      # API文档
│   ├── core/                 # 核心API
│   │   ├── template-engine.md
│   │   └── configuration-management.md
│   └── generated/            # 自动生成的API文档
├── user/                     # 用户文档
│   ├── guides/               # 使用指南
│   │   ├── getting-started.md
│   │   ├── template-creation.md
│   │   └── configuration-management.md
│   ├── tutorials/            # 教程
│   │   ├── basic-usage.md
│   │   └── advanced-features.md
│   └── examples/             # 示例
│       ├── flutter-project.md
│       └── enterprise-setup.md
├── developer/                # 开发者文档
│   ├── setup/                # 环境搭建
│   │   ├── development-environment.md
│   │   └── testing-environment.md
│   ├── contributing/         # 贡献指南
│   │   ├── code-style.md
│   │   ├── pull-request-process.md
│   │   └── issue-reporting.md
│   └── testing/              # 测试指南
│       ├── unit-testing.md
│       ├── integration-testing.md
│       └── performance-testing.md
└── modules/                  # 模块文档
    ├── configuration_management/
    │   ├── README.md
    │   ├── ARCHITECTURE.md
    │   ├── API.md
    │   ├── USAGE.md
    │   ├── EXAMPLES.md
    │   ├── TESTING.md
    │   └── CHANGELOG.md
    └── template_creator/
        └── ... (同样结构)
```

### 2. 文档类型定义

| 文档类型 | 目标受众 | 主要内容 | 更新频率 | 维护责任 |
|----------|----------|----------|----------|----------|
| **架构文档** | 架构师、高级开发者 | 系统设计、模块关系、技术决策 | 低频 | 架构师 |
| **API文档** | 开发者、集成者 | 接口定义、参数说明、示例代码 | 高频 | 模块开发者 |
| **用户文档** | 最终用户、运维人员 | 功能说明、操作指南、故障排除 | 中频 | 产品经理 |
| **开发者文档** | 贡献者、维护者 | 开发环境、编码规范、测试流程 | 中频 | 技术负责人 |
| **模块文档** | 模块开发者、使用者 | 模块设计、实现细节、使用方法 | 高频 | 模块负责人 |

## 📝 通用文档规范

### 1. 文档头部信息

每个文档都应包含以下头部信息：

```markdown
# 文档标题

> **文档类型**: [架构文档/API文档/用户指南/开发者文档/模块文档]  
> **目标受众**: [具体受众]  
> **维护者**: [负责人]  
> **最后更新**: [YYYY-MM-DD]  
> **版本**: [文档版本]

## 📋 概述

[文档概述，1-2段简要说明文档内容和目的]
```

### 2. 标题规范

- **一级标题**: 使用 `#`，文档主标题
- **二级标题**: 使用 `##`，主要章节
- **三级标题**: 使用 `###`，子章节
- **四级标题**: 使用 `####`，详细内容（谨慎使用）

### 3. 内容格式规范

#### 代码块
```markdown
# 行内代码
使用 `代码` 格式

# 代码块
```dart
// 指定语言类型
class Example {
  void method() {}
}
```
```

#### 表格
```markdown
| 列1 | 列2 | 列3 |
|-----|-----|-----|
| 内容1 | 内容2 | 内容3 |
```

#### 链接
```markdown
# 内部链接（相对路径）
[模块文档](../modules/configuration_management/README.md)

# 外部链接
[Flutter官网](https://flutter.dev)

# 锚点链接
[跳转到概述](#概述)
```

#### 图片
```markdown
# 图片引用
![图片描述](../assets/images/architecture-diagram.png)

# 图片存放规范
docs/assets/
├── images/           # 图片文件
├── diagrams/         # 图表文件
└── videos/           # 视频文件
```

### 4. 特殊标记

```markdown
# 提示框
> **💡 提示**: 这是一个提示信息

> **⚠️ 警告**: 这是一个警告信息

> **❌ 错误**: 这是一个错误信息

> **✅ 成功**: 这是一个成功信息

# 状态标记
- ✅ 已完成
- 🚧 开发中
- 📋 计划中
- ❌ 已废弃
```

## 🏗️ 模块文档规范

### 1. 文档结构标准

每个模块必须包含以下文档：

1. **README.md** - 模块概览
2. **ARCHITECTURE.md** - 架构设计
3. **API.md** - API文档
4. **USAGE.md** - 使用指南
5. **EXAMPLES.md** - 示例代码
6. **TESTING.md** - 测试文档
7. **CHANGELOG.md** - 变更日志

### 2. 文档内容要求

#### README.md 要求
- 模块简介（1-2段）
- 核心功能列表
- 快速开始示例
- 目录结构说明
- 相关文档链接

#### ARCHITECTURE.md 要求
- 设计理念和目标
- 核心组件说明
- 数据流图
- 依赖关系图
- 设计决策说明

#### API.md 要求
- 公共接口列表
- 类和方法详细说明
- 参数和返回值定义
- 异常处理说明
- 代码示例

## 📊 文档质量标准

### 1. 内容质量要求

- **准确性**: 内容与代码实现保持一致
- **完整性**: 覆盖所有公共接口和主要功能
- **清晰性**: 语言简洁明了，逻辑清晰
- **实用性**: 提供实际可用的示例和指导

### 2. 维护要求

- **及时更新**: 代码变更时同步更新文档
- **版本控制**: 重要变更记录在 CHANGELOG.md
- **审查机制**: 文档变更需要经过审查
- **定期检查**: 定期检查文档的准确性和完整性

## 🔄 文档生命周期

### 1. 创建阶段
- 使用标准模板创建文档
- 填写基本信息和结构
- 初始内容编写

### 2. 维护阶段
- 代码变更时更新文档
- 定期审查和优化
- 用户反馈处理

### 3. 归档阶段
- 废弃功能的文档标记
- 历史版本归档
- 迁移指南编写

## 📋 检查清单

### 新模块文档检查清单

- [ ] 创建了完整的文档结构
- [ ] README.md 包含必要信息
- [ ] ARCHITECTURE.md 说明设计理念
- [ ] API.md 覆盖所有公共接口
- [ ] USAGE.md 提供使用指南
- [ ] EXAMPLES.md 包含实用示例
- [ ] TESTING.md 说明测试策略
- [ ] CHANGELOG.md 记录变更历史
- [ ] 所有文档使用统一格式
- [ ] 链接和引用正确
- [ ] 代码示例可执行

### 文档更新检查清单

- [ ] 内容与代码实现一致
- [ ] 新功能已添加到文档
- [ ] 废弃功能已标记
- [ ] 示例代码已验证
- [ ] 链接和引用已检查
- [ ] CHANGELOG.md 已更新
- [ ] 版本信息已更新

---

> **维护者**: Ming Status CLI 团队  
> **最后更新**: 2025-07-13  
> **版本**: 1.0.0
