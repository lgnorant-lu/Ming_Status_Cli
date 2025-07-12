# 配置管理系统 API 文档

## 📚 API 概览

配置管理系统提供了丰富的 API 接口，支持配置优化、兼容性检查、版本解析、测试执行等核心功能。

## 🔧 核心 API

### ConfigurationManager

主要的配置管理接口，提供高级配置管理功能。

#### getOptimizedConfig

获取优化的配置建议。

```dart
Future<ConfigurationResult> getOptimizedConfig({
  ConfigurationSet? currentConfig,
  List<String>? packageNames,
  ConfigurationStrategy strategy = ConfigurationStrategy.balanced,
  Map<String, dynamic>? constraints,
})
```

**参数**:
- `currentConfig`: 当前配置（可选）
- `packageNames`: 要优化的包名列表（可选）
- `strategy`: 优化策略，默认为平衡策略
- `constraints`: 额外约束条件（可选）

**返回**: `ConfigurationResult` - 包含推荐配置和详细分析结果

**示例**:
```dart
final result = await configManager.getOptimizedConfig(
  packageNames: ['http', 'dio', 'json_annotation'],
  strategy: ConfigurationStrategy.balanced,
);

print('推荐配置: ${result.recommendedConfig.name}');
print('成功率: ${(result.successRate * 100).toStringAsFixed(1)}%');
```

#### checkConfigurationCompatibility

检查配置的兼容性。

```dart
Future<bool> checkConfigurationCompatibility(ConfigurationSet config)
```

**参数**:
- `config`: 要检查的配置集合

**返回**: `bool` - 是否兼容

**示例**:
```dart
final isCompatible = await configManager.checkConfigurationCompatibility(myConfig);
if (!isCompatible) {
  final issues = await configManager.getCompatibilityIssues(myConfig);
  print('兼容性问题: ${issues.join(', ')}');
}
```

#### predictConfigurationSuccess

预测配置的成功率。

```dart
Future<double> predictConfigurationSuccess(ConfigurationSet config)
```

**参数**:
- `config`: 要预测的配置集合

**返回**: `double` - 成功率 (0.0-1.0)

**示例**:
```dart
final successRate = await configManager.predictConfigurationSuccess(config);
print('预测成功率: ${(successRate * 100).toStringAsFixed(1)}%');
```

### ConfigurationOptions

配置管理器的选项设置。

```dart
class ConfigurationOptions {
  const ConfigurationOptions({
    this.maxCombinations = 50,
    this.maxImpactThreshold = 0.7,
    this.includePrerelease = false,
    this.enableTesting = true,
    this.concurrency = 4,
    this.timeoutSeconds = 30,
    this.enableCache = true,
  });
}
```

**字段说明**:
- `maxCombinations`: 最大测试组合数
- `maxImpactThreshold`: 最大影响阈值 (0.0-1.0)
- `includePrerelease`: 是否包含预发布版本
- `enableTesting`: 是否执行配置测试
- `concurrency`: 并发执行数
- `timeoutSeconds`: 操作超时时间（秒）
- `enableCache`: 是否启用缓存

### ConfigurationStrategy

配置优化策略枚举。

```dart
enum ConfigurationStrategy {
  conservative,  // 保守策略 - 优先稳定性
  balanced,      // 平衡策略 - 稳定性与新特性平衡
  aggressive,    // 激进策略 - 优先新特性
  automatic,     // 自动策略 - 基于ML自动选择
}
```

## 📊 数据模型

### ConfigurationSet

配置集合，表示一组依赖配置。

```dart
class ConfigurationSet {
  const ConfigurationSet({
    required this.id,
    required this.name,
    this.description = '',
    required this.essentialDependencies,
    this.optionalDependencies = const {},
    this.devDependencies = const {},
    required this.createdAt,
    this.priority = 0.5,
    this.complexity = 5,
  });
  
  // 核心属性
  final String id;
  final String name;
  final String description;
  final Map<String, VersionInfo> essentialDependencies;
  final Map<String, VersionInfo> optionalDependencies;
  final Map<String, VersionInfo> devDependencies;
  final DateTime createdAt;
  final double priority;
  final int complexity;
  
  // 计算方法
  double calculateStabilityScore();
  double calculateFreshnessScore();
  Map<String, VersionInfo> get allDependencies;
}
```

### ConfigurationResult

配置优化结果。

```dart
class ConfigurationResult {
  const ConfigurationResult({
    required this.recommendedConfig,
    required this.candidateConfigs,
    required this.testResults,
    this.incrementalResult,
    required this.executionTime,
    this.metrics = const {},
  });
  
  final ConfigurationSet recommendedConfig;
  final List<ConfigurationSet> candidateConfigs;
  final List<TestResult> testResults;
  final IncrementalUpdateResult? incrementalResult;
  final Duration executionTime;
  final Map<String, dynamic> metrics;
  
  // 计算属性
  double get successRate;
  ConfigurationSet get bestConfig;
}
```

### VersionInfo

版本信息模型。

```dart
class VersionInfo {
  const VersionInfo({
    required this.packageName,
    required this.version,
    required this.publishedAt,
    this.description,
    this.homepage,
    this.repositoryUrl,
    this.license,
    this.downloadCount,
    this.dependencies,
    this.devDependencies,
  });
  
  final String packageName;
  final Version version;
  final DateTime publishedAt;
  final String? description;
  final String? homepage;
  final String? repositoryUrl;
  final String? license;
  final int? downloadCount;
  final Map<String, VersionConstraint>? dependencies;
  final Map<String, VersionConstraint>? devDependencies;
  
  // 计算方法
  bool get isPrerelease;
  bool get isStable;
  int get daysSincePublished;
  double calculateStabilityScore();
}
```

### TestResult

测试结果模型。

```dart
class TestResult {
  const TestResult({
    required this.testId,
    required this.configurationSet,
    required this.isSuccess,
    required this.startTime,
    required this.endTime,
    this.errorMessage,
    this.errorType,
    this.logs = const [],
    this.metrics = const {},
  });
  
  final String testId;
  final ConfigurationSet configurationSet;
  final bool isSuccess;
  final DateTime startTime;
  final DateTime endTime;
  final String? errorMessage;
  final TestErrorType? errorType;
  final List<String> logs;
  final Map<String, dynamic> metrics;
  
  // 计算属性
  Duration get duration;
  
  // 工厂方法
  factory TestResult.success({...});
  factory TestResult.failure({...});
}
```

## 🔄 增量更新 API

### IncrementalUpdater

增量更新管理器。

#### performIncrementalUpdate

执行增量更新。

```dart
Future<IncrementalUpdateResult> performIncrementalUpdate({
  required ConfigurationSet currentConfig,
  required Map<String, VersionInfo> availableVersions,
  double maxImpactThreshold = 0.7,
  bool testChanges = true,
})
```

**参数**:
- `currentConfig`: 当前配置
- `availableVersions`: 可用版本信息
- `maxImpactThreshold`: 最大影响阈值
- `testChanges`: 是否测试变更

**返回**: `IncrementalUpdateResult` - 增量更新结果

#### getUpdateSuggestions

获取更新建议。

```dart
Future<List<DependencyChange>> getUpdateSuggestions({
  required ConfigurationSet currentConfig,
  required Map<String, VersionInfo> availableVersions,
  double maxImpactThreshold = 0.7,
})
```

### DependencyChange

依赖变更模型。

```dart
class DependencyChange {
  const DependencyChange({
    required this.packageName,
    required this.changeType,
    this.oldVersion,
    this.newVersion,
    required this.layer,
    this.reason = '',
  });
  
  final String packageName;
  final ChangeType changeType;
  final VersionInfo? oldVersion;
  final VersionInfo? newVersion;
  final DependencyLayer layer;
  final String reason;
  
  // 计算属性
  double get impactScore;
  String get description;
}
```

## 🧪 测试 API

### ParallelTester

并行测试器。

#### testInParallel

并行测试多个配置。

```dart
Future<List<TestResult>> testInParallel(
  List<ConfigurationSet> configurations, {
  Map<String, dynamic> options = const {},
})
```

### ConfigurationTester

配置测试器。

#### testConfiguration

测试单个配置。

```dart
Future<TestResult> testConfiguration(
  ConfigurationSet config, {
  Map<String, dynamic> options = const {},
})
```

## 🔍 版本解析 API

### IntelligentVersionResolver

智能版本解析器。

#### getLatestVersions

获取最新版本信息。

```dart
Future<Map<String, VersionInfo>> getLatestVersions({
  List<String>? packageNames,
  bool includePrerelease = false,
})
```

#### generateTestConfigurations

生成测试配置。

```dart
Future<List<ConfigurationSet>> generateTestConfigurations({
  required Map<String, VersionInfo> versions,
  TestStrategy strategy = TestStrategy.balanced,
  int maxCombinations = 50,
})
```

## 🛡️ 兼容性 API

### CompatibilityMatrix

兼容性矩阵。

#### isCompatible

检查配置兼容性。

```dart
bool isCompatible(ConfigurationSet config)
```

#### getCompatibilityIssues

获取兼容性问题。

```dart
List<String> getCompatibilityIssues(ConfigurationSet config)
```

## 🤖 机器学习 API

### ConfigurationSuccessPredictor

配置成功率预测器。

#### predictSuccessRate

预测配置成功率。

```dart
double predictSuccessRate(ConfigurationSet config)
```

#### train

训练模型。

```dart
Future<void> train(List<TrainingData> data)
```

## 🚨 错误处理

### ConfigurationException

配置管理异常基类。

```dart
class ConfigurationException implements Exception {
  const ConfigurationException(this.message, [this.cause]);
  
  final String message;
  final dynamic cause;
}
```

### 具体异常类型

```dart
class VersionNotFoundException extends ConfigurationException
class CompatibilityException extends ConfigurationException
class TestTimeoutException extends ConfigurationException
class NetworkException extends ConfigurationException
```

## 📝 使用示例

### 完整的配置优化流程

```dart
import 'package:ming_status_cli/src/core/configuration_management/index.dart';

Future<void> optimizeProjectConfiguration() async {
  // 1. 创建配置管理器
  final configManager = ConfigurationManager(
    options: const ConfigurationOptions(
      maxCombinations: 20,
      enableTesting: true,
      concurrency: 4,
    ),
  );
  
  try {
    // 2. 获取优化配置
    final result = await configManager.getOptimizedConfig(
      packageNames: ['http', 'dio', 'json_annotation', 'json_serializable'],
      strategy: ConfigurationStrategy.balanced,
    );
    
    // 3. 分析结果
    print('🎯 推荐配置: ${result.recommendedConfig.name}');
    print('📊 候选配置: ${result.candidateConfigs.length} 个');
    print('✅ 成功率: ${(result.successRate * 100).toStringAsFixed(1)}%');
    print('⏱️ 执行时间: ${result.executionTime.inMilliseconds}ms');
    
    // 4. 检查兼容性
    final isCompatible = await configManager.checkConfigurationCompatibility(
      result.recommendedConfig,
    );
    
    if (!isCompatible) {
      final issues = await configManager.getCompatibilityIssues(
        result.recommendedConfig,
      );
      print('⚠️ 兼容性问题: ${issues.join(', ')}');
    }
    
    // 5. 预测成功率
    final successRate = await configManager.predictConfigurationSuccess(
      result.recommendedConfig,
    );
    print('🔮 ML预测成功率: ${(successRate * 100).toStringAsFixed(1)}%');
    
  } catch (e) {
    print('❌ 配置优化失败: $e');
  } finally {
    // 6. 清理资源
    configManager.dispose();
  }
}
```

---

**API 设计原则**: 简单易用、类型安全、高性能、可扩展 🎯
