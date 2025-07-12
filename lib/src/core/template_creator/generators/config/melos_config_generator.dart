/*
---------------------------------------------------------------
File name:          melos_config_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        melos.yaml配置文件生成器 (Melos Configuration Generator)
---------------------------------------------------------------
Change History:
    2025/07/13: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加更多monorepo管理脚本
    - [ ] 优化依赖管理策略
    - [ ] 添加CI/CD集成脚本
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/config/config_generator_base.dart';

/// 嵌套级别枚举
enum NestingLevel {
  /// 根级 (pro_0)
  root,

  /// 系统级 (pro_1.0, pro_1.1)
  system,

  /// 模块级 (pro_1.1.1, pro_1.1.2)
  module,
}

/// melos.yaml配置文件生成器
///
/// 负责生成Melos monorepo管理配置文件
class MelosConfigGenerator extends ConfigGeneratorBase {
  /// 创建melos.yaml生成器实例
  const MelosConfigGenerator();

  @override
  String getFileName() => 'melos.yaml';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer()
      ..writeln('# Melos Monorepo管理配置')
      ..writeln('# 更多信息: https://pub.dev/packages/melos')
      ..writeln()
      ..writeln('name: ${config.templateName}')
      ..writeln();

    // 根据嵌套级别生成不同的配置
    final nestingLevel = _detectNestingLevel(config);

    // 添加包配置
    _addPackageConfiguration(buffer, config, nestingLevel);

    // 添加忽略配置
    _addIgnoreConfiguration(buffer, config);

    // 添加IDE配置 (只在根级启用)
    if (nestingLevel == NestingLevel.root) {
      _addIDEConfiguration(buffer, config);
    }

    // 添加命令配置
    _addCommandConfiguration(buffer, config, nestingLevel);

    // 添加脚本配置
    buffer.writeln('# 脚本配置');
    buffer.writeln('scripts:');

    // 根据嵌套级别添加不同的脚本
    _addScriptsByNestingLevel(buffer, config, nestingLevel);

    return buffer.toString();
  }

  /// 检测嵌套级别
  NestingLevel _detectNestingLevel(ScaffoldConfig config) {
    // 通过模板名称或路径检测嵌套级别
    final name = config.templateName.toLowerCase();

    if (name.contains('_root') || name.startsWith('pro_0')) {
      return NestingLevel.root;
    } else if (name.contains('_system') || name.contains('pro_1.')) {
      return NestingLevel.system;
    } else if (name.contains('_module') || name.contains('pro_1.1.')) {
      return NestingLevel.module;
    }

    // 默认为根级
    return NestingLevel.root;
  }

  /// 添加包配置
  void _addPackageConfiguration(
      StringBuffer buffer, ScaffoldConfig config, NestingLevel level,) {
    buffer.writeln('# 包配置');
    buffer.writeln('packages:');

    switch (level) {
      case NestingLevel.root:
        buffer
          ..writeln('  - .')
          ..writeln('  - pro_*/**') // 所有 pro_ 开头的子项目
          ..writeln('  - packages/**') // 共享包
          ..writeln('  - apps/**') // 应用包
          ..writeln('  - tools/**') // 工具包
          ..writeln('  - modules/**'); // 模块包
      case NestingLevel.system:
        buffer
          ..writeln('  - .')
          ..writeln('  - pro_*.*/**') // 当前系统下的所有模块
          ..writeln('  - shared/**'); // 系统级共享包
      case NestingLevel.module:
        buffer
          ..writeln('  - .')
          ..writeln('  - lib/**') // 模块内的子包
          ..writeln('  - components/**'); // 组件包
    }

    buffer.writeln();
  }

  /// 添加忽略配置
  void _addIgnoreConfiguration(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('# 忽略配置')
      ..writeln('ignore:')
      ..writeln('  - "**/.*"')
      ..writeln('  - "**/build/**"')
      ..writeln('  - "**/.dart_tool/**"')
      ..writeln('  - "**/generated/**"')
      ..writeln('  - "**/*.g.dart"')
      ..writeln('  - "**/*.freezed.dart"')
      ..writeln('  - "**/*.mocks.dart"')
      ..writeln();
  }

  /// 添加IDE配置
  void _addIDEConfiguration(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('# IDE配置')
      ..writeln('ide:')
      ..writeln('  intellij:')
      ..writeln('    enabled: true')
      ..writeln('    moduleNamePrefix: "${config.templateName}_"')
      ..writeln();
  }

  /// 添加命令配置
  void _addCommandConfiguration(
      StringBuffer buffer, ScaffoldConfig config, NestingLevel level,) {
    buffer
      ..writeln('# 命令配置')
      ..writeln('command:')
      ..writeln('  version:')
      ..writeln('    # 版本管理策略')
      ..writeln(
          '    strategy: ${level == NestingLevel.root ? 'all' : 'independent'}',)
      ..writeln('    # 更新依赖')
      ..writeln('    updateGitTagRefs: ${level == NestingLevel.root}')
      ..writeln('    # 工作区依赖')
      ..writeln('    workspaceChangelog: ${level == NestingLevel.root}')
      ..writeln();
  }

  /// 根据嵌套级别添加脚本
  void _addScriptsByNestingLevel(
      StringBuffer buffer, ScaffoldConfig config, NestingLevel level,) {
    switch (level) {
      case NestingLevel.root:
        _addRootLevelScripts(buffer, config);
      case NestingLevel.system:
        _addSystemLevelScripts(buffer, config);
      case NestingLevel.module:
        _addModuleLevelScripts(buffer, config);
    }
  }

  /// 添加根级脚本
  void _addRootLevelScripts(StringBuffer buffer, ScaffoldConfig config) {
    // 添加开发脚本
    _addDevelopmentScripts(buffer, config);
    // 添加质量保证脚本
    _addQualityScripts(buffer, config);
    // 添加测试脚本
    _addTestScripts(buffer, config);
    // 添加构建脚本
    _addBuildScripts(buffer, config);
    // 添加依赖管理脚本
    _addDependencyScripts(buffer, config);
  }

  /// 添加系统级脚本
  void _addSystemLevelScripts(StringBuffer buffer, ScaffoldConfig config) {
    // 系统级只包含基本的开发和测试脚本
    _addDevelopmentScripts(buffer, config);
    _addTestScripts(buffer, config);
  }

  /// 添加模块级脚本
  void _addModuleLevelScripts(StringBuffer buffer, ScaffoldConfig config) {
    // 模块级只包含最基本的脚本
    buffer
      ..writeln('  # === 模块级脚本 ===')
      ..writeln()
      ..writeln('  # 🧪 运行测试')
      ..writeln('  test:')
      ..writeln('    run: flutter test')
      ..writeln('    description: 运行模块测试')
      ..writeln()
      ..writeln('  # 🔍 代码分析')
      ..writeln('  analyze:')
      ..writeln('    run: flutter analyze')
      ..writeln('    description: 分析模块代码')
      ..writeln();
  }

  /// 添加开发脚本
  void _addDevelopmentScripts(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  # === 开发脚本 ===')
      ..writeln()
      ..writeln('  # 🚀 获取所有依赖')
      ..writeln('  get:')
      ..writeln('    run: melos exec -- "flutter pub get"')
      ..writeln('    description: 获取所有包的依赖')
      ..writeln()
      ..writeln('  # 🧹 清理构建文件')
      ..writeln('  clean:')
      ..writeln('    run: melos exec -- "flutter clean"')
      ..writeln('    description: 清理所有包的构建文件')
      ..writeln()
      ..writeln('  # 🔄 重置项目')
      ..writeln('  reset:')
      ..writeln('    run: |')
      ..writeln('      melos clean')
      ..writeln('      melos get')
      ..writeln('    description: 重置整个项目（清理+获取依赖）')
      ..writeln()
      ..writeln('  # 🔧 代码生成')
      ..writeln('  generate:')
      ..writeln(
          '    run: melos exec -- "dart run build_runner build --delete-conflicting-outputs"',)
      ..writeln('    description: 运行代码生成')
      ..writeln('    packageFilters:')
      ..writeln('      dependsOn: "build_runner"')
      ..writeln()
      ..writeln('  # 👀 监听代码生成')
      ..writeln('  watch:')
      ..writeln(
          '    run: melos exec -- "dart run build_runner watch --delete-conflicting-outputs"',)
      ..writeln('    description: 监听文件变化并自动生成代码')
      ..writeln('    packageFilters:')
      ..writeln('      dependsOn: "build_runner"')
      ..writeln();
  }

  /// 添加质量保证脚本
  void _addQualityScripts(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  # === 质量保证脚本 ===')
      ..writeln()
      ..writeln('  # 📊 代码分析')
      ..writeln('  analyze:')
      ..writeln('    run: melos exec -- "dart analyze ."')
      ..writeln('    description: 分析所有包的代码质量')
      ..writeln()
      ..writeln('  # 🎨 代码格式化')
      ..writeln('  format:')
      ..writeln('    run: melos exec -- "dart format . --set-exit-if-changed"')
      ..writeln('    description: 格式化所有包的代码')
      ..writeln()
      ..writeln('  # 🔍 格式检查')
      ..writeln('  format-check:')
      ..writeln(
          '    run: melos exec -- "dart format . --output=none --set-exit-if-changed"',)
      ..writeln('    description: 检查代码格式是否正确')
      ..writeln()
      ..writeln('  # ✅ 质量检查')
      ..writeln('  quality:')
      ..writeln('    run: |')
      ..writeln('      melos format-check')
      ..writeln('      melos analyze')
      ..writeln('    description: 运行所有质量检查')
      ..writeln()
      ..writeln('  # 🔧 修复代码')
      ..writeln('  fix:')
      ..writeln('    run: melos exec -- "dart fix --apply"')
      ..writeln('    description: 自动修复代码问题')
      ..writeln();
  }

  /// 添加测试脚本
  void _addTestScripts(StringBuffer buffer, ScaffoldConfig config) {
    if (config.includeTests) {
      buffer
        ..writeln('  # === 测试脚本 ===')
        ..writeln()
        ..writeln('  # 🧪 单元测试')
        ..writeln('  test:')
        ..writeln('    run: melos exec -- "flutter test"')
        ..writeln('    description: 运行所有单元测试')
        ..writeln('    packageFilters:')
        ..writeln('      dirExists: test')
        ..writeln()
        ..writeln('  # 📱 Widget测试')
        ..writeln('  test-widget:')
        ..writeln('    run: melos exec -- "flutter test test/widget"')
        ..writeln('    description: 运行Widget测试')
        ..writeln('    packageFilters:')
        ..writeln('      dirExists: test/widget')
        ..writeln()
        ..writeln('  # 🔗 集成测试')
        ..writeln('  test-integration:')
        ..writeln('    run: melos exec -- "flutter test integration_test"')
        ..writeln('    description: 运行集成测试')
        ..writeln('    packageFilters:')
        ..writeln('      dirExists: integration_test')
        ..writeln()
        ..writeln('  # 📊 测试覆盖率')
        ..writeln('  coverage:')
        ..writeln('    run: melos exec -- "flutter test --coverage"')
        ..writeln('    description: 生成测试覆盖率报告')
        ..writeln('    packageFilters:')
        ..writeln('      dirExists: test')
        ..writeln()
        ..writeln('  # 🎯 完整测试')
        ..writeln('  test-all:')
        ..writeln('    run: |')
        ..writeln('      melos test')
        ..writeln('      melos test-widget')
        ..writeln('      melos test-integration')
        ..writeln('    description: 运行所有类型的测试')
        ..writeln();
    }
  }

  /// 添加构建脚本
  void _addBuildScripts(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  # === 构建脚本 ===')
      ..writeln()
      ..writeln('  # 🏗️ 构建所有')
      ..writeln('  build:')
      ..writeln('    run: melos exec -- "flutter build"')
      ..writeln('    description: 构建所有应用')
      ..writeln('    packageFilters:')
      ..writeln('      scope: "apps/*"')
      ..writeln()
      ..writeln('  # 📦 构建APK')
      ..writeln('  build-apk:')
      ..writeln('    run: melos exec -- "flutter build apk"')
      ..writeln('    description: 构建Android APK')
      ..writeln('    packageFilters:')
      ..writeln('      scope: "apps/*"')
      ..writeln()
      ..writeln('  # 🍎 构建iOS')
      ..writeln('  build-ios:')
      ..writeln('    run: melos exec -- "flutter build ios"')
      ..writeln('    description: 构建iOS应用')
      ..writeln('    packageFilters:')
      ..writeln('      scope: "apps/*"')
      ..writeln()
      ..writeln('  # 🌐 构建Web')
      ..writeln('  build-web:')
      ..writeln('    run: melos exec -- "flutter build web"')
      ..writeln('    description: 构建Web应用')
      ..writeln('    packageFilters:')
      ..writeln('      scope: "apps/*"')
      ..writeln();
  }

  /// 添加依赖管理脚本
  void _addDependencyScripts(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  # === 依赖管理脚本 ===')
      ..writeln()
      ..writeln('  # 📋 依赖列表')
      ..writeln('  deps:')
      ..writeln('    run: melos list --long')
      ..writeln('    description: 显示所有包及其依赖')
      ..writeln()
      ..writeln('  # 🔄 更新依赖')
      ..writeln('  upgrade:')
      ..writeln('    run: melos exec -- "flutter pub upgrade"')
      ..writeln('    description: 更新所有包的依赖')
      ..writeln()
      ..writeln('  # 🔍 依赖检查')
      ..writeln('  deps-check:')
      ..writeln('    run: melos exec -- "flutter pub deps"')
      ..writeln('    description: 检查依赖关系')
      ..writeln()
      ..writeln('  # 🧹 依赖清理')
      ..writeln('  deps-clean:')
      ..writeln('    run: |')
      ..writeln('      melos exec -- "flutter pub deps --style=compact"')
      ..writeln('      melos exec -- "flutter pub get --offline"')
      ..writeln('    description: 清理并重新获取依赖')
      ..writeln()
      ..writeln('  # 📊 依赖图')
      ..writeln('  deps-graph:')
      ..writeln('    run: melos graph')
      ..writeln('    description: 生成依赖关系图')
      ..writeln()
      ..writeln('  # 🚀 完整工作流')
      ..writeln('  workflow:')
      ..writeln('    run: |')
      ..writeln('      echo "🧹 清理项目..."')
      ..writeln('      melos clean')
      ..writeln('      echo "📦 获取依赖..."')
      ..writeln('      melos get')
      ..writeln('      echo "🔧 生成代码..."')
      ..writeln('      melos generate')
      ..writeln('      echo "📊 质量检查..."')
      ..writeln('      melos quality');

    if (config.includeTests) {
      buffer
        ..writeln('      echo "🧪 运行测试..."')
        ..writeln('      melos test');
    }

    buffer
      ..writeln('      echo "✅ 工作流完成！"')
      ..writeln('    description: 运行完整的开发工作流');
  }
}
