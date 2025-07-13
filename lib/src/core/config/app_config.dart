/// 应用配置管理
/// 
/// 统一管理所有硬编码的配置项，支持从配置文件、环境变量等多种来源读取配置

import 'dart:io';
import 'package:yaml/yaml.dart';

/// 应用配置管理器
class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._();
  
  AppConfig._();
  
  Map<String, dynamic>? _configData;
  
  /// 从配置文件加载配置
  Future<void> _loadConfigData() async {
    if (_configData != null) return;
    
    try {
      // 尝试加载用户配置文件
      final userConfigFile = File('ming_config.yaml');
      if (await userConfigFile.exists()) {
        final content = await userConfigFile.readAsString();
        _configData = loadYaml(content) as Map<String, dynamic>;
        return;
      }
      
      // 尝试加载项目配置文件
      final projectConfigFile = File('.ming_config.yaml');
      if (await projectConfigFile.exists()) {
        final content = await projectConfigFile.readAsString();
        _configData = loadYaml(content) as Map<String, dynamic>;
        return;
      }
      
      // 使用默认配置
      _configData = _getDefaultConfig();
    } catch (e) {
      // 出错时使用默认配置
      _configData = _getDefaultConfig();
    }
  }
  
  /// 获取默认配置
  Map<String, dynamic> _getDefaultConfig() {
    return {
      'app': {
        'name': 'Ming Status CLI',
        'author': 'lgnorant-lu',
        'license': 'MIT',
        'repository': 'https://github.com/lgnorant-lu/ming_status_cli',
      },
      'defaults': {
        'template_type': 'basic',
        'framework': 'agnostic',
        'platform': 'crossPlatform',
        'complexity': 'simple',
        'description': 'A new project created with Ming Status CLI',
      },
      'paths': {
        'templates_dir': './templates',
        'workspace_dir': './workspace',
        'cache_dir': './.ming_cache',
      },
      'timeouts': {
        'validation': 300,
        'optimization': 600,
        'network': 30,
        'command': 120,
      },
      'validation': {
        'levels': ['basic', 'standard', 'strict', 'enterprise'],
        'output_formats': ['console', 'json', 'junit', 'compact'],
        'cache_duration': 1800, // 30分钟
      },
      'optimization': {
        'strategies': [
          'memory',
          'startup',
          'bundle_size',
          'network',
          'storage',
          'rendering'
        ],
        'default_memory_limit': 524288000, // 500MB
        'default_response_time': 3000, // 3000ms
      },
      'registry': {
        'types': ['official', 'community', 'enterprise', 'private'],
        'auth_types': ['none', 'token', 'oauth2', 'apikey', 'certificate'],
        'default_priority': 100,
        'default_timeout': 30,
        'default_retries': 3,
        'builtin_registries': [
          {
            'name': 'Local Templates',
            'url': 'file://./templates',
            'type': 'official',
            'priority': 1,
          },
          {
            'name': 'Built-in Templates',
            'url': 'internal://builtin',
            'type': 'official',
            'priority': 2,
          },
        ],
      },
      'doctor': {
        'check_items': [
          'dart_version',
          'flutter_version',
          'git_status',
          'dependencies',
          'environment',
          'permissions',
        ],
        'environments': ['development', 'production'],
        'template_types': ['basic', 'enterprise'],
      },
      'urls': {
        'github_api': 'https://api.github.com',
        'update_check': 'https://api.github.com/repos/pet-app/ming_status_cli/releases/latest',
        'documentation': 'https://github.com/lgnorant-lu/ming_status_cli/wiki',
        'issues': 'https://github.com/lgnorant-lu/ming_status_cli/issues',
      },
    };
  }
  
  /// 获取配置值
  Future<T> get<T>(String key, {T? defaultValue}) async {
    await _loadConfigData();
    
    final keys = key.split('.');
    dynamic current = _configData;
    
    for (final k in keys) {
      if (current is Map && current.containsKey(k)) {
        current = current[k];
      } else {
        return defaultValue ?? (throw ConfigException('配置键 "$key" 不存在'));
      }
    }
    
    if (current is T) {
      return current;
    } else {
      return defaultValue ?? (throw ConfigException('配置键 "$key" 的类型不匹配'));
    }
  }
  
  /// 获取字符串配置
  Future<String> getString(String key, {String? defaultValue}) async {
    return await get<String>(key, defaultValue: defaultValue);
  }
  
  /// 获取整数配置
  Future<int> getInt(String key, {int? defaultValue}) async {
    return await get<int>(key, defaultValue: defaultValue);
  }
  
  /// 获取布尔配置
  Future<bool> getBool(String key, {bool? defaultValue}) async {
    return await get<bool>(key, defaultValue: defaultValue);
  }
  
  /// 获取列表配置
  Future<List<T>> getList<T>(String key, {List<T>? defaultValue}) async {
    final value = await get<List>(key, defaultValue: defaultValue);
    return value?.cast<T>() ?? defaultValue ?? [];
  }
  
  /// 获取Map配置
  Future<Map<String, T>> getMap<T>(String key, {Map<String, T>? defaultValue}) async {
    final value = await get<Map>(key, defaultValue: defaultValue);
    return value?.cast<String, T>() ?? defaultValue ?? {};
  }
  
  /// 设置配置值
  Future<void> set(String key, dynamic value) async {
    await _loadConfigData();
    
    final keys = key.split('.');
    dynamic current = _configData;
    
    for (int i = 0; i < keys.length - 1; i++) {
      final k = keys[i];
      if (current is Map) {
        if (!current.containsKey(k)) {
          current[k] = <String, dynamic>{};
        }
        current = current[k];
      } else {
        throw ConfigException('无法设置配置键 "$key"');
      }
    }
    
    if (current is Map) {
      current[keys.last] = value;
    } else {
      throw ConfigException('无法设置配置键 "$key"');
    }
  }
  
  /// 保存配置到文件
  Future<void> save({String? filePath}) async {
    await _loadConfigData();
    
    final file = File(filePath ?? 'ming_config.yaml');
    final yamlString = _mapToYaml(_configData!);
    await file.writeAsString(yamlString);
  }
  
  /// 将Map转换为YAML字符串
  String _mapToYaml(Map<String, dynamic> map, {int indent = 0}) {
    final buffer = StringBuffer();
    final spaces = '  ' * indent;
    
    for (final entry in map.entries) {
      buffer.write('$spaces${entry.key}:');
      
      if (entry.value is Map) {
        buffer.writeln();
        buffer.write(_mapToYaml(entry.value as Map<String, dynamic>, indent: indent + 1));
      } else if (entry.value is List) {
        buffer.writeln();
        for (final item in entry.value as List) {
          buffer.writeln('$spaces  - $item');
        }
      } else {
        buffer.writeln(' ${entry.value}');
      }
    }
    
    return buffer.toString();
  }
  
  /// 重新加载配置
  Future<void> reload() async {
    _configData = null;
    await _loadConfigData();
  }
}

/// 配置异常
class ConfigException implements Exception {
  final String message;
  
  ConfigException(this.message);
  
  @override
  String toString() => 'ConfigException: $message';
}
