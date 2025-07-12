/*
---------------------------------------------------------------
File name:          app_dart_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        app.dart模板文件生成器 (App Dart Template Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加更多主题配置选项
    - [ ] 支持动态主题切换
    - [ ] 添加国际化配置
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/template_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// app.dart模板文件生成器
///
/// 负责生成Flutter应用程序的主App Widget模板
class AppDartGenerator extends TemplateGeneratorBase {
  /// 创建app.dart生成器实例
  const AppDartGenerator();

  @override
  String getTemplateFileName() => 'app.dart.template';

  @override
  String getOutputFileName(ScaffoldConfig config) => 'app.dart.template';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.writeln(generateFileHeader(
      'app.dart',
      config,
      '${config.templateName}应用程序主Widget',
    ),);

    // 只为Flutter框架生成App Widget
    if (config.framework == TemplateFramework.flutter) {
      _generateFlutterApp(buffer, config);
    } else {
      _generateDartApp(buffer, config);
    }

    return buffer.toString();
  }

  /// 生成Flutter App Widget
  void _generateFlutterApp(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';")
      ..writeln("import 'package:go_router/go_router.dart';");

    // 根据复杂度添加不同的导入
    if (config.complexity == TemplateComplexity.medium ||
        config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      buffer
        ..writeln("import 'package:flutter_localizations/flutter_localizations.dart';")
        ..writeln("import 'package:flutter_gen/gen_l10n/app_localizations.dart';");
    }

    buffer
      ..writeln()
      ..writeln("import 'core/router/app_router.dart';")
      ..writeln("import 'core/theme/app_theme.dart';");

    // 根据复杂度添加不同的导入
    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      buffer
        ..writeln("import 'core/providers/theme_provider.dart';")
        ..writeln("import 'core/providers/locale_provider.dart';");
    }

    buffer
      ..writeln()
      ..writeln('/// {className}应用程序主Widget')
      ..writeln('///')
      ..writeln('/// 应用程序的根Widget，配置路由、主题和国际化')
      ..writeln('class {className}App extends ConsumerWidget {')
      ..writeln('  /// 创建{className}App实例')
      ..writeln('  const {className}App({super.key});')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Widget build(BuildContext context, WidgetRef ref) {');

    // 根据复杂度生成不同的构建逻辑
    if (config.complexity == TemplateComplexity.simple) {
      _generateSimpleApp(buffer, config);
    } else if (config.complexity == TemplateComplexity.medium) {
      _generateMediumApp(buffer, config);
    } else {
      _generateComplexApp(buffer, config);
    }

    buffer
      ..writeln('  }')
      ..writeln('}');
  }

  /// 生成简单App配置
  void _generateSimpleApp(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('    return MaterialApp.router(')
      ..writeln("      title: '{description}',")
      ..writeln('      debugShowCheckedModeBanner: false,')
      ..writeln('      theme: AppTheme.lightTheme,')
      ..writeln('      darkTheme: AppTheme.darkTheme,')
      ..writeln('      themeMode: ThemeMode.system,')
      ..writeln('      routerConfig: AppRouter.router,')
      ..writeln('    );');
  }

  /// 生成中等复杂度App配置
  void _generateMediumApp(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('    return MaterialApp.router(')
      ..writeln("      title: '{description}',")
      ..writeln('      debugShowCheckedModeBanner: false,')
      ..writeln('      ')
      ..writeln('      // 主题配置')
      ..writeln('      theme: AppTheme.lightTheme,')
      ..writeln('      darkTheme: AppTheme.darkTheme,')
      ..writeln('      themeMode: ThemeMode.system,')
      ..writeln('      ')
      ..writeln('      // 国际化配置')
      ..writeln('      localizationsDelegates: const [')
      ..writeln('        AppLocalizations.delegate,')
      ..writeln('        GlobalMaterialLocalizations.delegate,')
      ..writeln('        GlobalWidgetsLocalizations.delegate,')
      ..writeln('        GlobalCupertinoLocalizations.delegate,')
      ..writeln('      ],')
      ..writeln('      supportedLocales: const [')
      ..writeln("        Locale('en', ''), // 英语")
      ..writeln("        Locale('zh', ''), // 中文")
      ..writeln('      ],')
      ..writeln('      ')
      ..writeln('      // 路由配置')
      ..writeln('      routerConfig: AppRouter.router,')
      ..writeln('    );');
  }

  /// 生成复杂App配置
  void _generateComplexApp(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('    // 监听主题变化')
      ..writeln('    final themeMode = ref.watch(themeModeProvider);')
      ..writeln('    final locale = ref.watch(localeProvider);')
      ..writeln('    ')
      ..writeln('    return MaterialApp.router(')
      ..writeln("      title: '{description}',")
      ..writeln('      debugShowCheckedModeBanner: false,')
      ..writeln('      ')
      ..writeln('      // 动态主题配置')
      ..writeln('      theme: AppTheme.lightTheme,')
      ..writeln('      darkTheme: AppTheme.darkTheme,')
      ..writeln('      themeMode: themeMode,')
      ..writeln('      ')
      ..writeln('      // 动态国际化配置')
      ..writeln('      locale: locale,')
      ..writeln('      localizationsDelegates: const [')
      ..writeln('        AppLocalizations.delegate,')
      ..writeln('        GlobalMaterialLocalizations.delegate,')
      ..writeln('        GlobalWidgetsLocalizations.delegate,')
      ..writeln('        GlobalCupertinoLocalizations.delegate,')
      ..writeln('      ],')
      ..writeln('      supportedLocales: const [')
      ..writeln("        Locale('en', ''), // English")
      ..writeln("        Locale('zh', ''), // 中文")
      ..writeln("        Locale('ja', ''), // 日本語")
      ..writeln("        Locale('ko', ''), // 한국어")
      ..writeln("        Locale('es', ''), // Español")
      ..writeln("        Locale('fr', ''), // Français")
      ..writeln("        Locale('de', ''), // Deutsch")
      ..writeln("        Locale('ru', ''), // Русский")
      ..writeln("        Locale('ar', ''), // العربية")
      ..writeln("        Locale('hi', ''), // हिन्दी")
      ..writeln('      ],')
      ..writeln('      ')
      ..writeln('      // 路由配置')
      ..writeln('      routerConfig: AppRouter.router,')
      ..writeln('      ')
      ..writeln('      // 构建器配置')
      ..writeln('      builder: (context, child) {')
      ..writeln('        return MediaQuery(')
      ..writeln('          // 禁用系统字体缩放')
      ..writeln('          data: MediaQuery.of(context).copyWith(')
      ..writeln('            textScaleFactor: 1.0,')
      ..writeln('          ),')
      ..writeln('          child: child ?? const SizedBox.shrink(),')
      ..writeln('        );')
      ..writeln('      },')
      ..writeln('    );');
  }

  /// 生成Dart应用程序类
  void _generateDartApp(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln()
      ..writeln('/// {className}应用程序类')
      ..writeln('///')
      ..writeln('/// Dart应用程序的主要逻辑类')
      ..writeln('class {className}App {')
      ..writeln('  /// 应用程序名称')
      ..writeln("  static const String appName = '{templateName}';")
      ..writeln('  ')
      ..writeln('  /// 应用程序版本')
      ..writeln("  static const String appVersion = '{version}';")
      ..writeln('  ')
      ..writeln('  /// 应用程序描述')
      ..writeln("  static const String appDescription = '{description}';")
      ..writeln('  ')
      ..writeln('  /// 应用程序作者')
      ..writeln("  static const String appAuthor = '{author}';")
      ..writeln()
      ..writeln('  /// 运行应用程序')
      ..writeln('  ///')
      ..writeln('  /// [arguments] 命令行参数')
      ..writeln('  void run(List<String> arguments) {')
      ..writeln('    _printWelcomeMessage();')
      ..writeln('    _processArguments(arguments);')
      ..writeln('    _startApplication();')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 打印欢迎信息')
      ..writeln('  void _printWelcomeMessage() {')
      ..writeln("    print('=' * 50);")
      ..writeln(r"    print('欢迎使用 $appName!');")
      ..writeln(r"    print('版本: $appVersion');")
      ..writeln(r"    print('描述: $appDescription');")
      ..writeln(r"    print('作者: $appAuthor');")
      ..writeln("    print('=' * 50);")
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 处理命令行参数')
      ..writeln('  ///')
      ..writeln('  /// [arguments] 命令行参数')
      ..writeln('  void _processArguments(List<String> arguments) {')
      ..writeln('    if (arguments.isEmpty) {')
      ..writeln("      print('没有提供命令行参数');")
      ..writeln('      return;')
      ..writeln('    }')
      ..writeln()
      ..writeln("    print('命令行参数:');")
      ..writeln('    for (int i = 0; i < arguments.length; i++) {')
      ..writeln(r"      print('  [$i]: ${arguments[i]}');")
      ..writeln('    }')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 启动应用程序')
      ..writeln('  void _startApplication() {')
      ..writeln(r"    print('\n应用程序正在启动...');")
      ..writeln('    ')
      ..writeln('    // TODO: 在此处添加您的应用程序逻辑')
      ..writeln('    ')
      ..writeln("    print('应用程序启动完成!');")
      ..writeln('  }')
      ..writeln('}');
  }

  @override
  Map<String, String> getTemplateVariables(ScaffoldConfig config) {
    final baseVariables = super.getTemplateVariables(config);
    
    // 添加特定于app.dart的变量
    baseVariables.addAll({
      'appTitle': config.description,
      'supportedLocales': _getSupportedLocales(config),
    });

    return baseVariables;
  }

  /// 获取支持的语言列表
  String _getSupportedLocales(ScaffoldConfig config) {
    if (config.complexity == TemplateComplexity.simple) {
      return 'en, zh';
    } else if (config.complexity == TemplateComplexity.medium) {
      return 'en, zh, ja, ko';
    } else {
      return 'en, zh, ja, ko, es, fr, de, ru, ar, hi';
    }
  }
}
