/*
---------------------------------------------------------------
File name:          condition_evaluator.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级条件求值器 (Enterprise Condition Evaluator)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 条件表达式求值系统;
---------------------------------------------------------------
*/

import 'dart:math';

import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 求值结果
///
/// 包含条件求值的结果信息
class EvaluationResult {
  /// 创建求值结果实例
  const EvaluationResult({
    required this.success,
    this.value,
    this.errors = const [],
    this.warnings = const [],
  });

  /// 创建成功结果
  factory EvaluationResult.success({
    required dynamic value,
    List<String> warnings = const [],
  }) {
    return EvaluationResult(
      success: true,
      value: value,
      warnings: warnings,
    );
  }

  /// 创建失败结果
  factory EvaluationResult.failure({
    required List<String> errors,
    List<String> warnings = const [],
  }) {
    return EvaluationResult(
      success: false,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 是否成功
  final bool success;

  /// 求值结果
  final dynamic value;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;
}

/// 操作符类型
///
/// 定义支持的操作符类型
enum OperatorType {
  // 逻辑运算符
  and,
  or,
  not,
  xor,

  // 比较运算符
  equal,
  notEqual,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,

  // 字符串运算符
  contains,
  startsWith,
  endsWith,
  matches, // 正则表达式

  // 数组运算符
  includes,
  length,

  // 算术运算符
  add,
  subtract,
  multiply,
  divide,
  modulo,
}

/// 表达式节点
///
/// 表示表达式树中的一个节点
abstract class ExpressionNode {
  /// 求值
  Future<EvaluationResult> evaluate(Map<String, dynamic> variables);
}

/// 字面量节点
///
/// 表示字面量值 (字符串、数字、布尔值等)
class LiteralNode extends ExpressionNode {
  /// 创建字面量节点实例
  LiteralNode(this.value);

  /// 字面量值
  final dynamic value;

  @override
  Future<EvaluationResult> evaluate(Map<String, dynamic> variables) async {
    return EvaluationResult.success(value: value);
  }
}

/// 变量节点
///
/// 表示变量引用
class VariableNode extends ExpressionNode {
  /// 创建变量节点实例
  VariableNode(this.path);

  /// 变量路径 (支持点号分隔)
  final String path;

  @override
  Future<EvaluationResult> evaluate(Map<String, dynamic> variables) async {
    final value = _getVariableValue(path, variables);
    if (value == null && !_hasVariable(path, variables)) {
      return EvaluationResult.failure(
        errors: ['变量未定义: $path'],
      );
    }
    return EvaluationResult.success(value: value);
  }

  /// 获取变量值
  dynamic _getVariableValue(String path, Map<String, dynamic> variables) {
    final parts = path.split('.');
    dynamic current = variables;

    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current;
  }

  /// 检查变量是否存在
  bool _hasVariable(String path, Map<String, dynamic> variables) {
    final parts = path.split('.');
    dynamic current = variables;

    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return false;
      }
    }

    return true;
  }
}

/// 二元操作节点
///
/// 表示二元操作 (如 a + b, a > b 等)
class BinaryOperationNode extends ExpressionNode {
  /// 创建二元操作节点实例
  BinaryOperationNode({
    required this.left,
    required this.operator,
    required this.right,
  });

  /// 左操作数
  final ExpressionNode left;

  /// 操作符
  final OperatorType operator;

  /// 右操作数
  final ExpressionNode right;

  @override
  Future<EvaluationResult> evaluate(Map<String, dynamic> variables) async {
    final leftResult = await left.evaluate(variables);
    if (!leftResult.success) {
      return leftResult;
    }

    final rightResult = await right.evaluate(variables);
    if (!rightResult.success) {
      return rightResult;
    }

    try {
      final result = _performOperation(
        leftResult.value,
        operator,
        rightResult.value,
      );
      return EvaluationResult.success(value: result);
    } catch (e) {
      return EvaluationResult.failure(
        errors: ['操作执行失败: $e'],
      );
    }
  }

  /// 执行操作
  dynamic _performOperation(
    dynamic left,
    OperatorType operator,
    dynamic right,
  ) {
    switch (operator) {
      // 逻辑运算符
      case OperatorType.and:
        return _toBool(left) && _toBool(right);
      case OperatorType.or:
        return _toBool(left) || _toBool(right);
      case OperatorType.not:
        // NOT是一元操作符，在二元操作中不应该出现
        throw ArgumentError('NOT是一元操作符，不能用于二元操作');
      case OperatorType.xor:
        return _toBool(left) != _toBool(right);

      // 比较运算符
      case OperatorType.equal:
        return left == right;
      case OperatorType.notEqual:
        return left != right;
      case OperatorType.greaterThan:
        return _compareNumbers(left, right) > 0;
      case OperatorType.lessThan:
        return _compareNumbers(left, right) < 0;
      case OperatorType.greaterThanOrEqual:
        return _compareNumbers(left, right) >= 0;
      case OperatorType.lessThanOrEqual:
        return _compareNumbers(left, right) <= 0;

      // 字符串运算符
      case OperatorType.contains:
        return left.toString().contains(right.toString());
      case OperatorType.startsWith:
        return left.toString().startsWith(right.toString());
      case OperatorType.endsWith:
        return left.toString().endsWith(right.toString());
      case OperatorType.matches:
        return RegExp(right.toString()).hasMatch(left.toString());

      // 数组运算符
      case OperatorType.includes:
        return left is List && left.contains(right);
      case OperatorType.length:
        if (left is List) return left.length;
        if (left is String) return left.length;
        if (left is Map) return left.length;
        return 0;

      // 算术运算符
      case OperatorType.add:
        return _toNumber(left) + _toNumber(right);
      case OperatorType.subtract:
        return _toNumber(left) - _toNumber(right);
      case OperatorType.multiply:
        return _toNumber(left) * _toNumber(right);
      case OperatorType.divide:
        final rightNum = _toNumber(right);
        if (rightNum == 0) throw ArgumentError('除零错误');
        return _toNumber(left) / rightNum;
      case OperatorType.modulo:
        return _toNumber(left) % _toNumber(right);
    }
  }

  /// 转换为布尔值
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return value != null;
  }

  /// 转换为数字
  num _toNumber(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// 比较数字
  int _compareNumbers(dynamic left, dynamic right) {
    final leftNum = _toNumber(left);
    final rightNum = _toNumber(right);
    return leftNum.compareTo(rightNum);
  }
}

/// 一元操作节点
///
/// 表示一元操作 (如 !a, -a 等)
class UnaryOperationNode extends ExpressionNode {
  /// 创建一元操作节点实例
  UnaryOperationNode({
    required this.operator,
    required this.operand,
  });

  /// 操作符
  final OperatorType operator;

  /// 操作数
  final ExpressionNode operand;

  @override
  Future<EvaluationResult> evaluate(Map<String, dynamic> variables) async {
    final operandResult = await operand.evaluate(variables);
    if (!operandResult.success) {
      return operandResult;
    }

    try {
      final result = _performUnaryOperation(operator, operandResult.value);
      return EvaluationResult.success(value: result);
    } catch (e) {
      return EvaluationResult.failure(
        errors: ['一元操作执行失败: $e'],
      );
    }
  }

  /// 执行一元操作
  dynamic _performUnaryOperation(OperatorType operator, dynamic operand) {
    switch (operator) {
      case OperatorType.not:
        return !_toBool(operand);
      case OperatorType.and:
      case OperatorType.or:
      case OperatorType.xor:
      case OperatorType.equal:
      case OperatorType.notEqual:
      case OperatorType.greaterThan:
      case OperatorType.lessThan:
      case OperatorType.greaterThanOrEqual:
      case OperatorType.lessThanOrEqual:
      case OperatorType.contains:
      case OperatorType.startsWith:
      case OperatorType.endsWith:
      case OperatorType.matches:
      case OperatorType.includes:
      case OperatorType.length:
      case OperatorType.add:
      case OperatorType.subtract:
      case OperatorType.multiply:
      case OperatorType.divide:
      case OperatorType.modulo:
        throw ArgumentError('$operator 是二元操作符，不能用于一元操作');
    }
  }

  /// 转换为布尔值
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return value != null;
  }
}

/// 函数调用节点
///
/// 表示函数调用 (如 version_gte("3.0.0"))
class FunctionCallNode extends ExpressionNode {
  /// 创建函数调用节点实例
  FunctionCallNode({
    required this.functionName,
    required this.arguments,
  });

  /// 函数名
  final String functionName;

  /// 参数列表
  final List<ExpressionNode> arguments;

  @override
  Future<EvaluationResult> evaluate(Map<String, dynamic> variables) async {
    // 求值所有参数
    final argValues = <dynamic>[];
    for (final arg in arguments) {
      final argResult = await arg.evaluate(variables);
      if (!argResult.success) {
        return argResult;
      }
      argValues.add(argResult.value);
    }

    try {
      final result = _callBuiltinFunction(functionName, argValues);
      return EvaluationResult.success(value: result);
    } catch (e) {
      return EvaluationResult.failure(
        errors: ['函数调用失败: $functionName - $e'],
      );
    }
  }

  /// 调用内置函数
  dynamic _callBuiltinFunction(String name, List<dynamic> args) {
    switch (name) {
      case 'version_gte':
        if (args.length != 2) throw ArgumentError('version_gte需要2个参数');
        return _compareVersions(args[0].toString(), args[1].toString()) >= 0;

      case 'version_lt':
        if (args.length != 2) throw ArgumentError('version_lt需要2个参数');
        return _compareVersions(args[0].toString(), args[1].toString()) < 0;

      case 'length':
        if (args.isEmpty) throw ArgumentError('length需要1个参数');
        final value = args[0];
        if (value is List) return value.length;
        if (value is String) return value.length;
        if (value is Map) return value.length;
        return 0;

      case 'empty':
        if (args.isEmpty) throw ArgumentError('empty需要1个参数');
        final value = args[0];
        if (value is List) return value.isEmpty;
        if (value is String) return value.isEmpty;
        if (value is Map) return value.isEmpty;
        return value == null;

      case 'max':
        if (args.isEmpty) throw ArgumentError('max需要至少1个参数');
        return args.map(_toNumber).reduce(max);

      case 'min':
        if (args.isEmpty) throw ArgumentError('min需要至少1个参数');
        return args.map(_toNumber).reduce(min);

      // 平台检测函数
      case 'platform_is':
        if (args.length != 2) throw ArgumentError('platform_is需要2个参数');
        return _checkPlatform(args[0], args[1].toString());

      case 'framework_is':
        if (args.length != 2) throw ArgumentError('framework_is需要2个参数');
        return _checkFramework(args[0], args[1].toString());

      case 'environment_is':
        if (args.length != 2) throw ArgumentError('environment_is需要2个参数');
        return _checkEnvironment(args[0], args[1].toString());

      // 功能检测函数
      case 'has_feature':
        if (args.length != 2) throw ArgumentError('has_feature需要2个参数');
        return _checkFeature(args[0], args[1].toString());

      case 'has_integration':
        if (args.length != 2) throw ArgumentError('has_integration需要2个参数');
        return _checkIntegration(args[0], args[1].toString());

      case 'team_size_gte':
        if (args.length != 2) throw ArgumentError('team_size_gte需要2个参数');
        return _checkTeamSize(args[0], args[1].toString());

      case 'complexity_gte':
        if (args.length != 2) throw ArgumentError('complexity_gte需要2个参数');
        return _checkComplexity(args[0], args[1].toString());

      // 逻辑组合函数
      case 'and':
        return args.every(_toBool);

      case 'or':
        return args.any(_toBool);

      case 'not':
        if (args.length != 1) throw ArgumentError('not需要1个参数');
        return !_toBool(args[0]);

      // 数组操作函数
      case 'includes':
        if (args.length != 2) throw ArgumentError('includes需要2个参数');
        return args[0] is List && (args[0] as List).contains(args[1]);

      case 'any':
        if (args.length != 2) throw ArgumentError('any需要2个参数');
        final list = args[0];
        final condition = args[1];
        if (list is! List) return false;
        return list.any((item) => _matchesCondition(item, condition));

      case 'all':
        if (args.length != 2) throw ArgumentError('all需要2个参数');
        final list = args[0];
        final condition = args[1];
        if (list is! List) return false;
        return list.every((item) => _matchesCondition(item, condition));

      default:
        throw ArgumentError('未知函数: $name');
    }
  }

  /// 比较版本号
  int _compareVersions(String version1, String version2) {
    final parts1 = version1.split('.').map(int.parse).toList();
    final parts2 = version2.split('.').map(int.parse).toList();

    final maxLength = max(parts1.length, parts2.length);

    for (var i = 0; i < maxLength; i++) {
      final part1 = i < parts1.length ? parts1[i] : 0;
      final part2 = i < parts2.length ? parts2[i] : 0;

      if (part1 != part2) {
        return part1.compareTo(part2);
      }
    }

    return 0;
  }

  /// 转换为数字
  num _toNumber(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// 检查平台
  bool _checkPlatform(dynamic platformData, String expectedPlatform) {
    if (platformData is Map) {
      final primaryPlatform = platformData['primaryPlatform']?.toString();
      final webPlatform = platformData['webPlatform']?.toString();
      final mobilePlatform = platformData['mobilePlatform']?.toString();
      final desktopPlatform = platformData['desktopPlatform']?.toString();

      return primaryPlatform == expectedPlatform ||
          webPlatform == expectedPlatform ||
          mobilePlatform == expectedPlatform ||
          desktopPlatform == expectedPlatform;
    }
    return platformData.toString() == expectedPlatform;
  }

  /// 检查框架
  bool _checkFramework(dynamic frameworkData, String expectedFramework) {
    if (frameworkData is Map) {
      final framework = frameworkData['framework']?.toString();
      return framework == expectedFramework;
    }
    return frameworkData.toString() == expectedFramework;
  }

  /// 检查环境
  bool _checkEnvironment(dynamic environmentData, String expectedEnvironment) {
    if (environmentData is Map) {
      final environment = environmentData['environment']?.toString();
      return environment == expectedEnvironment;
    }
    return environmentData.toString() == expectedEnvironment;
  }

  /// 检查功能
  bool _checkFeature(dynamic featureData, String expectedFeature) {
    if (featureData is Map) {
      final features = featureData['techStackFeatures'];
      if (features is List) {
        return features.contains(expectedFeature);
      }
    }
    if (featureData is List) {
      return featureData.contains(expectedFeature);
    }
    return false;
  }

  /// 检查集成
  bool _checkIntegration(dynamic integrationData, String expectedIntegration) {
    if (integrationData is Map) {
      final integrations = integrationData['thirdPartyIntegrations'];
      if (integrations is List) {
        return integrations.contains(expectedIntegration);
      }
    }
    if (integrationData is List) {
      return integrationData.contains(expectedIntegration);
    }
    return false;
  }

  /// 检查团队规模
  bool _checkTeamSize(dynamic teamData, String minSize) {
    final teamSizeOrder = ['solo', 'small', 'medium', 'large', 'enterprise'];

    var currentSize = 'solo';
    if (teamData is Map) {
      currentSize = teamData['teamSize']?.toString() ?? 'solo';
    } else {
      currentSize = teamData.toString();
    }

    final currentIndex = teamSizeOrder.indexOf(currentSize);
    final minIndex = teamSizeOrder.indexOf(minSize);

    return currentIndex >= minIndex;
  }

  /// 检查复杂度
  bool _checkComplexity(dynamic complexityData, String minComplexity) {
    final complexityOrder = ['simple', 'medium', 'complex', 'enterprise'];

    var currentComplexity = 'simple';
    if (complexityData is Map) {
      currentComplexity =
          complexityData['projectComplexity']?.toString() ?? 'simple';
    } else {
      currentComplexity = complexityData.toString();
    }

    final currentIndex = complexityOrder.indexOf(currentComplexity);
    final minIndex = complexityOrder.indexOf(minComplexity);

    return currentIndex >= minIndex;
  }

  /// 检查条件匹配
  bool _matchesCondition(dynamic item, dynamic condition) {
    // 简化的条件匹配实现
    if (condition is String) {
      return item.toString().contains(condition);
    }
    return item == condition;
  }

  /// 转换为布尔值 (FunctionCallNode版本)
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return value != null;
  }
}

/// 企业级条件求值器
///
/// 支持复杂表达式、自定义函数、安全验证
class ConditionEvaluator {
  /// 创建条件求值器实例
  ConditionEvaluator({
    this.enableSafetyCheck = true,
    this.maxExpressionDepth = 20,
  });

  /// 是否启用安全检查
  final bool enableSafetyCheck;

  /// 最大表达式深度
  final int maxExpressionDepth;

  /// 表达式缓存
  final Map<String, ExpressionNode> _expressionCache = {};

  /// 求值表达式
  ///
  /// 解析并求值条件表达式
  Future<EvaluationResult> evaluate(
    String expression,
    Map<String, dynamic> variables,
  ) async {
    try {
      cli_logger.Logger.debug('求值表达式: $expression');

      // 安全检查
      if (enableSafetyCheck && !_isSafeExpression(expression)) {
        return EvaluationResult.failure(
          errors: ['表达式安全检查失败: $expression'],
        );
      }

      // 解析表达式
      final expressionNode = await _parseExpression(expression);

      // 求值
      final result = await expressionNode.evaluate(variables);

      cli_logger.Logger.debug(
        '表达式求值完成: $expression = ${result.value}',
      );

      return result;
    } catch (e) {
      cli_logger.Logger.error('表达式求值失败', error: e);
      return EvaluationResult.failure(
        errors: ['表达式求值异常: $e'],
      );
    }
  }

  /// 解析表达式
  ///
  /// 将字符串表达式解析为表达式树
  Future<ExpressionNode> _parseExpression(String expression) async {
    // 检查缓存
    if (_expressionCache.containsKey(expression)) {
      return _expressionCache[expression]!;
    }

    // 简化的表达式解析 (实际实现需要完整的词法分析和语法分析)
    final node = _parseSimpleExpression(expression.trim());

    // 缓存结果
    _expressionCache[expression] = node;

    return node;
  }

  /// 解析简单表达式
  ExpressionNode _parseSimpleExpression(String expression) {
    // 处理字面量
    if (expression == 'true') return LiteralNode(true);
    if (expression == 'false') return LiteralNode(false);
    if (expression == 'null') return LiteralNode(null);

    // 处理数字
    final number = num.tryParse(expression);
    if (number != null) return LiteralNode(number);

    // 处理字符串 (简化处理)
    if (expression.startsWith('"') && expression.endsWith('"')) {
      return LiteralNode(expression.substring(1, expression.length - 1));
    }

    // 处理变量
    return VariableNode(expression);
  }

  /// 安全检查
  bool _isSafeExpression(String expression) {
    // 检查危险关键词
    final dangerousKeywords = [
      'eval',
      'exec',
      'import',
      'require',
      'process',
      'global',
      'window',
      'document',
      'Function',
      'constructor',
    ];

    for (final keyword in dangerousKeywords) {
      if (expression.contains(keyword)) {
        return false;
      }
    }

    // 检查表达式长度
    if (expression.length > 1000) {
      return false;
    }

    return true;
  }

  /// 清理缓存
  void clearCache() {
    _expressionCache.clear();
    cli_logger.Logger.debug('条件求值器缓存已清理');
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    return {
      'expressionCacheSize': _expressionCache.length,
      'memoryEstimate': _expressionCache.length * 512,
    };
  }
}
