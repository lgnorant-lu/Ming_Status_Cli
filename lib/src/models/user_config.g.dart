// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserConfig _$UserConfigFromJson(Map<String, dynamic> json) => UserConfig(
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>?),
      preferences: UserPreferences.fromJson(
          json['preferences'] as Map<String, dynamic>?),
      defaults:
          UserDefaults.fromJson(json['defaults'] as Map<String, dynamic>?),
      integrations: json['integrations'] as Map<String, dynamic>?,
      security: json['security'] == null
          ? null
          : SecuritySettings.fromJson(
              json['security'] as Map<String, dynamic>?),
    );

Map<String, dynamic> _$UserConfigToJson(UserConfig instance) =>
    <String, dynamic>{
      'user': instance.user,
      'preferences': instance.preferences,
      'defaults': instance.defaults,
      'integrations': instance.integrations,
      'security': instance.security,
    };

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      company: json['company'] as String? ?? '',
    );

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'company': instance.company,
    };

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
      defaultTemplate: json['defaultTemplate'] as String? ?? 'basic',
      coloredOutput: json['coloredOutput'] as bool? ?? true,
      autoUpdateCheck: json['autoUpdateCheck'] as bool? ?? true,
      verboseLogging: json['verboseLogging'] as bool? ?? false,
      preferredIde: json['preferredIde'] as String? ?? 'vscode',
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
      'defaultTemplate': instance.defaultTemplate,
      'coloredOutput': instance.coloredOutput,
      'autoUpdateCheck': instance.autoUpdateCheck,
      'verboseLogging': instance.verboseLogging,
      'preferredIde': instance.preferredIde,
    };

UserDefaults _$UserDefaultsFromJson(Map<String, dynamic> json) => UserDefaults(
      author: json['author'] as String,
      license: json['license'] as String,
      dartVersion: json['dartVersion'] as String,
      description: json['description'] as String? ??
          'A Flutter module created by Ming Status CLI',
    );

Map<String, dynamic> _$UserDefaultsToJson(UserDefaults instance) =>
    <String, dynamic>{
      'author': instance.author,
      'license': instance.license,
      'dartVersion': instance.dartVersion,
      'description': instance.description,
    };

SecuritySettings _$SecuritySettingsFromJson(Map<String, dynamic> json) =>
    SecuritySettings(
      encryptedCredentials: json['encryptedCredentials'] as bool? ?? false,
      strictPermissions: json['strictPermissions'] as bool? ?? true,
    );

Map<String, dynamic> _$SecuritySettingsToJson(SecuritySettings instance) =>
    <String, dynamic>{
      'encryptedCredentials': instance.encryptedCredentials,
      'strictPermissions': instance.strictPermissions,
    };
