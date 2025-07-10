/*
---------------------------------------------------------------
File name:          smart_recommendation_engine.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级智能推荐引擎 (Enterprise Smart Recommendation Engine)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 智能条件生成系统;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/conditional/feature_detector.dart';
import 'package:ming_status_cli/src/core/conditional/platform_detector.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 推荐类型
enum RecommendationType {
  /// 模板推荐
  template,

  /// 功能推荐
  feature,

  /// 架构推荐
  architecture,

  /// 工具推荐
  tool,

  /// 最佳实践推荐
  bestPractice,

  /// 性能优化推荐
  performance,

  /// 安全推荐
  security,
}

/// 推荐优先级
enum RecommendationPriority {
  /// 低优先级
  low,

  /// 中等优先级
  medium,

  /// 高优先级
  high,

  /// 关键优先级
  critical,
}

/// 推荐原因
enum RecommendationReason {
  /// 平台兼容性
  platformCompatibility,

  /// 功能需求
  featureRequirement,

  /// 性能优化
  performanceOptimization,

  /// 安全增强
  securityEnhancement,

  /// 开发效率
  developmentEfficiency,

  /// 团队协作
  teamCollaboration,

  /// 行业标准
  industryStandard,

  /// 技术趋势
  technologyTrend,
}

/// 推荐项
class RecommendationItem {
  /// 创建推荐项实例
  const RecommendationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.reason,
    required this.confidence,
    this.tags = const [],
    this.dependencies = const [],
    this.alternatives = const [],
    this.estimatedEffort,
    this.benefits = const [],
    this.risks = const [],
    this.resources = const [],
    this.metadata = const {},
  });

  /// 推荐ID
  final String id;

  /// 推荐标题
  final String title;

  /// 推荐描述
  final String description;

  /// 推荐类型
  final RecommendationType type;

  /// 优先级
  final RecommendationPriority priority;

  /// 推荐原因
  final RecommendationReason reason;

  /// 置信度 (0.0-1.0)
  final double confidence;

  /// 标签
  final List<String> tags;

  /// 依赖项
  final List<String> dependencies;

  /// 替代方案
  final List<String> alternatives;

  /// 预估工作量 (小时)
  final int? estimatedEffort;

  /// 预期收益
  final List<String> benefits;

  /// 潜在风险
  final List<String> risks;

  /// 相关资源
  final List<String> resources;

  /// 额外元数据
  final Map<String, dynamic> metadata;
}

/// 推荐结果
class RecommendationResult {
  /// 创建推荐结果实例
  const RecommendationResult({
    required this.recommendations,
    required this.totalScore,
    this.generationTime,
    this.metadata = const {},
  });

  /// 推荐列表
  final List<RecommendationItem> recommendations;

  /// 总体评分
  final double totalScore;

  /// 生成时间
  final DateTime? generationTime;

  /// 额外元数据
  final Map<String, dynamic> metadata;

  /// 按优先级分组
  Map<RecommendationPriority, List<RecommendationItem>> get byPriority {
    final grouped = <RecommendationPriority, List<RecommendationItem>>{};
    for (final priority in RecommendationPriority.values) {
      grouped[priority] =
          recommendations.where((r) => r.priority == priority).toList();
    }
    return grouped;
  }

  /// 按类型分组
  Map<RecommendationType, List<RecommendationItem>> get byType {
    final grouped = <RecommendationType, List<RecommendationItem>>{};
    for (final type in RecommendationType.values) {
      grouped[type] = recommendations.where((r) => r.type == type).toList();
    }
    return grouped;
  }

  /// 高优先级推荐
  List<RecommendationItem> get highPriorityRecommendations => recommendations
      .where(
        (r) =>
            r.priority == RecommendationPriority.high ||
            r.priority == RecommendationPriority.critical,
      )
      .toList();
}

/// 企业级智能推荐引擎
///
/// 基于平台检测和功能分析，提供智能化的模板、工具和最佳实践推荐
class SmartRecommendationEngine {
  /// 创建智能推荐引擎实例
  SmartRecommendationEngine({
    this.enableCaching = true,
    this.cacheTimeout = const Duration(minutes: 15),
    this.maxRecommendations = 20,
    this.minConfidence = 0.3,
  });

  /// 是否启用缓存
  final bool enableCaching;

  /// 缓存超时时间
  final Duration cacheTimeout;

  /// 最大推荐数量
  final int maxRecommendations;

  /// 最小置信度阈值
  final double minConfidence;

  /// 推荐结果缓存
  final Map<String, RecommendationResult> _cache = {};
  final Map<String, DateTime> _cacheTime = {};

  /// 生成智能推荐
  ///
  /// 基于平台检测和功能分析结果生成个性化推荐
  Future<RecommendationResult> generateRecommendations({
    required PlatformDetectionResult platformResult,
    required FeatureDetectionResult featureResult,
    Map<String, dynamic>? userPreferences,
    Map<String, dynamic>? projectContext,
  }) async {
    try {
      cli_logger.Logger.debug('开始生成智能推荐');

      // 生成缓存键
      final cacheKey = _generateCacheKey(
        platformResult,
        featureResult,
        userPreferences,
        projectContext,
      );

      // 检查缓存
      if (enableCaching && _isCacheValid(cacheKey)) {
        cli_logger.Logger.debug('使用缓存的推荐结果');
        return _cache[cacheKey]!;
      }

      final startTime = DateTime.now();
      final recommendations = <RecommendationItem>[];

      // 1. 生成模板推荐
      recommendations.addAll(
        await _generateTemplateRecommendations(
          platformResult,
          featureResult,
          userPreferences,
        ),
      );

      // 2. 生成功能推荐
      recommendations.addAll(
        await _generateFeatureRecommendations(
          platformResult,
          featureResult,
          userPreferences,
        ),
      );

      // 3. 生成架构推荐
      recommendations.addAll(
        await _generateArchitectureRecommendations(
          platformResult,
          featureResult,
          userPreferences,
        ),
      );

      // 4. 生成工具推荐
      recommendations.addAll(
        await _generateToolRecommendations(
          platformResult,
          featureResult,
          userPreferences,
        ),
      );

      // 5. 生成最佳实践推荐
      recommendations.addAll(
        await _generateBestPracticeRecommendations(
          platformResult,
          featureResult,
          userPreferences,
        ),
      );

      // 6. 生成性能优化推荐
      recommendations.addAll(
        await _generatePerformanceRecommendations(
          platformResult,
          featureResult,
          userPreferences,
        ),
      );

      // 7. 生成安全推荐
      recommendations.addAll(
        await _generateSecurityRecommendations(
          platformResult,
          featureResult,
          userPreferences,
        ),
      );

      // 8. 过滤和排序推荐
      final filteredRecommendations = _filterAndSortRecommendations(
        recommendations,
        platformResult,
        featureResult,
      );

      // 9. 计算总体评分
      final totalScore = _calculateTotalScore(filteredRecommendations);

      final result = RecommendationResult(
        recommendations: filteredRecommendations,
        totalScore: totalScore,
        generationTime: startTime,
        metadata: {
          'generationDuration':
              DateTime.now().difference(startTime).inMilliseconds,
          'totalCandidates': recommendations.length,
          'filteredCount': filteredRecommendations.length,
          'platformType': platformResult.primaryPlatform.name,
          'framework': platformResult.framework.name,
          'teamSize': featureResult.teamSize.name,
          'complexity': featureResult.projectComplexity.name,
        },
      );

      // 缓存结果
      if (enableCaching) {
        _cache[cacheKey] = result;
        _cacheTime[cacheKey] = DateTime.now();
      }

      cli_logger.Logger.info(
        '智能推荐生成完成: ${filteredRecommendations.length}个推荐 '
        '(总评分: ${totalScore.toStringAsFixed(2)})',
      );

      return result;
    } catch (e) {
      cli_logger.Logger.error('智能推荐生成失败', error: e);

      // 返回空推荐结果
      return RecommendationResult(
        recommendations: const [],
        totalScore: 0,
        generationTime: DateTime.now(),
        metadata: {'error': e.toString()},
      );
    }
  }

  /// 生成模板推荐
  Future<List<RecommendationItem>> _generateTemplateRecommendations(
    PlatformDetectionResult platformResult,
    FeatureDetectionResult featureResult,
    Map<String, dynamic>? userPreferences,
  ) async {
    final recommendations = <RecommendationItem>[];

    // 基于平台推荐模板
    switch (platformResult.primaryPlatform) {
      case PlatformType.mobile:
        if (platformResult.framework == FrameworkType.flutter) {
          recommendations.add(
            const RecommendationItem(
              id: 'flutter_mobile_template',
              title: 'Flutter移动应用模板',
              description: '适用于Flutter移动应用开发的完整模板，包含状态管理、路由和常用功能',
              type: RecommendationType.template,
              priority: RecommendationPriority.high,
              reason: RecommendationReason.platformCompatibility,
              confidence: 0.9,
              tags: ['flutter', 'mobile', 'cross-platform'],
              benefits: ['快速启动项目', '最佳实践集成', '跨平台支持'],
              estimatedEffort: 2,
            ),
          );
        }

      case PlatformType.web:
        if (platformResult.framework == FrameworkType.react) {
          recommendations.add(
            const RecommendationItem(
              id: 'react_spa_template',
              title: 'React单页应用模板',
              description: '现代React SPA模板，集成TypeScript、状态管理和构建工具',
              type: RecommendationType.template,
              priority: RecommendationPriority.high,
              reason: RecommendationReason.platformCompatibility,
              confidence: 0.85,
              tags: ['react', 'spa', 'typescript'],
              benefits: ['类型安全', '现代开发体验', '性能优化'],
              estimatedEffort: 3,
            ),
          );
        }

      case PlatformType.server:
        recommendations.add(
          const RecommendationItem(
            id: 'microservice_template',
            title: '微服务API模板',
            description: '企业级微服务模板，包含API网关、服务发现和监控',
            type: RecommendationType.template,
            priority: RecommendationPriority.medium,
            reason: RecommendationReason.industryStandard,
            confidence: 0.75,
            tags: ['microservice', 'api', 'enterprise'],
            benefits: ['可扩展性', '服务隔离', '容错能力'],
            estimatedEffort: 8,
          ),
        );

      default:
        break;
    }

    return recommendations;
  }

  /// 生成功能推荐
  Future<List<RecommendationItem>> _generateFeatureRecommendations(
    PlatformDetectionResult platformResult,
    FeatureDetectionResult featureResult,
    Map<String, dynamic>? userPreferences,
  ) async {
    final recommendations = <RecommendationItem>[];

    // 检查缺失的关键功能
    if (!featureResult.techStackFeatures
        .contains(TechStackFeature.stateManagement)) {
      recommendations.add(
        const RecommendationItem(
          id: 'state_management_feature',
          title: '状态管理解决方案',
          description: '添加状态管理以提高应用的可维护性和性能',
          type: RecommendationType.feature,
          priority: RecommendationPriority.high,
          reason: RecommendationReason.developmentEfficiency,
          confidence: 0.8,
          tags: ['state-management', 'architecture'],
          benefits: ['代码组织', '性能优化', '调试便利'],
          estimatedEffort: 4,
        ),
      );
    }

    if (!featureResult.techStackFeatures.contains(TechStackFeature.testing)) {
      recommendations.add(
        const RecommendationItem(
          id: 'testing_framework',
          title: '测试框架集成',
          description: '集成单元测试和集成测试框架，提高代码质量',
          type: RecommendationType.feature,
          priority: RecommendationPriority.medium,
          reason: RecommendationReason.industryStandard,
          confidence: 0.9,
          tags: ['testing', 'quality'],
          benefits: ['代码质量', '回归测试', '持续集成'],
          estimatedEffort: 6,
        ),
      );
    }

    return recommendations;
  }

  /// 生成架构推荐
  Future<List<RecommendationItem>> _generateArchitectureRecommendations(
    PlatformDetectionResult platformResult,
    FeatureDetectionResult featureResult,
    Map<String, dynamic>? userPreferences,
  ) async {
    final recommendations = <RecommendationItem>[];

    // 基于项目复杂度推荐架构
    if (featureResult.projectComplexity == ProjectComplexity.complex ||
        featureResult.projectComplexity == ProjectComplexity.enterprise) {
      if (!featureResult.architecturePatterns
          .contains(ArchitecturePattern.cleanArchitecture)) {
        recommendations.add(
          const RecommendationItem(
            id: 'clean_architecture',
            title: 'Clean Architecture实施',
            description: '采用Clean Architecture模式，提高代码的可测试性和可维护性',
            type: RecommendationType.architecture,
            priority: RecommendationPriority.high,
            reason: RecommendationReason.developmentEfficiency,
            confidence: 0.85,
            tags: ['clean-architecture', 'maintainability'],
            benefits: ['代码分离', '可测试性', '可维护性'],
            estimatedEffort: 12,
          ),
        );
      }
    }

    return recommendations;
  }

  /// 生成工具推荐
  Future<List<RecommendationItem>> _generateToolRecommendations(
    PlatformDetectionResult platformResult,
    FeatureDetectionResult featureResult,
    Map<String, dynamic>? userPreferences,
  ) async {
    final recommendations = <RecommendationItem>[];

    // CI/CD推荐
    if (!featureResult.developmentTools
            .contains(DevelopmentTool.githubActions) &&
        !featureResult.developmentTools.contains(DevelopmentTool.gitlabCI)) {
      recommendations.add(
        const RecommendationItem(
          id: 'cicd_setup',
          title: 'CI/CD流水线设置',
          description: '设置自动化构建、测试和部署流水线',
          type: RecommendationType.tool,
          priority: RecommendationPriority.medium,
          reason: RecommendationReason.developmentEfficiency,
          confidence: 0.8,
          tags: ['cicd', 'automation'],
          benefits: ['自动化部署', '质量保证', '快速反馈'],
          estimatedEffort: 8,
        ),
      );
    }

    return recommendations;
  }

  /// 生成最佳实践推荐
  Future<List<RecommendationItem>> _generateBestPracticeRecommendations(
    PlatformDetectionResult platformResult,
    FeatureDetectionResult featureResult,
    Map<String, dynamic>? userPreferences,
  ) async {
    final recommendations = <RecommendationItem>[];

    // 代码规范推荐
    recommendations.add(
      const RecommendationItem(
        id: 'code_standards',
        title: '代码规范和Lint配置',
        description: '建立统一的代码规范和自动化检查',
        type: RecommendationType.bestPractice,
        priority: RecommendationPriority.medium,
        reason: RecommendationReason.teamCollaboration,
        confidence: 0.9,
        tags: ['code-quality', 'standards'],
        benefits: ['代码一致性', '团队协作', '错误预防'],
        estimatedEffort: 2,
      ),
    );

    return recommendations;
  }

  /// 生成性能优化推荐
  Future<List<RecommendationItem>> _generatePerformanceRecommendations(
    PlatformDetectionResult platformResult,
    FeatureDetectionResult featureResult,
    Map<String, dynamic>? userPreferences,
  ) async {
    final recommendations = <RecommendationItem>[];

    if (!featureResult.techStackFeatures.contains(TechStackFeature.caching)) {
      recommendations.add(
        const RecommendationItem(
          id: 'caching_strategy',
          title: '缓存策略实施',
          description: '实施多层缓存策略，提高应用性能',
          type: RecommendationType.performance,
          priority: RecommendationPriority.medium,
          reason: RecommendationReason.performanceOptimization,
          confidence: 0.75,
          tags: ['caching', 'performance'],
          benefits: ['响应速度', '资源节约', '用户体验'],
          estimatedEffort: 6,
        ),
      );
    }

    return recommendations;
  }

  /// 生成安全推荐
  Future<List<RecommendationItem>> _generateSecurityRecommendations(
    PlatformDetectionResult platformResult,
    FeatureDetectionResult featureResult,
    Map<String, dynamic>? userPreferences,
  ) async {
    final recommendations = <RecommendationItem>[];

    if (!featureResult.techStackFeatures
        .contains(TechStackFeature.authentication)) {
      recommendations.add(
        const RecommendationItem(
          id: 'authentication_security',
          title: '身份认证和授权',
          description: '实施安全的身份认证和授权机制',
          type: RecommendationType.security,
          priority: RecommendationPriority.high,
          reason: RecommendationReason.securityEnhancement,
          confidence: 0.9,
          tags: ['security', 'authentication'],
          benefits: ['数据安全', '访问控制', '合规性'],
          estimatedEffort: 10,
        ),
      );
    }

    return recommendations;
  }

  /// 过滤和排序推荐
  List<RecommendationItem> _filterAndSortRecommendations(
    List<RecommendationItem> recommendations,
    PlatformDetectionResult platformResult,
    FeatureDetectionResult featureResult,
  ) {
    // 过滤低置信度推荐
    final filtered =
        recommendations.where((r) => r.confidence >= minConfidence).toList();

    // 按优先级和置信度排序
    filtered.sort((a, b) {
      // 首先按优先级排序
      final priorityOrder = {
        RecommendationPriority.critical: 4,
        RecommendationPriority.high: 3,
        RecommendationPriority.medium: 2,
        RecommendationPriority.low: 1,
      };

      final priorityComparison =
          priorityOrder[b.priority]!.compareTo(priorityOrder[a.priority]!);

      if (priorityComparison != 0) {
        return priorityComparison;
      }

      // 然后按置信度排序
      return b.confidence.compareTo(a.confidence);
    });

    // 限制推荐数量
    return filtered.take(maxRecommendations).toList();
  }

  /// 计算总体评分
  double _calculateTotalScore(List<RecommendationItem> recommendations) {
    if (recommendations.isEmpty) return 0;

    var totalScore = 0.0;
    var totalWeight = 0;

    for (final recommendation in recommendations) {
      // 根据优先级分配权重
      var weight = 1;
      switch (recommendation.priority) {
        case RecommendationPriority.critical:
          weight = 4;
        case RecommendationPriority.high:
          weight = 3;
        case RecommendationPriority.medium:
          weight = 2;
        case RecommendationPriority.low:
          weight = 1;
      }

      totalScore += recommendation.confidence * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? totalScore / totalWeight : 0.0;
  }

  /// 生成缓存键
  String _generateCacheKey(
    PlatformDetectionResult platformResult,
    FeatureDetectionResult featureResult,
    Map<String, dynamic>? userPreferences,
    Map<String, dynamic>? projectContext,
  ) {
    final keyComponents = [
      platformResult.primaryPlatform.name,
      platformResult.framework.name,
      featureResult.teamSize.name,
      featureResult.projectComplexity.name,
      featureResult.techStackFeatures.length.toString(),
      userPreferences?.toString().hashCode.toString() ?? '0',
      projectContext?.toString().hashCode.toString() ?? '0',
    ];

    return keyComponents.join('_');
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
    cli_logger.Logger.debug('智能推荐引擎缓存已清理');
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'cacheTimeout': cacheTimeout.inSeconds,
      'oldestCacheAge': _cacheTime.values.isNotEmpty
          ? DateTime.now()
              .difference(
                  _cacheTime.values.reduce((a, b) => a.isBefore(b) ? a : b),)
              .inSeconds
          : null,
    };
  }
}
