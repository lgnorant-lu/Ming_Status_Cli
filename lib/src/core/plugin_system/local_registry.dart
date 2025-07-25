/*
---------------------------------------------------------------
File name:          local_registry.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        本地插件注册表核心实现 (Local plugin registry core implementation)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 本地插件注册表核心逻辑;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// 本地插件注册表
///
/// 管理本地安装的插件，提供插件的索引、安装、卸载等功能。
class LocalRegistry {
  /// 注册表根目录
  late final String _registryPath;

  /// 插件索引文件路径
  late final String _indexPath;

  /// 插件存储目录
  late final String _pluginsPath;

  /// 构造函数
  LocalRegistry({String? registryPath}) {
    _registryPath = registryPath ?? _getDefaultRegistryPath();
    _indexPath = path.join(_registryPath, 'index.json');
    _pluginsPath = path.join(_registryPath, 'plugins');
  }

  /// 获取默认注册表路径
  String _getDefaultRegistryPath() {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return path.join(homeDir, '.ming_cli', 'plugin_registry');
  }

  /// 初始化注册表
  Future<void> initialize() async {
    // 创建注册表目录
    final registryDir = Directory(_registryPath);
    if (!registryDir.existsSync()) {
      await registryDir.create(recursive: true);
    }

    // 创建插件存储目录
    final pluginsDir = Directory(_pluginsPath);
    if (!pluginsDir.existsSync()) {
      await pluginsDir.create(recursive: true);
    }

    // 初始化索引文件
    final indexFile = File(_indexPath);
    if (!indexFile.existsSync()) {
      await _createEmptyIndex();
    }
  }

  /// 创建空索引
  Future<void> _createEmptyIndex() async {
    final emptyIndex = {
      'version': '1.0.0',
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
      'plugins': <String, dynamic>{},
      'metadata': {
        'total_plugins': 0,
        'registry_path': _registryPath,
      },
    };

    final indexFile = File(_indexPath);
    await indexFile.writeAsString(jsonEncode(emptyIndex));
  }

  /// 读取索引
  Future<Map<String, dynamic>> _readIndex() async {
    await initialize();

    final indexFile = File(_indexPath);
    if (!indexFile.existsSync()) {
      await _createEmptyIndex();
    }

    final indexContent = await indexFile.readAsString();
    return jsonDecode(indexContent) as Map<String, dynamic>;
  }

  /// 写入索引
  Future<void> _writeIndex(Map<String, dynamic> index) async {
    index['updated'] = DateTime.now().toIso8601String();

    final indexFile = File(_indexPath);
    await indexFile.writeAsString(jsonEncode(index));
  }

  /// 发布插件到本地注册表
  Future<void> publishPlugin(
    String packagePath,
    Map<String, dynamic> manifest,
  ) async {
    final pluginId = (manifest['plugin']?['id'] ?? manifest['id']) as String?;
    final version =
        (manifest['plugin']?['version'] ?? manifest['version']) as String?;

    if (pluginId == null || version == null) {
      throw Exception('插件清单缺少必需的id或version字段');
    }

    // 读取当前索引
    final index = await _readIndex();
    final plugins = index['plugins'] as Map<String, dynamic>;

    // 创建插件目录
    final pluginDir = Directory(path.join(_pluginsPath, pluginId));
    if (!pluginDir.existsSync()) {
      await pluginDir.create(recursive: true);
    }

    // 复制插件包
    final packageFile = File(packagePath);
    final targetPath = path.join(pluginDir.path, '$pluginId-$version.zip');
    await packageFile.copy(targetPath);

    // 更新索引
    if (!plugins.containsKey(pluginId)) {
      plugins[pluginId] = {
        'id': pluginId,
        'name': (manifest['plugin']?['name'] ?? manifest['name']) as String?,
        'description': (manifest['plugin']?['description'] ??
            manifest['description']) as String?,
        'author':
            (manifest['plugin']?['author'] ?? manifest['author']) as String?,
        'category': (manifest['plugin']?['category'] ?? manifest['category'])
            as String?,
        'versions': <String, dynamic>{},
        'latest_version': version,
        'installed': true,
        'created': DateTime.now().toIso8601String(),
      };
    }

    // 添加版本信息
    final pluginInfo = plugins[pluginId] as Map<String, dynamic>;
    final versions = pluginInfo['versions'] as Map<String, dynamic>;

    versions[version] = {
      'version': version,
      'package_path': targetPath,
      'manifest': manifest,
      'published': DateTime.now().toIso8601String(),
      'size': await packageFile.length(),
    };

    pluginInfo['latest_version'] = version;
    pluginInfo['updated'] = DateTime.now().toIso8601String();

    // 更新元数据
    final metadata = index['metadata'] as Map<String, dynamic>;
    metadata['total_plugins'] = plugins.length;

    // 写入索引
    await _writeIndex(index);
  }

  /// 获取插件信息
  Future<Map<String, dynamic>?> getPlugin(String pluginId) async {
    final index = await _readIndex();
    final plugins = index['plugins'] as Map<String, dynamic>;

    return plugins[pluginId] as Map<String, dynamic>?;
  }

  /// 列出所有插件
  Future<List<Map<String, dynamic>>> listPlugins({
    bool installedOnly = false,
  }) async {
    final index = await _readIndex();
    final plugins = index['plugins'] as Map<String, dynamic>;

    final result = <Map<String, dynamic>>[];

    for (final pluginInfo in plugins.values) {
      final plugin = pluginInfo as Map<String, dynamic>;

      if (installedOnly && !(plugin['installed'] as bool? ?? false)) {
        continue;
      }

      result.add(plugin);
    }

    return result;
  }

  /// 安装插件
  Future<void> installPlugin(String pluginId, {String? version}) async {
    final pluginInfo = await getPlugin(pluginId);
    if (pluginInfo == null) {
      throw Exception('插件 $pluginId 不存在于本地注册表中');
    }

    final targetVersion = version ?? pluginInfo['latest_version'] as String;
    final versions = pluginInfo['versions'] as Map<String, dynamic>;

    if (!versions.containsKey(targetVersion)) {
      throw Exception('版本 $targetVersion 不存在');
    }

    // 标记为已安装
    pluginInfo['installed'] = true;
    pluginInfo['installed_version'] = targetVersion;
    pluginInfo['installed_date'] = DateTime.now().toIso8601String();

    // 更新索引
    final index = await _readIndex();
    final plugins = index['plugins'] as Map<String, dynamic>;
    plugins[pluginId] = pluginInfo;

    await _writeIndex(index);
  }

  /// 卸载插件
  Future<void> uninstallPlugin(String pluginId) async {
    final pluginInfo = await getPlugin(pluginId);
    if (pluginInfo == null) {
      throw Exception('插件 $pluginId 不存在');
    }

    // 标记为未安装
    pluginInfo['installed'] = false;
    pluginInfo.remove('installed_version');
    pluginInfo.remove('installed_date');

    // 更新索引
    final index = await _readIndex();
    final plugins = index['plugins'] as Map<String, dynamic>;
    plugins[pluginId] = pluginInfo;

    await _writeIndex(index);
  }

  /// 删除插件（完全移除）
  Future<void> removePlugin(String pluginId) async {
    final pluginInfo = await getPlugin(pluginId);
    if (pluginInfo == null) {
      throw Exception('插件 $pluginId 不存在');
    }

    // 删除插件文件
    final pluginDir = Directory(path.join(_pluginsPath, pluginId));
    if (pluginDir.existsSync()) {
      await pluginDir.delete(recursive: true);
    }

    // 从索引中移除
    final index = await _readIndex();
    final plugins = index['plugins'] as Map<String, dynamic>;
    plugins.remove(pluginId);

    // 更新元数据
    final metadata = index['metadata'] as Map<String, dynamic>;
    metadata['total_plugins'] = plugins.length;

    await _writeIndex(index);
  }

  /// 搜索插件
  Future<List<Map<String, dynamic>>> searchPlugins(String query) async {
    final allPlugins = await listPlugins();
    final results = <Map<String, dynamic>>[];

    final lowerQuery = query.toLowerCase();

    for (final plugin in allPlugins) {
      final name = (plugin['name'] as String? ?? '').toLowerCase();
      final description =
          (plugin['description'] as String? ?? '').toLowerCase();
      final id = (plugin['id'] as String? ?? '').toLowerCase();
      final category = (plugin['category'] as String? ?? '').toLowerCase();

      if (name.contains(lowerQuery) ||
          description.contains(lowerQuery) ||
          id.contains(lowerQuery) ||
          category.contains(lowerQuery)) {
        results.add(plugin);
      }
    }

    return results;
  }

  /// 获取注册表统计信息
  Future<Map<String, dynamic>> getStatistics() async {
    final index = await _readIndex();
    final plugins = index['plugins'] as Map<String, dynamic>;

    int installedCount = 0;
    int totalVersions = 0;
    final categories = <String, int>{};

    for (final plugin in plugins.values) {
      final pluginInfo = plugin as Map<String, dynamic>;

      if (pluginInfo['installed'] as bool? ?? false) {
        installedCount++;
      }

      final versions = pluginInfo['versions'] as Map<String, dynamic>;
      totalVersions += versions.length;

      final category = pluginInfo['category'] as String? ?? 'unknown';
      categories[category] = (categories[category] ?? 0) + 1;
    }

    return {
      'total_plugins': plugins.length,
      'installed_plugins': installedCount,
      'total_versions': totalVersions,
      'categories': categories,
      'registry_path': _registryPath,
      'last_updated': index['updated'],
    };
  }

  /// 清理注册表（移除未安装的插件文件）
  Future<void> cleanup() async {
    final plugins = await listPlugins();

    for (final plugin in plugins) {
      if (!(plugin['installed'] as bool? ?? false)) {
        final pluginId = plugin['id'] as String;
        await removePlugin(pluginId);
      }
    }
  }
}
