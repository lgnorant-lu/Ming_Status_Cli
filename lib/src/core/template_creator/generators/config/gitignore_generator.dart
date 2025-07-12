/*
---------------------------------------------------------------
File name:          gitignore_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        .gitignore配置文件生成器 (Gitignore Configuration Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/config/config_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// .gitignore配置文件生成器
///
/// 负责生成Git版本控制忽略文件配置
class GitignoreGenerator extends ConfigGeneratorBase {
  /// 创建.gitignore生成器实例
  const GitignoreGenerator();

  @override
  String getFileName() => '.gitignore';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer()
      ..writeln('# ${config.templateName} - Git忽略文件')
      ..writeln('# 生成时间: ${TemplateConstants.currentDate}')
      ..writeln('# 更多信息: https://git-scm.com/docs/gitignore')
      ..writeln()
      ..writeln('# === Dart/Flutter 核心文件 ===')
      ..writeln()
      ..writeln('# Dart工具生成的文件')
      ..writeln('.dart_tool/')
      ..writeln('.packages')
      ..writeln('build/')
      ..writeln('pubspec.lock')
      ..writeln()
      ..writeln('# 代码生成文件')
      ..writeln('*.g.dart')
      ..writeln('*.freezed.dart')
      ..writeln('*.gr.dart')
      ..writeln('*.config.dart')
      ..writeln('*.mocks.dart')
      ..writeln('lib/generated/')
      ..writeln()
      ..writeln('# 测试覆盖率')
      ..writeln('coverage/')
      ..writeln('test/coverage/')
      ..writeln('lcov.info')
      ..writeln()
      ..writeln('# Flutter特定文件')
      ..writeln('.flutter-plugins')
      ..writeln('.flutter-plugins-dependencies')
      ..writeln('.metadata')
      ..writeln();

    // Flutter平台特定忽略
    if (config.framework == TemplateFramework.flutter) {
      _addFlutterPlatformIgnores(buffer, config);
    }

    // IDE和编辑器文件
    _addIDEIgnores(buffer);

    // 操作系统文件
    _addOSIgnores(buffer);

    // 开发工具文件
    _addDevelopmentToolIgnores(buffer, config);

    // 部署和CI/CD文件
    _addDeploymentIgnores(buffer, config);

    // 安全和敏感文件
    _addSecurityIgnores(buffer, config);

    // 临时和缓存文件
    _addTemporaryIgnores(buffer);

    // 项目特定忽略
    _addProjectSpecificIgnores(buffer, config);

    return buffer.toString();
  }

  /// 添加Flutter平台特定忽略
  void _addFlutterPlatformIgnores(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('# === Flutter 平台特定文件 ===')
      ..writeln();

    // Android
    if (_supportsPlatform(config, TemplatePlatform.mobile) ||
        _supportsPlatform(config, TemplatePlatform.crossPlatform)) {
      buffer
        ..writeln('# Android')
        ..writeln('android/.gradle/')
        ..writeln('android/app/debug/')
        ..writeln('android/app/profile/')
        ..writeln('android/app/release/')
        ..writeln('android/gradle.properties')
        ..writeln('android/local.properties')
        ..writeln('android/key.properties')
        ..writeln('android/app/upload-keystore.jks')
        ..writeln('android/.project')
        ..writeln('android/.classpath')
        ..writeln('android/.settings/')
        ..writeln();
    }

    // iOS
    if (_supportsPlatform(config, TemplatePlatform.mobile) ||
        _supportsPlatform(config, TemplatePlatform.crossPlatform)) {
      buffer
        ..writeln('# iOS')
        ..writeln('ios/Flutter/flutter_export_environment.sh')
        ..writeln('ios/Pods/')
        ..writeln('ios/.symlinks/')
        ..writeln(
            'ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings',)
        ..writeln('ios/Runner/GoogleService-Info.plist')
        ..writeln('ios/firebase_app_id_file.json')
        ..writeln();
    }

    // Web
    if (_supportsPlatform(config, TemplatePlatform.web) ||
        _supportsPlatform(config, TemplatePlatform.crossPlatform)) {
      buffer
        ..writeln('# Web')
        ..writeln('web/favicon.png')
        ..writeln('web/icons/Icon-192.png')
        ..writeln('web/icons/Icon-512.png')
        ..writeln('web/icons/Icon-maskable-192.png')
        ..writeln('web/icons/Icon-maskable-512.png')
        ..writeln();
    }

    // Desktop
    if (_supportsPlatform(config, TemplatePlatform.desktop) ||
        _supportsPlatform(config, TemplatePlatform.crossPlatform)) {
      buffer
        ..writeln('# Desktop')
        ..writeln('macos/Flutter/ephemeral/')
        ..writeln('windows/flutter/ephemeral/')
        ..writeln('linux/flutter/ephemeral/')
        ..writeln();
    }
  }

  /// 添加IDE和编辑器忽略
  void _addIDEIgnores(StringBuffer buffer) {
    buffer
      ..writeln('# === IDE 和编辑器文件 ===')
      ..writeln()
      ..writeln('# Visual Studio Code')
      ..writeln('.vscode/')
      ..writeln('!.vscode/settings.json')
      ..writeln('!.vscode/tasks.json')
      ..writeln('!.vscode/launch.json')
      ..writeln('!.vscode/extensions.json')
      ..writeln()
      ..writeln('# IntelliJ IDEA / Android Studio')
      ..writeln('.idea/')
      ..writeln('*.iml')
      ..writeln('*.ipr')
      ..writeln('*.iws')
      ..writeln('.idea_modules/')
      ..writeln()
      ..writeln('# Sublime Text')
      ..writeln('*.sublime-workspace')
      ..writeln('*.sublime-project')
      ..writeln()
      ..writeln('# Vim')
      ..writeln('*.swp')
      ..writeln('*.swo')
      ..writeln('*~')
      ..writeln()
      ..writeln('# Emacs')
      ..writeln('*~')
      ..writeln(r'\#*\#')
      ..writeln('/.emacs.desktop')
      ..writeln('/.emacs.desktop.lock')
      ..writeln('*.elc')
      ..writeln('auto-save-list')
      ..writeln('tramp')
      ..writeln();
  }

  /// 添加操作系统文件忽略
  void _addOSIgnores(StringBuffer buffer) {
    buffer
      ..writeln('# === 操作系统文件 ===')
      ..writeln()
      ..writeln('# macOS')
      ..writeln('.DS_Store')
      ..writeln('.AppleDouble')
      ..writeln('.LSOverride')
      ..writeln('Icon')
      ..writeln('._*')
      ..writeln('.DocumentRevisions-V100')
      ..writeln('.fseventsd')
      ..writeln('.Spotlight-V100')
      ..writeln('.TemporaryItems')
      ..writeln('.Trashes')
      ..writeln('.VolumeIcon.icns')
      ..writeln('.com.apple.timemachine.donotpresent')
      ..writeln()
      ..writeln('# Windows')
      ..writeln('Thumbs.db')
      ..writeln('Thumbs.db:encryptable')
      ..writeln('ehthumbs.db')
      ..writeln('ehthumbs_vista.db')
      ..writeln('*.stackdump')
      ..writeln('[Dd]esktop.ini')
      ..writeln(r'$RECYCLE.BIN/')
      ..writeln('*.cab')
      ..writeln('*.msi')
      ..writeln('*.msix')
      ..writeln('*.msm')
      ..writeln('*.msp')
      ..writeln('*.lnk')
      ..writeln()
      ..writeln('# Linux')
      ..writeln('*~')
      ..writeln('.fuse_hidden*')
      ..writeln('.directory')
      ..writeln('.Trash-*')
      ..writeln('.nfs*')
      ..writeln();
  }

  /// 添加开发工具忽略
  void _addDevelopmentToolIgnores(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('# === 开发工具文件 ===')
      ..writeln()
      ..writeln('# Melos')
      ..writeln('.melos_tool/')
      ..writeln('melos_bootstrap.log')
      ..writeln()
      ..writeln('# Shorebird')
      ..writeln('.shorebird/')
      ..writeln('shorebird.log')
      ..writeln()
      ..writeln('# FVM (Flutter Version Management)')
      ..writeln('.fvm/')
      ..writeln()
      ..writeln('# Mason')
      ..writeln('.mason/')
      ..writeln()
      ..writeln('# Very Good CLI')
      ..writeln('.vgv/')
      ..writeln();

    // 企业级工具
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer
        ..writeln('# 企业级工具')
        ..writeln('.sonarqube/')
        ..writeln('.scannerwork/')
        ..writeln('sonar-project.properties')
        ..writeln('.codecov.yml')
        ..writeln();
    }
  }

  /// 添加部署和CI/CD忽略
  void _addDeploymentIgnores(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('# === 部署和CI/CD文件 ===')
      ..writeln()
      ..writeln('# Docker')
      ..writeln('.dockerignore')
      ..writeln('Dockerfile.dev')
      ..writeln('docker-compose.override.yml')
      ..writeln()
      ..writeln('# Kubernetes')
      ..writeln('k8s/secrets/')
      ..writeln('*.kubeconfig')
      ..writeln()
      ..writeln('# Terraform')
      ..writeln('*.tfstate')
      ..writeln('*.tfstate.*')
      ..writeln('.terraform/')
      ..writeln('.terraform.lock.hcl')
      ..writeln('terraform.tfvars')
      ..writeln('terraform.tfvars.json')
      ..writeln();

    // Firebase部署
    if (config.tags.contains('firebase')) {
      buffer
        ..writeln('# Firebase')
        ..writeln('.firebase/')
        ..writeln('firebase-debug.log')
        ..writeln('firebase-debug.*.log')
        ..writeln('firestore-debug.log')
        ..writeln('ui-debug.log')
        ..writeln();
    }
  }

  /// 添加安全和敏感文件忽略
  void _addSecurityIgnores(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('# === 安全和敏感文件 ===')
      ..writeln()
      ..writeln('# 环境变量')
      ..writeln('.env')
      ..writeln('.env.local')
      ..writeln('.env.development')
      ..writeln('.env.test')
      ..writeln('.env.production')
      ..writeln('.env.staging')
      ..writeln()
      ..writeln('# 密钥和证书')
      ..writeln('*.pem')
      ..writeln('*.key')
      ..writeln('*.p12')
      ..writeln('*.keystore')
      ..writeln('*.jks')
      ..writeln('google-services.json')
      ..writeln('GoogleService-Info.plist')
      ..writeln()
      ..writeln('# API密钥')
      ..writeln('api_keys.dart')
      ..writeln('secrets.dart')
      ..writeln('config/secrets/')
      ..writeln()
      ..writeln('# 数据库')
      ..writeln('*.db')
      ..writeln('*.sqlite')
      ..writeln('*.sqlite3')
      ..writeln('database.json')
      ..writeln();
  }

  /// 添加临时和缓存文件忽略
  void _addTemporaryIgnores(StringBuffer buffer) {
    buffer
      ..writeln('# === 临时和缓存文件 ===')
      ..writeln()
      ..writeln('# 日志文件')
      ..writeln('*.log')
      ..writeln('logs/')
      ..writeln('npm-debug.log*')
      ..writeln('yarn-debug.log*')
      ..writeln('yarn-error.log*')
      ..writeln()
      ..writeln('# 缓存目录')
      ..writeln('node_modules/')
      ..writeln('.npm')
      ..writeln('.yarn/')
      ..writeln('.pnp')
      ..writeln('.pnp.js')
      ..writeln()
      ..writeln('# 临时文件')
      ..writeln('*.tmp')
      ..writeln('*.temp')
      ..writeln('*.bak')
      ..writeln('*.backup')
      ..writeln('*~')
      ..writeln()
      ..writeln('# 压缩文件')
      ..writeln('*.zip')
      ..writeln('*.tar.gz')
      ..writeln('*.rar')
      ..writeln('*.7z')
      ..writeln();
  }

  /// 添加项目特定忽略
  void _addProjectSpecificIgnores(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('# === 项目特定文件 ===')
      ..writeln()
      ..writeln('# 文档生成')
      ..writeln('doc/api/')
      ..writeln('dartdoc_options.yaml')
      ..writeln()
      ..writeln('# 性能分析')
      ..writeln('*.trace')
      ..writeln('*.timeline')
      ..writeln('*.profile')
      ..writeln()
      ..writeln('# 自定义忽略')
      ..writeln('# 在此添加项目特定的忽略规则')
      ..writeln();

    // 根据模板类型添加特定忽略
    switch (config.templateType) {
      case TemplateType.plugin:
        buffer
          ..writeln('# Plugin特定')
          ..writeln('example/.flutter-plugins')
          ..writeln('example/.flutter-plugins-dependencies')
          ..writeln();
      case TemplateType.infrastructure:
        buffer
          ..writeln('# Infrastructure特定')
          ..writeln('infrastructure/secrets/')
          ..writeln('infrastructure/*.tfvars')
          ..writeln();
      default:
        break;
    }
  }

  /// 检查是否支持特定平台
  bool _supportsPlatform(ScaffoldConfig config, TemplatePlatform platform) {
    return config.platform == platform ||
        config.platform == TemplatePlatform.crossPlatform;
  }
}
