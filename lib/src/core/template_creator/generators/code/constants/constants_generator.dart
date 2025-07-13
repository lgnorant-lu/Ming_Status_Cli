/*
---------------------------------------------------------------
File name:          constants_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        常量定义Constants文件生成器
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 常量定义Constants文件生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/base/base_code_generator.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 常量定义Constants文件生成器
///
/// 生成应用程序常量定义文件
class ConstantsGenerator extends BaseCodeGenerator {
  /// 创建Constants生成器实例
  const ConstantsGenerator();

  @override
  String getFileName(ScaffoldConfig config) {
    return '${config.templateName}_constants.dart';
  }

  @override
  String getRelativePath(ScaffoldConfig config) {
    return 'lib/src/constants';
  }

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();
    
    // 添加文件头部注释
    buffer.write(generateFileHeader(
      getFileName(config),
      config,
      '${config.templateName}应用程序常量定义',
    ),);

    final imports = _getImports(config);
    buffer.write(generateImports(imports));
    
    // 生成应用常量类
    _generateAppConstants(buffer, config);
    
    // 生成API常量类
    _generateApiConstants(buffer, config);
    
    // 生成UI常量类
    if (config.framework == TemplateFramework.flutter) {
      _generateUiConstants(buffer, config);
    }
    
    // 生成配置常量类
    _generateConfigConstants(buffer, config);
    
    // 生成错误常量类
    _generateErrorConstants(buffer, config);

    return buffer.toString();
  }

  /// 获取导入
  List<String> _getImports(ScaffoldConfig config) {
    final imports = <String>[];
    
    if (config.framework == TemplateFramework.flutter) {
      imports.addAll([
        'package:flutter/material.dart',
      ]);
    }
    
    return imports;
  }

  /// 生成应用常量类
  void _generateAppConstants(StringBuffer buffer, ScaffoldConfig config) {
    final className = '${_getCapitalizedName(config)}AppConstants';
    
    buffer.write(generateClassDocumentation(
      className,
      '${config.templateName}应用程序基础常量',
      examples: [
        '$className.appName',
        '$className.version',
        '$className.buildNumber',
      ],
    ),);

    buffer.writeln('class $className {');
    buffer.writeln('  /// 私有构造函数，防止实例化');
    buffer.writeln('  $className._();');
    buffer.writeln();
    
    // 应用信息
    buffer.writeln('  /// 应用名称');
    buffer.writeln("  static const String appName = '${_getCapitalizedName(config)}';");
    buffer.writeln();
    
    buffer.writeln('  /// 应用版本');
    buffer.writeln("  static const String version = '1.0.0';");
    buffer.writeln();
    
    buffer.writeln('  /// 构建号');
    buffer.writeln('  static const int buildNumber = 1;');
    buffer.writeln();
    
    buffer.writeln('  /// 应用包名');
    buffer.writeln("  static const String packageName = 'com.example.${config.templateName}';");
    buffer.writeln();
    
    // 环境配置
    buffer.writeln('  /// 开发环境');
    buffer.writeln("  static const String envDevelopment = 'development';");
    buffer.writeln();
    
    buffer.writeln('  /// 测试环境');
    buffer.writeln("  static const String envTesting = 'testing';");
    buffer.writeln();
    
    buffer.writeln('  /// 生产环境');
    buffer.writeln("  static const String envProduction = 'production';");
    buffer.writeln();
    
    // 默认值
    buffer.writeln('  /// 默认超时时间（秒）');
    buffer.writeln('  static const int defaultTimeoutSeconds = 30;');
    buffer.writeln();
    
    buffer.writeln('  /// 默认分页大小');
    buffer.writeln('  static const int defaultPageSize = 20;');
    buffer.writeln();
    
    buffer.writeln('  /// 最大分页大小');
    buffer.writeln('  static const int maxPageSize = 100;');
    buffer.writeln();
    
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('  /// 缓存过期时间（毫秒）');
      buffer.writeln('  static const int cacheExpirationMs = 300000; // 5分钟');
      buffer.writeln();
      
      buffer.writeln('  /// 最大重试次数');
      buffer.writeln('  static const int maxRetryAttempts = 3;');
      buffer.writeln();
      
      buffer.writeln('  /// 重试延迟（毫秒）');
      buffer.writeln('  static const int retryDelayMs = 1000;');
      buffer.writeln();
    }
    
    buffer.writeln('}');
    buffer.writeln();
  }

  /// 生成API常量类
  void _generateApiConstants(StringBuffer buffer, ScaffoldConfig config) {
    final className = '${_getCapitalizedName(config)}ApiConstants';
    
    buffer.write(generateClassDocumentation(
      className,
      '${config.templateName}API相关常量',
      examples: [
        '$className.baseUrl',
        '$className.endpoints.users',
        '$className.headers.contentType',
      ],
    ),);

    buffer.writeln('class $className {');
    buffer.writeln('  /// 私有构造函数，防止实例化');
    buffer.writeln('  $className._();');
    buffer.writeln();
    
    // 基础URL
    buffer.writeln('  /// 开发环境API基础URL');
    buffer.writeln("  static const String baseUrlDev = 'https://api-dev.example.com';");
    buffer.writeln();
    
    buffer.writeln('  /// 测试环境API基础URL');
    buffer.writeln("  static const String baseUrlTest = 'https://api-test.example.com';");
    buffer.writeln();
    
    buffer.writeln('  /// 生产环境API基础URL');
    buffer.writeln("  static const String baseUrlProd = 'https://api.example.com';");
    buffer.writeln();
    
    buffer.writeln('  /// 当前环境API基础URL');
    buffer.writeln('  static const String baseUrl = baseUrlDev; // TODO: 根据环境配置');
    buffer.writeln();
    
    // API端点
    buffer.writeln('  /// API端点');
    buffer.writeln('  static const ApiEndpoints endpoints = ApiEndpoints._();');
    buffer.writeln();
    
    // HTTP头部
    buffer.writeln('  /// HTTP头部');
    buffer.writeln('  static const ApiHeaders headers = ApiHeaders._();');
    buffer.writeln();
    
    // 状态码
    buffer.writeln('  /// HTTP状态码');
    buffer.writeln('  static const ApiStatusCodes statusCodes = ApiStatusCodes._();');
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // API端点类
    buffer.writeln('/// API端点常量');
    buffer.writeln('class ApiEndpoints {');
    buffer.writeln('  const ApiEndpoints._();');
    buffer.writeln();
    
    buffer.writeln('  /// 用户相关端点');
    buffer.writeln("  String get users => '/api/v1/users';");
    buffer.writeln("  String get userProfile => '/api/v1/users/profile';");
    buffer.writeln("  String get userById => '/api/v1/users/{id}';");
    buffer.writeln();
    
    buffer.writeln('  /// 认证相关端点');
    buffer.writeln("  String get login => '/api/v1/auth/login';");
    buffer.writeln("  String get logout => '/api/v1/auth/logout';");
    buffer.writeln("  String get refresh => '/api/v1/auth/refresh';");
    buffer.writeln();
    
    buffer.writeln('  /// ${config.templateName}相关端点');
    buffer.writeln("  String get ${config.templateName}s => '/api/v1/${config.templateName}s';");
    buffer.writeln("  String get ${config.templateName}ById => '/api/v1/${config.templateName}s/{id}';");
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // HTTP头部类
    buffer.writeln('/// HTTP头部常量');
    buffer.writeln('class ApiHeaders {');
    buffer.writeln('  const ApiHeaders._();');
    buffer.writeln();
    
    buffer.writeln('  /// Content-Type');
    buffer.writeln("  String get contentType => 'Content-Type';");
    buffer.writeln("  String get contentTypeJson => 'application/json';");
    buffer.writeln("  String get contentTypeForm => 'application/x-www-form-urlencoded';");
    buffer.writeln();
    
    buffer.writeln('  /// Authorization');
    buffer.writeln("  String get authorization => 'Authorization';");
    buffer.writeln("  String get bearer => 'Bearer';");
    buffer.writeln();
    
    buffer.writeln('  /// Accept');
    buffer.writeln("  String get accept => 'Accept';");
    buffer.writeln("  String get acceptJson => 'application/json';");
    buffer.writeln();
    
    buffer.writeln('  /// User-Agent');
    buffer.writeln("  String get userAgent => 'User-Agent';");
    buffer.writeln("  String get defaultUserAgent => '${_getCapitalizedName(config)}/1.0.0';");
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // 状态码类
    buffer.writeln('/// HTTP状态码常量');
    buffer.writeln('class ApiStatusCodes {');
    buffer.writeln('  const ApiStatusCodes._();');
    buffer.writeln();
    
    buffer.writeln('  /// 成功状态码');
    buffer.writeln('  int get ok => 200;');
    buffer.writeln('  int get created => 201;');
    buffer.writeln('  int get accepted => 202;');
    buffer.writeln('  int get noContent => 204;');
    buffer.writeln();
    
    buffer.writeln('  /// 客户端错误状态码');
    buffer.writeln('  int get badRequest => 400;');
    buffer.writeln('  int get unauthorized => 401;');
    buffer.writeln('  int get forbidden => 403;');
    buffer.writeln('  int get notFound => 404;');
    buffer.writeln('  int get methodNotAllowed => 405;');
    buffer.writeln('  int get conflict => 409;');
    buffer.writeln('  int get unprocessableEntity => 422;');
    buffer.writeln('  int get tooManyRequests => 429;');
    buffer.writeln();
    
    buffer.writeln('  /// 服务器错误状态码');
    buffer.writeln('  int get internalServerError => 500;');
    buffer.writeln('  int get badGateway => 502;');
    buffer.writeln('  int get serviceUnavailable => 503;');
    buffer.writeln('  int get gatewayTimeout => 504;');
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
  }

  /// 生成UI常量类
  void _generateUiConstants(StringBuffer buffer, ScaffoldConfig config) {
    final className = '${_getCapitalizedName(config)}UiConstants';
    
    buffer.write(generateClassDocumentation(
      className,
      '${config.templateName}UI相关常量',
      examples: [
        '$className.spacing.small',
        '$className.borderRadius.medium',
        '$className.animationDuration.fast',
      ],
    ),);

    buffer.writeln('class $className {');
    buffer.writeln('  /// 私有构造函数，防止实例化');
    buffer.writeln('  $className._();');
    buffer.writeln();
    
    buffer.writeln('  /// 间距常量');
    buffer.writeln('  static const UiSpacing spacing = UiSpacing._();');
    buffer.writeln();
    
    buffer.writeln('  /// 圆角常量');
    buffer.writeln('  static const UiBorderRadius borderRadius = UiBorderRadius._();');
    buffer.writeln();
    
    buffer.writeln('  /// 动画时长常量');
    buffer.writeln('  static const UiAnimationDuration animationDuration = UiAnimationDuration._();');
    buffer.writeln();
    
    buffer.writeln('  /// 字体大小常量');
    buffer.writeln('  static const UiFontSize fontSize = UiFontSize._();');
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // 间距常量类
    buffer.writeln('/// UI间距常量');
    buffer.writeln('class UiSpacing {');
    buffer.writeln('  const UiSpacing._();');
    buffer.writeln();
    
    buffer.writeln('  double get xs => 4.0;');
    buffer.writeln('  double get small => 8.0;');
    buffer.writeln('  double get medium => 16.0;');
    buffer.writeln('  double get large => 24.0;');
    buffer.writeln('  double get xl => 32.0;');
    buffer.writeln('  double get xxl => 48.0;');
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // 圆角常量类
    buffer.writeln('/// UI圆角常量');
    buffer.writeln('class UiBorderRadius {');
    buffer.writeln('  const UiBorderRadius._();');
    buffer.writeln();
    
    buffer.writeln('  double get small => 4.0;');
    buffer.writeln('  double get medium => 8.0;');
    buffer.writeln('  double get large => 12.0;');
    buffer.writeln('  double get xl => 16.0;');
    buffer.writeln('  double get circular => 999.0;');
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // 动画时长常量类
    buffer.writeln('/// UI动画时长常量');
    buffer.writeln('class UiAnimationDuration {');
    buffer.writeln('  const UiAnimationDuration._();');
    buffer.writeln();
    
    buffer.writeln('  Duration get fast => const Duration(milliseconds: 150);');
    buffer.writeln('  Duration get medium => const Duration(milliseconds: 300);');
    buffer.writeln('  Duration get slow => const Duration(milliseconds: 500);');
    buffer.writeln('  Duration get verySlow => const Duration(milliseconds: 1000);');
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // 字体大小常量类
    buffer.writeln('/// UI字体大小常量');
    buffer.writeln('class UiFontSize {');
    buffer.writeln('  const UiFontSize._();');
    buffer.writeln();
    
    buffer.writeln('  double get xs => 10.0;');
    buffer.writeln('  double get small => 12.0;');
    buffer.writeln('  double get medium => 14.0;');
    buffer.writeln('  double get large => 16.0;');
    buffer.writeln('  double get xl => 18.0;');
    buffer.writeln('  double get xxl => 20.0;');
    buffer.writeln('  double get title => 24.0;');
    buffer.writeln('  double get heading => 32.0;');
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
  }

  /// 生成配置常量类
  void _generateConfigConstants(StringBuffer buffer, ScaffoldConfig config) {
    final className = '${_getCapitalizedName(config)}ConfigConstants';
    
    buffer.write(generateClassDocumentation(
      className,
      '${config.templateName}配置相关常量',
      examples: [
        '$className.database.name',
        '$className.storage.cacheDir',
        '$className.logging.level',
      ],
    ),);

    buffer.writeln('class $className {');
    buffer.writeln('  /// 私有构造函数，防止实例化');
    buffer.writeln('  $className._();');
    buffer.writeln();
    
    buffer.writeln('  /// 数据库配置');
    buffer.writeln('  static const DatabaseConfig database = DatabaseConfig._();');
    buffer.writeln();
    
    buffer.writeln('  /// 存储配置');
    buffer.writeln('  static const StorageConfig storage = StorageConfig._();');
    buffer.writeln();
    
    buffer.writeln('  /// 日志配置');
    buffer.writeln('  static const LoggingConfig logging = LoggingConfig._();');
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // 数据库配置类
    buffer.writeln('/// 数据库配置常量');
    buffer.writeln('class DatabaseConfig {');
    buffer.writeln('  const DatabaseConfig._();');
    buffer.writeln();
    
    buffer.writeln("  String get name => '${config.templateName}.db';");
    buffer.writeln('  int get version => 1;');
    buffer.writeln('  int get connectionPoolSize => 10;');
    buffer.writeln('  Duration get connectionTimeout => const Duration(seconds: 30);');
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // 存储配置类
    buffer.writeln('/// 存储配置常量');
    buffer.writeln('class StorageConfig {');
    buffer.writeln('  const StorageConfig._();');
    buffer.writeln();
    
    buffer.writeln("  String get cacheDir => 'cache';");
    buffer.writeln("  String get tempDir => 'temp';");
    buffer.writeln("  String get dataDir => 'data';");
    buffer.writeln("  String get logDir => 'logs';");
    buffer.writeln();
    
    buffer.writeln('  /// 最大缓存大小（字节）');
    buffer.writeln('  int get maxCacheSize => 100 * 1024 * 1024; // 100MB');
    buffer.writeln();
    
    buffer.writeln('  /// 最大日志文件大小（字节）');
    buffer.writeln('  int get maxLogFileSize => 10 * 1024 * 1024; // 10MB');
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // 日志配置类
    buffer.writeln('/// 日志配置常量');
    buffer.writeln('class LoggingConfig {');
    buffer.writeln('  const LoggingConfig._();');
    buffer.writeln();
    
    buffer.writeln("  String get level => 'INFO';");
    buffer.writeln("  String get format => '[{timestamp}] {level}: {message}';");
    buffer.writeln('  bool get enableConsole => true;');
    buffer.writeln('  bool get enableFile => true;');
    buffer.writeln('  int get maxFiles => 7; // 保留7天的日志');
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
  }

  /// 生成错误常量类
  void _generateErrorConstants(StringBuffer buffer, ScaffoldConfig config) {
    final className = '${_getCapitalizedName(config)}ErrorConstants';
    
    buffer.write(generateClassDocumentation(
      className,
      '${config.templateName}错误相关常量',
      examples: [
        '$className.codes.networkError',
        '$className.messages.invalidInput',
        '$className.types.validation',
      ],
    ),);

    buffer.writeln('class $className {');
    buffer.writeln('  /// 私有构造函数，防止实例化');
    buffer.writeln('  $className._();');
    buffer.writeln();
    
    buffer.writeln('  /// 错误代码');
    buffer.writeln('  static const ErrorCodes codes = ErrorCodes._();');
    buffer.writeln();
    
    buffer.writeln('  /// 错误消息');
    buffer.writeln('  static const ErrorMessages messages = ErrorMessages._();');
    buffer.writeln();
    
    buffer.writeln('  /// 错误类型');
    buffer.writeln('  static const ErrorTypes types = ErrorTypes._();');
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // 错误代码类
    buffer.writeln('/// 错误代码常量');
    buffer.writeln('class ErrorCodes {');
    buffer.writeln('  const ErrorCodes._();');
    buffer.writeln();
    
    buffer.writeln("  String get unknown => 'UNKNOWN_ERROR';");
    buffer.writeln("  String get networkError => 'NETWORK_ERROR';");
    buffer.writeln("  String get timeoutError => 'TIMEOUT_ERROR';");
    buffer.writeln("  String get validationError => 'VALIDATION_ERROR';");
    buffer.writeln("  String get authenticationError => 'AUTHENTICATION_ERROR';");
    buffer.writeln("  String get authorizationError => 'AUTHORIZATION_ERROR';");
    buffer.writeln("  String get notFoundError => 'NOT_FOUND_ERROR';");
    buffer.writeln("  String get serverError => 'SERVER_ERROR';");
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // 错误消息类
    buffer.writeln('/// 错误消息常量');
    buffer.writeln('class ErrorMessages {');
    buffer.writeln('  const ErrorMessages._();');
    buffer.writeln();
    
    buffer.writeln("  String get unknown => '发生未知错误';");
    buffer.writeln("  String get networkError => '网络连接失败，请检查网络设置';");
    buffer.writeln("  String get timeoutError => '请求超时，请稍后重试';");
    buffer.writeln("  String get validationError => '输入数据验证失败';");
    buffer.writeln("  String get authenticationError => '身份验证失败，请重新登录';");
    buffer.writeln("  String get authorizationError => '权限不足，无法执行此操作';");
    buffer.writeln("  String get notFoundError => '请求的资源不存在';");
    buffer.writeln("  String get serverError => '服务器内部错误，请稍后重试';");
    buffer.writeln();
    
    buffer.writeln('}');
    buffer.writeln();
    
    // 错误类型类
    buffer.writeln('/// 错误类型常量');
    buffer.writeln('class ErrorTypes {');
    buffer.writeln('  const ErrorTypes._();');
    buffer.writeln();
    
    buffer.writeln("  String get network => 'network';");
    buffer.writeln("  String get validation => 'validation';");
    buffer.writeln("  String get authentication => 'authentication';");
    buffer.writeln("  String get authorization => 'authorization';");
    buffer.writeln("  String get business => 'business';");
    buffer.writeln("  String get system => 'system';");
    buffer.writeln();
    
    buffer.writeln('}');
  }

  /// 获取首字母大写的名称
  String _getCapitalizedName(ScaffoldConfig config) {
    final name = config.templateName;
    return name[0].toUpperCase() + name.substring(1);
  }
}
