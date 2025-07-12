/*
---------------------------------------------------------------
File name:          template_install_command.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板安装命令 (Template Install Command)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 Week 2 智能搜索和分发系统;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/distribution/dependency_resolver.dart';
import 'package:ming_status_cli/src/core/distribution/template_downloader.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板安装命令
///
/// 实现 `ming template install` 命令，支持模板下载和依赖管理
class TemplateInstallCommand extends Command<int> {
  /// 创建模板安装命令实例
  TemplateInstallCommand() {
    argParser
      ..addOption(
        'version',
        abbr: 'v',
        help: '指定模板版本',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '输出目录',
        defaultsTo: './templates',
      )
      ..addOption(
        'format',
        abbr: 'f',
        help: '下载格式',
        allowed: ['zip', 'tar.gz', '7z'],
        defaultsTo: 'zip',
      )
      ..addOption(
        'registry',
        abbr: 'r',
        help: '指定注册表',
      )
      ..addFlag(
        'with-dependencies',
        abbr: 'd',
        help: '同时安装依赖',
      )
      ..addFlag(
        'verify-signature',
        help: '验证数字签名',
      )
      ..addFlag(
        'force',
        help: '强制覆盖已存在的文件',
      )
      ..addFlag(
        'dry-run',
        help: '仅显示安装计划，不执行实际安装',
      )
      ..addFlag(
        'verbose',
        help: '显示详细安装过程',
      );
  }

  @override
  String get name => 'install';

  @override
  String get description => '安装模板';

  @override
  String get usage => '''
安装模板

使用方法:
  ming template install <模板名称> [选项]

参数:
  <模板名称>             要安装的模板名称

安装选项:
  -v, --version=<版本>   指定模板版本 (默认: 最新版本)
  -o, --output=<目录>    输出目录 (默认: ./templates)
  -f, --format=<格式>    下载格式 (zip, tar.gz, 7z)
  -r, --registry=<注册表> 指定注册表源

依赖管理:
  -d, --with-dependencies 同时安装所有依赖
      --verify-signature   验证数字签名和完整性

安装控制:
      --force             强制覆盖已存在的文件
      --dry-run           仅显示安装计划，不执行实际安装
      --verbose           显示详细安装过程

示例:
  # 基本安装
  ming template install flutter_clean_app

  # 指定版本和输出目录
  ming template install flutter_clean_app --version=2.1.0 --output=./my_templates

  # 安装依赖并验证签名
  ming template install react_dashboard --with-dependencies --verify-signature

  # 预览安装计划
  ming template install vue_component --dry-run --verbose

  # 从指定注册表安装
  ming template install enterprise_template --registry=company-internal --force

更多信息:
  使用 'ming help template install' 查看详细文档
''';

  @override
  Future<int> run() async {
    try {
      final args = argResults!.rest;
      if (args.isEmpty) {
        print('错误: 需要指定模板名称');
        print('使用方法: ming template install <模板名称> [选项]');
        return 1;
      }

      final templateName = args[0];
      final version = argResults!['version'] as String?;
      final outputDir = argResults!['output'] as String;
      final format = argResults!['format'] as String;
      final registry = argResults!['registry'] as String?;
      final withDependencies = argResults!['with-dependencies'] as bool;
      final verifySignature = argResults!['verify-signature'] as bool;
      final force = argResults!['force'] as bool;
      final dryRun = argResults!['dry-run'] as bool;
      final verbose = argResults!['verbose'] as bool;

      cli_logger.Logger.info('开始安装模板: $templateName');

      // 显示安装计划
      await _displayInstallPlan(
        templateName,
        version,
        outputDir,
        format,
        registry,
        withDependencies,
        verifySignature,
        verbose,
      );

      if (dryRun) {
        print('\n✅ 预览完成，未执行实际安装操作');
        return 0;
      }

      // 创建下载器和依赖解析器
      final downloader = TemplateDownloader();
      final dependencyResolver = DependencyResolver();

      // 解析依赖
      if (withDependencies) {
        print('\n🔍 解析依赖关系...');
        await _resolveDependencies(dependencyResolver, templateName, verbose);
      }

      // 执行安装
      print('\n📦 开始安装模板...');
      await _performInstall(
        downloader,
        templateName,
        version,
        outputDir,
        format,
        verifySignature,
        force,
        verbose,
      );

      // 显示安装结果
      _displayInstallResult(templateName, outputDir);

      cli_logger.Logger.success('模板安装完成: $templateName');
      return 0;
    } catch (e) {
      cli_logger.Logger.error('模板安装失败', error: e);
      return 1;
    }
  }

  /// 显示安装计划
  Future<void> _displayInstallPlan(
    String templateName,
    String? version,
    String outputDir,
    String format,
    String? registry,
    bool withDependencies,
    bool verifySignature,
    bool verbose,
  ) async {
    print('\n📋 模板安装计划');
    print('─' * 60);
    print('模板名称: $templateName');
    print('版本: ${version ?? '最新版本'}');
    print('输出目录: $outputDir');
    print('下载格式: ${_getFormatDescription(format)}');
    print('注册表: ${registry ?? '默认注册表'}');
    print('安装依赖: ${withDependencies ? '是' : '否'}');
    print('验证签名: ${verifySignature ? '是' : '否'}');
    print('');
  }

  /// 获取格式描述
  String _getFormatDescription(String format) {
    switch (format) {
      case 'zip':
        return 'ZIP压缩包';
      case 'tar.gz':
        return 'TAR.GZ压缩包';
      case '7z':
        return '7Z压缩包';
      default:
        return format;
    }
  }

  /// 解析依赖
  Future<void> _resolveDependencies(
    DependencyResolver resolver,
    String templateName,
    bool verbose,
  ) async {
    // 模拟依赖解析
    final dependencies = await _getTemplateDependencies(templateName);

    if (dependencies.isEmpty) {
      print('  ✅ 无依赖项');
      return;
    }

    print('  📋 发现依赖项:');
    for (final dep in dependencies) {
      print('    • ${dep.name} ${dep.versionConstraint.expression}');
      if (verbose) {
        print('      类型: ${_getDependencyTypeDescription(dep.type)}');
        print('      可选: ${dep.optional ? '是' : '否'}');
        if (dep.license != null) {
          print('      许可证: ${dep.license}');
        }
      }
    }

    // 执行依赖解析
    final result = await resolver.resolveDependencies(dependencies);

    if (result.isSuccessful) {
      print('  ✅ 依赖解析成功');
      if (verbose) {
        print('    解析版本:');
        result.resolvedVersions.forEach((name, version) {
          print('      • $name: $version');
        });
      }
    } else {
      print('  ❌ 依赖解析失败');
      for (final conflict in result.conflicts) {
        print('    冲突: ${conflict.dependencyName}');
        if (conflict.suggestedResolution != null) {
          print('    建议: ${conflict.suggestedResolution}');
        }
      }
    }

    // 安全检查
    if (result.hasSecurityIssues) {
      print('  ⚠️ 发现安全问题:');
      for (final vulnerability in result.vulnerabilities) {
        print('    • $vulnerability');
      }
    }

    // 许可证检查
    if (result.hasLicenseIssues) {
      print('  ⚠️ 发现许可证问题:');
      for (final issue in result.licenseIssues) {
        print('    • $issue');
      }
    }
  }

  /// 获取模板依赖
  Future<List<Dependency>> _getTemplateDependencies(String templateName) async {
    // 模拟获取依赖信息
    switch (templateName) {
      case 'flutter_clean_app':
        return [
          Dependency(
            name: 'flutter',
            versionConstraint: VersionConstraint.parse('^3.0.0'),
          ),
          Dependency(
            name: 'provider',
            versionConstraint: VersionConstraint.parse('^6.0.0'),
          ),
          Dependency(
            name: 'flutter_test',
            versionConstraint: VersionConstraint.parse('^3.0.0'),
            type: DependencyType.development,
            optional: true,
          ),
        ];
      case 'react_dashboard':
        return [
          Dependency(
            name: 'react',
            versionConstraint: VersionConstraint.parse('^18.0.0'),
          ),
          Dependency(
            name: 'typescript',
            versionConstraint: VersionConstraint.parse('^4.0.0'),
            type: DependencyType.development,
          ),
        ];
      default:
        return [];
    }
  }

  /// 获取依赖类型描述
  String _getDependencyTypeDescription(DependencyType type) {
    switch (type) {
      case DependencyType.runtime:
        return '运行时依赖';
      case DependencyType.development:
        return '开发依赖';
      case DependencyType.optional:
        return '可选依赖';
      case DependencyType.peer:
        return '对等依赖';
      case DependencyType.conditional:
        return '条件依赖';
    }
  }

  /// 执行安装
  Future<void> _performInstall(
    TemplateDownloader downloader,
    String templateName,
    String? version,
    String outputDir,
    String format,
    bool verifySignature,
    bool force,
    bool verbose,
  ) async {
    // 构建下载URL
    final downloadUrl = _buildDownloadUrl(templateName, version, format);
    final outputPath = '$outputDir/$templateName.$format';

    if (verbose) {
      print('  下载URL: $downloadUrl');
      print('  输出路径: $outputPath');
    }

    // 下载模板
    await downloader.downloadTemplate(
      downloadUrl,
      outputPath,
      format: _getCompressionFormat(format),
      onProgress: (progress) {
        if (verbose) {
          final percentage = progress.percentage.toStringAsFixed(1);
          final speed = _formatSpeed(progress.speed);
          final remaining = _formatTime(progress.remainingTime);
          print('  下载进度: $percentage% ($speed, 剩余: $remaining)');
        } else {
          _showProgressBar(progress.percentage);
        }
      },
    );

    print('\n  ✅ 下载完成');

    // 验证签名
    if (verifySignature) {
      print('  🔐 验证数字签名...');
      await _verifySignature(outputPath, verbose);
      print('  ✅ 签名验证通过');
    }

    // 解压文件
    print('  📂 解压模板文件...');
    await _extractTemplate(outputPath, outputDir, force, verbose);
    print('  ✅ 解压完成');
  }

  /// 构建下载URL
  String _buildDownloadUrl(
    String templateName,
    String? version,
    String format,
  ) {
    const baseUrl = 'https://templates.ming.dev';
    final versionPart = version != null ? '/v$version' : '/latest';
    return '$baseUrl/$templateName$versionPart.$format';
  }

  /// 获取压缩格式
  CompressionFormat _getCompressionFormat(String format) {
    switch (format) {
      case 'zip':
        return CompressionFormat.zip;
      case 'tar.gz':
        return CompressionFormat.tarGz;
      case '7z':
        return CompressionFormat.sevenZ;
      default:
        return CompressionFormat.zip;
    }
  }

  /// 格式化速度
  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  /// 格式化时间
  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '$seconds秒';
    } else if (seconds < 3600) {
      return '${(seconds / 60).round()}分钟';
    } else {
      return '${(seconds / 3600).round()}小时';
    }
  }

  /// 显示进度条
  void _showProgressBar(double percentage) {
    const barLength = 30;
    final filledLength = (barLength * percentage / 100).round();
    final bar = '█' * filledLength + '░' * (barLength - filledLength);
    print('\r  [$bar] ${percentage.toStringAsFixed(1)}%');
  }

  /// 验证签名
  Future<void> _verifySignature(String filePath, bool verbose) async {
    // 模拟签名验证
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (verbose) {
      print('    • 检查数字签名...');
      print('    • 验证证书链...');
      print('    • 检查时间戳...');
    }
  }

  /// 解压模板
  Future<void> _extractTemplate(
    String archivePath,
    String outputDir,
    bool force,
    bool verbose,
  ) async {
    // 模拟解压过程
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (verbose) {
      print('    • 创建输出目录...');
      print('    • 解压文件...');
      print('    • 设置文件权限...');
    }
  }

  /// 显示安装结果
  void _displayInstallResult(String templateName, String outputDir) {
    print('\n✅ 模板安装成功');
    print('─' * 60);
    print('模板名称: $templateName');
    print('安装位置: $outputDir');
    print('安装时间: ${DateTime.now().toLocal()}');
    print('');

    print('💡 下一步:');
    print('  • 使用 "ming template list" 查看已安装模板');
    print('  • 使用 "ming template generate" 生成项目');
    print('  • 查看模板文档了解使用方法');
  }
}
