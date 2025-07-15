/*
---------------------------------------------------------------
File name:          widget_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        Flutter Widget组件生成器
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - Flutter Widget组件生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/base/base_code_generator.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// Flutter Widget组件生成器
///
/// 生成Flutter UI组件文件
class WidgetGenerator extends BaseCodeGenerator {
  /// 创建Widget生成器实例
  const WidgetGenerator({
    required this.widgetType,
  });

  /// Widget类型
  final WidgetType widgetType;

  @override
  String getFileName(ScaffoldConfig config) {
    final baseName = config.templateName;
    switch (widgetType) {
      case WidgetType.page:
        return '${baseName}_page.dart';
      case WidgetType.screen:
        return '${baseName}_screen.dart';
      case WidgetType.component:
        return '${baseName}_component.dart';
      case WidgetType.dialog:
        return '${baseName}_dialog.dart';
    }
  }

  @override
  String getRelativePath(ScaffoldConfig config) {
    switch (widgetType) {
      case WidgetType.page:
        return 'lib/src/pages';
      case WidgetType.screen:
        return 'lib/src/screens';
      case WidgetType.component:
        return 'lib/src/components';
      case WidgetType.dialog:
        return 'lib/src/dialogs';
    }
  }

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.write(
      generateFileHeader(
        getFileName(config),
        config,
        '${config.templateName} ${widgetType.displayName}组件',
      ),
    );

    final imports = _getImports(config);
    buffer.write(generateImports(imports));

    switch (widgetType) {
      case WidgetType.page:
        _generatePageWidget(buffer, config);
      case WidgetType.screen:
        _generateScreenWidget(buffer, config);
      case WidgetType.component:
        _generateComponentWidget(buffer, config);
      case WidgetType.dialog:
        _generateDialogWidget(buffer, config);
    }

    return buffer.toString();
  }

  /// 获取导入
  List<String> _getImports(ScaffoldConfig config) {
    final imports = <String>[
      'package:flutter/material.dart',
    ];

    if (config.complexity != TemplateComplexity.simple &&
        (widgetType == WidgetType.screen || widgetType == WidgetType.page)) {
      imports.addAll([
        'package:provider/provider.dart',
        '../providers/${config.templateName}_provider.dart',
      ]);
    }

    // Enterprise复杂度时添加BLoC导入（仅Page组件需要）
    if (config.complexity == TemplateComplexity.enterprise &&
        widgetType == WidgetType.page) {
      imports.add('package:flutter_bloc/flutter_bloc.dart');
    }

    return imports;
  }

  /// 生成页面Widget
  void _generatePageWidget(StringBuffer buffer, ScaffoldConfig config) {
    final className = formatClassName(config.templateName, 'Page');

    buffer.write(
      generateClassDocumentation(
        className,
        '${config.templateName}页面组件',
        examples: [
          'Navigator.push(',
          '  context,',
          '  MaterialPageRoute(builder: (context) => $className()),',
          ')',
        ],
      ),
    );

    buffer.writeln('class $className extends StatefulWidget {');
    buffer.writeln('  /// 创建$className实例');
    buffer.writeln('  const $className({super.key});');
    buffer.writeln();

    buffer.writeln('  @override');
    buffer
        .writeln('  State<$className> createState() => _${className}State();');
    buffer.writeln('}');
    buffer.writeln();

    // State类
    buffer.writeln('class _${className}State extends State<$className> {');

    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln(
          '  late ${formatClassName(config.templateName, 'Provider')} _provider;');
      buffer.writeln();

      buffer.writeln('  @override');
      buffer.writeln('  void initState() {');
      buffer.writeln('    super.initState();');
      buffer.writeln(
          '    _provider = context.read<${formatClassName(config.templateName, 'Provider')}>();');
      buffer.writeln('    _initializeData();');
      buffer.writeln('  }');
      buffer.writeln();

      buffer.writeln('  Future<void> _initializeData() async {');
      buffer.writeln('    await _provider.initialize();');
      buffer.writeln('    if (mounted) {');
      buffer.writeln('      await _provider.loadData();');
      buffer.writeln('    }');
      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');

    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln(
          '    return Consumer<${formatClassName(config.templateName, 'Provider')}>(');
      buffer.writeln('      builder: (context, provider, child) {');
      buffer.writeln('        return Scaffold(');
      _generateScaffoldContent(buffer, config, '        ');
      buffer.writeln('        );');
      buffer.writeln('      },');
      buffer.writeln('    );');
    } else {
      buffer.writeln('    return Scaffold(');
      _generateScaffoldContent(buffer, config, '      ');
      buffer.writeln('    );');
    }

    buffer.writeln('  }');

    // 生成辅助方法
    _generateHelperMethods(buffer, config);

    buffer.writeln('}');
  }

  /// 生成屏幕Widget
  void _generateScreenWidget(StringBuffer buffer, ScaffoldConfig config) {
    final className = formatClassName(config.templateName, 'Screen');

    buffer.write(
      generateClassDocumentation(
        className,
        '${config.templateName}屏幕组件',
      ),
    );

    buffer.writeln('class $className extends StatelessWidget {');
    buffer.writeln('  /// 创建$className实例');
    buffer.writeln('  const $className({super.key});');
    buffer.writeln();

    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return Container(');
    buffer.writeln('      padding: const EdgeInsets.all(16.0),');
    buffer.writeln('      child: Column(');
    buffer.writeln('        crossAxisAlignment: CrossAxisAlignment.start,');
    buffer.writeln('        children: [');
    buffer.writeln('          Text(');
    buffer.writeln(
        "            '${formatClassName(config.templateName, '')} Screen',");
    buffer.writeln(
        '            style: Theme.of(context).textTheme.headlineMedium,');
    buffer.writeln('          ),');
    buffer.writeln('          const SizedBox(height: 16),');
    buffer.writeln('          Expanded(');
    buffer.writeln('            child: _buildContent(context),');
    buffer.writeln('          ),');
    buffer.writeln('        ],');
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  Widget _buildContent(BuildContext context) {');
    buffer.writeln('    return const Center(');
    buffer.writeln(
        "      child: Text('${config.templateName} content goes here'),");
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  /// 生成组件Widget
  void _generateComponentWidget(StringBuffer buffer, ScaffoldConfig config) {
    final className = formatClassName(config.templateName, 'Component');

    buffer.write(
      generateClassDocumentation(
        className,
        '${config.templateName}可复用组件',
      ),
    );

    buffer.writeln('class $className extends StatelessWidget {');
    buffer.writeln('  /// 数据');
    buffer.writeln('  final Map<String, dynamic>? data;');
    buffer.writeln();
    buffer.writeln('  /// 点击回调');
    buffer.writeln('  final VoidCallback? onTap;');
    buffer.writeln();
    buffer.writeln('  /// 创建$className实例');
    buffer.writeln('  const $className({');
    buffer.writeln('    super.key,');
    buffer.writeln('    this.data,');
    buffer.writeln('    this.onTap,');
    buffer.writeln('  });');
    buffer.writeln();

    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return Card(');
    buffer.writeln('      margin: const EdgeInsets.symmetric(');
    buffer.writeln('        horizontal: 16.0,');
    buffer.writeln('        vertical: 8.0,');
    buffer.writeln('      ),');
    buffer.writeln('      child: InkWell(');
    buffer.writeln('        onTap: onTap,');
    buffer.writeln('        borderRadius: BorderRadius.circular(8.0),');
    buffer.writeln('        child: Padding(');
    buffer.writeln('          padding: const EdgeInsets.all(16.0),');
    buffer.writeln('          child: _buildContent(context),');
    buffer.writeln('        ),');
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  Widget _buildContent(BuildContext context) {');
    buffer.writeln('    if (data == null) {');
    buffer.writeln("      return const Text('No data available');");
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    return Column(');
    buffer.writeln('      crossAxisAlignment: CrossAxisAlignment.start,');
    buffer.writeln('      children: [');
    buffer.writeln("        if (data!['title'] != null)");
    buffer.writeln('          Text(');
    buffer.writeln("            data!['title'] as String,");
    buffer
        .writeln('            style: Theme.of(context).textTheme.titleMedium,');
    buffer.writeln('          ),');
    buffer.writeln("        if (data!['subtitle'] != null) ...[");
    buffer.writeln('          const SizedBox(height: 4),');
    buffer.writeln('          Text(');
    buffer.writeln("            data!['subtitle'] as String,");
    buffer
        .writeln('            style: Theme.of(context).textTheme.bodyMedium,');
    buffer.writeln('          ),');
    buffer.writeln('        ],');
    buffer.writeln("        if (data!['description'] != null) ...[");
    buffer.writeln('          const SizedBox(height: 8),');
    buffer.writeln('          Text(');
    buffer.writeln("            data!['description'] as String,");
    buffer.writeln('            style: Theme.of(context).textTheme.bodySmall,');
    buffer.writeln('          ),');
    buffer.writeln('        ],');
    buffer.writeln('      ],');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  /// 生成对话框Widget
  void _generateDialogWidget(StringBuffer buffer, ScaffoldConfig config) {
    final className = formatClassName(config.templateName, 'Dialog');

    buffer.write(
      generateClassDocumentation(
        className,
        '${config.templateName}对话框组件',
        examples: [
          'showDialog(',
          '  context: context,',
          '  builder: (context) => $className(),',
          ')',
        ],
      ),
    );

    buffer.writeln('class $className extends StatefulWidget {');
    buffer.writeln('  /// 标题');
    buffer.writeln('  final String? title;');
    buffer.writeln();
    buffer.writeln('  /// 内容');
    buffer.writeln('  final String? content;');
    buffer.writeln();
    buffer.writeln('  /// 确认回调');
    buffer.writeln('  final VoidCallback? onConfirm;');
    buffer.writeln();
    buffer.writeln('  /// 取消回调');
    buffer.writeln('  final VoidCallback? onCancel;');
    buffer.writeln();
    buffer.writeln('  /// 创建$className实例');
    buffer.writeln('  const $className({');
    buffer.writeln('    super.key,');
    buffer.writeln('    this.title,');
    buffer.writeln('    this.content,');
    buffer.writeln('    this.onConfirm,');
    buffer.writeln('    this.onCancel,');
    buffer.writeln('  });');
    buffer.writeln();

    buffer.writeln('  @override');
    buffer
        .writeln('  State<$className> createState() => _${className}State();');
    buffer.writeln();

    buffer.writeln('  /// 显示对话框');
    buffer.writeln('  static Future<bool?> show(');
    buffer.writeln('    BuildContext context, {');
    buffer.writeln('    String? title,');
    buffer.writeln('    String? content,');
    buffer.writeln('    VoidCallback? onConfirm,');
    buffer.writeln('    VoidCallback? onCancel,');
    buffer.writeln('  }) {');
    buffer.writeln('    return showDialog<bool>(');
    buffer.writeln('      context: context,');
    buffer.writeln('      builder: (context) => $className(');
    buffer.writeln('        title: title,');
    buffer.writeln('        content: content,');
    buffer.writeln('        onConfirm: onConfirm,');
    buffer.writeln('        onCancel: onCancel,');
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();

    // State类
    buffer.writeln('class _${className}State extends State<$className> {');
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return AlertDialog(');
    buffer.writeln(
        '      title: widget.title != null ? Text(widget.title!) : null,');
    buffer.writeln(
        '      content: widget.content != null ? Text(widget.content!) : null,');
    buffer.writeln('      actions: [');
    buffer.writeln('        TextButton(');
    buffer.writeln('          onPressed: () {');
    buffer.writeln('            widget.onCancel?.call();');
    buffer.writeln('            Navigator.of(context).pop(false);');
    buffer.writeln('          },');
    buffer.writeln("          child: const Text('取消'),");
    buffer.writeln('        ),');
    buffer.writeln('        TextButton(');
    buffer.writeln('          onPressed: () {');
    buffer.writeln('            widget.onConfirm?.call();');
    buffer.writeln('            Navigator.of(context).pop(true);');
    buffer.writeln('          },');
    buffer.writeln("          child: const Text('确认'),");
    buffer.writeln('        ),');
    buffer.writeln('      ],');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  /// 生成Scaffold内容
  void _generateScaffoldContent(
      StringBuffer buffer, ScaffoldConfig config, String indent) {
    buffer.writeln('${indent}appBar: AppBar(');
    buffer.writeln(
        "$indent  title: const Text('${formatClassName(config.templateName, '')}'),");
    buffer.writeln('$indent),');

    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('${indent}body: provider.isLoading');
      buffer.writeln(
          '$indent    ? const Center(child: CircularProgressIndicator())');
      buffer.writeln('$indent    : provider.error != null');
      buffer.writeln('$indent        ? _buildErrorWidget(provider.error!)');
      buffer.writeln('$indent        : _buildContent(),');
      buffer.writeln('${indent}floatingActionButton: FloatingActionButton(');
      buffer.writeln('$indent  onPressed: () => _provider.loadData(),');
      buffer.writeln('$indent  child: const Icon(Icons.refresh),');
      buffer.writeln('$indent),');
    } else {
      buffer.writeln('${indent}body: _buildContent(),');
    }
  }

  /// 生成辅助方法
  void _generateHelperMethods(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln();
    buffer.writeln('  Widget _buildContent() {');

    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('    final data = _provider.data;');

      // Enterprise复杂度时的额外逻辑
      if (config.complexity == TemplateComplexity.enterprise) {
        buffer.writeln('    // Enterprise级别的数据处理');
        buffer.writeln('    const maxItems = 10; // 最大显示项目数');
      }
      buffer.writeln('    ');
      buffer.writeln('    if (data.isEmpty) {');
      buffer.writeln('      return const Center(');
      buffer.writeln("        child: Text('暂无数据'),");
      buffer.writeln('      );');
      buffer.writeln('    }');
      buffer.writeln('    ');
      buffer.writeln('    return ListView.builder(');
      if (config.complexity == TemplateComplexity.enterprise) {
        buffer.writeln('      itemCount: data.length.clamp(0, maxItems),');
        buffer.writeln('      itemBuilder: (context, index) {');
        buffer.writeln('        final item = data[index];');
        buffer.writeln('        // Enterprise级别的项目处理');
      } else {
        buffer.writeln('      itemCount: data.length,');
        buffer.writeln('      itemBuilder: (context, index) {');
        buffer.writeln('        final item = data[index];');
      }
      buffer.writeln('        return ListTile(');
      buffer.writeln(
          "          title: Text(item['name']?.toString() ?? 'Unknown'),");
      buffer.writeln(
          "          subtitle: Text(item['description']?.toString() ?? ''),");
      buffer.writeln('          onTap: () => _provider.selectItem(item),');
      buffer.writeln('        );');
      buffer.writeln('      },');
      buffer.writeln('    );');
    } else {
      buffer.writeln('    return const Center(');
      buffer.writeln('      child: Column(');
      buffer.writeln('        mainAxisAlignment: MainAxisAlignment.center,');
      buffer.writeln('        children: [');
      buffer.writeln('          Icon(Icons.star, size: 64),');
      buffer.writeln('          SizedBox(height: 16),');
      buffer.writeln("          Text('${config.templateName} Page'),");
      buffer.writeln('        ],');
      buffer.writeln('      ),');
      buffer.writeln('    );');
    }

    buffer.writeln('  }');

    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln();
      buffer.writeln('  Widget _buildErrorWidget(String error) {');
      buffer.writeln('    return Center(');
      buffer.writeln('      child: Column(');
      buffer.writeln('        mainAxisAlignment: MainAxisAlignment.center,');
      buffer.writeln('        children: [');
      buffer.writeln(
          '          const Icon(Icons.error, size: 64, color: Colors.red),');
      buffer.writeln('          const SizedBox(height: 16),');
      buffer.writeln('          Text(error),');
      buffer.writeln('          const SizedBox(height: 16),');
      buffer.writeln('          ElevatedButton(');
      buffer.writeln('            onPressed: () => _provider.loadData(),');
      buffer.writeln("            child: const Text('重试'),");
      buffer.writeln('          ),');
      buffer.writeln('        ],');
      buffer.writeln('      ),');
      buffer.writeln('    );');
      buffer.writeln('  }');
    }
  }
}

/// Widget类型枚举
enum WidgetType {
  page('页面'),
  screen('屏幕'),
  component('组件'),
  dialog('对话框');

  const WidgetType(this.displayName);
  final String displayName;
}
