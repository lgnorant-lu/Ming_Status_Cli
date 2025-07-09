# Ming Status CLI API 文档

## 目录

1. [概述](#概述)
2. [核心架构](#核心架构)
3. [公共API](#公共api)
4. [服务接口](#服务接口)
5. [数据模型](#数据模型)
6. [扩展接口](#扩展接口)
7. [错误处理](#错误处理)
8. [示例代码](#示例代码)

## 概述

Ming Status CLI 提供了一套完整的 API 接口，支持：
- 编程式访问所有CLI功能
- 自定义扩展和插件开发
- 第三方工具集成
- 自动化脚本编写

### API 版本
- **当前版本**: 1.0.0
- **兼容性**: 向后兼容
- **稳定性**: 稳定版本

### 导入方式
```dart
// 核心API
import 'package:ming_status_cli/ming_status_cli.dart';

// 特定服务
import 'package:ming_status_cli/src/core/services/template_service.dart';
import 'package:ming_status_cli/src/core/services/validator_service.dart';
import 'package:ming_status_cli/src/core/services/config_service.dart';
```

## 核心架构

### 主要组件

```dart
// 应用程序入口
class CliApp {
  /// 运行CLI应用程序
  Future<int> run(List<String> arguments);
  
  /// 注册自定义命令
  void registerCommand(Command command);
  
  /// 设置全局配置
  void setGlobalConfig(Map<String, dynamic> config);
}

// 服务管理器
class ServiceManager {
  /// 获取服务实例
  T getService<T>();
  
  /// 注册服务
  void registerService<T>(T service);
  
  /// 初始化所有服务
  Future<void> initialize();
}

// 配置管理
class ConfigService {
  /// 获取配置值
  T? get<T>(String key);
  
  /// 设置配置值
  Future<void> set(String key, dynamic value);
  
  /// 加载配置文件
  Future<void> loadConfig(String path);
}
```

## 公共API

### 工作空间管理

#### WorkspaceService
```dart
class WorkspaceService {
  /// 初始化工作空间
  Future<WorkspaceResult> initializeWorkspace({
    required String path,
    required String name,
    String? description,
    String? author,
    String? template,
  });
  
  /// 获取工作空间信息
  Future<Workspace?> getWorkspace(String path);
  
  /// 验证工作空间
  Future<ValidationResult> validateWorkspace(String path);
  
  /// 列出所有模块
  Future<List<Module>> listModules(String workspacePath);
}

// 使用示例
final workspaceService = ServiceManager.instance.getService<WorkspaceService>();

final result = await workspaceService.initializeWorkspace(
  path: '/path/to/workspace',
  name: 'My Project',
  description: 'A sample project',
  author: 'John Doe',
);

if (result.isSuccess) {
  print('Workspace created successfully');
} else {
  print('Error: ${result.error}');
}
```

#### 工作空间配置
```dart
class WorkspaceConfig {
  final String name;
  final String? description;
  final String? author;
  final String version;
  final Map<String, dynamic> metadata;
  
  /// 从YAML文件加载
  static Future<WorkspaceConfig> fromFile(String path);
  
  /// 保存到YAML文件
  Future<void> saveToFile(String path);
  
  /// 验证配置
  ValidationResult validate();
}
```

### 模块管理

#### ModuleService
```dart
class ModuleService {
  /// 创建模块
  Future<ModuleResult> createModule({
    required String name,
    required String outputPath,
    String template = 'basic',
    Map<String, dynamic> variables = const {},
    bool overwrite = false,
  });
  
  /// 获取模块信息
  Future<Module?> getModule(String path);
  
  /// 验证模块
  Future<ValidationResult> validateModule(String path);
  
  /// 删除模块
  Future<bool> deleteModule(String path);
}

// 使用示例
final moduleService = ServiceManager.instance.getService<ModuleService>();

final result = await moduleService.createModule(
  name: 'user_auth',
  outputPath: '/workspace/modules',
  template: 'flutter_feature',
  variables: {
    'feature_name': 'User Authentication',
    'use_bloc': true,
    'use_dio': true,
  },
);
```

#### 模块配置
```dart
class ModuleConfig {
  final String name;
  final String version;
  final String? description;
  final List<String> dependencies;
  final Map<String, dynamic> metadata;
  
  /// 从pubspec.yaml加载
  static Future<ModuleConfig> fromPubspec(String path);
  
  /// 更新依赖
  Future<void> updateDependencies(List<String> newDeps);
}
```

### 模板管理

#### TemplateService
```dart
class TemplateService {
  /// 获取可用模板列表
  Future<List<Template>> getAvailableTemplates();
  
  /// 获取模板信息
  Future<Template?> getTemplate(String name);
  
  /// 渲染模板
  Future<TemplateResult> renderTemplate({
    required String templateName,
    required String outputPath,
    required Map<String, dynamic> variables,
    bool overwrite = false,
  });
  
  /// 安装模板
  Future<bool> installTemplate(String source);
  
  /// 卸载模板
  Future<bool> uninstallTemplate(String name);
}

// 使用示例
final templateService = ServiceManager.instance.getService<TemplateService>();

// 获取模板列表
final templates = await templateService.getAvailableTemplates();
for (final template in templates) {
  print('${template.name}: ${template.description}');
}

// 渲染模板
final result = await templateService.renderTemplate(
  templateName: 'flutter_app',
  outputPath: '/output/my_app',
  variables: {
    'app_name': 'My Flutter App',
    'package_name': 'com.example.myapp',
    'author': 'John Doe',
  },
);
```

#### 模板定义
```dart
class Template {
  final String name;
  final String description;
  final String version;
  final String author;
  final List<TemplateVariable> variables;
  final List<TemplateFile> files;
  final TemplateHooks? hooks;
  
  /// 验证模板
  ValidationResult validate();
  
  /// 获取必需变量
  List<TemplateVariable> getRequiredVariables();
}

class TemplateVariable {
  final String name;
  final String type;
  final String? description;
  final dynamic defaultValue;
  final bool required;
  final String? pattern;
  
  /// 验证变量值
  bool validateValue(dynamic value);
}
```

### 验证系统

#### ValidatorService
```dart
class ValidatorService {
  /// 验证工作空间
  Future<ValidationResult> validateWorkspace(String path, {
    ValidationLevel level = ValidationLevel.error,
    bool autoFix = false,
  });
  
  /// 验证模块
  Future<ValidationResult> validateModule(String path, {
    ValidationLevel level = ValidationLevel.error,
    bool autoFix = false,
  });
  
  /// 注册自定义验证器
  void registerValidator(Validator validator);
  
  /// 获取验证报告
  Future<ValidationReport> generateReport(String path);
}

// 使用示例
final validatorService = ServiceManager.instance.getService<ValidatorService>();

final result = await validatorService.validateWorkspace(
  '/path/to/workspace',
  level: ValidationLevel.warning,
  autoFix: true,
);

print('Validation result: ${result.isValid}');
for (final message in result.messages) {
  print('${message.level}: ${message.message}');
}
```

#### 验证结果
```dart
class ValidationResult {
  final bool isValid;
  final List<ValidationMessage> messages;
  final Duration duration;
  
  /// 获取错误消息
  List<ValidationMessage> get errors;
  
  /// 获取警告消息
  List<ValidationMessage> get warnings;
  
  /// 获取信息消息
  List<ValidationMessage> get infos;
}

class ValidationMessage {
  final ValidationLevel level;
  final String message;
  final String? file;
  final int? line;
  final String? suggestion;
}

enum ValidationLevel { error, warning, info }
```

## 服务接口

### 配置服务

#### ConfigService
```dart
class ConfigService {
  /// 获取配置值
  T? get<T>(String key, {T? defaultValue});
  
  /// 设置配置值
  Future<void> set(String key, dynamic value);
  
  /// 删除配置
  Future<void> unset(String key);
  
  /// 重置配置
  Future<void> reset();
  
  /// 导出配置
  Map<String, dynamic> export();
  
  /// 导入配置
  Future<void> import(Map<String, dynamic> config);
}

// 使用示例
final configService = ServiceManager.instance.getService<ConfigService>();

// 设置用户信息
await configService.set('user.name', 'John Doe');
await configService.set('user.email', 'john@example.com');

// 获取配置
final userName = configService.get<String>('user.name');
final enableColors = configService.get<bool>('ui.colors', defaultValue: true);
```

### 日志服务

#### LoggingService
```dart
class LoggingService {
  /// 记录调试信息
  void debug(String message, {String? tag, Map<String, dynamic>? data});
  
  /// 记录信息
  void info(String message, {String? tag, Map<String, dynamic>? data});
  
  /// 记录警告
  void warning(String message, {String? tag, Map<String, dynamic>? data});
  
  /// 记录错误
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace});
  
  /// 设置日志级别
  void setLevel(LogLevel level);
  
  /// 添加日志输出器
  void addOutput(LogOutput output);
}

// 使用示例
final logger = ServiceManager.instance.getService<LoggingService>();

logger.info('Starting module creation', tag: 'ModuleService');
logger.debug('Template variables', data: {'name': 'my_module', 'author': 'John'});
logger.error('Failed to create module', error: exception, stackTrace: stackTrace);
```

### 缓存服务

#### CacheService
```dart
class CacheService {
  /// 获取缓存值
  Future<T?> get<T>(String key);
  
  /// 设置缓存值
  Future<void> set<T>(String key, T value, {Duration? ttl});
  
  /// 删除缓存
  Future<void> delete(String key);
  
  /// 清空缓存
  Future<void> clear();
  
  /// 检查缓存是否存在
  Future<bool> exists(String key);
}
```

## 数据模型

### 核心模型

#### Workspace
```dart
class Workspace {
  final String path;
  final String name;
  final String? description;
  final String? author;
  final String version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Module> modules;
  
  /// 添加模块
  Future<void> addModule(Module module);
  
  /// 移除模块
  Future<void> removeModule(String moduleName);
  
  /// 获取模块
  Module? getModule(String name);
}
```

#### Module
```dart
class Module {
  final String name;
  final String path;
  final String? description;
  final String version;
  final List<String> dependencies;
  final Map<String, dynamic> metadata;
  
  /// 更新版本
  Future<void> updateVersion(String newVersion);
  
  /// 添加依赖
  Future<void> addDependency(String dependency);
  
  /// 移除依赖
  Future<void> removeDependency(String dependency);
}
```

#### GenerationResult
```dart
class GenerationResult {
  final bool isSuccess;
  final String? error;
  final List<String> generatedFiles;
  final Duration duration;
  final Map<String, dynamic> metadata;
  
  /// 获取生成的文件数量
  int get fileCount => generatedFiles.length;
  
  /// 检查是否有错误
  bool get hasError => error != null;
}
```

## 扩展接口

### 自定义命令

#### Command接口
```dart
abstract class Command {
  String get name;
  String get description;
  ArgParser get argParser;
  
  Future<int> run();
}

// 实现自定义命令
class MyCustomCommand extends Command {
  @override
  String get name => 'my-command';
  
  @override
  String get description => 'My custom command';
  
  @override
  ArgParser get argParser => ArgParser()
    ..addOption('input', abbr: 'i', help: 'Input file');
  
  @override
  Future<int> run() async {
    final input = argResults?['input'];
    // 实现命令逻辑
    return 0;
  }
}

// 注册命令
final app = CliApp();
app.registerCommand(MyCustomCommand());
```

### 自定义验证器

#### Validator接口
```dart
abstract class Validator {
  String get name;
  String get description;
  ValidationLevel get level;
  
  Future<List<ValidationMessage>> validate(String path);
  Future<bool> canFix(ValidationMessage message);
  Future<bool> fix(ValidationMessage message);
}

// 实现自定义验证器
class MyValidator extends Validator {
  @override
  String get name => 'my-validator';
  
  @override
  String get description => 'My custom validator';
  
  @override
  ValidationLevel get level => ValidationLevel.warning;
  
  @override
  Future<List<ValidationMessage>> validate(String path) async {
    final messages = <ValidationMessage>[];
    // 实现验证逻辑
    return messages;
  }
  
  @override
  Future<bool> canFix(ValidationMessage message) async {
    // 检查是否可以自动修复
    return true;
  }
  
  @override
  Future<bool> fix(ValidationMessage message) async {
    // 实现自动修复逻辑
    return true;
  }
}

// 注册验证器
final validatorService = ServiceManager.instance.getService<ValidatorService>();
validatorService.registerValidator(MyValidator());
```

### 模板钩子

#### TemplateHook接口
```dart
abstract class TemplateHook {
  String get name;
  
  Future<void> preGenerate(TemplateContext context);
  Future<void> postGenerate(TemplateContext context);
}

class TemplateContext {
  final String templateName;
  final String outputPath;
  final Map<String, dynamic> variables;
  final List<String> generatedFiles;
  
  /// 添加变量
  void addVariable(String key, dynamic value);
  
  /// 获取变量
  T? getVariable<T>(String key);
}
```

## 错误处理

### 异常类型

```dart
// 基础异常
abstract class MingCliException implements Exception {
  String get message;
  String? get context;
  Object? get cause;
}

// 配置异常
class ConfigException extends MingCliException {
  final String message;
  final String? context;
  final Object? cause;
  
  ConfigException(this.message, {this.context, this.cause});
}

// 模板异常
class TemplateException extends MingCliException {
  final String templateName;
  final String message;
  final String? context;
  
  TemplateException(this.templateName, this.message, {this.context});
}

// 验证异常
class ValidationException extends MingCliException {
  final String path;
  final String message;
  final ValidationLevel level;
  
  ValidationException(this.path, this.message, this.level);
}
```

### 错误处理最佳实践

```dart
// 使用 Result 模式
class Result<T> {
  final T? data;
  final String? error;
  
  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
  
  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

// 服务方法示例
Future<Result<Module>> createModule(String name) async {
  try {
    final module = await _doCreateModule(name);
    return Result.success(module);
  } on TemplateException catch (e) {
    return Result.failure('Template error: ${e.message}');
  } on FileSystemException catch (e) {
    return Result.failure('File system error: ${e.message}');
  } catch (e) {
    return Result.failure('Unexpected error: $e');
  }
}
```

## 示例代码

### 完整的工作流示例

```dart
import 'package:ming_status_cli/ming_status_cli.dart';

Future<void> main() async {
  // 初始化服务管理器
  final serviceManager = ServiceManager.instance;
  await serviceManager.initialize();
  
  // 获取服务
  final workspaceService = serviceManager.getService<WorkspaceService>();
  final moduleService = serviceManager.getService<ModuleService>();
  final validatorService = serviceManager.getService<ValidatorService>();
  
  try {
    // 1. 创建工作空间
    print('Creating workspace...');
    final workspaceResult = await workspaceService.initializeWorkspace(
      path: '/tmp/my_project',
      name: 'My Project',
      description: 'A sample project created via API',
      author: 'API User',
    );
    
    if (!workspaceResult.isSuccess) {
      throw Exception('Failed to create workspace: ${workspaceResult.error}');
    }
    
    // 2. 创建模块
    print('Creating modules...');
    final modules = ['core', 'auth', 'ui'];
    
    for (final moduleName in modules) {
      final moduleResult = await moduleService.createModule(
        name: moduleName,
        outputPath: '/tmp/my_project/modules',
        template: 'dart_package',
        variables: {
          'package_name': 'my_project_$moduleName',
          'description': 'The $moduleName module',
          'author': 'API User',
        },
      );
      
      if (moduleResult.isSuccess) {
        print('✓ Created module: $moduleName');
      } else {
        print('✗ Failed to create module $moduleName: ${moduleResult.error}');
      }
    }
    
    // 3. 验证项目
    print('Validating project...');
    final validationResult = await validatorService.validateWorkspace(
      '/tmp/my_project',
      level: ValidationLevel.warning,
      autoFix: true,
    );
    
    if (validationResult.isValid) {
      print('✓ Project validation passed');
    } else {
      print('⚠ Project validation found issues:');
      for (final message in validationResult.messages) {
        print('  ${message.level}: ${message.message}');
      }
    }
    
    print('Project created successfully!');
    
  } catch (e) {
    print('Error: $e');
  }
}
```

### 自定义扩展示例

```dart
// 自定义命令
class AnalyzeCommand extends Command {
  @override
  String get name => 'analyze';
  
  @override
  String get description => 'Analyze project structure';
  
  @override
  ArgParser get argParser => ArgParser()
    ..addFlag('detailed', abbr: 'd', help: 'Show detailed analysis')
    ..addOption('output', abbr: 'o', help: 'Output file');
  
  @override
  Future<int> run() async {
    final detailed = argResults?['detailed'] ?? false;
    final output = argResults?['output'];
    
    // 实现分析逻辑
    final analyzer = ProjectAnalyzer();
    final result = await analyzer.analyze('.', detailed: detailed);
    
    if (output != null) {
      await File(output).writeAsString(result.toJson());
    } else {
      print(result.summary);
    }
    
    return 0;
  }
}

// 注册并使用
final app = CliApp();
app.registerCommand(AnalyzeCommand());
await app.run(['analyze', '--detailed']);
```

---

*API文档版本: 1.0.0 | 最后更新: 2025-07-08*
