/*
---------------------------------------------------------------
File name:          l10n_config_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        l10n.yaml国际化配置文件生成器 (L10n Configuration Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/config/config_generator_base.dart';

/// l10n.yaml国际化配置文件生成器
///
/// 负责生成Flutter项目的国际化配置文件
class L10nConfigGenerator extends ConfigGeneratorBase {
  /// 创建l10n.yaml生成器实例
  const L10nConfigGenerator();

  @override
  String getFileName() => 'l10n.yaml';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer()
      ..writeln('# Flutter国际化配置文件')
      ..writeln(
          '# 更多信息: https://docs.flutter.dev/development/accessibility-and-localization/internationalization',)
      ..writeln()
      ..writeln('# ARB文件目录')
      ..writeln('arb-dir: l10n')
      ..writeln()
      ..writeln('# 模板ARB文件')
      ..writeln('template-arb-file: app_en.arb')
      ..writeln()
      ..writeln('# 输出目录')
      ..writeln('output-dir: lib/generated/l10n')
      ..writeln()
      ..writeln('# 输出本地化文件')
      ..writeln('output-localization-file: app_localizations.dart')
      ..writeln()
      ..writeln('# 输出类名')
      ..writeln('output-class: AppLocalizations')
      ..writeln()
      ..writeln('# 首选支持的语言环境')
      ..writeln('preferred-supported-locales:')
      ..writeln('  - en')
      ..writeln('  - zh')
      ..writeln()
      ..writeln('# 头部注释')
      ..writeln('header: |')
      ..writeln('  /// Generated file. Do not edit.')
      ..writeln('  ///')
      ..writeln('  /// To regenerate, run: `flutter gen-l10n`')
      ..writeln('  ///')
      ..writeln('  /// Project: ${config.templateName}')
      ..writeln('  /// Generated: ${DateTime.now().toString().split(' ')[0]}')
      ..writeln()
      ..writeln('# 是否使用延迟加载')
      ..writeln('use-deferred-loading: false')
      ..writeln()
      ..writeln('# 生成合成包')
      ..writeln('synthetic-package: false')
      ..writeln()
      ..writeln('# 项目目录')
      ..writeln('project-dir: .')
      ..writeln()
      ..writeln('# 是否生成空的构造函数')
      ..writeln('nullable-getter: true')
      ..writeln()
      ..writeln('# 格式化输出')
      ..writeln('format: true')
      ..writeln();

    return buffer.toString();
  }
}
