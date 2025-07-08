# Git工作流规范

## 概述

本文档定义了Ming Status CLI项目的Git工作流规范，基于DEC-001决策制定的约定式提交规范。

## 分支策略

### 主要分支

- **main**: 主分支，包含生产就绪的代码
- **develop**: 开发分支，包含最新的开发功能
- **feature/***: 功能分支，用于开发新功能
- **fix/***: 修复分支，用于修复bug
- **release/***: 发布分支，用于准备新版本发布

### 分支命名规范

```bash
# 功能分支
feature/validation-system
feature/cli-enhancement
feature/template-engine

# 修复分支  
fix/encoding-issue
fix/test-failure
fix/performance-bug

# 发布分支
release/v1.0.0
release/v1.1.0
```

## 提交信息规范

### 完整格式

```
<type>(<scope>): <中文简短描述>

[可选的正文，详细描述本次提交的动机、实现思路和与之前行为的对比。
可以有多行，每行建议不超过72个字符。]

[可选的页脚]
BREAKING CHANGE: <描述此提交引入的重大变更，以及迁移指南。>
Closes: #<问题编号>
```

### 类型定义

| 类型 | 描述 | 示例 |
|------|------|------|
| feat | 新功能 | `feat(core): 添加验证器注册功能` |
| fix | Bug修复 | `fix(cli): 修复命令行参数解析错误` |
| docs | 文档更新 | `docs(readme): 更新安装说明` |
| style | 代码格式 | `style(core): 统一代码缩进格式` |
| refactor | 代码重构 | `refactor(validators): 重构验证器架构` |
| perf | 性能优化 | `perf(core): 优化验证器执行性能` |
| test | 测试相关 | `test(validators): 添加结构验证器测试` |
| build | 构建相关 | `build(deps): 更新pubspec.yaml依赖` |
| ci | CI/CD相关 | `ci(github): 添加自动化测试流水线` |
| chore | 其他杂项 | `chore(git): 添加.gitignore规则` |
| revert | 撤销提交 | `revert: 撤销feat(core): 添加验证功能` |

### 范围定义

| 范围 | 描述 | 包含内容 |
|------|------|----------|
| core | 核心系统 | ValidatorService, ModuleValidator等 |
| cli | 命令行接口 | 命令实现、参数解析、帮助系统 |
| validators | 验证器 | StructureValidator, QualityValidator等 |
| templates | 模板系统 | 模板引擎、模板文件、生成逻辑 |
| config | 配置管理 | 配置文件、配置解析、默认设置 |
| models | 数据模型 | ValidationResult, ValidationMessage等 |
| utils | 工具类 | Logger, FileUtils, PathUtils等 |
| test | 测试相关 | 单元测试、集成测试、性能测试 |
| docs | 文档相关 | README, API文档, 规范文档 |

## 工作流程

### 1. 功能开发流程

```bash
# 1. 从main分支创建功能分支
git checkout main
git pull origin main
git checkout -b feature/new-validation-feature

# 2. 开发功能并提交
git add .
git commit -m "feat(validators): 添加新的验证规则

实现了针对模块依赖关系的高级验证功能：
- 循环依赖检测
- 版本兼容性验证
- 安全漏洞扫描

提升了验证系统的企业级能力。"

# 3. 推送分支
git push origin feature/new-validation-feature

# 4. 创建Pull Request
# 在GitHub/GitLab上创建PR，请求合并到develop分支
```

### 2. Bug修复流程

```bash
# 1. 从main分支创建修复分支
git checkout main
git pull origin main
git checkout -b fix/cli-encoding-issue

# 2. 修复bug并提交
git add .
git commit -m "fix(cli): 修复Windows环境下中文字符显示问题

通过设置UTF-8编码解决了在Windows环境下中文字符和emoji
显示为乱码的问题。

修复内容：
- 在CLI启动时自动设置UTF-8编码
- 更新测试用例以适配编码修复
- 添加跨平台编码兼容性检查

Closes: #42"

# 3. 推送并创建PR
git push origin fix/cli-encoding-issue
```

### 3. 发布流程

```bash
# 1. 从develop创建发布分支
git checkout develop
git pull origin develop
git checkout -b release/v1.1.0

# 2. 准备发布（更新版本号、CHANGELOG等）
git add .
git commit -m "chore(release): 准备v1.1.0版本发布

更新内容：
- 版本号更新至1.1.0
- 更新CHANGELOG.md
- 更新文档版本信息"

# 3. 合并到main并打标签
git checkout main
git merge release/v1.1.0
git tag -a v1.1.0 -m "Release version 1.1.0"
git push origin main --tags

# 4. 合并回develop
git checkout develop
git merge main
git push origin develop
```

## 提交最佳实践

### 1. 提交频率
- 小而频繁的提交优于大而稀少的提交
- 每个提交应该代表一个逻辑上完整的变更
- 避免将多个不相关的变更放在同一个提交中

### 2. 提交信息质量
- 使用现在时态："添加功能"而不是"添加了功能"
- 首行不超过50个字符
- 正文每行不超过72个字符
- 详细说明变更的原因和影响

### 3. 代码质量检查
```bash
# 提交前检查
dart analyze                    # 静态分析
dart test                      # 运行测试
dart format --set-exit-if-changed .  # 代码格式检查
```

## 自动化工具

### 1. 提交信息验证
可以使用commit-msg hook验证提交信息格式：

```bash
#!/bin/sh
# .git/hooks/commit-msg

commit_regex='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?: .{1,50}'

if ! grep -qE "$commit_regex" "$1"; then
    echo "Invalid commit message format!"
    echo "Format: <type>(<scope>): <description>"
    echo "Example: feat(core): 添加新的验证功能"
    exit 1
fi
```

### 2. 自动化CHANGELOG生成
使用conventional-changelog工具自动生成CHANGELOG：

```bash
npm install -g conventional-changelog-cli
conventional-changelog -p angular -i CHANGELOG.md -s
```

## 相关文档

- [约定式提交规范官方文档](https://www.conventionalcommits.org/)
- [项目贡献指南](../README.md#贡献指南)
- [代码审查规范](./Code-Review.md) (待创建)
- [发布流程文档](./Release-Process.md) (待创建)
