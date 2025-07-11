/*
---------------------------------------------------------------
File name:          task_2_2_4_enterprise_test.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        Task 2.2.4 企业级模板管理测试
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.4 测试;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/enterprise/access_control.dart';
import 'package:ming_status_cli/src/core/enterprise/compliance_checker.dart';
import 'package:ming_status_cli/src/core/enterprise/lifecycle_manager.dart';
import 'package:ming_status_cli/src/core/enterprise/private_registry.dart';
import 'package:test/test.dart';

void main() {
  group('Task 2.2.4: 企业级模板管理', () {
    group('PrivateRegistry Tests', () {
      late PrivateRegistry privateRegistry;

      setUp(() {
        const config = RegistryConfig(
          id: 'test_registry',
          name: 'Test Registry',
          url: 'https://test.registry.com',
          type: RegistryType.enterprise,
          deploymentMode: DeploymentMode.onPremise,
          authType: AuthenticationType.oauth2,
          authConfig: {},
          multiTenant: true,
          federationEnabled: true,
          syncConfig: {},
          storageConfig: {},
          networkConfig: {},
        );
        privateRegistry = PrivateRegistry(config: config);
      });

      test('应该创建租户', () async {
        final tenant = await privateRegistry.createTenant(
          name: 'test-tenant',
          domain: 'test.example.com',
          userLimit: 50,
        );

        expect(tenant.name, equals('test-tenant'));
        expect(tenant.domain, equals('test.example.com'));
        expect(tenant.storageQuota, equals(1024 * 1024 * 1024));
        expect(tenant.userLimit, equals(50));
        expect(tenant.isActive, isTrue);
        expect(tenant.isNearQuota, isFalse);
      });

      test('应该获取租户信息', () async {
        final tenant = await privateRegistry.createTenant(
          name: 'test-tenant',
          domain: 'test.example.com',
        );

        final retrievedTenant = privateRegistry.getTenant(tenant.id);
        expect(retrievedTenant, isNotNull);
        expect(retrievedTenant!.name, equals('test-tenant'));
      });

      test('应该配置联邦同步', () async {
        final federationSync = await privateRegistry.configureFederationSync(
          sourceRegistry: 'source-registry',
          targetRegistry: 'target-registry',
          strategy: 'incremental',
          config: {'intervalMinutes': 30},
        );

        expect(federationSync.sourceRegistry, equals('source-registry'));
        expect(federationSync.targetRegistry, equals('target-registry'));
        expect(federationSync.strategy, equals('incremental'));
        expect(federationSync.status, equals(SyncStatus.paused));
      });

      test('应该获取注册表统计', () {
        final stats = privateRegistry.getRegistryStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('registryId'), isTrue);
        expect(stats.containsKey('tenants'), isTrue);
        expect(stats.containsKey('federation'), isTrue);
        expect(stats.containsKey('authentication'), isTrue);
      });
    });

    group('AccessControl Tests', () {
      late AccessControl accessControl;

      setUp(() {
        accessControl = AccessControl();
      });

      test('应该创建用户', () async {
        final user = await accessControl.createUser(
          username: 'testuser',
          email: 'test@example.com',
          displayName: 'Test User',
          tenantId: 'test-tenant',
          department: 'Engineering',
          position: 'Developer',
        );

        expect(user.username, equals('testuser'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('Test User'));
        expect(user.tenantId, equals('test-tenant'));
        expect(user.isActive, isTrue);
      });

      test('应该创建角色', () async {
        final role = await accessControl.createRole(
          name: 'Test Role',
          type: RoleType.developer,
          description: 'Test role for developers',
          permissions: {
            Permission.read,
            Permission.download,
            Permission.upload,
          },
          createdBy: 'admin',
        );

        expect(role.name, equals('Test Role'));
        expect(role.type, equals(RoleType.developer));
        expect(role.permissions.length, equals(3));
        expect(role.hasPermission(Permission.read), isTrue);
        expect(role.hasPermission(Permission.manage), isFalse);
      });

      test('应该分配角色给用户', () async {
        final user = await accessControl.createUser(
          username: 'testuser',
          email: 'test@example.com',
          displayName: 'Test User',
          tenantId: 'test-tenant',
        );

        final role = await accessControl.createRole(
          name: 'Test Role',
          type: RoleType.developer,
          description: 'Test role',
          permissions: {Permission.read},
          createdBy: 'admin',
        );

        final assignment = await accessControl.assignRoleToUser(
          userId: user.id,
          roleId: role.id,
          assignedBy: 'admin',
          reason: 'Test assignment',
        );

        expect(assignment.userId, equals(user.id));
        expect(assignment.roleId, equals(role.id));
        expect(assignment.isValid, isTrue);
      });

      test('应该检查访问权限', () async {
        final user = await accessControl.createUser(
          username: 'testuser',
          email: 'test@example.com',
          displayName: 'Test User',
          tenantId: 'test-tenant',
        );

        final role = await accessControl.createRole(
          name: 'Test Role',
          type: RoleType.developer,
          description: 'Test role',
          permissions: {Permission.read, Permission.download},
          createdBy: 'admin',
        );

        await accessControl.assignRoleToUser(
          userId: user.id,
          roleId: role.id,
          assignedBy: 'admin',
        );

        final accessRequest = AccessRequest(
          id: 'test-request',
          userId: user.id,
          resourceType: ResourceType.template,
          resourceId: 'test-template',
          permission: Permission.read,
          requestTime: DateTime.now(),
          context: {},
        );

        final decision = await accessControl.checkAccess(accessRequest);
        expect(decision.isAllowed, isTrue);
      });

      test('应该获取访问控制统计', () {
        final stats = accessControl.getAccessControlStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('users'), isTrue);
        expect(stats.containsKey('roles'), isTrue);
        expect(stats.containsKey('assignments'), isTrue);
        expect(stats.containsKey('audit'), isTrue);
      });
    });

    group('LifecycleManager Tests', () {
      late LifecycleManager lifecycleManager;

      setUp(() {
        lifecycleManager = LifecycleManager();
      });

      test('应该创建模板版本', () async {
        final version = await lifecycleManager.createVersion(
          templateId: 'test-template',
          version: '1.0.0',
          description: 'Initial version',
          createdBy: 'developer',
          changelog: ['Initial release'],
        );

        expect(version.templateId, equals('test-template'));
        expect(version.version, equals('1.0.0'));
        expect(version.state, equals(LifecycleState.development));
        expect(version.isReleased, isFalse);
        expect(version.isAvailable, isFalse);
      });

      test('应该请求状态变更', () async {
        final version = await lifecycleManager.createVersion(
          templateId: 'test-template',
          version: '1.0.0',
          description: 'Test version',
          createdBy: 'developer',
        );

        final request = await lifecycleManager.requestStateChange(
          versionId: version.id,
          targetState: LifecycleState.testing,
          requestedBy: 'developer',
          reason: 'Ready for testing',
        );

        expect(request.versionId, equals(version.id));
        expect(request.targetState, equals(LifecycleState.testing));
        expect(request.currentState, equals(LifecycleState.development));
        expect(request.needsApproval, isTrue);
      });

      test('应该生成下一个版本号', () {
        final nextVersion =
            lifecycleManager.generateNextVersion('test-template', '1.0.0');
        expect(nextVersion, equals('1.0.1'));
      });

      test('应该获取生命周期统计', () {
        final stats = lifecycleManager.getLifecycleStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('versions'), isTrue);
        expect(stats.containsKey('approvals'), isTrue);
        expect(stats.containsKey('events'), isTrue);
        expect(stats.containsKey('strategies'), isTrue);
      });
    });

    group('ComplianceChecker Tests', () {
      late ComplianceChecker complianceChecker;

      setUp(() {
        complianceChecker = ComplianceChecker();
      });

      test('应该创建合规规则', () async {
        final rule = ComplianceRule(
          id: 'test-rule',
          name: 'Test Compliance Rule',
          standard: ComplianceStandard.gdpr,
          description: 'Test rule for GDPR compliance',
          ruleType: 'encryption',
          severity: ViolationSeverity.high,
          enabled: true,
          conditions: {'requiresEncryption': true},
          remediation: 'Enable encryption',
          references: ['GDPR Article 32'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await complianceChecker.addRule(rule);

        final rules =
            complianceChecker.getRules(standard: ComplianceStandard.gdpr);
        expect(rules.any((r) => r.id == 'test-rule'), isTrue);
      });

      test('应该执行合规检查', () async {
        final violations = await complianceChecker.performComplianceCheck(
          resourceId: 'test-resource',
          resourceType: 'template',
          resourceData: {
            'id': 'test-resource',
            'type': 'template',
            'encrypted': false,
          },
        );

        expect(violations, isA<List<ComplianceViolation>>());
      });

      test('应该生成合规报告', () async {
        final report = await complianceChecker.generateComplianceReport(
          standard: ComplianceStandard.gdpr,
          periodStart: DateTime.now().subtract(const Duration(days: 30)),
          periodEnd: DateTime.now(),
          name: 'Test GDPR Report',
        );

        expect(report.name, equals('Test GDPR Report'));
        expect(report.standard, equals(ComplianceStandard.gdpr));
        expect(report.complianceScore, greaterThanOrEqualTo(0.0));
        expect(report.complianceScore, lessThanOrEqualTo(100.0));
      });

      test('应该获取违规统计', () {
        final stats = complianceChecker.getViolationStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('total'), isTrue);
        expect(stats.containsKey('open'), isTrue);
        expect(stats.containsKey('byStandard'), isTrue);
        expect(stats.containsKey('bySeverity'), isTrue);
      });
    });

    group('Integration Tests', () {
      test('应该集成私有注册表和访问控制', () async {
        const registryConfig = RegistryConfig(
          id: 'test_registry',
          name: 'Test Registry',
          url: 'https://test.registry.com',
          type: RegistryType.enterprise,
          deploymentMode: DeploymentMode.onPremise,
          authType: AuthenticationType.oauth2,
          authConfig: {},
          multiTenant: true,
          federationEnabled: false,
          syncConfig: {},
          storageConfig: {},
          networkConfig: {},
        );

        final registry = PrivateRegistry(config: registryConfig);
        final accessControl = AccessControl();

        // 创建租户
        final tenant = await registry.createTenant(
          name: 'integration-tenant',
          domain: 'integration.test.com',
        );

        // 创建用户
        final user = await accessControl.createUser(
          username: 'integration-user',
          email: 'integration@test.com',
          displayName: 'Integration User',
          tenantId: tenant.id,
        );

        expect(tenant.name, equals('integration-tenant'));
        expect(user.tenantId, equals(tenant.id));
      });

      test('应该集成生命周期管理和合规检查', () async {
        final lifecycleManager = LifecycleManager();
        final complianceChecker = ComplianceChecker();

        // 创建版本
        final version = await lifecycleManager.createVersion(
          templateId: 'compliance-template',
          version: '1.0.0',
          description: 'Compliance test version',
          createdBy: 'developer',
        );

        // 执行合规检查
        final violations = await complianceChecker.performComplianceCheck(
          resourceId: version.id,
          resourceType: 'template_version',
          resourceData: {
            'id': version.id,
            'templateId': version.templateId,
            'version': version.version,
            'state': version.state.name,
          },
        );

        expect(version.templateId, equals('compliance-template'));
        expect(violations, isA<List<ComplianceViolation>>());
      });

      test('应该完整的企业级管理流程', () async {
        // 创建所有组件
        const registryConfig = RegistryConfig(
          id: 'enterprise_registry',
          name: 'Enterprise Registry',
          url: 'https://enterprise.registry.com',
          type: RegistryType.enterprise,
          deploymentMode: DeploymentMode.cloud,
          authType: AuthenticationType.oauth2,
          authConfig: {},
          multiTenant: true,
          federationEnabled: true,
          syncConfig: {},
          storageConfig: {},
          networkConfig: {},
        );

        final registry = PrivateRegistry(config: registryConfig);
        final accessControl = AccessControl();
        final lifecycleManager = LifecycleManager();
        final complianceChecker = ComplianceChecker();

        // 1. 创建租户
        final tenant = await registry.createTenant(
          name: 'enterprise-tenant',
          domain: 'enterprise.company.com',
        );

        // 2. 创建用户和角色
        final user = await accessControl.createUser(
          username: 'enterprise-user',
          email: 'enterprise@company.com',
          displayName: 'Enterprise User',
          tenantId: tenant.id,
        );

        final role = await accessControl.createRole(
          name: 'Enterprise Developer',
          type: RoleType.developer,
          description: 'Enterprise developer role',
          permissions: {
            Permission.read,
            Permission.download,
            Permission.upload,
          },
          createdBy: 'admin',
        );

        await accessControl.assignRoleToUser(
          userId: user.id,
          roleId: role.id,
          assignedBy: 'admin',
        );

        // 3. 创建模板版本
        final version = await lifecycleManager.createVersion(
          templateId: 'enterprise-template',
          version: '1.0.0',
          description: 'Enterprise template',
          createdBy: user.id,
        );

        // 4. 执行合规检查
        final violations = await complianceChecker.performComplianceCheck(
          resourceId: version.id,
          resourceType: 'template_version',
          resourceData: {
            'id': version.id,
            'templateId': version.templateId,
            'createdBy': user.id,
            'tenantId': tenant.id,
          },
        );

        // 验证集成结果
        expect(tenant.isActive, isTrue);
        expect(user.isActive, isTrue);
        expect(version.state, equals(LifecycleState.development));
        expect(violations, isA<List<ComplianceViolation>>());

        // 获取统计信息
        final registryStats = registry.getRegistryStats();
        final accessStats = accessControl.getAccessControlStats();
        final lifecycleStats = lifecycleManager.getLifecycleStats();
        final complianceStats = complianceChecker.getViolationStats();

        expect(registryStats['tenants']['total'], greaterThan(0));
        expect(accessStats['users']['total'], greaterThan(0));
        expect(lifecycleStats['versions']['total'], greaterThan(0));
        expect(complianceStats, isA<Map<String, dynamic>>());
      });
    });
  });
}
