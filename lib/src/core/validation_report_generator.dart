/*
---------------------------------------------------------------
File name:          validation_report_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/08
Last modified:      2025/07/08
Dart Version:       3.2+
Description:        验证报告生成器 - 生成详细的验证报告
---------------------------------------------------------------
Change History:
    2025/07/08: Initial creation - 验证报告生成器;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 验证报告生成器
/// 
/// 支持多种格式的验证报告生成：
/// - HTML报告 (详细的可视化报告)
/// - JSON报告 (机器可读格式)
/// - JUnit XML (CI/CD集成)
/// - Markdown报告 (文档友好格式)
/// - CSV报告 (数据分析格式)
class ValidationReportGenerator {
  /// 创建验证报告生成器
  const ValidationReportGenerator();

  /// 生成完整的验证报告
  Future<void> generateReport({
    required ValidationResult result,
    required String outputPath,
    required Set<ReportFormat> formats,
    Map<String, dynamic>? metadata,
  }) async {
    final reportMetadata = {
      'generated_at': DateTime.now().toIso8601String(),
      'generator': 'Ming Status CLI',
      'version': '1.0.0',
      ...?metadata,
    };

    for (final format in formats) {
      try {
        switch (format) {
          case ReportFormat.html:
            await _generateHtmlReport(result, outputPath, reportMetadata);
          case ReportFormat.json:
            await _generateJsonReport(result, outputPath, reportMetadata);
          case ReportFormat.junit:
            await _generateJUnitReport(result, outputPath, reportMetadata);
          case ReportFormat.markdown:
            await _generateMarkdownReport(result, outputPath, reportMetadata);
          case ReportFormat.csv:
            await _generateCsvReport(result, outputPath, reportMetadata);
        }
      } catch (e) {
        Logger.error('生成 ${format.name} 报告失败: $e');
      }
    }
  }

  /// 生成HTML报告
  Future<void> _generateHtmlReport(
    ValidationResult result,
    String outputPath,
    Map<String, dynamic> metadata,
  ) async {
    final htmlContent = _buildHtmlReport(result, metadata);
    final filePath = path.join(outputPath, 'validation-report.html');
    
    await Directory(outputPath).create(recursive: true);
    await File(filePath).writeAsString(htmlContent);
    
    Logger.info('✅ HTML报告已生成: $filePath');
  }

  /// 构建HTML报告内容
  String _buildHtmlReport(ValidationResult result, Map<String, dynamic> metadata) {
    final errorCount = result.messages.where((m) => m.severity == ValidationSeverity.error).length;
    final warningCount = result.messages.where((m) => m.severity == ValidationSeverity.warning).length;
    final successCount = result.messages.where((m) => m.severity == ValidationSeverity.success).length;
    
    final statusColor = result.isValid ? '#28a745' : '#dc3545';
    final statusText = result.isValid ? '通过' : '失败';

    return '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ming Status CLI 验证报告</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f8f9fa; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; }
        .header h1 { margin: 0; font-size: 2.5em; }
        .header .subtitle { opacity: 0.9; margin-top: 10px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; padding: 30px; }
        .summary-card { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; border-left: 4px solid #007bff; }
        .summary-card.error { border-left-color: #dc3545; }
        .summary-card.warning { border-left-color: #ffc107; }
        .summary-card.success { border-left-color: #28a745; }
        .summary-card h3 { margin: 0; font-size: 2em; }
        .summary-card p { margin: 10px 0 0; color: #6c757d; }
        .status { display: inline-block; padding: 8px 16px; border-radius: 20px; color: white; font-weight: bold; background: $statusColor; }
        .messages { padding: 0 30px 30px; }
        .message { margin: 10px 0; padding: 15px; border-radius: 6px; border-left: 4px solid #007bff; }
        .message.error { background: #f8d7da; border-left-color: #dc3545; color: #721c24; }
        .message.warning { background: #fff3cd; border-left-color: #ffc107; color: #856404; }
        .message.success { background: #d4edda; border-left-color: #28a745; color: #155724; }
        .message-header { font-weight: bold; margin-bottom: 5px; }
        .message-file { font-family: monospace; font-size: 0.9em; color: #6c757d; }
        .footer { padding: 20px 30px; border-top: 1px solid #dee2e6; color: #6c757d; font-size: 0.9em; }
        .metadata { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px; }
        .metadata-item { display: flex; justify-content: space-between; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 验证报告</h1>
            <div class="subtitle">
                <span class="status">$statusText</span>
                <span style="margin-left: 20px;">生成时间: ${metadata['generated_at']}</span>
            </div>
        </div>
        
        <div class="summary">
            <div class="summary-card error">
                <h3>$errorCount</h3>
                <p>错误</p>
            </div>
            <div class="summary-card warning">
                <h3>$warningCount</h3>
                <p>警告</p>
            </div>
            <div class="summary-card success">
                <h3>$successCount</h3>
                <p>成功</p>
            </div>
            <div class="summary-card">
                <h3>${result.messages.length}</h3>
                <p>总计</p>
            </div>
        </div>
        
        <div class="messages">
            <h2>验证详情</h2>
            ${result.messages.map((message) => '''
            <div class="message ${message.severity.name}">
                <div class="message-header">${message.message}</div>
                ${message.file != null ? '<div class="message-file">📁 ${message.file}</div>' : ''}
            </div>
            ''',).join()}
        </div>
        
        <div class="footer">
            <h3>元数据</h3>
            <div class="metadata">
                ${metadata.entries.map((entry) => '''
                <div class="metadata-item">
                    <span><strong>${entry.key}:</strong></span>
                    <span>${entry.value}</span>
                </div>
                ''',).join()}
            </div>
        </div>
    </div>
</body>
</html>
''';
  }

  /// 生成JSON报告
  Future<void> _generateJsonReport(
    ValidationResult result,
    String outputPath,
    Map<String, dynamic> metadata,
  ) async {
    final jsonData = {
      'metadata': metadata,
      'summary': {
        'is_valid': result.isValid,
        'total_messages': result.messages.length,
        'error_count': result.messages.where((m) => m.severity == ValidationSeverity.error).length,
        'warning_count': result.messages.where((m) => m.severity == ValidationSeverity.warning).length,
        'success_count': result.messages.where((m) => m.severity == ValidationSeverity.success).length,
      },
      'messages': result.messages.map((message) => {
        'severity': message.severity.name,
        'message': message.message,
        'validator': message.validatorName,
        'file_path': message.file,
        'line_number': message.line,
        'code': message.code,
        'fix_suggestion': message.fixSuggestion?.description,
      },).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
    final filePath = path.join(outputPath, 'validation-report.json');
    
    await Directory(outputPath).create(recursive: true);
    await File(filePath).writeAsString(jsonString);
    
    Logger.info('✅ JSON报告已生成: $filePath');
  }

  /// 生成JUnit XML报告
  Future<void> _generateJUnitReport(
    ValidationResult result,
    String outputPath,
    Map<String, dynamic> metadata,
  ) async {
    final errorCount = result.messages.where((m) => m.severity == ValidationSeverity.error).length;
    final warningCount = result.messages.where((m) => m.severity == ValidationSeverity.warning).length;
    final totalTests = result.messages.length;
    final failures = errorCount + warningCount;

    final xmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Ming Status CLI Validation" tests="$totalTests" failures="$failures" errors="$errorCount" time="0">
  <testsuite name="Validation" tests="$totalTests" failures="$failures" errors="$errorCount" time="0">
    ${result.messages.map((message) => '''
    <testcase classname="${message.validatorName}" name="${message.message.replaceAll('"', '&quot;')}" time="0">
      ${message.severity == ValidationSeverity.error ? '''
      <error message="${message.message.replaceAll('"', '&quot;')}" type="ValidationError">
        ${message.file != null ? 'File: ${message.file}' : ''}
        ${message.line != null ? 'Line: ${message.line}' : ''}
        ${message.fixSuggestion != null ? 'Fix: ${message.fixSuggestion!.description}' : ''}
      </error>
      ''' : message.severity == ValidationSeverity.warning ? '''
      <failure message="${message.message.replaceAll('"', '&quot;')}" type="ValidationWarning">
        ${message.file != null ? 'File: ${message.file}' : ''}
        ${message.line != null ? 'Line: ${message.line}' : ''}
        ${message.fixSuggestion != null ? 'Fix: ${message.fixSuggestion!.description}' : ''}
      </failure>
      ''' : ''}
    </testcase>
    ''',).join()}
  </testsuite>
</testsuites>''';

    final filePath = path.join(outputPath, 'test-results.xml');
    
    await Directory(outputPath).create(recursive: true);
    await File(filePath).writeAsString(xmlContent);
    
    Logger.info('✅ JUnit XML报告已生成: $filePath');
  }

  /// 生成Markdown报告
  Future<void> _generateMarkdownReport(
    ValidationResult result,
    String outputPath,
    Map<String, dynamic> metadata,
  ) async {
    final errorCount = result.messages.where((m) => m.severity == ValidationSeverity.error).length;
    final warningCount = result.messages.where((m) => m.severity == ValidationSeverity.warning).length;
    final successCount = result.messages.where((m) => m.severity == ValidationSeverity.success).length;
    
    final statusEmoji = result.isValid ? '✅' : '❌';
    final statusText = result.isValid ? '通过' : '失败';

    final markdownContent = '''# 🔍 Ming Status CLI 验证报告

## 📊 验证结果

$statusEmoji **状态**: $statusText

| 类型 | 数量 |
|------|------|
| ❌ 错误 | $errorCount |
| ⚠️ 警告 | $warningCount |
| ✅ 成功 | $successCount |
| 📊 总计 | ${result.messages.length} |

## 📋 验证详情

${result.messages.map((message) => '''
### ${_getSeverityEmoji(message.severity)} ${message.message}

- **验证器**: ${message.validatorName}
${message.file != null ? '- **文件**: `${message.file}`' : ''}
${message.line != null ? '- **行号**: ${message.line}' : ''}
${message.fixSuggestion != null ? '- **修复建议**: ${message.fixSuggestion!.description}' : ''}
''',).join('\n')}

## 📈 元数据

${metadata.entries.map((entry) => '- **${entry.key}**: ${entry.value}').join('\n')}

---
*报告由 Ming Status CLI 生成*
''';

    final filePath = path.join(outputPath, 'validation-report.md');
    
    await Directory(outputPath).create(recursive: true);
    await File(filePath).writeAsString(markdownContent);
    
    Logger.info('✅ Markdown报告已生成: $filePath');
  }

  /// 生成CSV报告
  Future<void> _generateCsvReport(
    ValidationResult result,
    String outputPath,
    Map<String, dynamic> metadata,
  ) async {
    final csvLines = <String>[
      'Severity,Message,Validator,File Path,Line Number,Code,Fix Suggestion',
      ...result.messages.map((message) => [
        message.severity.name,
        '"${message.message.replaceAll('"', '""')}"',
        message.validatorName ?? '',
        message.file ?? '',
        message.line?.toString() ?? '',
        message.code ?? '',
        if (message.fixSuggestion != null) '"${message.fixSuggestion!.description.replaceAll('"', '""')}"' else '',
      ].join(','),),
    ];

    final csvContent = csvLines.join('\n');
    final filePath = path.join(outputPath, 'validation-report.csv');
    
    await Directory(outputPath).create(recursive: true);
    await File(filePath).writeAsString(csvContent);
    
    Logger.info('✅ CSV报告已生成: $filePath');
  }

  /// 获取严重程度对应的emoji
  String _getSeverityEmoji(ValidationSeverity severity) {
    switch (severity) {
      case ValidationSeverity.error:
        return '❌';
      case ValidationSeverity.warning:
        return '⚠️';
      case ValidationSeverity.success:
        return '✅';
      case ValidationSeverity.info:
        return 'ℹ️';
    }
  }
}

/// 报告格式
enum ReportFormat {
  /// HTML格式
  html,
  
  /// JSON格式
  json,
  
  /// JUnit XML格式
  junit,
  
  /// Markdown格式
  markdown,
  
  /// CSV格式
  csv,
}
