/*
---------------------------------------------------------------
File name:          task_2_2_2_security_test.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        Task 2.2.2 企业级安全验证系统测试
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.2 测试;
---------------------------------------------------------------
*/

import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:ming_status_cli/src/core/security/digital_signature.dart';
import 'package:ming_status_cli/src/core/security/trusted_source_manager.dart';
import 'package:ming_status_cli/src/core/security/malware_detector.dart';
import 'package:ming_status_cli/src/core/security/security_validator.dart';

void main() {
  group('Task 2.2.2: 企业级安全验证系统', () {
    group('DigitalSignature Tests', () {
      late DigitalSignature digitalSignature;

      setUp(() {
        digitalSignature = DigitalSignature();
      });

      test('应该创建证书信息', () {
        final certificate = CertificateInfo(
          subject: 'CN=Test Publisher',
          issuer: 'CN=Test CA',
          serialNumber: '123456789',
          notBefore: DateTime.now().subtract(const Duration(days: 30)),
          notAfter: DateTime.now().add(const Duration(days: 30)),
          fingerprint: 'SHA256:ABCDEF123456',
          status: CertificateStatus.valid,
          keyUsage: ['Digital Signature'],
          extendedKeyUsage: ['Code Signing'],
        );

        expect(certificate.subject, equals('CN=Test Publisher'));
        expect(certificate.isValid, isTrue);
        expect(certificate.isExpired, isFalse);
        expect(certificate.isInValidPeriod, isTrue);
      });

      test('应该创建签名信息', () {
        final certificate = CertificateInfo(
          subject: 'CN=Test Publisher',
          issuer: 'CN=Test CA',
          serialNumber: '123456789',
          notBefore: DateTime.now().subtract(const Duration(days: 30)),
          notAfter: DateTime.now().add(const Duration(days: 30)),
          fingerprint: 'SHA256:ABCDEF123456',
          status: CertificateStatus.valid,
          keyUsage: ['Digital Signature'],
          extendedKeyUsage: ['Code Signing'],
        );

        final signature = SignatureInfo(
          algorithm: SignatureAlgorithm.rsa2048,
          signature: Uint8List.fromList([1, 2, 3, 4, 5]),
          signedAt: DateTime.now(),
          certificate: certificate,
        );

        expect(signature.algorithm, equals(SignatureAlgorithm.rsa2048));
        expect(signature.hasTimestamp, isFalse);
        expect(signature.isTrusted, isTrue);
      });

      test('应该验证文件签名', () async {
        final testData = Uint8List.fromList('test file content'.codeUnits);

        final result = await digitalSignature.verifyFileSignature(
          'test.txt',
          testData,
        );

        expect(result, isA<SignatureVerificationResult>());
        expect(result.verifiedAt, isA<DateTime>());
        expect(result.policy, isA<SignaturePolicy>());
      });

      test('应该获取签名统计', () {
        final stats = digitalSignature.getSignatureStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalVerifications'), isTrue);
        expect(stats.containsKey('trustedCAs'), isTrue);
        expect(stats.containsKey('policy'), isTrue);
      });
    });

    group('TrustedSourceManager Tests', () {
      late TrustedSourceManager trustedSourceManager;

      setUp(() {
        trustedSourceManager = TrustedSourceManager();
      });

      test('应该创建可信源', () {
        final source = TrustedSource(
          id: 'test_source',
          name: 'Test Source',
          url: 'https://test.example.com',
          trustLevel: TrustLevel.certified,
          status: TrustSourceStatus.active,
          createdAt: DateTime.now(),
          lastVerifiedAt: DateTime.now(),
          reputationScore: 85,
          verificationCount: 100,
          failureCount: 5,
          tags: ['test', 'verified'],
          metadata: {'region': 'test'},
        );

        expect(source.id, equals('test_source'));
        expect(source.isActive, isTrue);
        expect(source.isExpired, isFalse);
        expect(source.isTrusted, isTrue);
        expect(source.successRate, closeTo(0.95, 0.01));
        expect(source.trustRating, equals('Good'));
      });

      test('应该验证源的可信性', () async {
        final isTrusted = await trustedSourceManager
            .verifySourceTrust('https://templates.ming.dev');

        expect(isTrusted, isA<bool>());
      });

      test('应该获取源的信任级别', () {
        final trustLevel = trustedSourceManager
            .getSourceTrustLevel('https://templates.ming.dev');

        expect(trustLevel, isA<TrustLevel>());
      });

      test('应该获取源的信誉评分', () {
        final score = trustedSourceManager
            .getSourceReputationScore('https://templates.ming.dev');

        expect(score, isA<int>());
        expect(score, greaterThanOrEqualTo(0));
        expect(score, lessThanOrEqualTo(100));
      });

      test('应该管理白名单和黑名单', () {
        const testUrl = 'https://test.example.com';

        trustedSourceManager.addToWhitelist(testUrl);
        trustedSourceManager.addToBlacklist(testUrl);

        trustedSourceManager.removeFromWhitelist(testUrl);
        trustedSourceManager.removeFromBlacklist(testUrl);

        // 测试通过，没有异常
        expect(true, isTrue);
      });

      test('应该获取统计信息', () {
        final stats = trustedSourceManager.getStatistics();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalSources'), isTrue);
        expect(stats.containsKey('activeSources'), isTrue);
        expect(stats.containsKey('trustLevelDistribution'), isTrue);
      });
    });

    group('MalwareDetector Tests', () {
      late MalwareDetector malwareDetector;

      setUp(() {
        malwareDetector = MalwareDetector();
      });

      test('应该创建检测结果', () {
        final result = DetectionResult(
          threatLevel: ThreatLevel.low,
          detectionType: DetectionType.staticAnalysis,
          threatTypes: [ThreatType.suspiciousBehavior],
          issues: [],
          detectedAt: DateTime.now(),
          scanDuration: const Duration(milliseconds: 100),
          confidence: 80,
          engineVersion: '1.0.0',
          metadata: {},
        );

        expect(result.threatLevel, equals(ThreatLevel.low));
        expect(result.isSafe, isFalse);
        expect(result.hasThreat, isTrue);
        expect(result.isHighRisk, isFalse);
      });

      test('应该创建安全问题', () {
        final issue = SecurityIssue(
          id: 'test_issue',
          title: 'Test Security Issue',
          description: 'This is a test security issue',
          threatType: ThreatType.suspiciousBehavior,
          severity: ThreatLevel.medium,
          filePath: '/test/file.txt',
          lineNumber: 42,
          references: [],
          confidence: 75,
        );

        expect(issue.id, equals('test_issue'));
        expect(issue.threatType, equals(ThreatType.suspiciousBehavior));
        expect(issue.severity, equals(ThreatLevel.medium));
      });

      test('应该扫描数据', () async {
        final testData = Uint8List.fromList('test file content'.codeUnits);

        final result = await malwareDetector.scanData(testData, 'test.txt');

        expect(result, isA<DetectionResult>());
        expect(result.detectedAt, isA<DateTime>());
        expect(result.scanDuration, isA<Duration>());
      });

      test('应该批量扫描', () async {
        final filePaths = ['test1.txt', 'test2.txt'];

        final results = await malwareDetector.scanBatch(filePaths);

        expect(results, isA<List<DetectionResult>>());
        expect(results.length, equals(2));
      });

      test('应该获取检测统计', () {
        final stats = malwareDetector.getDetectionStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalScans'), isTrue);
        expect(stats.containsKey('cacheSize'), isTrue);
      });
    });

    group('SecurityValidator Tests', () {
      late SecurityValidator securityValidator;

      setUp(() {
        securityValidator = SecurityValidator();
      });

      test('应该创建安全验证结果', () {
        final result = SecurityValidationResult(
          securityLevel: SecurityLevel.safe,
          isValid: true,
          stepResults: {
            ValidationStep.signatureVerification: true,
            ValidationStep.trustedSourceVerification: true,
            ValidationStep.malwareDetection: true,
            ValidationStep.policyCheck: true,
          },
          securityIssues: [],
          validatedAt: DateTime.now(),
          validationDuration: const Duration(milliseconds: 500),
          policy: SecurityPolicy.standard,
          validatorVersion: '1.0.0',
          metadata: {},
        );

        expect(result.securityLevel, equals(SecurityLevel.safe));
        expect(result.isValid, isTrue);
        expect(result.isSafeToUse, isTrue);
        expect(result.stepResults.length, equals(4));
      });

      test('应该验证模板安全性', () async {
        final testData = Uint8List.fromList('test template content'.codeUnits);

        final result = await securityValidator.validateTemplateSecurity(
          'test_template.zip',
          testData,
          'https://test.example.com',
        );

        expect(result, isA<SecurityValidationResult>());
        expect(result.validatedAt, isA<DateTime>());
        expect(result.validationDuration, isA<Duration>());
        expect(result.policy, equals(SecurityPolicy.standard));
      });

      test('应该批量验证', () async {
        final filePaths = ['test1.zip', 'test2.zip'];
        final fileDataList = [
          Uint8List.fromList('test1 content'.codeUnits),
          Uint8List.fromList('test2 content'.codeUnits),
        ];
        final sourceUrls = ['https://test1.com', 'https://test2.com'];

        final results = await securityValidator.validateBatch(
          filePaths,
          fileDataList,
          sourceUrls,
        );

        expect(results, isA<List<SecurityValidationResult>>());
        expect(results.length, equals(2));
      });

      test('应该获取安全事件', () {
        final events = securityValidator.getSecurityEvents();

        expect(events, isA<List<SecurityEvent>>());
      });

      test('应该获取审计日志', () {
        final logs = securityValidator.getAuditLogs();

        expect(logs, isA<List<SecurityAuditLog>>());
      });

      test('应该生成安全报告', () {
        final report = securityValidator.generateSecurityReport();

        expect(report, isA<Map<String, dynamic>>());
        expect(report.containsKey('reportGeneratedAt'), isTrue);
        expect(report.containsKey('policy'), isTrue);
        expect(report.containsKey('statistics'), isTrue);
      });
    });

    group('Integration Tests', () {
      test('应该集成数字签名和可信源管理', () async {
        final digitalSignature = DigitalSignature();
        final trustedSourceManager = TrustedSourceManager();

        try {
          // 模拟集成流程
          final testData = Uint8List.fromList('signed template'.codeUnits);
          final signatureResult = await digitalSignature.verifyFileSignature(
            'signed_template.zip',
            testData,
          );

          final isTrusted = await trustedSourceManager.verifySourceTrust(
            'https://templates.ming.dev',
          );

          expect(signatureResult, isA<SignatureVerificationResult>());
          expect(isTrusted, isA<bool>());
        } finally {
          digitalSignature.clearCache();
        }
      });

      test('应该集成恶意代码检测和安全验证', () async {
        final malwareDetector = MalwareDetector();
        final securityValidator = SecurityValidator(
          malwareDetector: malwareDetector,
        );

        try {
          // 模拟集成流程
          final testData = Uint8List.fromList('template content'.codeUnits);

          final malwareResult = await malwareDetector.scanData(testData);
          final securityResult =
              await securityValidator.validateTemplateSecurity(
            'test_template.zip',
            testData,
            'https://test.example.com',
          );

          expect(malwareResult, isA<DetectionResult>());
          expect(securityResult, isA<SecurityValidationResult>());
        } finally {
          malwareDetector.clearCache();
        }
      });

      test('应该完整的安全验证流程', () async {
        final securityValidator = SecurityValidator(
          policy: SecurityPolicy.enterprise,
        );

        // 模拟企业级安全验证
        final testData = Uint8List.fromList('enterprise template'.codeUnits);

        final result = await securityValidator.validateTemplateSecurity(
          'enterprise_template.zip',
          testData,
          'https://enterprise.example.com',
        );

        expect(result, isA<SecurityValidationResult>());
        expect(result.policy, equals(SecurityPolicy.enterprise));
        expect(result.stepResults.length, greaterThan(0));

        // 检查安全报告
        final report = securityValidator.generateSecurityReport();
        expect(report['policy'], equals('enterprise'));
      });
    });
  });
}
