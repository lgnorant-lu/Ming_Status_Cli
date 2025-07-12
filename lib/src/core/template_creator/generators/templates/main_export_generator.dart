/*
---------------------------------------------------------------
File name:          main_export_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        主导出文件生成器 (Main Export Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Initial creation - 主导出文件生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/template_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 主导出文件生成器
///
/// 生成模块的公共API导出文件
class MainExportGenerator extends TemplateGeneratorBase {
  /// 创建主导出生成器实例
  const MainExportGenerator();

  @override
  String getTemplateFileName() => 'main_export.dart.template';

  @override
  String getOutputFileName(ScaffoldConfig config) =>
      '${config.templateName}.dart.template';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.writeln(
      generateFileHeader(
        '${config.templateName}.dart',
        config,
        '${config.templateName}模块公共API导出文件',
      ),
    );

    // 添加库文档
    _generateLibraryDocumentation(buffer, config);

    // 添加导出语句
    _generateExports(buffer, config);

    return buffer.toString();
  }

  /// 生成库文档
  void _generateLibraryDocumentation(
    StringBuffer buffer,
    ScaffoldConfig config,
  ) {
    buffer.writeln('/// ${config.templateName}模块');
    buffer.writeln('/// ');
    buffer.writeln('/// ${config.description ?? '提供模块功能的公共API接口'}');
    buffer.writeln('/// ');
    buffer.writeln('/// ## 功能特性');
    buffer.writeln('/// ');

    // 根据模板类型添加特性描述
    switch (config.templateType) {
      case TemplateType.ui:
        buffer.writeln('/// - 提供UI组件和界面元素');
        buffer.writeln('/// - 支持主题定制和样式配置');
        buffer.writeln('/// - 响应式设计支持');
      case TemplateType.service:
        buffer.writeln('/// - 提供业务服务和API接口');
        buffer.writeln('/// - 支持异步操作和错误处理');
        buffer.writeln('/// - 数据持久化和缓存');
      case TemplateType.data:
        buffer.writeln('/// - 提供数据模型和序列化');
        buffer.writeln('/// - 支持数据验证和转换');
        buffer.writeln('/// - 数据库操作和查询');
      case TemplateType.full:
        buffer.writeln('/// - 完整的功能模块实现');
        buffer.writeln('/// - UI组件和业务逻辑');
        buffer.writeln('/// - 数据管理和状态控制');
      case TemplateType.basic:
        buffer.writeln('/// - 基础功能实现');
        buffer.writeln('/// - 核心API接口');
        buffer.writeln('/// - 简单易用的设计');
      default:
        buffer.writeln('/// - 模块化设计');
        buffer.writeln('/// - 可扩展架构');
        buffer.writeln('/// - 标准化接口');
    }

    buffer.writeln('/// ');
    buffer.writeln('/// ## 使用示例');
    buffer.writeln('/// ');
    buffer.writeln('/// ```dart');
    buffer.writeln(
      "/// import 'package:${config.templateName}/${config.templateName}.dart';",
    );
    buffer.writeln('/// ');

    // 根据框架类型添加使用示例
    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('/// // 在Flutter应用中使用');
      buffer.writeln('/// class MyApp extends StatelessWidget {');
      buffer.writeln('///   @override');
      buffer.writeln('///   Widget build(BuildContext context) {');
      buffer.writeln('///     return MaterialApp(');
      buffer.writeln(
        '///       home: ${_getExampleWidgetName(config.templateName)}(),',
      );
      buffer.writeln('///     );');
      buffer.writeln('///   }');
      buffer.writeln('/// }');
    } else {
      buffer.writeln('/// // 在Dart应用中使用');
      buffer.writeln('/// void main() async {');
      buffer.writeln(
        '///   final module = ${_getModuleClassName(config.templateName)}.instance;',
      );
      buffer.writeln('///   await module.initialize();');
      buffer.writeln('///   // 使用模块功能');
      buffer.writeln('/// }');
    }

    buffer.writeln('/// ```');
    buffer.writeln('/// ');
    buffer.writeln('/// @author ${config.author ?? 'Unknown'}');
    buffer.writeln('/// @version 1.0.0');
    buffer.writeln('library ${config.templateName};');
    buffer.writeln();
  }

  /// 生成导出语句
  void _generateExports(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('// 核心模块导出');
    buffer.writeln("export '${config.templateName}_module.dart';");
    buffer.writeln();

    // 根据模板类型添加特定导出
    switch (config.templateType) {
      case TemplateType.ui:
        _generateUIExports(buffer, config);
      case TemplateType.service:
        _generateServiceExports(buffer, config);
      case TemplateType.data:
        _generateDataExports(buffer, config);
      case TemplateType.full:
        _generateFullExports(buffer, config);
      case TemplateType.basic:
        _generateBasicExports(buffer, config);
      default:
        _generateDefaultExports(buffer, config);
    }

    // 根据复杂度添加额外导出
    if (config.complexity == TemplateComplexity.enterprise) {
      _generateEnterpriseExports(buffer, config);
    }

    // 添加条件导出
    _generateConditionalExports(buffer, config);
  }

  /// 生成UI类型导出
  void _generateUIExports(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('// UI组件导出');
    buffer.writeln("export 'src/widgets/index.dart';");
    buffer.writeln("export 'src/themes/index.dart';");
    buffer.writeln("export 'src/styles/index.dart';");
    buffer.writeln();

    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('// Flutter特定导出');
      buffer.writeln("export 'src/widgets/flutter/index.dart';");
      buffer.writeln("export 'src/screens/index.dart';");
      buffer.writeln();
    }
  }

  /// 生成服务类型导出
  void _generateServiceExports(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('// 服务接口导出');
    buffer.writeln("export 'src/services/index.dart';");
    buffer.writeln("export 'src/repositories/index.dart';");
    buffer.writeln("export 'src/providers/index.dart';");
    buffer.writeln();

    buffer.writeln('// API接口导出');
    buffer.writeln("export 'src/api/index.dart';");
    buffer.writeln("export 'src/models/index.dart';");
    buffer.writeln();
  }

  /// 生成数据类型导出
  void _generateDataExports(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('// 数据模型导出');
    buffer.writeln("export 'src/models/index.dart';");
    buffer.writeln("export 'src/entities/index.dart';");
    buffer.writeln("export 'src/dto/index.dart';");
    buffer.writeln();

    buffer.writeln('// 数据访问导出');
    buffer.writeln("export 'src/repositories/index.dart';");
    buffer.writeln("export 'src/datasources/index.dart';");
    buffer.writeln();
  }

  /// 生成完整类型导出
  void _generateFullExports(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('// 完整模块导出');
    buffer.writeln("export 'src/widgets/index.dart';");
    buffer.writeln("export 'src/services/index.dart';");
    buffer.writeln("export 'src/models/index.dart';");
    buffer.writeln("export 'src/providers/index.dart';");
    buffer.writeln("export 'src/repositories/index.dart';");
    buffer.writeln();

    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('// Flutter完整导出');
      buffer.writeln("export 'src/screens/index.dart';");
      buffer.writeln("export 'src/themes/index.dart';");
      buffer.writeln();
    }
  }

  /// 生成基础类型导出
  void _generateBasicExports(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('// 基础功能导出');
    buffer.writeln("export 'src/core/index.dart';");
    buffer.writeln("export 'src/utils/index.dart';");
    buffer.writeln();
  }

  /// 生成默认导出
  void _generateDefaultExports(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('// 通用导出');
    buffer.writeln("export 'src/core/index.dart';");
    buffer.writeln("export 'src/utils/index.dart';");
    buffer.writeln();
  }

  /// 生成企业级导出
  void _generateEnterpriseExports(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('// 企业级功能导出');
    buffer.writeln("export 'src/security/index.dart';");
    buffer.writeln("export 'src/monitoring/index.dart';");
    buffer.writeln("export 'src/logging/index.dart';");
    buffer.writeln("export 'src/configuration/index.dart';");
    buffer.writeln();
  }

  /// 生成条件导出
  void _generateConditionalExports(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('// 条件导出（根据平台和环境）');

    // 平台特定导出
    switch (config.platform) {
      case TemplatePlatform.mobile:
        buffer.writeln("export 'src/mobile/index.dart';");
      case TemplatePlatform.web:
        buffer.writeln("export 'src/web/index.dart';");
      case TemplatePlatform.desktop:
        buffer.writeln("export 'src/desktop/index.dart';");
      case TemplatePlatform.crossPlatform:
        buffer.writeln("export 'src/cross_platform/index.dart';");
      case TemplatePlatform.server:
        buffer.writeln("export 'src/server/index.dart';");
      case TemplatePlatform.cloud:
        buffer.writeln("export 'src/cloud/index.dart';");
      default:
        break;
    }

    buffer.writeln();
    buffer.writeln('// 开发工具导出（仅在开发环境）');
    buffer.writeln("// export 'src/dev_tools/index.dart';");
    buffer.writeln();
    buffer.writeln('// 测试工具导出（仅在测试环境）');
    buffer.writeln("// export 'src/test_utils/index.dart';");
  }

  /// 获取示例Widget名称
  String _getExampleWidgetName(String templateName) {
    final words = templateName.split('_');
    final className = words
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join();
    return '${className}Widget';
  }

  /// 获取模块类名
  String _getModuleClassName(String templateName) {
    final words = templateName.split('_');
    final className = words
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join();
    return '${className}Module';
  }
}
