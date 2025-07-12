/*
---------------------------------------------------------------
File name:          ml_models.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        机器学习模型 (Machine Learning Models)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 企业级模板配置管理系统;
---------------------------------------------------------------
*/

import 'dart:math';

import 'package:ming_status_cli/src/core/configuration_management/models/configuration_set.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/test_result.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/version_info.dart';

/// 特征向量
class FeatureVector {
  const FeatureVector(this.features, {this.metadata = const {}});
  final List<double> features;
  final Map<String, dynamic> metadata;

  /// 归一化特征向量
  FeatureVector normalize() {
    final maxValue = features.reduce(max);
    final minValue = features.reduce(min);
    final range = maxValue - minValue;

    if (range == 0) return this;

    final normalizedFeatures =
        features.map((f) => (f - minValue) / range).toList();

    return FeatureVector(normalizedFeatures, metadata: metadata);
  }

  /// 计算与另一个向量的距离
  double distanceTo(FeatureVector other) {
    if (features.length != other.features.length) {
      throw ArgumentError('Feature vectors must have the same length');
    }

    double sum = 0;
    for (var i = 0; i < features.length; i++) {
      final diff = features[i] - other.features[i];
      sum += diff * diff;
    }

    return sqrt(sum);
  }

  /// 点积
  double dotProduct(FeatureVector other) {
    if (features.length != other.features.length) {
      throw ArgumentError('Feature vectors must have the same length');
    }

    double sum = 0;
    for (var i = 0; i < features.length; i++) {
      sum += features[i] * other.features[i];
    }

    return sum;
  }
}

/// 线性回归模型
class LinearRegressionModel {
  List<double> _weights = [];
  double _bias = 0;
  bool _isTrained = false;

  /// 训练模型
  void train(
    List<FeatureVector> trainingData,
    List<double> targets, {
    double learningRate = 0.01,
    int epochs = 1000,
    double tolerance = 1e-6,
  }) {
    if (trainingData.isEmpty) return;

    final featureCount = trainingData.first.features.length;
    _weights = List.filled(featureCount, 0);
    _bias = 0.0;

    // 梯度下降训练
    for (var epoch = 0; epoch < epochs; epoch++) {
      var totalLoss = 0.0;
      final gradients = List.filled(featureCount, 0.0);
      var biasGradient = 0.0;

      // 计算梯度
      for (var i = 0; i < trainingData.length; i++) {
        final features = trainingData[i].features;
        final target = targets[i];
        final prediction = _predict(features);
        final error = prediction - target;

        totalLoss += error * error;

        // 更新梯度
        for (var j = 0; j < featureCount; j++) {
          gradients[j] += error * features[j];
        }
        biasGradient += error;
      }

      // 更新权重
      for (var j = 0; j < featureCount; j++) {
        _weights[j] -= learningRate * gradients[j] / trainingData.length;
      }
      _bias -= learningRate * biasGradient / trainingData.length;

      // 检查收敛
      final avgLoss = totalLoss / trainingData.length;
      if (avgLoss < tolerance) break;
    }

    _isTrained = true;
  }

  /// 预测
  double predict(FeatureVector input) {
    if (!_isTrained) {
      throw StateError('Model must be trained before prediction');
    }

    return _predict(input.features);
  }

  /// 内部预测方法
  double _predict(List<double> features) {
    var sum = _bias;
    for (var i = 0; i < features.length; i++) {
      sum += _weights[i] * features[i];
    }
    return sum;
  }

  /// 获取特征重要性
  Map<int, double> getFeatureImportance() {
    if (!_isTrained) return {};

    final importance = <int, double>{};
    for (var i = 0; i < _weights.length; i++) {
      importance[i] = _weights[i].abs();
    }

    return importance;
  }
}

/// 决策树节点
class DecisionTreeNode {
  int? featureIndex;
  double? threshold;
  double? value;
  DecisionTreeNode? left;
  DecisionTreeNode? right;

  bool get isLeaf => value != null;

  double predict(List<double> features) {
    if (isLeaf) return value!;

    if (features[featureIndex!] <= threshold!) {
      return left!.predict(features);
    } else {
      return right!.predict(features);
    }
  }
}

/// 决策树模型
class DecisionTreeModel {
  DecisionTreeModel({
    int maxDepth = 10,
    int minSamplesLeaf = 5,
  })  : _maxDepth = maxDepth,
        _minSamplesLeaf = minSamplesLeaf;
  DecisionTreeNode? _root;
  final int _maxDepth;
  final int _minSamplesLeaf;

  /// 训练决策树
  void train(List<FeatureVector> trainingData, List<double> targets) {
    if (trainingData.isEmpty) return;

    final indices = List.generate(trainingData.length, (i) => i);
    _root = _buildTree(trainingData, targets, indices, 0);
  }

  /// 预测
  double predict(FeatureVector input) {
    if (_root == null) {
      throw StateError('Model must be trained before prediction');
    }

    return _root!.predict(input.features);
  }

  /// 构建决策树
  DecisionTreeNode _buildTree(
    List<FeatureVector> data,
    List<double> targets,
    List<int> indices,
    int depth,
  ) {
    // 停止条件
    if (depth >= _maxDepth ||
        indices.length <= _minSamplesLeaf ||
        _isPure(targets, indices)) {
      return DecisionTreeNode()..value = _calculateMean(targets, indices);
    }

    // 寻找最佳分割
    final bestSplit = _findBestSplit(data, targets, indices);
    if (bestSplit == null) {
      return DecisionTreeNode()..value = _calculateMean(targets, indices);
    }

    // 创建节点
    final node = DecisionTreeNode()
      ..featureIndex = bestSplit['featureIndex'] as int
      ..threshold = bestSplit['threshold'] as double;

    final leftIndices = bestSplit['leftIndices'] as List<int>;
    final rightIndices = bestSplit['rightIndices'] as List<int>;

    // 递归构建子树
    node.left = _buildTree(data, targets, leftIndices, depth + 1);
    node.right = _buildTree(data, targets, rightIndices, depth + 1);

    return node;
  }

  /// 寻找最佳分割
  Map<String, dynamic>? _findBestSplit(
    List<FeatureVector> data,
    List<double> targets,
    List<int> indices,
  ) {
    var bestGain = 0.0;
    Map<String, dynamic>? bestSplit;

    final featureCount = data.first.features.length;

    for (var featureIndex = 0; featureIndex < featureCount; featureIndex++) {
      final values = indices
          .map((i) => data[i].features[featureIndex])
          .toSet()
          .toList()
        ..sort();

      for (var i = 0; i < values.length - 1; i++) {
        final threshold = (values[i] + values[i + 1]) / 2;

        final leftIndices = <int>[];
        final rightIndices = <int>[];

        for (final index in indices) {
          if (data[index].features[featureIndex] <= threshold) {
            leftIndices.add(index);
          } else {
            rightIndices.add(index);
          }
        }

        if (leftIndices.isEmpty || rightIndices.isEmpty) continue;

        final gain = _calculateInformationGain(
          targets,
          indices,
          leftIndices,
          rightIndices,
        );

        if (gain > bestGain) {
          bestGain = gain;
          bestSplit = {
            'featureIndex': featureIndex,
            'threshold': threshold,
            'leftIndices': leftIndices,
            'rightIndices': rightIndices,
          };
        }
      }
    }

    return bestSplit;
  }

  /// 计算信息增益
  double _calculateInformationGain(
    List<double> targets,
    List<int> parentIndices,
    List<int> leftIndices,
    List<int> rightIndices,
  ) {
    final parentVariance = _calculateVariance(targets, parentIndices);
    final leftVariance = _calculateVariance(targets, leftIndices);
    final rightVariance = _calculateVariance(targets, rightIndices);

    final leftWeight = leftIndices.length / parentIndices.length;
    final rightWeight = rightIndices.length / parentIndices.length;

    return parentVariance -
        (leftWeight * leftVariance + rightWeight * rightVariance);
  }

  /// 计算方差
  double _calculateVariance(List<double> targets, List<int> indices) {
    if (indices.isEmpty) return 0;

    final mean = _calculateMean(targets, indices);
    var sum = 0.0;

    for (final index in indices) {
      final diff = targets[index] - mean;
      sum += diff * diff;
    }

    return sum / indices.length;
  }

  /// 计算均值
  double _calculateMean(List<double> targets, List<int> indices) {
    if (indices.isEmpty) return 0;

    var sum = 0.0;
    for (final index in indices) {
      sum += targets[index];
    }

    return sum / indices.length;
  }

  /// 检查是否为纯节点
  bool _isPure(List<double> targets, List<int> indices) {
    if (indices.isEmpty) return true;

    final firstValue = targets[indices.first];
    return indices.every((index) => targets[index] == firstValue);
  }
}

/// 集成学习模型
class EnsembleModel {
  final List<LinearRegressionModel> _linearModels = [];
  final List<DecisionTreeModel> _treeModels = [];
  final List<double> _modelWeights = [];

  /// 训练集成模型
  void train(
    List<FeatureVector> trainingData,
    List<double> targets, {
    int numLinearModels = 3,
    int numTreeModels = 3,
  }) {
    _linearModels.clear();
    _treeModels.clear();
    _modelWeights.clear();

    final random = Random();

    // 训练线性模型
    for (var i = 0; i < numLinearModels; i++) {
      final model = LinearRegressionModel();
      final bootstrapData = _bootstrap(trainingData, targets, random);

      model.train(
        bootstrapData['data']! as List<FeatureVector>,
        bootstrapData['targets']! as List<double>,
      );

      _linearModels.add(model);
      _modelWeights.add(1); // 初始权重
    }

    // 训练决策树模型
    for (var i = 0; i < numTreeModels; i++) {
      final model = DecisionTreeModel(
        maxDepth: 8 + random.nextInt(5),
        minSamplesLeaf: 3 + random.nextInt(5),
      );

      final bootstrapData = _bootstrap(trainingData, targets, random);

      model.train(
        bootstrapData['data']! as List<FeatureVector>,
        bootstrapData['targets']! as List<double>,
      );

      _treeModels.add(model);
      _modelWeights.add(1); // 初始权重
    }

    // 计算模型权重（基于验证集性能）
    _calculateModelWeights(trainingData, targets);
  }

  /// 预测
  double predict(FeatureVector input) {
    var weightedSum = 0.0;
    var totalWeight = 0.0;

    // 线性模型预测
    for (var i = 0; i < _linearModels.length; i++) {
      final prediction = _linearModels[i].predict(input);
      final weight = _modelWeights[i];
      weightedSum += prediction * weight;
      totalWeight += weight;
    }

    // 决策树模型预测
    for (var i = 0; i < _treeModels.length; i++) {
      final prediction = _treeModels[i].predict(input);
      final weight = _modelWeights[_linearModels.length + i];
      weightedSum += prediction * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  /// Bootstrap采样
  Map<String, List> _bootstrap(
    List<FeatureVector> data,
    List<double> targets,
    Random random,
  ) {
    final bootstrapData = <FeatureVector>[];
    final bootstrapTargets = <double>[];

    for (var i = 0; i < data.length; i++) {
      final index = random.nextInt(data.length);
      bootstrapData.add(data[index]);
      bootstrapTargets.add(targets[index]);
    }

    return {
      'data': bootstrapData,
      'targets': bootstrapTargets,
    };
  }

  /// 计算模型权重
  void _calculateModelWeights(
    List<FeatureVector> validationData,
    List<double> validationTargets,
  ) {
    // 简化的权重计算 - 基于验证集误差
    for (var i = 0; i < _linearModels.length; i++) {
      final error = _calculateModelError(
        _linearModels[i].predict,
        validationData,
        validationTargets,
      );
      _modelWeights[i] = 1.0 / (1.0 + error);
    }

    for (var i = 0; i < _treeModels.length; i++) {
      final error = _calculateModelError(
        _treeModels[i].predict,
        validationData,
        validationTargets,
      );
      _modelWeights[_linearModels.length + i] = 1.0 / (1.0 + error);
    }
  }

  /// 计算模型误差
  double _calculateModelError(
    double Function(FeatureVector) predictor,
    List<FeatureVector> data,
    List<double> targets,
  ) {
    var totalError = 0.0;

    for (var i = 0; i < data.length; i++) {
      final prediction = predictor(data[i]);
      final error = (prediction - targets[i]).abs();
      totalError += error;
    }

    return data.isNotEmpty ? totalError / data.length : double.infinity;
  }
}

/// 配置成功率预测器
class ConfigurationSuccessPredictor {
  final EnsembleModel _model = EnsembleModel();
  bool _isTrained = false;

  /// 训练预测器
  void train(List<TestResult> historicalResults) {
    if (historicalResults.isEmpty) return;

    final trainingData = <FeatureVector>[];
    final targets = <double>[];

    for (final result in historicalResults) {
      final features = _extractFeatures(result.configurationSet);
      trainingData.add(features);
      targets.add(result.isSuccess ? 1.0 : 0.0);
    }

    _model.train(trainingData, targets);
    _isTrained = true;
  }

  /// 预测配置成功率
  double predictSuccessRate(ConfigurationSet config) {
    if (!_isTrained) return 0.5; // 默认成功率

    final features = _extractFeatures(config);
    return _model.predict(features).clamp(0.0, 1.0);
  }

  /// 提取特征
  FeatureVector _extractFeatures(ConfigurationSet config) {
    final features = <double>[
      // 基本特征
      config.complexity.toDouble(),
      config.calculateStabilityScore(),
      config.calculateFreshnessScore(),
      config.priority,

      // 依赖特征
      config.coreDependencies.length.toDouble(),
      config.essentialDependencies.length.toDouble(),
      config.optionalDependencies.length.toDouble(),
      config.devDependencies.length.toDouble(),

      // 版本特征
      _calculateAverageVersionAge(config),
      _calculatePreReleaseRatio(config),
      _calculateMajorVersionSpread(config),

      // 流行度特征
      _calculateAveragePopularity(config),
      _calculateDownloadCountScore(config),

      // 兼容性特征
      _calculateCompatibilityScore(config),
      _calculateConflictRisk(config),
    ];

    return FeatureVector(
      features,
      metadata: {
        'configId': config.id,
        'configName': config.name,
      },
    );
  }

  /// 计算平均版本年龄
  double _calculateAverageVersionAge(ConfigurationSet config) {
    final versions = config.allDependencies.values;
    if (versions.isEmpty) return 0;

    final now = DateTime.now();
    final ages = versions.map((v) => now.difference(v.publishedAt).inDays);
    return ages.reduce((a, b) => a + b) / ages.length;
  }

  /// 计算预发布版本比例
  double _calculatePreReleaseRatio(ConfigurationSet config) {
    final versions = config.allDependencies.values;
    if (versions.isEmpty) return 0;

    final preReleaseCount = versions.where((v) => v.isPrerelease).length;
    return preReleaseCount / versions.length;
  }

  /// 计算主版本分散度
  double _calculateMajorVersionSpread(ConfigurationSet config) {
    final versions = config.allDependencies.values;
    if (versions.isEmpty) return 0;

    final majorVersions = versions.map((v) => v.version.major).toSet();
    return majorVersions.length.toDouble();
  }

  /// 计算平均流行度
  double _calculateAveragePopularity(ConfigurationSet config) {
    // 简化实现 - 实际应该从真实数据获取
    return 0.5;
  }

  /// 计算下载量评分
  double _calculateDownloadCountScore(ConfigurationSet config) {
    final versions = config.allDependencies.values;
    if (versions.isEmpty) return 0;

    final downloadCounts =
        versions.map((v) => v.downloadCount ?? 0).where((count) => count > 0);

    if (downloadCounts.isEmpty) return 0;

    final avgDownloads =
        downloadCounts.reduce((a, b) => a + b) / downloadCounts.length;
    return (log(avgDownloads + 1) / log(1000000)).clamp(0.0, 1.0);
  }

  /// 计算兼容性评分
  double _calculateCompatibilityScore(ConfigurationSet config) {
    final versions = config.allDependencies.values.toList();
    if (versions.length < 2) return 1;

    var compatiblePairs = 0;
    var totalPairs = 0;

    for (var i = 0; i < versions.length; i++) {
      for (var j = i + 1; j < versions.length; j++) {
        totalPairs++;
        if (versions[i].isCompatibleWith(versions[j])) {
          compatiblePairs++;
        }
      }
    }

    return totalPairs > 0 ? compatiblePairs / totalPairs : 1.0;
  }

  /// 计算冲突风险
  double _calculateConflictRisk(ConfigurationSet config) {
    // 基于已知的冲突模式计算风险
    const riskPatterns = {
      'mockito': ['mocktail'],
      'provider': ['riverpod'],
      'bloc': ['riverpod'],
    };

    final packages = config.allDependencies.keys.toSet();
    var riskScore = 0.0;

    for (final entry in riskPatterns.entries) {
      final package = entry.key;
      final conflicts = entry.value;

      if (packages.contains(package)) {
        for (final conflict in conflicts) {
          if (packages.contains(conflict)) {
            riskScore += 1.0;
          }
        }
      }
    }

    return riskScore / packages.length;
  }
}
