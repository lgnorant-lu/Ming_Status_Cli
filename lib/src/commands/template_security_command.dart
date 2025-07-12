/*
---------------------------------------------------------------
File name:          template_security_command.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板安全命令 (Template Security Command)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.2 企业级安全验证系统;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/security/digital_signature.dart';
import 'package:ming_status_cli/src/core/security/malware_detector.dart';
import 'package:ming_status_cli/src/core/security/security_validator.dart';
import 'package:ming_status_cli/src/core/security/trusted_source_manager.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板安全命令
///
/// 实现 `ming template security` 命令，支持安全验证和管理
class TemplateSecurityCommand extends Command<int> {
  /// 创建模板安全命令实例
  TemplateSecurityCommand() {
    argParser
      ..addOption(
        'file',
        abbr: 'f',
        help: '要验证的模板文件路径',
      )
      ..addOption(
        'source-url',
        abbr: 's',
        help: '模板来源URL',
      )
      ..addOption(
        'policy',
        abbr: 'p',
        help: '安全策略',
        allowed: ['enterprise', 'standard', 'relaxed'],
        defaultsTo: 'standard',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '输出格式',
        allowed: ['table', 'json', 'detailed'],
        defaultsTo: 'table',
      )
      ..addFlag(
        'signature-only',
        help: '仅验证数字签名',
      )
      ..addFlag(
        'malware-only',
        help: '仅进行恶意代码检测',
      )
      ..addFlag(
        'trusted-source-only',
        help: '仅验证可信源',
      )
      ..addFlag(
        'generate-report',
        help: '生成安全报告',
      )
      ..addFlag(
        'show-events',
        help: '显示安全事件',
      )
      ..addFlag(
        'show-audit-logs',
        help: '显示审计日志',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: '显示详细信息',
      );
  }

  @override
  String get name => 'security';

  @override
  String get description => '模板安全验证和管理';

  @override
  String get usage => '''
模板安全验证和管理

使用方法:
  ming template security [选项]

基础选项:
  -f, --file=<路径>          要验证的模板文件路径
  -s, --source-url=<URL>     模板来源URL
  -p, --policy=<策略>        安全策略 (默认: standard)
  -o, --output=<格式>        输出格式 (默认: table)

安全策略:
      enterprise             企业级安全策略
      standard               标准安全策略
      relaxed                宽松安全策略

验证范围:
      --signature-only       仅验证数字签名
      --malware-only         仅进行恶意代码检测
      --trusted-source-only  仅验证可信源

输出格式:
      table                  表格格式输出
      json                   JSON格式输出
      detailed               详细格式输出

报告和日志:
      --generate-report      生成安全报告
      --show-events          显示安全事件
      --show-audit-logs      显示审计日志
  -v, --verbose              显示详细信息

示例:
  # 完整安全验证
  ming template security --file=./template.zip --source-url=https://github.com/user/repo

  # 企业级安全策略验证
  ming template security --file=./template.zip --policy=enterprise --verbose

  # 仅验证数字签名
  ming template security --file=./template.zip --signature-only

  # 仅检测恶意代码
  ming template security --file=./template.zip --malware-only --output=json

  # 生成安全报告
  ming template security --generate-report --output=detailed

  # 查看安全事件
  ming template security --show-events --verbose

  # 查看审计日志
  ming template security --show-audit-logs

更多信息:
  使用 'ming help template security' 查看详细文档
''';

  @override
  Future<int> run() async {
    try {
      final filePath = argResults!['file'] as String?;
      final sourceUrl = argResults!['source-url'] as String?;
      final policyName = argResults!['policy'] as String;
      final outputFormat = argResults!['output'] as String;
      final signatureOnly = argResults!['signature-only'] as bool;
      final malwareOnly = argResults!['malware-only'] as bool;
      final trustedSourceOnly = argResults!['trusted-source-only'] as bool;
      final generateReport = argResults!['generate-report'] as bool;
      final showEvents = argResults!['show-events'] as bool;
      final showAuditLogs = argResults!['show-audit-logs'] as bool;
      final verbose = argResults!['verbose'] as bool;

      cli_logger.Logger.info('开始模板安全验证');

      // 解析安全策略
      final policy = SecurityPolicy.values.byName(policyName);

      // 创建安全验证器
      final securityValidator = SecurityValidator(policy: policy);

      // 处理不同的操作模式
      if (generateReport) {
        await _generateSecurityReport(securityValidator, outputFormat, verbose);
      } else if (showEvents) {
        await _showSecurityEvents(securityValidator, verbose);
      } else if (showAuditLogs) {
        await _showAuditLogs(securityValidator, verbose);
      } else if (filePath != null) {
        await _validateTemplateFile(
          securityValidator,
          filePath,
          sourceUrl,
          signatureOnly,
          malwareOnly,
          trustedSourceOnly,
          outputFormat,
          verbose,
        );
      } else {
        print('错误: 需要指定操作模式');
        print('使用 --file 验证文件，--generate-report 生成报告，或 --show-events 查看事件');
        return 1;
      }

      cli_logger.Logger.success('模板安全操作完成');
      return 0;
    } catch (e) {
      cli_logger.Logger.error('模板安全操作失败', error: e);
      return 1;
    }
  }

  /// 验证模板文件
  Future<void> _validateTemplateFile(
    SecurityValidator validator,
    String filePath,
    String? sourceUrl,
    bool signatureOnly,
    bool malwareOnly,
    bool trustedSourceOnly,
    String outputFormat,
    bool verbose,
  ) async {
    print('\n🔒 模板安全验证');
    print('─' * 60);
    print('文件路径: $filePath');
    if (sourceUrl != null) {
      print('来源URL: $sourceUrl');
    }
    print('');

    // 检查文件是否存在
    final file = File(filePath);
    if (!await file.exists()) {
      print('❌ 错误: 文件不存在: $filePath');
      return;
    }

    final fileData = await file.readAsBytes();
    print('📊 文件信息:');
    print('  大小: ${_formatFileSize(fileData.length)}');
    print('  类型: ${_getFileType(filePath)}');
    print('');

    if (signatureOnly) {
      // 仅验证数字签名
      await _performSignatureVerification(
        filePath,
        fileData,
        outputFormat,
        verbose,
      );
    } else if (malwareOnly) {
      // 仅检测恶意代码
      await _performMalwareDetection(filePath, fileData, outputFormat, verbose);
    } else if (trustedSourceOnly && sourceUrl != null) {
      // 仅验证可信源
      await _performTrustedSourceVerification(sourceUrl, outputFormat, verbose);
    } else {
      // 完整安全验证
      await _performFullSecurityValidation(
        validator,
        filePath,
        fileData,
        sourceUrl,
        outputFormat,
        verbose,
      );
    }
  }

  /// 执行完整安全验证
  Future<void> _performFullSecurityValidation(
    SecurityValidator validator,
    String filePath,
    List<int> fileData,
    String? sourceUrl,
    String outputFormat,
    bool verbose,
  ) async {
    print('🔍 执行完整安全验证...');

    final result = await validator.validateTemplateSecurity(
      filePath,
      Uint8List.fromList(fileData),
      sourceUrl,
    );

    print('\n📋 验证结果:');
    print('─' * 40);

    // 显示安全等级
    final levelIcon = _getSecurityLevelIcon(result.securityLevel);
    // final levelColor = _getSecurityLevelColor(result.securityLevel);
    print('$levelIcon 安全等级: ${result.securityLevel.name.toUpperCase()}');
    print('✅ 验证通过: ${result.isValid ? '是' : '否'}');
    print('⏱️ 验证耗时: ${result.validationDuration.inMilliseconds}ms');
    print('📋 安全策略: ${result.policy.name}');
    print('');

    // 显示验证步骤结果
    print('🔍 验证步骤:');
    result.stepResults.forEach((step, passed) {
      final icon = passed ? '✅' : '❌';
      final stepName = _getStepName(step);
      print('  $icon $stepName');
    });
    print('');

    // 显示安全问题
    if (result.securityIssues.isNotEmpty) {
      print('⚠️ 发现安全问题 (${result.securityIssues.length}个):');
      for (final issue in result.securityIssues) {
        _displaySecurityIssue(issue, verbose);
      }
      print('');
    }

    // 显示详细结果
    if (verbose) {
      _displayDetailedResults(result);
    }

    // 输出格式化结果
    if (outputFormat == 'json') {
      _outputJsonResult(result);
    } else if (outputFormat == 'detailed') {
      _outputDetailedResult(result);
    }
  }

  /// 执行数字签名验证
  Future<void> _performSignatureVerification(
    String filePath,
    List<int> fileData,
    String outputFormat,
    bool verbose,
  ) async {
    print('🔐 数字签名验证...');

    final digitalSignature = DigitalSignature();
    final result = await digitalSignature.verifyFileSignature(
      filePath,
      Uint8List.fromList(fileData),
    );

    print('\n📋 签名验证结果:');
    print('─' * 40);
    print('✅ 验证通过: ${result.isValid ? '是' : '否'}');
    print('📝 签名数量: ${result.signatures.length}');
    print('🔒 可信签名: ${result.hasTrustedSignature ? '是' : '否'}');
    print('⏰ 时间戳: ${result.hasTimestamp ? '是' : '否'}');
    print('📋 验证策略: ${result.policy.name}');
    print('');

    if (result.signatures.isNotEmpty && verbose) {
      print('📜 签名详情:');
      for (final signature in result.signatures) {
        print('  算法: ${signature.algorithm.name}');
        print('  签名时间: ${signature.signedAt}');
        print('  证书主题: ${signature.certificate.subject}');
        print('  证书状态: ${signature.certificate.status.name}');
        print('');
      }
    }

    if (result.errors.isNotEmpty) {
      print('❌ 验证错误:');
      for (final error in result.errors) {
        print('  • $error');
      }
      print('');
    }

    if (result.warnings.isNotEmpty) {
      print('⚠️ 验证警告:');
      for (final warning in result.warnings) {
        print('  • $warning');
      }
      print('');
    }
  }

  /// 执行恶意代码检测
  Future<void> _performMalwareDetection(
    String filePath,
    List<int> fileData,
    String outputFormat,
    bool verbose,
  ) async {
    print('🦠 恶意代码检测...');

    final malwareDetector = MalwareDetector();
    final result =
        await malwareDetector.scanData(Uint8List.fromList(fileData), filePath);

    print('\n📋 检测结果:');
    print('─' * 40);
    final threatIcon = _getThreatLevelIcon(result.threatLevel);
    print('$threatIcon 威胁级别: ${result.threatLevel.name.toUpperCase()}');
    print('🛡️ 安全状态: ${result.isSafe ? '安全' : '有威胁'}');
    print('🔍 检测类型: ${result.detectionType.name}');
    print('📊 置信度: ${result.confidence}%');
    print('⏱️ 扫描耗时: ${result.scanDuration.inMilliseconds}ms');
    print('');

    if (result.threatTypes.isNotEmpty) {
      print('⚠️ 威胁类型:');
      for (final threatType in result.threatTypes) {
        print('  • ${threatType.name}');
      }
      print('');
    }

    if (result.issues.isNotEmpty) {
      print('🚨 发现问题 (${result.issues.length}个):');
      for (final issue in result.issues) {
        _displaySecurityIssue(issue, verbose);
      }
      print('');
    }
  }

  /// 执行可信源验证
  Future<void> _performTrustedSourceVerification(
    String sourceUrl,
    String outputFormat,
    bool verbose,
  ) async {
    print('🌐 可信源验证...');

    final trustedSourceManager = TrustedSourceManager();
    final isTrusted = await trustedSourceManager.verifySourceTrust(sourceUrl);
    final trustLevel = trustedSourceManager.getSourceTrustLevel(sourceUrl);
    final reputationScore =
        trustedSourceManager.getSourceReputationScore(sourceUrl);

    print('\n📋 可信源验证结果:');
    print('─' * 40);
    print('🌐 源URL: $sourceUrl');
    print('✅ 可信状态: ${isTrusted ? '可信' : '不可信'}');
    print('🏆 信任级别: ${trustLevel.name}');
    print('📊 信誉评分: $reputationScore/100');
    print('');

    if (verbose) {
      final sources = trustedSourceManager.getAllTrustedSources();
      final matchingSource =
          sources.where((s) => sourceUrl.contains(s.url)).firstOrNull;

      if (matchingSource != null) {
        print('📜 源详情:');
        print('  名称: ${matchingSource.name}');
        print('  状态: ${matchingSource.status.name}');
        print('  创建时间: ${matchingSource.createdAt}');
        print('  最后验证: ${matchingSource.lastVerifiedAt}');
        print('  验证次数: ${matchingSource.verificationCount}');
        print('  失败次数: ${matchingSource.failureCount}');
        print(
          '  成功率: ${(matchingSource.successRate * 100).toStringAsFixed(1)}%',
        );
        print('  标签: ${matchingSource.tags.join(', ')}');
        print('');
      }
    }
  }

  /// 生成安全报告
  Future<void> _generateSecurityReport(
    SecurityValidator validator,
    String outputFormat,
    bool verbose,
  ) async {
    print('\n📊 生成安全报告...');

    final report = validator.generateSecurityReport();

    print('\n📋 安全报告');
    print('─' * 60);
    print('生成时间: ${report['reportGeneratedAt']}');
    print('安全策略: ${report['policy']}');
    print('验证器版本: ${report['validatorVersion']}');
    print('');

    final stats = report['statistics'] as Map<String, dynamic>;
    print('📊 统计信息:');
    print('  总验证次数: ${stats['totalValidations']}');
    print('  最近事件数: ${stats['recentEvents']}');
    print('  最近审计日志: ${stats['recentAuditLogs']}');
    print('');

    if (verbose) {
      final validationsByLevel =
          stats['validationsByLevel'] as Map<String, dynamic>;
      print('📈 验证分布:');
      validationsByLevel.forEach((level, count) {
        print('  $level: $count');
      });
      print('');

      final recentEvents = report['recentSecurityEvents'] as List;
      if (recentEvents.isNotEmpty) {
        print('🚨 最近安全事件:');
        for (final event in recentEvents.take(5)) {
          final eventMap = event as Map<String, dynamic>;
          print('  • ${eventMap['type']}: ${eventMap['description']}');
        }
        print('');
      }
    }

    if (outputFormat == 'json') {
      print('\n📄 JSON格式报告:');
      print(const JsonEncoder.withIndent('  ').convert(report));
    }
  }

  /// 显示安全事件
  Future<void> _showSecurityEvents(
    SecurityValidator validator,
    bool verbose,
  ) async {
    print('\n🚨 安全事件');
    print('─' * 60);

    final events = validator.getSecurityEvents(limit: verbose ? 50 : 10);

    if (events.isEmpty) {
      print('暂无安全事件');
      return;
    }

    for (final event in events) {
      final severityIcon = _getSecurityLevelIcon(event.severity);
      print('$severityIcon [${event.timestamp}] ${event.eventType}');
      print('  描述: ${event.description}');
      if (event.filePath != null) {
        print('  文件: ${event.filePath}');
      }
      if (event.sourceUrl != null) {
        print('  来源: ${event.sourceUrl}');
      }
      if (verbose && event.eventData.isNotEmpty) {
        print('  数据: ${event.eventData}');
      }
      print('');
    }
  }

  /// 显示审计日志
  Future<void> _showAuditLogs(SecurityValidator validator, bool verbose) async {
    print('\n📋 审计日志');
    print('─' * 60);

    final logs = validator.getAuditLogs(limit: verbose ? 50 : 10);

    if (logs.isEmpty) {
      print('暂无审计日志');
      return;
    }

    for (final log in logs) {
      final statusIcon = log.success ? '✅' : '❌';
      print('$statusIcon [${log.timestamp}] ${log.operation}');
      if (log.resourcePath != null) {
        print('  资源: ${log.resourcePath}');
      }
      if (verbose && log.details.isNotEmpty) {
        print('  详情: ${log.details}');
      }
      print('');
    }
  }

  /// 显示安全问题
  void _displaySecurityIssue(SecurityIssue issue, bool verbose) {
    final severityIcon = _getThreatLevelIcon(issue.severity);
    print('  $severityIcon ${issue.title}');
    print('    描述: ${issue.description}');
    print('    威胁类型: ${issue.threatType.name}');
    print('    严重程度: ${issue.severity.name}');
    print('    置信度: ${issue.confidence}%');

    if (verbose) {
      if (issue.filePath != null) {
        print('    文件: ${issue.filePath}');
      }
      if (issue.lineNumber != null) {
        print('    行号: ${issue.lineNumber}');
      }
      if (issue.codeSnippet != null) {
        print('    代码片段: ${issue.codeSnippet}');
      }
      if (issue.remediation != null) {
        print('    修复建议: ${issue.remediation}');
      }
    }
    print('');
  }

  /// 显示详细结果
  void _displayDetailedResults(SecurityValidationResult result) {
    print('📊 详细验证信息:');

    if (result.signatureResult != null) {
      print('  数字签名:');
      print('    验证通过: ${result.signatureResult!.isValid}');
      print('    签名数量: ${result.signatureResult!.signatures.length}');
      print('    策略: ${result.signatureResult!.policy.name}');
    }

    if (result.trustedSourceResult != null) {
      print('  可信源:');
      print('    验证通过: ${result.trustedSourceResult}');
    }

    if (result.malwareResult != null) {
      print('  恶意代码检测:');
      print('    威胁级别: ${result.malwareResult!.threatLevel.name}');
      print('    检测类型: ${result.malwareResult!.detectionType.name}');
      print('    置信度: ${result.malwareResult!.confidence}%');
    }

    print('');
  }

  /// 输出JSON结果
  void _outputJsonResult(SecurityValidationResult result) {
    final jsonData = {
      'securityLevel': result.securityLevel.name,
      'isValid': result.isValid,
      'validatedAt': result.validatedAt.toIso8601String(),
      'validationDuration': result.validationDuration.inMilliseconds,
      'policy': result.policy.name,
      'stepResults': result.stepResults.map((k, v) => MapEntry(k.name, v)),
      'securityIssues': result.securityIssues
          .map(
            (issue) => {
              'id': issue.id,
              'title': issue.title,
              'description': issue.description,
              'threatType': issue.threatType.name,
              'severity': issue.severity.name,
              'confidence': issue.confidence,
            },
          )
          .toList(),
    };

    print('\n📄 JSON结果:');
    print(const JsonEncoder.withIndent('  ').convert(jsonData));
  }

  /// 输出详细结果
  void _outputDetailedResult(SecurityValidationResult result) {
    print('\n📄 详细结果报告:');
    print('═' * 80);
    print('验证时间: ${result.validatedAt}');
    print('验证耗时: ${result.validationDuration.inMilliseconds}ms');
    print('安全策略: ${result.policy.name}');
    print('验证器版本: ${result.validatorVersion}');
    print('');

    print('验证步骤详情:');
    result.stepResults.forEach((step, passed) {
      print('  ${_getStepName(step)}: ${passed ? '通过' : '失败'}');
    });
    print('');

    if (result.metadata.isNotEmpty) {
      print('元数据:');
      result.metadata.forEach((key, value) {
        print('  $key: $value');
      });
    }
  }

  /// 获取安全等级图标
  String _getSecurityLevelIcon(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.safe:
        return '🟢';
      case SecurityLevel.warning:
        return '🟡';
      case SecurityLevel.dangerous:
        return '🟠';
      case SecurityLevel.blocked:
        return '🔴';
    }
  }

  /// 获取威胁级别图标
  String _getThreatLevelIcon(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.none:
        return '🟢';
      case ThreatLevel.low:
        return '🟡';
      case ThreatLevel.medium:
        return '🟠';
      case ThreatLevel.high:
        return '🔴';
      case ThreatLevel.critical:
        return '⚫';
    }
  }

// 获取安全等级颜色方法已移除 - 当前未使用

  /// 获取步骤名称
  String _getStepName(ValidationStep step) {
    switch (step) {
      case ValidationStep.signatureVerification:
        return '数字签名验证';
      case ValidationStep.trustedSourceVerification:
        return '可信源验证';
      case ValidationStep.malwareDetection:
        return '恶意代码检测';
      case ValidationStep.policyCheck:
        return '安全策略检查';
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 获取文件类型
  String _getFileType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'zip':
        return 'ZIP压缩包';
      case 'tar':
      case 'gz':
        return 'TAR压缩包';
      case '7z':
        return '7Z压缩包';
      case 'exe':
        return '可执行文件';
      case 'dll':
        return '动态链接库';
      default:
        return '未知类型';
    }
  }
}
