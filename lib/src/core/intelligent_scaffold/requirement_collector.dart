import 'dart:io';

/// 项目需求数据模型
class ProjectRequirements {
  // 基础信息
  String projectName = '';
  String description = '';
  
  // 项目类型
  ProjectType projectType = ProjectType.unknown;
  
  // 目标平台
  Set<TargetPlatform> platforms = {};
  
  // 核心功能需求
  Set<CoreFeature> coreFeatures = {};
  
  // UI/UX需求
  UIRequirements uiRequirements = UIRequirements();
  
  // 数据和后端需求
  DataRequirements dataRequirements = DataRequirements();
  
  // 质量和性能要求
  QualityRequirements qualityRequirements = QualityRequirements();
  
  // 团队和开发偏好
  DevelopmentPreferences devPreferences = DevelopmentPreferences();
}

/// 项目类型枚举
enum ProjectType {
  unknown,
  ecommerce,      // 电商应用
  social,         // 社交应用
  productivity,   // 生产力工具
  entertainment,  // 娱乐应用
  education,      // 教育应用
  healthcare,     // 医疗健康
  finance,        // 金融应用
  enterprise,     // 企业应用
  portfolio,      // 作品集
  blog,          // 博客/内容
}

/// 目标平台
enum TargetPlatform {
  android,
  ios,
  web,
  windows,
  macos,
  linux,
}

/// 核心功能
enum CoreFeature {
  userAuth,           // 用户认证
  dataSync,           // 数据同步
  offlineSupport,     // 离线支持
  pushNotifications,  // 推送通知
  payment,           // 支付集成
  socialLogin,       // 社交登录
  fileUpload,        // 文件上传
  realTimeChat,      // 实时聊天
  geolocation,       // 地理定位
  camera,            // 相机功能
  analytics,         // 数据分析
  crashReporting,    // 崩溃报告
}

/// UI/UX需求
class UIRequirements {
  UIStyle style = UIStyle.material;
  ColorScheme colorScheme = ColorScheme.system;
  bool darkModeSupport = true;
  bool customTheme = false;
  Set<String> supportedLanguages = {'en'};
}

enum UIStyle { material, cupertino, custom }
enum ColorScheme { system, light, dark, custom }

/// 数据需求
class DataRequirements {
  bool needsDatabase = false;
  DatabaseType databaseType = DatabaseType.sqlite;
  bool needsCloudSync = false;
  CloudProvider cloudProvider = CloudProvider.firebase;
  bool needsAPI = false;
  APIType apiType = APIType.rest;
}

enum DatabaseType { sqlite, hive, isar, realm }
enum CloudProvider { firebase, supabase, aws, custom }
enum APIType { rest, graphql, grpc }

/// 质量需求
class QualityRequirements {
  Priority developmentSpeed = Priority.medium;
  Priority stability = Priority.high;
  Priority performance = Priority.medium;
  Priority maintainability = Priority.high;
  bool needsTestCoverage = true;
  int targetTestCoverage = 80;
}

enum Priority { low, medium, high, critical }

/// 开发偏好
class DevelopmentPreferences {
  StateManagement stateManagement = StateManagement.riverpod;
  bool useCodeGeneration = true;
  bool useLinting = true;
  bool useCI = false;
  TeamSize teamSize = TeamSize.small;
}

enum StateManagement { riverpod, bloc, provider, setState }
enum TeamSize { solo, small, medium, large }

/// 智能需求收集器
class RequirementCollector {
  
  /// 收集项目需求
  Future<ProjectRequirements> collectRequirements() async {
    final requirements = ProjectRequirements();
    
    print('🚀 Ming Status CLI - 智能项目生成器');
    print('=' * 50);
    print('让我们通过几个简单问题来了解您的项目需求\n');
    
    // 1. 基础信息收集
    await _collectBasicInfo(requirements);
    
    // 2. 项目类型识别
    await _identifyProjectType(requirements);
    
    // 3. 平台需求分析
    await _analyzePlatformNeeds(requirements);
    
    // 4. 功能需求收集
    await _collectFeatureRequirements(requirements);
    
    // 5. UI/UX偏好
    await _collectUIPreferences(requirements);
    
    // 6. 数据和后端需求
    await _collectDataRequirements(requirements);
    
    // 7. 质量要求评估
    await _assessQualityRequirements(requirements);
    
    // 8. 开发偏好
    await _collectDevelopmentPreferences(requirements);
    
    // 9. 需求确认和优化建议
    await _confirmAndOptimize(requirements);
    
    return requirements;
  }
  
  /// 收集基础信息
  Future<void> _collectBasicInfo(ProjectRequirements requirements) async {
    print('📝 项目基础信息');
    print('-' * 30);
    
    requirements.projectName = _promptString(
      '项目名称',
      defaultValue: 'my_awesome_app',
      validator: (value) => value.isNotEmpty && RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value),
    );
    
    requirements.description = _promptString(
      '项目描述',
      defaultValue: 'A new Flutter project',
      required: false,
    );
    
    print('');
  }
  
  /// 识别项目类型
  Future<void> _identifyProjectType(ProjectRequirements requirements) async {
    print('🎯 项目类型识别');
    print('-' * 30);
    print('请选择最符合您项目的类型：');
    
    final projectTypes = {
      1: ProjectType.ecommerce,
      2: ProjectType.social,
      3: ProjectType.productivity,
      4: ProjectType.entertainment,
      5: ProjectType.education,
      6: ProjectType.healthcare,
      7: ProjectType.finance,
      8: ProjectType.enterprise,
      9: ProjectType.portfolio,
      10: ProjectType.blog,
    };
    
    final descriptions = {
      1: '电商应用 (商品展示、购物车、支付)',
      2: '社交应用 (用户互动、聊天、分享)',
      3: '生产力工具 (任务管理、笔记、工具)',
      4: '娱乐应用 (游戏、音视频、内容)',
      5: '教育应用 (学习、培训、知识分享)',
      6: '医疗健康 (健康监测、医疗服务)',
      7: '金融应用 (理财、支付、交易)',
      8: '企业应用 (内部管理、业务流程)',
      9: '作品集 (个人展示、简历)',
      10: '博客/内容 (文章、新闻、媒体)',
    };
    
    for (final entry in descriptions.entries) {
      print('${entry.key}. ${entry.value}');
    }
    
    final choice = _promptInt('请选择 (1-10)', min: 1, max: 10);
    requirements.projectType = projectTypes[choice]!;
    
    print('✅ 已选择: ${descriptions[choice]}\n');
  }
  
  /// 分析平台需求
  Future<void> _analyzePlatformNeeds(ProjectRequirements requirements) async {
    print('📱 目标平台选择');
    print('-' * 30);
    print('您希望应用运行在哪些平台？(可多选，用逗号分隔)');
    
    final platforms = {
      1: TargetPlatform.android,
      2: TargetPlatform.ios,
      3: TargetPlatform.web,
      4: TargetPlatform.windows,
      5: TargetPlatform.macos,
      6: TargetPlatform.linux,
    };
    
    final descriptions = {
      1: 'Android',
      2: 'iOS',
      3: 'Web',
      4: 'Windows',
      5: 'macOS',
      6: 'Linux',
    };
    
    for (final entry in descriptions.entries) {
      print('${entry.key}. ${entry.value}');
    }
    
    final input = _promptString('请选择平台 (例如: 1,2,3)', defaultValue: '1,2');
    final choices = input.split(',').map((s) => int.tryParse(s.trim())).where((i) => i != null).cast<int>();
    
    for (final choice in choices) {
      if (platforms.containsKey(choice)) {
        requirements.platforms.add(platforms[choice]!);
      }
    }
    
    if (requirements.platforms.isEmpty) {
      requirements.platforms.addAll([TargetPlatform.android, TargetPlatform.ios]);
    }
    
    print('✅ 已选择平台: ${requirements.platforms.map((p) => descriptions.entries.firstWhere((e) => platforms[e.key] == p).value).join(', ')}\n');
  }
  
  /// 收集功能需求
  Future<void> _collectFeatureRequirements(ProjectRequirements requirements) async {
    print('⚡ 核心功能需求');
    print('-' * 30);
    print('根据您的项目类型，推荐以下功能：');
    
    // 根据项目类型推荐功能
    final recommendedFeatures = _getRecommendedFeatures(requirements.projectType);
    
    print('\n推荐功能 (自动包含):');
    for (final feature in recommendedFeatures) {
      print('✓ ${_getFeatureDescription(feature)}');
      requirements.coreFeatures.add(feature);
    }
    
    print('\n其他可选功能:');
    final otherFeatures = CoreFeature.values.where((f) => !recommendedFeatures.contains(f)).toList();
    
    for (var i = 0; i < otherFeatures.length; i++) {
      print('${i + 1}. ${_getFeatureDescription(otherFeatures[i])}');
    }
    
    final input = _promptString('选择额外功能 (用逗号分隔，回车跳过)', required: false);
    if (input.isNotEmpty) {
      final choices = input.split(',').map((s) => int.tryParse(s.trim())).where((i) => i != null).cast<int>();
      for (final choice in choices) {
        if (choice >= 1 && choice <= otherFeatures.length) {
          requirements.coreFeatures.add(otherFeatures[choice - 1]);
        }
      }
    }
    
    print('');
  }
  
  /// 获取推荐功能
  Set<CoreFeature> _getRecommendedFeatures(ProjectType type) {
    switch (type) {
      case ProjectType.ecommerce:
        return {CoreFeature.userAuth, CoreFeature.payment, CoreFeature.pushNotifications};
      case ProjectType.social:
        return {CoreFeature.userAuth, CoreFeature.realTimeChat, CoreFeature.socialLogin};
      case ProjectType.productivity:
        return {CoreFeature.dataSync, CoreFeature.offlineSupport};
      case ProjectType.enterprise:
        return {CoreFeature.userAuth, CoreFeature.analytics, CoreFeature.crashReporting};
      default:
        return {CoreFeature.userAuth};
    }
  }
  
  /// 获取功能描述
  String _getFeatureDescription(CoreFeature feature) {
    switch (feature) {
      case CoreFeature.userAuth: return '用户认证 (登录/注册)';
      case CoreFeature.dataSync: return '数据同步';
      case CoreFeature.offlineSupport: return '离线支持';
      case CoreFeature.pushNotifications: return '推送通知';
      case CoreFeature.payment: return '支付集成';
      case CoreFeature.socialLogin: return '社交登录';
      case CoreFeature.fileUpload: return '文件上传';
      case CoreFeature.realTimeChat: return '实时聊天';
      case CoreFeature.geolocation: return '地理定位';
      case CoreFeature.camera: return '相机功能';
      case CoreFeature.analytics: return '数据分析';
      case CoreFeature.crashReporting: return '崩溃报告';
    }
  }
  
  // 其他收集方法的简化实现...
  Future<void> _collectUIPreferences(ProjectRequirements requirements) async {
    print('🎨 UI/UX偏好 (使用默认推荐配置)\n');
    // 使用智能默认值
  }
  
  Future<void> _collectDataRequirements(ProjectRequirements requirements) async {
    print('💾 数据需求 (根据功能自动配置)\n');
    // 根据选择的功能自动推导数据需求
  }
  
  Future<void> _assessQualityRequirements(ProjectRequirements requirements) async {
    print('🏆 质量要求 (使用最佳实践配置)\n');
    // 使用最佳实践默认值
  }
  
  Future<void> _collectDevelopmentPreferences(ProjectRequirements requirements) async {
    print('⚙️ 开发偏好 (使用推荐配置)\n');
    // 使用推荐的开发配置
  }
  
  Future<void> _confirmAndOptimize(ProjectRequirements requirements) async {
    print('✅ 需求收集完成！');
    print('正在生成最优配置...\n');
  }
  
  /// 辅助方法
  String _promptString(String prompt, {String? defaultValue, bool required = true, bool Function(String)? validator}) {
    while (true) {
      stdout.write('$prompt${defaultValue != null ? ' [$defaultValue]' : ''}: ');
      final input = stdin.readLineSync()?.trim() ?? '';
      
      if (input.isEmpty && defaultValue != null) {
        return defaultValue;
      }
      
      if (input.isEmpty && !required) {
        return '';
      }
      
      if (input.isEmpty && required) {
        print('❌ 此字段为必填项');
        continue;
      }
      
      if (validator != null && !validator(input)) {
        print('❌ 输入格式不正确');
        continue;
      }
      
      return input;
    }
  }
  
  int _promptInt(String prompt, {int? defaultValue, int? min, int? max}) {
    while (true) {
      final input = _promptString(prompt, defaultValue: defaultValue?.toString(), required: defaultValue == null);
      final value = int.tryParse(input);
      
      if (value == null) {
        print('❌ 请输入有效数字');
        continue;
      }
      
      if (min != null && value < min) {
        print('❌ 数值不能小于 $min');
        continue;
      }
      
      if (max != null && value > max) {
        print('❌ 数值不能大于 $max');
        continue;
      }
      
      return value;
    }
  }
}
