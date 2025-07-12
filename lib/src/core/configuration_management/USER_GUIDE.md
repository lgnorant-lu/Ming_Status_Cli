# 配置管理系统用户指南

## 🎯 快速入门

配置管理系统帮助您智能地管理项目依赖，自动检测版本冲突，优化配置组合，确保项目的稳定性和性能。

### 基本概念

- **配置集合**: 一组相关的依赖包及其版本
- **兼容性检查**: 检测依赖包之间的版本冲突
- **配置优化**: 自动推荐最佳的依赖版本组合
- **增量更新**: 安全地更新部分依赖而不影响整体稳定性

## 🚀 CLI 使用指南

### 检查配置兼容性

检查当前模板的依赖配置是否存在兼容性问题。

```bash
# 基本兼容性检查
ming template update --check-config --template=my_app

# 详细兼容性检查
ming template update --check-config --template=my_app --verbose
```

**输出示例**:
```
🔍 检查模板配置兼容性: my_app
✅ 配置兼容性检查通过
```

**如果发现问题**:
```
🔍 检查模板配置兼容性: my_app
❌ 发现配置兼容性问题

兼容性问题:
  • http ^0.13.0 与 dio ^5.0.0 存在网络库冲突
  • json_annotation ^4.0.0 与 json_serializable ^6.0.0 版本不匹配
  • provider ^6.0.0 与 riverpod ^2.0.0 状态管理库冲突
```

### 优化配置版本

自动分析并推荐最优的依赖版本组合。

```bash
# 使用平衡策略优化
ming template update --optimize-config --template=my_app

# 使用保守策略优化（生产环境推荐）
ming template update --optimize-config --template=my_app --config-strategy=conservative

# 使用激进策略优化（获取最新特性）
ming template update --optimize-config --template=my_app --config-strategy=aggressive

# 详细输出模式
ming template update --optimize-config --template=my_app --verbose
```

**输出示例**:
```
⚡ 优化模板配置: my_app (策略: balanced)
✅ 配置优化完成
📊 优化结果:
  • 候选配置: 15 个
  • 测试结果: 15 个
  • 成功率: 86.7%
  • 执行时间: 1247ms

推荐配置:
  • ID: balanced_1752346115329
  • 名称: Balanced Configuration
  • 优先级: 0.85
  • 复杂度: 8
  • 依赖 (12 个):
    - http: v1.2.0
    - json_annotation: v4.9.0
    - json_serializable: v6.9.5
    - provider: v6.1.2
    - go_router: v16.0.0
    ... 还有 7 个依赖
```

### 测试配置可用性

测试当前配置并获取更新建议。

```bash
# 基本配置测试
ming template update --test-config --template=my_app

# 详细配置测试
ming template update --test-config --template=my_app --verbose
```

**输出示例**:
```
🧪 测试模板配置: my_app
📋 发现 3 个更新建议:
  • 更新 http 从 v1.1.0 到 v1.2.0 (影响: 15.2%)
  • 更新 json_serializable 从 v6.8.0 到 v6.9.5 (影响: 8.7%)
  • 添加 very_good_analysis 到 v9.0.0 (影响: 5.3%)

📊 更新分析:
  • 总体影响: 9.7%
  • 安全等级: 🟢 安全
```

### 高级选项

#### 控制影响阈值

限制更新的影响范围，确保稳定性。

```bash
# 只允许低影响的更新（影响 < 30%）
ming template update --optimize-config --template=my_app --max-impact=0.3

# 只允许极低影响的更新（影响 < 10%）
ming template update --optimize-config --template=my_app --max-impact=0.1
```

#### 选择配置策略

根据项目需求选择不同的优化策略。

```bash
# 保守策略 - 优先稳定性（生产环境）
ming template update --optimize-config --config-strategy=conservative

# 平衡策略 - 稳定性与新特性平衡（默认）
ming template update --optimize-config --config-strategy=balanced

# 激进策略 - 优先新特性（实验项目）
ming template update --optimize-config --config-strategy=aggressive

# 自动策略 - AI自动选择最优策略
ming template update --optimize-config --config-strategy=automatic
```

## 📊 配置策略详解

### 🛡️ 保守策略 (Conservative)

**适用场景**: 生产环境、关键业务系统、稳定性要求高的项目

**特点**:
- 优先选择经过长期验证的稳定版本
- 避免使用预发布版本和最新版本
- 最小化依赖变更的影响
- 重视向后兼容性

**推荐使用**:
```bash
ming template update --optimize-config --config-strategy=conservative --max-impact=0.2
```

### ⚖️ 平衡策略 (Balanced)

**适用场景**: 大多数开发项目、日常开发工作

**特点**:
- 在稳定性和新特性之间取得平衡
- 适度采用新版本的改进
- 考虑性能和安全性提升
- 合理的风险控制

**推荐使用**:
```bash
ming template update --optimize-config --config-strategy=balanced
```

### 🚀 激进策略 (Aggressive)

**适用场景**: 实验性项目、新技术探索、原型开发

**特点**:
- 优先使用最新版本和新特性
- 快速采用社区最新改进
- 接受较高的不稳定风险
- 追求最新的性能和功能

**推荐使用**:
```bash
ming template update --optimize-config --config-strategy=aggressive --max-impact=0.8
```

### 🤖 自动策略 (Automatic)

**适用场景**: 复杂项目、不确定的场景、需要AI辅助决策

**特点**:
- 基于机器学习模型自动选择
- 考虑项目历史和成功模式
- 动态调整策略参数
- 智能风险评估

**推荐使用**:
```bash
ming template update --optimize-config --config-strategy=automatic
```

## 🔧 编程接口使用

### 基本使用

```dart
import 'package:ming_status_cli/src/core/configuration_management/index.dart';

Future<void> main() async {
  // 创建配置管理器
  final configManager = ConfigurationManager(
    options: const ConfigurationOptions(
      maxCombinations: 20,
      enableTesting: true,
      concurrency: 4,
    ),
  );
  
  try {
    // 获取优化配置
    final result = await configManager.getOptimizedConfig(
      packageNames: ['http', 'dio', 'json_annotation'],
      strategy: ConfigurationStrategy.balanced,
    );
    
    print('推荐配置: ${result.recommendedConfig.name}');
    print('成功率: ${(result.successRate * 100).toStringAsFixed(1)}%');
    
  } finally {
    configManager.dispose();
  }
}
```

### 高级使用

```dart
// 自定义配置选项
final configManager = ConfigurationManager(
  options: const ConfigurationOptions(
    maxCombinations: 50,        // 增加测试组合数
    maxImpactThreshold: 0.5,    // 降低影响阈值
    includePrerelease: false,   // 排除预发布版本
    enableTesting: true,        // 启用配置测试
    concurrency: 8,             // 提高并发数
    timeoutSeconds: 60,         // 增加超时时间
    enableCache: true,          // 启用缓存
  ),
);

// 带约束的配置优化
final result = await configManager.getOptimizedConfig(
  currentConfig: myCurrentConfig,
  packageNames: ['http', 'dio', 'json_annotation', 'json_serializable'],
  strategy: ConfigurationStrategy.conservative,
  constraints: {
    'minStabilityScore': 0.8,
    'maxComplexity': 10,
    'requiredPackages': ['http'],
    'excludedPackages': ['chopper'],
  },
);
```

## 🚨 故障排除

### 常见问题和解决方案

#### 1. 模板不存在

**问题**: `❌ 模板不存在: template_name`

**解决方案**:
```bash
# 查看可用模板列表
ming template list

# 确认模板名称拼写正确
ming template info template_name
```

#### 2. 配置兼容性检查失败

**问题**: `❌ 发现配置兼容性问题`

**解决方案**:
```bash
# 查看详细的兼容性问题
ming template update --check-config --template=my_app --verbose

# 使用保守策略重新优化
ming template update --optimize-config --config-strategy=conservative
```

#### 3. 优化配置成功率低

**问题**: `成功率: 0.0%` 或成功率很低

**解决方案**:
```bash
# 降低影响阈值
ming template update --optimize-config --max-impact=0.3

# 使用更保守的策略
ming template update --optimize-config --config-strategy=conservative

# 减少测试组合数（如果性能问题）
# 在代码中设置 maxCombinations: 10
```

#### 4. 网络连接问题

**问题**: 网络超时或连接失败

**解决方案**:
```bash
# 增加超时时间
# 在代码中设置 timeoutSeconds: 120

# 启用缓存以减少网络请求
# 在代码中设置 enableCache: true

# 检查网络连接和代理设置
```

#### 5. 性能问题

**问题**: 执行时间过长

**解决方案**:
```bash
# 减少最大组合数
# maxCombinations: 20

# 增加并发数
# concurrency: 8

# 禁用测试以提高速度
# enableTesting: false
```

### 调试技巧

#### 启用详细日志

```dart
// 在代码中启用详细日志
final configManager = ConfigurationManager(
  options: const ConfigurationOptions(
    // ... 其他选项
  ),
);

// 使用 verbose 模式的 CLI 命令
ming template update --optimize-config --template=my_app --verbose
```

#### 性能监控

```dart
// 监控执行时间
final stopwatch = Stopwatch()..start();
final result = await configManager.getOptimizedConfig(...);
stopwatch.stop();

print('执行时间: ${stopwatch.elapsedMilliseconds}ms');
print('性能指标: ${result.metrics}');
```

## 📈 最佳实践

### 1. 选择合适的策略

- **生产环境**: 使用保守策略，设置较低的影响阈值
- **开发环境**: 使用平衡策略，适度采用新特性
- **实验项目**: 使用激进策略，快速获取最新功能

### 2. 合理设置参数

```dart
// 生产环境推荐设置
const productionOptions = ConfigurationOptions(
  maxCombinations: 20,
  maxImpactThreshold: 0.3,
  includePrerelease: false,
  enableTesting: true,
  concurrency: 4,
  timeoutSeconds: 60,
);

// 开发环境推荐设置
const developmentOptions = ConfigurationOptions(
  maxCombinations: 50,
  maxImpactThreshold: 0.7,
  includePrerelease: false,
  enableTesting: true,
  concurrency: 8,
  timeoutSeconds: 30,
);
```

### 3. 定期维护

```bash
# 定期检查配置兼容性
ming template update --check-config --template=my_app

# 定期优化配置
ming template update --optimize-config --template=my_app

# 监控依赖更新
ming template update --test-config --template=my_app
```

### 4. 版本控制

- 在版本控制中记录配置变更
- 使用分支测试新的配置
- 保留配置变更的详细日志

## 🔗 相关资源

- [README.md](./README.md) - 系统概述和快速开始
- [ARCHITECTURE.md](./ARCHITECTURE.md) - 系统架构和设计原理
- [API.md](./API.md) - 详细的API参考文档

---

**让依赖管理变得简单智能** 🎯
