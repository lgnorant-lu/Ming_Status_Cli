/*
---------------------------------------------------------------
File name:          feature_detector.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级功能检测器 (Enterprise Feature Detector)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 智能条件生成系统;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 技术栈特性
enum TechStackFeature {
  /// 状态管理
  stateManagement,
  
  /// 路由管理
  routing,
  
  /// 网络请求
  networking,
  
  /// 数据库
  database,
  
  /// 缓存
  caching,
  
  /// 认证授权
  authentication,
  
  /// 国际化
  internationalization,
  
  /// 主题系统
  theming,
  
  /// 测试框架
  testing,
  
  /// 构建工具
  buildTools,
  
  /// 代码生成
  codeGeneration,
  
  /// 性能监控
  performanceMonitoring,
  
  /// 错误追踪
  errorTracking,
  
  /// 日志记录
  logging,
  
  /// 安全防护
  security,
}

/// 架构模式
enum ArchitecturePattern {
  /// Model-View-ViewModel
  mvvm,
  
  /// Model-View-Controller
  mvc,
  
  /// Clean Architecture
  cleanArchitecture,
  
  /// Business Logic Component
  bloc,
  
  /// Redux
  redux,
  
  /// MobX
  mobx,
  
  /// Provider
  provider,
  
  /// Riverpod
  riverpod,
  
  /// GetX
  getx,
  
  /// 微服务架构
  microservices,
  
  /// 单体架构
  monolithic,
  
  /// 分层架构
  layered,
  
  /// 六边形架构
  hexagonal,
}

/// 第三方集成
enum ThirdPartyIntegration {
  /// Firebase
  firebase,
  
  /// AWS
  aws,
  
  /// Azure
  azure,
  
  /// Google Cloud
  googleCloud,
  
  /// Supabase
  supabase,
  
  /// MongoDB
  mongodb,
  
  /// PostgreSQL
  postgresql,
  
  /// MySQL
  mysql,
  
  /// Redis
  redis,
  
  /// Elasticsearch
  elasticsearch,
  
  /// Stripe
  stripe,
  
  /// PayPal
  paypal,
  
  /// Twilio
  twilio,
  
  /// SendGrid
  sendgrid,
  
  /// Sentry
  sentry,
  
  /// Crashlytics
  crashlytics,
  
  /// Analytics
  analytics,
  
  /// Push Notifications
  pushNotifications,
}

/// 开发工具
enum DevelopmentTool {
  /// Visual Studio Code
  vscode,
  
  /// IntelliJ IDEA
  intellij,
  
  /// Android Studio
  androidStudio,
  
  /// Xcode
  xcode,
  
  /// Git
  git,
  
  /// GitHub
  github,
  
  /// GitLab
  gitlab,
  
  /// Bitbucket
  bitbucket,
  
  /// Jenkins
  jenkins,
  
  /// GitHub Actions
  githubActions,
  
  /// GitLab CI
  gitlabCI,
  
  /// Docker
  docker,
  
  /// Kubernetes
  kubernetes,
  
  /// Terraform
  terraform,
}

/// 团队规模
enum TeamSize {
  /// 个人项目
  solo,
  
  /// 小团队 (2-5人)
  small,
  
  /// 中等团队 (6-15人)
  medium,
  
  /// 大团队 (16-50人)
  large,
  
  /// 企业级团队 (50+人)
  enterprise,
}

/// 项目复杂度
enum ProjectComplexity {
  /// 简单项目
  simple,
  
  /// 中等复杂度
  medium,
  
  /// 复杂项目
  complex,
  
  /// 企业级复杂度
  enterprise,
}

/// 功能检测结果
class FeatureDetectionResult {
  /// 创建功能检测结果实例
  const FeatureDetectionResult({
    required this.techStackFeatures,
    required this.architecturePatterns,
    required this.thirdPartyIntegrations,
    required this.developmentTools,
    required this.teamSize,
    required this.projectComplexity,
    this.confidence = 1.0,
    this.detectionTime,
    this.metadata = const {},
  });

  /// 技术栈特性
  final Set<TechStackFeature> techStackFeatures;
  
  /// 架构模式
  final Set<ArchitecturePattern> architecturePatterns;
  
  /// 第三方集成
  final Set<ThirdPartyIntegration> thirdPartyIntegrations;
  
  /// 开发工具
  final Set<DevelopmentTool> developmentTools;
  
  /// 团队规模
  final TeamSize teamSize;
  
  /// 项目复杂度
  final ProjectComplexity projectComplexity;
  
  /// 检测置信度 (0.0-1.0)
  final double confidence;
  
  /// 检测时间
  final DateTime? detectionTime;
  
  /// 额外元数据
  final Map<String, dynamic> metadata;
}

/// 企业级功能检测器
/// 
/// 检测技术栈、架构模式、第三方集成、开发工具、团队规模和复杂度
class FeatureDetector {
  /// 创建功能检测器实例
  FeatureDetector({
    this.enableCaching = true,
    this.cacheTimeout = const Duration(minutes: 10),
    this.enableDeepAnalysis = true,
  });

  /// 是否启用缓存
  final bool enableCaching;
  
  /// 缓存超时时间
  final Duration cacheTimeout;
  
  /// 是否启用深度分析
  final bool enableDeepAnalysis;

  /// 检测结果缓存
  final Map<String, FeatureDetectionResult> _cache = {};
  final Map<String, DateTime> _cacheTime = {};

  /// 检测项目功能
  /// 
  /// 分析项目的技术栈、架构模式、集成和工具
  Future<FeatureDetectionResult> detectFeatures({
    required String projectPath,
    Map<String, dynamic>? hints,
  }) async {
    try {
      cli_logger.Logger.debug('开始功能检测: $projectPath');
      
      // 生成缓存键
      final cacheKey = _generateCacheKey(projectPath, hints);
      
      // 检查缓存
      if (enableCaching && _isCacheValid(cacheKey)) {
        cli_logger.Logger.debug('使用缓存的功能检测结果');
        return _cache[cacheKey]!;
      }

      final startTime = DateTime.now();
      
      // 1. 检测技术栈特性
      final techStackFeatures = await _detectTechStackFeatures(projectPath);
      
      // 2. 检测架构模式
      final architecturePatterns = await _detectArchitecturePatterns(projectPath);
      
      // 3. 检测第三方集成
      final thirdPartyIntegrations = await _detectThirdPartyIntegrations(projectPath);
      
      // 4. 检测开发工具
      final developmentTools = await _detectDevelopmentTools(projectPath);
      
      // 5. 评估团队规模
      final teamSize = await _estimateTeamSize(projectPath);
      
      // 6. 评估项目复杂度
      final projectComplexity = await _estimateProjectComplexity(
        projectPath,
        techStackFeatures,
        architecturePatterns,
        thirdPartyIntegrations,
      );
      
      // 7. 计算置信度
      final confidence = _calculateConfidence(
        techStackFeatures,
        architecturePatterns,
        projectPath,
      );
      
      final result = FeatureDetectionResult(
        techStackFeatures: techStackFeatures,
        architecturePatterns: architecturePatterns,
        thirdPartyIntegrations: thirdPartyIntegrations,
        developmentTools: developmentTools,
        teamSize: teamSize,
        projectComplexity: projectComplexity,
        confidence: confidence,
        detectionTime: startTime,
        metadata: {
          'detectionDuration': DateTime.now().difference(startTime).inMilliseconds,
          'projectPath': projectPath,
          'hints': hints,
          'deepAnalysis': enableDeepAnalysis,
        },
      );
      
      // 缓存结果
      if (enableCaching) {
        _cache[cacheKey] = result;
        _cacheTime[cacheKey] = DateTime.now();
      }
      
      cli_logger.Logger.info(
        '功能检测完成: ${techStackFeatures.length}个特性, '
        '${architecturePatterns.length}个架构模式, '
        '${thirdPartyIntegrations.length}个集成',
      );
      
      return result;
    } catch (e) {
      cli_logger.Logger.error('功能检测失败', error: e);
      
      // 返回默认结果
      return FeatureDetectionResult(
        techStackFeatures: const {},
        architecturePatterns: const {},
        thirdPartyIntegrations: const {},
        developmentTools: const {},
        teamSize: TeamSize.solo,
        projectComplexity: ProjectComplexity.simple,
        confidence: 0.1,
        detectionTime: DateTime.now(),
        metadata: {'error': e.toString()},
      );
    }
  }

  /// 检测技术栈特性
  Future<Set<TechStackFeature>> _detectTechStackFeatures(String projectPath) async {
    final features = <TechStackFeature>{};
    
    // 检查Flutter项目
    final pubspecFile = File('$projectPath/pubspec.yaml');
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();
      
      // 状态管理
      if (content.contains('bloc') || content.contains('flutter_bloc')) {
        features.add(TechStackFeature.stateManagement);
      }
      if (content.contains('provider') || content.contains('riverpod')) {
        features.add(TechStackFeature.stateManagement);
      }
      if (content.contains('get') || content.contains('getx')) {
        features.add(TechStackFeature.stateManagement);
      }
      
      // 路由
      if (content.contains('go_router') || content.contains('auto_route')) {
        features.add(TechStackFeature.routing);
      }
      
      // 网络
      if (content.contains('http') || content.contains('dio')) {
        features.add(TechStackFeature.networking);
      }
      
      // 数据库
      if (content.contains('sqflite') || content.contains('hive') || 
          content.contains('isar') || content.contains('drift')) {
        features.add(TechStackFeature.database);
      }
      
      // 缓存
      if (content.contains('shared_preferences') || content.contains('hive')) {
        features.add(TechStackFeature.caching);
      }
      
      // 认证
      if (content.contains('firebase_auth') || content.contains('oauth')) {
        features.add(TechStackFeature.authentication);
      }
      
      // 国际化
      if (content.contains('intl') || content.contains('flutter_localizations')) {
        features.add(TechStackFeature.internationalization);
      }
      
      // 测试
      if (content.contains('test') || content.contains('mockito') || 
          content.contains('integration_test')) {
        features.add(TechStackFeature.testing);
      }
      
      // 代码生成
      if (content.contains('build_runner') || content.contains('json_annotation')) {
        features.add(TechStackFeature.codeGeneration);
      }
      
      // 性能监控
      if (content.contains('firebase_performance') || content.contains('sentry')) {
        features.add(TechStackFeature.performanceMonitoring);
      }
      
      // 错误追踪
      if (content.contains('crashlytics') || content.contains('sentry')) {
        features.add(TechStackFeature.errorTracking);
      }
      
      // 日志
      if (content.contains('logger') || content.contains('logging')) {
        features.add(TechStackFeature.logging);
      }
    }
    
    // 检查Node.js项目
    final packageJsonFile = File('$projectPath/package.json');
    if (await packageJsonFile.exists()) {
      final content = await packageJsonFile.readAsString();
      try {
        final packageJson = json.decode(content) as Map<String, dynamic>;
        final dependencies = {
          ...?packageJson['dependencies'] as Map<String, dynamic>?,
          ...?packageJson['devDependencies'] as Map<String, dynamic>?,
        };
        
        // 状态管理
        if (dependencies.containsKey('redux') || dependencies.containsKey('mobx')) {
          features.add(TechStackFeature.stateManagement);
        }
        
        // 路由
        if (dependencies.containsKey('react-router') || 
            dependencies.containsKey('vue-router') ||
            dependencies.containsKey('@angular/router')) {
          features.add(TechStackFeature.routing);
        }
        
        // 网络
        if (dependencies.containsKey('axios') || dependencies.containsKey('fetch')) {
          features.add(TechStackFeature.networking);
        }
        
        // 测试
        if (dependencies.containsKey('jest') || dependencies.containsKey('mocha') ||
            dependencies.containsKey('cypress') || dependencies.containsKey('playwright')) {
          features.add(TechStackFeature.testing);
        }
        
        // 构建工具
        if (dependencies.containsKey('webpack') || dependencies.containsKey('vite') ||
            dependencies.containsKey('rollup') || dependencies.containsKey('parcel')) {
          features.add(TechStackFeature.buildTools);
        }
      } catch (e) {
        // JSON解析失败，继续其他检测
      }
    }
    
    return features;
  }

  /// 检测架构模式
  Future<Set<ArchitecturePattern>> _detectArchitecturePatterns(String projectPath) async {
    final patterns = <ArchitecturePattern>{};
    
    // 检查目录结构
    final libDir = Directory('$projectPath/lib');
    if (await libDir.exists()) {
      final entities = await libDir.list().toList();
      final dirNames = entities
          .whereType<Directory>()
          .map((d) => d.path.split('/').last.toLowerCase())
          .toSet();
      
      // Clean Architecture
      if (dirNames.contains('domain') && 
          dirNames.contains('data') && 
          dirNames.contains('presentation')) {
        patterns.add(ArchitecturePattern.cleanArchitecture);
      }
      
      // MVVM
      if (dirNames.contains('models') && 
          dirNames.contains('views') && 
          dirNames.contains('viewmodels')) {
        patterns.add(ArchitecturePattern.mvvm);
      }
      
      // MVC
      if (dirNames.contains('models') && 
          dirNames.contains('views') && 
          dirNames.contains('controllers')) {
        patterns.add(ArchitecturePattern.mvc);
      }
      
      // 分层架构
      if (dirNames.contains('services') && 
          dirNames.contains('repositories') && 
          dirNames.contains('models')) {
        patterns.add(ArchitecturePattern.layered);
      }
    }
    
    // 检查依赖
    final pubspecFile = File('$projectPath/pubspec.yaml');
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();
      
      if (content.contains('bloc') || content.contains('flutter_bloc')) {
        patterns.add(ArchitecturePattern.bloc);
      }
      if (content.contains('provider')) {
        patterns.add(ArchitecturePattern.provider);
      }
      if (content.contains('riverpod')) {
        patterns.add(ArchitecturePattern.riverpod);
      }
      if (content.contains('get') || content.contains('getx')) {
        patterns.add(ArchitecturePattern.getx);
      }
    }
    
    return patterns;
  }

  /// 检测第三方集成
  Future<Set<ThirdPartyIntegration>> _detectThirdPartyIntegrations(String projectPath) async {
    final integrations = <ThirdPartyIntegration>{};
    
    // 检查Flutter项目
    final pubspecFile = File('$projectPath/pubspec.yaml');
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();
      
      // Firebase
      if (content.contains('firebase')) {
        integrations.add(ThirdPartyIntegration.firebase);
      }
      
      // AWS
      if (content.contains('aws') || content.contains('amplify')) {
        integrations.add(ThirdPartyIntegration.aws);
      }
      
      // Google Cloud
      if (content.contains('google_cloud') || content.contains('gcp')) {
        integrations.add(ThirdPartyIntegration.googleCloud);
      }
      
      // Supabase
      if (content.contains('supabase')) {
        integrations.add(ThirdPartyIntegration.supabase);
      }
      
      // 支付
      if (content.contains('stripe') || content.contains('paypal')) {
        integrations.add(ThirdPartyIntegration.stripe);
      }
      
      // 通信
      if (content.contains('twilio')) {
        integrations.add(ThirdPartyIntegration.twilio);
      }
      
      // 错误追踪
      if (content.contains('sentry') || content.contains('crashlytics')) {
        integrations.add(ThirdPartyIntegration.sentry);
      }
      
      // 分析
      if (content.contains('analytics') || content.contains('firebase_analytics')) {
        integrations.add(ThirdPartyIntegration.analytics);
      }
      
      // 推送通知
      if (content.contains('firebase_messaging') || content.contains('push')) {
        integrations.add(ThirdPartyIntegration.pushNotifications);
      }
    }
    
    return integrations;
  }

  /// 检测开发工具
  Future<Set<DevelopmentTool>> _detectDevelopmentTools(String projectPath) async {
    final tools = <DevelopmentTool>{};
    
    // 检查Git
    if (await Directory('$projectPath/.git').exists()) {
      tools.add(DevelopmentTool.git);
    }
    
    // 检查GitHub Actions
    if (await Directory('$projectPath/.github/workflows').exists()) {
      tools.add(DevelopmentTool.githubActions);
    }
    
    // 检查GitLab CI
    if (await File('$projectPath/.gitlab-ci.yml').exists()) {
      tools.add(DevelopmentTool.gitlabCI);
    }
    
    // 检查Docker
    if (await File('$projectPath/Dockerfile').exists() ||
        await File('$projectPath/docker-compose.yml').exists()) {
      tools.add(DevelopmentTool.docker);
    }
    
    // 检查VS Code配置
    if (await Directory('$projectPath/.vscode').exists()) {
      tools.add(DevelopmentTool.vscode);
    }
    
    // 检查IntelliJ配置
    if (await Directory('$projectPath/.idea').exists()) {
      tools.add(DevelopmentTool.intellij);
    }
    
    return tools;
  }

  /// 估算团队规模
  Future<TeamSize> _estimateTeamSize(String projectPath) async {
    // 基于Git提交历史估算团队规模
    try {
      final result = await Process.run(
        'git',
        ['log', '--format=%ae'],
        workingDirectory: projectPath,
      );
      
      if (result.exitCode == 0) {
        final emails = result.stdout.toString()
            .split('\n')
            .where((email) => email.isNotEmpty)
            .toSet();
        
        if (emails.length >= 50) {
          return TeamSize.enterprise;
        } else if (emails.length >= 16) {
          return TeamSize.large;
        } else if (emails.length >= 6) {
          return TeamSize.medium;
        } else if (emails.length >= 2) {
          return TeamSize.small;
        }
      }
    } catch (e) {
      // Git命令失败，使用其他方法估算
    }
    
    return TeamSize.solo;
  }

  /// 估算项目复杂度
  Future<ProjectComplexity> _estimateProjectComplexity(
    String projectPath,
    Set<TechStackFeature> features,
    Set<ArchitecturePattern> patterns,
    Set<ThirdPartyIntegration> integrations,
  ) async {
    var complexityScore = 0;
    
    // 基于特性数量
    complexityScore += features.length * 2;
    
    // 基于架构模式
    complexityScore += patterns.length * 3;
    
    // 基于第三方集成
    complexityScore += integrations.length * 2;
    
    // 基于代码行数
    try {
      final result = await Process.run(
        'find',
        [projectPath, '-name', '*.dart', '-o', '-name', '*.js', '-o', '-name', '*.ts'],
      );
      
      if (result.exitCode == 0) {
        final files = result.stdout.toString().split('\n').where((f) => f.isNotEmpty);
        complexityScore += files.length ~/ 10; // 每10个文件增加1分
      }
    } catch (e) {
      // 文件统计失败，忽略
    }
    
    // 根据分数确定复杂度
    if (complexityScore >= 50) {
      return ProjectComplexity.enterprise;
    } else if (complexityScore >= 30) {
      return ProjectComplexity.complex;
    } else if (complexityScore >= 15) {
      return ProjectComplexity.medium;
    } else {
      return ProjectComplexity.simple;
    }
  }

  /// 计算检测置信度
  double _calculateConfidence(
    Set<TechStackFeature> features,
    Set<ArchitecturePattern> patterns,
    String projectPath,
  ) {
    var confidence = 0.3; // 基础置信度
    
    // 检测到的特性增加置信度
    confidence += features.length * 0.05;
    
    // 检测到的架构模式增加置信度
    confidence += patterns.length * 0.1;
    
    // 项目文件存在增加置信度
    if (File('$projectPath/pubspec.yaml').existsSync() ||
        File('$projectPath/package.json').existsSync()) {
      confidence += 0.3;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// 生成缓存键
  String _generateCacheKey(String projectPath, Map<String, dynamic>? hints) {
    final hintsHash = hints?.toString().hashCode ?? 0;
    return '${projectPath.hashCode}_$hintsHash';
  }

  /// 检查缓存是否有效
  bool _isCacheValid(String cacheKey) {
    if (!_cache.containsKey(cacheKey) || !_cacheTime.containsKey(cacheKey)) {
      return false;
    }
    
    final now = DateTime.now();
    return now.difference(_cacheTime[cacheKey]!).compareTo(cacheTimeout) < 0;
  }

  /// 清理缓存
  void clearCache() {
    _cache.clear();
    _cacheTime.clear();
    cli_logger.Logger.debug('功能检测器缓存已清理');
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'cacheTimeout': cacheTimeout.inSeconds,
      'oldestCacheAge': _cacheTime.values.isNotEmpty
          ? DateTime.now().difference(_cacheTime.values.reduce((a, b) => a.isBefore(b) ? a : b)).inSeconds
          : null,
    };
  }
}
