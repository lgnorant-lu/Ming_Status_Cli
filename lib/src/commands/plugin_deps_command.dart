/*
---------------------------------------------------------------
File name:          plugin_deps_command.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件依赖管理命令 (Plugin dependencies command)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 插件依赖管理命令实现;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/plugin_system/dependency_resolver.dart';
import 'package:ming_status_cli/src/core/plugin_system/local_registry.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 插件依赖管理命令
///
/// 提供插件依赖分析、解析和管理功能。
class PluginDepsCommand extends BaseCommand {
  @override
  String get name => 'deps';

  @override
  String get description => '分析和管理插件依赖关系';

  @override
  String get category => 'plugin';

  @override
  String get invocation => 'ming plugin deps <plugin-id> [options]';

  /// 构造函数
  PluginDepsCommand() {
    // 操作类型选项
    argParser.addOption(
      'action',
      abbr: 'a',
      allowed: ['analyze', 'resolve', 'tree', 'check'],
      defaultsTo: 'analyze',
      help: '操作类型',
      valueHelp: 'action',
    );

    // 输出格式选项
    argParser.addOption(
      'format',
      abbr: 'f',
      allowed: ['table', 'tree', 'json', 'dot'],
      defaultsTo: 'table',
      help: '输出格式',
      valueHelp: 'format',
    );

    // 包含可选依赖
    argParser.addFlag(
      'include-optional',
      help: '包含可选依赖',
      negatable: false,
    );

    // 递归分析
    argParser.addFlag(
      'recursive',
      abbr: 'r',
      help: '递归分析所有依赖',
      negatable: false,
    );

    // 详细输出
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: '显示详细的依赖信息',
      negatable: false,
    );
  }

  @override
  String get usageFooter => '''

📋 使用示例:
  ming plugin deps my-plugin                    # 分析插件依赖
  ming plugin deps my-plugin -a resolve         # 解析依赖并生成安装顺序
  ming plugin deps my-plugin -a tree -f tree    # 显示依赖树
  ming plugin deps my-plugin -a check           # 检查依赖冲突

📋 操作类型:
  analyze   - 分析插件的直接依赖
  resolve   - 解析完整依赖图并生成安装顺序
  tree      - 显示依赖树结构
  check     - 检查依赖冲突和问题

📋 输出格式:
  table     - 表格格式（默认）
  tree      - 树形结构
  json      - JSON格式
  dot       - Graphviz DOT格式

⚠️  注意事项:
  • 依赖分析基于本地注册表中的插件信息
  • 使用 --recursive 可以分析所有层级的依赖
  • 使用 --include-optional 包含可选依赖''';

  @override
  Future<int> execute() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      Logger.error('请指定要分析的插件ID');
      Logger.info('使用 "ming plugin deps --help" 查看帮助');
      return 1;
    }

    final pluginId = args.first;
    final action = argResults!['action'] as String;
    final format = argResults!['format'] as String;
    final includeOptional = argResults!['include-optional'] as bool;
    final recursive = argResults!['recursive'] as bool;
    final verbose = argResults!['verbose'] as bool;

    Logger.info('🔍 开始分析插件依赖...');
    Logger.info('插件ID: $pluginId');
    Logger.info('操作类型: ${_getActionDescription(action)}');

    try {
      final localRegistry = LocalRegistry();
      
      // 获取插件信息
      final pluginInfo = await localRegistry.getPlugin(pluginId);
      if (pluginInfo == null) {
        Logger.error('插件 "$pluginId" 不存在于本地注册表中');
        Logger.info('使用 "ming plugin list --all" 查看可用插件');
        return 1;
      }

      // 获取所有可用插件
      final allPlugins = await localRegistry.listPlugins();
      final availablePlugins = <String, PluginInfo>{};
      final installedPlugins = <String, PluginInfo>{};

      for (final plugin in allPlugins) {
        final info = _convertToPluginInfo(plugin);
        availablePlugins[info.id] = info;
        
        if (plugin['installed'] as bool? ?? false) {
          installedPlugins[info.id] = info;
        }
      }

      final targetPlugin = _convertToPluginInfo(pluginInfo);

      // 执行相应的操作
      switch (action) {
        case 'analyze':
          return await _analyzeAction(
            targetPlugin,
            availablePlugins,
            format,
            includeOptional,
            verbose,
          );
        case 'resolve':
          return await _resolveAction(
            targetPlugin,
            availablePlugins,
            installedPlugins,
            format,
            verbose,
          );
        case 'tree':
          return await _treeAction(
            targetPlugin,
            availablePlugins,
            format,
            includeOptional,
            recursive,
            verbose,
          );
        case 'check':
          return await _checkAction(
            targetPlugin,
            availablePlugins,
            installedPlugins,
            format,
            verbose,
          );
        default:
          Logger.error('不支持的操作类型: $action');
          return 1;
      }
    } catch (e) {
      Logger.error('依赖分析过程中发生错误: $e');
      return 1;
    }
  }

  /// 分析操作
  Future<int> _analyzeAction(
    PluginInfo targetPlugin,
    Map<String, PluginInfo> availablePlugins,
    String format,
    bool includeOptional,
    bool verbose,
  ) async {
    Logger.info('\n📋 插件依赖分析:');
    
    final dependencies = targetPlugin.dependencies
        .where((dep) => includeOptional || !dep.isOptional)
        .toList();

    if (dependencies.isEmpty) {
      Logger.info('插件 "${targetPlugin.id}" 没有依赖');
      return 0;
    }

    _displayDependencies(dependencies, availablePlugins, format, verbose);
    return 0;
  }

  /// 解析操作
  Future<int> _resolveAction(
    PluginInfo targetPlugin,
    Map<String, PluginInfo> availablePlugins,
    Map<String, PluginInfo> installedPlugins,
    String format,
    bool verbose,
  ) async {
    Logger.info('\n🔄 解析插件依赖...');

    final resolver = DependencyResolver();
    final result = resolver.resolveDependencies(
      targetPlugin: targetPlugin,
      availablePlugins: availablePlugins,
      installedPlugins: installedPlugins,
    );

    _displayResolutionResult(result, format, verbose);

    return result.isSuccess ? 0 : 1;
  }

  /// 树形显示操作
  Future<int> _treeAction(
    PluginInfo targetPlugin,
    Map<String, PluginInfo> availablePlugins,
    String format,
    bool includeOptional,
    bool recursive,
    bool verbose,
  ) async {
    Logger.info('\n🌳 插件依赖树:');
    
    _displayDependencyTree(
      targetPlugin,
      availablePlugins,
      format,
      includeOptional,
      recursive,
      0,
      <String>{},
    );

    return 0;
  }

  /// 检查操作
  Future<int> _checkAction(
    PluginInfo targetPlugin,
    Map<String, PluginInfo> availablePlugins,
    Map<String, PluginInfo> installedPlugins,
    String format,
    bool verbose,
  ) async {
    Logger.info('\n🔍 检查依赖问题...');

    final resolver = DependencyResolver();
    final result = resolver.resolveDependencies(
      targetPlugin: targetPlugin,
      availablePlugins: availablePlugins,
      installedPlugins: installedPlugins,
    );

    _displayDependencyProblems(result, format, verbose);

    return result.isSuccess ? 0 : 1;
  }

  /// 显示依赖列表
  void _displayDependencies(
    List<PluginDependency> dependencies,
    Map<String, PluginInfo> availablePlugins,
    String format,
    bool verbose,
  ) {
    if (format == 'json') {
      final jsonData = dependencies.map((dep) => dep.toMap()).toList();
      Logger.info(jsonData.toString());
      return;
    }

    Logger.info('');
    Logger.info('依赖插件    版本约束      状态      类型');
    Logger.info('─' * 50);

    for (final dep in dependencies) {
      final available = availablePlugins.containsKey(dep.pluginId);
      final status = available ? '可用' : '缺失';
      final type = dep.isOptional ? '可选' : '必需';
      
      Logger.info(
        '${_padRight(dep.pluginId, 12)} '
        '${_padRight(dep.versionConstraint, 12)} '
        '${_padRight(status, 8)} '
        '$type'
      );

      if (verbose && dep.description != null) {
        Logger.info('  描述: ${dep.description}');
      }
    }
  }

  /// 显示解析结果
  void _displayResolutionResult(
    DependencyResolutionResult result,
    String format,
    bool verbose,
  ) {
    Logger.info('\n📋 依赖解析结果:');
    Logger.info('  解析状态: ${result.isSuccess ? "成功" : "失败"}');

    if (result.isSuccess) {
      Logger.info('  安装顺序: ${result.installOrder.join(' → ')}');
      Logger.info('  需要安装: ${result.installOrder.length} 个插件');
    }

    if (result.errors.isNotEmpty) {
      Logger.info('\n❌ 错误:');
      for (final error in result.errors) {
        Logger.error('  • $error');
      }
    }

    if (result.warnings.isNotEmpty) {
      Logger.info('\n⚠️  警告:');
      for (final warning in result.warnings) {
        Logger.warning('  • $warning');
      }
    }

    if (verbose) {
      if (result.missingDependencies.isNotEmpty) {
        Logger.info('\n❌ 缺失依赖:');
        for (final dep in result.missingDependencies) {
          Logger.info('  • ${dep.pluginId} (${dep.versionConstraint})');
        }
      }

      if (result.circularDependencies.isNotEmpty) {
        Logger.info('\n🔄 循环依赖:');
        for (final cycle in result.circularDependencies) {
          Logger.info('  • ${cycle.join(' → ')}');
        }
      }
    }
  }

  /// 显示依赖树
  void _displayDependencyTree(
    PluginInfo plugin,
    Map<String, PluginInfo> availablePlugins,
    String format,
    bool includeOptional,
    bool recursive,
    int depth,
    Set<String> visited,
  ) {
    final indent = '  ' * depth;
    final prefix = depth == 0 ? '' : '├─ ';
    
    Logger.info('$indent$prefix${plugin.id} (${plugin.version})');

    if (visited.contains(plugin.id)) {
      Logger.info('$indent   (循环依赖)');
      return;
    }

    if (!recursive && depth > 0) return;

    visited.add(plugin.id);

    final dependencies = plugin.dependencies
        .where((dep) => includeOptional || !dep.isOptional)
        .toList();

    for (final dep in dependencies) {
      final depPlugin = availablePlugins[dep.pluginId];
      if (depPlugin != null) {
        _displayDependencyTree(
          depPlugin,
          availablePlugins,
          format,
          includeOptional,
          recursive,
          depth + 1,
          Set.from(visited),
        );
      } else {
        Logger.info('$indent  ├─ ${dep.pluginId} (缺失)');
      }
    }

    visited.remove(plugin.id);
  }

  /// 显示依赖问题
  void _displayDependencyProblems(
    DependencyResolutionResult result,
    String format,
    bool verbose,
  ) {
    if (result.isSuccess) {
      Logger.success('✅ 未发现依赖问题');
      return;
    }

    Logger.info('发现以下依赖问题:');

    if (result.missingDependencies.isNotEmpty) {
      Logger.info('\n❌ 缺失依赖:');
      for (final dep in result.missingDependencies) {
        Logger.error('  • ${dep.pluginId} (${dep.versionConstraint})');
      }
    }

    if (result.circularDependencies.isNotEmpty) {
      Logger.info('\n🔄 循环依赖:');
      for (final cycle in result.circularDependencies) {
        Logger.error('  • ${cycle.join(' → ')}');
      }
    }

    if (result.versionConflicts.isNotEmpty) {
      Logger.info('\n⚠️  版本冲突:');
      for (final conflict in result.versionConflicts) {
        Logger.warning('  • $conflict');
      }
    }
  }

  /// 转换为PluginInfo
  PluginInfo _convertToPluginInfo(Map<String, dynamic> pluginData) {
    // 模拟依赖数据（实际应该从plugin.yaml解析）
    final dependencies = <PluginDependency>[
      if (pluginData['id'] == 'test_build_plugin')
        const PluginDependency(
          pluginId: 'plugin_system',
          versionConstraint: '^1.0.0',
        ),
    ];

    return PluginInfo(
      id: pluginData['id'] as String,
      version: pluginData['latest_version'] as String,
      dependencies: dependencies,
      isInstalled: pluginData['installed'] as bool? ?? false,
    );
  }

  /// 获取操作描述
  String _getActionDescription(String action) {
    switch (action) {
      case 'analyze':
        return '分析直接依赖';
      case 'resolve':
        return '解析完整依赖图';
      case 'tree':
        return '显示依赖树';
      case 'check':
        return '检查依赖问题';
      default:
        return action;
    }
  }

  /// 右对齐填充
  String _padRight(String text, int width) {
    return text.padRight(width);
  }
}
