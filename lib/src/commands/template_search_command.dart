/*
---------------------------------------------------------------
File name:          template_search_command.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        模板搜索命令 (Template Search Command)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - 模板搜索命令;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/template_system/template_metadata.dart';
import 'package:ming_status_cli/src/core/template_system/template_registry.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板搜索命令
///
/// 实现 `ming template search` 命令
class TemplateSearchCommand extends Command<int> {
  /// 创建模板搜索命令实例
  TemplateSearchCommand() {
    argParser
      ..addOption(
        'type',
        abbr: 't',
        help: '按模板类型过滤',
        allowed: TemplateType.values.map((t) => t.name),
        allowedHelp: {
          for (final type in TemplateType.values) type.name: type.displayName,
        },
      )
      ..addOption(
        'platform',
        abbr: 'p',
        help: '按目标平台过滤',
        allowed: TemplatePlatform.values.map((p) => p.name),
        allowedHelp: {
          'web': 'Web平台',
          'mobile': '移动平台 (iOS/Android)',
          'desktop': '桌面平台 (Windows/macOS/Linux)',
          'server': '服务器端',
          'cloud': '云原生',
          'crossPlatform': '跨平台',
        },
      )
      ..addOption(
        'framework',
        abbr: 'f',
        help: '按技术框架过滤',
        allowed: TemplateFramework.values.map((f) => f.name),
        allowedHelp: {
          'flutter': 'Flutter框架',
          'dart': 'Dart原生',
          'react': 'React框架',
          'vue': 'Vue.js框架',
          'angular': 'Angular框架',
          'nodejs': 'Node.js',
          'springBoot': 'Spring Boot',
          'agnostic': '框架无关',
        },
      )
      ..addOption(
        'complexity',
        abbr: 'c',
        help: '按复杂度过滤',
        allowed: TemplateComplexity.values.map((c) => c.name),
        allowedHelp: {
          'simple': '简单模板',
          'medium': '中等复杂度模板',
          'complex': '复杂模板',
          'enterprise': '企业级模板',
        },
      )
      ..addOption(
        'author',
        abbr: 'a',
        help: '按作者过滤',
      )
      ..addOption(
        'tag',
        help: '按标签过滤 (可指定多个，用逗号分隔)',
      )
      ..addOption(
        'min-rating',
        help: '最低评分 (0.0-5.0)',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '输出格式',
        allowed: ['table', 'json', 'yaml', 'list'],
        defaultsTo: 'table',
        allowedHelp: {
          'table': '表格格式',
          'json': 'JSON格式',
          'yaml': 'YAML格式',
          'list': '列表格式',
        },
      )
      ..addOption(
        'sort',
        abbr: 's',
        help: '排序方式',
        allowed: ['relevance', 'name', 'rating', 'downloads', 'updated'],
        defaultsTo: 'relevance',
        allowedHelp: {
          'relevance': '按相关性排序',
          'name': '按名称排序',
          'rating': '按评分排序',
          'downloads': '按下载量排序',
          'updated': '按更新时间排序',
        },
      )
      ..addOption(
        'limit',
        abbr: 'l',
        help: '限制结果数量',
        defaultsTo: '20',
      )
      ..addFlag(
        'detailed',
        abbr: 'd',
        help: '显示详细信息',
      )
      ..addFlag(
        'exact',
        help: '精确匹配模式',
      )
      ..addFlag(
        'case-sensitive',
        help: '区分大小写',
      );
  }

  @override
  String get name => 'search';

  @override
  String get description => '搜索模板';

  @override
  String get usage => '''
搜索模板

使用方法:
  ming template search <关键词> [选项]

参数:
  <关键词>               搜索关键词或短语

过滤选项:
  -t, --type=<类型>      按模板类型过滤 (可选值见下方)
  -p, --platform=<平台>  按目标平台过滤 (可选值见下方)
  -f, --framework=<框架> 按技术框架过滤 (可选值见下方)
  -c, --complexity=<复杂度> 按复杂度过滤 (可选值见下方)
  -a, --author=<作者>    按作者过滤
      --tag=<标签>       按标签过滤 (逗号分隔)
      --min-rating=<评分> 最低评分 (0.0-5.0)

模板类型 (-t, --type):
  ui                     UI组件
  service                业务服务
  data                   数据层
  full                   完整应用
  system                 系统配置
  basic                  基础模板
  micro                  微服务
  plugin                 插件系统
  infrastructure         基础设施

目标平台 (-p, --platform):
  web                    Web平台
  mobile                 移动平台 (iOS/Android)
  desktop                桌面平台 (Windows/macOS/Linux)
  server                 服务器端
  cloud                  云原生
  crossPlatform          跨平台

技术框架 (-f, --framework):
  flutter                Flutter框架
  dart                   Dart原生
  react                  React框架
  vue                    Vue.js框架
  angular                Angular框架
  nodejs                 Node.js
  springBoot             Spring Boot
  agnostic               框架无关

复杂度级别 (-c, --complexity):
  simple                 简单模板
  medium                 中等复杂度模板
  complex                复杂模板
  enterprise             企业级模板

输出格式 (-o, --output):
  table                  表格格式 (默认)
  json                   JSON格式
  yaml                   YAML格式
  list                   列表格式

排序方式 (-s, --sort):
  relevance              按相关性排序 (默认)
  name                   按名称排序
  rating                 按评分排序
  downloads              按下载量排序
  updated                按更新时间排序

搜索选项:
      --exact            精确匹配模式
      --case-sensitive   区分大小写搜索
  -d, --detailed         显示详细信息
  -l, --limit=<数量>     限制结果数量 (默认: 20)

示例:
  # 基础搜索
  ming template search "flutter clean architecture"

  # 高质量移动应用模板
  ming template search "mobile app" --platform=flutter --min-rating=4.0

  # 最近更新的React组件
  ming template search "component" --platform=react --sort=updated

  # 精确匹配和详细信息
  ming template search "flutter_clean_app" --exact --detailed

  # JSON格式输出
  ming template search "microservice" --sort=rating --output=json --limit=10

更多信息:
  使用 'ming help template search' 查看详细文档
''';

  @override
  Future<int> run() async {
    try {
      // 获取搜索关键词
      final keyword =
          argResults!.rest.isNotEmpty ? argResults!.rest.join(' ') : null;

      if (keyword == null || keyword.trim().isEmpty) {
        cli_logger.Logger.error('请提供搜索关键词');
        print(usage);
        return 1;
      }

      cli_logger.Logger.info('正在搜索模板: "$keyword"');

      // 创建搜索查询
      final query = _buildSearchQuery(keyword);

      // 获取模板注册表 - 使用当前工作目录
      final registry = TemplateRegistry(registryPath: Directory.current.path);

      // 执行搜索
      final searchResult = await registry.searchTemplates(query);

      if (searchResult.templates.isEmpty) {
        cli_logger.Logger.warning('未找到匹配 "$keyword" 的模板');
        _showSearchSuggestions(keyword);
        return 0;
      }

      // 显示结果
      await _displayResults(searchResult.templates, keyword);

      cli_logger.Logger.success('找到 ${searchResult.templates.length} 个匹配的模板');
      return 0;
    } catch (e) {
      cli_logger.Logger.error('搜索模板失败', error: e);
      return 1;
    }
  }

  /// 构建搜索查询
  TemplateSearchQuery _buildSearchQuery(String keyword) {
    final typeStr = argResults!['type'] as String?;
    final platformStr = argResults!['platform'] as String?;
    final frameworkStr = argResults!['framework'] as String?;
    final complexityStr = argResults!['complexity'] as String?;
    final author = argResults!['author'] as String?;
    final tagStr = argResults!['tag'] as String?;
    final minRatingStr = argResults!['min-rating'] as String?;
    final sortStr = argResults!['sort'] as String?;
    final limitStr = argResults!['limit'] as String;
    final exact = argResults!['exact'] as bool;

    // 解析枚举值
    final type = typeStr != null
        ? TemplateType.values.firstWhere((t) => t.name == typeStr)
        : null;
    final platform = platformStr != null
        ? TemplatePlatform.values.firstWhere((p) => p.name == platformStr)
        : null;
    final framework = frameworkStr != null
        ? TemplateFramework.values.firstWhere((f) => f.name == frameworkStr)
        : null;
    final complexity = complexityStr != null
        ? TemplateComplexity.values.firstWhere((c) => c.name == complexityStr)
        : null;

    // 解析标签
    final tags = tagStr?.split(',').map((tag) => tag.trim()).toList() ?? [];

    // 解析最低评分
    final minRating =
        minRatingStr != null ? double.tryParse(minRatingStr) : null;

    // 解析排序
    final sortBy = _parseSortBy(sortStr ?? 'relevance');

    // 解析限制
    final limit = int.tryParse(limitStr) ?? 20;

    // 处理精确匹配
    final searchKeyword = exact ? '"$keyword"' : keyword;

    return TemplateSearchQuery(
      keyword: searchKeyword,
      type: type,
      platform: platform,
      framework: framework,
      complexity: complexity,
      tags: tags,
      author: author,
      minRating: minRating,
      sortBy: sortBy,
      limit: limit,
    );
  }

  /// 解析排序方式
  TemplateSortBy _parseSortBy(String sortStr) {
    switch (sortStr) {
      case 'relevance':
        return TemplateSortBy.relevance;
      case 'name':
        return TemplateSortBy.name;
      case 'rating':
        return TemplateSortBy.rating;
      case 'downloads':
        return TemplateSortBy.downloadCount;
      case 'updated':
        return TemplateSortBy.updatedAt;
      default:
        return TemplateSortBy.relevance;
    }
  }

  /// 显示搜索结果
  Future<void> _displayResults(
    List<TemplateMetadata> results,
    String keyword,
  ) async {
    final outputFormat = argResults!['output'] as String;
    final detailed = argResults!['detailed'] as bool;

    print('\n🔍 搜索结果: "$keyword"');
    print('─' * 80);

    switch (outputFormat) {
      case 'json':
        await _displayJsonResults(results, detailed);
      case 'yaml':
        await _displayYamlResults(results, detailed);
      case 'list':
        await _displayListResults(results, detailed);
      case 'table':
      default:
        await _displayTableResults(results, detailed);
    }
  }

  /// 显示表格格式结果
  Future<void> _displayTableResults(
    List<TemplateMetadata> results,
    bool detailed,
  ) async {
    if (detailed) {
      for (var i = 0; i < results.length; i++) {
        final metadata = results[i];

        print('${i + 1}. 📦 ${metadata.name} (${metadata.version})');
        print('   类型: ${metadata.type.displayName}');
        print('   作者: ${metadata.author}');
        print('   描述: ${metadata.description}');
        print('   平台: ${metadata.platform.name}');
        print('   框架: ${metadata.framework.name}');
        if (metadata.tags.isNotEmpty) {
          print('   标签: ${metadata.tags.join(', ')}');
        }
        print('   评分: ${metadata.rating.toStringAsFixed(1)} ⭐');
        print('   下载: ${metadata.downloadCount} 次');
        print('');
      }
    } else {
      print(
        '${'排名'.padRight(4)}${'名称'.padRight(25)}${'类型'.padRight(12)}${'评分'.padRight(8)}匹配度',
      );
      print('─' * 80);

      for (var i = 0; i < results.length; i++) {
        final metadata = results[i];
        final rank = '${i + 1}.';
        final name = metadata.name.length > 24
            ? '${metadata.name.substring(0, 21)}...'
            : metadata.name;
        final type = metadata.type.name;
        final rating = metadata.rating.toStringAsFixed(1);

        print(
          '${rank.padRight(4)}${name.padRight(25)}${type.padRight(12)}${rating.padRight(8)}',
        );
      }
    }
  }

  /// 显示JSON格式结果
  Future<void> _displayJsonResults(
    List<TemplateMetadata> results,
    bool detailed,
  ) async {
    print('JSON输出功能开发中...');
  }

  /// 显示YAML格式结果
  Future<void> _displayYamlResults(
    List<TemplateMetadata> results,
    bool detailed,
  ) async {
    print('YAML输出功能开发中...');
  }

  /// 显示列表格式结果
  Future<void> _displayListResults(
    List<TemplateMetadata> results,
    bool detailed,
  ) async {
    for (var i = 0; i < results.length; i++) {
      final metadata = results[i];
      if (detailed) {
        print(
          '${i + 1}. ${metadata.name} (${metadata.version}) - ${metadata.description}',
        );
      } else {
        print('${i + 1}. ${metadata.name}');
      }
    }
  }

  /// 显示搜索建议
  void _showSearchSuggestions(String keyword) {
    print('\n💡 搜索建议:');
    print('• 尝试使用更通用的关键词');
    print('• 检查拼写是否正确');
    print('• 使用 --type 或 --platform 参数缩小搜索范围');
    print('• 使用 ming template list 查看所有可用模板');

    // 基于关键词提供具体建议
    final lowerKeyword = keyword.toLowerCase();
    if (lowerKeyword.contains('flutter')) {
      print('• 尝试搜索: "app", "widget", "ui"');
    } else if (lowerKeyword.contains('api')) {
      print('• 尝试搜索: "service", "microservice", "rest"');
    } else if (lowerKeyword.contains('web')) {
      print('• 尝试搜索: "react", "vue", "angular"');
    }
  }
}
