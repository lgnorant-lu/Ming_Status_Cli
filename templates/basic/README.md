# Basic Module Template

## 概述

这是Ming Status CLI的基础模块模板，用于快速创建标准的Dart项目结构。该模板适用于：

- 个人项目开发
- 小型模块创建
- 快速原型开发
- 学习和实验项目

## 模板结构

```
{{module_name}}/
├── lib/
│   ├── {{module_name}}.dart          # 主库文件
│   └── src/                          # 源代码目录
│       ├── core/                     # 核心功能
│       ├── models/                   # 数据模型
│       ├── services/                 # 服务层
│       └── utils/                    # 工具类
├── test/                             # 测试文件
│   ├── {{module_name}}_test.dart     # 主测试文件
│   └── src/                          # 源代码测试
├── example/                          # 示例代码
│   └── main.dart                     # 示例入口
├── doc/                              # 文档目录
│   └── api.md                        # API文档
├── pubspec.yaml                      # 项目配置文件
├── analysis_options.yaml             # 代码分析配置
├── README.md                         # 项目说明
├── CHANGELOG.md                      # 变更日志
└── LICENSE                           # 开源许可证
```

## 模板变量

| 变量名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| `module_name` | string | my_module | 模块名称 |
| `description` | string | A new Dart module | 模块描述 |
| `author` | string | Developer | 作者名称 |
| `dart_version` | string | ^3.2.0 | Dart版本约束 |
| `license` | string | MIT | 开源许可证 |
| `use_analysis` | boolean | true | 是否包含代码分析配置 |
| `create_example` | boolean | true | 是否创建示例文件 |

## 使用方法

### 通过Ming Status CLI使用

```bash
# 使用默认配置创建模块
ming create module --template basic

# 指定模块名称
ming create module --template basic --name my_awesome_module

# 交互式创建
ming create module --template basic --interactive
```

### 通过Mason直接使用

```bash
# 添加模板
mason add basic --path ./templates/basic

# 生成模块
mason make basic

# 指定变量生成
mason make basic --module_name my_module --author "John Doe"
```

## 生成后的步骤

1. 进入生成的模块目录
2. 运行 `dart pub get` 安装依赖
3. 运行 `dart test` 执行测试
4. 开始编写您的代码！

## 自定义

您可以通过以下方式自定义此模板：

1. **修改brick.yaml**: 添加或修改变量定义
2. **编辑模板文件**: 在`__brick__`目录中添加或修改模板文件
3. **添加钩子**: 在`hooks`部分添加生成前后的脚本

## 注意事项

- 模块名称应符合Dart包命名规范（小写字母、数字、下划线）
- 确保Dart版本兼容性
- 根据项目需要选择合适的开源许可证

## 支持与反馈

如有问题或建议，请通过以下方式联系：

- 项目仓库Issue
- Ming Status CLI官方文档
- 社区讨论区

---

*该模板由Ming Status CLI v1.0.0生成* 