/*
---------------------------------------------------------------
File name:          readme_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        README文档生成器 (README Documentation Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加更多文档模板
    - [ ] 支持多语言文档
    - [ ] 添加自动化文档更新
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/template_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// README文档生成器
///
/// 负责生成项目的README.md文档
class ReadmeGenerator extends TemplateGeneratorBase {
  /// 创建README生成器实例
  const ReadmeGenerator();

  @override
  String getTemplateFileName() => 'README.md.template';

  @override
  String getOutputFileName(ScaffoldConfig config) => 'README.md.template';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 项目标题和描述
    _addProjectHeader(buffer, config);

    // 徽章
    _addBadges(buffer, config);

    // 目录
    _addTableOfContents(buffer, config);

    // 项目描述
    _addProjectDescription(buffer, config);

    // 功能特性
    _addFeatures(buffer, config);

    // 快速开始
    _addQuickStart(buffer, config);

    // 安装说明
    _addInstallation(buffer, config);

    // 使用说明
    _addUsage(buffer, config);

    // API文档
    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      _addApiDocumentation(buffer, config);
    }

    // 开发指南
    _addDevelopmentGuide(buffer, config);

    // 测试
    if (config.includeTests) {
      _addTestingSection(buffer, config);
    }

    // 部署
    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      _addDeploymentSection(buffer, config);
    }

    // 贡献指南
    _addContributingSection(buffer, config);

    // 许可证
    _addLicenseSection(buffer, config);

    // 联系方式
    _addContactSection(buffer, config);

    return buffer.toString();
  }

  /// 添加项目标题和描述
  void _addProjectHeader(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('# ${config.templateName}')
      ..writeln()
      ..writeln(config.description)
      ..writeln();
  }

  /// 添加徽章
  void _addBadges(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 📊 项目状态')
      ..writeln()
      ..writeln(
          '[![Dart Version](https://img.shields.io/badge/dart-%3E%3D3.2.0-blue.svg)](https://dart.dev/)',)
      ..writeln(
          '[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)',)
      ..writeln(
          '[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)',);

    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln(
          '[![Flutter Version](https://img.shields.io/badge/flutter-%3E%3D3.16.0-blue.svg)](https://flutter.dev/)',);
    }

    if (config.includeTests) {
      buffer
        ..writeln(
            '[![codecov](https://codecov.io/gh/username/${config.templateName}/branch/main/graph/badge.svg)](https://codecov.io/gh/username/${config.templateName})',)
        ..writeln(
            '[![Tests](https://github.com/username/${config.templateName}/workflows/Tests/badge.svg)](https://github.com/username/${config.templateName}/actions)',);
    }

    buffer.writeln();
  }

  /// 添加目录
  void _addTableOfContents(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 📋 目录')
      ..writeln()
      ..writeln('- [项目描述](#-项目描述)')
      ..writeln('- [功能特性](#-功能特性)')
      ..writeln('- [快速开始](#-快速开始)')
      ..writeln('- [安装说明](#-安装说明)')
      ..writeln('- [使用说明](#-使用说明)');

    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('- [API文档](#-api文档)');
    }

    buffer.writeln('- [开发指南](#-开发指南)');

    if (config.includeTests) {
      buffer.writeln('- [测试](#-测试)');
    }

    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('- [部署](#-部署)');
    }

    buffer
      ..writeln('- [贡献指南](#-贡献指南)')
      ..writeln('- [许可证](#-许可证)')
      ..writeln('- [联系方式](#-联系方式)')
      ..writeln();
  }

  /// 添加项目描述
  void _addProjectDescription(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 📖 项目描述')
      ..writeln()
      ..writeln(config.description)
      ..writeln()
      ..writeln(
          '这是一个基于${_getFrameworkName(config.framework)}的${_getComplexityDescription(config.complexity)}项目，',)
      ..writeln('支持${_getPlatformDescription(config.platform)}平台。')
      ..writeln();
  }

  /// 添加功能特性
  void _addFeatures(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## ✨ 功能特性')
      ..writeln();

    final features = _getFeatures(config);
    for (final feature in features) {
      buffer.writeln('- $feature');
    }

    buffer.writeln();
  }

  /// 添加快速开始
  void _addQuickStart(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 🚀 快速开始')
      ..writeln()
      ..writeln('### 前置要求')
      ..writeln();

    if (config.framework == TemplateFramework.flutter) {
      buffer
        ..writeln('- [Flutter](https://flutter.dev/) >= 3.16.0')
        ..writeln('- [Dart](https://dart.dev/) >= 3.2.0');
    } else {
      buffer.writeln('- [Dart](https://dart.dev/) >= 3.2.0');
    }

    buffer
      ..writeln('- Git')
      ..writeln()
      ..writeln('### 克隆项目')
      ..writeln()
      ..writeln('```bash')
      ..writeln(
          'git clone https://github.com/username/${config.templateName}.git',)
      ..writeln('cd ${config.templateName}')
      ..writeln('```')
      ..writeln();
  }

  /// 添加安装说明
  void _addInstallation(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 📦 安装说明')
      ..writeln()
      ..writeln('### 1. 安装依赖')
      ..writeln()
      ..writeln('```bash');

    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('flutter pub get');
    } else {
      buffer.writeln('dart pub get');
    }

    buffer
      ..writeln('```')
      ..writeln();

    // 根据复杂度添加额外的安装步骤
    if (config.complexity == TemplateComplexity.medium ||
        config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      buffer
        ..writeln('### 2. 生成代码')
        ..writeln()
        ..writeln('```bash')
        ..writeln('dart run build_runner build')
        ..writeln('```')
        ..writeln();
    }

    if (config.complexity == TemplateComplexity.enterprise) {
      buffer
        ..writeln('### 3. 配置环境变量')
        ..writeln()
        ..writeln('复制环境变量模板文件：')
        ..writeln()
        ..writeln('```bash')
        ..writeln('cp .env.example .env')
        ..writeln('```')
        ..writeln()
        ..writeln('编辑 `.env` 文件，填入相应的配置信息。')
        ..writeln();
    }
  }

  /// 添加使用说明
  void _addUsage(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 🎯 使用说明')
      ..writeln();

    if (config.framework == TemplateFramework.flutter) {
      buffer
        ..writeln('### 运行应用')
        ..writeln()
        ..writeln('```bash')
        ..writeln('flutter run')
        ..writeln('```')
        ..writeln();

      if (config.platform == TemplatePlatform.web ||
          config.platform == TemplatePlatform.crossPlatform) {
        buffer
          ..writeln('### Web版本')
          ..writeln()
          ..writeln('```bash')
          ..writeln('flutter run -d chrome')
          ..writeln('```')
          ..writeln();
      }
    } else {
      buffer
        ..writeln('### 运行程序')
        ..writeln()
        ..writeln('```bash')
        ..writeln('dart run')
        ..writeln('```')
        ..writeln();
    }

    // 添加具体的使用示例
    _addUsageExamples(buffer, config);
  }

  /// 添加使用示例
  void _addUsageExamples(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('### 基本用法')
      ..writeln()
      ..writeln('```dart')
      ..writeln(
          "import 'package:${config.templateName}/${config.templateName}.dart';",)
      ..writeln()
      ..writeln('void main() {')
      ..writeln('  // 创建应用实例')
      ..writeln('  final app = ${_toClassName(config.templateName)}();')
      ..writeln('  ')
      ..writeln('  // 运行应用')
      ..writeln('  app.run();')
      ..writeln('}')
      ..writeln('```')
      ..writeln();
  }

  /// 添加API文档
  void _addApiDocumentation(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 📚 API文档')
      ..writeln()
      ..writeln('### 核心API')
      ..writeln()
      ..writeln('详细的API文档请参考：')
      ..writeln()
      ..writeln('- [在线文档](https://username.github.io/${config.templateName}/)')
      ..writeln('- [API参考](./docs/api/)')
      ..writeln()
      ..writeln('### 生成文档')
      ..writeln()
      ..writeln('```bash')
      ..writeln('dart doc')
      ..writeln('```')
      ..writeln();
  }

  /// 添加开发指南
  void _addDevelopmentGuide(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 🛠️ 开发指南')
      ..writeln()
      ..writeln('### 项目结构')
      ..writeln()
      ..writeln('```')
      ..writeln('${config.templateName}/')
      ..writeln('├── lib/                 # 源代码')
      ..writeln('│   ├── src/            # 核心代码')
      ..writeln('│   └── ${config.templateName}.dart  # 主入口')
      ..writeln('├── test/               # 测试文件')
      ..writeln('├── docs/               # 文档')
      ..writeln('├── example/            # 示例代码')
      ..writeln('└── pubspec.yaml        # 项目配置')
      ..writeln('```')
      ..writeln()
      ..writeln('### 代码规范')
      ..writeln()
      ..writeln(
          '项目遵循 [Dart 官方代码规范](https://dart.dev/guides/language/effective-dart)。',)
      ..writeln()
      ..writeln('运行代码检查：')
      ..writeln()
      ..writeln('```bash')
      ..writeln('dart analyze')
      ..writeln('```')
      ..writeln()
      ..writeln('格式化代码：')
      ..writeln()
      ..writeln('```bash')
      ..writeln('dart format .')
      ..writeln('```')
      ..writeln();
  }

  /// 添加测试部分
  void _addTestingSection(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 🧪 测试')
      ..writeln()
      ..writeln('### 运行测试')
      ..writeln()
      ..writeln('```bash');

    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('flutter test');
    } else {
      buffer.writeln('dart test');
    }

    buffer
      ..writeln('```')
      ..writeln()
      ..writeln('### 测试覆盖率')
      ..writeln()
      ..writeln('```bash');

    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('flutter test --coverage');
    } else {
      buffer.writeln('dart test --coverage=coverage');
    }

    buffer
      ..writeln('```')
      ..writeln()
      ..writeln('### 查看覆盖率报告')
      ..writeln()
      ..writeln('```bash')
      ..writeln('genhtml coverage/lcov.info -o coverage/html')
      ..writeln('open coverage/html/index.html')
      ..writeln('```')
      ..writeln();
  }

  /// 添加部署部分
  void _addDeploymentSection(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 🚀 部署')
      ..writeln();

    if (config.framework == TemplateFramework.flutter) {
      if (config.platform == TemplatePlatform.web ||
          config.platform == TemplatePlatform.crossPlatform) {
        buffer
          ..writeln('### Web部署')
          ..writeln()
          ..writeln('```bash')
          ..writeln('flutter build web')
          ..writeln('```')
          ..writeln();
      }

      if (config.platform == TemplatePlatform.mobile ||
          config.platform == TemplatePlatform.crossPlatform) {
        buffer
          ..writeln('### 移动端构建')
          ..writeln()
          ..writeln('#### Android')
          ..writeln('```bash')
          ..writeln('flutter build apk --release')
          ..writeln('```')
          ..writeln()
          ..writeln('#### iOS')
          ..writeln('```bash')
          ..writeln('flutter build ios --release')
          ..writeln('```')
          ..writeln();
      }
    } else {
      buffer
        ..writeln('### 编译可执行文件')
        ..writeln()
        ..writeln('```bash')
        ..writeln('dart compile exe bin/${config.templateName}.dart')
        ..writeln('```')
        ..writeln();
    }
  }

  /// 添加贡献指南
  void _addContributingSection(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 🤝 贡献指南')
      ..writeln()
      ..writeln('我们欢迎所有形式的贡献！请阅读 [贡献指南](CONTRIBUTING.md) 了解详情。')
      ..writeln()
      ..writeln('### 提交流程')
      ..writeln()
      ..writeln('1. Fork 本仓库')
      ..writeln('2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)')
      ..writeln("3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)")
      ..writeln('4. 推送到分支 (`git push origin feature/AmazingFeature`)')
      ..writeln('5. 创建 Pull Request')
      ..writeln();
  }

  /// 添加许可证部分
  void _addLicenseSection(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 📄 许可证')
      ..writeln()
      ..writeln('本项目基于 MIT 许可证开源 - 查看 [LICENSE](LICENSE) 文件了解详情。')
      ..writeln();
  }

  /// 添加联系方式
  void _addContactSection(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('## 📞 联系方式')
      ..writeln()
      ..writeln('**${config.author}**')
      ..writeln()
      ..writeln(
          '- 项目链接: [https://github.com/username/${config.templateName}](https://github.com/username/${config.templateName})',)
      ..writeln(
          '- 问题反馈: [https://github.com/username/${config.templateName}/issues](https://github.com/username/${config.templateName}/issues)',)
      ..writeln()
      ..writeln('---')
      ..writeln()
      ..writeln('⭐ 如果这个项目对你有帮助，请给它一个星标！')
      ..writeln();
  }

  /// 获取框架名称
  String _getFrameworkName(TemplateFramework framework) {
    switch (framework) {
      case TemplateFramework.flutter:
        return 'Flutter';
      case TemplateFramework.dart:
        return 'Dart';
      case TemplateFramework.react:
        return 'React';
      case TemplateFramework.vue:
        return 'Vue';
      case TemplateFramework.angular:
        return 'Angular';
      case TemplateFramework.nodejs:
        return 'Node.js';
      case TemplateFramework.springBoot:
        return 'Spring Boot';
      case TemplateFramework.agnostic:
        return '框架无关';
    }
  }

  /// 获取复杂度描述
  String _getComplexityDescription(TemplateComplexity complexity) {
    switch (complexity) {
      case TemplateComplexity.simple:
        return '简单';
      case TemplateComplexity.medium:
        return '中等复杂度';
      case TemplateComplexity.complex:
        return '复杂';
      case TemplateComplexity.enterprise:
        return '企业级';
    }
  }

  /// 获取平台描述
  String _getPlatformDescription(TemplatePlatform platform) {
    switch (platform) {
      case TemplatePlatform.mobile:
        return '移动端';
      case TemplatePlatform.web:
        return 'Web';
      case TemplatePlatform.desktop:
        return '桌面端';
      case TemplatePlatform.server:
        return '服务器';
      case TemplatePlatform.crossPlatform:
        return '跨平台';
      case TemplatePlatform.cloud:
        return '云端';
    }
  }

  /// 获取功能特性列表
  List<String> _getFeatures(ScaffoldConfig config) {
    final features = <String>['🎯 现代化的${_getFrameworkName(config.framework)}架构',
        '📱 支持${_getPlatformDescription(config.platform)}',
        '🎨 Material Design 3.0 设计语言',]

      // 基础特性
      ;

    // 根据复杂度添加特性
    if (config.complexity == TemplateComplexity.medium ||
        config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      features.addAll([
        '🌍 国际化支持',
        '🎭 状态管理 (Riverpod)',
        '🛣️ 声明式路由 (GoRouter)',
      ]);
    }

    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      features.addAll([
        '🔐 用户认证',
        '📡 网络请求 (Dio)',
        '💾 本地存储',
        '🔄 代码生成 (build_runner)',
      ]);
    }

    if (config.complexity == TemplateComplexity.enterprise) {
      features.addAll([
        '☁️ 云服务集成',
        '📊 数据分析',
        '🚨 错误监控',
        '🔧 CI/CD 支持',
      ]);
    }

    if (config.includeTests) {
      features.add('🧪 完整的测试覆盖');
    }

    return features;
  }

  /// 转换为类名格式
  String _toClassName(String name) {
    return name
        .split(RegExp('[^a-zA-Z0-9]'))
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase(),)
        .join();
  }
}
