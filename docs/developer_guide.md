# Ming Status CLI 开发者指南

## 目录

1. [开发环境设置](#开发环境设置)
2. [项目结构](#项目结构)
3. [开发工作流](#开发工作流)
4. [代码规范](#代码规范)
5. [测试指南](#测试指南)
6. [调试技巧](#调试技巧)
7. [性能优化](#性能优化)
8. [发布流程](#发布流程)

## 开发环境设置

### 系统要求

- **Dart SDK**: 3.2.0 或更高版本
- **Git**: 2.30 或更高版本
- **IDE**: VS Code 或 IntelliJ IDEA
- **操作系统**: Windows 10+, macOS 10.14+, Linux (Ubuntu 18.04+)

### 环境配置

#### 1. 克隆项目
```bash
git clone https://github.com/your-org/ming_status_cli.git
cd ming_status_cli
```

#### 2. 安装依赖
```bash
# 安装 Dart 依赖
dart pub get

# 安装开发工具
dart pub global activate coverage
dart pub global activate dart_code_metrics
dart pub global activate pana
```

#### 3. 配置IDE

**VS Code 配置** (`.vscode/settings.json`):
```json
{
  "dart.flutterSdkPath": null,
  "dart.lineLength": 80,
  "dart.insertArgumentPlaceholders": false,
  "dart.enableSdkFormatter": true,
  "dart.runPubGetOnPubspecChanges": true,
  "files.associations": {
    "*.yaml": "yaml",
    "*.yml": "yaml"
  },
  "editor.rulers": [80],
  "editor.formatOnSave": true
}
```

**启动配置** (`.vscode/launch.json`):
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Ming CLI",
      "request": "launch",
      "type": "dart",
      "program": "bin/ming_status_cli.dart",
      "args": ["--help"],
      "console": "terminal"
    },
    {
      "name": "Ming CLI Debug",
      "request": "launch",
      "type": "dart",
      "program": "bin/ming_status_cli.dart",
      "args": ["init", "test_project"],
      "console": "terminal",
      "env": {
        "MING_DEBUG": "true"
      }
    }
  ]
}
```

#### 4. 验证环境
```bash
# 检查 Dart 版本
dart --version

# 运行测试
dart test

# 运行 CLI
dart run bin/ming_status_cli.dart --help
```

## 项目结构

### 目录结构
```
ming_status_cli/
├── bin/                          # 可执行文件
│   └── ming_status_cli.dart      # 主入口点
├── lib/                          # 核心库代码
│   ├── ming_status_cli.dart      # 公共API导出
│   └── src/                      # 内部实现
│       ├── cli_app.dart          # CLI应用程序
│       ├── commands/             # 命令实现
│       ├── core/                 # 核心服务和管理器
│       ├── models/               # 数据模型
│       ├── services/             # 业务服务
│       └── utils/                # 工具类
├── test/                         # 测试代码
│   ├── unit/                     # 单元测试
│   ├── integration/              # 集成测试
│   └── performance/              # 性能测试
├── docs/                         # 文档
├── templates/                    # 内置模板
├── scripts/                      # 构建和部署脚本
├── .github/                      # GitHub Actions
├── analysis_options.yaml        # 代码分析配置
├── pubspec.yaml                  # 包配置
└── README.md                     # 项目说明
```

### 核心模块

#### 1. CLI应用程序 (`lib/src/cli_app.dart`)
```dart
/// 主应用程序类，负责：
/// - 命令行参数解析
/// - 命令注册和路由
/// - 全局错误处理
/// - 服务初始化
class CliApp {
  final CommandRunner _runner;
  final ServiceManager _serviceManager;
  
  Future<int> run(List<String> arguments);
  void registerCommand(Command command);
}
```

#### 2. 服务管理器 (`lib/src/core/service_manager.dart`)
```dart
/// 服务容器，管理所有业务服务：
/// - 依赖注入
/// - 服务生命周期
/// - 服务发现
class ServiceManager {
  static ServiceManager get instance;
  
  T getService<T>();
  void registerService<T>(T service);
  Future<void> initialize();
}
```

#### 3. 命令系统 (`lib/src/commands/`)
```dart
/// 基础命令类
abstract class BaseCommand extends Command {
  ServiceManager get serviceManager;
  Logger get logger;
  
  @override
  Future<int> run();
}

/// 具体命令实现
class InitCommand extends BaseCommand { ... }
class CreateCommand extends BaseCommand { ... }
class ValidateCommand extends BaseCommand { ... }
```

## 开发工作流

### Git 工作流

#### 1. 分支策略
```bash
# 主分支
main                    # 稳定版本
develop                 # 开发分支

# 功能分支
feature/feature-name    # 新功能开发
bugfix/bug-description  # 错误修复
hotfix/critical-fix     # 紧急修复
release/v1.0.0         # 发布准备
```

#### 2. 开发流程
```bash
# 1. 创建功能分支
git checkout develop
git pull origin develop
git checkout -b feature/new-feature

# 2. 开发和提交
git add .
git commit -m "feat: add new feature"

# 3. 推送和创建PR
git push origin feature/new-feature
# 在GitHub上创建Pull Request

# 4. 代码审查和合并
# 审查通过后合并到develop分支
```

#### 3. 提交信息规范
```bash
# 格式: <type>(<scope>): <description>
feat(commands): add new validate command
fix(template): resolve variable substitution issue
docs(api): update API documentation
test(integration): add end-to-end tests
refactor(core): improve service manager architecture
perf(validator): optimize validation performance
style(format): fix code formatting issues
chore(deps): update dependencies
```

### 开发任务

#### 1. 添加新命令
```bash
# 1. 创建命令文件
touch lib/src/commands/my_command.dart

# 2. 实现命令类
# 3. 注册命令
# 4. 添加测试
# 5. 更新文档
```

#### 2. 添加新服务
```bash
# 1. 创建服务接口
touch lib/src/services/my_service.dart

# 2. 实现服务类
# 3. 注册服务
# 4. 添加单元测试
# 5. 更新API文档
```

#### 3. 添加新模板
```bash
# 1. 创建模板目录
mkdir -p templates/my_template

# 2. 创建模板配置
# 3. 添加模板文件
# 4. 编写测试
# 5. 更新文档
```

## 代码规范

### Dart 代码风格

#### 1. 命名约定
```dart
// 类名：PascalCase
class TemplateService { }
class ValidationResult { }

// 方法和变量：camelCase
void createModule() { }
String templateName = '';

// 常量：lowerCamelCase
const String defaultTemplate = 'basic';

// 私有成员：下划线前缀
String _privateField;
void _privateMethod() { }

// 文件名：snake_case
template_service.dart
validation_result.dart
```

#### 2. 代码组织
```dart
// 导入顺序
import 'dart:io';                    // Dart 核心库
import 'dart:convert';

import 'package:args/args.dart';     // 第三方包
import 'package:yaml/yaml.dart';

import '../core/service_manager.dart'; // 项目内部导入
import '../models/template.dart';

// 类成员顺序
class MyClass {
  // 1. 静态常量
  static const String defaultValue = 'default';
  
  // 2. 静态变量
  static String? _instance;
  
  // 3. 实例字段
  final String name;
  String? _description;
  
  // 4. 构造函数
  MyClass(this.name);
  MyClass.named({required this.name});
  
  // 5. 静态方法
  static MyClass getInstance() { ... }
  
  // 6. 公共方法
  void publicMethod() { ... }
  
  // 7. 私有方法
  void _privateMethod() { ... }
}
```

#### 3. 文档注释
```dart
/// 模板服务类
/// 
/// 提供模板管理功能，包括：
/// - 模板发现和加载
/// - 模板渲染和生成
/// - 模板验证和缓存
class TemplateService {
  /// 渲染指定模板
  /// 
  /// [templateName] 模板名称
  /// [outputPath] 输出路径
  /// [variables] 模板变量
  /// 
  /// 返回渲染结果，包含生成的文件列表和元数据
  /// 
  /// 抛出 [TemplateException] 如果模板不存在或渲染失败
  Future<TemplateResult> renderTemplate({
    required String templateName,
    required String outputPath,
    required Map<String, dynamic> variables,
  }) async {
    // 实现...
  }
}
```

### 错误处理规范

#### 1. 异常设计
```dart
// 自定义异常基类
abstract class MingCliException implements Exception {
  String get message;
  String? get context;
}

// 具体异常类
class TemplateNotFoundException extends MingCliException {
  final String templateName;
  
  TemplateNotFoundException(this.templateName);
  
  @override
  String get message => 'Template "$templateName" not found';
  
  @override
  String? get context => 'Check available templates with: ming template list';
}
```

#### 2. 错误处理模式
```dart
// 使用 Result 模式
Future<Result<Module>> createModule(String name) async {
  try {
    final module = await _doCreateModule(name);
    return Result.success(module);
  } on TemplateException catch (e) {
    logger.error('Template error', error: e);
    return Result.failure('Failed to create module: ${e.message}');
  } catch (e, stackTrace) {
    logger.error('Unexpected error', error: e, stackTrace: stackTrace);
    return Result.failure('Unexpected error occurred');
  }
}
```

## 测试指南

### 测试结构

#### 1. 测试类型
```bash
test/
├── unit/                    # 单元测试
│   ├── services/           # 服务测试
│   ├── models/             # 模型测试
│   └── utils/              # 工具类测试
├── integration/            # 集成测试
│   ├── commands/           # 命令集成测试
│   ├── workflows/          # 工作流测试
│   └── end_to_end/         # 端到端测试
└── performance/            # 性能测试
    ├── benchmarks/         # 基准测试
    └── load_tests/         # 负载测试
```

#### 2. 测试命名
```dart
// 测试文件命名：<source_file>_test.dart
template_service.dart → template_service_test.dart

// 测试组命名：描述测试的功能
group('TemplateService', () {
  group('renderTemplate', () {
    test('should render basic template successfully', () { });
    test('should throw exception for invalid template', () { });
  });
});
```

### 单元测试

#### 1. 服务测试示例
```dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:ming_status_cli/src/services/template_service.dart';

@GenerateMocks([FileSystem, Logger])
import 'template_service_test.mocks.dart';

void main() {
  group('TemplateService', () {
    late TemplateService service;
    late MockFileSystem mockFileSystem;
    late MockLogger mockLogger;

    setUp(() {
      mockFileSystem = MockFileSystem();
      mockLogger = MockLogger();
      service = TemplateService(
        fileSystem: mockFileSystem,
        logger: mockLogger,
      );
    });

    group('renderTemplate', () {
      test('should render template successfully', () async {
        // Arrange
        const templateName = 'basic';
        const outputPath = '/output';
        final variables = {'name': 'test'};
        
        when(mockFileSystem.exists(any)).thenReturn(true);
        when(mockFileSystem.readAsString(any))
            .thenAnswer((_) async => 'Hello {{name}}!');

        // Act
        final result = await service.renderTemplate(
          templateName: templateName,
          outputPath: outputPath,
          variables: variables,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.generatedFiles, isNotEmpty);
        verify(mockFileSystem.writeAsString(any, 'Hello test!')).called(1);
      });

      test('should throw exception for missing template', () async {
        // Arrange
        when(mockFileSystem.exists(any)).thenReturn(false);

        // Act & Assert
        expect(
          () => service.renderTemplate(
            templateName: 'nonexistent',
            outputPath: '/output',
            variables: {},
          ),
          throwsA(isA<TemplateNotFoundException>()),
        );
      });
    });
  });
}
```

#### 2. 模型测试示例
```dart
void main() {
  group('ValidationResult', () {
    test('should be valid when no error messages', () {
      final result = ValidationResult(messages: [
        ValidationMessage(level: ValidationLevel.info, message: 'Info'),
      ]);
      
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('should be invalid when has error messages', () {
      final result = ValidationResult(messages: [
        ValidationMessage(level: ValidationLevel.error, message: 'Error'),
      ]);
      
      expect(result.isValid, isFalse);
      expect(result.errors, hasLength(1));
    });
  });
}
```

### 集成测试

#### 1. 命令集成测试
```dart
void main() {
  group('InitCommand Integration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ming_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should create workspace successfully', () async {
      // Arrange
      final app = CliApp();
      final args = [
        'init',
        'test_workspace',
        '--path', tempDir.path,
        '--name', 'Test Workspace',
      ];

      // Act
      final exitCode = await app.run(args);

      // Assert
      expect(exitCode, equals(0));
      
      final configFile = File(path.join(tempDir.path, 'ming_status.yaml'));
      expect(configFile.existsSync(), isTrue);
      
      final config = await configFile.readAsString();
      expect(config, contains('name: Test Workspace'));
    });
  });
}
```

### 测试工具

#### 1. 测试辅助类
```dart
/// 测试辅助工具类
class TestHelper {
  /// 创建临时目录
  static Future<Directory> createTempDir([String? prefix]) async {
    return Directory.systemTemp.createTemp(prefix ?? 'ming_test_');
  }

  /// 创建测试文件
  static Future<File> createTestFile(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return file;
  }

  /// 运行CLI命令
  static Future<ProcessResult> runCli(List<String> args) async {
    return Process.run(
      'dart',
      ['run', 'bin/ming_status_cli.dart', ...args],
      workingDirectory: Directory.current.path,
    );
  }
}
```

#### 2. Mock 工厂
```dart
/// Mock 对象工厂
class MockFactory {
  static MockTemplateService createTemplateService() {
    final mock = MockTemplateService();
    when(mock.getAvailableTemplates())
        .thenAnswer((_) async => [
          Template(name: 'basic', description: 'Basic template'),
          Template(name: 'flutter', description: 'Flutter template'),
        ]);
    return mock;
  }

  static MockValidatorService createValidatorService() {
    final mock = MockValidatorService();
    when(mock.validateWorkspace(any))
        .thenAnswer((_) async => ValidationResult(messages: []));
    return mock;
  }
}
```

### 运行测试

#### 1. 基本测试命令
```bash
# 运行所有测试
dart test

# 运行特定测试文件
dart test test/unit/services/template_service_test.dart

# 运行特定测试组
dart test --name "TemplateService"

# 运行测试并生成覆盖率报告
dart test --coverage=coverage
dart pub global run coverage:format_coverage \
  --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

#### 2. 持续集成配置
```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: 3.2.0
      
      - name: Install dependencies
        run: dart pub get
      
      - name: Run tests
        run: dart test --coverage=coverage
      
      - name: Generate coverage report
        run: |
          dart pub global activate coverage
          dart pub global run coverage:format_coverage \
            --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

## 调试技巧

### 调试环境配置

#### 1. 启用调试模式
```bash
# 设置环境变量
export MING_DEBUG=true
export MING_LOG_LEVEL=debug

# 运行CLI
dart run bin/ming_status_cli.dart --verbose init test_project
```

#### 2. 调试配置
```dart
// lib/src/utils/debug.dart
class Debug {
  static bool get isEnabled =>
      Platform.environment['MING_DEBUG'] == 'true';

  static void log(String message, {String? tag}) {
    if (isEnabled) {
      final timestamp = DateTime.now().toIso8601String();
      print('[$timestamp] ${tag ?? 'DEBUG'}: $message');
    }
  }

  static void breakpoint() {
    if (isEnabled) {
      // 在调试器中设置断点
      print('Breakpoint reached');
    }
  }
}
```

### 常见调试场景

#### 1. 模板渲染调试
```dart
Future<TemplateResult> renderTemplate(...) async {
  Debug.log('Starting template rendering', tag: 'TemplateService');
  Debug.log('Template: $templateName, Output: $outputPath');

  try {
    final template = await _loadTemplate(templateName);
    Debug.log('Template loaded: ${template.files.length} files');

    for (final file in template.files) {
      Debug.log('Processing file: ${file.path}');
      final content = await _renderFile(file, variables);
      Debug.log('Rendered content length: ${content.length}');
    }

    return TemplateResult.success(generatedFiles);
  } catch (e, stackTrace) {
    Debug.log('Template rendering failed: $e');
    if (Debug.isEnabled) {
      print(stackTrace);
    }
    rethrow;
  }
}
```

#### 2. 命令执行调试
```dart
@override
Future<int> run() async {
  Debug.log('Command started: ${name}', tag: 'Command');
  Debug.log('Arguments: ${argResults?.arguments}');

  try {
    final result = await execute();
    Debug.log('Command completed with exit code: $result');
    return result;
  } catch (e) {
    Debug.log('Command failed: $e');
    return 1;
  }
}
```

### 性能分析

#### 1. 性能监控
```dart
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  static void start(String operation) {
    _timers[operation] = Stopwatch()..start();
    Debug.log('Started: $operation', tag: 'Performance');
  }

  static void end(String operation) {
    final timer = _timers.remove(operation);
    if (timer != null) {
      timer.stop();
      Debug.log('Completed: $operation in ${timer.elapsedMilliseconds}ms',
                tag: 'Performance');
    }
  }
}

// 使用示例
PerformanceMonitor.start('template_rendering');
await renderTemplate(...);
PerformanceMonitor.end('template_rendering');
```

#### 2. 内存监控
```dart
class MemoryMonitor {
  static void logMemoryUsage(String operation) {
    if (Debug.isEnabled) {
      final rss = ProcessInfo.currentRss;
      final maxRss = ProcessInfo.maxRss;
      Debug.log('Memory usage for $operation: ${_formatBytes(rss)} / ${_formatBytes(maxRss)}',
                tag: 'Memory');
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
```

## 性能优化

### 代码优化

#### 1. 异步操作优化
```dart
// 避免：串行执行
Future<void> processModules(List<String> modules) async {
  for (final module in modules) {
    await processModule(module);  // 串行执行
  }
}

// 推荐：并行执行
Future<void> processModules(List<String> modules) async {
  final futures = modules.map((module) => processModule(module));
  await Future.wait(futures);  // 并行执行
}

// 推荐：限制并发数
Future<void> processModules(List<String> modules) async {
  const concurrency = 4;
  for (int i = 0; i < modules.length; i += concurrency) {
    final batch = modules.skip(i).take(concurrency);
    final futures = batch.map((module) => processModule(module));
    await Future.wait(futures);
  }
}
```

#### 2. 缓存策略
```dart
class TemplateCache {
  static final Map<String, Template> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheExpiry = Duration(hours: 1);

  static Future<Template?> get(String name) async {
    final cached = _cache[name];
    final cacheTime = _cacheTime[name];

    if (cached != null && cacheTime != null) {
      if (DateTime.now().difference(cacheTime) < _cacheExpiry) {
        return cached;
      }
    }

    return null;
  }

  static void put(String name, Template template) {
    _cache[name] = template;
    _cacheTime[name] = DateTime.now();
  }

  static void clear() {
    _cache.clear();
    _cacheTime.clear();
  }
}
```

#### 3. 文件I/O优化
```dart
// 避免：频繁的小文件读写
Future<void> writeFiles(Map<String, String> files) async {
  for (final entry in files.entries) {
    await File(entry.key).writeAsString(entry.value);
  }
}

// 推荐：批量操作
Future<void> writeFiles(Map<String, String> files) async {
  final futures = files.entries.map((entry) async {
    final file = File(entry.key);
    await file.parent.create(recursive: true);
    return file.writeAsString(entry.value);
  });

  await Future.wait(futures);
}
```

### 内存优化

#### 1. 流式处理
```dart
// 避免：加载大文件到内存
Future<String> processLargeFile(String path) async {
  final content = await File(path).readAsString();  // 全部加载到内存
  return processContent(content);
}

// 推荐：流式处理
Future<void> processLargeFile(String inputPath, String outputPath) async {
  final input = File(inputPath).openRead();
  final output = File(outputPath).openWrite();

  await input
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .map((line) => processLine(line))
      .transform(utf8.encoder)
      .pipe(output);

  await output.close();
}
```

#### 2. 对象池
```dart
class StringBuilderPool {
  static final Queue<StringBuffer> _pool = Queue<StringBuffer>();
  static const int _maxPoolSize = 10;

  static StringBuffer acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeFirst()..clear();
    }
    return StringBuffer();
  }

  static void release(StringBuffer buffer) {
    if (_pool.length < _maxPoolSize) {
      _pool.add(buffer);
    }
  }
}

// 使用示例
final buffer = StringBuilderPool.acquire();
try {
  buffer.write('Hello');
  buffer.write(' World');
  return buffer.toString();
} finally {
  StringBuilderPool.release(buffer);
}
```

## 发布流程

### 版本管理

#### 1. 语义化版本
```bash
# 版本格式：MAJOR.MINOR.PATCH
1.0.0    # 初始版本
1.0.1    # 补丁版本（错误修复）
1.1.0    # 次要版本（新功能，向后兼容）
2.0.0    # 主要版本（破坏性变更）
```

#### 2. 版本更新流程
```bash
# 1. 更新版本号
# 编辑 pubspec.yaml
version: 1.1.0

# 2. 更新变更日志
# 编辑 CHANGELOG.md

# 3. 创建版本标签
git add .
git commit -m "chore: bump version to 1.1.0"
git tag v1.1.0
git push origin main --tags
```

### 构建和打包

#### 1. 构建脚本
```bash
#!/bin/bash
# scripts/build.sh

set -e

echo "Building Ming Status CLI..."

# 清理之前的构建
rm -rf build/

# 创建构建目录
mkdir -p build/

# 编译各平台版本
echo "Building for Linux..."
dart compile exe bin/ming_status_cli.dart -o build/ming-linux

echo "Building for macOS..."
dart compile exe bin/ming_status_cli.dart -o build/ming-macos

echo "Building for Windows..."
dart compile exe bin/ming_status_cli.dart -o build/ming-windows.exe

echo "Build completed!"
```

#### 2. 发布脚本
```bash
#!/bin/bash
# scripts/release.sh

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

echo "Releasing version $VERSION..."

# 运行测试
echo "Running tests..."
dart test

# 运行代码分析
echo "Running analysis..."
dart analyze

# 构建
echo "Building..."
./scripts/build.sh

# 创建发布包
echo "Creating release package..."
tar -czf "build/ming-status-cli-$VERSION-linux.tar.gz" -C build ming-linux
tar -czf "build/ming-status-cli-$VERSION-macos.tar.gz" -C build ming-macos
zip "build/ming-status-cli-$VERSION-windows.zip" build/ming-windows.exe

echo "Release $VERSION created successfully!"
```

### CI/CD 配置

#### 1. GitHub Actions 发布流程
```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags:
      - 'v*'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart test
      - run: dart analyze

  build:
    needs: test
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - name: Build executable
        run: |
          if [ "$RUNNER_OS" == "Windows" ]; then
            dart compile exe bin/ming_status_cli.dart -o ming.exe
          else
            dart compile exe bin/ming_status_cli.dart -o ming
          fi
        shell: bash
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: ming-${{ runner.os }}
          path: ming*

  release:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Download artifacts
        uses: actions/download-artifact@v3
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            ming-Linux/ming
            ming-macOS/ming
            ming-Windows/ming.exe
          generate_release_notes: true
```

#### 2. 发布到 pub.dev
```yaml
# .github/workflows/publish.yml
name: Publish to pub.dev
on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart test
      - name: Publish
        run: dart pub publish --force
        env:
          PUB_TOKEN: ${{ secrets.PUB_TOKEN }}
```

### 质量检查

#### 1. 发布前检查清单
```bash
# scripts/pre_release_check.sh
#!/bin/bash

echo "Pre-release quality check..."

# 1. 运行所有测试
echo "Running tests..."
dart test || exit 1

# 2. 代码分析
echo "Running analysis..."
dart analyze || exit 1

# 3. 格式检查
echo "Checking format..."
dart format --set-exit-if-changed . || exit 1

# 4. 依赖检查
echo "Checking dependencies..."
dart pub deps || exit 1

# 5. 文档检查
echo "Checking documentation..."
dart doc --validate-links || exit 1

# 6. 性能测试
echo "Running performance tests..."
dart test test/performance/ || exit 1

echo "All checks passed!"
```

#### 2. 代码质量指标
```bash
# 使用 dart_code_metrics
dart pub global activate dart_code_metrics

# 生成代码质量报告
dart pub global run dart_code_metrics:metrics \
  analyze lib \
  --reporter=html \
  --output-directory=reports/

# 检查代码复杂度
dart pub global run dart_code_metrics:metrics \
  check-unnecessary-nullable lib
```

---

## 贡献指南

### 如何贡献

1. **Fork 项目**
2. **创建功能分支** (`git checkout -b feature/amazing-feature`)
3. **提交更改** (`git commit -m 'Add amazing feature'`)
4. **推送分支** (`git push origin feature/amazing-feature`)
5. **创建 Pull Request**

### 代码审查

- 所有代码必须通过测试
- 遵循项目代码规范
- 添加适当的文档和注释
- 更新相关文档

### 社区

- **GitHub**: https://github.com/ming-cli/ming_status_cli
- **Discord**: https://discord.gg/ming-cli
- **邮件**: dev@ming-cli.com

---

*开发者指南版本: 1.0.0 | 最后更新: 2025-07-08*
