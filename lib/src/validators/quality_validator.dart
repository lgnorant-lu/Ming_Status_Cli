/*
---------------------------------------------------------------
File name:          quality_validator.dart
Author:             Ignorant-lu
Date created:       2025/07/03
Last modified:      2025/07/03
Dart Version:       3.32.4
Description:        代码质量验证器 - 验证代码格式、文档和最佳实践
---------------------------------------------------------------
Change History:
    2025/07/03: Initial creation - 代码质量验证器实现;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/core/validation_system/validator_service.dart';
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:path/path.dart' as path;

/// 代码质量验证器
/// 验证代码格式、文档注释、复杂度和最佳实践
class QualityValidator extends ModuleValidator {
  @override
  String get validatorName => 'quality';

  @override
  List<ValidationType> get supportedTypes => [ValidationType.quality];

  @override
  int get priority => 20;

  @override
  Future<ValidationResult> validate(
    String modulePath,
    ValidationContext context,
  ) async {
    final result = ValidationResult(strictMode: context.strictMode);

    try {
      // Dart静态分析集成 (Task 40.2)
      await _integrateDartAnalyze(result, modulePath);

      // 代码格式验证
      await _validateCodeFormatting(result, modulePath);

      // 文档注释验证
      await _validateDocumentation(result, modulePath);

      // 代码复杂度验证
      await _validateComplexity(result, modulePath);

      // 最佳实践验证
      await _validateBestPractices(result, modulePath);

      // Linter规则验证
      await _validateLinterRules(result, modulePath);

      // 高级代码风格检查 (Task 40.3)
      await _validateAdvancedCodeStyle(result, modulePath);

      // 性能分析建议 (Task 40.3)
      await _validatePerformancePatterns(result, modulePath);
    } catch (e) {
      result.addError(
        '代码质量验证过程发生异常: $e',
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }

    result.markCompleted();
    return result;
  }

  /// 验证代码格式
  Future<void> _validateCodeFormatting(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));
    if (!libDir.existsSync()) return;

    final dartFiles = <File>[];
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity);
      }
    }

    if (dartFiles.isEmpty) {
      result.addWarning(
        '没有找到Dart源文件',
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
      return;
    }

    for (final file in dartFiles) {
      await _validateSingleFileFormatting(result, file, modulePath);
    }
  }

  /// 验证单个文件格式
  Future<void> _validateSingleFileFormatting(
    ValidationResult result,
    File file,
    String modulePath,
  ) async {
    final content = await file.readAsString();
    final lines = content.split('\n');
    final relativePath = path.relative(file.path, from: modulePath);

    // 检查行长度
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.length > 80) {
        result.addWarning(
          '行长度超过80字符',
          file: relativePath,
          line: i + 1,
          validationType: ValidationType.quality,
          validatorName: validatorName,
          fixSuggestion: const FixSuggestion(
            description: '将长行拆分为多行',
            fixabilityLevel: FixabilityLevel.manual,
          ),
        );
      }
    }

    // 检查文件头注释
    if (!content.startsWith('/*') && !content.startsWith('//')) {
      result.addWarning(
        '缺少文件头注释',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    } else {
      result.addSuccess(
        '包含文件头注释',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }

    // 检查导入语句组织
    _validateImportOrganization(result, content, relativePath);
  }

  /// 验证导入语句组织
  void _validateImportOrganization(
    ValidationResult result,
    String content,
    String relativePath,
  ) {
    final lines = content.split('\n');
    final imports = <String>[];
    var importSection = true;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('import ')) {
        if (!importSection) {
          result.addWarning(
            '导入语句应该集中在文件顶部',
            file: relativePath,
            validationType: ValidationType.quality,
            validatorName: validatorName,
          );
          return;
        }
        imports.add(trimmed);
      } else if (trimmed.isNotEmpty &&
          !trimmed.startsWith('//') &&
          !trimmed.startsWith('/*')) {
        importSection = false;
      }
    }

    if (imports.isNotEmpty) {
      // 检查导入顺序
      final dartImports = imports.where((i) => i.contains('dart:')).toList();
      final packageImports =
          imports.where((i) => i.contains('package:')).toList();
      final relativeImports = imports
          .where((i) => !i.contains('dart:') && !i.contains('package:'))
          .toList();

      final expectedOrder = <String>[
        ...dartImports,
        ...packageImports,
        ...relativeImports,
      ];

      if (imports.join() == expectedOrder.join()) {
        result.addSuccess(
          '导入语句顺序正确',
          file: relativePath,
          validationType: ValidationType.quality,
          validatorName: validatorName,
        );
      } else {
        result.addWarning(
          '导入语句顺序不规范 (dart: -> package: -> relative)',
          file: relativePath,
          validationType: ValidationType.quality,
          validatorName: validatorName,
        );
      }
    }
  }

  /// 验证文档注释
  Future<void> _validateDocumentation(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));
    if (!libDir.existsSync()) return;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _validateFileDocumentation(result, entity, modulePath);
      }
    }
  }

  /// 验证文件文档注释
  Future<void> _validateFileDocumentation(
    ValidationResult result,
    File file,
    String modulePath,
  ) async {
    final content = await file.readAsString();
    final relativePath = path.relative(file.path, from: modulePath);

    // 检查公共API文档
    final publicClassRegex = RegExp(r'^class\s+(\w+)', multiLine: true);
    final publicMethodRegex = RegExp(r'^\s*(\w+.*?)\s*\(', multiLine: true);

    var documentedClasses = 0;
    var totalClasses = 0;
    var documentedMethods = 0;
    var totalMethods = 0;

    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // 检查类文档
      if (publicClassRegex.hasMatch(line) && !line.startsWith('_')) {
        totalClasses++;
        if (i > 0 && lines[i - 1].trim().startsWith('///')) {
          documentedClasses++;
        }
      }

      // 检查方法文档
      if (publicMethodRegex.hasMatch(line) &&
          !line.startsWith('_') &&
          !line.contains('get ') &&
          !line.contains('set ')) {
        totalMethods++;
        if (i > 0 && lines[i - 1].trim().startsWith('///')) {
          documentedMethods++;
        }
      }
    }

    // 计算文档覆盖率
    final classDocRate =
        totalClasses > 0 ? documentedClasses / totalClasses : 1.0;
    final methodDocRate =
        totalMethods > 0 ? documentedMethods / totalMethods : 1.0;

    if (classDocRate >= 0.8) {
      result.addSuccess(
        '类文档覆盖率良好: ${(classDocRate * 100).toInt()}%',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    } else {
      result.addWarning(
        '类文档覆盖率偏低: ${(classDocRate * 100).toInt()}%',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }

    if (methodDocRate >= 0.6) {
      result.addSuccess(
        '方法文档覆盖率良好: ${(methodDocRate * 100).toInt()}%',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    } else {
      result.addWarning(
        '方法文档覆盖率偏低: ${(methodDocRate * 100).toInt()}%',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }
  }

  /// 验证代码复杂度
  Future<void> _validateComplexity(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));
    if (!libDir.existsSync()) return;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _validateFileComplexity(result, entity, modulePath);
      }
    }
  }

  /// 验证文件复杂度
  Future<void> _validateFileComplexity(
    ValidationResult result,
    File file,
    String modulePath,
  ) async {
    final content = await file.readAsString();
    final relativePath = path.relative(file.path, from: modulePath);
    final lines = content.split('\n');

    // 检查文件长度
    if (lines.length > 1000) {
      result.addWarning(
        '文件过长 (${lines.length}行)，建议拆分',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    } else if (lines.length > 500) {
      result.addInfo(
        '文件较长 (${lines.length}行)，考虑拆分',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }

    // 检查方法长度
    _validateMethodComplexity(result, content, relativePath);
  }

  /// 验证方法复杂度
  void _validateMethodComplexity(
    ValidationResult result,
    String content,
    String relativePath,
  ) {
    final lines = content.split('\n');
    var inMethod = false;
    var methodStart = 0;
    var braceCount = 0;
    var methodName = '';

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 检测方法开始
      if (RegExp(r'^\s*\w+.*?\(.*?\)\s*\{?').hasMatch(line) && !inMethod) {
        inMethod = true;
        methodStart = i + 1;
        braceCount = line.contains('{') ? 1 : 0;
        methodName = line.trim().split('(')[0].split(' ').last;
      }

      if (inMethod) {
        braceCount += '{'.allMatches(line).length;
        braceCount -= '}'.allMatches(line).length;

        if (braceCount == 0) {
          final methodLength = i - methodStart + 1;
          if (methodLength > 50) {
            result.addWarning(
              '方法 $methodName 过长 ($methodLength行)',
              file: relativePath,
              line: methodStart,
              validationType: ValidationType.quality,
              validatorName: validatorName,
            );
          }
          inMethod = false;
        }
      }
    }
  }

  /// 验证最佳实践
  Future<void> _validateBestPractices(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));
    if (!libDir.existsSync()) return;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _validateFileBestPractices(result, entity, modulePath);
      }
    }
  }

  /// 验证文件最佳实践
  Future<void> _validateFileBestPractices(
    ValidationResult result,
    File file,
    String modulePath,
  ) async {
    final content = await file.readAsString();
    final relativePath = path.relative(file.path, from: modulePath);

    // 检查常见反模式
    final antiPatterns = {
      'print(': '使用日志框架而不是print语句',
      'TODO:': 'TODO注释应该及时处理',
      'FIXME:': 'FIXME注释需要优先处理',
      'throw Exception(': '使用具体的异常类型',
    };

    for (final pattern in antiPatterns.keys) {
      if (content.contains(pattern)) {
        result.addWarning(
          '发现反模式: ${antiPatterns[pattern]}',
          file: relativePath,
          validationType: ValidationType.quality,
          validatorName: validatorName,
        );
      }
    }

    // 检查好的实践
    if (content.contains('const ')) {
      result.addSuccess(
        '使用const关键字优化性能',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }

    if (content.contains('@override')) {
      result.addSuccess(
        '正确使用@override注解',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }
  }

  /// 验证Linter规则
  Future<void> _validateLinterRules(
    ValidationResult result,
    String modulePath,
  ) async {
    final analysisOptionsFile =
        File(path.join(modulePath, 'analysis_options.yaml'));

    if (analysisOptionsFile.existsSync()) {
      result.addSuccess(
        '包含静态分析配置',
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );

      final content = await analysisOptionsFile.readAsString();
      if (content.contains('linter:')) {
        result.addSuccess(
          '启用了linter规则',
          validationType: ValidationType.quality,
          validatorName: validatorName,
        );
      }
    } else {
      result.addWarning(
        '缺少analysis_options.yaml配置文件',
        validationType: ValidationType.quality,
        validatorName: validatorName,
        fixSuggestion: const FixSuggestion(
          description: '创建analysis_options.yaml文件',
          fixabilityLevel: FixabilityLevel.suggested,
        ),
      );
    }
  }

  /// 集成Dart静态分析 (Task 40.2)
  Future<void> _integrateDartAnalyze(
    ValidationResult result,
    String modulePath,
  ) async {
    try {
      // 执行dart analyze命令
      final processResult = await Process.run(
        'dart',
        ['analyze', '--format=json', modulePath],
        workingDirectory: modulePath,
      );

      if (processResult.exitCode == 0) {
        result.addSuccess(
          'Dart静态分析通过',
          validationType: ValidationType.quality,
          validatorName: validatorName,
        );

        // 解析JSON输出
        if (processResult.stdout.toString().isNotEmpty) {
          await _parseDartAnalyzeOutput(
            result,
            processResult.stdout.toString(),
            modulePath,
          );
        }
      } else {
        // 解析分析错误
        await _parseAnalyzeErrors(
          result,
          processResult.stderr.toString(),
          modulePath,
        );
      }
    } catch (e) {
      result.addWarning(
        'Dart静态分析执行失败: $e',
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }
  }

  /// 解析dart analyze JSON输出
  Future<void> _parseDartAnalyzeOutput(
    ValidationResult result,
    String jsonOutput,
    String modulePath,
  ) async {
    try {
      final analyzeData = jsonDecode(jsonOutput);
      if (analyzeData is Map && analyzeData.containsKey('diagnostics')) {
        final diagnostics = analyzeData['diagnostics'] as List;

        for (final diagnostic in diagnostics) {
          final diagnosticMap = diagnostic as Map<String, dynamic>;
          final severity = diagnosticMap['severity'] as String;
          final message = diagnosticMap['message'] as String;
          final location = diagnosticMap['location'] as Map<String, dynamic>?;

          final file = location?['file'] as String?;
          final range = location?['range'] as Map<String, dynamic>?;
          final start = range?['start'] as Map<String, dynamic>?;
          final line = start?['line'] as int?;

          final relativePath =
              file != null ? path.relative(file, from: modulePath) : null;

          switch (severity.toLowerCase()) {
            case 'error':
              result.addError(
                'Dart分析错误: $message',
                file: relativePath,
                line: line,
                validationType: ValidationType.quality,
                validatorName: validatorName,
              );
            case 'warning':
              result.addWarning(
                'Dart分析警告: $message',
                file: relativePath,
                line: line,
                validationType: ValidationType.quality,
                validatorName: validatorName,
              );
            case 'info':
              result.addInfo(
                'Dart分析信息: $message',
                file: relativePath,
                line: line,
                validationType: ValidationType.quality,
                validatorName: validatorName,
              );
          }
        }
      }
    } catch (e) {
      result.addWarning(
        'Dart分析结果解析失败: $e',
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }
  }

  /// 解析分析错误
  Future<void> _parseAnalyzeErrors(
    ValidationResult result,
    String errorOutput,
    String modulePath,
  ) async {
    if (errorOutput.isNotEmpty) {
      // 简单的错误解析，可以根据需要增强
      final lines = errorOutput.split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          result.addError(
            'Dart分析错误: $line',
            validationType: ValidationType.quality,
            validatorName: validatorName,
          );
        }
      }
    }
  }

  /// 高级代码风格检查 (Task 40.3)
  Future<void> _validateAdvancedCodeStyle(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));
    if (!libDir.existsSync()) return;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _validateAdvancedFileStyle(result, entity, modulePath);
      }
    }
  }

  /// 验证单个文件的高级代码风格
  Future<void> _validateAdvancedFileStyle(
    ValidationResult result,
    File file,
    String modulePath,
  ) async {
    final content = await file.readAsString();
    final relativePath = path.relative(file.path, from: modulePath);

    // 检查函数参数风格
    _validateParameterStyle(result, content, relativePath);

    // 检查变量命名风格
    _validateVariableNaming(result, content, relativePath);

    // 检查控制流风格
    _validateControlFlowStyle(result, content, relativePath);

    // 检查异步模式
    _validateAsyncPatterns(result, content, relativePath);
  }

  /// 验证参数风格
  void _validateParameterStyle(
    ValidationResult result,
    String content,
    String relativePath,
  ) {
    // 检查长参数列表
    final longParameterRegex = RegExp(r'\([^)]{100,}\)');
    if (longParameterRegex.hasMatch(content)) {
      result.addWarning(
        '发现过长的参数列表，建议使用参数对象',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
        fixSuggestion: const FixSuggestion(
          description: '使用参数对象或命名参数重构长参数列表',
          fixabilityLevel: FixabilityLevel.manual,
        ),
      );
    }

    // 检查命名参数使用
    final namedParameterRegex = RegExp(r'\{[^}]*\}');
    if (namedParameterRegex.hasMatch(content)) {
      result.addSuccess(
        '正确使用命名参数',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }
  }

  /// 验证变量命名风格
  void _validateVariableNaming(
    ValidationResult result,
    String content,
    String relativePath,
  ) {
    // 检查单字母变量（除了循环变量）
    final singleLetterRegex = RegExp(r'\b(var|final|const)\s+([a-z])\b');
    final matches = singleLetterRegex.allMatches(content);

    for (final match in matches) {
      final varName = match.group(2);
      if (varName != null &&
          !['i', 'j', 'k', 'x', 'y', 'z'].contains(varName)) {
        result.addWarning(
          '避免使用单字母变量名: $varName',
          file: relativePath,
          validationType: ValidationType.quality,
          validatorName: validatorName,
        );
      }
    }

    // 检查魔法数字
    final magicNumberRegex = RegExp(r'\b\d{2,}\b');
    if (magicNumberRegex.hasMatch(content) && !content.contains('const')) {
      result.addInfo(
        '考虑将数字字面量定义为命名常量',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }
  }

  /// 验证控制流风格
  void _validateControlFlowStyle(
    ValidationResult result,
    String content,
    String relativePath,
  ) {
    // 检查深度嵌套
    final lines = content.split('\n');
    var maxIndentLevel = 0;

    for (final line in lines) {
      final indent = line.length - line.trimLeft().length;
      final indentLevel = indent ~/ 2; // 假设2空格缩进

      if (indentLevel > maxIndentLevel) {
        maxIndentLevel = indentLevel;
      }
    }

    if (maxIndentLevel > 4) {
      result.addWarning(
        '代码嵌套层次过深($maxIndentLevel层)，建议重构',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
        fixSuggestion: const FixSuggestion(
          description: '提取方法或使用early return减少嵌套',
          fixabilityLevel: FixabilityLevel.manual,
        ),
      );
    }

    // 检查return语句数量
    final returnCount = 'return'.allMatches(content).length;
    if (returnCount > 5) {
      result.addInfo(
        '方法包含多个return语句($returnCount个)，考虑重构',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }
  }

  /// 验证异步模式
  void _validateAsyncPatterns(
    ValidationResult result,
    String content,
    String relativePath,
  ) {
    // 检查异步方法命名
    if (content.contains('async') && !content.contains('await')) {
      result.addWarning(
        'async方法应该使用await或返回Future',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }

    // 检查Future使用模式
    if (content.contains('Future') && content.contains('.then(')) {
      result.addInfo(
        '考虑使用async/await替代.then()链式调用',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }

    // 检查错误处理
    if (content.contains('async') && !content.contains('try')) {
      result.addWarning(
        '异步方法缺少错误处理',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }
  }

  /// 性能模式验证 (Task 40.3)
  Future<void> _validatePerformancePatterns(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));
    if (!libDir.existsSync()) return;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _validateFilePerformance(result, entity, modulePath);
      }
    }
  }

  /// 验证文件性能模式
  Future<void> _validateFilePerformance(
    ValidationResult result,
    File file,
    String modulePath,
  ) async {
    final content = await file.readAsString();
    final relativePath = path.relative(file.path, from: modulePath);

    // 检查String拼接性能
    if (content.contains(RegExp(r'".*?\+.*?"')) ||
        content.contains(RegExp(r"'.*?\+.*?'"))) {
      result.addInfo(
        '频繁字符串拼接，考虑使用StringBuffer',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
        fixSuggestion: const FixSuggestion(
          description: '使用StringBuffer进行大量字符串拼接',
          fixabilityLevel: FixabilityLevel.manual,
        ),
      );
    }

    // 检查List性能反模式
    if (content.contains('List()') && content.contains('add(')) {
      result.addInfo(
        '动态List添加，考虑预分配大小',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }

    // 检查循环中的对象创建
    _validateLoopPerformance(result, content, relativePath);

    // 检查内存泄漏风险
    _validateMemoryLeaks(result, content, relativePath);
  }

  /// 验证循环性能
  void _validateLoopPerformance(
    ValidationResult result,
    String content,
    String relativePath,
  ) {
    final lines = content.split('\n');
    var inLoop = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // 检测循环开始
      if (line.contains('for ') || line.contains('while ')) {
        inLoop = true;
        continue;
      }

      // 检测循环结束
      if (inLoop && line.contains('}')) {
        inLoop = false;
        continue;
      }

      // 在循环中检查对象创建
      if (inLoop) {
        if (line.contains('new ') || line.contains('()')) {
          result.addWarning(
            '循环中创建对象，可能影响性能',
            file: relativePath,
            line: i + 1,
            validationType: ValidationType.quality,
            validatorName: validatorName,
            fixSuggestion: const FixSuggestion(
              description: '将对象创建移到循环外部',
              fixabilityLevel: FixabilityLevel.manual,
            ),
          );
        }
      }
    }
  }

  /// 验证内存泄漏风险
  void _validateMemoryLeaks(
    ValidationResult result,
    String content,
    String relativePath,
  ) {
    // 检查Stream订阅
    if (content.contains('.listen(') && !content.contains('.cancel()')) {
      result.addWarning(
        'Stream监听可能导致内存泄漏，确保正确取消订阅',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }

    // 检查Timer使用
    if (content.contains('Timer.') && !content.contains('.cancel()')) {
      result.addWarning(
        'Timer使用可能导致内存泄漏，确保正确取消',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }

    // 检查全局变量
    if (content
        .contains(RegExp(r'^(var|final|const)\s+\w+', multiLine: true))) {
      result.addInfo(
        '发现全局变量，注意内存使用',
        file: relativePath,
        validationType: ValidationType.quality,
        validatorName: validatorName,
      );
    }
  }
}
