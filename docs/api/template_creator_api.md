# Template Creator API 文档

## 📋 概述

Template Creator 是 Ming Status CLI 的核心模块，提供企业级模板生成和管理功能。该模块采用模块化架构，支持多种复杂度级别和框架类型。

## 🏗️ 架构概览

```
template_creator/
├── config/                    # 配置管理
├── generators/                # 内容生成器
│   ├── assets/               # 资源生成器
│   ├── config/               # 配置文件生成器
│   ├── dependencies/         # 依赖管理生成器
│   ├── docs/                 # 文档生成器
│   ├── flutter/              # Flutter特定生成器
│   ├── l10n/                 # 国际化生成器
│   ├── templates/            # 模板文件生成器
│   └── tests/                # 测试文件生成器
├── orchestrator/             # 编排器
├── structure/                # 目录结构创建器
├── template_scaffold.dart    # 主要脚手架
└── template_validator.dart   # 模板验证器
```

## 🎯 核心类和接口

### TemplateScaffold

主要的模板生成类，负责协调整个模板创建过程。

```dart
class TemplateScaffold {
  /// 生成模板脚手架
  Future<ScaffoldResult> generateScaffold(ScaffoldConfig config);
  
  /// 生成配置文件
  Future<List<String>> _generateConfigFiles(String templatePath, ScaffoldConfig config);
  
  /// 生成模板文件
  Future<List<String>> _generateTemplateFiles(String templatePath, ScaffoldConfig config);
  
  /// 生成Flutter特定文件
  Future<List<String>> _generateFlutterFiles(String templatePath, ScaffoldConfig config);
  
  /// 生成国际化文件
  Future<List<String>> _generateL10nFiles(String templatePath, ScaffoldConfig config);
}
```

### ScaffoldConfig

模板配置类，定义模板生成的所有参数。

```dart
class ScaffoldConfig {
  final String templateName;           // 模板名称
  final TemplateType templateType;     // 模板类型
  final String author;                 // 作者
  final String description;            // 描述
  final String outputPath;             // 输出路径
  final TemplatePlatform platform;     // 目标平台
  final TemplateFramework framework;   // 技术框架
  final TemplateComplexity complexity; // 复杂度级别
  final bool includeTests;             // 是否包含测试
  final bool includeDocumentation;     // 是否包含文档
  final bool includeExamples;          // 是否包含示例
}
```

## 🔧 复杂度级别详解

### Simple (简单)
- **目标用户**: 初学者
- **生成文件**: ~20个
- **国际化**: 2种语言 (en, zh)
- **配置文件**: 基础配置 (pubspec.yaml, analysis_options.yaml, l10n.yaml, flutter_gen.yaml)
- **状态管理**: 无Provider文件
- **代码生成**: 无build.yaml
- **企业级工具**: 无

### Medium (中等)
- **目标用户**: 有经验的开发者
- **生成文件**: ~26个
- **国际化**: 4种语言 (en, zh, ja, ko)
- **配置文件**: + build.yaml
- **状态管理**: 包含Provider文件 (4个Provider)
- **代码生成**: freezed, json_serializable, riverpod_generator
- **企业级工具**: 无

### Complex (复杂)
- **目标用户**: 高级开发者
- **生成文件**: 32个
- **国际化**: 8种语言 (en, zh, ja, ko, es, fr, de, ru)
- **配置文件**: 完整配置套件
- **状态管理**: 高级Provider (6个Provider + 认证 + API)
- **代码生成**: 完整代码生成套件
- **企业级工具**: 无

### Enterprise (企业级)
- **目标用户**: 架构师和团队
- **生成文件**: 34个
- **国际化**: 8种语言 + 专业本地化
- **配置文件**: + melos.yaml (215行) + shorebird.yaml (219行)
- **状态管理**: 企业级状态管理
- **代码生成**: 企业级代码生成 + 质量检查
- **企业级工具**: melos, shorebird, very_good_analysis, Firebase

## 📦 生成器模块

### 配置文件生成器

#### PubspecGenerator
```dart
class PubspecGenerator extends ConfigGeneratorBase {
  String generateContent(ScaffoldConfig config);
  
  // 复杂度相关方法
  bool _needsNetworking(ScaffoldConfig config);    // Complex/Enterprise
  bool _needsStorage(ScaffoldConfig config);       // Medium+
  bool _needsFirebase(ScaffoldConfig config);      // Enterprise
}
```

#### AnalysisOptionsGenerator
```dart
class AnalysisOptionsGenerator extends ConfigGeneratorBase {
  String generateContent(ScaffoldConfig config);
  
  // 企业级配置
  // - 包含 package:very_good_analysis
  // - Enterprise级别添加 dart_code_metrics
}
```

#### BuildConfigGenerator
```dart
class BuildConfigGenerator extends ConfigGeneratorBase {
  String generateContent(ScaffoldConfig config);
  
  // 仅在 Medium+ 复杂度生成
  // 包含: freezed, json_serializable, riverpod_generator
}
```

#### MelosConfigGenerator
```dart
class MelosConfigGenerator extends ConfigGeneratorBase {
  String generateContent(ScaffoldConfig config);
  
  // 仅在 Enterprise 复杂度生成
  // 215行完整monorepo管理配置
}
```

#### ShorebirdConfigGenerator
```dart
class ShorebirdConfigGenerator extends ConfigGeneratorBase {
  String generateContent(ScaffoldConfig config);
  
  // 仅在 Enterprise 复杂度生成
  // 219行多环境代码推送配置
}
```

### Flutter生成器

#### ProviderGenerator
```dart
class ProviderGenerator extends TemplateGeneratorBase {
  String generateContent(ScaffoldConfig config);
  
  // 复杂度相关生成
  void _generateSimpleProviders(StringBuffer buffer, ScaffoldConfig config);   // 2个Provider
  void _generateMediumProviders(StringBuffer buffer, ScaffoldConfig config);   // 4个Provider
  void _generateComplexProviders(StringBuffer buffer, ScaffoldConfig config);  // 6个Provider + 认证 + API
  
  // 仅在 Medium+ 复杂度生成
}
```

#### RouterGenerator
```dart
class RouterGenerator extends TemplateGeneratorBase {
  String generateContent(ScaffoldConfig config);
  
  // 所有复杂度都生成，但内容复杂度不同
}
```

#### ThemeGenerator
```dart
class ThemeGenerator extends TemplateGeneratorBase {
  String generateContent(ScaffoldConfig config);
  
  // 所有复杂度都生成
}
```

### 国际化生成器

#### ArbGenerator
```dart
class ArbGenerator extends TemplateGeneratorBase {
  String generateContent(ScaffoldConfig config);
  
  // 根据复杂度生成不同数量的语言文件
  // Simple: 2种语言, Medium: 4种语言, Complex/Enterprise: 8种语言
}
```

### 结构创建器

#### FlutterStructureCreator
```dart
class FlutterStructureCreator extends DirectoryCreator {
  List<String> getDirectories(ScaffoldConfig config);
  
  List<String> _getComplexityDirectories(TemplateComplexity complexity);
  
  // Simple: 基础目录
  // Medium: + config, extensions
  // Complex: + middleware, interceptors, validators
  // Enterprise: + 完整企业级目录结构
}
```

## 🔍 验证器

### TemplateValidator
```dart
class TemplateValidator {
  Future<TemplateValidationResult> validateTemplate(String templatePath);
  
  // 验证功能
  Future<List<ValidationIssue>> _validateStructure(String templatePath);
  Future<List<ValidationIssue>> _validateConfigFiles(String templatePath);
  Future<List<ValidationIssue>> _validateDependencies(String templatePath);
}
```

## 🎮 使用示例

### 基础使用
```dart
final config = ScaffoldConfig(
  templateName: 'my_app',
  templateType: TemplateType.basic,
  author: 'Developer',
  description: 'My Flutter App',
  complexity: TemplateComplexity.simple,
);

final scaffold = TemplateScaffold();
final result = await scaffold.generateScaffold(config);
```

### 企业级模板
```dart
final config = ScaffoldConfig(
  templateName: 'enterprise_app',
  templateType: TemplateType.full,
  author: 'Enterprise Team',
  description: 'Enterprise Flutter App',
  complexity: TemplateComplexity.enterprise,
  framework: TemplateFramework.flutter,
  platform: TemplatePlatform.crossPlatform,
);

final scaffold = TemplateScaffold();
final result = await scaffold.generateScaffold(config);
// 生成34个文件，包含melos.yaml, shorebird.yaml等企业级配置
```

## 📊 复杂度对比表

| 功能 | Simple | Medium | Complex | Enterprise |
|------|--------|--------|---------|------------|
| 文件数量 | ~20 | ~26 | 32 | 34 |
| 国际化语言 | 2 | 4 | 8 | 8 |
| build.yaml | ❌ | ✅ | ✅ | ✅ |
| Provider文件 | ❌ | ✅ | ✅ | ✅ |
| melos.yaml | ❌ | ❌ | ❌ | ✅ |
| shorebird.yaml | ❌ | ❌ | ❌ | ✅ |
| Firebase集成 | ❌ | ❌ | ❌ | ✅ |
| 企业级目录 | ❌ | 部分 | 大部分 | 完整 |

## 🚀 扩展指南

### 添加新的生成器
1. 继承相应的基类 (`ConfigGeneratorBase` 或 `TemplateGeneratorBase`)
2. 实现 `generateContent` 方法
3. 在 `TemplateScaffold` 中集成
4. 添加复杂度相关逻辑

### 添加新的复杂度级别
1. 在 `TemplateComplexity` 枚举中添加新级别
2. 更新所有生成器的复杂度判断逻辑
3. 更新结构创建器
4. 添加相应的测试

## � CLI 命令接口

### 基础命令
```bash
# 创建简单模板
ming template create --name=my_app --type=basic --framework=flutter --author="Developer" --description="My App" --complexity=simple

# 创建中等复杂度模板
ming template create --name=medium_app --type=full --framework=flutter --author="Developer" --description="Medium App" --complexity=medium

# 创建复杂模板
ming template create --name=complex_app --type=full --framework=flutter --author="Developer" --description="Complex App" --complexity=complex

# 创建企业级模板
ming template create --name=enterprise_app --type=full --framework=flutter --author="Enterprise Team" --description="Enterprise App" --complexity=enterprise
```

### 向导模式
```bash
# 使用交互式向导
ming template create --wizard
```

### 参数说明
- `--name, -n`: 模板名称 (必需)
- `--type, -t`: 模板类型 (必需)
- `--author, -a`: 作者名称 (必需)
- `--description, -d`: 模板描述 (必需)
- `--complexity, -c`: 复杂度级别 (simple|medium|complex|enterprise)
- `--framework, -f`: 技术框架 (flutter|dart|react|vue|angular|nodejs|springBoot|agnostic)
- `--platform, -p`: 目标平台 (web|mobile|desktop|server|cloud|crossPlatform)
- `--output, -o`: 输出目录 (默认: .)
- `--wizard, -w`: 使用交互式向导
- `--validate, -v`: 生成后验证模板 (默认: true)
- `--strict`: 启用严格验证模式
- `--no-tests`: 不包含测试文件
- `--no-docs`: 不包含文档
- `--no-examples`: 不包含示例
- `--no-git`: 不初始化Git仓库

## 🎨 自定义和扩展

### 自定义生成器

#### 创建自定义配置生成器
```dart
class CustomConfigGenerator extends ConfigGeneratorBase {
  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 根据复杂度生成不同内容
    switch (config.complexity) {
      case TemplateComplexity.simple:
        _generateSimpleConfig(buffer, config);
        break;
      case TemplateComplexity.medium:
        _generateMediumConfig(buffer, config);
        break;
      case TemplateComplexity.complex:
      case TemplateComplexity.enterprise:
        _generateAdvancedConfig(buffer, config);
        break;
    }

    return buffer.toString();
  }

  void _generateSimpleConfig(StringBuffer buffer, ScaffoldConfig config) {
    // 简单配置逻辑
  }

  void _generateMediumConfig(StringBuffer buffer, ScaffoldConfig config) {
    // 中等配置逻辑
  }

  void _generateAdvancedConfig(StringBuffer buffer, ScaffoldConfig config) {
    // 高级配置逻辑
  }
}
```

#### 创建自定义模板生成器
```dart
class CustomTemplateGenerator extends TemplateGeneratorBase {
  @override
  String generateContent(ScaffoldConfig config) {
    return '''
// 自定义模板内容
// 模板名称: ${config.templateName}
// 复杂度: ${config.complexity.name}
// 框架: ${config.framework.name}

${_generateCustomContent(config)}
''';
  }

  String _generateCustomContent(ScaffoldConfig config) {
    // 根据配置生成自定义内容
    if (config.complexity == TemplateComplexity.enterprise) {
      return _generateEnterpriseContent(config);
    }
    return _generateBasicContent(config);
  }
}
```

### 集成自定义生成器

在 `TemplateScaffold` 中集成自定义生成器：

```dart
// 在 _generateConfigFiles 方法中添加
if (shouldGenerateCustomConfig(config)) {
  const customGenerator = CustomConfigGenerator();
  final customContent = customGenerator.generateContent(config);
  await _writeFile(templatePath, 'custom.yaml', customContent);
  generatedFiles.add('custom.yaml');
}
```

## 🧪 测试指南

### 单元测试示例
```dart
import 'package:test/test.dart';
import 'package:ming_status_cli/src/core/template_creator/template_scaffold.dart';

void main() {
  group('TemplateScaffold Tests', () {
    test('should generate simple template correctly', () async {
      final config = ScaffoldConfig(
        templateName: 'test_app',
        templateType: TemplateType.basic,
        author: 'Test Author',
        description: 'Test Description',
        complexity: TemplateComplexity.simple,
      );

      final scaffold = TemplateScaffold();
      final result = await scaffold.generateScaffold(config);

      expect(result.success, isTrue);
      expect(result.generatedFiles.length, greaterThan(15));
      expect(result.generatedFiles, contains('pubspec.yaml'));
      expect(result.generatedFiles, isNot(contains('build.yaml')));
    });

    test('should generate enterprise template with all features', () async {
      final config = ScaffoldConfig(
        templateName: 'enterprise_app',
        templateType: TemplateType.full,
        author: 'Enterprise Team',
        description: 'Enterprise Application',
        complexity: TemplateComplexity.enterprise,
        framework: TemplateFramework.flutter,
      );

      final scaffold = TemplateScaffold();
      final result = await scaffold.generateScaffold(config);

      expect(result.success, isTrue);
      expect(result.generatedFiles.length, greaterThan(30));
      expect(result.generatedFiles, contains('melos.yaml'));
      expect(result.generatedFiles, contains('shorebird.yaml'));
      expect(result.generatedFiles, contains('build.yaml'));
    });
  });
}
```

### 集成测试示例
```dart
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Template Creator Integration Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('template_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should create valid Flutter project structure', () async {
      final config = ScaffoldConfig(
        templateName: 'integration_test_app',
        templateType: TemplateType.full,
        author: 'Integration Test',
        description: 'Integration Test App',
        outputPath: tempDir.path,
        complexity: TemplateComplexity.complex,
        framework: TemplateFramework.flutter,
      );

      final scaffold = TemplateScaffold();
      final result = await scaffold.generateScaffold(config);

      expect(result.success, isTrue);

      // 验证关键文件存在
      final projectPath = '${tempDir.path}/integration_test_app';
      expect(await File('$projectPath/pubspec.yaml').exists(), isTrue);
      expect(await File('$projectPath/build.yaml').exists(), isTrue);
      expect(await Directory('$projectPath/lib').exists(), isTrue);
      expect(await Directory('$projectPath/test').exists(), isTrue);
    });
  });
}
```

## 🔍 故障排除

### 常见问题

#### 1. 模板生成失败
**问题**: 模板生成过程中出现错误
**解决方案**:
- 检查输出目录权限
- 确认模板名称不包含特殊字符
- 验证所有必需参数是否提供

#### 2. 企业级功能缺失
**问题**: Enterprise复杂度没有生成melos.yaml或shorebird.yaml
**解决方案**:
- 确认使用了 `--complexity=enterprise` 参数
- 检查框架是否设置为Flutter
- 验证模板类型是否为full

#### 3. 国际化文件数量不正确
**问题**: 生成的ARB文件数量与预期不符
**解决方案**:
- 检查复杂度设置
- 确认 `_getSupportedLanguages` 方法的逻辑
- 验证国际化生成器的配置

### 调试技巧

#### 启用详细日志
```dart
// 在生成过程中添加调试信息
Logger.debug('Generating template with complexity: ${config.complexity.name}');
Logger.debug('Framework: ${config.framework.name}');
Logger.debug('Generated files: ${result.generatedFiles.length}');
```

#### 验证生成结果
```dart
// 使用验证器检查生成的模板
final validator = TemplateValidator();
final validationResult = await validator.validateTemplate(templatePath);

if (validationResult.hasErrors) {
  for (final error in validationResult.errors) {
    Logger.error('Validation error: ${error.message}');
  }
}
```

## 📈 性能优化

### 生成器性能
- 使用 `StringBuffer` 而不是字符串连接
- 避免在循环中进行文件I/O操作
- 缓存重复计算的结果

### 文件I/O优化
- 批量写入文件
- 使用异步操作
- 避免不必要的文件读取

### 内存管理
- 及时释放大型字符串缓冲区
- 避免在内存中保存完整的文件内容
- 使用流式处理处理大型模板

## �📚 相关文档

- [模板系统类型定义](../template_system/template_types.md)
- [配置向导使用指南](../guides/configuration_wizard.md)
- [模板验证规则](../validation/template_validation.md)
- [企业级功能详解](../enterprise/enterprise_features.md)
- [生成器开发指南](../development/generator_development.md)
- [测试最佳实践](../testing/testing_best_practices.md)
