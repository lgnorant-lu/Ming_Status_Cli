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


import 'package:args/command_runner.dart';
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
      )
      ..addOption(
        'framework',
        abbr: 'f',
        help: '技术框架',
        allowed: TemplateFramework.values.map((f) => f.name),
        defaultsTo: TemplateFramework.agnostic.name,
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
使用方法:
  ming template create [选项]

示例:
  # 使用交互式向导
  ming template create --wizard

  # 快速创建UI组件模板
  ming template create --name my_widget --type ui --author "John Doe"

  # 创建完整应用模板
  ming template create -n my_app -t full -a "Team" -d "Flutter应用模板" -p mobile

  # 创建微服务模板
  ming template create --name api_service --type micro --framework dart --no-examples
''';

  @override
  Future<int> run() async {
    try {
      cli_logger.Logger.info('开始创建模板');

      ScaffoldConfig? config;

      // 检查是否使用向导模式
      if (argResults!['wizard'] as bool) {
        config = await _runWizard();
      } else {
        config = await _parseArguments();
      }

      if (config == null) {
        cli_logger.Logger.warning('模板创建已取消');
        return 1;
      }

      // 生成模板脚手架
      final scaffold = TemplateScaffold();
      final result = await scaffold.generateScaffold(config);

      if (!result.success) {
        cli_logger.Logger.error('模板创建失败');
        for (final error in result.errors) {
          cli_logger.Logger.error('  - $error');
        }
        return 1;
      }

      // 显示生成结果
      _printGenerationResult(result);

      // 验证模板
      if (argResults!['validate'] as bool) {
        await _validateTemplate(result.templatePath);
      }

      cli_logger.Logger.success('模板创建完成: ${result.templatePath}');
      return 0;
    } catch (e) {
      cli_logger.Logger.error('模板创建失败', error: e);
      return 1;
    }
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

    return ScaffoldConfig(
      templateName: name,
      templateType: templateType,
      author: author,
      description: description,
      outputPath: argResults!['output'] as String,
      platform: platform,
      framework: framework,
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
}
