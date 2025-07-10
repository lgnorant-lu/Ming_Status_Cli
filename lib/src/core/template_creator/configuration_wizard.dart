/*
---------------------------------------------------------------
File name:          configuration_wizard.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级配置向导 (Enterprise Configuration Wizard)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 交互式模板配置向导;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/template_creator/template_scaffold.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 向导步骤
/// 
/// 定义配置向导的步骤
enum WizardStep {
  /// 基础信息
  basicInfo,
  
  /// 模板类型选择
  templateType,
  
  /// 技术栈配置
  techStack,
  
  /// 高级选项
  advancedOptions,
  
  /// 确认配置
  confirmation,
}

/// 向导上下文
/// 
/// 保存向导过程中的状态信息
class WizardContext {
  /// 创建向导上下文实例
  WizardContext() : _answers = {};

  /// 用户答案映射
  final Map<String, dynamic> _answers;

  /// 设置答案
  void setAnswer(String key, dynamic value) {
    _answers[key] = value;
  }

  /// 获取答案
  T? getAnswer<T>(String key) {
    return _answers[key] as T?;
  }

  /// 获取所有答案
  Map<String, dynamic> get answers => Map.unmodifiable(_answers);

  /// 清空答案
  void clear() {
    _answers.clear();
  }
}

/// 向导问题
/// 
/// 表示向导中的一个问题
class WizardQuestion {
  /// 创建向导问题实例
  const WizardQuestion({
    required this.key,
    required this.prompt,
    required this.type,
    this.options = const [],
    this.defaultValue,
    this.validator,
    this.condition,
  });

  /// 问题键
  final String key;
  
  /// 问题提示
  final String prompt;
  
  /// 问题类型
  final QuestionType type;
  
  /// 选项列表 (用于选择题)
  final List<String> options;
  
  /// 默认值
  final dynamic defaultValue;
  
  /// 验证器
  final String? Function(String?)? validator;
  
  /// 显示条件
  final bool Function(WizardContext)? condition;
}

/// 问题类型
/// 
/// 定义不同类型的问题
enum QuestionType {
  /// 文本输入
  text,
  
  /// 数字输入
  number,
  
  /// 布尔选择
  boolean,
  
  /// 单选
  choice,
  
  /// 多选
  multiChoice,
  
  /// 列表输入
  list,
}

/// 企业级配置向导
/// 
/// 交互式模板配置向导，智能推荐和验证
class ConfigurationWizard {
  /// 创建配置向导实例
  ConfigurationWizard();

  /// 向导上下文
  final WizardContext _context = WizardContext();

  /// 运行配置向导
  /// 
  /// 引导用户完成模板配置
  Future<ScaffoldConfig?> runWizard() async {
    try {
      cli_logger.Logger.info('启动模板配置向导');
      
      _printWelcome();
      
      // 执行向导步骤
      for (final step in WizardStep.values) {
        final shouldContinue = await _executeStep(step);
        if (!shouldContinue) {
          cli_logger.Logger.info('用户取消了配置向导');
          return null;
        }
      }
      
      // 生成配置
      final config = _generateConfig();
      
      cli_logger.Logger.success('模板配置完成');
      return config;
    } catch (e) {
      cli_logger.Logger.error('配置向导执行失败', error: e);
      return null;
    }
  }

  /// 执行向导步骤
  Future<bool> _executeStep(WizardStep step) async {
    switch (step) {
      case WizardStep.basicInfo:
        return _collectBasicInfo();
      case WizardStep.templateType:
        return _selectTemplateType();
      case WizardStep.techStack:
        return _configureTechStack();
      case WizardStep.advancedOptions:
        return _configureAdvancedOptions();
      case WizardStep.confirmation:
        return _confirmConfiguration();
    }
  }

  /// 收集基础信息
  Future<bool> _collectBasicInfo() async {
    _printStepHeader('基础信息配置');
    
    final questions = [
      WizardQuestion(
        key: 'templateName',
        prompt: '请输入模板名称',
        type: QuestionType.text,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '模板名称不能为空';
          }
          if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(value)) {
            return '模板名称只能包含字母、数字、下划线和连字符，且必须以字母开头';
          }
          return null;
        },
      ),
      WizardQuestion(
        key: 'author',
        prompt: '请输入作者名称',
        type: QuestionType.text,
        defaultValue: _getDefaultAuthor(),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '作者名称不能为空';
          }
          return null;
        },
      ),
      WizardQuestion(
        key: 'description',
        prompt: '请输入模板描述',
        type: QuestionType.text,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '模板描述不能为空';
          }
          return null;
        },
      ),
      WizardQuestion(
        key: 'version',
        prompt: '请输入模板版本',
        type: QuestionType.text,
        defaultValue: '1.0.0',
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '版本号不能为空';
          }
          if (!RegExp(r'^\d+\.\d+\.\d+').hasMatch(value)) {
            return '版本号格式不正确，应为 x.y.z 格式';
          }
          return null;
        },
      ),
    ];

    for (final question in questions) {
      final answer = await _askQuestion(question);
      if (answer == null) return false;
      _context.setAnswer(question.key, answer);
    }

    return true;
  }

  /// 选择模板类型
  Future<bool> _selectTemplateType() async {
    _printStepHeader('模板类型选择');
    
    // 主类型选择
    final typeQuestion = WizardQuestion(
      key: 'templateType',
      prompt: '请选择模板类型',
      type: QuestionType.choice,
      options: TemplateType.values.map((t) => '${t.name} - ${t.displayName}').toList(),
    );
    
    final typeAnswer = await _askQuestion(typeQuestion);
    if (typeAnswer == null) return false;
    
    final selectedType = TemplateType.values[int.parse(typeAnswer) - 1];
    _context.setAnswer('templateType', selectedType);
    
    // 子类型选择
    final supportedSubTypes = selectedType.supportedSubTypes;
    if (supportedSubTypes.isNotEmpty) {
      final subTypeQuestion = WizardQuestion(
        key: 'subType',
        prompt: '请选择子类型 (可选)',
        type: QuestionType.choice,
        options: [
          '跳过',
          ...supportedSubTypes.map((st) => '${st.name} - ${st.displayName}'),
        ],
      );
      
      final subTypeAnswer = await _askQuestion(subTypeQuestion);
      if (subTypeAnswer == null) return false;
      
      if (subTypeAnswer != '1') {
        final selectedSubType = supportedSubTypes[int.parse(subTypeAnswer) - 2];
        _context.setAnswer('subType', selectedSubType);
      }
    }

    return true;
  }

  /// 配置技术栈
  Future<bool> _configureTechStack() async {
    _printStepHeader('技术栈配置');
    
    final questions = [
      WizardQuestion(
        key: 'platform',
        prompt: '请选择目标平台',
        type: QuestionType.choice,
        options: TemplatePlatform.values.map((p) => p.name).toList(),
      ),
      WizardQuestion(
        key: 'framework',
        prompt: '请选择技术框架',
        type: QuestionType.choice,
        options: TemplateFramework.values.map((f) => f.name).toList(),
      ),
      WizardQuestion(
        key: 'complexity',
        prompt: '请选择复杂度等级',
        type: QuestionType.choice,
        options: TemplateComplexity.values.map((c) => c.name).toList(),
      ),
    ];

    for (final question in questions) {
      final answer = await _askQuestion(question);
      if (answer == null) return false;
      
      switch (question.key) {
        case 'platform':
          _context.setAnswer(question.key, TemplatePlatform.values[int.parse(answer) - 1]);
        case 'framework':
          _context.setAnswer(question.key, TemplateFramework.values[int.parse(answer) - 1]);
        case 'complexity':
          _context.setAnswer(question.key, TemplateComplexity.values[int.parse(answer) - 1]);
      }
    }

    return true;
  }

  /// 配置高级选项
  Future<bool> _configureAdvancedOptions() async {
    _printStepHeader('高级选项配置');
    
    final questions = [
      const WizardQuestion(
        key: 'includeTests',
        prompt: '是否包含测试文件？',
        type: QuestionType.boolean,
        defaultValue: true,
      ),
      const WizardQuestion(
        key: 'includeDocumentation',
        prompt: '是否包含文档？',
        type: QuestionType.boolean,
        defaultValue: true,
      ),
      const WizardQuestion(
        key: 'includeExamples',
        prompt: '是否包含示例代码？',
        type: QuestionType.boolean,
        defaultValue: true,
      ),
      const WizardQuestion(
        key: 'enableGitInit',
        prompt: '是否初始化Git仓库？',
        type: QuestionType.boolean,
        defaultValue: true,
      ),
      const WizardQuestion(
        key: 'tags',
        prompt: '请输入标签 (用逗号分隔，可选)',
        type: QuestionType.list,
      ),
    ];

    for (final question in questions) {
      final answer = await _askQuestion(question);
      if (answer == null) return false;
      _context.setAnswer(question.key, answer);
    }

    return true;
  }

  /// 确认配置
  Future<bool> _confirmConfiguration() async {
    _printStepHeader('配置确认');
    
    _printConfigurationSummary();
    
    const confirmQuestion = WizardQuestion(
      key: 'confirm',
      prompt: '确认以上配置并生成模板？',
      type: QuestionType.boolean,
      defaultValue: true,
    );
    
    final answer = await _askQuestion(confirmQuestion);
    return answer == true;
  }

  /// 询问问题
  Future<dynamic> _askQuestion(WizardQuestion question) async {
    while (true) {
      // 检查显示条件
      if (question.condition != null && !question.condition!(_context)) {
        return question.defaultValue;
      }

      _printQuestion(question);
      
      final input = stdin.readLineSync()?.trim();
      
      // 处理取消
      if (input?.toLowerCase() == 'q' || input?.toLowerCase() == 'quit') {
        return null;
      }
      
      // 处理默认值
      if ((input == null || input.isEmpty) && question.defaultValue != null) {
        return question.defaultValue;
      }
      
      // 验证输入
      final validationResult = _validateInput(input, question);
      if (validationResult != null) {
        print('❌ $validationResult');
        continue;
      }
      
      // 转换输入
      return _convertInput(input, question);
    }
  }

  /// 验证输入
  String? _validateInput(String? input, WizardQuestion question) {
    if (question.validator != null) {
      return question.validator!(input);
    }
    
    switch (question.type) {
      case QuestionType.number:
        if (input != null && num.tryParse(input) == null) {
          return '请输入有效的数字';
        }
      case QuestionType.choice:
        if (input != null) {
          final choice = int.tryParse(input);
          if (choice == null || choice < 1 || choice > question.options.length) {
            return '请输入有效的选项编号 (1-${question.options.length})';
          }
        }
      case QuestionType.boolean:
        if (input != null && !['y', 'n', 'yes', 'no', 'true', 'false'].contains(input.toLowerCase())) {
          return '请输入 y/n 或 yes/no';
        }
      default:
        break;
    }
    
    return null;
  }

  /// 转换输入
  dynamic _convertInput(String? input, WizardQuestion question) {
    if (input == null || input.isEmpty) {
      return question.defaultValue;
    }
    
    switch (question.type) {
      case QuestionType.number:
        return num.parse(input);
      case QuestionType.boolean:
        return ['y', 'yes', 'true'].contains(input.toLowerCase());
      case QuestionType.choice:
        return input;
      case QuestionType.list:
        return input.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      default:
        return input;
    }
  }

  /// 生成配置
  ScaffoldConfig _generateConfig() {
    return ScaffoldConfig(
      templateName: _context.getAnswer<String>('templateName')!,
      templateType: _context.getAnswer<TemplateType>('templateType')!,
      subType: _context.getAnswer<TemplateSubType>('subType'),
      author: _context.getAnswer<String>('author')!,
      description: _context.getAnswer<String>('description')!,
      version: _context.getAnswer<String>('version') ?? '1.0.0',
      platform: _context.getAnswer<TemplatePlatform>('platform') ?? TemplatePlatform.crossPlatform,
      framework: _context.getAnswer<TemplateFramework>('framework') ?? TemplateFramework.agnostic,
      complexity: _context.getAnswer<TemplateComplexity>('complexity') ?? TemplateComplexity.simple,
      includeTests: _context.getAnswer<bool>('includeTests') ?? true,
      includeDocumentation: _context.getAnswer<bool>('includeDocumentation') ?? true,
      includeExamples: _context.getAnswer<bool>('includeExamples') ?? true,
      enableGitInit: _context.getAnswer<bool>('enableGitInit') ?? true,
      tags: _context.getAnswer<List<String>>('tags') ?? [],
    );
  }

  /// 打印欢迎信息
  void _printWelcome() {
    print('\n🎯 Ming Status CLI - 模板创建向导');
    print('═' * 50);
    print('欢迎使用企业级模板创建向导！');
    print('我们将引导您创建一个自定义模板。');
    print('提示：输入 q 或 quit 可随时退出向导。');
    print('═' * 50);
  }

  /// 打印步骤标题
  void _printStepHeader(String title) {
    print('\n📋 $title');
    print('─' * 30);
  }

  /// 打印问题
  void _printQuestion(WizardQuestion question) {
    print('\n❓ ${question.prompt}');
    
    if (question.type == QuestionType.choice) {
      for (var i = 0; i < question.options.length; i++) {
        print('  ${i + 1}. ${question.options[i]}');
      }
    }
    
    if (question.defaultValue != null) {
      print('   (默认: ${question.defaultValue})');
    }
    
    stdout.write('> ');
  }

  /// 打印配置摘要
  void _printConfigurationSummary() {
    print('\n📊 配置摘要');
    print('─' * 30);
    print('模板名称: ${_context.getAnswer('templateName')}');
    print('作者: ${_context.getAnswer('author')}');
    print('描述: ${_context.getAnswer('description')}');
    print('版本: ${_context.getAnswer('version')}');
    print('类型: ${_context.getAnswer<TemplateType>('templateType')?.displayName}');
    final subType = _context.getAnswer<TemplateSubType>('subType');
    if (subType != null) {
      print('子类型: ${subType.displayName}');
    }
    print('平台: ${_context.getAnswer<TemplatePlatform>('platform')?.name}');
    print('框架: ${_context.getAnswer<TemplateFramework>('framework')?.name}');
    print('复杂度: ${_context.getAnswer<TemplateComplexity>('complexity')?.name}');
    print('包含测试: ${_context.getAnswer('includeTests') ? '是' : '否'}');
    print('包含文档: ${_context.getAnswer('includeDocumentation') ? '是' : '否'}');
    print('包含示例: ${_context.getAnswer('includeExamples') ? '是' : '否'}');
    print('Git初始化: ${_context.getAnswer('enableGitInit') ? '是' : '否'}');
    final tags = _context.getAnswer<List<String>>('tags');
    if (tags != null && tags.isNotEmpty) {
      print('标签: ${tags.join(', ')}');
    }
    print('─' * 30);
  }

  /// 获取默认作者
  String _getDefaultAuthor() {
    // 尝试从Git配置获取用户名
    try {
      final result = Process.runSync('git', ['config', 'user.name']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      // 忽略错误
    }
    
    // 尝试从环境变量获取
    return Platform.environment['USER'] ?? 
           Platform.environment['USERNAME'] ?? 
           'Unknown Author';
  }
}
