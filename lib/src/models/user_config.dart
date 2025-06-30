/*
---------------------------------------------------------------
File name:          user_config.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        用户配置数据模型 (User configuration data model)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 用户全局配置模型;
---------------------------------------------------------------
*/

import 'package:json_annotation/json_annotation.dart';

part 'user_config.g.dart';

/// 用户配置类
/// 管理用户的全局配置和偏好设置
@JsonSerializable()
class UserConfig {
  const UserConfig({
    required this.user,
    required this.preferences,
    required this.defaults,
    this.integrations,
    this.security,
  });

  /// 从JSON创建实例
  factory UserConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      // 空JSON时返回具有基本默认值但security为null的配置
      return const UserConfig(
        user: UserInfo(name: '开发者名称'),
        preferences: UserPreferences(),
        defaults: UserDefaults(
          author: '开发者名称',
          license: 'MIT',
          dartVersion: '^3.2.0',
        ),
      );
    }
    try {
      return _$UserConfigFromJson(json);
    } catch (e) {
      // JSON解析失败时返回具有基本默认值但security为null的配置
      return const UserConfig(
        user: UserInfo(name: '开发者名称'),
        preferences: UserPreferences(),
        defaults: UserDefaults(
          author: '开发者名称',
          license: 'MIT',
          dartVersion: '^3.2.0',
        ),
      );
    }
  }

  /// 创建默认用户配置
  factory UserConfig.defaultConfig() {
    return const UserConfig(
      user: UserInfo(
        name: '开发者名称',
      ),
      preferences: UserPreferences(
        
      ),
      defaults: UserDefaults(
        author: '开发者名称',
        license: 'MIT',
        dartVersion: '^3.2.0',
      ),
      security: SecuritySettings(
        
      ),
    );
  }

  /// 用户基本信息
  final UserInfo user;

  /// 用户偏好设置
  final UserPreferences preferences;

  /// 用户默认值
  final UserDefaults defaults;

  /// 集成配置
  final Map<String, dynamic>? integrations;

  /// 安全设置
  final SecuritySettings? security;

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$UserConfigToJson(this);

  /// 拷贝并更新配置
  UserConfig copyWith({
    UserInfo? user,
    UserPreferences? preferences,
    UserDefaults? defaults,
    Map<String, dynamic>? integrations,
    SecuritySettings? security,
  }) {
    return UserConfig(
      user: user ?? this.user,
      preferences: preferences ?? this.preferences,
      defaults: defaults ?? this.defaults,
      integrations: integrations ?? this.integrations,
      security: security ?? this.security,
    );
  }
}

/// 用户基本信息
@JsonSerializable()
class UserInfo {
  const UserInfo({
    required this.name,
    this.email = '',
    this.company = '',
  });

  factory UserInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const UserInfo(name: '');
    }
    try {
      return _$UserInfoFromJson(json);
    } catch (e) {
      return const UserInfo(name: '');
    }
  }

  /// 用户姓名
  final String name;

  /// 邮箱地址
  final String email;

  /// 公司名称
  final String company;

  Map<String, dynamic> toJson() => _$UserInfoToJson(this);

  /// 拷贝并更新用户信息
  UserInfo copyWith({
    String? name,
    String? email,
    String? company,
  }) {
    return UserInfo(
      name: name ?? this.name,
      email: email ?? this.email,
      company: company ?? this.company,
    );
  }
}

/// 用户偏好设置
@JsonSerializable()
class UserPreferences {
  const UserPreferences({
    this.defaultTemplate = 'basic',
    this.coloredOutput = true,
    this.autoUpdateCheck = true,
    this.verboseLogging = false,
    this.preferredIde = 'vscode',
  });

  factory UserPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const UserPreferences();
    }
    try {
      return _$UserPreferencesFromJson(json);
    } catch (e) {
      return const UserPreferences();
    }
  }

  /// 默认模板类型
  final String defaultTemplate;

  /// 彩色输出
  final bool coloredOutput;

  /// 自动更新检查
  final bool autoUpdateCheck;

  /// 详细日志输出
  final bool verboseLogging;

  /// 首选IDE
  final String preferredIde;

  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);

  /// 拷贝并更新偏好设置
  UserPreferences copyWith({
    String? defaultTemplate,
    bool? coloredOutput,
    bool? autoUpdateCheck,
    bool? verboseLogging,
    String? preferredIde,
  }) {
    return UserPreferences(
      defaultTemplate: defaultTemplate ?? this.defaultTemplate,
      coloredOutput: coloredOutput ?? this.coloredOutput,
      autoUpdateCheck: autoUpdateCheck ?? this.autoUpdateCheck,
      verboseLogging: verboseLogging ?? this.verboseLogging,
      preferredIde: preferredIde ?? this.preferredIde,
    );
  }
}

/// 用户默认值
@JsonSerializable()
class UserDefaults {
  const UserDefaults({
    required this.author,
    required this.license,
    required this.dartVersion,
    this.description = 'A Flutter module created by Ming Status CLI',
  });

  factory UserDefaults.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const UserDefaults(
        author: '',
        license: 'MIT',
        dartVersion: '^3.2.0',
      );
    }
    try {
      return _$UserDefaultsFromJson(json);
    } catch (e) {
      return const UserDefaults(
        author: '',
        license: 'MIT',
        dartVersion: '^3.2.0',
      );
    }
  }

  /// 默认作者
  final String author;

  /// 默认许可证
  final String license;

  /// 默认Dart版本
  final String dartVersion;

  /// 默认描述
  final String description;

  Map<String, dynamic> toJson() => _$UserDefaultsToJson(this);

  /// 拷贝并更新默认值
  UserDefaults copyWith({
    String? author,
    String? license,
    String? dartVersion,
    String? description,
  }) {
    return UserDefaults(
      author: author ?? this.author,
      license: license ?? this.license,
      dartVersion: dartVersion ?? this.dartVersion,
      description: description ?? this.description,
    );
  }
}

/// 安全设置
@JsonSerializable()
class SecuritySettings {
  const SecuritySettings({
    this.encryptedCredentials = false,
    this.strictPermissions = true,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const SecuritySettings();
    }
    try {
      return _$SecuritySettingsFromJson(json);
    } catch (e) {
      return const SecuritySettings();
    }
  }

  /// 加密凭证存储
  final bool encryptedCredentials;

  /// 严格权限检查
  final bool strictPermissions;

  Map<String, dynamic> toJson() => _$SecuritySettingsToJson(this);

  /// 拷贝并更新安全设置
  SecuritySettings copyWith({
    bool? encryptedCredentials,
    bool? strictPermissions,
  }) {
    return SecuritySettings(
      encryptedCredentials: encryptedCredentials ?? this.encryptedCredentials,
      strictPermissions: strictPermissions ?? this.strictPermissions,
    );
  }
}
