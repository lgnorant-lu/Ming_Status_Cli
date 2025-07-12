/*
---------------------------------------------------------------
File name:          asset_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        资源文件生成器 (Asset File Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加更多资源类型支持
    - [ ] 支持资源优化和压缩
    - [ ] 添加资源版本管理
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/template_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 资源文件生成器
///
/// 负责生成Flutter应用程序的资源文件和目录结构
class AssetGenerator extends TemplateGeneratorBase {
  /// 创建资源生成器实例
  const AssetGenerator({
    required this.assetType,
  });

  /// 资源类型
  final AssetType assetType;

  @override
  String getTemplateFileName() => '${assetType.name}_assets.template';

  @override
  String getOutputFileName(ScaffoldConfig config) =>
      '${assetType.name}_assets.template';

  @override
  String generateContent(ScaffoldConfig config) {
    switch (assetType) {
      case AssetType.images:
        return _generateImageAssets(config);
      case AssetType.icons:
        return _generateIconAssets(config);
      case AssetType.fonts:
        return _generateFontAssets(config);
      case AssetType.colors:
        return _generateColorAssets(config);
      case AssetType.animations:
        return _generateAnimationAssets(config);
    }
  }

  /// 生成图片资源
  String _generateImageAssets(ScaffoldConfig config) {
    final buffer = StringBuffer()

      ..writeln(generateFileHeader(
        'images.dart',
        config,
        '${config.templateName}应用程序图片资源',
      ),)

      ..writeln()
      ..writeln('/// 图片资源路径常量')
      ..writeln('///')
      ..writeln('/// 定义应用程序中使用的所有图片资源路径')
      ..writeln('class ImageAssets {')
      ..writeln('  /// 私有构造函数，防止实例化')
      ..writeln('  ImageAssets._();')
      ..writeln()
      ..writeln('  /// 资源根路径')
      ..writeln("  static const String _basePath = 'assets/images';")
      ..writeln();

    // 根据复杂度添加不同的图片资源
    if (config.complexity == TemplateComplexity.simple) {
      _addSimpleImageAssets(buffer);
    } else if (config.complexity == TemplateComplexity.medium) {
      _addMediumImageAssets(buffer);
    } else {
      _addComplexImageAssets(buffer);
    }

    buffer
      ..writeln()
      ..writeln('  /// 获取完整的图片路径')
      ..writeln('  ///')
      ..writeln('  /// [imageName] 图片文件名')
      ..writeln('  /// 返回完整的资源路径')
      ..writeln('  static String getImagePath(String imageName) {')
      ..writeln(r"    return '$_basePath/$imageName';")
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 检查图片是否存在')
      ..writeln('  ///')
      ..writeln('  /// [imagePath] 图片路径')
      ..writeln('  /// 返回图片是否存在')
      ..writeln('  static bool imageExists(String imagePath) {')
      ..writeln('    // 在实际应用中，这里可以检查资源是否存在')
      ..writeln('    return true;')
      ..writeln('  }')
      ..writeln('}');

    return buffer.toString();
  }

  /// 添加简单图片资源
  void _addSimpleImageAssets(StringBuffer buffer) {
    buffer
      ..writeln('  /// 应用图标')
      ..writeln(r"  static const String logo = '$_basePath/logo.png';")
      ..writeln()
      ..writeln('  /// 启动画面')
      ..writeln(r"  static const String splash = '$_basePath/splash.png';")
      ..writeln()
      ..writeln('  /// 占位符图片')
      ..writeln(
          r"  static const String placeholder = '$_basePath/placeholder.png';",);
  }

  /// 添加中等复杂度图片资源
  void _addMediumImageAssets(StringBuffer buffer) {
    buffer
      ..writeln('  /// === 品牌资源 ===')
      ..writeln('  ')
      ..writeln('  /// 应用图标')
      ..writeln(r"  static const String logo = '$_basePath/logo.png';")
      ..writeln('  ')
      ..writeln('  /// 应用图标（暗色主题）')
      ..writeln(
          r"  static const String logoDark = '$_basePath/logo_dark.png';",)
      ..writeln('  ')
      ..writeln('  /// 启动画面')
      ..writeln(r"  static const String splash = '$_basePath/splash.png';")
      ..writeln()
      ..writeln('  /// === 界面资源 ===')
      ..writeln('  ')
      ..writeln('  /// 占位符图片')
      ..writeln(
          r"  static const String placeholder = '$_basePath/placeholder.png';",)
      ..writeln('  ')
      ..writeln('  /// 空状态图片')
      ..writeln(
          r"  static const String emptyState = '$_basePath/empty_state.png';",)
      ..writeln('  ')
      ..writeln('  /// 错误状态图片')
      ..writeln(
          r"  static const String errorState = '$_basePath/error_state.png';",)
      ..writeln()
      ..writeln('  /// === 用户头像 ===')
      ..writeln('  ')
      ..writeln('  /// 默认头像')
      ..writeln(
          r"  static const String defaultAvatar = '$_basePath/default_avatar.png';",);
  }

  /// 添加复杂图片资源
  void _addComplexImageAssets(StringBuffer buffer) {
    buffer
      ..writeln('  /// === 品牌资源 ===')
      ..writeln('  ')
      ..writeln('  /// 应用图标')
      ..writeln(r"  static const String logo = '$_basePath/logo.png';")
      ..writeln('  ')
      ..writeln('  /// 应用图标（暗色主题）')
      ..writeln(
          r"  static const String logoDark = '$_basePath/logo_dark.png';",)
      ..writeln('  ')
      ..writeln('  /// 应用图标（小尺寸）')
      ..writeln(
          r"  static const String logoSmall = '$_basePath/logo_small.png';",)
      ..writeln('  ')
      ..writeln('  /// 启动画面')
      ..writeln(r"  static const String splash = '$_basePath/splash.png';")
      ..writeln('  ')
      ..writeln('  /// 品牌横幅')
      ..writeln(r"  static const String banner = '$_basePath/banner.png';")
      ..writeln()
      ..writeln('  /// === 界面资源 ===')
      ..writeln('  ')
      ..writeln('  /// 占位符图片')
      ..writeln(
          r"  static const String placeholder = '$_basePath/placeholder.png';",)
      ..writeln('  ')
      ..writeln('  /// 空状态图片')
      ..writeln(
          r"  static const String emptyState = '$_basePath/empty_state.png';",)
      ..writeln('  ')
      ..writeln('  /// 错误状态图片')
      ..writeln(
          r"  static const String errorState = '$_basePath/error_state.png';",)
      ..writeln('  ')
      ..writeln('  /// 加载状态图片')
      ..writeln(
          r"  static const String loadingState = '$_basePath/loading_state.png';",)
      ..writeln('  ')
      ..writeln('  /// 成功状态图片')
      ..writeln(
          r"  static const String successState = '$_basePath/success_state.png';",)
      ..writeln()
      ..writeln('  /// === 用户相关 ===')
      ..writeln('  ')
      ..writeln('  /// 默认头像')
      ..writeln(
          r"  static const String defaultAvatar = '$_basePath/default_avatar.png';",)
      ..writeln('  ')
      ..writeln('  /// 用户背景')
      ..writeln(
          r"  static const String userBackground = '$_basePath/user_background.png';",)
      ..writeln()
      ..writeln('  /// === 功能图标 ===')
      ..writeln('  ')
      ..writeln('  /// 设置图标')
      ..writeln(
          r"  static const String settingsIcon = '$_basePath/settings_icon.png';",)
      ..writeln('  ')
      ..writeln('  /// 通知图标')
      ..writeln(
          r"  static const String notificationIcon = '$_basePath/notification_icon.png';",)
      ..writeln('  ')
      ..writeln('  /// 搜索图标')
      ..writeln(
          r"  static const String searchIcon = '$_basePath/search_icon.png';",)
      ..writeln()
      ..writeln('  /// === 背景图片 ===')
      ..writeln('  ')
      ..writeln('  /// 主背景')
      ..writeln(
          r"  static const String mainBackground = '$_basePath/main_background.png';",)
      ..writeln('  ')
      ..writeln('  /// 登录背景')
      ..writeln(
          r"  static const String loginBackground = '$_basePath/login_background.png';",);
  }

  /// 生成图标资源
  String _generateIconAssets(ScaffoldConfig config) {
    final buffer = StringBuffer();

    buffer.writeln(generateFileHeader(
      'icons.dart',
      config,
      '${config.templateName}应用程序图标资源',
    ),);

    buffer
      ..writeln()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln()
      ..writeln('/// 图标资源常量')
      ..writeln('///')
      ..writeln('/// 定义应用程序中使用的所有图标')
      ..writeln('class AppIcons {')
      ..writeln('  /// 私有构造函数，防止实例化')
      ..writeln('  AppIcons._();')
      ..writeln()
      ..writeln('  /// === Material Design 图标 ===')
      ..writeln('  ')
      ..writeln('  /// 首页图标')
      ..writeln('  static const IconData home = Icons.home;')
      ..writeln('  ')
      ..writeln('  /// 设置图标')
      ..writeln('  static const IconData settings = Icons.settings;')
      ..writeln('  ')
      ..writeln('  /// 用户图标')
      ..writeln('  static const IconData person = Icons.person;')
      ..writeln('  ')
      ..writeln('  /// 搜索图标')
      ..writeln('  static const IconData search = Icons.search;')
      ..writeln('  ')
      ..writeln('  /// 通知图标')
      ..writeln('  static const IconData notifications = Icons.notifications;')
      ..writeln('  ')
      ..writeln('  /// 菜单图标')
      ..writeln('  static const IconData menu = Icons.menu;')
      ..writeln('  ')
      ..writeln('  /// 返回图标')
      ..writeln('  static const IconData back = Icons.arrow_back;')
      ..writeln('  ')
      ..writeln('  /// 关闭图标')
      ..writeln('  static const IconData close = Icons.close;')
      ..writeln('  ')
      ..writeln('  /// 编辑图标')
      ..writeln('  static const IconData edit = Icons.edit;')
      ..writeln('  ')
      ..writeln('  /// 删除图标')
      ..writeln('  static const IconData delete = Icons.delete;')
      ..writeln('  ')
      ..writeln('  /// 保存图标')
      ..writeln('  static const IconData save = Icons.save;')
      ..writeln('  ')
      ..writeln('  /// 分享图标')
      ..writeln('  static const IconData share = Icons.share;')
      ..writeln('  ')
      ..writeln('  /// 收藏图标')
      ..writeln('  static const IconData favorite = Icons.favorite;')
      ..writeln('  ')
      ..writeln('  /// 收藏边框图标')
      ..writeln(
          '  static const IconData favoriteBorder = Icons.favorite_border;',)
      ..writeln('  ')
      ..writeln('  /// 添加图标')
      ..writeln('  static const IconData add = Icons.add;')
      ..writeln('  ')
      ..writeln('  /// 移除图标')
      ..writeln('  static const IconData remove = Icons.remove;')
      ..writeln('  ')
      ..writeln('  /// 刷新图标')
      ..writeln('  static const IconData refresh = Icons.refresh;')
      ..writeln('  ')
      ..writeln('  /// 下载图标')
      ..writeln('  static const IconData download = Icons.download;')
      ..writeln('  ')
      ..writeln('  /// 上传图标')
      ..writeln('  static const IconData upload = Icons.upload;')
      ..writeln('}');

    return buffer.toString();
  }

  /// 生成字体资源
  String _generateFontAssets(ScaffoldConfig config) {
    final buffer = StringBuffer();

    buffer.writeln(generateFileHeader(
      'fonts.dart',
      config,
      '${config.templateName}应用程序字体资源',
    ),);

    buffer
      ..writeln()
      ..writeln('/// 字体资源常量')
      ..writeln('///')
      ..writeln('/// 定义应用程序中使用的所有字体')
      ..writeln('class AppFonts {')
      ..writeln('  /// 私有构造函数，防止实例化')
      ..writeln('  AppFonts._();')
      ..writeln()
      ..writeln('  /// 默认字体')
      ..writeln("  static const String defaultFont = 'Roboto';")
      ..writeln('  ')
      ..writeln('  /// 标题字体')
      ..writeln("  static const String titleFont = 'RobotoSlab';")
      ..writeln('  ')
      ..writeln('  /// 等宽字体')
      ..writeln("  static const String monospaceFont = 'RobotoMono';")
      ..writeln('  ')
      ..writeln('  /// 装饰字体')
      ..writeln("  static const String decorativeFont = 'Pacifico';")
      ..writeln()
      ..writeln('  /// 字体权重')
      ..writeln('  static const Map<String, int> fontWeights = {')
      ..writeln("    'thin': 100,")
      ..writeln("    'light': 300,")
      ..writeln("    'regular': 400,")
      ..writeln("    'medium': 500,")
      ..writeln("    'semiBold': 600,")
      ..writeln("    'bold': 700,")
      ..writeln("    'extraBold': 800,")
      ..writeln("    'black': 900,")
      ..writeln('  };')
      ..writeln()
      ..writeln('  /// 字体大小')
      ..writeln('  static const Map<String, double> fontSizes = {')
      ..writeln("    'caption': 12.0,")
      ..writeln("    'body2': 14.0,")
      ..writeln("    'body1': 16.0,")
      ..writeln("    'subtitle2': 14.0,")
      ..writeln("    'subtitle1': 16.0,")
      ..writeln("    'headline6': 20.0,")
      ..writeln("    'headline5': 24.0,")
      ..writeln("    'headline4': 34.0,")
      ..writeln("    'headline3': 48.0,")
      ..writeln("    'headline2': 60.0,")
      ..writeln("    'headline1': 96.0,")
      ..writeln('  };')
      ..writeln('}');

    return buffer.toString();
  }

  /// 生成颜色资源
  String _generateColorAssets(ScaffoldConfig config) {
    final buffer = StringBuffer();

    buffer.writeln(generateFileHeader(
      'colors.dart',
      config,
      '${config.templateName}应用程序颜色资源',
    ),);

    buffer
      ..writeln()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln()
      ..writeln('/// 颜色资源常量')
      ..writeln('///')
      ..writeln('/// 定义应用程序中使用的所有颜色')
      ..writeln('class AppColors {')
      ..writeln('  /// 私有构造函数，防止实例化')
      ..writeln('  AppColors._();')
      ..writeln()
      ..writeln('  /// === 主要颜色 ===')
      ..writeln('  ')
      ..writeln('  /// 主色调')
      ..writeln('  static const Color primary = Color(0xFF2196F3);')
      ..writeln('  ')
      ..writeln('  /// 主色调变体')
      ..writeln('  static const Color primaryVariant = Color(0xFF1976D2);')
      ..writeln('  ')
      ..writeln('  /// 次要色调')
      ..writeln('  static const Color secondary = Color(0xFF03DAC6);')
      ..writeln('  ')
      ..writeln('  /// 次要色调变体')
      ..writeln('  static const Color secondaryVariant = Color(0xFF018786);')
      ..writeln()
      ..writeln('  /// === 表面颜色 ===')
      ..writeln('  ')
      ..writeln('  /// 背景色')
      ..writeln('  static const Color background = Color(0xFFFAFAFA);')
      ..writeln('  ')
      ..writeln('  /// 表面色')
      ..writeln('  static const Color surface = Color(0xFFFFFFFF);')
      ..writeln('  ')
      ..writeln('  /// 错误色')
      ..writeln('  static const Color error = Color(0xFFB00020);')
      ..writeln()
      ..writeln('  /// === 文本颜色 ===')
      ..writeln('  ')
      ..writeln('  /// 主要文本色（在主色调上）')
      ..writeln('  static const Color onPrimary = Color(0xFFFFFFFF);')
      ..writeln('  ')
      ..writeln('  /// 次要文本色（在次要色调上）')
      ..writeln('  static const Color onSecondary = Color(0xFF000000);')
      ..writeln('  ')
      ..writeln('  /// 背景文本色（在背景上）')
      ..writeln('  static const Color onBackground = Color(0xFF000000);')
      ..writeln('  ')
      ..writeln('  /// 表面文本色（在表面上）')
      ..writeln('  static const Color onSurface = Color(0xFF000000);')
      ..writeln('  ')
      ..writeln('  /// 错误文本色（在错误色上）')
      ..writeln('  static const Color onError = Color(0xFFFFFFFF);')
      ..writeln()
      ..writeln('  /// === 语义颜色 ===')
      ..writeln('  ')
      ..writeln('  /// 成功色')
      ..writeln('  static const Color success = Color(0xFF4CAF50);')
      ..writeln('  ')
      ..writeln('  /// 警告色')
      ..writeln('  static const Color warning = Color(0xFFFF9800);')
      ..writeln('  ')
      ..writeln('  /// 信息色')
      ..writeln('  static const Color info = Color(0xFF2196F3);')
      ..writeln()
      ..writeln('  /// === 灰度颜色 ===')
      ..writeln('  ')
      ..writeln('  /// 灰色调色板')
      ..writeln('  static const Map<int, Color> grey = {')
      ..writeln('    50: Color(0xFFFAFAFA),')
      ..writeln('    100: Color(0xFFF5F5F5),')
      ..writeln('    200: Color(0xFFEEEEEE),')
      ..writeln('    300: Color(0xFFE0E0E0),')
      ..writeln('    400: Color(0xFFBDBDBD),')
      ..writeln('    500: Color(0xFF9E9E9E),')
      ..writeln('    600: Color(0xFF757575),')
      ..writeln('    700: Color(0xFF616161),')
      ..writeln('    800: Color(0xFF424242),')
      ..writeln('    900: Color(0xFF212121),')
      ..writeln('  };')
      ..writeln('}');

    return buffer.toString();
  }

  /// 生成动画资源
  String _generateAnimationAssets(ScaffoldConfig config) {
    final buffer = StringBuffer();

    buffer.writeln(generateFileHeader(
      'animations.dart',
      config,
      '${config.templateName}应用程序动画资源',
    ),);

    buffer
      ..writeln()
      ..writeln('/// 动画资源常量')
      ..writeln('///')
      ..writeln('/// 定义应用程序中使用的所有动画')
      ..writeln('class AnimationAssets {')
      ..writeln('  /// 私有构造函数，防止实例化')
      ..writeln('  AnimationAssets._();')
      ..writeln()
      ..writeln('  /// 资源根路径')
      ..writeln("  static const String _basePath = 'assets/animations';")
      ..writeln()
      ..writeln('  /// 加载动画')
      ..writeln(r"  static const String loading = '$_basePath/loading.json';")
      ..writeln('  ')
      ..writeln('  /// 成功动画')
      ..writeln(r"  static const String success = '$_basePath/success.json';")
      ..writeln('  ')
      ..writeln('  /// 错误动画')
      ..writeln(r"  static const String error = '$_basePath/error.json';")
      ..writeln('  ')
      ..writeln('  /// 空状态动画')
      ..writeln(r"  static const String empty = '$_basePath/empty.json';")
      ..writeln()
      ..writeln('  /// 动画持续时间（毫秒）')
      ..writeln('  static const Map<String, int> durations = {')
      ..writeln("    'fast': 200,")
      ..writeln("    'normal': 300,")
      ..writeln("    'slow': 500,")
      ..writeln("    'verySlow': 1000,")
      ..writeln('  };')
      ..writeln('}');

    return buffer.toString();
  }

  @override
  Map<String, String> getTemplateVariables(ScaffoldConfig config) {
    final baseVariables = super.getTemplateVariables(config);

    // 添加特定于资源的变量
    baseVariables.addAll({
      'assetType': assetType.name,
      'assetCount': _getAssetCount(config).toString(),
    });

    return baseVariables;
  }

  /// 获取资源数量
  int _getAssetCount(ScaffoldConfig config) {
    switch (assetType) {
      case AssetType.images:
        return config.complexity == TemplateComplexity.simple
            ? 3
            : config.complexity == TemplateComplexity.medium
                ? 7
                : 15;
      case AssetType.icons:
        return 20;
      case AssetType.fonts:
        return 4;
      case AssetType.colors:
        return 15;
      case AssetType.animations:
        return 4;
    }
  }
}

/// 资源类型枚举
enum AssetType {
  /// 图片资源
  images,

  /// 图标资源
  icons,

  /// 字体资源
  fonts,

  /// 颜色资源
  colors,

  /// 动画资源
  animations,
}
