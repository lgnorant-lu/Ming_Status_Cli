/*
---------------------------------------------------------------
File name:          registry_list_command.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        列出注册表命令 (List Registry Command)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 远程模板生态建设;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/registry/registry_data_service.dart';
import 'package:ming_status_cli/src/core/registry/template_registry.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 列出注册表命令
///
/// 实现 `ming registry list` 命令，显示所有注册表信息
class RegistryListCommand extends Command<int> {
  /// 创建列出注册表命令实例
  RegistryListCommand() {
    argParser
      ..addOption(
        'type',
        abbr: 't',
        help: '按类型过滤',
        allowed: ['official', 'community', 'enterprise', 'private'],
      )
      ..addOption(
        'status',
        abbr: 's',
        help: '按状态过滤',
        allowed: ['healthy', 'warning', 'error', 'offline'],
      )
      ..addFlag(
        'enabled-only',
        help: '仅显示启用的注册表',
      )
      ..addFlag(
        'detailed',
        abbr: 'd',
        help: '显示详细信息',
      )
      ..addFlag(
        'health',
        help: '显示健康状态',
      )
      ..addFlag(
        'performance',
        abbr: 'p',
        help: '显示性能信息',
      )
      ..addFlag(
        'json',
        help: '以JSON格式输出',
      );
  }

  @override
  String get name => 'list';

  @override
  String get description => '列出所有模板注册表';

  @override
  String get usage => '''
使用方法:
  ming registry list [选项]

示例:
  # 列出所有注册表
  ming registry list

  # 显示详细信息
  ming registry list --detailed

  # 显示健康状态和性能信息
  ming registry list --health --performance

  # 按类型过滤
  ming registry list --type=official

  # 仅显示启用的注册表
  ming registry list --enabled-only

  # JSON格式输出
  ming registry list --json
''';

  @override
  Future<int> run() async {
    try {
      final type = argResults!['type'] as String?;
      final status = argResults!['status'] as String?;
      final enabledOnly = argResults!['enabled-only'] as bool;
      final detailed = argResults!['detailed'] as bool;
      final showHealth = argResults!['health'] as bool;
      final showPerformance = argResults!['performance'] as bool;
      final jsonOutput = argResults!['json'] as bool;

      cli_logger.Logger.info('获取注册表列表');

      // 初始化数据服务
      final dataService = RegistryDataService();
      await dataService.initialize();

      // 获取注册表列表
      var registries = dataService.getAllRegistries();

      // 应用过滤器
      registries = _applyFilters(registries, type, enabledOnly);

      // 获取健康状态
      Map<String, RegistryHealth>? healthData;
      if (showHealth || status != null) {
        healthData = await _getHealthData(dataService, registries);

        // 按状态过滤
        if (status != null) {
          registries = registries.where((config) {
            final health = healthData![config.id];
            return health?.status.name == status;
          }).toList();
        }
      }

      // 输出结果
      if (jsonOutput) {
        _outputJson(registries, healthData);
      } else {
        _outputTable(
            registries, healthData, detailed, showHealth, showPerformance,);
      }

      cli_logger.Logger.success('注册表列表获取完成');
      return 0;
    } catch (e) {
      cli_logger.Logger.error('获取注册表列表失败', error: e);
      return 1;
    }
  }

  /// 应用过滤器
  List<RegistryConfig> _applyFilters(
    List<RegistryConfig> registries,
    String? type,
    bool enabledOnly,
  ) {
    var filtered = registries;

    // 按类型过滤
    if (type != null) {
      final registryType = RegistryType.values.byName(type);
      filtered = filtered.where((r) => r.type == registryType).toList();
    }

    // 仅显示启用的
    if (enabledOnly) {
      filtered = filtered.where((r) => r.enabled).toList();
    }

    return filtered;
  }

  /// 获取健康状态数据
  Future<Map<String, RegistryHealth>> _getHealthData(
    RegistryDataService dataService,
    List<RegistryConfig> registries,
  ) async {
    final healthData = <String, RegistryHealth>{};

    for (final config in registries) {
      try {
        final health = dataService.getRegistryHealth(config.id);
        healthData[config.id] = health;
      } catch (e) {
        // 忽略获取健康状态失败的注册表
      }
    }

    return healthData;
  }

  /// 输出JSON格式
  void _outputJson(
    List<RegistryConfig> registries,
    Map<String, RegistryHealth>? healthData,
  ) {
    final data = registries.map((config) {
      final json = config.toJson();
      if (healthData != null && healthData.containsKey(config.id)) {
        final health = healthData[config.id]!;
        json['health'] = {
          'status': health.status.name,
          'responseTime': health.responseTime,
          'lastCheck': health.lastCheck.toIso8601String(),
          'availability': health.availability,
          'templateCount': health.templateCount,
          'error': health.error,
        };
      }
      return json;
    }).toList();

    const encoder = JsonEncoder.withIndent('  ');
    print(encoder.convert(data));
  }

  /// 输出表格格式
  void _outputTable(
    List<RegistryConfig> registries,
    Map<String, RegistryHealth>? healthData,
    bool detailed,
    bool showHealth,
    bool showPerformance,
  ) {
    if (registries.isEmpty) {
      print('📭 未找到注册表');
      print('');
      print('💡 提示: 使用 "ming registry add" 添加注册表');
      return;
    }

    print('\n📚 模板注册表列表');
    print('─' * 80);

    for (final config in registries) {
      _displayRegistry(config, healthData?[config.id], detailed, showHealth,
          showPerformance,);
      print('');
    }

    // 显示统计信息
    _displaySummary(registries, healthData);
  }

  /// 显示单个注册表
  void _displayRegistry(
    RegistryConfig config,
    RegistryHealth? health,
    bool detailed,
    bool showHealth,
    bool showPerformance,
  ) {
    // 基本信息
    final typeIcon = _getTypeIcon(config.type);
    final statusIcon = config.enabled ? '🟢' : '🔴';

    print('$typeIcon $statusIcon ${config.name} (${config.id})');
    print('   URL: ${config.url}');
    print('   类型: ${_getTypeDescription(config.type)}');
    print('   优先级: ${config.priority}');

    // 详细信息
    if (detailed) {
      print('   超时: ${config.timeout}秒');
      print('   重试: ${config.retryCount}次');
      print('   认证: ${config.auth != null ? '已配置' : '无'}');
      print('   创建: ${_formatDateTime(config.createdAt)}');
      print('   更新: ${_formatDateTime(config.updatedAt)}');
    }

    // 健康状态
    if (showHealth && health != null) {
      final healthIcon = _getHealthIcon(health.status);
      print('   健康: $healthIcon ${_getHealthDescription(health.status)}');
      print('   检查: ${_formatDateTime(health.lastCheck)}');
      print('   可用性: ${health.availability.toStringAsFixed(1)}%');
      print('   模板数: ${health.templateCount}');

      if (health.error != null) {
        print('   错误: ${health.error}');
      }
    }

    // 性能信息
    if (showPerformance && health != null) {
      print('   响应时间: ${health.responseTime}ms');
    }
  }

  /// 获取类型图标
  String _getTypeIcon(RegistryType type) {
    switch (type) {
      case RegistryType.official:
        return '🏛️';
      case RegistryType.community:
        return '👥';
      case RegistryType.enterprise:
        return '🏢';
      case RegistryType.private:
        return '🔒';
    }
  }

  /// 获取类型描述
  String _getTypeDescription(RegistryType type) {
    switch (type) {
      case RegistryType.official:
        return '官方注册表';
      case RegistryType.community:
        return '社区注册表';
      case RegistryType.enterprise:
        return '企业注册表';
      case RegistryType.private:
        return '私有注册表';
    }
  }

  /// 获取健康状态图标
  String _getHealthIcon(RegistryStatus status) {
    switch (status) {
      case RegistryStatus.healthy:
        return '✅';
      case RegistryStatus.warning:
        return '⚠️';
      case RegistryStatus.error:
        return '❌';
      case RegistryStatus.offline:
        return '🔴';
    }
  }

  /// 获取健康状态描述
  String _getHealthDescription(RegistryStatus status) {
    switch (status) {
      case RegistryStatus.healthy:
        return '健康';
      case RegistryStatus.warning:
        return '警告';
      case RegistryStatus.error:
        return '错误';
      case RegistryStatus.offline:
        return '离线';
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 显示统计摘要
  void _displaySummary(
    List<RegistryConfig> registries,
    Map<String, RegistryHealth>? healthData,
  ) {
    print('📊 统计摘要');
    print('─' * 40);

    final total = registries.length;
    final enabled = registries.where((r) => r.enabled).length;
    final disabled = total - enabled;

    print('总数: $total');
    print('启用: $enabled');
    print('禁用: $disabled');

    if (healthData != null) {
      final healthy = healthData.values
          .where((h) => h.status == RegistryStatus.healthy)
          .length;
      final warning = healthData.values
          .where((h) => h.status == RegistryStatus.warning)
          .length;
      final error = healthData.values
          .where((h) => h.status == RegistryStatus.error)
          .length;
      final offline = healthData.values
          .where((h) => h.status == RegistryStatus.offline)
          .length;

      print('');
      print('健康状态:');
      print('  ✅ 健康: $healthy');
      print('  ⚠️ 警告: $warning');
      print('  ❌ 错误: $error');
      print('  🔴 离线: $offline');
    }

    // 按类型统计
    final typeStats = <RegistryType, int>{};
    for (final registry in registries) {
      typeStats[registry.type] = (typeStats[registry.type] ?? 0) + 1;
    }

    if (typeStats.isNotEmpty) {
      print('');
      print('按类型统计:');
      for (final entry in typeStats.entries) {
        final icon = _getTypeIcon(entry.key);
        final desc = _getTypeDescription(entry.key);
        print('  $icon $desc: ${entry.value}');
      }
    }
  }
}
