/*
---------------------------------------------------------------
File name:          theme_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        Flutter主题生成器 (Flutter Theme Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加Material Design 3.0主题支持
    - [ ] 支持动态颜色主题
    - [ ] 添加自定义主题扩展
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/template_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// Flutter主题生成器
///
/// 负责生成Flutter应用程序的主题配置文件
class ThemeGenerator extends TemplateGeneratorBase {
  /// 创建主题生成器实例
  const ThemeGenerator();

  @override
  String getTemplateFileName() => 'app_theme.dart.template';

  @override
  String getOutputFileName(ScaffoldConfig config) => 'app_theme.dart.template';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.writeln(generateFileHeader(
      'app_theme.dart',
      config,
      '${config.templateName}应用程序主题配置',
    ),);

    buffer
      ..writeln()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln("import 'package:flutter/services.dart';");

    // 根据复杂度添加不同的导入
    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      buffer
        ..writeln("import 'package:google_fonts/google_fonts.dart';")
        ..writeln("import 'package:{packageName}/generated/colors.gen.dart';");
    }

    buffer
      ..writeln()
      ..writeln('/// {className}应用程序主题配置')
      ..writeln('///')
      ..writeln('/// 定义应用程序的亮色和暗色主题')
      ..writeln('class AppTheme {')
      ..writeln('  /// 私有构造函数，防止实例化')
      ..writeln('  AppTheme._();')
      ..writeln();

    // 根据复杂度生成不同的主题配置
    if (config.complexity == TemplateComplexity.simple) {
      _generateSimpleTheme(buffer, config);
    } else if (config.complexity == TemplateComplexity.medium) {
      _generateMediumTheme(buffer, config);
    } else {
      _generateComplexTheme(buffer, config);
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  /// 生成简单主题配置
  void _generateSimpleTheme(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  /// 亮色主题')
      ..writeln('  static ThemeData get lightTheme {')
      ..writeln('    return ThemeData(')
      ..writeln('      useMaterial3: true,')
      ..writeln('      brightness: Brightness.light,')
      ..writeln('      colorScheme: ColorScheme.fromSeed(')
      ..writeln('        seedColor: Colors.blue,')
      ..writeln('        brightness: Brightness.light,')
      ..writeln('      ),')
      ..writeln('      appBarTheme: const AppBarTheme(')
      ..writeln('        centerTitle: true,')
      ..writeln('        elevation: 0,')
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 暗色主题')
      ..writeln('  static ThemeData get darkTheme {')
      ..writeln('    return ThemeData(')
      ..writeln('      useMaterial3: true,')
      ..writeln('      brightness: Brightness.dark,')
      ..writeln('      colorScheme: ColorScheme.fromSeed(')
      ..writeln('        seedColor: Colors.blue,')
      ..writeln('        brightness: Brightness.dark,')
      ..writeln('      ),')
      ..writeln('      appBarTheme: const AppBarTheme(')
      ..writeln('        centerTitle: true,')
      ..writeln('        elevation: 0,')
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }');
  }

  /// 生成中等复杂度主题配置
  void _generateMediumTheme(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  /// 主色调')
      ..writeln('  static const Color primaryColor = Color(0xFF2196F3);')
      ..writeln('  ')
      ..writeln('  /// 次要色调')
      ..writeln('  static const Color secondaryColor = Color(0xFF03DAC6);')
      ..writeln('  ')
      ..writeln('  /// 错误色调')
      ..writeln('  static const Color errorColor = Color(0xFFB00020);')
      ..writeln()
      ..writeln('  /// 亮色主题')
      ..writeln('  static ThemeData get lightTheme {')
      ..writeln('    return ThemeData(')
      ..writeln('      useMaterial3: true,')
      ..writeln('      brightness: Brightness.light,')
      ..writeln('      colorScheme: ColorScheme.fromSeed(')
      ..writeln('        seedColor: primaryColor,')
      ..writeln('        brightness: Brightness.light,')
      ..writeln('        secondary: secondaryColor,')
      ..writeln('        error: errorColor,')
      ..writeln('      ),')
      ..writeln('      appBarTheme: const AppBarTheme(')
      ..writeln('        centerTitle: true,')
      ..writeln('        elevation: 0,')
      ..writeln('        systemOverlayStyle: SystemUiOverlayStyle.dark,')
      ..writeln('      ),')
      ..writeln('      cardTheme: CardTheme(')
      ..writeln('        elevation: 2,')
      ..writeln('        shape: RoundedRectangleBorder(')
      ..writeln('          borderRadius: BorderRadius.circular(12),')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('      elevatedButtonTheme: ElevatedButtonThemeData(')
      ..writeln('        style: ElevatedButton.styleFrom(')
      ..writeln('          shape: RoundedRectangleBorder(')
      ..writeln('            borderRadius: BorderRadius.circular(8),')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 暗色主题')
      ..writeln('  static ThemeData get darkTheme {')
      ..writeln('    return ThemeData(')
      ..writeln('      useMaterial3: true,')
      ..writeln('      brightness: Brightness.dark,')
      ..writeln('      colorScheme: ColorScheme.fromSeed(')
      ..writeln('        seedColor: primaryColor,')
      ..writeln('        brightness: Brightness.dark,')
      ..writeln('        secondary: secondaryColor,')
      ..writeln('        error: errorColor,')
      ..writeln('      ),')
      ..writeln('      appBarTheme: const AppBarTheme(')
      ..writeln('        centerTitle: true,')
      ..writeln('        elevation: 0,')
      ..writeln('        systemOverlayStyle: SystemUiOverlayStyle.light,')
      ..writeln('      ),')
      ..writeln('      cardTheme: CardTheme(')
      ..writeln('        elevation: 2,')
      ..writeln('        shape: RoundedRectangleBorder(')
      ..writeln('          borderRadius: BorderRadius.circular(12),')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('      elevatedButtonTheme: ElevatedButtonThemeData(')
      ..writeln('        style: ElevatedButton.styleFrom(')
      ..writeln('          shape: RoundedRectangleBorder(')
      ..writeln('            borderRadius: BorderRadius.circular(8),')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }');
  }

  /// 生成复杂主题配置
  void _generateComplexTheme(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  /// 品牌颜色')
      ..writeln('  static const Color brandPrimary = Color(0xFF6750A4);')
      ..writeln('  static const Color brandSecondary = Color(0xFF625B71);')
      ..writeln('  static const Color brandTertiary = Color(0xFF7D5260);')
      ..writeln('  ')
      ..writeln('  /// 语义颜色')
      ..writeln('  static const Color successColor = Color(0xFF4CAF50);')
      ..writeln('  static const Color warningColor = Color(0xFFFF9800);')
      ..writeln('  static const Color errorColor = Color(0xFFF44336);')
      ..writeln('  static const Color infoColor = Color(0xFF2196F3);')
      ..writeln('  ')
      ..writeln('  /// 文本样式')
      ..writeln('  static TextTheme get textTheme {')
      ..writeln('    return GoogleFonts.robotoTextTheme().copyWith(')
      ..writeln('      displayLarge: GoogleFonts.roboto(')
      ..writeln('        fontSize: 57,')
      ..writeln('        fontWeight: FontWeight.w400,')
      ..writeln('        letterSpacing: -0.25,')
      ..writeln('      ),')
      ..writeln('      displayMedium: GoogleFonts.roboto(')
      ..writeln('        fontSize: 45,')
      ..writeln('        fontWeight: FontWeight.w400,')
      ..writeln('      ),')
      ..writeln('      displaySmall: GoogleFonts.roboto(')
      ..writeln('        fontSize: 36,')
      ..writeln('        fontWeight: FontWeight.w400,')
      ..writeln('      ),')
      ..writeln('      headlineLarge: GoogleFonts.roboto(')
      ..writeln('        fontSize: 32,')
      ..writeln('        fontWeight: FontWeight.w400,')
      ..writeln('      ),')
      ..writeln('      headlineMedium: GoogleFonts.roboto(')
      ..writeln('        fontSize: 28,')
      ..writeln('        fontWeight: FontWeight.w400,')
      ..writeln('      ),')
      ..writeln('      headlineSmall: GoogleFonts.roboto(')
      ..writeln('        fontSize: 24,')
      ..writeln('        fontWeight: FontWeight.w400,')
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 亮色主题')
      ..writeln('  static ThemeData get lightTheme {')
      ..writeln('    final colorScheme = ColorScheme.fromSeed(')
      ..writeln('      seedColor: brandPrimary,')
      ..writeln('      brightness: Brightness.light,')
      ..writeln('      secondary: brandSecondary,')
      ..writeln('      tertiary: brandTertiary,')
      ..writeln('      error: errorColor,')
      ..writeln('    );')
      ..writeln()
      ..writeln('    return ThemeData(')
      ..writeln('      useMaterial3: true,')
      ..writeln('      brightness: Brightness.light,')
      ..writeln('      colorScheme: colorScheme,')
      ..writeln('      textTheme: textTheme,')
      ..writeln('      appBarTheme: AppBarTheme(')
      ..writeln('        centerTitle: true,')
      ..writeln('        elevation: 0,')
      ..writeln('        backgroundColor: colorScheme.surface,')
      ..writeln('        foregroundColor: colorScheme.onSurface,')
      ..writeln('        systemOverlayStyle: SystemUiOverlayStyle.dark,')
      ..writeln('        titleTextStyle: textTheme.headlineSmall?.copyWith(')
      ..writeln('          color: colorScheme.onSurface,')
      ..writeln('          fontWeight: FontWeight.w500,')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('      cardTheme: CardTheme(')
      ..writeln('        elevation: 1,')
      ..writeln('        shape: RoundedRectangleBorder(')
      ..writeln('          borderRadius: BorderRadius.circular(12),')
      ..writeln('        ),')
      ..writeln('        color: colorScheme.surface,')
      ..writeln('      ),')
      ..writeln('      elevatedButtonTheme: ElevatedButtonThemeData(')
      ..writeln('        style: ElevatedButton.styleFrom(')
      ..writeln('          elevation: 1,')
      ..writeln('          shape: RoundedRectangleBorder(')
      ..writeln('            borderRadius: BorderRadius.circular(20),')
      ..writeln('          ),')
      ..writeln('          padding: const EdgeInsets.symmetric(')
      ..writeln('            horizontal: 24,')
      ..writeln('            vertical: 12,')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('      filledButtonTheme: FilledButtonThemeData(')
      ..writeln('        style: FilledButton.styleFrom(')
      ..writeln('          shape: RoundedRectangleBorder(')
      ..writeln('            borderRadius: BorderRadius.circular(20),')
      ..writeln('          ),')
      ..writeln('          padding: const EdgeInsets.symmetric(')
      ..writeln('            horizontal: 24,')
      ..writeln('            vertical: 12,')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('      inputDecorationTheme: InputDecorationTheme(')
      ..writeln('        filled: true,')
      ..writeln('        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),')
      ..writeln('        border: OutlineInputBorder(')
      ..writeln('          borderRadius: BorderRadius.circular(12),')
      ..writeln('          borderSide: BorderSide.none,')
      ..writeln('        ),')
      ..writeln('        focusedBorder: OutlineInputBorder(')
      ..writeln('          borderRadius: BorderRadius.circular(12),')
      ..writeln('          borderSide: BorderSide(')
      ..writeln('            color: colorScheme.primary,')
      ..writeln('            width: 2,')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 暗色主题')
      ..writeln('  static ThemeData get darkTheme {')
      ..writeln('    final colorScheme = ColorScheme.fromSeed(')
      ..writeln('      seedColor: brandPrimary,')
      ..writeln('      brightness: Brightness.dark,')
      ..writeln('      secondary: brandSecondary,')
      ..writeln('      tertiary: brandTertiary,')
      ..writeln('      error: errorColor,')
      ..writeln('    );')
      ..writeln()
      ..writeln('    return ThemeData(')
      ..writeln('      useMaterial3: true,')
      ..writeln('      brightness: Brightness.dark,')
      ..writeln('      colorScheme: colorScheme,')
      ..writeln('      textTheme: textTheme,')
      ..writeln('      appBarTheme: AppBarTheme(')
      ..writeln('        centerTitle: true,')
      ..writeln('        elevation: 0,')
      ..writeln('        backgroundColor: colorScheme.surface,')
      ..writeln('        foregroundColor: colorScheme.onSurface,')
      ..writeln('        systemOverlayStyle: SystemUiOverlayStyle.light,')
      ..writeln('        titleTextStyle: textTheme.headlineSmall?.copyWith(')
      ..writeln('          color: colorScheme.onSurface,')
      ..writeln('          fontWeight: FontWeight.w500,')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('      cardTheme: CardTheme(')
      ..writeln('        elevation: 1,')
      ..writeln('        shape: RoundedRectangleBorder(')
      ..writeln('          borderRadius: BorderRadius.circular(12),')
      ..writeln('        ),')
      ..writeln('        color: colorScheme.surface,')
      ..writeln('      ),')
      ..writeln('      elevatedButtonTheme: ElevatedButtonThemeData(')
      ..writeln('        style: ElevatedButton.styleFrom(')
      ..writeln('          elevation: 1,')
      ..writeln('          shape: RoundedRectangleBorder(')
      ..writeln('            borderRadius: BorderRadius.circular(20),')
      ..writeln('          ),')
      ..writeln('          padding: const EdgeInsets.symmetric(')
      ..writeln('            horizontal: 24,')
      ..writeln('            vertical: 12,')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('      filledButtonTheme: FilledButtonThemeData(')
      ..writeln('        style: FilledButton.styleFrom(')
      ..writeln('          shape: RoundedRectangleBorder(')
      ..writeln('            borderRadius: BorderRadius.circular(20),')
      ..writeln('          ),')
      ..writeln('          padding: const EdgeInsets.symmetric(')
      ..writeln('            horizontal: 24,')
      ..writeln('            vertical: 12,')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('      inputDecorationTheme: InputDecorationTheme(')
      ..writeln('        filled: true,')
      ..writeln('        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),')
      ..writeln('        border: OutlineInputBorder(')
      ..writeln('          borderRadius: BorderRadius.circular(12),')
      ..writeln('          borderSide: BorderSide.none,')
      ..writeln('        ),')
      ..writeln('        focusedBorder: OutlineInputBorder(')
      ..writeln('          borderRadius: BorderRadius.circular(12),')
      ..writeln('          borderSide: BorderSide(')
      ..writeln('            color: colorScheme.primary,')
      ..writeln('            width: 2,')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }');
  }

  @override
  Map<String, String> getTemplateVariables(ScaffoldConfig config) {
    final baseVariables = super.getTemplateVariables(config);
    
    // 添加特定于主题的变量
    baseVariables.addAll({
      'primaryColorHex': '#2196F3',
      'secondaryColorHex': '#03DAC6',
      'errorColorHex': '#B00020',
    });

    return baseVariables;
  }
}
