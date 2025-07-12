/*
---------------------------------------------------------------
File name:          router_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        Flutter路由生成器 (Flutter Router Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加嵌套路由支持
    - [ ] 支持路由守卫和中间件
    - [ ] 添加路由动画配置
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/template_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// Flutter路由生成器
///
/// 负责生成Flutter应用程序的路由配置文件
class RouterGenerator extends TemplateGeneratorBase {
  /// 创建路由生成器实例
  const RouterGenerator();

  @override
  String getTemplateFileName() => 'app_router.dart.template';

  @override
  String getOutputFileName(ScaffoldConfig config) => 'app_router.dart.template';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.writeln(generateFileHeader(
      'app_router.dart',
      config,
      '${config.templateName}应用程序路由配置',
    ),);

    buffer
      ..writeln()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln("import 'package:go_router/go_router.dart';");

    // 根据复杂度添加不同的导入
    if (config.complexity == TemplateComplexity.medium ||
        config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      buffer
        .writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
    }

    buffer
      ..writeln()
      ..writeln("import '../screens/home_screen.dart';")
      ..writeln("import '../screens/settings_screen.dart';");

    // 根据复杂度添加不同的导入
    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      buffer
        ..writeln("import '../screens/profile_screen.dart';")
        ..writeln("import '../screens/about_screen.dart';")
        ..writeln("import '../screens/error_screen.dart';")
        ..writeln("import '../providers/auth_provider.dart';");
    }

    buffer
      ..writeln()
      ..writeln('/// {className}应用程序路由配置')
      ..writeln('///')
      ..writeln('/// 使用GoRouter进行声明式路由管理')
      ..writeln('class AppRouter {')
      ..writeln('  /// 私有构造函数，防止实例化')
      ..writeln('  AppRouter._();')
      ..writeln();

    // 根据复杂度生成不同的路由配置
    if (config.complexity == TemplateComplexity.simple) {
      _generateSimpleRouter(buffer, config);
    } else if (config.complexity == TemplateComplexity.medium) {
      _generateMediumRouter(buffer, config);
    } else {
      _generateComplexRouter(buffer, config);
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  /// 生成简单路由配置
  void _generateSimpleRouter(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  /// 路由路径常量')
      ..writeln("  static const String home = '/';")
      ..writeln("  static const String settings = '/settings';")
      ..writeln()
      ..writeln('  /// GoRouter实例')
      ..writeln('  static final GoRouter router = GoRouter(')
      ..writeln('    initialLocation: home,')
      ..writeln('    routes: [')
      ..writeln('      GoRoute(')
      ..writeln('        path: home,')
      ..writeln("        name: 'home',")
      ..writeln('        builder: (context, state) => const HomeScreen(),')
      ..writeln('      ),')
      ..writeln('      GoRoute(')
      ..writeln('        path: settings,')
      ..writeln("        name: 'settings',")
      ..writeln('        builder: (context, state) => const SettingsScreen(),')
      ..writeln('      ),')
      ..writeln('    ],')
      ..writeln('  );');
  }

  /// 生成中等复杂度路由配置
  void _generateMediumRouter(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  /// 路由路径常量')
      ..writeln("  static const String home = '/';")
      ..writeln("  static const String settings = '/settings';")
      ..writeln("  static const String profile = '/profile';")
      ..writeln("  static const String about = '/about';")
      ..writeln()
      ..writeln('  /// 全局导航键')
      ..writeln('  static final GlobalKey<NavigatorState> navigatorKey =')
      ..writeln('      GlobalKey<NavigatorState>();')
      ..writeln()
      ..writeln('  /// GoRouter实例')
      ..writeln('  static final GoRouter router = GoRouter(')
      ..writeln('    navigatorKey: navigatorKey,')
      ..writeln('    initialLocation: home,')
      ..writeln('    debugLogDiagnostics: true,')
      ..writeln('    routes: [')
      ..writeln('      GoRoute(')
      ..writeln('        path: home,')
      ..writeln("        name: 'home',")
      ..writeln('        builder: (context, state) => const HomeScreen(),')
      ..writeln('      ),')
      ..writeln('      GoRoute(')
      ..writeln('        path: settings,')
      ..writeln("        name: 'settings',")
      ..writeln('        builder: (context, state) => const SettingsScreen(),')
      ..writeln('      ),')
      ..writeln('      GoRoute(')
      ..writeln('        path: profile,')
      ..writeln("        name: 'profile',")
      ..writeln('        builder: (context, state) => const ProfileScreen(),')
      ..writeln('      ),')
      ..writeln('      GoRoute(')
      ..writeln('        path: about,')
      ..writeln("        name: 'about',")
      ..writeln('        builder: (context, state) => const AboutScreen(),')
      ..writeln('      ),')
      ..writeln('    ],')
      ..writeln('    errorBuilder: (context, state) => Scaffold(')
      ..writeln('      body: Center(')
      ..writeln(r"        child: Text('页面未找到: ${state.location}'),")
      ..writeln('      ),')
      ..writeln('    ),')
      ..writeln('  );');
  }

  /// 生成复杂路由配置
  void _generateComplexRouter(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  /// 路由路径常量')
      ..writeln("  static const String home = '/';")
      ..writeln("  static const String settings = '/settings';")
      ..writeln("  static const String profile = '/profile';")
      ..writeln("  static const String about = '/about';")
      ..writeln("  static const String login = '/login';")
      ..writeln("  static const String error = '/error';")
      ..writeln()
      ..writeln('  /// 全局导航键')
      ..writeln('  static final GlobalKey<NavigatorState> navigatorKey =')
      ..writeln('      GlobalKey<NavigatorState>();')
      ..writeln()
      ..writeln('  /// 路由提供者')
      ..writeln('  static final routerProvider = Provider<GoRouter>((ref) {')
      ..writeln('    final authState = ref.watch(authStateProvider);')
      ..writeln('    ')
      ..writeln('    return GoRouter(')
      ..writeln('      navigatorKey: navigatorKey,')
      ..writeln('      initialLocation: home,')
      ..writeln('      debugLogDiagnostics: true,')
      ..writeln('      redirect: (context, state) {')
      ..writeln('        final isLoggedIn = authState.when(')
      ..writeln('          data: (user) => user != null,')
      ..writeln('          loading: () => false,')
      ..writeln('          error: (_, __) => false,')
      ..writeln('        );')
      ..writeln()
      ..writeln('        final isLoginRoute = state.location == login;')
      ..writeln()
      ..writeln('        // 如果未登录且不在登录页面，重定向到登录页面')
      ..writeln('        if (!isLoggedIn && !isLoginRoute) {')
      ..writeln('          return login;')
      ..writeln('        }')
      ..writeln()
      ..writeln('        // 如果已登录且在登录页面，重定向到首页')
      ..writeln('        if (isLoggedIn && isLoginRoute) {')
      ..writeln('          return home;')
      ..writeln('        }')
      ..writeln()
      ..writeln('        return null;')
      ..writeln('      },')
      ..writeln('      routes: [')
      ..writeln('        GoRoute(')
      ..writeln('          path: home,')
      ..writeln("          name: 'home',")
      ..writeln('          builder: (context, state) => const HomeScreen(),')
      ..writeln('          routes: [')
      ..writeln('            GoRoute(')
      ..writeln("              path: 'details/:id',")
      ..writeln("              name: 'details',")
      ..writeln('              builder: (context, state) {')
      ..writeln("                final id = state.pathParameters['id']!;")
      ..writeln('                return DetailsScreen(id: id);')
      ..writeln('              },')
      ..writeln('            ),')
      ..writeln('          ],')
      ..writeln('        ),')
      ..writeln('        GoRoute(')
      ..writeln('          path: settings,')
      ..writeln("          name: 'settings',")
      ..writeln('          builder: (context, state) => const SettingsScreen(),')
      ..writeln('        ),')
      ..writeln('        GoRoute(')
      ..writeln('          path: profile,')
      ..writeln("          name: 'profile',")
      ..writeln('          builder: (context, state) => const ProfileScreen(),')
      ..writeln('        ),')
      ..writeln('        GoRoute(')
      ..writeln('          path: about,')
      ..writeln("          name: 'about',")
      ..writeln('          builder: (context, state) => const AboutScreen(),')
      ..writeln('        ),')
      ..writeln('        GoRoute(')
      ..writeln('          path: login,')
      ..writeln("          name: 'login',")
      ..writeln('          builder: (context, state) => const LoginScreen(),')
      ..writeln('        ),')
      ..writeln('        GoRoute(')
      ..writeln('          path: error,')
      ..writeln("          name: 'error',")
      ..writeln('          builder: (context, state) {')
      ..writeln('            final error = state.extra as String?;')
      ..writeln('            return ErrorScreen(error: error);')
      ..writeln('          },')
      ..writeln('        ),')
      ..writeln('      ],')
      ..writeln('      errorBuilder: (context, state) => ErrorScreen(')
      ..writeln(r"        error: '页面未找到: ${state.location}',")
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  });')
      ..writeln()
      ..writeln('  /// GoRouter实例（用于非Riverpod环境）')
      ..writeln('  static final GoRouter router = GoRouter(')
      ..writeln('    navigatorKey: navigatorKey,')
      ..writeln('    initialLocation: home,')
      ..writeln('    debugLogDiagnostics: true,')
      ..writeln('    routes: [')
      ..writeln('      GoRoute(')
      ..writeln('        path: home,')
      ..writeln("        name: 'home',")
      ..writeln('        builder: (context, state) => const HomeScreen(),')
      ..writeln('      ),')
      ..writeln('      GoRoute(')
      ..writeln('        path: settings,')
      ..writeln("        name: 'settings',")
      ..writeln('        builder: (context, state) => const SettingsScreen(),')
      ..writeln('      ),')
      ..writeln('      GoRoute(')
      ..writeln('        path: profile,')
      ..writeln("        name: 'profile',")
      ..writeln('        builder: (context, state) => const ProfileScreen(),')
      ..writeln('      ),')
      ..writeln('      GoRoute(')
      ..writeln('        path: about,')
      ..writeln("        name: 'about',")
      ..writeln('        builder: (context, state) => const AboutScreen(),')
      ..writeln('      ),')
      ..writeln('    ],')
      ..writeln('    errorBuilder: (context, state) => ErrorScreen(')
      ..writeln(r"      error: '页面未找到: ${state.location}',")
      ..writeln('    ),')
      ..writeln('  );')
      ..writeln()
      ..writeln('  /// 导航辅助方法')
      ..writeln("  static void goToHome() => router.goNamed('home');")
      ..writeln("  static void goToSettings() => router.goNamed('settings');")
      ..writeln("  static void goToProfile() => router.goNamed('profile');")
      ..writeln("  static void goToAbout() => router.goNamed('about');")
      ..writeln('  ')
      ..writeln('  /// 返回上一页')
      ..writeln('  static void goBack() {')
      ..writeln('    if (router.canPop()) {')
      ..writeln('      router.pop();')
      ..writeln('    }')
      ..writeln('  }')
      ..writeln('  ')
      ..writeln('  /// 获取当前路由')
      ..writeln('  static String get currentLocation => router.location;');
  }

  @override
  Map<String, String> getTemplateVariables(ScaffoldConfig config) {
    final baseVariables = super.getTemplateVariables(config);
    
    // 添加特定于路由的变量
    baseVariables.addAll({
      'routeCount': _getRouteCount(config).toString(),
      'hasAuth': _hasAuthentication(config).toString(),
    });

    return baseVariables;
  }

  /// 获取路由数量
  int _getRouteCount(ScaffoldConfig config) {
    switch (config.complexity) {
      case TemplateComplexity.simple:
        return 2;
      case TemplateComplexity.medium:
        return 4;
      case TemplateComplexity.complex:
      case TemplateComplexity.enterprise:
        return 6;
    }
  }

  /// 是否包含认证
  bool _hasAuthentication(ScaffoldConfig config) {
    return config.complexity == TemplateComplexity.complex ||
           config.complexity == TemplateComplexity.enterprise;
  }
}
