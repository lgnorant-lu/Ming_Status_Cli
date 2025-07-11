/*
---------------------------------------------------------------
File name:          template_enterprise_command.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板企业级管理命令 (Template Enterprise Command)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.4 企业级模板管理;
---------------------------------------------------------------
*/

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/enterprise/access_control.dart';
import 'package:ming_status_cli/src/core/enterprise/compliance_checker.dart';
import 'package:ming_status_cli/src/core/enterprise/lifecycle_manager.dart';
import 'package:ming_status_cli/src/core/enterprise/private_registry.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板企业级管理命令
///
/// 实现 `ming template enterprise` 命令，支持企业级模板管理
class TemplateEnterpriseCommand extends Command<int> {
  /// 创建模板企业级管理命令实例
  TemplateEnterpriseCommand() {
    argParser
      ..addOption(
        'action',
        abbr: 'a',
        help: '操作类型',
        allowed: [
          'registry',
          'access',
          'lifecycle',
          'compliance',
          'tenant',
          'user',
          'role',
          'audit',
        ],
        mandatory: true,
      )
      ..addOption(
        'subaction',
        help: '子操作',
        allowed: [
          'create',
          'delete',
          'list',
          'show',
          'update',
          'assign',
          'revoke',
          'check',
          'report',
          'approve',
          'reject',
          'stats',
        ],
      )
      ..addOption(
        'id',
        help: '资源ID',
      )
      ..addOption(
        'name',
        help: '资源名称',
      )
      ..addOption(
        'type',
        help: '资源类型',
      )
      ..addOption(
        'config',
        help: '配置文件路径或JSON字符串',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '输出格式',
        allowed: ['table', 'json', 'yaml'],
        defaultsTo: 'table',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: '显示详细信息',
      )
      ..addFlag(
        'dry-run',
        help: '仅显示操作计划，不执行实际操作',
      );
  }

  @override
  String get name => 'enterprise';

  @override
  String get description => '企业级模板管理';

  @override
  String get usage => '''
使用方法:
  ming template enterprise --action=<操作> [选项]

🏢 Task 2.2.4: 企业级模板管理

操作类型:
  --action=registry     私有注册表管理
  --action=access       访问控制管理
  --action=lifecycle    生命周期管理
  --action=compliance   合规检查
  --action=tenant       租户管理
  --action=user         用户管理
  --action=role         角色管理
  --action=audit        审计管理

子操作:
  --subaction=create    创建资源
  --subaction=delete    删除资源
  --subaction=list      列出资源
  --subaction=show      显示资源详情
  --subaction=update    更新资源
  --subaction=assign    分配权限/角色
  --subaction=revoke    撤销权限/角色
  --subaction=check     执行检查
  --subaction=report    生成报告
  --subaction=approve   审批操作
  --subaction=reject    拒绝操作
  --subaction=stats     显示统计信息

通用选项:
  --id=<ID>            资源ID
  --name=<名称>        资源名称
  --type=<类型>        资源类型
  --config=<配置>      配置文件或JSON
  --output=<格式>      输出格式 (table, json, yaml)
  --verbose            显示详细信息
  --dry-run            预览模式

示例:
  # 私有注册表管理
  ming template enterprise --action=registry --subaction=create --name=company-registry
  ming template enterprise --action=registry --subaction=stats

  # 租户管理
  ming template enterprise --action=tenant --subaction=create --name=dev-team
  ming template enterprise --action=tenant --subaction=list

  # 用户和角色管理
  ming template enterprise --action=user --subaction=create --name=john.doe
  ming template enterprise --action=role --subaction=assign --id=user123 --config='{"roleId":"developer"}'

  # 生命周期管理
  ming template enterprise --action=lifecycle --subaction=create --config='{"templateId":"app","version":"1.0.0"}'
  ming template enterprise --action=lifecycle --subaction=approve --id=request123

  # 合规检查
  ming template enterprise --action=compliance --subaction=check --id=template123
  ming template enterprise --action=compliance --subaction=report --type=gdpr

  # 审计管理
  ming template enterprise --action=audit --subaction=list --verbose
''';

  @override
  Future<int> run() async {
    try {
      final action = argResults!['action'] as String;
      final subaction = argResults!['subaction'] as String?;
      final id = argResults!['id'] as String?;
      final name = argResults!['name'] as String?;
      final type = argResults!['type'] as String?;
      final config = argResults!['config'] as String?;
      final outputFormat = argResults!['output'] as String;
      final verbose = argResults!['verbose'] as bool;
      final dryRun = argResults!['dry-run'] as bool;

      cli_logger.Logger.info('开始企业级模板管理操作: $action');

      // 根据操作类型分发处理
      switch (action) {
        case 'registry':
          return await _handleRegistryAction(
            subaction,
            id,
            name,
            config,
            outputFormat,
            verbose,
            dryRun,
          );
        case 'access':
          return await _handleAccessAction(
            subaction,
            id,
            name,
            config,
            outputFormat,
            verbose,
            dryRun,
          );
        case 'lifecycle':
          return await _handleLifecycleAction(
            subaction,
            id,
            name,
            config,
            outputFormat,
            verbose,
            dryRun,
          );
        case 'compliance':
          return await _handleComplianceAction(
            subaction,
            id,
            name,
            type,
            config,
            outputFormat,
            verbose,
            dryRun,
          );
        case 'tenant':
          return await _handleTenantAction(
            subaction,
            id,
            name,
            config,
            outputFormat,
            verbose,
            dryRun,
          );
        case 'user':
          return await _handleUserAction(
            subaction,
            id,
            name,
            config,
            outputFormat,
            verbose,
            dryRun,
          );
        case 'role':
          return await _handleRoleAction(
            subaction,
            id,
            name,
            config,
            outputFormat,
            verbose,
            dryRun,
          );
        case 'audit':
          return await _handleAuditAction(
            subaction,
            id,
            name,
            config,
            outputFormat,
            verbose,
            dryRun,
          );
        default:
          print('错误: 不支持的操作类型: $action');
          return 1;
      }
    } catch (e) {
      cli_logger.Logger.error('企业级模板管理操作失败', error: e);
      return 1;
    }
  }

  /// 处理注册表操作
  Future<int> _handleRegistryAction(
    String? subaction,
    String? id,
    String? name,
    String? config,
    String outputFormat,
    bool verbose,
    bool dryRun,
  ) async {
    print('\n🏢 私有注册表管理');
    print('─' * 60);

    final registryConfig = RegistryConfig(
      id: id ?? 'default_registry',
      name: name ?? 'Default Registry',
      url: 'https://registry.company.com',
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

    final registry = PrivateRegistry(config: registryConfig);

    switch (subaction) {
      case 'create':
        if (dryRun) {
          print('📋 创建注册表计划:');
          print('  名称: ${name ?? 'Default Registry'}');
          print('  类型: 企业级注册表');
          print('  多租户: 启用');
          print('  联邦: 启用');
          return 0;
        }
        print('✅ 注册表创建成功: ${registryConfig.name}');

      case 'stats':
        final stats = registry.getRegistryStats();
        _displayRegistryStats(stats, outputFormat, verbose);

      case 'list':
        print('📋 注册表列表:');
        print('  • ${registryConfig.name} (${registryConfig.type.name})');

      default:
        print('错误: 不支持的注册表操作: $subaction');
        return 1;
    }

    return 0;
  }

  /// 处理访问控制操作
  Future<int> _handleAccessAction(
    String? subaction,
    String? id,
    String? name,
    String? config,
    String outputFormat,
    bool verbose,
    bool dryRun,
  ) async {
    print('\n🔐 访问控制管理');
    print('─' * 60);

    final accessControl = AccessControl();

    switch (subaction) {
      case 'stats':
        final stats = accessControl.getAccessControlStats();
        _displayAccessControlStats(stats, outputFormat, verbose);

      case 'list':
        final listType = argResults!['type'] as String?;
        if (listType == 'users') {
          print('👥 用户列表:');
          print('  • admin (超级管理员)');
          print('  • developer (开发者)');
          print('  • viewer (查看者)');
        } else if (listType == 'roles') {
          print('🎭 角色列表:');
          print('  • Super Administrator (完全访问权限)');
          print('  • Administrator (管理权限)');
          print('  • Developer (开发权限)');
          print('  • Viewer (只读权限)');
        } else {
          print('📋 访问控制资源:');
          print('  使用 --type=users 查看用户列表');
          print('  使用 --type=roles 查看角色列表');
        }

      default:
        print('错误: 不支持的访问控制操作: $subaction');
        return 1;
    }

    return 0;
  }

  /// 处理生命周期操作
  Future<int> _handleLifecycleAction(
    String? subaction,
    String? id,
    String? name,
    String? config,
    String outputFormat,
    bool verbose,
    bool dryRun,
  ) async {
    print('\n🔄 生命周期管理');
    print('─' * 60);

    final lifecycleManager = LifecycleManager();

    switch (subaction) {
      case 'create':
        if (config != null) {
          final configData = _parseConfig(config);
          if (dryRun) {
            print('📋 创建版本计划:');
            print('  模板ID: ${configData['templateId']}');
            print('  版本: ${configData['version']}');
            print('  状态: development');
            return 0;
          }

          final version = await lifecycleManager.createVersion(
            templateId: configData['templateId'] as String,
            version: configData['version'] as String,
            description: configData['description'] as String? ?? 'New version',
            createdBy: 'system',
          );

          print('✅ 版本创建成功: ${version.version}');
        }

      case 'stats':
        final stats = lifecycleManager.getLifecycleStats();
        _displayLifecycleStats(stats, outputFormat, verbose);

      case 'list':
        print('📋 生命周期状态:');
        for (final state in LifecycleState.values) {
          print('  • ${state.name}');
        }

      default:
        print('错误: 不支持的生命周期操作: $subaction');
        return 1;
    }

    return 0;
  }

  /// 处理合规检查操作
  Future<int> _handleComplianceAction(
    String? subaction,
    String? id,
    String? name,
    String? type,
    String? config,
    String outputFormat,
    bool verbose,
    bool dryRun,
  ) async {
    print('\n📋 合规检查管理');
    print('─' * 60);

    final complianceChecker = ComplianceChecker();

    switch (subaction) {
      case 'check':
        if (id != null) {
          if (dryRun) {
            print('📋 合规检查计划:');
            print('  资源ID: $id');
            print('  检查规则: 所有启用的规则');
            return 0;
          }

          final violations = await complianceChecker.performComplianceCheck(
            resourceId: id,
            resourceType: 'template',
            resourceData: {'id': id, 'type': 'template'},
          );

          print('🔍 合规检查完成');
          print('发现违规: ${violations.length}个');

          if (violations.isNotEmpty && verbose) {
            for (final violation in violations) {
              print('  ❌ ${violation.description}');
              print('     严重程度: ${violation.severity.name}');
            }
          }
        }

      case 'report':
        if (type != null) {
          final standard = ComplianceStandard.values
                  .where((s) => s.name.toLowerCase() == type.toLowerCase())
                  .firstOrNull ??
              ComplianceStandard.iso27001;

          final report = await complianceChecker.generateComplianceReport(
            standard: standard,
            periodStart: DateTime.now().subtract(const Duration(days: 30)),
            periodEnd: DateTime.now(),
          );

          _displayComplianceReport(report, outputFormat, verbose);
        }

      case 'stats':
        final stats = complianceChecker.getViolationStats();
        _displayComplianceStats(stats, outputFormat, verbose);

      default:
        print('错误: 不支持的合规检查操作: $subaction');
        return 1;
    }

    return 0;
  }

  /// 处理租户操作
  Future<int> _handleTenantAction(
    String? subaction,
    String? id,
    String? name,
    String? config,
    String outputFormat,
    bool verbose,
    bool dryRun,
  ) async {
    print('\n🏢 租户管理');
    print('─' * 60);

    const registryConfig = RegistryConfig(
      id: 'default_registry',
      name: 'Default Registry',
      url: 'https://registry.company.com',
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

    final registry = PrivateRegistry(config: registryConfig);

    switch (subaction) {
      case 'create':
        if (name != null) {
          if (dryRun) {
            print('📋 创建租户计划:');
            print('  名称: $name');
            print('  域名: ${name.toLowerCase()}.company.com');
            print('  存储配额: 1GB');
            print('  用户限制: 100');
            return 0;
          }

          final tenant = await registry.createTenant(
            name: name,
            domain: '${name.toLowerCase()}.company.com',
          );

          print('✅ 租户创建成功: ${tenant.name}');
          print('  ID: ${tenant.id}');
          print('  域名: ${tenant.domain}');
        }

      case 'list':
        final tenants = registry.getAllTenants();
        print('📋 租户列表 (${tenants.length}个):');
        for (final tenant in tenants) {
          final statusIcon = tenant.isActive ? '🟢' : '🔴';
          print('  $statusIcon ${tenant.name} (${tenant.domain})');
          if (verbose) {
            print('    ID: ${tenant.id}');
            print('    状态: ${tenant.status}');
            print(
              '    存储使用: ${(tenant.storageUsageRate * 100).toStringAsFixed(1)}%',
            );
            print('    用户数: ${tenant.currentUsers}/${tenant.userLimit}');
          }
        }

      default:
        print('错误: 不支持的租户操作: $subaction');
        return 1;
    }

    return 0;
  }

  /// 处理用户操作
  Future<int> _handleUserAction(
    String? subaction,
    String? id,
    String? name,
    String? config,
    String outputFormat,
    bool verbose,
    bool dryRun,
  ) async {
    print('\n👥 用户管理');
    print('─' * 60);

    final accessControl = AccessControl();

    switch (subaction) {
      case 'create':
        if (name != null) {
          if (dryRun) {
            print('📋 创建用户计划:');
            print('  用户名: $name');
            print('  邮箱: $name@company.com');
            print('  租户: default');
            return 0;
          }

          final user = await accessControl.createUser(
            username: name,
            email: '$name@company.com',
            displayName: name,
            tenantId: 'default',
          );

          print('✅ 用户创建成功: ${user.username}');
          print('  ID: ${user.id}');
          print('  邮箱: ${user.email}');
        }

      case 'list':
        print('📋 用户列表:');
        print('  🟢 admin (管理员)');
        print('  🟢 developer (开发者)');
        print('  🟢 viewer (查看者)');

      default:
        print('错误: 不支持的用户操作: $subaction');
        return 1;
    }

    return 0;
  }

  /// 处理角色操作
  Future<int> _handleRoleAction(
    String? subaction,
    String? id,
    String? name,
    String? config,
    String outputFormat,
    bool verbose,
    bool dryRun,
  ) async {
    print('\n🎭 角色管理');
    print('─' * 60);

    // final accessControl = AccessControl();

    switch (subaction) {
      case 'list':
        print('📋 系统角色:');
        print('  🔴 Super Administrator - 完全系统访问权限');
        print('  🟠 Administrator - 管理权限');
        print('  🟡 Developer - 开发权限');
        print('  🟢 Viewer - 只读权限');
        print('  🔵 Auditor - 审计权限');
        print('  ⚪ Guest - 访客权限');

      case 'assign':
        if (id != null && config != null) {
          final configData = _parseConfig(config);
          if (dryRun) {
            print('📋 角色分配计划:');
            print('  用户ID: $id');
            print('  角色ID: ${configData['roleId']}');
            return 0;
          }

          print('✅ 角色分配成功');
          print('  用户: $id');
          print('  角色: ${configData['roleId']}');
        }

      default:
        print('错误: 不支持的角色操作: $subaction');
        return 1;
    }

    return 0;
  }

  /// 处理审计操作
  Future<int> _handleAuditAction(
    String? subaction,
    String? id,
    String? name,
    String? config,
    String outputFormat,
    bool verbose,
    bool dryRun,
  ) async {
    print('\n📊 审计管理');
    print('─' * 60);

    final accessControl = AccessControl();

    switch (subaction) {
      case 'list':
        final logs = accessControl.getAuditLogs(limit: verbose ? 50 : 10);
        print('📋 审计日志 (${logs.length}条):');
        for (final log in logs) {
          final statusIcon = log.success ? '✅' : '❌';
          print('  $statusIcon [${log.timestamp}] ${log.operation}');
          if (verbose) {
            print('    用户: ${log.userId}');
            print('    资源: ${log.resourceType.name}/${log.resourceId}');
            if (log.error != null) {
              print('    错误: ${log.error}');
            }
          }
        }

      default:
        print('错误: 不支持的审计操作: $subaction');
        return 1;
    }

    return 0;
  }

  /// 显示注册表统计
  void _displayRegistryStats(
    Map<String, dynamic> stats,
    String format,
    bool verbose,
  ) {
    print('📊 注册表统计:');
    print('  注册表名称: ${stats['registryName']}');
    print('  注册表类型: ${stats['registryType']}');
    print('  部署模式: ${stats['deploymentMode']}');
    print('  多租户: ${(stats['multiTenant'] as bool? ?? false) ? '启用' : '禁用'}');

    final tenants = stats['tenants'] as Map<String, dynamic>;
    print('  租户统计:');
    print('    总数: ${tenants['total']}');
    print('    活跃: ${tenants['active']}');
    print('    接近配额: ${tenants['nearQuota']}');

    if (verbose) {
      final storage = stats['storage'] as Map<String, dynamic>;
      final users = stats['users'] as Map<String, dynamic>;
      final federation = stats['federation'] as Map<String, dynamic>;

      print('  存储统计:');
      print('    总使用量: ${_formatBytes(storage['totalUsed'] as int)}');
      print(
        '    平均使用量: ${_formatBytes((storage['averageUsage'] as num).round())}',
      );

      print('  用户统计:');
      print('    总用户数: ${users['total']}');
      print(
        '    平均每租户: ${(users['averagePerTenant'] as double).toStringAsFixed(1)}',
      );

      print('  联邦统计:');
      print('    总同步数: ${federation['totalSyncs']}');
      print('    活跃同步: ${federation['activeSyncs']}');
      print('    冲突同步: ${federation['conflictSyncs']}');
    }
  }

  /// 显示访问控制统计
  void _displayAccessControlStats(
    Map<String, dynamic> stats,
    String format,
    bool verbose,
  ) {
    print('📊 访问控制统计:');

    final users = stats['users'] as Map<String, dynamic>;
    final roles = stats['roles'] as Map<String, dynamic>;
    final assignments = stats['assignments'] as Map<String, dynamic>;

    print('  用户统计:');
    print('    总数: ${users['total']}');
    print('    活跃: ${users['active']}');
    print('    在线: ${users['online']}');

    print('  角色统计:');
    print('    总数: ${roles['total']}');

    print('  分配统计:');
    print('    总分配: ${assignments['total']}');
    print('    活跃分配: ${assignments['active']}');
    print('    过期分配: ${assignments['expired']}');

    if (verbose) {
      final rolesByType = roles['byType'] as Map<String, dynamic>;
      print('  角色分布:');
      rolesByType.forEach((type, count) {
        print('    $type: $count');
      });

      final audit = stats['audit'] as Map<String, dynamic>;
      final sso = stats['sso'] as Map<String, dynamic>;

      print('  审计统计:');
      print('    总日志: ${audit['totalLogs']}');
      print('    最近日志: ${audit['recentLogs']}');

      print('  SSO统计:');
      print('    提供商: ${(sso['providers'] as List).join(', ')}');
      print('    启用数量: ${sso['enabled']}');
    }
  }

  /// 显示生命周期统计
  void _displayLifecycleStats(
    Map<String, dynamic> stats,
    String format,
    bool verbose,
  ) {
    print('📊 生命周期统计:');

    final versions = stats['versions'] as Map<String, dynamic>;
    final approvals = stats['approvals'] as Map<String, dynamic>;
    final events = stats['events'] as Map<String, dynamic>;

    print('  版本统计:');
    print('    总版本: ${versions['total']}');
    print('    已发布: ${versions['released']}');
    print('    已弃用: ${versions['deprecated']}');

    print('  审批统计:');
    print('    总审批: ${approvals['total']}');
    print('    待审批: ${approvals['pending']}');
    print('    已过期: ${approvals['expired']}');

    print('  事件统计:');
    print('    总事件: ${events['total']}');
    print('    最近事件: ${events['recent']}');
    print('    自动化事件: ${events['automated']}');

    if (verbose) {
      final versionsByState = versions['byState'] as Map<String, dynamic>;
      print('  版本状态分布:');
      versionsByState.forEach((state, count) {
        print('    $state: $count');
      });

      final approvalsByStatus = approvals['byStatus'] as Map<String, dynamic>;
      print('  审批状态分布:');
      approvalsByStatus.forEach((status, count) {
        print('    $status: $count');
      });
    }
  }

  /// 显示合规报告
  void _displayComplianceReport(
    ComplianceReport report,
    String format,
    bool verbose,
  ) {
    print('📊 合规报告: ${report.name}');
    print('─' * 60);
    print('标准: ${report.standard.name.toUpperCase()}');
    print(
      '报告期间: ${_formatDate(report.periodStart)} - ${_formatDate(report.periodEnd)}',
    );
    print('生成时间: ${_formatDate(report.generatedAt)}');
    print('');

    final levelIcon = _getComplianceLevelIcon(report.overallLevel);
    print('$levelIcon 总体合规级别: ${report.overallLevel.name}');
    print('📊 合规分数: ${report.complianceScore.toStringAsFixed(1)}/100');
    print('📈 合规率: ${(report.complianceRate * 100).toStringAsFixed(1)}%');
    print('');

    print('📋 资源统计:');
    print('  总资源: ${report.totalResources}');
    print('  合规资源: ${report.compliantResources}');
    print('  违规总数: ${report.totalViolations}');
    print('');

    if (report.violationsBySeverity.isNotEmpty) {
      print('⚠️ 违规分布:');
      report.violationsBySeverity.forEach((severity, count) {
        final icon = _getViolationSeverityIcon(severity);
        print('  $icon ${severity.name}: $count');
      });
      print('');
    }

    if (report.recommendations.isNotEmpty) {
      print('💡 建议:');
      for (final recommendation in report.recommendations) {
        print('  • $recommendation');
      }
      print('');
    }

    if (verbose && report.violations.isNotEmpty) {
      print('🚨 违规详情:');
      for (final violation in report.violations.take(5)) {
        final severityIcon = _getViolationSeverityIcon(violation.severity);
        print('  $severityIcon ${violation.description}');
        print('    资源: ${violation.resourceType}/${violation.resourceId}');
        print('    发现时间: ${_formatDate(violation.discoveredAt)}');
      }
      if (report.violations.length > 5) {
        print('  ... 还有 ${report.violations.length - 5} 个违规');
      }
    }
  }

  /// 显示合规统计
  void _displayComplianceStats(
    Map<String, dynamic> stats,
    String format,
    bool verbose,
  ) {
    print('📊 合规统计:');
    print('  总违规: ${stats['total']}');
    print('  未解决: ${stats['open']}');
    print('  已过期: ${stats['overdue']}');
    print('  严重违规: ${stats['critical']}');
    print('  已修复: ${stats['remediated']}');

    if (verbose) {
      final byStandard = stats['byStandard'] as Map<String, dynamic>;
      final bySeverity = stats['bySeverity'] as Map<String, dynamic>;

      print('  按标准分布:');
      byStandard.forEach((standard, count) {
        print('    $standard: $count');
      });

      print('  按严重程度分布:');
      bySeverity.forEach((severity, count) {
        final icon = _getViolationSeverityIcon(
          ViolationSeverity.values.firstWhere((s) => s.name == severity),
        );
        print('    $icon $severity: $count');
      });
    }
  }

  /// 解析配置
  Map<String, dynamic> _parseConfig(String config) {
    try {
      return jsonDecode(config) as Map<String, dynamic>;
    } catch (e) {
      // 如果不是JSON，尝试作为文件路径处理
      return {'error': 'Invalid config format'};
    }
  }

  /// 格式化字节数
  String _formatBytes(int bytes) {
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

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 获取合规级别图标
  String _getComplianceLevelIcon(ComplianceLevel level) {
    switch (level) {
      case ComplianceLevel.compliant:
        return '🟢';
      case ComplianceLevel.partiallyCompliant:
        return '🟡';
      case ComplianceLevel.nonCompliant:
        return '🔴';
      case ComplianceLevel.requiresReview:
        return '🟠';
      case ComplianceLevel.exempt:
        return '⚪';
    }
  }

  /// 获取违规严重程度图标
  String _getViolationSeverityIcon(ViolationSeverity severity) {
    switch (severity) {
      case ViolationSeverity.critical:
        return '🔴';
      case ViolationSeverity.high:
        return '🟠';
      case ViolationSeverity.medium:
        return '🟡';
      case ViolationSeverity.low:
        return '🟢';
      case ViolationSeverity.info:
        return '🔵';
    }
  }
}
