/*
---------------------------------------------------------------
File name:          plugin_validate_command.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件验证命令 (Plugin validation command)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 实现插件验证功能;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/plugin_system/plugin_validator.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 插件验证命令
///
/// 验证插件项目的结构、清单文件和代码质量，确保插件符合Pet App V3规范。
///
/// ## 验证内容
/// - 项目结构完整性
/// - plugin.yaml清单文件
/// - pubspec.yaml配置
/// - 代码质量检查
/// - Pet App V3兼容性
/// - 依赖关系验证
///
/// ## 使用示例
/// ```bash
/// # 验证当前目录
/// ming plugin validate
///
/// # 验证指定目录
/// ming plugin validate --path=./my_plugin
///
/// # 详细验证报告
/// ming plugin validate --verbose
///
/// # 仅检查关键问题
/// ming plugin validate --strict
/// ```
class PluginValidateCommand extends BaseCommand {
  /// 创建插件验证命令实例
  PluginValidateCommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: '插件项目路径',
        defaultsTo: '.',
      )
      ..addFlag(
        'strict',
        abbr: 's',
        help: '严格模式，仅检查关键问题',
        defaultsTo: false,
      )
      ..addFlag(
        'fix',
        help: '自动修复可修复的问题',
        defaultsTo: false,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '验证报告输出文件路径',
      );
  }

  @override
  String get name => 'validate';

  @override
  String get description => '验证插件结构和清单文件';

  @override
  String get usage => '''
验证插件结构和清单文件

使用方法:
  ming plugin validate [选项]

选项:
  -p, --path=<路径>      插件项目路径 (默认: 当前目录)
  -s, --strict           严格模式，仅检查关键问题
      --fix              自动修复可修复的问题
  -o, --output=<文件>    验证报告输出文件路径
  -v, --verbose          显示详细验证信息
  -h, --help             显示帮助信息

示例:
  # 验证当前目录的插件
  ming plugin validate

  # 验证指定目录
  ming plugin validate --path=./my_plugin

  # 严格模式验证
  ming plugin validate --strict

  # 自动修复问题
  ming plugin validate --fix

  # 生成验证报告
  ming plugin validate --output=validation_report.json

更多信息:
  使用 'ming help plugin validate' 查看详细文档
''';

  @override
  Future<int> execute() async {
    final pluginPath = argResults!['path'] as String;
    final isStrict = argResults!['strict'] as bool;
    final shouldFix = argResults!['fix'] as bool;
    final outputPath = argResults!['output'] as String?;

    Logger.info('🔍 开始验证插件项目...');
    Logger.debug('插件路径: $pluginPath');
    Logger.debug('严格模式: $isStrict');
    Logger.debug('自动修复: $shouldFix');

    // 检查路径是否存在
    final pluginDir = Directory(pluginPath);
    if (!pluginDir.existsSync()) {
      Logger.error('插件路径不存在: $pluginPath');
      return 1;
    }

    try {
      // 创建插件验证器
      final validator = PluginValidator();

      // 执行验证
      final result = await validator.validatePlugin(
        pluginPath,
        strict: isStrict,
        autoFix: shouldFix,
      );

      // 显示验证结果
      _displayValidationResult(result);

      // 输出报告文件
      if (outputPath != null) {
        await _saveValidationReport(result, outputPath);
      }

      // 返回结果
      if (result.isValid) {
        Logger.success('✅ 插件验证通过！');
        return 0;
      } else {
        Logger.error('❌ 插件验证失败');
        return 1;
      }
    } catch (e) {
      Logger.error('验证过程中发生错误: $e');
      return 1;
    }
  }

  /// 显示验证结果
  void _displayValidationResult(PluginValidationResult result) {
    Logger.info('\n📋 验证结果摘要:');
    Logger.info('  总检查项: ${result.totalChecks}');
    Logger.info('  通过项: ${result.passedChecks}');
    Logger.info('  失败项: ${result.failedChecks}');
    Logger.info('  警告项: ${result.warningChecks}');

    if (result.errors.isNotEmpty) {
      Logger.info('\n❌ 错误:');
      for (final error in result.errors) {
        Logger.error('  • $error');
      }
    }

    if (result.warnings.isNotEmpty) {
      Logger.info('\n⚠️  警告:');
      for (final warning in result.warnings) {
        Logger.warning('  • $warning');
      }
    }

    if (result.suggestions.isNotEmpty) {
      Logger.info('\n💡 建议:');
      for (final suggestion in result.suggestions) {
        Logger.info('  • $suggestion');
      }
    }
  }

  /// 保存验证报告
  Future<void> _saveValidationReport(
    PluginValidationResult result,
    String outputPath,
  ) async {
    try {
      final reportFile = File(outputPath);
      await reportFile.writeAsString(result.toJson());
      Logger.success('验证报告已保存到: $outputPath');
    } catch (e) {
      Logger.warning('保存验证报告失败: $e');
    }
  }
}
