/*
---------------------------------------------------------------
File name:          template_create_command.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        模板创建CLI命令 (Template Create CLI Command)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 CLI命令集成;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/configuration_wizard.dart';
import 'package:ming_status_cli/src/core/template_creator/template_scaffold.dart';
import 'package:ming_status_cli/src/core/template_creator/template_validator.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板创建命令
///
/// 实现 `ming template create` 命令
class TemplateCreateCommand extends Command<int> {
  /// 创建模板创建命令实例
  TemplateCreateCommand() {
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help: '模板名称',
      )
      ..addOption(
        'type',
        abbr: 't',
        help: '模板类型',
        allowed: TemplateType.values.map((t) => t.name),
        allowedHelp: {
          for (final type in TemplateType.values) type.name: type.displayName,
        },
      )
      ..addOption(
        'author',
        abbr: 'a',
        help: '作者名称',
      )
      ..addOption(
        'description',
        abbr: 'd',
        help: '模板描述',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '输出目录',
        defaultsTo: '.',
      )
      ..addOption(
        'platform',
        abbr: 'p',
        help: '目标平台',
        allowed: TemplatePlatform.values.map((p) => p.name),
        defaultsTo: TemplatePlatform.crossPlatform.name,
        allowedHelp: {
          'web': 'Web平台',
          'mobile': '移动平台 (iOS/Android)',
          'desktop': '桌面平台 (Windows/macOS/Linux)',
          'server': '服务器端',
          'cloud': '云原生',
          'crossPlatform': '跨平台',
        },
      )
      ..addOption(
        'framework',
        abbr: 'f',
        help: '技术框架',
        allowed: TemplateFramework.values.map((f) => f.name),
        defaultsTo: TemplateFramework.agnostic.name,
        allowedHelp: {
          'flutter': 'Flutter框架',
          'dart': 'Dart原生',
          'react': 'React框架',
          'vue': 'Vue.js框架',
          'angular': 'Angular框架',
          'nodejs': 'Node.js',
          'springBoot': 'Spring Boot',
          'agnostic': '框架无关',
        },
      )
      ..addOption(
        'complexity',
        abbr: 'c',
        help: '模板复杂度',
        allowed: TemplateComplexity.values.map((c) => c.name),
        defaultsTo: TemplateComplexity.simple.name,
        allowedHelp: {
          'simple': '简单模板',
          'medium': '中等复杂度模板',
          'complex': '复杂模板',
          'enterprise': '企业级模板',
        },
      )
      ..addFlag(
        'wizard',
        abbr: 'w',
        help: '使用交互式向导',
      )
      ..addFlag(
        'no-tests',
        help: '不包含测试文件',
      )
      ..addFlag(
        'no-docs',
        help: '不包含文档',
      )
      ..addFlag(
        'no-examples',
        help: '不包含示例',
      )
      ..addFlag(
        'no-git',
        help: '不初始化Git仓库',
      )
      ..addFlag(
        'validate',
        abbr: 'v',
        help: '生成后验证模板',
        defaultsTo: true,
      )
      ..addFlag(
        'strict',
        help: '启用严格验证模式',
      );
  }

  @override
  String get name => 'create';

  @override
  String get description => '创建自定义模板';

  @override
  String get usage => '''
创建自定义模板

使用方法:
  ming template create [选项]

基础选项:
  -n, --name=<名称>          模板名称 (必需)
  -t, --type=<类型>          模板类型 (可选值见下方)
  -a, --author=<作者>        作者名称
  -d, --description=<描述>   模板描述
  -o, --output=<目录>        输出目录 (默认: .)

模板类型 (-t, --type):
  ui                         UI组件 - 用户界面组件、页面和交互元素
  service                    业务服务 - 业务逻辑、API服务和第三方集成
  data                       数据层 - 数据模型、仓库模式和持久化层
  full                       完整应用 - 完整的应用程序、包和库
  system                     系统配置 - 系统配置、基础设施和部署脚本
  basic                      基础模板 - 基础模板和起始项目
  micro                      微服务 - 微服务架构组件和分布式系统
  plugin                     插件系统 - 可扩展插件、中间件和工具
  infrastructure             基础设施 - 容器化、监控、安全和运维工具

复杂度级别 (-c, --complexity):
  simple                     简单模板 (默认)
  medium                     中等复杂度模板
  complex                    复杂模板
  enterprise                 企业级模板

目标平台 (-p, --platform):
  web                        Web平台
  mobile                     移动平台 (iOS/Android)
  desktop                    桌面平台 (Windows/macOS/Linux)
  server                     服务器端
  cloud                      云原生
  crossPlatform              跨平台 (默认)

技术框架 (-f, --framework):
  flutter                    Flutter框架
  dart                       Dart原生
  react                      React框架
  vue                        Vue.js框架
  angular                    Angular框架
  nodejs                     Node.js
  springBoot                 Spring Boot
  agnostic                   框架无关 (默认)

内容选项:
      --no-tests             不包含测试文件
      --no-docs              不包含文档
      --no-examples          不包含示例
      --no-git               不初始化Git仓库

验证选项:
  -v, --[no-]validate        生成后验证模板 (默认: on)
      --strict               启用严格验证模式

交互选项:
  -w, --wizard               使用交互式向导

示例:
  # 使用交互式向导
  ming template create --wizard

  # 快速创建UI组件模板
  ming template create --name my_widget --type ui --author "John Doe"

  # 创建完整Flutter应用模板
  ming template create -n my_app -t full -a "Team" -d "Flutter应用模板" -p mobile -f flutter

  # 创建企业级微服务模板
  ming template create --name api_service --type micro --complexity enterprise --framework dart --no-examples

  # 创建基础模板并跳过验证
  ming template create -n simple -t basic -a "Dev" -d "简单模板" --no-validate

  # 创建云原生基础设施模板
  ming template create -n k8s_deploy -t infrastructure -c complex -p cloud -f agnostic

更多信息:
  使用 'ming help template create' 查看详细文档
''';

  @override
  Future<int> run() async {
    try {
      // 显示友好的开始信息
      print('\n🚀 Ming Status CLI - 模板创建工具');
      print('═' * 50);
      cli_logger.Logger.info('开始创建模板');

      ScaffoldConfig? config;

      // 检查是否使用向导模式
      if (argResults!['wizard'] as bool) {
        print('\n🧙‍♂️ 启动向导模式...');
        config = await _runWizard();
      } else {
        print('\n📋 解析命令行参数...');
        config = await _parseArguments();
      }

      if (config == null) {
        print('\n❌ 模板创建已取消');
        cli_logger.Logger.warning('模板创建已取消');
        return 1;
      }

      // 显示配置摘要
      _printConfigSummary(config);

      // 生成模板脚手架
      print('\n⚙️ 正在生成模板脚手架...');
      final scaffold = TemplateScaffold();
      final result = await scaffold.generateScaffold(config);

      if (!result.success) {
        print('\n💥 模板创建失败');
        cli_logger.Logger.error('模板创建失败');
        for (final error in result.errors) {
          print('  ❌ $error');
          cli_logger.Logger.error('  - $error');
        }
        _printTroubleshootingTips();
        return 1;
      }

      // 显示生成结果
      _printGenerationResult(result);

      // 验证模板
      if (argResults!['validate'] as bool) {
        print('\n🔍 正在验证生成的模板...');
        await _validateTemplate(result.templatePath);
      }

      print('\n🎉 模板创建完成！');
      cli_logger.Logger.success('模板创建完成: ${result.templatePath}');
      return 0;
    } catch (e) {
      print('\n💥 模板创建过程中发生错误');
      print('错误详情: $e');
      _printTroubleshootingTips();
      cli_logger.Logger.error('模板创建失败', error: e);
      return 1;
    }
  }

  /// 显示配置摘要
  void _printConfigSummary(ScaffoldConfig config) {
    print('\n📋 模板配置摘要');
    print('─' * 40);
    print('📝 名称: ${config.templateName}');
    print('🏷️  类型: ${config.templateType.name}');
    print('🏗️  框架: ${config.framework.name}');
    print('📱 平台: ${config.platform.name}');
    print('⚡ 复杂度: ${config.complexity.name}');
    print('👤 作者: ${config.author}');
    print('📄 描述: ${config.description}');
    print('📂 输出路径: ${config.outputPath}');

    final features = <String>[];
    if (config.includeTests) features.add('测试');
    if (config.includeDocumentation) features.add('文档');
    if (config.includeExamples) features.add('示例');
    if (config.enableGitInit) features.add('Git');

    if (features.isNotEmpty) {
      print('✨ 功能: ${features.join(', ')}');
    }
  }

  /// 显示故障排除提示
  void _printTroubleshootingTips() {
    print('\n🔧 故障排除提示:');
    print('─' * 30);
    print('1. 检查模板名称是否符合规范 (字母开头，只含字母数字下划线)');
    print('2. 确保输出目录有写入权限');
    print('3. 检查磁盘空间是否充足');
    print('4. 尝试使用 --wizard 模式重新创建');
    print('5. 查看详细日志: ming template create --help');
    print('\n💡 需要帮助？运行: ming help template create');
  }

  /// 运行配置向导
  Future<ScaffoldConfig?> _runWizard() async {
    final wizard = ConfigurationWizard();
    return wizard.runWizard();
  }

  /// 解析命令行参数
  Future<ScaffoldConfig?> _parseArguments() async {
    final name = argResults!['name'] as String?;
    final typeStr = argResults!['type'] as String?;
    final author = argResults!['author'] as String?;
    final description = argResults!['description'] as String?;

    // 验证必需参数
    if (name == null || name.isEmpty) {
      cli_logger.Logger.error('模板名称是必需的，请使用 --name 参数或 --wizard 模式');
      return null;
    }

    // 验证模板名称格式
    if (!_isValidTemplateName(name)) {
      cli_logger.Logger.error('模板名称格式无效: $name');
      cli_logger.Logger.info('模板名称只能包含字母、数字、下划线和连字符，且必须以字母开头');
      return null;
    }

    if (typeStr == null) {
      cli_logger.Logger.error('模板类型是必需的，请使用 --type 参数或 --wizard 模式');
      return null;
    }

    if (author == null || author.isEmpty) {
      cli_logger.Logger.error('作者名称是必需的，请使用 --author 参数或 --wizard 模式');
      return null;
    }

    if (description == null || description.isEmpty) {
      cli_logger.Logger.error('模板描述是必需的，请使用 --description 参数或 --wizard 模式');
      return null;
    }

    // 验证输出路径
    final outputPath = argResults!['output'] as String;
    if (!_isValidOutputPath(outputPath)) {
      cli_logger.Logger.error('输出路径无效或无权限访问: $outputPath');
      cli_logger.Logger.info('请确保输出路径存在且有写入权限');
      return null;
    }

    // 解析枚举值
    final templateType = TemplateType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => TemplateType.basic,
    );

    final platform = TemplatePlatform.values.firstWhere(
      (p) => p.name == argResults!['platform'],
      orElse: () => TemplatePlatform.crossPlatform,
    );

    final framework = TemplateFramework.values.firstWhere(
      (f) => f.name == argResults!['framework'],
      orElse: () => TemplateFramework.agnostic,
    );

    final complexity = TemplateComplexity.values.firstWhere(
      (c) => c.name == argResults!['complexity'],
      orElse: () => TemplateComplexity.simple,
    );

    return ScaffoldConfig(
      templateName: name,
      templateType: templateType,
      author: author,
      description: description,
      outputPath: argResults!['output'] as String,
      platform: platform,
      framework: framework,
      complexity: complexity,
      includeTests: !(argResults!['no-tests'] as bool),
      includeDocumentation: !(argResults!['no-docs'] as bool),
      includeExamples: !(argResults!['no-examples'] as bool),
      enableGitInit: !(argResults!['no-git'] as bool),
    );
  }

  /// 验证模板
  Future<void> _validateTemplate(String templatePath) async {
    cli_logger.Logger.info('验证生成的模板...');

    final validator = TemplateValidator(
      config: ValidationConfig(
        strictMode: argResults!['strict'] as bool,
      ),
    );

    final result = await validator.validateTemplate(templatePath);

    if (result.isValid) {
      cli_logger.Logger.success('模板验证通过');
    } else {
      cli_logger.Logger.warning('模板验证发现问题:');
    }

    // 显示验证结果
    _printValidationResult(result);
  }

  /// 打印生成结果
  void _printGenerationResult(ScaffoldResult result) {
    print('\n🎉 模板生成成功!');
    print('─' * 40);
    print('📁 模板路径: ${result.templatePath}');
    print('📄 生成文件: ${result.generatedFiles.length}个');

    if (result.generatedFiles.isNotEmpty) {
      print('\n生成的文件:');
      for (final file in result.generatedFiles) {
        print('  ✓ $file');
      }
    }

    if (result.warnings.isNotEmpty) {
      print('\n⚠️  警告:');
      for (final warning in result.warnings) {
        print('  - $warning');
      }
    }
  }

  /// 打印验证结果
  void _printValidationResult(TemplateValidationResult result) {
    if (result.issues.isEmpty) {
      print('  ✅ 没有发现问题');
      return;
    }

    // 按严重性分组显示
    final fatalErrors = result.issues
        .where((i) => i.severity == ValidationSeverity.fatal)
        .toList();
    final errors = result.issues
        .where((i) => i.severity == ValidationSeverity.error)
        .toList();
    final warnings = result.issues
        .where((i) => i.severity == ValidationSeverity.warning)
        .toList();
    final infos = result.issues
        .where((i) => i.severity == ValidationSeverity.info)
        .toList();

    if (fatalErrors.isNotEmpty) {
      print('\n💀 致命错误 (${fatalErrors.length}):');
      for (final issue in fatalErrors) {
        print('  - ${issue.message}');
        if (issue.suggestion != null) {
          print('    💡 建议: ${issue.suggestion}');
        }
      }
    }

    if (errors.isNotEmpty) {
      print('\n❌ 错误 (${errors.length}):');
      for (final issue in errors) {
        print('  - ${issue.message}');
        if (issue.suggestion != null) {
          print('    💡 建议: ${issue.suggestion}');
        }
      }
    }

    if (warnings.isNotEmpty) {
      print('\n⚠️  警告 (${warnings.length}):');
      for (final issue in warnings) {
        print('  - ${issue.message}');
        if (issue.suggestion != null) {
          print('    💡 建议: ${issue.suggestion}');
        }
      }
    }

    if (infos.isNotEmpty) {
      print('\nℹ️  信息 (${infos.length}):');
      for (final issue in infos) {
        print('  - ${issue.message}');
        if (issue.suggestion != null) {
          print('    💡 建议: ${issue.suggestion}');
        }
      }
    }

    if (result.recommendations.isNotEmpty) {
      print('\n🚀 优化建议:');
      for (final recommendation in result.recommendations) {
        print('  - $recommendation');
      }
    }

    // 显示验证摘要
    print('\n📊 验证摘要:');
    print('  总问题数: ${result.issues.length}');
    print('  致命错误: ${fatalErrors.length}');
    print('  错误: ${errors.length}');
    print('  警告: ${warnings.length}');
    print('  信息: ${infos.length}');
  }

  /// 验证模板名称格式
  bool _isValidTemplateName(String name) {
    // 模板名称只能包含字母、数字、下划线和连字符，且必须以字母开头
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$');
    return regex.hasMatch(name) && name.length <= 50;
  }

  /// 验证输出路径
  bool _isValidOutputPath(String outputPath) {
    try {
      final dir = Directory(outputPath);
      // 检查路径是否存在或可以创建
      if (dir.existsSync()) {
        return true;
      }
      // 尝试创建父目录来验证权限
      final parent = dir.parent;
      return parent.existsSync();
    } catch (e) {
      return false;
    }
  }
}
