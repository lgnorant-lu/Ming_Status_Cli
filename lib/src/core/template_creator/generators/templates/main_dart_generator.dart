/*
---------------------------------------------------------------
File name:          main_dart_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        main.dart模板文件生成器 (Main Dart Template Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Initial creation - main.dart模板文件生成器;
---------------------------------------------------------------
TODO:
    - [ ] 添加更多启动配置选项
    - [ ] 支持多环境配置
    - [ ] 添加性能监控集成
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/template_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// main.dart模板文件生成器
///
/// 负责生成Flutter/Dart项目的主入口文件模板
class MainDartGenerator extends TemplateGeneratorBase {
  /// 创建main.dart生成器实例
  const MainDartGenerator();

  @override
  String getTemplateFileName() => 'main.dart.template';

  @override
  String getOutputFileName(ScaffoldConfig config) => 'main.dart.template';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.writeln(
      generateFileHeader(
        'main.dart',
        config,
        '${config.templateName}应用程序主入口文件',
      ),
    );

    // 根据框架类型生成不同的内容
    if (config.framework == TemplateFramework.flutter) {
      _generateFlutterMain(buffer, config);
    } else {
      _generateDartMain(buffer, config);
    }

    return buffer.toString();
  }

  /// 生成Flutter主入口文件
  void _generateFlutterMain(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln("import 'package:flutter/services.dart';")
      ..writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");

    // 根据复杂度添加不同的导入
    if (config.complexity == TemplateComplexity.medium ||
        config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      buffer
        ..writeln("import 'package:firebase_core/firebase_core.dart';")
        ..writeln(
            "import 'package:flutter_localizations/flutter_localizations.dart';");
    }

    buffer
      ..writeln()
      ..writeln("import 'src/app.dart';");

    // 根据复杂度添加不同的导入
    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      buffer
        ..writeln("import 'src/core/providers/app_providers.dart';")
        ..writeln("import 'src/core/services/app_initializer.dart';")
        ..writeln("import 'src/core/utils/error_handler.dart';");
    }

    buffer
      ..writeln()
      ..writeln('/// 应用程序主入口函数')
      ..writeln('///')
      ..writeln('/// 初始化应用程序并启动主界面')
      ..writeln('Future<void> main() async {');

    // 基础初始化
    buffer
      ..writeln('  // 确保Flutter绑定初始化')
      ..writeln('  WidgetsFlutterBinding.ensureInitialized();')
      ..writeln();

    // 根据复杂度添加不同的初始化逻辑
    if (config.complexity == TemplateComplexity.simple) {
      _generateSimpleInitialization(buffer, config);
    } else if (config.complexity == TemplateComplexity.medium) {
      _generateMediumInitialization(buffer, config);
    } else if (config.complexity == TemplateComplexity.complex) {
      _generateComplexInitialization(buffer, config);
    } else if (config.complexity == TemplateComplexity.enterprise) {
      _generateEnterpriseInitialization(buffer, config);
    }

    buffer
      ..writeln()
      ..writeln('  // 启动应用程序')
      ..writeln('  runApp(')
      ..writeln('    const ProviderScope(')
      ..writeln('      child: ${_getClassName(config)}App(),')
      ..writeln('    ),')
      ..writeln('  );')
      ..writeln('}');

    // 添加错误处理函数
    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      _generateErrorHandling(buffer, config);
    }
  }

  /// 生成简单初始化逻辑
  void _generateSimpleInitialization(
      StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  // 设置系统UI样式')
      ..writeln('  SystemChrome.setSystemUIOverlayStyle(')
      ..writeln('    const SystemUiOverlayStyle(')
      ..writeln('      statusBarColor: Colors.transparent,')
      ..writeln('      statusBarIconBrightness: Brightness.dark,')
      ..writeln('    ),')
      ..writeln('  );');
  }

  /// 生成中等复杂度初始化逻辑
  void _generateMediumInitialization(
      StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  // 设置系统UI样式')
      ..writeln('  await SystemChrome.setPreferredOrientations([')
      ..writeln('    DeviceOrientation.portraitUp,')
      ..writeln('    DeviceOrientation.portraitDown,')
      ..writeln('  ]);')
      ..writeln()
      ..writeln('  SystemChrome.setSystemUIOverlayStyle(')
      ..writeln('    const SystemUiOverlayStyle(')
      ..writeln('      statusBarColor: Colors.transparent,')
      ..writeln('      statusBarIconBrightness: Brightness.dark,')
      ..writeln('      systemNavigationBarColor: Colors.white,')
      ..writeln('      systemNavigationBarIconBrightness: Brightness.dark,')
      ..writeln('    ),')
      ..writeln('  );')
      ..writeln()
      ..writeln('  // 初始化Firebase')
      ..writeln('  await Firebase.initializeApp();');
  }

  /// 生成复杂初始化逻辑
  void _generateComplexInitialization(
      StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  // 设置错误处理')
      ..writeln('  FlutterError.onError = ErrorHandler.handleFlutterError;')
      ..writeln()
      ..writeln('  // 设置系统UI样式')
      ..writeln('  await SystemChrome.setPreferredOrientations([')
      ..writeln('    DeviceOrientation.portraitUp,')
      ..writeln('    DeviceOrientation.portraitDown,')
      ..writeln('  ]);')
      ..writeln()
      ..writeln('  SystemChrome.setSystemUIOverlayStyle(')
      ..writeln('    const SystemUiOverlayStyle(')
      ..writeln('      statusBarColor: Colors.transparent,')
      ..writeln('      statusBarIconBrightness: Brightness.dark,')
      ..writeln('      systemNavigationBarColor: Colors.white,')
      ..writeln('      systemNavigationBarIconBrightness: Brightness.dark,')
      ..writeln('    ),')
      ..writeln('  );')
      ..writeln()
      ..writeln('  // 初始化应用程序服务')
      ..writeln('  await AppInitializer.initialize();');
  }

  /// 生成企业级初始化逻辑
  void _generateEnterpriseInitialization(
      StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  // 设置全局错误处理')
      ..writeln('  FlutterError.onError = ErrorHandler.handleFlutterError;')
      ..writeln(
          '  PlatformDispatcher.instance.onError = ErrorHandler.handlePlatformError;')
      ..writeln()
      ..writeln('  // 运行在错误保护区域中')
      ..writeln('  await runZonedGuarded<Future<void>>(')
      ..writeln('    () async {')
      ..writeln('      // 设置系统UI样式')
      ..writeln('      await SystemChrome.setPreferredOrientations([')
      ..writeln('        DeviceOrientation.portraitUp,')
      ..writeln('        DeviceOrientation.portraitDown,')
      ..writeln('      ]);')
      ..writeln()
      ..writeln('      SystemChrome.setSystemUIOverlayStyle(')
      ..writeln('        const SystemUiOverlayStyle(')
      ..writeln('          statusBarColor: Colors.transparent,')
      ..writeln('          statusBarIconBrightness: Brightness.dark,')
      ..writeln('          systemNavigationBarColor: Colors.white,')
      ..writeln('          systemNavigationBarIconBrightness: Brightness.dark,')
      ..writeln('        ),')
      ..writeln('      );')
      ..writeln()
      ..writeln('      // 初始化企业级服务')
      ..writeln('      await AppInitializer.initializeEnterprise();')
      ..writeln('    },')
      ..writeln('    ErrorHandler.handleZoneError,')
      ..writeln('  );');
  }

  /// 生成错误处理函数
  void _generateErrorHandling(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln()
      ..writeln('/// 应用程序错误处理')
      ..writeln('///')
      ..writeln('/// 处理应用程序运行时错误')
      ..writeln('void _handleError(Object error, StackTrace stackTrace) {')
      ..writeln('  // 记录错误')
      ..writeln(r"  debugPrint('应用程序错误: $error');")
      ..writeln(r"  debugPrint('堆栈跟踪: $stackTrace');")
      ..writeln()
      ..writeln('  // 发送错误报告到崩溃分析服务')
      ..writeln(
          '  // FirebaseCrashlytics.instance.recordError(error, stackTrace);')
      ..writeln('}');
  }

  /// 生成Dart主入口文件
  void _generateDartMain(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln()
      ..writeln('/// 应用程序主入口函数')
      ..writeln('///')
      ..writeln('/// 启动{description}')
      ..writeln('void main(List<String> arguments) {')
      ..writeln("  print('欢迎使用 {templateName}!');")
      ..writeln("  print('描述: {description}');")
      ..writeln("  print('版本: {version}');")
      ..writeln("  print('作者: {author}');")
      ..writeln()
      ..writeln('  // TODO: 在此处添加您的应用程序逻辑')
      ..writeln('  // 示例:')
      ..writeln('  // final app = {className}();')
      ..writeln('  // app.run(arguments);')
      ..writeln('}')
      ..writeln()
      ..writeln('/// {className}应用程序类')
      ..writeln('///')
      ..writeln('/// 主要的应用程序逻辑')
      ..writeln('class {className} {')
      ..writeln('  /// 运行应用程序')
      ..writeln('  ///')
      ..writeln('  /// [arguments] 命令行参数')
      ..writeln('  void run(List<String> arguments) {')
      ..writeln("    print('应用程序正在运行...');")
      ..writeln('    ')
      ..writeln('    // TODO: 实现您的应用程序逻辑')
      ..writeln('  }')
      ..writeln('}');
  }

  @override
  Map<String, String> getTemplateVariables(ScaffoldConfig config) {
    final baseVariables = super.getTemplateVariables(config);

    // 添加特定于main.dart的变量
    baseVariables.addAll({
      'appTitle': config.description,
      'packageName': config.templateName.toLowerCase().replaceAll('_', '.'),
    });

    return baseVariables;
  }

  /// 获取类名
  String _getClassName(ScaffoldConfig config) {
    final parts = config.templateName.split('_');
    final capitalizedParts = parts.map((part) =>
        part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : part);
    return capitalizedParts.join();
  }
}
