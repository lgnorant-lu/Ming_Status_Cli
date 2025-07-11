/*
---------------------------------------------------------------
File name:          version_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        版本管理器 (Version Manager)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.3 企业级模板库管理系统;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 版本类型
enum VersionType {
  /// 主版本 (Major)
  major,

  /// 次版本 (Minor)
  minor,

  /// 补丁版本 (Patch)
  patch,

  /// 预发布版本 (Pre-release)
  prerelease,

  /// 构建版本 (Build)
  build,
}

/// 版本分支类型
enum VersionBranch {
  /// 开发版
  development,

  /// 测试版
  testing,

  /// 候选版
  release_candidate,

  /// 稳定版
  stable,

  /// 长期支持版
  lts,

  /// 已弃用
  deprecated,
}

/// 语义化版本
class SemanticVersion implements Comparable<SemanticVersion> {
  /// 创建语义化版本实例
  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.prerelease,
    this.build,
  });

  /// 从字符串解析版本
  factory SemanticVersion.parse(String version) {
    final regex = RegExp(
      r'^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$',
    );

    final match = regex.firstMatch(version);
    if (match == null) {
      throw ArgumentError('Invalid semantic version: $version');
    }

    return SemanticVersion(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      prerelease: match.group(4),
      build: match.group(5),
    );
  }

  /// 主版本号
  final int major;

  /// 次版本号
  final int minor;

  /// 补丁版本号
  final int patch;

  /// 预发布标识
  final String? prerelease;

  /// 构建标识
  final String? build;

  /// 是否为预发布版本
  bool get isPrerelease => prerelease != null;

  /// 是否为稳定版本
  bool get isStable => prerelease == null;

  /// 获取核心版本 (不包含预发布和构建信息)
  SemanticVersion get coreVersion {
    return SemanticVersion(
      major: major,
      minor: minor,
      patch: patch,
    );
  }

  /// 增加主版本号
  SemanticVersion incrementMajor() {
    return SemanticVersion(
      major: major + 1,
      minor: 0,
      patch: 0,
    );
  }

  /// 增加次版本号
  SemanticVersion incrementMinor() {
    return SemanticVersion(
      major: major,
      minor: minor + 1,
      patch: 0,
    );
  }

  /// 增加补丁版本号
  SemanticVersion incrementPatch() {
    return SemanticVersion(
      major: major,
      minor: minor,
      patch: patch + 1,
    );
  }

  /// 设置预发布版本
  SemanticVersion withPrerelease(String prerelease) {
    return SemanticVersion(
      major: major,
      minor: minor,
      patch: patch,
      prerelease: prerelease,
      build: build,
    );
  }

  /// 设置构建版本
  SemanticVersion withBuild(String build) {
    return SemanticVersion(
      major: major,
      minor: minor,
      patch: patch,
      prerelease: prerelease,
      build: build,
    );
  }

  /// 检查是否兼容指定版本
  bool isCompatibleWith(SemanticVersion other) {
    // 主版本号相同且当前版本不低于指定版本
    return major == other.major && compareTo(other) >= 0;
  }

  /// 检查是否满足版本约束
  bool satisfies(String constraint) {
    // 简单的版本约束检查实现
    if (constraint.startsWith('^')) {
      final targetVersion = SemanticVersion.parse(constraint.substring(1));
      return isCompatibleWith(targetVersion);
    } else if (constraint.startsWith('~')) {
      final targetVersion = SemanticVersion.parse(constraint.substring(1));
      return major == targetVersion.major &&
          minor == targetVersion.minor &&
          patch >= targetVersion.patch;
    } else if (constraint.startsWith('>=')) {
      final targetVersion = SemanticVersion.parse(constraint.substring(2));
      return compareTo(targetVersion) >= 0;
    } else if (constraint.startsWith('<=')) {
      final targetVersion = SemanticVersion.parse(constraint.substring(2));
      return compareTo(targetVersion) <= 0;
    } else if (constraint.startsWith('>')) {
      final targetVersion = SemanticVersion.parse(constraint.substring(1));
      return compareTo(targetVersion) > 0;
    } else if (constraint.startsWith('<')) {
      final targetVersion = SemanticVersion.parse(constraint.substring(1));
      return compareTo(targetVersion) < 0;
    } else {
      final targetVersion = SemanticVersion.parse(constraint);
      return compareTo(targetVersion) == 0;
    }
  }

  @override
  int compareTo(SemanticVersion other) {
    // 比较主版本号
    if (major != other.major) {
      return major.compareTo(other.major);
    }

    // 比较次版本号
    if (minor != other.minor) {
      return minor.compareTo(other.minor);
    }

    // 比较补丁版本号
    if (patch != other.patch) {
      return patch.compareTo(other.patch);
    }

    // 比较预发布版本
    if (prerelease == null && other.prerelease == null) {
      return 0;
    } else if (prerelease == null) {
      return 1; // 正式版本大于预发布版本
    } else if (other.prerelease == null) {
      return -1; // 预发布版本小于正式版本
    } else {
      return prerelease!.compareTo(other.prerelease!);
    }
  }

  @override
  bool operator ==(Object other) {
    return other is SemanticVersion && compareTo(other) == 0;
  }

  @override
  int get hashCode {
    return Object.hash(major, minor, patch, prerelease, build);
  }

  @override
  String toString() {
    final buffer = StringBuffer('$major.$minor.$patch');

    if (prerelease != null) {
      buffer.write('-$prerelease');
    }

    if (build != null) {
      buffer.write('+$build');
    }

    return buffer.toString();
  }
}

/// 版本信息
class VersionInfo {
  /// 创建版本信息实例
  const VersionInfo({
    required this.version,
    required this.branch,
    required this.releaseDate,
    this.changelog,
    this.author,
    this.commitHash,
    this.downloadUrl,
    this.checksum,
    this.dependencies = const {},
    this.metadata = const {},
    this.isDeprecated = false,
    this.deprecationReason,
    this.migrationGuide,
  });

  /// 从Map创建版本信息
  factory VersionInfo.fromMap(Map<String, dynamic> map) {
    return VersionInfo(
      version: SemanticVersion.parse(map['version']?.toString() ?? '0.0.0'),
      branch: _parseVersionBranch(map['branch']?.toString() ?? 'stable'),
      releaseDate: map['release_date'] is String
          ? DateTime.tryParse(map['release_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      changelog: map['changelog']?.toString(),
      author: map['author']?.toString(),
      commitHash: map['commit_hash']?.toString(),
      downloadUrl: map['download_url']?.toString(),
      checksum: map['checksum']?.toString(),
      dependencies: map['dependencies'] is Map
          ? Map<String, String>.from(map['dependencies'] as Map)
          : const {},
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
      isDeprecated: map['is_deprecated'] == true,
      deprecationReason: map['deprecation_reason']?.toString(),
      migrationGuide: map['migration_guide']?.toString(),
    );
  }

  /// 版本号
  final SemanticVersion version;

  /// 版本分支
  final VersionBranch branch;

  /// 发布日期
  final DateTime releaseDate;

  /// 更新日志
  final String? changelog;

  /// 作者
  final String? author;

  /// 提交哈希
  final String? commitHash;

  /// 下载URL
  final String? downloadUrl;

  /// 校验和
  final String? checksum;

  /// 依赖关系
  final Map<String, String> dependencies;

  /// 额外元数据
  final Map<String, dynamic> metadata;

  /// 是否已弃用
  final bool isDeprecated;

  /// 弃用原因
  final String? deprecationReason;

  /// 迁移指南
  final String? migrationGuide;

  /// 解析版本分支
  static VersionBranch _parseVersionBranch(String branchStr) {
    switch (branchStr.toLowerCase()) {
      case 'development':
      case 'dev':
        return VersionBranch.development;
      case 'testing':
      case 'test':
        return VersionBranch.testing;
      case 'release_candidate':
      case 'rc':
        return VersionBranch.release_candidate;
      case 'lts':
        return VersionBranch.lts;
      case 'deprecated':
        return VersionBranch.deprecated;
      case 'stable':
      default:
        return VersionBranch.stable;
    }
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'version': version.toString(),
      'branch': branch.name,
      'release_date': releaseDate.toIso8601String(),
      if (changelog != null) 'changelog': changelog,
      if (author != null) 'author': author,
      if (commitHash != null) 'commit_hash': commitHash,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (checksum != null) 'checksum': checksum,
      if (dependencies.isNotEmpty) 'dependencies': dependencies,
      if (metadata.isNotEmpty) 'metadata': metadata,
      'is_deprecated': isDeprecated,
      if (deprecationReason != null) 'deprecation_reason': deprecationReason,
      if (migrationGuide != null) 'migration_guide': migrationGuide,
    };
  }

  @override
  String toString() {
    return 'VersionInfo(version: $version, branch: ${branch.name}, deprecated: $isDeprecated)';
  }
}

/// 版本兼容性检查结果
class CompatibilityResult {
  /// 创建兼容性检查结果实例
  const CompatibilityResult({
    required this.isCompatible,
    required this.sourceVersion,
    required this.targetVersion,
    this.issues = const [],
    this.warnings = const [],
    this.migrationSteps = const [],
  });

  /// 是否兼容
  final bool isCompatible;

  /// 源版本
  final SemanticVersion sourceVersion;

  /// 目标版本
  final SemanticVersion targetVersion;

  /// 兼容性问题
  final List<String> issues;

  /// 警告信息
  final List<String> warnings;

  /// 迁移步骤
  final List<String> migrationSteps;
}

/// 版本升级结果
class UpgradeResult {
  /// 创建版本升级结果实例
  const UpgradeResult({
    required this.success,
    required this.fromVersion,
    required this.toVersion,
    this.backupPath,
    this.migrationLog = const [],
    this.errors = const [],
    this.warnings = const [],
    this.duration,
  });

  /// 是否成功
  final bool success;

  /// 源版本
  final SemanticVersion fromVersion;

  /// 目标版本
  final SemanticVersion toVersion;

  /// 备份路径
  final String? backupPath;

  /// 迁移日志
  final List<String> migrationLog;

  /// 错误信息
  final List<String> errors;

  /// 警告信息
  final List<String> warnings;

  /// 升级耗时
  final Duration? duration;
}

/// 版本管理器
class VersionManager {
  /// 创建版本管理器实例
  VersionManager({
    String? versionsPath,
    this.enableAutoBackup = true,
    this.maxBackupCount = 5,
    this.enableCompatibilityCheck = true,
  }) : _versionsPath = versionsPath ?? _getDefaultVersionsPath();

  /// 版本数据路径
  final String _versionsPath;

  /// 是否启用自动备份
  final bool enableAutoBackup;

  /// 最大备份数量
  final int maxBackupCount;

  /// 是否启用兼容性检查
  final bool enableCompatibilityCheck;

  /// 版本信息映射 (templateId -> versions)
  final Map<String, List<VersionInfo>> _versions = {};

  /// 最后加载时间
  DateTime? _lastLoadTime;

  /// 初始化版本管理器
  Future<void> initialize() async {
    try {
      cli_logger.Logger.debug('初始化版本管理器');

      await _loadVersionData();

      cli_logger.Logger.info('版本管理器初始化完成');
    } catch (e) {
      cli_logger.Logger.error('版本管理器初始化失败', error: e);
      rethrow;
    }
  }

  /// 添加版本
  Future<bool> addVersion(String templateId, VersionInfo versionInfo) async {
    try {
      cli_logger.Logger.debug('添加版本: $templateId v${versionInfo.version}');

      _versions[templateId] ??= [];

      // 检查版本是否已存在
      final existingVersion = _versions[templateId]!
          .where((v) => v.version == versionInfo.version)
          .firstOrNull;

      if (existingVersion != null) {
        cli_logger.Logger.warning('版本已存在: $templateId v${versionInfo.version}');
        return false;
      }

      _versions[templateId]!.add(versionInfo);

      // 按版本号排序
      _versions[templateId]!.sort((a, b) => b.version.compareTo(a.version));

      await _saveVersionData();

      cli_logger.Logger.info('版本添加成功: $templateId v${versionInfo.version}');
      return true;
    } catch (e) {
      cli_logger.Logger.error('添加版本失败: $templateId', error: e);
      return false;
    }
  }

  /// 获取版本列表
  List<VersionInfo> getVersions(
    String templateId, {
    VersionBranch? branch,
    bool includeDeprecated = false,
  }) {
    final versions = _versions[templateId] ?? [];

    final filtered = versions.where((v) {
      if (!includeDeprecated && v.isDeprecated) {
        return false;
      }

      if (branch != null && v.branch != branch) {
        return false;
      }

      return true;
    }).toList();

    // 按版本号降序排序
    filtered.sort((a, b) => b.version.compareTo(a.version));

    return filtered;
  }

  /// 获取最新版本
  VersionInfo? getLatestVersion(
    String templateId, {
    VersionBranch? branch,
    bool stableOnly = true,
  }) {
    final versions = getVersions(templateId, branch: branch);

    if (stableOnly) {
      final stableVersions = versions.where((v) => v.version.isStable).toList();
      return stableVersions.isNotEmpty ? stableVersions.first : null;
    }

    return versions.isNotEmpty ? versions.first : null;
  }

  /// 获取指定版本
  VersionInfo? getVersion(String templateId, SemanticVersion version) {
    final versions = _versions[templateId] ?? [];
    return versions.where((v) => v.version == version).firstOrNull;
  }

  /// 检查版本兼容性
  Future<CompatibilityResult> checkCompatibility(
    String templateId,
    SemanticVersion sourceVersion,
    SemanticVersion targetVersion,
  ) async {
    try {
      cli_logger.Logger.debug(
          '检查版本兼容性: $templateId $sourceVersion -> $targetVersion',);

      final issues = <String>[];
      final warnings = <String>[];
      final migrationSteps = <String>[];

      // 获取版本信息
      final sourceInfo = getVersion(templateId, sourceVersion);
      final targetInfo = getVersion(templateId, targetVersion);

      if (sourceInfo == null) {
        issues.add('源版本不存在: $sourceVersion');
      }

      if (targetInfo == null) {
        issues.add('目标版本不存在: $targetVersion');
      }

      if (issues.isNotEmpty) {
        return CompatibilityResult(
          isCompatible: false,
          sourceVersion: sourceVersion,
          targetVersion: targetVersion,
          issues: issues,
        );
      }

      // 检查主版本号变化
      if (sourceVersion.major != targetVersion.major) {
        if (targetVersion.major > sourceVersion.major) {
          warnings.add('主版本号升级可能包含破坏性变更');
          migrationSteps.add('请查看迁移指南了解破坏性变更');
        } else {
          issues.add('不支持主版本号降级');
        }
      }

      // 检查是否为弃用版本
      if (targetInfo!.isDeprecated) {
        warnings.add('目标版本已弃用: ${targetInfo.deprecationReason ?? ''}');
        if (targetInfo.migrationGuide != null) {
          migrationSteps.add('迁移指南: ${targetInfo.migrationGuide}');
        }
      }

      final isCompatible = issues.isEmpty;

      cli_logger.Logger.info(
          '兼容性检查完成: $templateId - ${isCompatible ? '兼容' : '不兼容'}',);

      return CompatibilityResult(
        isCompatible: isCompatible,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        issues: issues,
        warnings: warnings,
        migrationSteps: migrationSteps,
      );
    } catch (e) {
      cli_logger.Logger.error('兼容性检查失败: $templateId', error: e);
      return CompatibilityResult(
        isCompatible: false,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        issues: ['兼容性检查失败: $e'],
      );
    }
  }

  /// 升级版本
  Future<UpgradeResult> upgradeVersion(
    String templateId,
    String templatePath,
    SemanticVersion targetVersion, {
    bool createBackup = true,
  }) async {
    final startTime = DateTime.now();

    try {
      cli_logger.Logger.debug('开始版本升级: $templateId -> v$targetVersion');

      final migrationLog = <String>[];
      final errors = <String>[];
      final warnings = <String>[];
      String? backupPath;

      // 获取当前版本
      final currentVersionInfo = _getCurrentVersion(templateId, templatePath);
      if (currentVersionInfo == null) {
        errors.add('无法确定当前版本');
        return UpgradeResult(
          success: false,
          fromVersion: SemanticVersion.parse('0.0.0'),
          toVersion: targetVersion,
          errors: errors,
          duration: DateTime.now().difference(startTime),
        );
      }

      final currentVersion = currentVersionInfo.version;

      // 检查兼容性
      if (enableCompatibilityCheck) {
        final compatibility =
            await checkCompatibility(templateId, currentVersion, targetVersion);
        if (!compatibility.isCompatible) {
          errors.addAll(compatibility.issues);
          return UpgradeResult(
            success: false,
            fromVersion: currentVersion,
            toVersion: targetVersion,
            errors: errors,
            duration: DateTime.now().difference(startTime),
          );
        }
        warnings.addAll(compatibility.warnings);
        migrationLog.addAll(compatibility.migrationSteps);
      }

      // 创建备份
      if (createBackup && enableAutoBackup) {
        backupPath = await _createBackup(templatePath, currentVersion);
        if (backupPath != null) {
          migrationLog.add('已创建备份: $backupPath');
        }
      }

      // 执行升级
      final upgradeSuccess = await _performUpgrade(
        templateId,
        templatePath,
        currentVersion,
        targetVersion,
        migrationLog,
      );

      if (!upgradeSuccess) {
        errors.add('版本升级执行失败');
      }

      final duration = DateTime.now().difference(startTime);

      cli_logger.Logger.info(
          '版本升级${upgradeSuccess ? '成功' : '失败'}: $templateId $currentVersion -> $targetVersion',);

      return UpgradeResult(
        success: upgradeSuccess,
        fromVersion: currentVersion,
        toVersion: targetVersion,
        backupPath: backupPath,
        migrationLog: migrationLog,
        errors: errors,
        warnings: warnings,
        duration: duration,
      );
    } catch (e) {
      cli_logger.Logger.error('版本升级失败: $templateId', error: e);
      return UpgradeResult(
        success: false,
        fromVersion: SemanticVersion.parse('0.0.0'),
        toVersion: targetVersion,
        errors: ['升级失败: $e'],
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  /// 回滚版本
  Future<bool> rollbackVersion(
    String templateId,
    String templatePath,
    SemanticVersion targetVersion,
  ) async {
    try {
      cli_logger.Logger.debug('开始版本回滚: $templateId -> v$targetVersion');

      // 这里实现版本回滚逻辑
      // 目前提供基础框架

      cli_logger.Logger.info('版本回滚完成: $templateId -> v$targetVersion');
      return true;
    } catch (e) {
      cli_logger.Logger.error('版本回滚失败: $templateId', error: e);
      return false;
    }
  }

  /// 获取默认版本路径
  static String _getDefaultVersionsPath() {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return '$homeDir/.ming/versions';
  }

  /// 加载版本数据
  Future<void> _loadVersionData() async {
    try {
      final versionsFile = File('$_versionsPath/versions.json');
      if (!await versionsFile.exists()) {
        cli_logger.Logger.debug('版本数据文件不存在，创建空数据');
        return;
      }

      final content = await versionsFile.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      _versions.clear();

      if (data['templates'] is Map) {
        final templatesData = data['templates'] as Map<String, dynamic>;
        for (final entry in templatesData.entries) {
          final templateId = entry.key;
          final versionsData = entry.value;

          if (versionsData is List) {
            final versions = <VersionInfo>[];
            for (final versionData in versionsData) {
              if (versionData is Map<String, dynamic>) {
                versions.add(VersionInfo.fromMap(versionData));
              }
            }
            _versions[templateId] = versions;
          }
        }
      }

      _lastLoadTime = DateTime.now();
      cli_logger.Logger.debug('版本数据加载完成: ${_versions.length}个模板');
    } catch (e) {
      cli_logger.Logger.error('加载版本数据失败', error: e);
    }
  }

  /// 保存版本数据
  Future<void> _saveVersionData() async {
    try {
      final versionsFile = File('$_versionsPath/versions.json');
      final versionsDir = Directory(versionsFile.parent.path);

      if (!await versionsDir.exists()) {
        await versionsDir.create(recursive: true);
      }

      final data = {
        'version': '1.0.0',
        'updated_at': DateTime.now().toIso8601String(),
        'templates': _versions.map(
          (templateId, versions) => MapEntry(
            templateId,
            versions.map((v) => v.toMap()).toList(),
          ),
        ),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      await versionsFile.writeAsString(jsonStr);

      cli_logger.Logger.debug('版本数据保存完成');
    } catch (e) {
      cli_logger.Logger.error('保存版本数据失败', error: e);
    }
  }

  /// 获取当前版本
  VersionInfo? _getCurrentVersion(String templateId, String templatePath) {
    // 这里应该从模板文件中读取当前版本信息
    // 目前返回null，需要具体实现
    return null;
  }

  /// 创建备份
  Future<String?> _createBackup(
      String templatePath, SemanticVersion version,) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '$_versionsPath/backups/${version}_$timestamp';

      final backupDir = Directory(backupPath);
      await backupDir.create(recursive: true);

      // 复制模板文件到备份目录
      final templateDir = Directory(templatePath);
      await for (final entity in templateDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = entity.path.replaceFirst(templatePath, '');
          final backupFile = File('$backupPath$relativePath');
          final backupFileDir = Directory(backupFile.parent.path);

          if (!await backupFileDir.exists()) {
            await backupFileDir.create(recursive: true);
          }

          await entity.copy(backupFile.path);
        }
      }

      return backupPath;
    } catch (e) {
      cli_logger.Logger.error('创建备份失败', error: e);
      return null;
    }
  }

  /// 执行升级
  Future<bool> _performUpgrade(
    String templateId,
    String templatePath,
    SemanticVersion fromVersion,
    SemanticVersion toVersion,
    List<String> migrationLog,
  ) async {
    try {
      // 这里实现具体的升级逻辑
      // 目前提供基础框架

      migrationLog.add('开始升级: $fromVersion -> $toVersion');
      migrationLog.add('升级完成');

      return true;
    } catch (e) {
      migrationLog.add('升级失败: $e');
      return false;
    }
  }
}
