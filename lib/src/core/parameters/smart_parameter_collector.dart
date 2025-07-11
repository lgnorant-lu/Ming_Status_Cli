/*
---------------------------------------------------------------
File name:          smart_parameter_collector.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        智能参数收集器 (Smart Parameter Collector)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.2 企业级参数化系统;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/core/conditional/feature_detector.dart';
import 'package:ming_status_cli/src/core/conditional/platform_detector.dart';
import 'package:ming_status_cli/src/core/parameters/enterprise_parameter_validator.dart';
import 'package:ming_status_cli/src/core/parameters/enterprise_template_parameter.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 参数收集模式
enum ParameterCollectionMode {
  /// 交互式模式
  interactive,

  /// 批量模式
  batch,

  /// 向导模式
  wizard,

  /// 自动模式
  automatic,
}

/// 参数推荐来源
enum RecommendationSource {
  /// 环境变量
  environment,

  /// 配置文件
  configFile,

  /// 项目检测
  projectDetection,

  /// 历史记录
  history,

  /// 默认值
  defaultValue,

  /// 用户输入
  userInput,
}

/// 参数推荐
class ParameterRecommendation {
  /// 创建参数推荐实例
  const ParameterRecommendation({
    required this.value,
    required this.source,
    required this.confidence,
    this.description,
    this.metadata = const {},
  });

  /// 推荐值
  final dynamic value;

  /// 推荐来源
  final RecommendationSource source;

  /// 置信度 (0.0-1.0)
  final double confidence;

  /// 推荐描述
  final String? description;

  /// 额外元数据
  final Map<String, dynamic> metadata;
}

/// 参数收集步骤
class ParameterCollectionStep {
  /// 创建参数收集步骤实例
  const ParameterCollectionStep({
    required this.name,
    required this.title,
    required this.parameters,
    this.description,
    this.condition,
    this.order = 0,
  });

  /// 步骤名称
  final String name;

  /// 步骤标题
  final String title;

  /// 步骤参数列表
  final List<EnterpriseTemplateParameter> parameters;

  /// 步骤描述
  final String? description;

  /// 显示条件
  final String? condition;

  /// 显示顺序
  final int order;
}

/// 参数收集会话
class ParameterCollectionSession {
  /// 创建参数收集会话实例
  ParameterCollectionSession({
    required this.sessionId,
    required this.parameters,
    this.mode = ParameterCollectionMode.interactive,
    this.enableRecommendations = true,
    this.enableValidation = true,
    this.enableProgress = true,
  });

  /// 会话ID
  final String sessionId;

  /// 参数列表
  final List<EnterpriseTemplateParameter> parameters;

  /// 收集模式
  final ParameterCollectionMode mode;

  /// 是否启用推荐
  final bool enableRecommendations;

  /// 是否启用验证
  final bool enableValidation;

  /// 是否显示进度
  final bool enableProgress;

  /// 收集的参数值
  final Map<String, dynamic> collectedValues = {};

  /// 参数推荐
  final Map<String, List<ParameterRecommendation>> recommendations = {};

  /// 验证结果
  final Map<String, EnterpriseValidationResult> validationResults = {};

  /// 当前步骤索引
  int currentStepIndex = 0;

  /// 收集步骤
  List<ParameterCollectionStep> steps = [];

  /// 会话开始时间
  final DateTime startTime = DateTime.now();

  /// 是否已完成
  bool isCompleted = false;

  /// 是否已取消
  bool isCancelled = false;

  /// 获取当前步骤
  ParameterCollectionStep? get currentStep =>
      currentStepIndex < steps.length ? steps[currentStepIndex] : null;

  /// 获取收集进度
  double get progress => steps.isEmpty ? 0.0 : currentStepIndex / steps.length;

  /// 获取已收集参数数量
  int get collectedCount => collectedValues.length;

  /// 获取总参数数量
  int get totalCount => parameters.length;
}

/// 智能参数收集器
class SmartParameterCollector {
  /// 创建智能参数收集器实例
  SmartParameterCollector({
    this.platformDetector,
    this.featureDetector,
    this.validator,
    this.enableAutoFill = true,
    this.enableSmartRecommendations = true,
    this.maxRecommendations = 5,
  });

  /// 平台检测器
  final PlatformDetector? platformDetector;

  /// 功能检测器
  final FeatureDetector? featureDetector;

  /// 参数验证器
  final EnterpriseParameterValidator? validator;

  /// 是否启用自动填充
  final bool enableAutoFill;

  /// 是否启用智能推荐
  final bool enableSmartRecommendations;

  /// 最大推荐数量
  final int maxRecommendations;

  /// 活动会话
  final Map<String, ParameterCollectionSession> _activeSessions = {};

  /// 开始参数收集会话
  Future<ParameterCollectionSession> startSession({
    required String sessionId,
    required List<EnterpriseTemplateParameter> parameters,
    ParameterCollectionMode mode = ParameterCollectionMode.interactive,
    Map<String, dynamic>? initialValues,
    String? projectPath,
  }) async {
    try {
      cli_logger.Logger.debug('开始参数收集会话: $sessionId');

      final session = ParameterCollectionSession(
        sessionId: sessionId,
        parameters: parameters,
        mode: mode,
      );

      // 设置初始值
      if (initialValues != null) {
        session.collectedValues.addAll(initialValues);
      }

      // 生成收集步骤
      session.steps = await _generateCollectionSteps(parameters);

      // 生成智能推荐
      if (enableSmartRecommendations) {
        await _generateRecommendations(session, projectPath);
      }

      // 自动填充
      if (enableAutoFill) {
        await _autoFillParameters(session, projectPath);
      }

      _activeSessions[sessionId] = session;

      cli_logger.Logger.info(
        '参数收集会话已启动: $sessionId - '
        '${parameters.length}个参数, ${session.steps.length}个步骤',
      );

      return session;
    } catch (e) {
      cli_logger.Logger.error('启动参数收集会话失败', error: e);
      rethrow;
    }
  }

  /// 收集单个参数
  Future<bool> collectParameter({
    required String sessionId,
    required String parameterName,
    required dynamic value,
    bool validateImmediately = true,
  }) async {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw ArgumentError('会话不存在: $sessionId');
    }

    try {
      // 设置参数值
      session.collectedValues[parameterName] = value;

      // 立即验证
      if (validateImmediately && validator != null) {
        final parameter =
            session.parameters.firstWhere((p) => p.name == parameterName);

        final result = await validator!.validateParameter(parameter, value);
        session.validationResults[parameterName] = result;

        if (!result.isValid) {
          cli_logger.Logger.warning(
            '参数验证失败: $parameterName - ${result.errors.join(', ')}',
          );
          return false;
        }
      }

      cli_logger.Logger.debug('参数收集成功: $parameterName = $value');
      return true;
    } catch (e) {
      cli_logger.Logger.error('收集参数失败: $parameterName', error: e);
      return false;
    }
  }

  /// 批量收集参数
  Future<Map<String, bool>> collectParameters({
    required String sessionId,
    required Map<String, dynamic> values,
    bool validateImmediately = true,
  }) async {
    final results = <String, bool>{};

    for (final entry in values.entries) {
      results[entry.key] = await collectParameter(
        sessionId: sessionId,
        parameterName: entry.key,
        value: entry.value,
        validateImmediately: validateImmediately,
      );
    }

    return results;
  }

  /// 获取参数推荐
  List<ParameterRecommendation> getRecommendations(
    String sessionId,
    String parameterName,
  ) {
    final session = _activeSessions[sessionId];
    if (session == null) return [];

    return session.recommendations[parameterName] ?? [];
  }

  /// 进入下一步骤
  bool nextStep(String sessionId) {
    final session = _activeSessions[sessionId];
    if (session == null) return false;

    if (session.currentStepIndex < session.steps.length - 1) {
      session.currentStepIndex++;
      cli_logger.Logger.debug(
        '进入下一步骤: ${session.currentStepIndex + 1}/${session.steps.length}',
      );
      return true;
    }

    return false;
  }

  /// 返回上一步骤
  bool previousStep(String sessionId) {
    final session = _activeSessions[sessionId];
    if (session == null) return false;

    if (session.currentStepIndex > 0) {
      session.currentStepIndex--;
      cli_logger.Logger.debug(
        '返回上一步骤: ${session.currentStepIndex + 1}/${session.steps.length}',
      );
      return true;
    }

    return false;
  }

  /// 完成收集会话
  Future<Map<String, dynamic>> completeSession(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw ArgumentError('会话不存在: $sessionId');
    }

    try {
      // 最终验证
      if (validator != null) {
        final results = await validator!.validateParameters(
          session.parameters,
          session.collectedValues,
        );
        session.validationResults.addAll(results);

        // 检查是否有验证错误
        final hasErrors = results.values.any((r) => !r.isValid);
        if (hasErrors) {
          throw Exception('参数验证失败，无法完成收集');
        }
      }

      session.isCompleted = true;
      final collectedValues =
          Map<String, dynamic>.from(session.collectedValues);

      // 清理会话
      _activeSessions.remove(sessionId);

      cli_logger.Logger.info(
        '参数收集会话完成: $sessionId - 收集了${collectedValues.length}个参数',
      );

      return collectedValues;
    } catch (e) {
      cli_logger.Logger.error('完成参数收集会话失败', error: e);
      rethrow;
    }
  }

  /// 取消收集会话
  void cancelSession(String sessionId) {
    final session = _activeSessions[sessionId];
    if (session != null) {
      session.isCancelled = true;
      _activeSessions.remove(sessionId);
      cli_logger.Logger.info('参数收集会话已取消: $sessionId');
    }
  }

  /// 获取会话状态
  ParameterCollectionSession? getSession(String sessionId) {
    return _activeSessions[sessionId];
  }

  /// 生成收集步骤
  Future<List<ParameterCollectionStep>> _generateCollectionSteps(
    List<EnterpriseTemplateParameter> parameters,
  ) async {
    final steps = <ParameterCollectionStep>[];

    // 按分组和顺序组织参数
    final groupedParams = <String, List<EnterpriseTemplateParameter>>{};

    for (final param in parameters) {
      final group = param.group ?? param.category ?? 'general';
      groupedParams.putIfAbsent(group, () => []).add(param);
    }

    // 为每个分组创建步骤
    var stepOrder = 0;
    for (final entry in groupedParams.entries) {
      final groupName = entry.key;
      final groupParams = entry.value;

      // 按order字段排序
      groupParams.sort((a, b) => a.order.compareTo(b.order));

      steps.add(
        ParameterCollectionStep(
          name: groupName,
          title: _generateStepTitle(groupName),
          parameters: groupParams,
          description: _generateStepDescription(groupName, groupParams),
          order: stepOrder++,
        ),
      );
    }

    // 按order排序
    steps.sort((a, b) => a.order.compareTo(b.order));

    return steps;
  }

  /// 生成智能推荐
  Future<void> _generateRecommendations(
    ParameterCollectionSession session,
    String? projectPath,
  ) async {
    for (final parameter in session.parameters) {
      final recommendations = <ParameterRecommendation>[];

      // 1. 环境变量推荐
      final envValue = _getEnvironmentValue(parameter.name);
      if (envValue != null) {
        recommendations.add(
          ParameterRecommendation(
            value: envValue,
            source: RecommendationSource.environment,
            confidence: 0.8,
            description: '从环境变量获取',
          ),
        );
      }

      // 2. 配置文件推荐
      if (projectPath != null) {
        final configValue =
            await _getConfigFileValue(projectPath, parameter.name);
        if (configValue != null) {
          recommendations.add(
            ParameterRecommendation(
              value: configValue,
              source: RecommendationSource.configFile,
              confidence: 0.9,
              description: '从配置文件获取',
            ),
          );
        }
      }

      // 3. 项目检测推荐
      if (projectPath != null && platformDetector != null) {
        final detectedValue = await _getDetectedValue(parameter, projectPath);
        if (detectedValue != null) {
          recommendations.add(
            ParameterRecommendation(
              value: detectedValue,
              source: RecommendationSource.projectDetection,
              confidence: 0.7,
              description: '基于项目检测',
            ),
          );
        }
      }

      // 4. 默认值推荐
      if (parameter.defaultValue != null) {
        recommendations.add(
          ParameterRecommendation(
            value: parameter.defaultValue,
            source: RecommendationSource.defaultValue,
            confidence: 0.5,
            description: '参数默认值',
          ),
        );
      }

      // 按置信度排序并限制数量
      recommendations.sort((a, b) => b.confidence.compareTo(a.confidence));
      session.recommendations[parameter.name] =
          recommendations.take(maxRecommendations).toList();
    }
  }

  /// 自动填充参数
  Future<void> _autoFillParameters(
    ParameterCollectionSession session,
    String? projectPath,
  ) async {
    for (final parameter in session.parameters) {
      if (session.collectedValues.containsKey(parameter.name)) {
        continue; // 已有值，跳过
      }

      final recommendations = session.recommendations[parameter.name] ?? [];
      if (recommendations.isNotEmpty) {
        final bestRecommendation = recommendations.first;

        // 只有高置信度的推荐才自动填充
        if (bestRecommendation.confidence >= 0.8) {
          session.collectedValues[parameter.name] = bestRecommendation.value;
          cli_logger.Logger.debug(
            '自动填充参数: ${parameter.name} = ${bestRecommendation.value}',
          );
        }
      }
    }
  }

  /// 从环境变量获取值
  String? _getEnvironmentValue(String parameterName) {
    // 尝试多种环境变量命名格式
    final envNames = [
      parameterName.toUpperCase(),
      parameterName.toUpperCase().replaceAll('.', '_'),
      'MING_${parameterName.toUpperCase()}',
      'MING_${parameterName.toUpperCase().replaceAll('.', '_')}',
    ];

    for (final envName in envNames) {
      final value = Platform.environment[envName];
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  /// 从配置文件获取值
  Future<dynamic> _getConfigFileValue(
      String projectPath, String parameterName) async {
    final configFiles = [
      'ming.config.json',
      'ming.config.yaml',
      'package.json',
      'pubspec.yaml',
    ];

    for (final configFile in configFiles) {
      final file = File('$projectPath/$configFile');
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          Map<String, dynamic> config;

          if (configFile.endsWith('.json')) {
            config = json.decode(content) as Map<String, dynamic>;
          } else if (configFile.endsWith('.yaml')) {
            // 简化的YAML解析，实际应用中应使用yaml包
            continue;
          } else {
            continue;
          }

          // 查找参数值
          final value = _findValueInConfig(config, parameterName);
          if (value != null) {
            return value;
          }
        } catch (e) {
          // 忽略配置文件解析错误
        }
      }
    }

    return null;
  }

  /// 基于项目检测获取值
  Future<dynamic> _getDetectedValue(
    EnterpriseTemplateParameter parameter,
    String projectPath,
  ) async {
    if (platformDetector == null) return null;

    try {
      final platformResult = await platformDetector!.detectPlatform(
        projectPath: projectPath,
      );

      switch (parameter.enterpriseType) {
        case EnterpriseParameterType.environment:
          return platformResult.environment.name;

        case EnterpriseParameterType.organization:
          // 从Git配置获取组织信息
          return await _getGitOrganization(projectPath);

        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// 在配置中查找值
  dynamic _findValueInConfig(
      Map<String, dynamic> config, String parameterName) {
    // 直接查找
    if (config.containsKey(parameterName)) {
      return config[parameterName];
    }

    // 查找嵌套值
    final parts = parameterName.split('.');
    dynamic current = config;

    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current;
  }

  /// 获取Git组织信息
  Future<String?> _getGitOrganization(String projectPath) async {
    try {
      final result = await Process.run(
        'git',
        ['config', '--get', 'remote.origin.url'],
        workingDirectory: projectPath,
      );

      if (result.exitCode == 0) {
        final url = result.stdout.toString().trim();
        final match = RegExp(r'github\.com[:/]([^/]+)/').firstMatch(url);
        return match?.group(1);
      }
    } catch (e) {
      // 忽略Git命令错误
    }

    return null;
  }

  /// 生成步骤标题
  String _generateStepTitle(String groupName) {
    switch (groupName.toLowerCase()) {
      case 'general':
        return '基本信息';
      case 'project':
        return '项目配置';
      case 'database':
        return '数据库配置';
      case 'auth':
      case 'authentication':
        return '认证配置';
      case 'deployment':
        return '部署配置';
      case 'security':
        return '安全配置';
      default:
        return groupName.substring(0, 1).toUpperCase() + groupName.substring(1);
    }
  }

  /// 生成步骤描述
  String _generateStepDescription(
      String groupName, List<EnterpriseTemplateParameter> parameters) {
    return '配置${_generateStepTitle(groupName)}相关的${parameters.length}个参数';
  }
}
