/*
---------------------------------------------------------------
File name:          platform_detector.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级平台检测器 (Enterprise Platform Detector)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 智能条件生成系统;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 平台类型
/// 
/// 定义支持的平台类型
enum PlatformType {
  /// Web平台
  web,
  
  /// 移动平台
  mobile,
  
  /// 桌面平台
  desktop,
  
  /// 服务器平台
  server,
  
  /// 嵌入式平台
  embedded,
  
  /// 跨平台
  crossPlatform,
}

/// Web平台子类型
enum WebPlatformType {
  /// 渐进式Web应用
  pwa,
  
  /// 单页应用
  spa,
  
  /// 多页应用
  mpa,
  
  /// 服务端渲染
  ssr,
  
  /// 静态站点生成
  ssg,
}

/// 移动平台子类型
enum MobilePlatformType {
  /// iOS原生
  ios,
  
  /// Android原生
  android,
  
  /// Flutter跨平台
  flutter,
  
  /// React Native
  reactNative,
  
  /// Ionic混合应用
  ionic,
  
  /// 小程序
  miniProgram,
}

/// 桌面平台子类型
enum DesktopPlatformType {
  /// Windows原生
  windows,
  
  /// macOS原生
  macos,
  
  /// Linux原生
  linux,
  
  /// Electron跨平台
  electron,
  
  /// Flutter桌面
  flutterDesktop,
  
  /// Tauri
  tauri,
}

/// 技术框架类型
enum FrameworkType {
  /// Flutter
  flutter,
  
  /// React
  react,
  
  /// Vue
  vue,
  
  /// Angular
  angular,
  
  /// Node.js
  nodejs,
  
  /// Spring Boot
  springBoot,
  
  /// Django
  django,
  
  /// Express
  express,
  
  /// FastAPI
  fastapi,
  
  /// 未知框架
  unknown,
}

/// 环境类型
enum EnvironmentType {
  /// 开发环境
  development,
  
  /// 测试环境
  testing,
  
  /// 预发布环境
  staging,
  
  /// 生产环境
  production,
  
  /// 本地环境
  local,
}

/// 设备特性
class DeviceCapabilities {
  /// 创建设备特性实例
  const DeviceCapabilities({
    this.screenWidth,
    this.screenHeight,
    this.pixelRatio,
    this.isTouch = false,
    this.hasCamera = false,
    this.hasGPS = false,
    this.hasAccelerometer = false,
    this.networkType,
    this.storageCapacity,
    this.memoryCapacity,
  });

  /// 屏幕宽度
  final int? screenWidth;
  
  /// 屏幕高度
  final int? screenHeight;
  
  /// 像素比
  final double? pixelRatio;
  
  /// 是否支持触摸
  final bool isTouch;
  
  /// 是否有摄像头
  final bool hasCamera;
  
  /// 是否有GPS
  final bool hasGPS;
  
  /// 是否有加速度计
  final bool hasAccelerometer;
  
  /// 网络类型
  final String? networkType;
  
  /// 存储容量 (GB)
  final int? storageCapacity;
  
  /// 内存容量 (GB)
  final int? memoryCapacity;
}

/// 用户偏好
class UserPreferences {
  /// 创建用户偏好实例
  const UserPreferences({
    this.language = 'en',
    this.theme = 'light',
    this.fontSize = 'medium',
    this.highContrast = false,
    this.reduceMotion = false,
    this.screenReader = false,
    this.timezone,
    this.locale,
  });

  /// 语言偏好
  final String language;
  
  /// 主题偏好
  final String theme;
  
  /// 字体大小
  final String fontSize;
  
  /// 高对比度
  final bool highContrast;
  
  /// 减少动画
  final bool reduceMotion;
  
  /// 屏幕阅读器
  final bool screenReader;
  
  /// 时区
  final String? timezone;
  
  /// 地区设置
  final String? locale;
}

/// 平台检测结果
class PlatformDetectionResult {
  /// 创建平台检测结果实例
  const PlatformDetectionResult({
    required this.primaryPlatform,
    required this.framework, required this.environment, required this.deviceCapabilities, required this.userPreferences, this.webPlatform,
    this.mobilePlatform,
    this.desktopPlatform,
    this.confidence = 1.0,
    this.detectionTime,
    this.metadata = const {},
  });

  /// 主要平台类型
  final PlatformType primaryPlatform;
  
  /// Web平台子类型
  final WebPlatformType? webPlatform;
  
  /// 移动平台子类型
  final MobilePlatformType? mobilePlatform;
  
  /// 桌面平台子类型
  final DesktopPlatformType? desktopPlatform;
  
  /// 技术框架
  final FrameworkType framework;
  
  /// 环境类型
  final EnvironmentType environment;
  
  /// 设备特性
  final DeviceCapabilities deviceCapabilities;
  
  /// 用户偏好
  final UserPreferences userPreferences;
  
  /// 检测置信度 (0.0-1.0)
  final double confidence;
  
  /// 检测时间
  final DateTime? detectionTime;
  
  /// 额外元数据
  final Map<String, dynamic> metadata;
}

/// 企业级平台检测器
/// 
/// 自动检测项目环境、平台、技术栈、设备特性和用户偏好
class PlatformDetector {
  /// 创建平台检测器实例
  PlatformDetector({
    this.enableCaching = true,
    this.cacheTimeout = const Duration(minutes: 5),
    this.enableDeepDetection = true,
  });

  /// 是否启用缓存
  final bool enableCaching;
  
  /// 缓存超时时间
  final Duration cacheTimeout;
  
  /// 是否启用深度检测
  final bool enableDeepDetection;

  /// 检测结果缓存
  PlatformDetectionResult? _cachedResult;
  DateTime? _cacheTime;

  /// 检测当前平台
  /// 
  /// 自动检测当前运行环境的平台信息
  Future<PlatformDetectionResult> detectPlatform({
    String? projectPath,
    Map<String, dynamic>? hints,
  }) async {
    try {
      cli_logger.Logger.debug('开始平台检测');
      
      // 检查缓存
      if (enableCaching && _isCacheValid()) {
        cli_logger.Logger.debug('使用缓存的平台检测结果');
        return _cachedResult!;
      }

      final startTime = DateTime.now();
      
      // 1. 检测主要平台类型
      final primaryPlatform = await _detectPrimaryPlatform(projectPath);
      
      // 2. 检测技术框架
      final framework = await _detectFramework(projectPath);
      
      // 3. 检测环境类型
      final environment = await _detectEnvironment();
      
      // 4. 检测设备特性
      final deviceCapabilities = await _detectDeviceCapabilities();
      
      // 5. 检测用户偏好
      final userPreferences = await _detectUserPreferences();
      
      // 6. 检测平台子类型
      WebPlatformType? webPlatform;
      MobilePlatformType? mobilePlatform;
      DesktopPlatformType? desktopPlatform;
      
      switch (primaryPlatform) {
        case PlatformType.web:
          webPlatform = await _detectWebPlatform(projectPath, framework);
        case PlatformType.mobile:
          mobilePlatform = await _detectMobilePlatform(projectPath, framework);
        case PlatformType.desktop:
          desktopPlatform = await _detectDesktopPlatform(projectPath, framework);
        default:
          break;
      }
      
      // 7. 计算置信度
      final confidence = _calculateConfidence(
        primaryPlatform,
        framework,
        projectPath,
      );
      
      final result = PlatformDetectionResult(
        primaryPlatform: primaryPlatform,
        webPlatform: webPlatform,
        mobilePlatform: mobilePlatform,
        desktopPlatform: desktopPlatform,
        framework: framework,
        environment: environment,
        deviceCapabilities: deviceCapabilities,
        userPreferences: userPreferences,
        confidence: confidence,
        detectionTime: startTime,
        metadata: {
          'detectionDuration': DateTime.now().difference(startTime).inMilliseconds,
          'projectPath': projectPath,
          'hints': hints,
          'deepDetection': enableDeepDetection,
        },
      );
      
      // 缓存结果
      if (enableCaching) {
        _cachedResult = result;
        _cacheTime = DateTime.now();
      }
      
      cli_logger.Logger.info(
        '平台检测完成: ${primaryPlatform.name} (${framework.name}) '
        '置信度: ${(confidence * 100).toStringAsFixed(1)}%',
      );
      
      return result;
    } catch (e) {
      cli_logger.Logger.error('平台检测失败', error: e);
      
      // 返回默认结果
      return PlatformDetectionResult(
        primaryPlatform: PlatformType.crossPlatform,
        framework: FrameworkType.unknown,
        environment: EnvironmentType.development,
        deviceCapabilities: const DeviceCapabilities(),
        userPreferences: const UserPreferences(),
        confidence: 0.1,
        detectionTime: DateTime.now(),
        metadata: {'error': e.toString()},
      );
    }
  }

  /// 检查缓存是否有效
  bool _isCacheValid() {
    if (_cachedResult == null || _cacheTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    return now.difference(_cacheTime!).compareTo(cacheTimeout) < 0;
  }

  /// 检测主要平台类型
  Future<PlatformType> _detectPrimaryPlatform(String? projectPath) async {
    // 检查当前运行环境
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // 进一步检查是否为桌面应用项目
      if (projectPath != null) {
        final pubspecFile = File('$projectPath/pubspec.yaml');
        if (await pubspecFile.exists()) {
          final content = await pubspecFile.readAsString();
          if (content.contains('flutter:') && 
              (content.contains('windows:') || 
               content.contains('macos:') || 
               content.contains('linux:'))) {
            return PlatformType.desktop;
          }
          if (content.contains('flutter:') && 
              (content.contains('android:') || content.contains('ios:'))) {
            return PlatformType.mobile;
          }
          if (content.contains('flutter:') && content.contains('web:')) {
            return PlatformType.web;
          }
        }
        
        // 检查其他Web框架标识
        if (await _hasWebFrameworkFiles(projectPath)) {
          return PlatformType.web;
        }
        
        // 检查服务器框架标识
        if (await _hasServerFrameworkFiles(projectPath)) {
          return PlatformType.server;
        }
      }
      
      return PlatformType.desktop;
    }
    
    // 默认为跨平台
    return PlatformType.crossPlatform;
  }

  /// 检查是否有Web框架文件
  Future<bool> _hasWebFrameworkFiles(String projectPath) async {
    final webFiles = [
      'package.json',
      'index.html',
      'webpack.config.js',
      'vite.config.js',
      'next.config.js',
      'nuxt.config.js',
      'angular.json',
    ];
    
    for (final fileName in webFiles) {
      final file = File('$projectPath/$fileName');
      if (await file.exists()) {
        return true;
      }
    }
    
    return false;
  }

  /// 检查是否有服务器框架文件
  Future<bool> _hasServerFrameworkFiles(String projectPath) async {
    final serverFiles = [
      'server.js',
      'app.js',
      'main.py',
      'manage.py',
      'requirements.txt',
      'Dockerfile',
      'docker-compose.yml',
    ];
    
    for (final fileName in serverFiles) {
      final file = File('$projectPath/$fileName');
      if (await file.exists()) {
        return true;
      }
    }
    
    return false;
  }

  /// 检测技术框架
  Future<FrameworkType> _detectFramework(String? projectPath) async {
    if (projectPath == null) {
      return FrameworkType.unknown;
    }
    
    // 检查Flutter
    final pubspecFile = File('$projectPath/pubspec.yaml');
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();
      if (content.contains('flutter:')) {
        return FrameworkType.flutter;
      }
    }
    
    // 检查Node.js框架
    final packageJsonFile = File('$projectPath/package.json');
    if (await packageJsonFile.exists()) {
      final content = await packageJsonFile.readAsString();
      try {
        final packageJson = json.decode(content) as Map<String, dynamic>;
        final dependencies = {
          ...?packageJson['dependencies'] as Map<String, dynamic>?,
          ...?packageJson['devDependencies'] as Map<String, dynamic>?,
        };
        
        if (dependencies.containsKey('react')) {
          return FrameworkType.react;
        }
        if (dependencies.containsKey('vue')) {
          return FrameworkType.vue;
        }
        if (dependencies.containsKey('@angular/core')) {
          return FrameworkType.angular;
        }
        if (dependencies.containsKey('express')) {
          return FrameworkType.express;
        }
        
        return FrameworkType.nodejs;
      } catch (e) {
        // JSON解析失败，继续其他检测
      }
    }
    
    // 检查Python框架
    final requirementsFile = File('$projectPath/requirements.txt');
    if (await requirementsFile.exists()) {
      final content = await requirementsFile.readAsString();
      if (content.contains('django')) {
        return FrameworkType.django;
      }
      if (content.contains('fastapi')) {
        return FrameworkType.fastapi;
      }
    }
    
    return FrameworkType.unknown;
  }

  /// 检测环境类型
  Future<EnvironmentType> _detectEnvironment() async {
    // 检查环境变量
    final env = Platform.environment;
    
    final nodeEnv = env['NODE_ENV']?.toLowerCase();
    if (nodeEnv != null) {
      switch (nodeEnv) {
        case 'development':
        case 'dev':
          return EnvironmentType.development;
        case 'test':
        case 'testing':
          return EnvironmentType.testing;
        case 'staging':
        case 'stage':
          return EnvironmentType.staging;
        case 'production':
        case 'prod':
          return EnvironmentType.production;
      }
    }
    
    final flutterEnv = env['FLUTTER_ENV']?.toLowerCase();
    if (flutterEnv != null) {
      switch (flutterEnv) {
        case 'development':
          return EnvironmentType.development;
        case 'testing':
          return EnvironmentType.testing;
        case 'staging':
          return EnvironmentType.staging;
        case 'production':
          return EnvironmentType.production;
      }
    }
    
    // 检查调试模式
    if (env.containsKey('DEBUG') || env.containsKey('FLUTTER_DEBUG')) {
      return EnvironmentType.development;
    }
    
    // 默认为开发环境
    return EnvironmentType.development;
  }

  /// 检测设备特性
  Future<DeviceCapabilities> _detectDeviceCapabilities() async {
    // 在CLI环境中，设备特性检测有限
    // 这里提供基础实现，实际应用中可以扩展
    
    return const DeviceCapabilities(
      networkType: 'ethernet', // 假设有网络连接
    );
  }

  /// 检测用户偏好
  Future<UserPreferences> _detectUserPreferences() async {
    final env = Platform.environment;
    
    // 检测语言偏好
    var language = 'en';
    final lang = env['LANG'] ?? env['LANGUAGE'] ?? env['LC_ALL'];
    if (lang != null) {
      if (lang.startsWith('zh')) {
        language = 'zh';
      } else if (lang.startsWith('ja')) {
        language = 'ja';
      } else if (lang.startsWith('ko')) {
        language = 'ko';
      } else if (lang.startsWith('es')) {
        language = 'es';
      } else if (lang.startsWith('fr')) {
        language = 'fr';
      } else if (lang.startsWith('de')) {
        language = 'de';
      }
    }
    
    // 检测时区
    String? timezone;
    try {
      timezone = env['TZ'];
    } catch (e) {
      // 忽略时区检测错误
    }
    
    return UserPreferences(
      language: language,
      timezone: timezone,
      locale: lang,
    );
  }

  /// 检测Web平台子类型
  Future<WebPlatformType?> _detectWebPlatform(
    String? projectPath,
    FrameworkType framework,
  ) async {
    if (projectPath == null) return null;
    
    // 检查Next.js (SSR/SSG)
    if (await File('$projectPath/next.config.js').exists()) {
      return WebPlatformType.ssr;
    }
    
    // 检查Nuxt.js (SSR/SSG)
    if (await File('$projectPath/nuxt.config.js').exists()) {
      return WebPlatformType.ssr;
    }
    
    // 检查PWA配置
    if (await File('$projectPath/manifest.json').exists() ||
        await File('$projectPath/public/manifest.json').exists()) {
      return WebPlatformType.pwa;
    }
    
    // 根据框架推断
    switch (framework) {
      case FrameworkType.react:
      case FrameworkType.vue:
      case FrameworkType.angular:
        return WebPlatformType.spa;
      default:
        return WebPlatformType.spa;
    }
  }

  /// 检测移动平台子类型
  Future<MobilePlatformType?> _detectMobilePlatform(
    String? projectPath,
    FrameworkType framework,
  ) async {
    if (framework == FrameworkType.flutter) {
      return MobilePlatformType.flutter;
    }
    
    if (projectPath == null) return null;
    
    // 检查React Native
    final packageJsonFile = File('$projectPath/package.json');
    if (await packageJsonFile.exists()) {
      final content = await packageJsonFile.readAsString();
      if (content.contains('react-native')) {
        return MobilePlatformType.reactNative;
      }
    }
    
    // 检查Ionic
    if (await File('$projectPath/ionic.config.json').exists()) {
      return MobilePlatformType.ionic;
    }
    
    return MobilePlatformType.flutter; // 默认Flutter
  }

  /// 检测桌面平台子类型
  Future<DesktopPlatformType?> _detectDesktopPlatform(
    String? projectPath,
    FrameworkType framework,
  ) async {
    if (framework == FrameworkType.flutter) {
      return DesktopPlatformType.flutterDesktop;
    }
    
    if (projectPath == null) return null;
    
    // 检查Electron
    final packageJsonFile = File('$projectPath/package.json');
    if (await packageJsonFile.exists()) {
      final content = await packageJsonFile.readAsString();
      if (content.contains('electron')) {
        return DesktopPlatformType.electron;
      }
    }
    
    // 检查Tauri
    if (await File('$projectPath/src-tauri').exists()) {
      return DesktopPlatformType.tauri;
    }
    
    // 根据操作系统推断
    if (Platform.isWindows) {
      return DesktopPlatformType.windows;
    } else if (Platform.isMacOS) {
      return DesktopPlatformType.macos;
    } else if (Platform.isLinux) {
      return DesktopPlatformType.linux;
    }
    
    return DesktopPlatformType.flutterDesktop; // 默认Flutter桌面
  }

  /// 计算检测置信度
  double _calculateConfidence(
    PlatformType platform,
    FrameworkType framework,
    String? projectPath,
  ) {
    var confidence = 0.5; // 基础置信度
    
    // 框架检测成功增加置信度
    if (framework != FrameworkType.unknown) {
      confidence += 0.3;
    }
    
    // 有项目路径增加置信度
    if (projectPath != null) {
      confidence += 0.2;
    }
    
    // 平台特定文件存在增加置信度
    // 这里可以添加更多的启发式规则
    
    return confidence.clamp(0.0, 1.0);
  }

  /// 清理缓存
  void clearCache() {
    _cachedResult = null;
    _cacheTime = null;
    cli_logger.Logger.debug('平台检测器缓存已清理');
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    return {
      'hasCachedResult': _cachedResult != null,
      'cacheTime': _cacheTime?.toIso8601String(),
      'cacheAge': _cacheTime != null 
          ? DateTime.now().difference(_cacheTime!).inSeconds 
          : null,
      'cacheTimeout': cacheTimeout.inSeconds,
    };
  }
}
