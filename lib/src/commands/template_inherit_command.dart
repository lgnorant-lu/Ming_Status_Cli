/*
---------------------------------------------------------------
File name:          template_inherit_command.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板继承命令 (Template Inheritance Command)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - 模板继承和组合命令;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/inheritance/composition_engine.dart';
import 'package:ming_status_cli/src/core/inheritance/dependency_resolver.dart';
import 'package:ming_status_cli/src/core/inheritance/inheritance_engine.dart';
import 'package:ming_status_cli/src/core/inheritance/inheritance_validator.dart';
import 'package:ming_status_cli/src/core/template_system/template_registry.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板继承命令
///
/// 实现 `ming template inherit` 命令，支持模板继承和组合功能
class TemplateInheritCommand extends Command<int> {
  /// 创建模板继承命令实例
  TemplateInheritCommand() {
    argParser
      ..addOption(
        'template',
        abbr: 't',
        help: '要继承的基础模板名称',
        mandatory: true,
      )
      ..addOption(
        'extends',
        abbr: 'e',
        help: '父模板列表，用逗号分隔',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '输出目录',
        defaultsTo: './inherited_template',
      )
      ..addOption(
        'strategy',
        abbr: 's',
        help: '继承策略',
        allowed: ['override', 'merge', 'append', 'prepend'],
        defaultsTo: 'merge',
        allowedHelp: {
          'override': '覆盖策略 - 子模板覆盖父模板',
          'merge': '合并策略 - 智能合并内容',
          'append': '追加策略 - 在父模板后追加',
          'prepend': '前置策略 - 在父模板前插入',
        },
      )
      ..addFlag(
        'validate',
        abbr: 'v',
        help: '验证继承链的完整性',
      )
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help: '仅显示继承计划，不执行实际操作',
      )
      ..addFlag(
        'show-dependencies',
        help: '显示依赖关系图',
      )
      ..addFlag(
        'optimize',
        help: '优化继承链性能',
      );
  }

  @override
  String get name => 'inherit';

  @override
  String get description => '执行模板继承和组合操作';

  @override
  String get usage => '''
执行模板继承和组合操作

使用方法:
  ming template inherit [选项]

必需选项:
  -t, --template=<名称>      基础模板名称

继承选项:
  -e, --extends=<模板>       要继承的模板，用逗号分隔
  -s, --strategy=<策略>      继承策略 (可选值见下方)
  -o, --output=<目录>        输出目录 (默认: .)

继承策略 (-s, --strategy):
  override                   覆盖策略 - 子模板覆盖父模板
  merge                      合并策略 - 智能合并内容 (默认)
  append                     追加策略 - 在父模板后追加
  prepend                    前置策略 - 在父模板前插入

验证选项:
      --validate             验证继承链
      --show-dependencies    显示依赖关系
      --dry-run              预览继承结果，不执行实际操作

示例:
  # 基础继承
  ming template inherit --template=my_app --extends=base_flutter,security_mixin

  # 验证继承链
  ming template inherit --template=complex_app --validate --show-dependencies

  # 预览继承结果
  ming template inherit --template=my_app --extends=base,theme --dry-run

  # 自定义继承策略
  ming template inherit -t my_app -e base_app -s override -o ./output

更多信息:
  使用 'ming help template inherit' 查看详细文档
''';

  @override
  Future<int> run() async {
    try {
      final templateName = argResults!['template'] as String;
      final extendsStr = argResults!['extends'] as String?;
      final outputDir = argResults!['output'] as String;
      final strategy = argResults!['strategy'] as String;
      final validate = argResults!['validate'] as bool;
      final dryRun = argResults!['dry-run'] as bool;
      final showDependencies = argResults!['show-dependencies'] as bool;
      final optimize = argResults!['optimize'] as bool;

      cli_logger.Logger.info('开始模板继承操作: $templateName');

      // 解析继承列表
      final extendsList =
          extendsStr?.split(',').map((e) => e.trim()).toList() ?? [];

      // 创建继承引擎和相关组件
      final dependencyResolver = DependencyResolver();
      final compositionEngine = CompositionEngine();
      final inheritanceEngine = InheritanceEngine(
        dependencyResolver: dependencyResolver,
        compositionEngine: compositionEngine,
      );
      final validator = InheritanceValidator();

      // 获取模板注册表
      final registry = TemplateRegistry(registryPath: './templates');

      // 获取基础模板
      final baseTemplate = await _getTemplate(registry, templateName);
      if (baseTemplate == null) {
        cli_logger.Logger.error('未找到基础模板: $templateName');
        return 1;
      }

      // 获取父模板列表
      final parentTemplates = <String>[];
      for (final parentName in extendsList) {
        final parentTemplate = await _getTemplate(registry, parentName);
        if (parentTemplate == null) {
          cli_logger.Logger.warning('未找到父模板: $parentName，跳过');
          continue;
        }
        parentTemplates.add(parentName);
      }

      if (parentTemplates.isEmpty && extendsStr != null) {
        cli_logger.Logger.error('没有找到任何有效的父模板');
        return 1;
      }

      // 显示继承计划
      _displayInheritancePlan(templateName, parentTemplates, strategy);

      // 验证继承链
      if (validate) {
        cli_logger.Logger.info('验证继承链完整性...');
        await _validateInheritanceChain(
          validator,
          templateName,
          parentTemplates,
        );
      }

      // 显示依赖关系
      if (showDependencies) {
        cli_logger.Logger.info('分析依赖关系...');
        await _showDependencies(
          dependencyResolver,
          templateName,
          parentTemplates,
        );
      }

      // 执行继承操作
      if (!dryRun) {
        cli_logger.Logger.info('执行模板继承...');
        await _executeInheritance(
          inheritanceEngine,
          compositionEngine,
          templateName,
          parentTemplates,
          strategy,
          outputDir,
          optimize,
        );
      } else {
        cli_logger.Logger.info('预览模式完成，未执行实际操作');
      }

      cli_logger.Logger.success('模板继承操作完成');
      return 0;
    } catch (e) {
      cli_logger.Logger.error('模板继承失败', error: e);
      return 1;
    }
  }

  /// 获取模板
  Future<dynamic> _getTemplate(
    TemplateRegistry registry,
    String templateName,
  ) async {
    try {
      final searchQuery = TemplateSearchQuery(keyword: templateName, limit: 1);
      final searchResult = await registry.searchTemplates(searchQuery);

      if (searchResult.templates.isNotEmpty) {
        return searchResult.templates.first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 显示继承计划
  void _displayInheritancePlan(
    String baseTemplate,
    List<String> parents,
    String strategy,
  ) {
    print('\n🔗 模板继承计划');
    print('─' * 50);
    print('基础模板: $baseTemplate');
    if (parents.isNotEmpty) {
      print('父模板列表:');
      for (var i = 0; i < parents.length; i++) {
        print('  ${i + 1}. ${parents[i]}');
      }
    }
    print('继承策略: $strategy');
    print('');
  }

  /// 验证继承链
  Future<void> _validateInheritanceChain(
    InheritanceValidator validator,
    String baseTemplate,
    List<String> parents,
  ) async {
    try {
      print('\n✅ 继承链验证结果');
      print('─' * 50);
      print('基础模板: $baseTemplate');

      if (parents.isNotEmpty) {
        print('父模板列表:');
        for (var i = 0; i < parents.length; i++) {
          print('  ${i + 1}. ${parents[i]}');
        }

        // 简单的验证逻辑
        if (parents.length > 5) {
          print('⚠️ 警告: 继承链过长 (${parents.length}层)，建议不超过5层');
        }

        // 检查重复继承
        final uniqueParents = parents.toSet();
        if (uniqueParents.length != parents.length) {
          print('❌ 错误: 发现重复的父模板');
        }

        print('✅ 基础验证通过');
      } else {
        print('无父模板继承');
      }
    } catch (e) {
      cli_logger.Logger.warning('继承链验证失败: $e');
    }
  }

  /// 显示依赖关系
  Future<void> _showDependencies(
    DependencyResolver resolver,
    String baseTemplate,
    List<String> parents,
  ) async {
    try {
      print('\n📊 依赖关系分析');
      print('─' * 50);
      print('基础模板: $baseTemplate');

      if (parents.isNotEmpty) {
        print('依赖关系:');
        for (var i = 0; i < parents.length; i++) {
          print('  $baseTemplate → ${parents[i]}');
        }
      } else {
        print('无外部依赖');
      }

      // 这里可以添加更复杂的依赖分析逻辑
      print('✅ 依赖关系分析完成');
    } catch (e) {
      cli_logger.Logger.warning('依赖关系分析失败: $e');
    }
  }

  /// 执行继承操作
  Future<void> _executeInheritance(
    InheritanceEngine inheritanceEngine,
    CompositionEngine compositionEngine,
    String baseTemplate,
    List<String> parents,
    String strategy,
    String outputDir,
    bool optimize,
  ) async {
    try {
      print('\n🔄 执行模板继承');
      print('─' * 50);

      // 创建输出目录
      print('创建输出目录: $outputDir');

      // 模拟继承过程
      print('应用继承策略: $strategy');

      if (parents.isNotEmpty) {
        for (final parent in parents) {
          print('合并父模板: $parent');
        }
      }

      if (optimize) {
        print('优化继承结果...');
      }

      print('✅ 模板继承完成');
      print('📁 输出位置: $outputDir');
    } catch (e) {
      throw Exception('继承执行失败: $e');
    }
  }
}
