# Brick.yaml Configuration Format Specification

**Version**: 2.0  
**Last Updated**: 2025-06-30  
**Compatibility**: Mason v0.1.1+, Ming Status CLI v1.0.0+

## 概述

`brick.yaml` 是 Ming Status CLI 模板系统的核心配置文件，基于 Mason 标准扩展了 Ming Status CLI 特有的功能。本文档定义了完整的配置格式规范。

这个配置文件定义了模板的结构、变量、钩子函数等关键信息，是模板系统的核心组件。

## 文件结构

### 1. 基本信息 (必需)

```yaml
# 模板标识符 (必需)
name: template_name

# 模板描述 (必需)
description: "模板功能的简要描述"

# 模板版本 (必需)
version: "1.0.0"
```

#### 字段说明

| 字段 | 类型 | 必需 | 描述 | 验证规则 |
|------|------|------|------|---------|
| `name` | string | ✅ | 模板唯一标识符 | 小写字母、数字、下划线，长度3-50字符 |
| `description` | string | ✅ | 模板功能描述 | 长度10-200字符 |
| `version` | string | ✅ | 语义化版本号 | 遵循SemVer格式 |

### 2. 变量定义 (vars)

```yaml
vars:
  variable_name:
    type: string|boolean|number|enum|list
    description: "变量说明"
    default: default_value
    prompt: "用户提示信息"
    optional: true|false
    validation:
      pattern: "正则表达式"
      min_length: number
      max_length: number
      min_value: number
      max_value: number
      message: "验证失败消息"
    values: # 仅enum类型
      - value1
      - value2
```

#### 支持的变量类型

##### string 类型
```yaml
module_name:
  type: string
  description: "模块名称"
  default: "my_module"
  prompt: "请输入模块名称"
  validation:
    pattern: "^[a-z][a-z0-9_]*$"
    min_length: 2
    max_length: 50
    message: "模块名称格式不正确"
```

##### boolean 类型
```yaml
create_tests:
  type: boolean
  description: "是否创建测试文件"
  default: true
  prompt: "是否创建测试文件?"
```

##### number 类型
```yaml
port:
  type: number
  description: "服务端口号"
  default: 8080
  validation:
    min_value: 1024
    max_value: 65535
```

##### enum 类型
```yaml
license:
  type: enum
  description: "开源许可证"
  default: "MIT"
  values:
    - "MIT"
    - "Apache-2.0"
    - "BSD-3-Clause"
    - "GPL-3.0"
```

##### list 类型
```yaml
dependencies:
  type: list
  description: "依赖包列表"
  default: []
  validation:
    min_length: 0
    max_length: 20
```

### 3. 输出配置 (output)

```yaml
output:
  # 包含的文件路径模式
  include_paths:
    - "**/*"
    - "lib/**/*.dart"
  
  # 排除的文件路径模式  
  exclude_paths:
    - ".git/**"
    - ".dart_tool/**"
    - "build/**"
  
  # 条件输出
  conditional:
    - condition: "{{use_analysis}}"
      include_paths:
        - "analysis_options.yaml"
    - condition: "{{create_example}}"
      include_paths:
        - "example/**"
      exclude_paths:
        - "example/.gitkeep"
```

#### 路径模式规则

- 使用 glob 模式匹配文件路径
- `**` 匹配任意深度的目录
- `*` 匹配单层目录或文件名
- `?` 匹配单个字符
- 支持变量插值: `{{variable_name}}`

### 4. 钩子配置 (hooks)

```yaml
hooks:
  pre_gen:
    - description: "钩子描述"
      script: "命令或脚本"
      condition: "执行条件"
      timeout: 30000
      ignore_errors: false
      
  post_gen:
    - description: "生成后处理"
      script: "echo '生成完成'"
      condition: "success"
```

#### 钩子类型

| 钩子类型 | 执行时机 | 描述 |
|----------|----------|------|
| `pre_gen` | 生成前 | 环境检查、依赖验证等 |
| `post_gen` | 生成后 | 依赖安装、格式化等 |

#### 钩子字段

| 字段 | 类型 | 必需 | 默认值 | 描述 |
|------|------|------|--------|------|
| `description` | string | ✅ | - | 钩子说明 |
| `script` | string | ✅ | - | 执行的命令 |
| `condition` | string | ❌ | "true" | 执行条件 |
| `timeout` | number | ❌ | 30000 | 超时时间(ms) |
| `ignore_errors` | boolean | ❌ | false | 忽略错误 |

#### 预定义条件

- `success`: 前一步成功
- `failure`: 前一步失败  
- `{{variable}}`: 变量值为真
- `!{{variable}}`: 变量值为假

### 5. 元数据配置 (metadata)

```yaml
metadata:
  # 分类信息
  category: "basic|advanced|specialized"
  tags:
    - "dart"
    - "flutter"
    - "package"
  
  # 兼容性
  min_dart_version: "3.0.0"
  max_dart_version: "4.0.0"
  min_mason_version: "0.1.0"
  
  # 平台支持
  platforms:
    supported: ["windows", "macos", "linux"]
    required_features: ["dart"]
    optional_features: ["git", "vscode"]
  
  # 创建信息
  created_by: "作者名称"
  maintainer: "维护者"
  homepage: "https://example.com"
  documentation: "https://docs.example.com"
  last_updated: "2025-06-30"
  
  # 性能指标
  estimated_generation_time: "< 3 seconds"
  estimated_file_count: 12
  estimated_size: "< 50KB"
```

### 6. Ming Status CLI 扩展配置 (ming_config)

```yaml
ming_config:
  # 模板配置
  template_version: "2.0"
  compatibility_check: true
  auto_format: true
  auto_analyze: true
  
  # 集成功能
  integrations:
    config_manager: true
    doctor_command: true
    validation_system: true
  
  # 自定义处理器
  custom_processors:
    - type: "snake_case_converter"
      target: "module_name"
    - type: "title_case_converter"
      target: "description"
  
  # 模板继承
  inheritance:
    base_template: "parent_template"
    override_vars: ["var1", "var2"]
    merge_hooks: true
```

## 最佳实践

### 1. 命名约定

- **模板名称**: 使用小写字母、数字和下划线
- **变量名称**: 使用snake_case格式
- **文件名**: 支持变量插值，如`{{module_name}}.dart`

### 2. 变量设计

- 提供合理的默认值
- 添加清晰的描述和提示
- 使用适当的验证规则
- 考虑变量之间的依赖关系

### 3. 钩子使用

- 保持钩子脚本简单
- 添加适当的错误处理
- 使用描述性的说明文本
- 避免长时间运行的操作

### 4. 元数据完整性

- 提供准确的兼容性信息
- 使用有意义的标签分类
- 保持文档链接有效
- 及时更新维护信息

## 验证规则

### 1. 语法验证

- YAML格式正确性
- 必需字段完整性
- 字段类型匹配

### 2. 语义验证

- 变量引用有效性
- 路径模式正确性
- 钩子脚本安全性

### 3. 兼容性验证

- Mason版本兼容性
- Dart版本约束
- 平台支持检查

## 示例模板

### 基础模板示例

```yaml
name: basic
description: "基础Dart模块模板"
version: "1.0.0"

vars:
  module_name:
    type: string
    default: "my_module"
    prompt: "模块名称"
    validation:
      pattern: "^[a-z][a-z0-9_]*$"

output:
  include_paths: ["**/*"]
  exclude_paths: [".git/**"]

hooks:
  post_gen:
    - description: "安装依赖"
      script: "dart pub get"

metadata:
  category: "basic"
  tags: ["dart", "module"]
  min_dart_version: "3.0.0"
```

### 高级模板示例

```yaml
name: flutter_package
description: "Flutter包模板"
version: "2.0.0"

vars:
  package_name:
    type: string
    validation:
      pattern: "^[a-z][a-z0-9_]*$"
  
  supports_web:
    type: boolean
    default: false
  
  license:
    type: enum
    values: ["MIT", "Apache-2.0", "BSD-3-Clause"]

output:
  conditional:
    - condition: "{{supports_web}}"
      include_paths: ["web/**"]

hooks:
  pre_gen:
    - description: "检查Flutter环境"
      script: "flutter --version"
  
  post_gen:
    - description: "获取依赖"
      script: "flutter pub get"
    - description: "运行测试"
      script: "flutter test"
      condition: "{{create_tests}}"

metadata:
  category: "flutter"
  platforms:
    supported: ["windows", "macos", "linux"]
    required_features: ["flutter"]

ming_config:
  auto_format: true
  custom_processors:
    - type: "flutter_package_validator"
      target: "package_name"
```

## 更新历史

- **v2.0** (2025-06-30): 添加Ming Status CLI扩展配置
- **v1.0** (2025-06-29): 初始版本，基于Mason标准
