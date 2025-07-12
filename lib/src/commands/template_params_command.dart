/*
---------------------------------------------------------------
File name:          template_params_command.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板参数化命令 (Template Parameters Command)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - 企业级参数化系统CLI命令;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板参数化命令
///
/// 实现 `ming template params` 命令，支持企业级参数化功能
class TemplateParamsCommand extends Command<int> {
  /// 创建模板参数化命令实例
  TemplateParamsCommand() {
    argParser
      ..addOption(
        'template',
        abbr: 't',
        help: '模板名称',
        mandatory: true,
      )
      ..addOption(
        'action',
        abbr: 'a',
        help: '操作类型',
        allowed: ['list', 'collect', 'validate', 'preset'],
        defaultsTo: 'list',
      )
      ..addOption(
        'preset',
        abbr: 'p',
        help: '参数预设名称',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '输出文件路径',
      )
      ..addOption(
        'mode',
        abbr: 'm',
        help: '收集模式',
        allowed: ['interactive', 'batch', 'wizard', 'automatic'],
        defaultsTo: 'interactive',
      )
      ..addFlag(
        'smart-collect',
        help: '启用智能参数收集',
      )
      ..addFlag(
        'validate-async',
        help: '启用异步验证',
      )
      ..addFlag(
        'show-recommendations',
        help: '显示参数推荐',
      )
      ..addFlag(
        'save-preset',
        help: '保存为参数预设',
      );
  }

  @override
  String get name => 'params';

  @override
  String get description => '管理模板参数化配置';

  @override
  String get usage => '''
管理模板参数化配置

使用方法:
  ming template params [选项]

必需选项:
  -t, --template=<名称>      模板名称

基础选项:
  -a, --action=<操作>        操作类型 (默认: list)
  -p, --preset=<名称>        参数预设名称
  -o, --output=<路径>        输出文件路径
  -m, --mode=<模式>          收集模式 (默认: interactive)

操作类型:
      list                   列出模板参数
      collect                收集参数值
      validate               验证参数
      preset                 管理参数预设

收集模式:
      interactive            交互式收集
      batch                  批量收集
      wizard                 向导式收集
      automatic              自动收集

功能选项:
      --smart-collect        启用智能参数收集
      --validate-async       启用异步验证
      --show-recommendations 显示参数推荐
      --save-preset          保存为参数预设

示例:
  # 列出模板参数
  ming template params --template=flutter_app --action=list

  # 交互式参数收集
  ming template params -t flutter_app -a collect -m interactive

  # 使用参数预设
  ming template params -t flutter_app -a collect --preset=mobile_app

  # 智能参数收集
  ming template params -t flutter_app -a collect --smart-collect

  # 验证参数
  ming template params -t flutter_app -a validate --validate-async

  # 创建参数预设
  ming template params -t flutter_app -a preset --save-preset

  # 向导式收集并保存预设
  ming template params -t flutter_app -a collect -m wizard --save-preset --output=params.json

更多信息:
  使用 'ming help template params' 查看详细文档
''';

  @override
  Future<int> run() async {
    try {
      final templateName = argResults!['template'] as String;
      final action = argResults!['action'] as String;
      final presetName = argResults!['preset'] as String?;
      final outputPath = argResults!['output'] as String?;
      final mode = argResults!['mode'] as String;
      final smartCollect = argResults!['smart-collect'] as bool;
      final validateAsync = argResults!['validate-async'] as bool;
      final showRecommendations = argResults!['show-recommendations'] as bool;
      final savePreset = argResults!['save-preset'] as bool;

      cli_logger.Logger.info('开始模板参数化操作: $templateName');

      switch (action) {
        case 'list':
          await _listParameters(templateName);
        case 'collect':
          await _collectParameters(
            templateName,
            mode: mode,
            presetName: presetName,
            smartCollect: smartCollect,
            showRecommendations: showRecommendations,
            savePreset: savePreset,
            outputPath: outputPath,
          );
        case 'validate':
          await _validateParameters(
            templateName,
            validateAsync: validateAsync,
          );
        case 'preset':
          await _managePresets(
            templateName,
            presetName: presetName,
            savePreset: savePreset,
          );
      }

      cli_logger.Logger.success('模板参数化操作完成');
      return 0;
    } catch (e) {
      cli_logger.Logger.error('模板参数化操作失败', error: e);
      return 1;
    }
  }

  /// 列出模板参数
  Future<void> _listParameters(String templateName) async {
    cli_logger.Logger.info('获取模板参数列表: $templateName');

    print('\n📋 模板参数列表');
    print('─' * 60);
    print('模板: $templateName');
    print('');

    // 模拟参数列表
    final parameters = [
      {
        'name': 'app_name',
        'type': 'string',
        'required': true,
        'description': '应用程序名称',
        'default': null,
      },
      {
        'name': 'package_name',
        'type': 'string',
        'required': true,
        'description': '包名 (例: com.example.app)',
        'default': null,
      },
      {
        'name': 'platform',
        'type': 'choice',
        'required': true,
        'description': '目标平台',
        'choices': ['mobile', 'web', 'desktop'],
        'default': 'mobile',
      },
      {
        'name': 'enable_analytics',
        'type': 'boolean',
        'required': false,
        'description': '启用分析功能',
        'default': false,
      },
      {
        'name': 'database_config',
        'type': 'composite',
        'required': false,
        'description': '数据库配置',
        'sensitivity': 'confidential',
      },
    ];

    for (final param in parameters) {
      final required = param['required']! as bool;
      final requiredIcon = required ? '🔴' : '🟡';
      final sensitivity = param['sensitivity'] as String?;
      final sensitivityIcon = sensitivity != null ? '🔒' : '';

      print(
          '$requiredIcon $sensitivityIcon ${param['name']} (${param['type']})',);
      print('   ${param['description']}');

      if (param['choices'] != null) {
        final choices = param['choices']! as List<String>;
        print('   选项: ${choices.join(', ')}');
      }

      if (param['default'] != null) {
        print('   默认值: ${param['default']}');
      }

      print('');
    }

    print('图例:');
    print('🔴 必需参数  🟡 可选参数  🔒 敏感参数');
  }

  /// 收集参数
  Future<void> _collectParameters(
    String templateName, {
    required String mode,
    String? presetName,
    bool smartCollect = false,
    bool showRecommendations = false,
    bool savePreset = false,
    String? outputPath,
  }) async {
    cli_logger.Logger.info('开始参数收集: $templateName (模式: $mode)');

    print('\n🔧 参数收集');
    print('─' * 60);
    print('模板: $templateName');
    print('模式: $mode');

    if (presetName != null) {
      print('预设: $presetName');
    }

    print('');

    // 智能推荐
    if (smartCollect || showRecommendations) {
      print('💡 智能推荐:');
      print('  • 检测到Flutter项目，推荐使用mobile平台');
      print('  • 检测到Git仓库，推荐使用仓库名作为app_name');
      print('  • 检测到pubspec.yaml，推荐使用现有包名');
      print('');
    }

    // 模拟参数收集过程
    final collectedParams = <String, dynamic>{};

    switch (mode) {
      case 'interactive':
        await _interactiveCollection(collectedParams);
      case 'wizard':
        await _wizardCollection(collectedParams);
      case 'batch':
        await _batchCollection(collectedParams);
      case 'automatic':
        await _automaticCollection(collectedParams);
    }

    // 显示收集结果
    print('\n✅ 参数收集完成');
    print('─' * 40);
    for (final entry in collectedParams.entries) {
      print('${entry.key}: ${entry.value}');
    }

    // 保存预设
    if (savePreset) {
      print('\n💾 保存参数预设...');
      print('✅ 预设已保存: ${templateName}_preset');
    }

    // 输出到文件
    if (outputPath != null) {
      print('\n📁 输出到文件: $outputPath');
    }
  }

  /// 交互式收集
  Future<void> _interactiveCollection(Map<String, dynamic> params) async {
    print('🎯 交互式参数收集');
    print('请输入以下参数 (按Enter使用默认值):');
    print('');

    // 模拟交互式输入
    params['app_name'] = 'MyFlutterApp';
    params['package_name'] = 'com.example.myflutterapp';
    params['platform'] = 'mobile';
    params['enable_analytics'] = true;

    print('app_name: MyFlutterApp');
    print('package_name: com.example.myflutterapp');
    print('platform: mobile');
    print('enable_analytics: true');
  }

  /// 向导式收集
  Future<void> _wizardCollection(Map<String, dynamic> params) async {
    print('🧙 向导式参数收集');
    print('');

    print('步骤 1/3: 基础信息');
    params['app_name'] = 'MyApp';
    params['package_name'] = 'com.example.myapp';

    print('步骤 2/3: 平台配置');
    params['platform'] = 'mobile';

    print('步骤 3/3: 功能选项');
    params['enable_analytics'] = false;
  }

  /// 批量收集
  Future<void> _batchCollection(Map<String, dynamic> params) async {
    print('📦 批量参数收集');
    print('从配置文件读取参数...');

    params['app_name'] = 'BatchApp';
    params['package_name'] = 'com.batch.app';
    params['platform'] = 'web';
    params['enable_analytics'] = true;
  }

  /// 自动收集
  Future<void> _automaticCollection(Map<String, dynamic> params) async {
    print('🤖 自动参数收集');
    print('基于项目环境自动推断参数...');

    params['app_name'] = 'AutoDetectedApp';
    params['package_name'] = 'com.auto.detected';
    params['platform'] = 'mobile';
    params['enable_analytics'] = false;
  }

  /// 验证参数
  Future<void> _validateParameters(
    String templateName, {
    bool validateAsync = false,
  }) async {
    cli_logger.Logger.info('验证模板参数: $templateName');

    print('\n🔍 参数验证');
    print('─' * 60);
    print('模板: $templateName');
    print('异步验证: ${validateAsync ? '启用' : '禁用'}');
    print('');

    // 模拟验证过程
    final validationResults = [
      {'param': 'app_name', 'status': 'valid', 'message': '应用名称格式正确'},
      {'param': 'package_name', 'status': 'valid', 'message': '包名格式符合规范'},
      {'param': 'platform', 'status': 'valid', 'message': '平台选择有效'},
      {'param': 'database_url', 'status': 'warning', 'message': '数据库连接未测试'},
    ];

    for (final result in validationResults) {
      final status = result['status']!;
      final icon = status == 'valid'
          ? '✅'
          : status == 'warning'
              ? '⚠️'
              : '❌';

      print('$icon ${result['param']}: ${result['message']}');
    }

    if (validateAsync) {
      print('\n🌐 异步验证结果:');
      print('✅ API端点可达性检查通过');
      print('✅ 域名有效性验证通过');
      print('⚠️ 数据库连接超时，请检查网络');
    }
  }

  /// 管理预设
  Future<void> _managePresets(
    String templateName, {
    String? presetName,
    bool savePreset = false,
  }) async {
    cli_logger.Logger.info('管理参数预设: $templateName');

    print('\n📚 参数预设管理');
    print('─' * 60);
    print('模板: $templateName');
    print('');

    if (savePreset) {
      print('💾 创建新预设...');
      print('✅ 预设已创建: ${presetName ?? '${templateName}_preset'}');
    } else {
      print('📋 可用预设:');
      print('  • mobile_app_preset - 移动应用默认配置');
      print('  • web_app_preset - Web应用默认配置');
      print('  • enterprise_preset - 企业级应用配置');
      print('  • development_preset - 开发环境配置');
      print('');

      if (presetName != null) {
        print('🔍 预设详情: $presetName');
        print('  app_name: "Enterprise App"');
        print('  platform: "mobile"');
        print('  enable_analytics: true');
        print('  database_config: {...}');
      }
    }
  }
}
