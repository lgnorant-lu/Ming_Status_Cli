/*
---------------------------------------------------------------
File name:          dart_structure_creator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        Dart项目目录结构创建器 (Dart Project Directory Structure Creator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/structure/directory_creator.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// Dart项目目录结构创建器
///
/// 负责创建纯Dart项目的标准目录结构
class DartStructureCreator extends DirectoryCreator {
  /// 创建Dart项目目录结构创建器实例
  const DartStructureCreator();

  @override
  List<String> getDirectories(ScaffoldConfig config) {
    final directories = <String>[];

    // 添加基础Dart目录
    directories.addAll(_getBaseDirectories());

    // 根据模板类型添加特定目录
    directories.addAll(_getTemplateTypeDirectories(config.templateType));

    // 根据复杂度添加目录
    directories.addAll(_getComplexityDirectories(config.complexity));

    // 添加可选功能目录
    if (config.includeTests) {
      directories.addAll(_getTestDirectories());
    }

    if (config.includeDocumentation) {
      directories.addAll(_getDocumentationDirectories());
    }

    if (config.includeExamples) {
      directories.addAll(_getExampleDirectories());
    }

    return directories.toSet().toList()..sort();
  }

  /// 获取基础目录结构
  List<String> _getBaseDirectories() {
    return [
      // 核心源码目录
      'lib',
      'lib/src',
      'lib/src/models',
      'lib/src/services',
      'lib/src/utils',
      'lib/src/constants',
      'lib/src/core',

      // 可执行文件目录
      'bin',

      // 工具脚本目录
      'tool',

      // 模板目录
      'templates',
      'config',
    ];
  }

  /// 获取模板类型特定目录
  List<String> _getTemplateTypeDirectories(TemplateType templateType) {
    final directories = <String>[];

    switch (templateType) {
      case TemplateType.service:
        directories.addAll([
          'lib/src/api',
          'lib/src/repositories',
          'lib/src/services',
        ]);

      case TemplateType.data:
        directories.addAll([
          'lib/src/entities',
          'lib/src/datasources',
          'lib/src/mappers',
          'lib/src/cache',
          'lib/src/serializers',
        ]);

      case TemplateType.full:
        directories.addAll([
          // Service相关
          'lib/src/api',
          'lib/src/data',
          'lib/src/domain',
          'lib/src/infrastructure',
          'lib/src/repositories',
          // Data相关
          'lib/src/entities',
          'lib/src/datasources',
          'lib/src/mappers',
          'lib/src/cache',
          'lib/src/serializers',
          // 额外功能
          'lib/src/features',
          'lib/src/shared',
          'lib/src/extensions',
        ]);

      case TemplateType.system:
        directories.addAll([
          'lib/src/system',
          'lib/src/monitoring',
          'lib/src/logging',
          'lib/src/performance',
          'lib/src/diagnostics',
        ]);

      case TemplateType.plugin:
        directories.addAll([
          'lib/src/platform',
          'lib/src/interfaces',
          'lib/src/implementations',
          'lib/src/exceptions',
        ]);

      case TemplateType.infrastructure:
        directories.addAll([
          'lib/src/database',
          'lib/src/network',
          'lib/src/storage',
          'lib/src/security',
          'lib/src/configuration',
        ]);

      case TemplateType.micro:
        directories.addAll([
          'lib/src/handlers',
          'lib/src/middleware',
          'lib/src/routes',
          'lib/src/controllers',
          'lib/src/dto',
        ]);

      case TemplateType.basic:
      case TemplateType.ui:
        // 使用基础目录结构
        break;
    }

    return directories;
  }

  /// 获取复杂度特定目录
  List<String> _getComplexityDirectories(TemplateComplexity complexity) {
    final directories = <String>[];

    switch (complexity) {
      case TemplateComplexity.simple:
        // 简单项目不需要额外目录
        break;

      case TemplateComplexity.medium:
        directories.addAll([
          'lib/src/config',
          'lib/src/utils',
        ]);

      case TemplateComplexity.complex:
        directories.addAll([
          'lib/src/config',
          'lib/src/extensions',
          'lib/src/helpers',
          'lib/src/middleware',
          'lib/src/interceptors',
          'lib/src/validators',
          'lib/src/converters',
        ]);

      case TemplateComplexity.enterprise:
        directories.addAll([
          'lib/src/config',
          'lib/src/extensions',
          'lib/src/helpers',
          'lib/src/middleware',
          'lib/src/interceptors',
          'lib/src/validators',
          'lib/src/converters',
          'lib/src/security',
          'lib/src/monitoring',
          'lib/src/analytics',
          'lib/src/audit',
          'lib/src/compliance',
        ]);
    }

    return directories;
  }

  /// 获取测试目录
  List<String> _getTestDirectories() {
    return [
      'test',
      'test/unit',
      'test/unit/models',
      'test/unit/services',
      'test/unit/repositories',
      'test/unit/utils',
      'test/integration',
      'test/mocks',
      'test/fixtures',
      'test/helpers',
      'test/performance',
    ];
  }

  /// 获取文档目录
  List<String> _getDocumentationDirectories() {
    return [
      'docs',
      'docs/api',
      'docs/guides',
      'docs/tutorials',
      'docs/architecture',
      'docs/deployment',
      'docs/development',
    ];
  }

  /// 获取示例目录
  List<String> _getExampleDirectories() {
    return [
      'example',
      'example/lib',
      'example/bin',
      'example/test',
    ];
  }

  /// 获取目录描述
  Map<String, String> getDirectoryDescriptions() {
    return {
      'lib': 'Dart库源代码主目录',
      'lib/src': '库的私有实现代码',
      'lib/src/models': '数据模型类',
      'lib/src/services': '业务逻辑服务',
      'lib/src/utils': '工具类和辅助函数',
      'lib/src/constants': '常量定义',
      'lib/src/core': '核心功能模块',
      'lib/src/api': 'API接口定义',
      'lib/src/data': '数据访问层',
      'lib/src/domain': '领域模型',
      'lib/src/infrastructure': '基础设施层',
      'lib/src/repositories': '数据仓库层',
      'lib/src/entities': '实体类',
      'lib/src/datasources': '数据源',
      'lib/src/mappers': '数据映射器',
      'lib/src/cache': '缓存实现',
      'lib/src/serializers': '序列化器',
      'lib/src/features': '功能模块',
      'lib/src/shared': '共享组件',
      'lib/src/extensions': '扩展方法',
      'lib/src/system': '系统级功能',
      'lib/src/monitoring': '监控功能',
      'lib/src/logging': '日志功能',
      'lib/src/performance': '性能监控',
      'lib/src/diagnostics': '诊断工具',
      'lib/src/platform': '平台特定代码',
      'lib/src/interfaces': '接口定义',
      'lib/src/implementations': '接口实现',
      'lib/src/exceptions': '异常类',
      'lib/src/database': '数据库相关',
      'lib/src/network': '网络功能',
      'lib/src/storage': '存储功能',
      'lib/src/security': '安全功能',
      'lib/src/configuration': '配置管理',
      'lib/src/config': '配置文件',
      'lib/src/helpers': '辅助工具',
      'lib/src/middleware': '中间件',
      'lib/src/interceptors': '拦截器',
      'lib/src/validators': '验证器',
      'lib/src/converters': '转换器',
      'lib/src/analytics': '分析功能',
      'lib/src/audit': '审计功能',
      'lib/src/compliance': '合规性检查',
      'bin': '可执行文件',
      'tool': '工具脚本',
      'test': '测试文件',
      'test/unit': '单元测试',
      'test/integration': '集成测试',
      'test/performance': '性能测试',
      'docs': '项目文档',
      'example': '示例代码',
      'templates': '代码模板',
      'config': '配置文件',
    };
  }

  /// 获取目录创建优先级
  ///
  /// 返回目录创建的优先级顺序，数字越小优先级越高
  Map<String, int> getDirectoryPriorities() {
    return {
      'lib': 1,
      'lib/src': 2,
      'bin': 3,
      'tool': 4,
      'test': 5,
      'docs': 6,
      'example': 7,
      'templates': 8,
      'config': 9,
    };
  }

  /// 获取可执行文件建议
  List<String> getExecutableFileSuggestions(ScaffoldConfig config) {
    final suggestions = <String>[];

    switch (config.templateType) {
      case TemplateType.service:
        suggestions.addAll([
          'bin/server.dart',
          'bin/client.dart',
          'bin/migrate.dart',
        ]);

      case TemplateType.micro:
        suggestions.addAll([
          'bin/microservice.dart',
          'bin/gateway.dart',
          'bin/health_check.dart',
        ]);

      case TemplateType.system:
        suggestions.addAll([
          'bin/monitor.dart',
          'bin/diagnostic.dart',
          'bin/benchmark.dart',
        ]);

      case TemplateType.plugin:
        suggestions.addAll([
          'bin/install.dart',
          'bin/configure.dart',
        ]);

      case TemplateType.infrastructure:
        suggestions.addAll([
          'bin/setup.dart',
          'bin/deploy.dart',
          'bin/backup.dart',
        ]);

      case TemplateType.basic:
      case TemplateType.ui:
      case TemplateType.data:
      case TemplateType.full:
        suggestions.addAll([
          'bin/main.dart',
          'bin/${config.templateName}.dart',
        ]);
    }

    return suggestions;
  }

  /// 获取工具脚本建议
  List<String> getToolScriptSuggestions(ScaffoldConfig config) {
    return [
      'tool/build.dart',
      'tool/test.dart',
      'tool/format.dart',
      'tool/analyze.dart',
      'tool/generate.dart',
      'tool/deploy.dart',
    ];
  }
}
