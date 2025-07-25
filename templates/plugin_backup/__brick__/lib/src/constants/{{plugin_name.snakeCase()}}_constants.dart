/*
---------------------------------------------------------------
File name:          {{plugin_name.snakeCase()}}_constants.dart
Author:             {{author}}{{#author_email}}
Email:              {{author_email}}{{/author_email}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       {{dart_version}}
Description:        {{plugin_name.titleCase()}}插件常量定义
---------------------------------------------------------------
Change History:
    {{generated_date}}: Initial creation - 插件常量定义;
---------------------------------------------------------------
*/

/// {{plugin_name.titleCase()}}插件常量
/// 
/// 定义插件使用的所有常量值
class {{plugin_name.pascalCase()}}Constants {
  /// 私有构造函数，防止实例化
  {{plugin_name.pascalCase()}}Constants._();

  // ============================================================================
  // 插件基本信息
  // ============================================================================

  /// 插件ID
  static const String pluginId = '{{plugin_name}}';

  /// 插件名称
  static const String pluginName = '{{#plugin_display_name}}{{plugin_display_name}}{{/plugin_display_name}}{{^plugin_display_name}}{{plugin_name.titleCase()}}{{/plugin_display_name}}';

  /// 插件版本
  static const String pluginVersion = '{{version}}';

  /// 插件描述
  static const String pluginDescription = '{{description}}';

  /// 插件作者
  static const String pluginAuthor = '{{author}}';{{#author_email}}

  /// 插件作者邮箱
  static const String pluginAuthorEmail = '{{author_email}}';{{/author_email}}

  /// 插件类型
  static const String pluginType = '{{plugin_type}}';

  /// 插件许可证
  static const String pluginLicense = '{{license}}';

  // ============================================================================
  // 配置相关常量
  // ============================================================================

  /// 默认配置文件名
  static const String defaultConfigFileName = '{{plugin_name}}_config.json';

  /// 配置文件目录
  static const String configDirectory = 'config';

  /// 数据存储目录
  static const String dataDirectory = 'data';

  /// 日志文件目录
  static const String logDirectory = 'logs';

  /// 缓存目录
  static const String cacheDirectory = 'cache';

  /// 临时文件目录
  static const String tempDirectory = 'temp';

  // ============================================================================
  // 默认配置值
  // ============================================================================

  /// 默认启用状态
  static const bool defaultEnabled = true;

  /// 默认自动启动状态
  static const bool defaultAutoStart = false;

  /// 默认调试模式状态
  static const bool defaultDebugMode = false;

  /// 默认最大重试次数
  static const int defaultMaxRetries = 3;

  /// 默认超时时间（毫秒）
  static const int defaultTimeoutMs = 30000;

  /// 默认日志级别
  static const String defaultLogLevel = 'info';

  // ============================================================================
  // 性能相关常量
  // ============================================================================

  /// 最大内存使用量（MB）
  static const int maxMemoryUsageMB = 100;

  /// 最大CPU使用率（%）
  static const int maxCpuUsagePercent = 50;

  /// 启动超时时间（秒）
  static const int startupTimeoutSeconds = 30;

  /// 响应超时时间（秒）
  static const int responseTimeoutSeconds = 10;

  /// 心跳检查间隔（秒）
  static const int heartbeatIntervalSeconds = 60;

  // ============================================================================
  // 事件相关常量
  // ============================================================================

  /// 事件历史最大保存数量
  static const int maxEventHistoryCount = 1000;

  /// 事件处理超时时间（毫秒）
  static const int eventProcessingTimeoutMs = 5000;

  // ============================================================================
  // UI相关常量
  // ============================================================================{{#include_ui_components}}

  /// 默认窗口宽度
  static const double defaultWindowWidth = 800.0;

  /// 默认窗口高度
  static const double defaultWindowHeight = 600.0;

  /// 最小窗口宽度
  static const double minWindowWidth = 400.0;

  /// 最小窗口高度
  static const double minWindowHeight = 300.0;

  /// 默认边距
  static const double defaultPadding = 16.0;

  /// 默认圆角半径
  static const double defaultBorderRadius = 8.0;

  /// 动画持续时间（毫秒）
  static const int animationDurationMs = 300;{{/include_ui_components}}

  // ============================================================================
  // 网络相关常量
  // ============================================================================{{#need_network}}

  /// 默认连接超时时间（秒）
  static const int defaultConnectionTimeoutSeconds = 10;

  /// 默认读取超时时间（秒）
  static const int defaultReadTimeoutSeconds = 30;

  /// 最大重连次数
  static const int maxReconnectAttempts = 5;

  /// 重连间隔时间（秒）
  static const int reconnectIntervalSeconds = 5;

  /// 默认用户代理
  static const String defaultUserAgent = '{{plugin_name}}/{{version}}';{{/need_network}}

  // ============================================================================
  // 文件系统相关常量
  // ============================================================================{{#need_file_system}}

  /// 支持的文件扩展名
  static const List<String> supportedFileExtensions = [
    '.txt',
    '.json',
    '.yaml',
    '.yml',
    '.xml',
    '.csv',
  ];

  /// 最大文件大小（字节）
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  /// 默认文件编码
  static const String defaultFileEncoding = 'utf-8';{{/need_file_system}}

  // ============================================================================
  // 错误代码常量
  // ============================================================================

  /// 通用错误代码
  static const String errorCodeGeneral = 'GENERAL_ERROR';

  /// 初始化错误代码
  static const String errorCodeInitialization = 'INITIALIZATION_ERROR';

  /// 配置错误代码
  static const String errorCodeConfiguration = 'CONFIGURATION_ERROR';

  /// 网络错误代码
  static const String errorCodeNetwork = 'NETWORK_ERROR';

  /// 文件系统错误代码
  static const String errorCodeFileSystem = 'FILE_SYSTEM_ERROR';

  /// 权限错误代码
  static const String errorCodePermission = 'PERMISSION_ERROR';

  /// 超时错误代码
  static const String errorCodeTimeout = 'TIMEOUT_ERROR';

  /// 验证错误代码
  static const String errorCodeValidation = 'VALIDATION_ERROR';

  // ============================================================================
  // 消息常量
  // ============================================================================

  /// 成功消息
  static const String messageSuccess = '操作成功完成';

  /// 初始化成功消息
  static const String messageInitializationSuccess = '插件初始化成功';

  /// 启动成功消息
  static const String messageStartSuccess = '插件启动成功';

  /// 停止成功消息
  static const String messageStopSuccess = '插件停止成功';

  /// 配置更新成功消息
  static const String messageConfigUpdateSuccess = '配置更新成功';

  // ============================================================================
  // 平台相关常量
  // ============================================================================{{#support_android}}

  /// Android最小SDK版本
  static const int androidMinSdkVersion = 21;

  /// Android目标SDK版本
  static const int androidTargetSdkVersion = 34;{{/support_android}}{{#support_ios}}

  /// iOS最小部署目标
  static const String iosMinDeploymentTarget = '12.0';{{/support_ios}}{{#support_web}}

  /// Web最小浏览器版本
  static const Map<String, String> webMinBrowserVersions = {
    'chrome': '88',
    'firefox': '85',
    'safari': '14',
    'edge': '88',
  };{{/support_web}}{{#support_desktop}}

  /// Windows最小版本
  static const String windowsMinVersion = '10.0.17763.0';

  /// macOS最小版本
  static const String macosMinVersion = '10.14';

  /// Linux最小内核版本
  static const String linuxMinKernelVersion = '4.15';{{/support_desktop}}

  // ============================================================================
  // 调试相关常量
  // ============================================================================

  /// 调试标签前缀
  static const String debugTagPrefix = '[{{plugin_name.pascalCase()}}]';

  /// 性能监控标签
  static const String performanceTag = '${debugTagPrefix}Performance';

  /// 网络监控标签
  static const String networkTag = '${debugTagPrefix}Network';

  /// UI监控标签
  static const String uiTag = '${debugTagPrefix}UI';

  // ============================================================================
  // 版本兼容性常量
  // ============================================================================

  /// 最小Dart版本
  static const String minDartVersion = '{{dart_version}}';

  /// 最小Flutter版本
  static const String minFlutterVersion = '{{flutter_version}}';

  /// 最小Pet App版本
  static const String minPetAppVersion = '3.0.0';

  /// 插件系统版本
  static const String pluginSystemVersion = '1.0.0';

  // ============================================================================
  // 资源相关常量
  // ============================================================================{{#include_assets}}

  /// 资源目录路径
  static const String assetsPath = 'assets';

  /// 图片资源路径
  static const String imagesPath = '$assetsPath/images';

  /// 图标资源路径
  static const String iconsPath = '$assetsPath/icons';

  /// 字体资源路径
  static const String fontsPath = '$assetsPath/fonts';

  /// 数据资源路径
  static const String dataPath = '$assetsPath/data';{{/include_assets}}
}
