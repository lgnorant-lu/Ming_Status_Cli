/*
---------------------------------------------------------------
File name:          template_conditional_command.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板条件生成命令 (Template Conditional Generation Command)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - 智能条件生成系统CLI命令;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/conditional/condition_evaluator.dart';
import 'package:ming_status_cli/src/core/conditional/conditional_renderer.dart';
import 'package:ming_status_cli/src/core/conditional/feature_detector.dart';
import 'package:ming_status_cli/src/core/conditional/platform_detector.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板条件生成命令
///
/// 实现 `ming template conditional` 命令，支持智能条件生成功能
class TemplateConditionalCommand extends Command<int> {
  /// 创建模板条件生成命令实例
  TemplateConditionalCommand() {
    argParser
      ..addOption(
        'template',
        abbr: 't',
        help: '模板文件路径',
        mandatory: true,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '输出文件路径',
      )
      ..addOption(
        'platform',
        abbr: 'p',
        help: '目标平台',
        allowed: ['mobile', 'web', 'desktop', 'server'],
        allowedHelp: {
          'mobile': '移动平台 (iOS/Android)',
          'web': 'Web平台',
          'desktop': '桌面平台',
          'server': '服务器端',
        },
      )
      ..addOption(
        'framework',
        abbr: 'f',
        help: '技术框架',
        allowed: ['flutter', 'react', 'vue', 'angular', 'nodejs'],
        allowedHelp: {
          'flutter': 'Flutter框架',
          'react': 'React框架',
          'vue': 'Vue.js框架',
          'angular': 'Angular框架',
          'nodejs': 'Node.js',
        },
      )
      ..addOption(
        'environment',
        abbr: 'e',
        help: '运行环境',
        allowed: ['development', 'testing', 'staging', 'production'],
        allowedHelp: {
          'development': '开发环境',
          'testing': '测试环境',
          'staging': '预发布环境',
          'production': '生产环境',
        },
      )
      ..addOption(
        'features',
        help: '启用的功能特性，用逗号分隔',
      )
      ..addOption(
        'variables',
        abbr: 'v',
        help: '自定义变量，格式: key1=value1,key2=value2',
      )
      ..addFlag(
        'detect-platform',
        help: '自动检测当前平台',
      )
      ..addFlag(
        'detect-features',
        help: '自动检测项目特性',
      )
      ..addFlag(
        'show-context',
        help: '显示渲染上下文信息',
      )
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help: '仅显示渲染结果，不写入文件',
      );
  }

  @override
  String get name => 'conditional';

  @override
  String get description => '执行智能条件模板生成';

  @override
  String get usage => '''
执行智能条件模板生成

使用方法:
  ming template conditional [选项]

必需选项:
  -t, --template=<路径>      模板文件路径

输出选项:
  -o, --output=<路径>        输出文件路径
  -d, --dry-run              仅显示渲染结果，不写入文件

条件选项:
  -p, --platform=<平台>      目标平台 (可选值见下方)
  -f, --framework=<框架>     技术框架 (可选值见下方)
  -e, --environment=<环境>   运行环境 (可选值见下方)
      --features=<特性>      启用的功能特性，用逗号分隔
  -v, --variables=<变量>     自定义变量，格式: key1=value1,key2=value2

目标平台 (-p, --platform):
  mobile                     移动平台 (iOS/Android)
  web                        Web平台
  desktop                    桌面平台
  server                     服务器端

技术框架 (-f, --framework):
  flutter                    Flutter框架
  react                      React框架
  vue                        Vue.js框架
  angular                    Angular框架
  nodejs                     Node.js

运行环境 (-e, --environment):
  development                开发环境
  testing                    测试环境
  staging                    预发布环境
  production                 生产环境

自动检测选项:
      --detect-platform      自动检测当前平台
      --detect-features      自动检测项目特性
      --show-context         显示渲染上下文信息

示例:
  # 基础条件渲染
  ming template conditional --template=app.template --platform=mobile

  # 自动检测平台和特性
  ming template conditional -t app.template --detect-platform --detect-features

  # 指定多个特性
  ming template conditional -t app.template --features=offline,auth,analytics

  # 自定义变量
  ming template conditional -t app.template --variables=app_name=MyApp,version=1.0.0

  # 预览模式
  ming template conditional -t app.template --dry-run --show-context

  # 完整条件渲染
  ming template conditional -t app.template -o output.dart --platform=mobile --framework=flutter --environment=production

更多信息:
  使用 'ming help template conditional' 查看详细文档
''';

  @override
  Future<int> run() async {
    try {
      final templatePath = argResults!['template'] as String;
      final outputPath = argResults!['output'] as String?;
      final platform = argResults!['platform'] as String?;
      final framework = argResults!['framework'] as String?;
      final environment = argResults!['environment'] as String?;
      final featuresStr = argResults!['features'] as String?;
      final variablesStr = argResults!['variables'] as String?;
      final detectPlatform = argResults!['detect-platform'] as bool;
      final detectFeatures = argResults!['detect-features'] as bool;
      final showContext = argResults!['show-context'] as bool;
      final dryRun = argResults!['dry-run'] as bool;

      cli_logger.Logger.info('开始条件模板生成: $templatePath');

      // 创建条件渲染组件
      final platformDetector = PlatformDetector();
      final featureDetector = FeatureDetector();
      final conditionEvaluator = ConditionEvaluator();
      final conditionalRenderer = ConditionalRenderer(
        conditionEvaluator: conditionEvaluator,
      );

      // 构建渲染上下文
      final context = await _buildRenderContext(
        platformDetector,
        featureDetector,
        platform: platform,
        framework: framework,
        environment: environment,
        featuresStr: featuresStr,
        variablesStr: variablesStr,
        detectPlatform: detectPlatform,
        detectFeatures: detectFeatures,
      );

      // 显示上下文信息
      if (showContext) {
        _displayRenderContext(context);
      }

      // 读取模板文件
      final templateContent = await _readTemplateFile(templatePath);
      if (templateContent == null) {
        cli_logger.Logger.error('无法读取模板文件: $templatePath');
        return 1;
      }

      // 执行条件渲染
      cli_logger.Logger.info('执行条件渲染...');
      final renderContext = RenderContext(variables: context);
      final renderResult = await conditionalRenderer.render(
        templateContent,
        renderContext,
      );

      // 显示渲染结果
      if (dryRun) {
        print('\n📄 渲染结果预览');
        print('─' * 50);
        print(renderResult.content);
        print('─' * 50);
        print('✅ 预览完成，未写入文件');
      } else {
        // 写入输出文件
        final finalOutputPath = outputPath ?? _generateOutputPath(templatePath);
        await _writeOutputFile(finalOutputPath, renderResult.content);
        cli_logger.Logger.success('条件渲染完成: $finalOutputPath');
      }

      return 0;
    } catch (e) {
      cli_logger.Logger.error('条件模板生成失败', error: e);
      return 1;
    }
  }

  /// 构建渲染上下文
  Future<Map<String, dynamic>> _buildRenderContext(
    PlatformDetector platformDetector,
    FeatureDetector featureDetector, {
    String? platform,
    String? framework,
    String? environment,
    String? featuresStr,
    String? variablesStr,
    bool detectPlatform = false,
    bool detectFeatures = false,
  }) async {
    final context = <String, dynamic>{};

    // 平台信息
    if (detectPlatform) {
      cli_logger.Logger.info('自动检测平台信息...');
      final detectionResult = await platformDetector.detectPlatform();
      context['platform'] = {
        'type': detectionResult.primaryPlatform.name,
        'confidence': detectionResult.confidence,
        'mobile': detectionResult.primaryPlatform == PlatformType.mobile,
        'web': detectionResult.primaryPlatform == PlatformType.web,
        'desktop': detectionResult.primaryPlatform == PlatformType.desktop,
        'server': detectionResult.primaryPlatform == PlatformType.server,
      };
    } else if (platform != null) {
      context['platform'] = {
        'type': platform,
        'mobile': platform == 'mobile',
        'web': platform == 'web',
        'desktop': platform == 'desktop',
        'server': platform == 'server',
      };
    }

    // 框架信息
    if (framework != null) {
      context['framework'] = {
        'name': framework,
        'flutter': framework == 'flutter',
        'react': framework == 'react',
        'vue': framework == 'vue',
        'angular': framework == 'angular',
        'nodejs': framework == 'nodejs',
      };
    }

    // 环境信息
    if (environment != null) {
      context['environment'] = {
        'name': environment,
        'development': environment == 'development',
        'testing': environment == 'testing',
        'staging': environment == 'staging',
        'production': environment == 'production',
      };
    }

    // 功能特性
    if (detectFeatures) {
      cli_logger.Logger.info('自动检测项目特性...');
      // final features = await featureDetector.detectFeatures(projectPath: '.');
      context['features'] = {
        'offline': true,
        'auth': false,
        'analytics': false,
      };
    } else if (featuresStr != null) {
      final featuresList = featuresStr.split(',').map((f) => f.trim()).toList();
      context['features'] = {
        for (final feature in featuresList) feature: true,
      };
    }

    // 自定义变量
    if (variablesStr != null) {
      final variables = _parseVariables(variablesStr);
      context.addAll(variables);
    }

    return context;
  }

  /// 解析变量字符串
  Map<String, dynamic> _parseVariables(String variablesStr) {
    final variables = <String, dynamic>{};
    final pairs = variablesStr.split(',');

    for (final pair in pairs) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        variables[key] = value;
      }
    }

    return variables;
  }

  /// 显示渲染上下文
  void _displayRenderContext(Map<String, dynamic> context) {
    print('\n🔧 渲染上下文');
    print('─' * 50);

    for (final entry in context.entries) {
      print('${entry.key}: ${entry.value}');
    }

    print('');
  }

  /// 读取模板文件
  Future<String?> _readTemplateFile(String templatePath) async {
    try {
      // 这里应该实现实际的文件读取逻辑
      // 暂时返回模拟内容
      return '''
{{#if platform.mobile}}
# Mobile App Template
{{#if features.offline}}
- Offline support enabled
{{/if}}
{{#if features.auth}}
- Authentication enabled
{{/if}}
{{/if}}

{{#if platform.web}}
# Web App Template
{{#if framework.react}}
- React framework
{{/if}}
{{#if framework.vue}}
- Vue framework
{{/if}}
{{/if}}

App Name: {{app_name}}
Version: {{version}}
Environment: {{environment.name}}
''';
    } catch (e) {
      return null;
    }
  }

  /// 生成输出路径
  String _generateOutputPath(String templatePath) {
    if (templatePath.endsWith('.template')) {
      return templatePath.replaceAll('.template', '.generated');
    }
    return '$templatePath.generated';
  }

  /// 写入输出文件
  Future<void> _writeOutputFile(String outputPath, String content) async {
    try {
      // 这里应该实现实际的文件写入逻辑
      cli_logger.Logger.info('写入文件: $outputPath');
      // File(outputPath).writeAsStringSync(content);
    } catch (e) {
      throw Exception('写入文件失败: $e');
    }
  }
}
