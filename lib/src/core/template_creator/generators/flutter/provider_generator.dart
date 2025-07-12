/*
---------------------------------------------------------------
File name:          provider_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        Flutter Provider生成器 (Flutter Provider Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加更多Provider类型支持
    - [ ] 支持Provider依赖注入
    - [ ] 添加Provider测试生成
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/template_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// Flutter Provider生成器
///
/// 负责生成Flutter应用程序的状态管理Provider文件
class ProviderGenerator extends TemplateGeneratorBase {
  /// 创建Provider生成器实例
  const ProviderGenerator();

  @override
  String getTemplateFileName() => 'app_providers.dart.template';

  @override
  String getOutputFileName(ScaffoldConfig config) => 'app_providers.dart.template';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.writeln(generateFileHeader(
      'app_providers.dart',
      config,
      '${config.templateName}应用程序状态管理Provider',
    ),);

    buffer
      ..writeln()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';")
      ..writeln("import 'package:riverpod_annotation/riverpod_annotation.dart';");

    // 根据复杂度添加不同的导入
    if (config.complexity == TemplateComplexity.medium ||
        config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      buffer
        .writeln("import 'package:shared_preferences/shared_preferences.dart';");
    }

    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      buffer
        ..writeln("import 'package:dio/dio.dart';")
        ..writeln("import '../models/user.dart';")
        ..writeln("import '../services/api_service.dart';")
        ..writeln("import '../services/storage_service.dart';");
    }

    buffer
      ..writeln()
      ..writeln("part 'app_providers.g.dart';")
      ..writeln();

    // 根据复杂度生成不同的Provider配置
    if (config.complexity == TemplateComplexity.simple) {
      _generateSimpleProviders(buffer, config);
    } else if (config.complexity == TemplateComplexity.medium) {
      _generateMediumProviders(buffer, config);
    } else {
      _generateComplexProviders(buffer, config);
    }

    return buffer.toString();
  }

  /// 生成简单Provider配置
  void _generateSimpleProviders(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('/// 主题模式Provider')
      ..writeln('///')
      ..writeln('/// 管理应用程序的主题模式（亮色/暗色）')
      ..writeln('@riverpod')
      ..writeln(r'class ThemeMode extends _$ThemeMode {')
      ..writeln('  @override')
      ..writeln('  ThemeMode build() {')
      ..writeln('    return ThemeMode.system;')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 切换到亮色主题')
      ..writeln('  void setLight() {')
      ..writeln('    state = ThemeMode.light;')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 切换到暗色主题')
      ..writeln('  void setDark() {')
      ..writeln('    state = ThemeMode.dark;')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 切换到系统主题')
      ..writeln('  void setSystem() {')
      ..writeln('    state = ThemeMode.system;')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 切换主题')
      ..writeln('  void toggle() {')
      ..writeln('    switch (state) {')
      ..writeln('      case ThemeMode.light:')
      ..writeln('        setDark();')
      ..writeln('        break;')
      ..writeln('      case ThemeMode.dark:')
      ..writeln('        setLight();')
      ..writeln('        break;')
      ..writeln('      case ThemeMode.system:')
      ..writeln('        setLight();')
      ..writeln('        break;')
      ..writeln('    }')
      ..writeln('  }')
      ..writeln('}')
      ..writeln()
      ..writeln('/// 计数器Provider')
      ..writeln('///')
      ..writeln('/// 简单的计数器状态管理示例')
      ..writeln('@riverpod')
      ..writeln(r'class Counter extends _$Counter {')
      ..writeln('  @override')
      ..writeln('  int build() {')
      ..writeln('    return 0;')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 增加计数')
      ..writeln('  void increment() {')
      ..writeln('    state++;')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 减少计数')
      ..writeln('  void decrement() {')
      ..writeln('    state--;')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 重置计数')
      ..writeln('  void reset() {')
      ..writeln('    state = 0;')
      ..writeln('  }')
      ..writeln('}');
  }

  /// 生成中等复杂度Provider配置
  void _generateMediumProviders(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('/// SharedPreferences Provider')
      ..writeln('///')
      ..writeln('/// 提供SharedPreferences实例')
      ..writeln('@riverpod')
      ..writeln('Future<SharedPreferences> sharedPreferences(')
      ..writeln('  SharedPreferencesRef ref,')
      ..writeln(') async {')
      ..writeln('  return await SharedPreferences.getInstance();')
      ..writeln('}')
      ..writeln()
      ..writeln('/// 主题模式Provider')
      ..writeln('///')
      ..writeln('/// 管理应用程序的主题模式，支持持久化')
      ..writeln('@riverpod')
      ..writeln(r'class ThemeModeNotifier extends _$ThemeModeNotifier {')
      ..writeln("  static const String _key = 'theme_mode';")
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Future<ThemeMode> build() async {')
      ..writeln('    final prefs = await ref.watch(sharedPreferencesProvider.future);')
      ..writeln('    final themeModeIndex = prefs.getInt(_key) ?? 0;')
      ..writeln('    return ThemeMode.values[themeModeIndex];')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 设置主题模式')
      ..writeln('  Future<void> setThemeMode(ThemeMode themeMode) async {')
      ..writeln('    final prefs = await ref.read(sharedPreferencesProvider.future);')
      ..writeln('    await prefs.setInt(_key, themeMode.index);')
      ..writeln('    state = AsyncValue.data(themeMode);')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 切换主题')
      ..writeln('  Future<void> toggleTheme() async {')
      ..writeln('    final currentTheme = await future;')
      ..writeln('    final newTheme = currentTheme == ThemeMode.light')
      ..writeln('        ? ThemeMode.dark')
      ..writeln('        : ThemeMode.light;')
      ..writeln('    await setThemeMode(newTheme);')
      ..writeln('  }')
      ..writeln('}')
      ..writeln()
      ..writeln('/// 语言Provider')
      ..writeln('///')
      ..writeln('/// 管理应用程序的语言设置')
      ..writeln('@riverpod')
      ..writeln(r'class LocaleNotifier extends _$LocaleNotifier {')
      ..writeln("  static const String _key = 'locale';")
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Future<Locale> build() async {')
      ..writeln('    final prefs = await ref.watch(sharedPreferencesProvider.future);')
      ..writeln("    final localeCode = prefs.getString(_key) ?? 'en';")
      ..writeln('    return Locale(localeCode);')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 设置语言')
      ..writeln('  Future<void> setLocale(Locale locale) async {')
      ..writeln('    final prefs = await ref.read(sharedPreferencesProvider.future);')
      ..writeln('    await prefs.setString(_key, locale.languageCode);')
      ..writeln('    state = AsyncValue.data(locale);')
      ..writeln('  }')
      ..writeln('}')
      ..writeln()
      ..writeln('/// 应用设置Provider')
      ..writeln('///')
      ..writeln('/// 管理应用程序的各种设置')
      ..writeln('@riverpod')
      ..writeln(r'class AppSettings extends _$AppSettings {')
      ..writeln('  @override')
      ..writeln('  Map<String, dynamic> build() {')
      ..writeln('    return {')
      ..writeln("      'notifications': true,")
      ..writeln("      'autoSave': true,")
      ..writeln("      'fontSize': 14.0,")
      ..writeln('    };')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 更新设置')
      ..writeln('  void updateSetting(String key, dynamic value) {')
      ..writeln('    state = {...state, key: value};')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 获取设置值')
      ..writeln('  T? getSetting<T>(String key) {')
      ..writeln('    return state[key] as T?;')
      ..writeln('  }')
      ..writeln('}');
  }

  /// 生成复杂Provider配置
  void _generateComplexProviders(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('/// Dio HTTP客户端Provider')
      ..writeln('///')
      ..writeln('/// 提供配置好的Dio实例')
      ..writeln('@riverpod')
      ..writeln('Dio dio(DioRef ref) {')
      ..writeln('  final dio = Dio();')
      ..writeln('  ')
      ..writeln('  // 基础配置')
      ..writeln("  dio.options.baseUrl = 'https://api.example.com';")
      ..writeln('  dio.options.connectTimeout = const Duration(seconds: 30);')
      ..writeln('  dio.options.receiveTimeout = const Duration(seconds: 30);')
      ..writeln('  ')
      ..writeln('  // 添加拦截器')
      ..writeln('  dio.interceptors.add(')
      ..writeln('    LogInterceptor(')
      ..writeln('      requestBody: true,')
      ..writeln('      responseBody: true,')
      ..writeln('    ),')
      ..writeln('  );')
      ..writeln('  ')
      ..writeln('  return dio;')
      ..writeln('}')
      ..writeln()
      ..writeln('/// API服务Provider')
      ..writeln('///')
      ..writeln('/// 提供API服务实例')
      ..writeln('@riverpod')
      ..writeln('ApiService apiService(ApiServiceRef ref) {')
      ..writeln('  final dio = ref.watch(dioProvider);')
      ..writeln('  return ApiService(dio);')
      ..writeln('}')
      ..writeln()
      ..writeln('/// 存储服务Provider')
      ..writeln('///')
      ..writeln('/// 提供本地存储服务')
      ..writeln('@riverpod')
      ..writeln('Future<StorageService> storageService(StorageServiceRef ref) async {')
      ..writeln('  final prefs = await ref.watch(sharedPreferencesProvider.future);')
      ..writeln('  return StorageService(prefs);')
      ..writeln('}')
      ..writeln()
      ..writeln('/// 用户认证Provider')
      ..writeln('///')
      ..writeln('/// 管理用户认证状态')
      ..writeln('@riverpod')
      ..writeln(r'class AuthNotifier extends _$AuthNotifier {')
      ..writeln('  @override')
      ..writeln('  Future<User?> build() async {')
      ..writeln('    // 从本地存储加载用户信息')
      ..writeln('    final storage = await ref.watch(storageServiceProvider.future);')
      ..writeln('    final userData = await storage.getUser();')
      ..writeln('    return userData;')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 登录')
      ..writeln('  Future<void> login(String email, String password) async {')
      ..writeln('    state = const AsyncValue.loading();')
      ..writeln('    ')
      ..writeln('    try {')
      ..writeln('      final apiService = ref.read(apiServiceProvider);')
      ..writeln('      final user = await apiService.login(email, password);')
      ..writeln('      ')
      ..writeln('      // 保存用户信息到本地')
      ..writeln('      final storage = await ref.read(storageServiceProvider.future);')
      ..writeln('      await storage.saveUser(user);')
      ..writeln('      ')
      ..writeln('      state = AsyncValue.data(user);')
      ..writeln('    } catch (error, stackTrace) {')
      ..writeln('      state = AsyncValue.error(error, stackTrace);')
      ..writeln('    }')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 登出')
      ..writeln('  Future<void> logout() async {')
      ..writeln('    state = const AsyncValue.loading();')
      ..writeln('    ')
      ..writeln('    try {')
      ..writeln('      final storage = await ref.read(storageServiceProvider.future);')
      ..writeln('      await storage.clearUser();')
      ..writeln('      ')
      ..writeln('      state = const AsyncValue.data(null);')
      ..writeln('    } catch (error, stackTrace) {')
      ..writeln('      state = AsyncValue.error(error, stackTrace);')
      ..writeln('    }')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 刷新用户信息')
      ..writeln('  Future<void> refreshUser() async {')
      ..writeln('    final currentUser = state.value;')
      ..writeln('    if (currentUser == null) return;')
      ..writeln('    ')
      ..writeln('    state = const AsyncValue.loading();')
      ..writeln('    ')
      ..writeln('    try {')
      ..writeln('      final apiService = ref.read(apiServiceProvider);')
      ..writeln('      final user = await apiService.getCurrentUser();')
      ..writeln('      ')
      ..writeln('      final storage = await ref.read(storageServiceProvider.future);')
      ..writeln('      await storage.saveUser(user);')
      ..writeln('      ')
      ..writeln('      state = AsyncValue.data(user);')
      ..writeln('    } catch (error, stackTrace) {')
      ..writeln('      state = AsyncValue.error(error, stackTrace);')
      ..writeln('    }')
      ..writeln('  }')
      ..writeln('}')
      ..writeln()
      ..writeln('/// 应用状态Provider')
      ..writeln('///')
      ..writeln('/// 管理应用程序的全局状态')
      ..writeln('@riverpod')
      ..writeln(r'class AppState extends _$AppState {')
      ..writeln('  @override')
      ..writeln('  Map<String, dynamic> build() {')
      ..writeln('    return {')
      ..writeln("      'isLoading': false,")
      ..writeln("      'isOnline': true,")
      ..writeln("      'lastSync': null,")
      ..writeln("      'notifications': <String>[],")
      ..writeln('    };')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 设置加载状态')
      ..writeln('  void setLoading(bool isLoading) {')
      ..writeln("    state = {...state, 'isLoading': isLoading};")
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 设置在线状态')
      ..writeln('  void setOnlineStatus(bool isOnline) {')
      ..writeln("    state = {...state, 'isOnline': isOnline};")
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 更新最后同步时间')
      ..writeln('  void updateLastSync() {')
      ..writeln("    state = {...state, 'lastSync': DateTime.now()};")
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 添加通知')
      ..writeln('  void addNotification(String message) {')
      ..writeln("    final notifications = List<String>.from(state['notifications']);")
      ..writeln('    notifications.add(message);')
      ..writeln("    state = {...state, 'notifications': notifications};")
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// 清除通知')
      ..writeln('  void clearNotifications() {')
      ..writeln("    state = {...state, 'notifications': <String>[]};")
      ..writeln('  }')
      ..writeln('}');
  }

  @override
  Map<String, String> getTemplateVariables(ScaffoldConfig config) {
    final baseVariables = super.getTemplateVariables(config);
    
    // 添加特定于Provider的变量
    baseVariables.addAll({
      'providerCount': _getProviderCount(config).toString(),
      'hasAuth': _hasAuthentication(config).toString(),
      'hasApi': _hasApiIntegration(config).toString(),
    });

    return baseVariables;
  }

  /// 获取Provider数量
  int _getProviderCount(ScaffoldConfig config) {
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

  /// 是否包含API集成
  bool _hasApiIntegration(ScaffoldConfig config) {
    return config.complexity == TemplateComplexity.complex ||
           config.complexity == TemplateComplexity.enterprise;
  }
}
