# Ming Status CLI 最佳实践指南

## 🎯 概述

本指南汇集了使用 Ming Status CLI 的最佳实践，帮助你构建高质量、可维护的项目。

## 📁 项目结构最佳实践

### 1. 工作空间组织

#### 推荐的目录结构
```
my-project/
├── ming_status.yaml          # 工作空间配置
├── modules/                  # 核心模块
│   ├── core/                # 核心业务逻辑
│   ├── shared/              # 共享代码
│   └── features/            # 功能模块
│       ├── auth/
│       ├── user/
│       └── dashboard/
├── apps/                     # 应用程序
│   ├── mobile/              # 移动应用
│   ├── web/                 # Web 应用
│   └── desktop/             # 桌面应用
├── packages/                 # 可重用包
│   ├── ui_kit/              # UI 组件库
│   ├── utils/               # 工具函数
│   └── api_client/          # API 客户端
├── tools/                    # 开发工具
│   ├── scripts/             # 构建脚本
│   ├── generators/          # 代码生成器
│   └── analyzers/           # 代码分析工具
├── docs/                     # 文档
├── tests/                    # 集成测试
└── deployment/               # 部署配置
    ├── docker/
    ├── k8s/
    └── terraform/
```

#### 模块分层原则
```
应用层 (apps/)
    ↓ 依赖
功能层 (modules/features/)
    ↓ 依赖
核心层 (modules/core/)
    ↓ 依赖
共享层 (modules/shared/)
    ↓ 依赖
包层 (packages/)
```

### 2. 命名约定

#### 工作空间和模块命名
```bash
# 工作空间：kebab-case
my-awesome-project
e-commerce-platform
blog-management-system

# 模块：snake_case
user_authentication
payment_processing
notification_service

# 包名：snake_case
ui_components
http_client
data_models
```

#### 文件和目录命名
```bash
# 文件：snake_case
user_service.dart
payment_controller.dart
auth_middleware.dart

# 目录：snake_case
lib/services/
lib/controllers/
lib/middleware/
```

## ⚙️ 配置管理最佳实践

### 1. 工作空间配置

#### ming_status.yaml 模板
```yaml
# 项目基本信息
name: "My Project"
description: "A comprehensive project built with Ming CLI"
version: "1.0.0"
author: "Your Name <your@email.com>"
license: "MIT"
homepage: "https://github.com/yourname/my-project"

# 项目类型和框架
type: "multi_module"
framework: "dart"

# 模块配置
modules:
  - name: "core"
    path: "./modules/core"
    type: "dart_package"
    dependencies: ["shared"]
  
  - name: "auth"
    path: "./modules/features/auth"
    type: "feature_module"
    dependencies: ["core", "shared"]

# 全局依赖
dependencies:
  dart: ">=3.0.0 <4.0.0"

dev_dependencies:
  test: ^1.21.0
  lints: ^2.0.0
  coverage: ^1.6.0

# 脚本配置
scripts:
  test: "ming test --coverage"
  analyze: "ming analyze --fatal-infos"
  format: "ming format --set-exit-if-changed"
  build: "ming build --release"
  deploy: "ming deploy --environment production"

# 环境配置
environments:
  development:
    database_url: "sqlite:///dev.db"
    api_base_url: "http://localhost:8080"
  
  production:
    database_url: "${DATABASE_URL}"
    api_base_url: "${API_BASE_URL}"

# 代码质量配置
quality:
  min_coverage: 80
  max_complexity: 10
  enforce_documentation: true
```

### 2. 环境变量管理

#### .env 文件结构
```bash
# .env.development
DATABASE_URL=sqlite:///dev.db
API_BASE_URL=http://localhost:8080
LOG_LEVEL=debug
ENABLE_DEBUG=true

# .env.production
DATABASE_URL=postgresql://user:pass@host:5432/db
API_BASE_URL=https://api.example.com
LOG_LEVEL=info
ENABLE_DEBUG=false
```

#### 配置加载
```dart
// lib/config/environment.dart
class Environment {
  static const String development = 'development';
  static const String production = 'production';
  
  static String get current => 
      Platform.environment['ENVIRONMENT'] ?? development;
  
  static bool get isDevelopment => current == development;
  static bool get isProduction => current == production;
  
  static String get databaseUrl => 
      Platform.environment['DATABASE_URL'] ?? 'sqlite:///dev.db';
  
  static String get apiBaseUrl => 
      Platform.environment['API_BASE_URL'] ?? 'http://localhost:8080';
}
```

## 🧪 测试最佳实践

### 1. 测试结构

#### 测试目录组织
```
test/
├── unit/                     # 单元测试
│   ├── services/
│   ├── models/
│   └── utils/
├── integration/              # 集成测试
│   ├── api/
│   ├── database/
│   └── workflows/
├── widget/                   # Widget 测试 (Flutter)
├── e2e/                      # 端到端测试
├── fixtures/                 # 测试数据
├── mocks/                    # Mock 对象
└── helpers/                  # 测试辅助工具
```

#### 测试命名约定
```dart
// 测试文件：<source_file>_test.dart
user_service.dart → user_service_test.dart

// 测试组：描述被测试的类或功能
group('UserService', () {
  group('createUser', () {
    test('should create user with valid data', () {});
    test('should throw exception for invalid email', () {});
  });
});
```

### 2. 测试模式

#### 单元测试模板
```dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:my_project/services/user_service.dart';
import 'package:my_project/repositories/user_repository.dart';

@GenerateMocks([UserRepository])
import 'user_service_test.mocks.dart';

void main() {
  group('UserService', () {
    late UserService userService;
    late MockUserRepository mockRepository;

    setUp(() {
      mockRepository = MockUserRepository();
      userService = UserService(mockRepository);
    });

    group('createUser', () {
      test('should create user successfully', () async {
        // Arrange
        final userData = UserData(
          name: 'John Doe',
          email: 'john@example.com',
        );
        final expectedUser = User(
          id: '1',
          name: 'John Doe',
          email: 'john@example.com',
        );

        when(mockRepository.create(any))
            .thenAnswer((_) async => expectedUser);

        // Act
        final result = await userService.createUser(userData);

        // Assert
        expect(result, equals(expectedUser));
        verify(mockRepository.create(userData)).called(1);
      });

      test('should throw exception for duplicate email', () async {
        // Arrange
        final userData = UserData(
          name: 'John Doe',
          email: 'existing@example.com',
        );

        when(mockRepository.create(any))
            .thenThrow(DuplicateEmailException());

        // Act & Assert
        expect(
          () => userService.createUser(userData),
          throwsA(isA<DuplicateEmailException>()),
        );
      });
    });
  });
}
```

### 3. 测试覆盖率

#### 覆盖率配置
```yaml
# test/coverage_config.yaml
coverage:
  min_coverage: 80
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/main.dart"
    - "test/**"
  
  per_file_min: 70
  
  reports:
    - lcov
    - html
    - json
```

#### 运行覆盖率测试
```bash
# 生成覆盖率报告
ming test --coverage

# 查看 HTML 报告
ming coverage report --format html --open

# 检查覆盖率阈值
ming coverage check --min 80
```

## 🔧 代码质量最佳实践

### 1. 代码分析配置

#### analysis_options.yaml
```yaml
include: package:lints/recommended.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "build/**"
  
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false
  
  errors:
    invalid_annotation_target: ignore
    missing_required_param: error
    missing_return: error

linter:
  rules:
    # 启用推荐规则
    - prefer_single_quotes
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_print
    - avoid_unnecessary_containers
    - sized_box_for_whitespace
    
    # 文档规则
    - public_member_api_docs
    - package_api_docs
    
    # 性能规则
    - prefer_const_declarations
    - prefer_final_locals
    - unnecessary_lambdas
```

### 2. 代码格式化

#### .editorconfig
```ini
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true

[*.dart]
indent_size = 2
max_line_length = 80

[*.{json,yaml,yml}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false
```

### 3. Git Hooks

#### pre-commit hook
```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Running pre-commit checks..."

# 格式检查
echo "Checking code format..."
if ! ming format --set-exit-if-changed; then
    echo "❌ Code formatting issues found. Run 'ming format' to fix."
    exit 1
fi

# 代码分析
echo "Running static analysis..."
if ! ming analyze --fatal-infos; then
    echo "❌ Static analysis issues found."
    exit 1
fi

# 运行测试
echo "Running tests..."
if ! ming test; then
    echo "❌ Tests failed."
    exit 1
fi

echo "✅ All pre-commit checks passed!"
```

## 🚀 性能优化最佳实践

### 1. 构建优化

#### 生产构建配置
```yaml
# build_config.yaml
targets:
  $default:
    builders:
      build_web_compilers|entrypoint:
        options:
          compiler: dart2js
          dart2js_args:
            - --minify
            - --fast-startup
            - --trust-primitives
```

### 2. 依赖管理

#### pubspec.yaml 优化
```yaml
dependencies:
  # 核心依赖
  http: ^0.13.5
  json_annotation: ^4.8.1
  
  # 开发时依赖
dev_dependencies:
  build_runner: ^2.4.6
  json_serializable: ^6.7.1
  test: ^1.21.0

# 依赖覆盖（谨慎使用）
dependency_overrides:
  # 仅在必要时使用
  meta: ^1.9.1
```

## 📦 发布和部署最佳实践

### 1. 版本管理

#### 语义化版本
```bash
# 补丁版本（错误修复）
ming version bump patch    # 1.0.0 → 1.0.1

# 次要版本（新功能）
ming version bump minor    # 1.0.1 → 1.1.0

# 主要版本（破坏性变更）
ming version bump major    # 1.1.0 → 2.0.0
```

#### CHANGELOG.md 格式
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature X
- Support for Y

### Changed
- Improved performance of Z

### Fixed
- Bug in component A

## [1.1.0] - 2025-07-08

### Added
- User authentication system
- Dashboard analytics

### Changed
- Updated UI components
- Improved error handling

### Fixed
- Memory leak in data service
- Validation issues in forms
```

### 2. CI/CD 配置

#### GitHub Actions 工作流
```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: 3.2.0
      
      - name: Install Ming CLI
        run: dart pub global activate ming_status_cli
      
      - name: Install dependencies
        run: ming deps install
      
      - name: Run tests
        run: ming test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      
      - name: Build project
        run: ming build --release
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: build/

  deploy:
    needs: [test, build]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to production
        run: ming deploy --environment production
```

## 📚 文档最佳实践

### 1. 代码文档

#### 文档注释模板
```dart
/// 用户服务类
/// 
/// 提供用户管理相关的业务逻辑，包括：
/// - 用户创建和更新
/// - 用户认证和授权
/// - 用户数据验证
/// 
/// 示例用法：
/// ```dart
/// final userService = UserService(userRepository);
/// final user = await userService.createUser(userData);
/// ```
class UserService {
  /// 用户数据仓库
  final UserRepository _repository;

  /// 创建用户服务实例
  /// 
  /// [repository] 用户数据仓库实例
  UserService(this._repository);

  /// 创建新用户
  /// 
  /// [userData] 用户数据
  /// 
  /// 返回创建的用户实例
  /// 
  /// 抛出 [ValidationException] 如果用户数据无效
  /// 抛出 [DuplicateEmailException] 如果邮箱已存在
  Future<User> createUser(UserData userData) async {
    // 实现...
  }
}
```

### 2. README 模板

#### 项目 README 结构
```markdown
# Project Name

Brief description of what this project does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Installation

```bash
ming init my-project
cd my-project
ming deps install
```

## Usage

```dart
// Code example
```

## API Reference

Link to API documentation.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.
```

---

**遵循这些最佳实践，你将能够构建高质量、可维护的 Ming CLI 项目！** 🚀

*最佳实践指南版本: 1.0.0 | 最后更新: 2025-07-08*
