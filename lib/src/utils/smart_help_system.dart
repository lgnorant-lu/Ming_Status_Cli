/*
---------------------------------------------------------------
File name:          smart_help_system.dart
Author:             lgnorant-lu
Date created:       2025-07-08
Last modified:      2025-07-08
Dart Version:       3.2+
Description:        Task 50.1 - 智能帮助系统
                    提供上下文相关的帮助和建议
---------------------------------------------------------------
Change History:
    2025-07-08: Initial creation - 智能帮助系统;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/utils/logger.dart';

/// 帮助上下文
enum HelpContext {
  general,
  command,
  error,
  workflow,
  configuration,
  troubleshooting,
}

/// 用户技能级别
enum UserSkillLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

/// 帮助内容类型
enum HelpContentType {
  quickStart,
  tutorial,
  reference,
  troubleshooting,
  bestPractices,
  examples,
}

/// 智能帮助项
class SmartHelpItem {
  const SmartHelpItem({
    required this.title,
    required this.content,
    required this.type,
    required this.skillLevel,
    this.tags = const [],
    this.relatedCommands = const [],
    this.examples = const [],
    this.links = const [],
  });

  final String title;
  final String content;
  final HelpContentType type;
  final UserSkillLevel skillLevel;
  final List<String> tags;
  final List<String> relatedCommands;
  final List<String> examples;
  final List<String> links;
}

/// 智能帮助系统
class SmartHelpSystem {
  static UserSkillLevel _userSkillLevel = UserSkillLevel.intermediate;
  static final Map<String, int> _commandUsageCount = {};
  static final List<String> _recentErrors = [];
  static final Map<String, List<SmartHelpItem>> _helpDatabase = {};

  /// 初始化帮助系统
  static void initialize() {
    _buildHelpDatabase();
  }

  /// 设置用户技能级别
  static void setUserSkillLevel(UserSkillLevel level) {
    _userSkillLevel = level;
  }

  /// 记录命令使用
  static void recordCommandUsage(String command) {
    _commandUsageCount[command] = (_commandUsageCount[command] ?? 0) + 1;
  }

  /// 记录错误
  static void recordError(String error) {
    _recentErrors.add(error);
    if (_recentErrors.length > 10) {
      _recentErrors.removeAt(0);
    }
  }

  /// 显示智能帮助
  static void showSmartHelp({
    HelpContext context = HelpContext.general,
    String? command,
    String? error,
  }) {
    Logger.newLine();
    Logger.info('🤖 智能帮助助手');
    Logger.newLine();

    switch (context) {
      case HelpContext.general:
        _showGeneralHelp();
      case HelpContext.command:
        _showCommandHelp(command);
      case HelpContext.error:
        _showErrorHelp(error);
      case HelpContext.workflow:
        _showWorkflowHelp();
      case HelpContext.configuration:
        _showConfigurationHelp();
      case HelpContext.troubleshooting:
        _showTroubleshootingHelp();
    }

    _showPersonalizedSuggestions();
    _showQuickActions();
  }

  /// 显示一般帮助
  static void _showGeneralHelp() {
    Logger.info('👋 欢迎使用 Ming Status CLI！');
    Logger.newLine();

    if (_userSkillLevel == UserSkillLevel.beginner) {
      Logger.info('🌟 新手指南:');
      Logger.listItem('运行 "ming init" 创建你的第一个工作空间');
      Logger.listItem('使用 "ming help <command>" 查看具体命令帮助');
      Logger.listItem('运行 "ming doctor" 检查环境配置');
      Logger.newLine();
    }

    Logger.info('🚀 常用命令:');
    final commonCommands = _getCommonCommands();
    for (final cmd in commonCommands) {
      Logger.listItem(cmd);
    }
  }

  /// 显示命令帮助
  static void _showCommandHelp(String? command) {
    if (command == null) {
      _showGeneralHelp();
      return;
    }

    final helpItems = _helpDatabase[command] ?? [];
    if (helpItems.isEmpty) {
      Logger.warning('未找到命令 "$command" 的帮助信息');
      _suggestSimilarCommands(command);
      return;
    }

    Logger.info('📖 命令 "$command" 帮助:');
    Logger.newLine();

    for (final item in helpItems) {
      if (_isRelevantForUser(item)) {
        _displayHelpItem(item);
      }
    }
  }

  /// 显示错误帮助
  static void _showErrorHelp(String? error) {
    if (error == null) return;

    Logger.info('🔍 错误分析和解决方案:');
    Logger.newLine();

    // 分析错误类型
    final errorType = _analyzeErrorType(error);
    final solutions = _getSolutionsForError(errorType, error);

    Logger.info('错误类型: $errorType');
    Logger.newLine();

    Logger.info('💡 建议解决方案:');
    for (var i = 0; i < solutions.length; i++) {
      Logger.listItem('${i + 1}. ${solutions[i]}');
    }

    // 显示相关的帮助内容
    final relatedHelp = _getRelatedHelpForError(errorType);
    if (relatedHelp.isNotEmpty) {
      Logger.newLine();
      Logger.info('📚 相关帮助:');
      for (final help in relatedHelp) {
        Logger.listItem(help);
      }
    }
  }

  /// 显示工作流帮助
  static void _showWorkflowHelp() {
    Logger.info('🔄 工作流指南:');
    Logger.newLine();

    final workflows = [
      '1. 初始化项目: ming init <project-name>',
      '2. 配置环境: ming config --set user.name="Your Name"',
      '3. 创建模块: ming create <module-name> --template basic',
      '4. 验证项目: ming validate',
      '5. 构建发布: ming build --release',
    ];

    for (final workflow in workflows) {
      Logger.listItem(workflow);
    }

    Logger.newLine();
    Logger.info('💡 最佳实践:');
    Logger.listItem('定期运行 "ming doctor" 检查环境');
    Logger.listItem('使用版本控制管理你的项目');
    Logger.listItem('遵循项目命名约定');
  }

  /// 显示配置帮助
  static void _showConfigurationHelp() {
    Logger.info('⚙️ 配置管理:');
    Logger.newLine();

    Logger.info('查看配置:');
    Logger.listItem('ming config --list  # 查看所有配置');
    Logger.listItem('ming config user.name  # 查看特定配置');
    Logger.newLine();

    Logger.info('设置配置:');
    Logger.listItem('ming config --set user.name="Your Name"');
    Logger.listItem('ming config --set user.email="your@email.com"');
    Logger.newLine();

    Logger.info('重置配置:');
    Logger.listItem('ming config --reset  # 重置所有配置');
    Logger.listItem('ming config --unset user.name  # 删除特定配置');
  }

  /// 显示故障排除帮助
  static void _showTroubleshootingHelp() {
    Logger.info('🔧 故障排除指南:');
    Logger.newLine();

    final troubleshootingSteps = [
      '1. 运行 "ming doctor" 进行环境诊断',
      '2. 检查文件权限和路径',
      '3. 确认网络连接正常',
      '4. 清除缓存: ming cache --clear',
      '5. 重启终端或IDE',
      '6. 更新到最新版本',
    ];

    for (final step in troubleshootingSteps) {
      Logger.listItem(step);
    }

    Logger.newLine();
    Logger.info('🆘 获取更多帮助:');
    Logger.listItem('查看在线文档: https://ming-cli.docs.com');
    Logger.listItem('提交问题: https://github.com/ming-cli/issues');
    Logger.listItem('社区讨论: https://discord.gg/ming-cli');
  }

  /// 显示个性化建议
  static void _showPersonalizedSuggestions() {
    Logger.newLine();
    Logger.info('🎯 个性化建议:');

    // 基于使用历史的建议
    final suggestions = _generatePersonalizedSuggestions();
    for (final suggestion in suggestions) {
      Logger.listItem(suggestion);
    }
  }

  /// 显示快速操作
  static void _showQuickActions() {
    Logger.newLine();
    Logger.info('⚡ 快速操作:');

    final actions = [
      'ming doctor  # 检查环境',
      'ming version  # 查看版本',
      'ming help <command>  # 获取命令帮助',
      'ming config --list  # 查看配置',
    ];

    for (final action in actions) {
      Logger.listItem(action);
    }
  }

  /// 获取常用命令
  static List<String> _getCommonCommands() {
    return [
      'ming init <name>  # 初始化工作空间',
      'ming create <name>  # 创建模块',
      'ming config  # 管理配置',
      'ming validate  # 验证项目',
      'ming doctor  # 环境检查',
      'ming help  # 获取帮助',
    ];
  }

  /// 建议相似命令
  static void _suggestSimilarCommands(String command) {
    final allCommands = ['init', 'create', 'config', 'validate', 'doctor', 'help', 'version'];
    final similar = allCommands.where((cmd) => _calculateSimilarity(command, cmd) > 0.5).toList();

    if (similar.isNotEmpty) {
      Logger.newLine();
      Logger.info('💡 你是否想要:');
      for (final cmd in similar) {
        Logger.listItem('ming $cmd');
      }
    }
  }

  /// 计算字符串相似度
  static double _calculateSimilarity(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;

    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;

    if (longer.isEmpty) return 1;

    final editDistance = _levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  /// 计算编辑距离
  static int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  /// 分析错误类型
  static String _analyzeErrorType(String error) {
    if (error.contains('permission') || error.contains('权限')) {
      return '权限错误';
    } else if (error.contains('file') || error.contains('文件')) {
      return '文件系统错误';
    } else if (error.contains('network') || error.contains('网络')) {
      return '网络错误';
    } else if (error.contains('config') || error.contains('配置')) {
      return '配置错误';
    } else {
      return '一般错误';
    }
  }

  /// 获取错误解决方案
  static List<String> _getSolutionsForError(String errorType, String error) {
    switch (errorType) {
      case '权限错误':
        return [
          '使用管理员权限运行命令',
          '检查文件夹访问权限',
          '确认用户组设置',
        ];
      case '文件系统错误':
        return [
          '检查文件路径是否正确',
          '确认文件是否存在',
          '检查磁盘空间',
        ];
      case '网络错误':
        return [
          '检查网络连接',
          '确认代理设置',
          '尝试离线模式',
        ];
      case '配置错误':
        return [
          '运行 "ming doctor" 检查配置',
          '重置配置到默认值',
          '检查配置文件格式',
        ];
      default:
        return [
          '使用 --verbose 获取详细信息',
          '查看日志文件',
          '重启应用程序',
        ];
    }
  }

  /// 获取错误相关帮助
  static List<String> _getRelatedHelpForError(String errorType) {
    return [
      'ming help troubleshooting',
      'ming doctor --detailed',
      'ming config --list',
    ];
  }

  /// 生成个性化建议
  static List<String> _generatePersonalizedSuggestions() {
    final suggestions = <String>[];

    // 基于命令使用频率
    if (_commandUsageCount['init'] == null || _commandUsageCount['init']! < 3) {
      suggestions.add('尝试创建更多项目来熟悉工作流');
    }

    if (_commandUsageCount['doctor'] == null || _commandUsageCount['doctor']! < 2) {
      suggestions.add('定期运行 "ming doctor" 检查环境状态');
    }

    // 基于错误历史
    if (_recentErrors.isNotEmpty) {
      suggestions.add('查看故障排除指南避免常见错误');
    }

    // 基于技能级别
    if (_userSkillLevel == UserSkillLevel.beginner) {
      suggestions.add('完成新手教程掌握基础操作');
    }

    return suggestions.isNotEmpty ? suggestions : ['继续探索 Ming CLI 的强大功能！'];
  }

  /// 检查帮助项是否与用户相关
  static bool _isRelevantForUser(SmartHelpItem item) {
    // 根据用户技能级别过滤
    switch (_userSkillLevel) {
      case UserSkillLevel.beginner:
        return item.skillLevel == UserSkillLevel.beginner ||
               item.type == HelpContentType.quickStart ||
               item.type == HelpContentType.tutorial;
      case UserSkillLevel.intermediate:
        return item.skillLevel != UserSkillLevel.expert;
      case UserSkillLevel.advanced:
      case UserSkillLevel.expert:
        return true;
    }
  }

  /// 显示帮助项
  static void _displayHelpItem(SmartHelpItem item) {
    Logger.info('📝 ${item.title}');
    Logger.info('   ${item.content}');

    if (item.examples.isNotEmpty) {
      Logger.info('   示例: ${item.examples.first}');
    }

    Logger.newLine();
  }

  /// 构建帮助数据库
  static void _buildHelpDatabase() {
    // 这里可以从配置文件或数据库加载帮助内容
    // 为了演示，我们添加一些示例内容
    _helpDatabase['init'] = [
      const SmartHelpItem(
        title: '初始化工作空间',
        content: '创建一个新的 Ming 工作空间，包含基础配置和目录结构',
        type: HelpContentType.tutorial,
        skillLevel: UserSkillLevel.beginner,
        examples: ['ming init my-project'],
        relatedCommands: ['config', 'create'],
      ),
    ];

    _helpDatabase['create'] = [
      const SmartHelpItem(
        title: '创建模块',
        content: '基于模板创建新的模块或组件',
        type: HelpContentType.tutorial,
        skillLevel: UserSkillLevel.beginner,
        examples: ['ming create my-module --template basic'],
        relatedCommands: ['validate', 'init'],
      ),
    ];
  }
}
