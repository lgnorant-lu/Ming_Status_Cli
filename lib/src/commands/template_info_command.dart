/*
---------------------------------------------------------------
File name:          template_info_command.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板信息命令 (Template Info Command)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - 模板信息命令;
    2025/07/11: Feature enhancement - 添加详细信息和过滤选项;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
// import 'package:ming_status_cli/src/core/template_system/template_metadata.dart';  // 未使用，注释掉
import 'package:ming_status_cli/src/core/template_system/template_registry.dart'
    as registry;
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板信息命令
///
/// 实现 `ming template info` 命令
class TemplateInfoCommand extends Command<int> {
  /// 创建模板信息命令实例
  TemplateInfoCommand() {
    argParser
      ..addOption(
        'version',
        abbr: 'v',
        help: '指定模板版本',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '输出格式',
        allowed: ['default', 'json', 'yaml'],
        defaultsTo: 'default',
      )
      ..addFlag(
        'detailed',
        abbr: 'd',
        help: '显示详细信息',
      )
      ..addFlag(
        'dependencies',
        help: '显示依赖关系',
      )
      ..addFlag(
        'metadata',
        abbr: 'm',
        help: '显示完整元数据',
      )
      ..addFlag(
        'performance',
        abbr: 'p',
        help: '显示性能指标',
      )
      ..addFlag(
        'security',
        abbr: 's',
        help: '显示安全信息',
      )
      ..addFlag(
        'compatibility',
        abbr: 'c',
        help: '显示兼容性信息',
      );
  }

  @override
  String get name => 'info';

  @override
  String get description => '显示模板详细信息';

  @override
  String get usage => '''
显示模板详细信息

使用方法:
  ming template info <模板名称> [选项]

参数:
  <模板名称>               要查看的模板名称

基础选项:
  -v, --version=<版本>     指定模板版本
  -o, --output=<格式>      输出格式 (默认: default)
  -d, --detailed           显示详细信息

输出格式:
      default              默认格式输出
      json                 JSON格式输出
      yaml                 YAML格式输出

信息选项:
      --dependencies       显示依赖关系
  -m, --metadata           显示完整元数据
  -p, --performance        显示性能指标
  -s, --security           显示安全信息
  -c, --compatibility      显示兼容性信息

示例:
  # 基础信息
  ming template info flutter_clean_app

  # 详细信息
  ming template info flutter_clean_app --detailed

  # 指定版本
  ming template info flutter_clean_app --version=2.1.0

  # 显示依赖关系
  ming template info flutter_clean_app --dependencies

  # 完整元数据
  ming template info flutter_clean_app --metadata --detailed

  # JSON格式输出
  ming template info flutter_clean_app --output=json

  # 性能和兼容性信息
  ming template info flutter_clean_app --performance --compatibility

更多信息:
  使用 'ming help template info' 查看详细文档
''';

  @override
  Future<int> run() async {
    try {
      // 获取模板名称
      if (argResults!.rest.isEmpty) {
        cli_logger.Logger.error('请提供模板名称');
        print(usage);
        return 1;
      }

      final templateName = argResults!.rest.first;
      final version = argResults!['version'] as String?;

      cli_logger.Logger.info('正在获取模板信息: $templateName');

      // 获取模板注册表 - 使用当前工作目录（与其他命令保持一致）
      final templateRegistry =
          registry.TemplateRegistry(registryPath: Directory.current.path);

      // 获取模板信息
      final templateInfo = await templateRegistry.getTemplateInfo(
        templateName,
        version: version,
      );

      if (templateInfo == null) {
        cli_logger.Logger.error('未找到模板: $templateName');
        _showSimilarTemplates(templateRegistry, templateName);
        return 1;
      }

      // 显示模板信息
      await _displayTemplateInfo(templateInfo);

      return 0;
    } catch (e) {
      cli_logger.Logger.error('获取模板信息失败', error: e);
      return 1;
    }
  }

  /// 显示模板信息
  Future<void> _displayTemplateInfo(registry.TemplateInfo templateInfo) async {
    final outputFormat = argResults!['output'] as String;

    switch (outputFormat) {
      case 'json':
        await _displayJsonInfo(templateInfo);
      case 'yaml':
        await _displayYamlInfo(templateInfo);
      case 'default':
      default:
        await _displayDefaultInfo(templateInfo);
    }
  }

  /// 显示默认格式信息
  Future<void> _displayDefaultInfo(registry.TemplateInfo templateInfo) async {
    final metadata = templateInfo.metadata;
    final detailed = argResults!['detailed'] as bool;
    final showDependencies = argResults!['dependencies'] as bool;
    final showMetadata = argResults!['metadata'] as bool;
    final showPerformance = argResults!['performance'] as bool;
    final showSecurity = argResults!['security'] as bool;
    final showCompatibility = argResults!['compatibility'] as bool;

    print('\n📦 ${metadata.name}');
    print('═' * 60);

    // 基础信息
    print('📋 基础信息');
    print('─' * 30);
    print('版本: ${metadata.version}');
    print('作者: ${metadata.author}');
    print('描述: ${metadata.description}');
    print('类型: ${metadata.type.name}');
    if (metadata.subType != null) {
      print('子类型: ${metadata.subType!.name}');
    }
    print('平台: ${metadata.platform.name}');
    print('框架: ${metadata.framework.name}');
    print('复杂度: ${metadata.complexity.name}');
    print('成熟度: ${metadata.maturity.name}');

    // 评分和统计
    print('\n📊 统计信息');
    print('─' * 30);
    print('评分: ${metadata.rating.toStringAsFixed(1)} ⭐');
    print('下载次数: ${metadata.downloadCount}');
    print('评价数量: ${metadata.reviewCount}');
    print('创建时间: ${metadata.createdAt.toString().substring(0, 10)}');
    print('更新时间: ${metadata.updatedAt.toString().substring(0, 10)}');

    // 标签
    if (metadata.tags.isNotEmpty) {
      print('\n🏷️  标签');
      print('─' * 30);
      print(metadata.tags.join(', '));
    }

    // 关键词
    if (metadata.keywords.isNotEmpty) {
      print('\n🔍 关键词');
      print('─' * 30);
      print(metadata.keywords.join(', '));
    }

    // 许可证信息
    if (metadata.license != null) {
      print('\n📄 许可证');
      print('─' * 30);
      print('类型: ${metadata.license!.name}');
      print('链接: ${metadata.license!.url}');
    }

    // 支持信息
    if (metadata.support != null) {
      print('\n🆘 支持信息');
      print('─' * 30);
      if (metadata.support!.email != null) {
        print('邮箱: ${metadata.support!.email}');
      }
      if (metadata.support!.website != null) {
        print('网站: ${metadata.support!.website}');
      }
      if (metadata.support!.documentation != null) {
        print('文档: ${metadata.support!.documentation}');
      }
    }

    // 企业级信息
    if (detailed || showMetadata) {
      if (metadata.organizationId != null || metadata.teamId != null) {
        print('\n🏢 企业信息');
        print('─' * 30);
        if (metadata.organizationId != null) {
          print('组织ID: ${metadata.organizationId}');
        }
        if (metadata.teamId != null) {
          print('团队ID: ${metadata.teamId}');
        }
      }

      // 合规信息
      if (metadata.compliance != null) {
        print('\n✅ 合规信息');
        print('─' * 30);

        if (metadata.compliance!.standards.isNotEmpty) {
          print('标准: ${metadata.compliance!.standards.join(', ')}');
        }
        if (metadata.compliance!.certifications.isNotEmpty) {
          print('认证: ${metadata.compliance!.certifications.join(', ')}');
        }
      }
    }

    // 依赖关系
    if (showDependencies && templateInfo.dependencies.isNotEmpty) {
      print('\n🔗 依赖关系');
      print('─' * 30);
      for (final dep in templateInfo.dependencies) {
        final typeIcon = dep.type == registry.DependencyType.required
            ? '🔴'
            : dep.type == registry.DependencyType.optional
                ? '🟡'
                : '🔵';
        print('$typeIcon ${dep.name} (${dep.version})');
        if (dep.description?.isNotEmpty == true) {
          print('   ${dep.description}');
        }
      }
    }

    // 性能指标
    if (showPerformance && templateInfo.performanceMetrics != null) {
      final metrics = templateInfo.performanceMetrics!;
      print('\n⚡ 性能指标');
      print('─' * 30);
      print('生成时间: ${metrics.generationTime.inMilliseconds}ms');
      print(
        '内存使用: ${(metrics.memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB',
      );
      print('文件数量: ${metrics.fileCount}');
      print('代码行数: ${metrics.linesOfCode}');
    }

    // 安全信息
    if (showSecurity && metadata.security != null) {
      print('\n🔒 安全信息');
      print('─' * 30);
      if (metadata.security!.vulnerabilities.isNotEmpty) {
        print('已知漏洞: ${metadata.security!.vulnerabilities.length}');
      } else {
        print('已知漏洞: 无');
      }
      if (metadata.security!.lastAudit != null) {
        print(
          '最后审计: ${metadata.security!.lastAudit.toString().substring(0, 10)}',
        );
      }
      if (metadata.security!.securityPolicy != null) {
        print('安全策略: ${metadata.security!.securityPolicy}');
      }
    }

    // 兼容性信息
    if (showCompatibility && templateInfo.compatibility != null) {
      final compat = templateInfo.compatibility!;
      print('\n🔄 兼容性信息');
      print('─' * 30);
      print('Dart SDK: ${compat.dartSdkVersion}');
      if (compat.flutterVersion != null) {
        print('Flutter: ${compat.flutterVersion}');
      }
      print('平台支持: ${compat.supportedPlatforms.join(', ')}');
      if (compat.minimumRequirements.isNotEmpty) {
        print('最低要求:');
        compat.minimumRequirements.forEach((key, value) {
          print('  $key: $value');
        });
      }
    }
  }

  /// 显示JSON格式信息
  Future<void> _displayJsonInfo(registry.TemplateInfo templateInfo) async {
    final jsonData = {
      'id': templateInfo.metadata.id,
      'name': templateInfo.metadata.name,
      'version': templateInfo.metadata.version,
      'author': templateInfo.metadata.author,
      'description': templateInfo.metadata.description,
      'type': templateInfo.metadata.type.name,
      'platform': templateInfo.metadata.platform.name,
      'framework': templateInfo.metadata.framework.name,
      'complexity': templateInfo.metadata.complexity.name,
      'maturity': templateInfo.metadata.maturity.name,
      'tags': templateInfo.metadata.tags,
      'keywords': templateInfo.metadata.keywords,
      'category': templateInfo.metadata.category,
      'createdAt': templateInfo.metadata.createdAt.toIso8601String(),
      'updatedAt': templateInfo.metadata.updatedAt.toIso8601String(),
      'dependencies': templateInfo.dependencies
          .map((dep) => {
                'name': dep.name,
                'version': dep.version,
                'type': dep.type.name,
                'description': dep.description,
              },)
          .toList(),
    };

    print(jsonEncode(jsonData));
  }

  /// 显示YAML格式信息
  Future<void> _displayYamlInfo(registry.TemplateInfo templateInfo) async {
    final buffer = StringBuffer();
    final metadata = templateInfo.metadata;

    buffer.writeln('id: ${metadata.id}');
    buffer.writeln('name: ${metadata.name}');
    buffer.writeln('version: ${metadata.version}');
    buffer.writeln('author: ${metadata.author}');
    buffer.writeln('description: ${metadata.description}');
    buffer.writeln('type: ${metadata.type.name}');
    buffer.writeln('platform: ${metadata.platform.name}');
    buffer.writeln('framework: ${metadata.framework.name}');
    buffer.writeln('complexity: ${metadata.complexity.name}');
    buffer.writeln('maturity: ${metadata.maturity.name}');
    buffer.writeln('tags: [${metadata.tags.join(', ')}]');
    buffer.writeln('keywords: [${metadata.keywords.join(', ')}]');
    buffer.writeln('category: ${metadata.category}');
    buffer.writeln('createdAt: ${metadata.createdAt.toIso8601String()}');
    buffer.writeln('updatedAt: ${metadata.updatedAt.toIso8601String()}');

    if (templateInfo.dependencies.isNotEmpty) {
      buffer.writeln('dependencies:');
      for (final dep in templateInfo.dependencies) {
        buffer.writeln('  - name: ${dep.name}');
        buffer.writeln('    version: ${dep.version}');
        buffer.writeln('    type: ${dep.type.name}');
        if (dep.description != null) {
          buffer.writeln('    description: ${dep.description}');
        }
      }
    } else {
      buffer.writeln('dependencies: []');
    }

    print(buffer);
  }

  /// 显示相似模板建议
  Future<void> _showSimilarTemplates(
    registry.TemplateRegistry templateRegistry,
    String templateName,
  ) async {
    try {
      // 尝试模糊搜索
      final query = registry.TemplateSearchQuery(
        keyword: templateName,
        limit: 5,
      );

      final searchResult = await templateRegistry.searchTemplates(query);

      if (searchResult.templates.isNotEmpty) {
        print('\n💡 您是否要查找以下模板？');
        for (var i = 0; i < searchResult.templates.length; i++) {
          final metadata = searchResult.templates[i];
          print(
            '${i + 1}. ${metadata.name} - ${metadata.description}',
          );
        }
        print('\n使用 ming template info <模板名称> 查看详细信息');
      }
    } catch (e) {
      // 忽略搜索错误
    }
  }
}
