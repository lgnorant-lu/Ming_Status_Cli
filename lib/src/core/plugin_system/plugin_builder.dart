/*
---------------------------------------------------------------
File name:          plugin_builder.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件构建器核心实现 (Plugin builder core implementation)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 插件构建核心逻辑;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// 插件构建结果
class PluginBuildResult {
  /// 是否构建成功
  final bool isSuccess;

  /// 构建输出路径
  final String? outputPath;

  /// 构建的文件列表
  final List<String> builtFiles;

  /// 构建错误列表
  final List<String> errors;

  /// 构建警告列表
  final List<String> warnings;

  /// 构建详情
  final Map<String, dynamic> details;

  /// 构造函数
  PluginBuildResult({
    required this.isSuccess,
    this.outputPath,
    required this.builtFiles,
    required this.errors,
    required this.warnings,
    required this.details,
  });

  /// 转换为JSON字符串
  String toJson() {
    return jsonEncode({
      'isSuccess': isSuccess,
      'outputPath': outputPath,
      'builtFiles': builtFiles,
      'errors': errors,
      'warnings': warnings,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

/// 插件构建器
///
/// 负责构建插件包，生成可分发的插件文件。
class PluginBuilder {
  /// 构建插件
  ///
  /// [pluginPath] 插件项目路径
  /// [outputPath] 输出目录路径
  /// [isRelease] 是否为发布版本
  Future<PluginBuildResult> buildPlugin(
    String pluginPath, {
    String outputPath = './dist',
    bool isRelease = false,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final builtFiles = <String>[];
    final details = <String, dynamic>{};

    try {
      // 1. 验证插件项目
      final validationResult = await _validatePluginForBuild(pluginPath);
      if (!(validationResult['isValid'] as bool)) {
        errors.addAll(validationResult['errors'] as List<String>);
        return PluginBuildResult(
          isSuccess: false,
          builtFiles: builtFiles,
          errors: errors,
          warnings: warnings,
          details: details,
        );
      }

      // 2. 准备构建环境
      await _prepareBuildEnvironment(outputPath);

      // 3. 读取插件清单
      final manifest = await _loadPluginManifest(pluginPath);
      details['manifest'] = manifest;

      // 4. 构建Dart代码
      final dartBuildResult = await _buildDartCode(pluginPath, isRelease);
      if (!(dartBuildResult['success'] as bool)) {
        errors.addAll(dartBuildResult['errors'] as List<String>);
      }
      warnings.addAll(dartBuildResult['warnings'] as List<String>);
      builtFiles.addAll(dartBuildResult['files'] as List<String>);

      // 5. 复制资源文件
      final assetResult = await _copyAssets(pluginPath, outputPath);
      builtFiles.addAll(assetResult['files'] as List<String>);

      // 6. 生成插件包
      final packagePath = await _createPluginPackage(
        pluginPath,
        outputPath,
        manifest,
        isRelease,
      );
      builtFiles.add(packagePath);

      // 7. 生成构建报告
      await _generateBuildReport(outputPath, details);

      return PluginBuildResult(
        isSuccess: errors.isEmpty,
        outputPath: packagePath,
        builtFiles: builtFiles,
        errors: errors,
        warnings: warnings,
        details: details,
      );
    } catch (e) {
      errors.add('构建过程中发生错误: $e');
      return PluginBuildResult(
        isSuccess: false,
        builtFiles: builtFiles,
        errors: errors,
        warnings: warnings,
        details: details,
      );
    }
  }

  /// 验证插件是否可以构建
  Future<Map<String, dynamic>> _validatePluginForBuild(
      String pluginPath) async {
    final errors = <String>[];

    // 检查必需文件
    final requiredFiles = [
      'pubspec.yaml',
      'plugin.yaml',
      'lib',
    ];

    for (final file in requiredFiles) {
      final filePath = path.join(pluginPath, file);
      final entityType = FileSystemEntity.typeSync(filePath);
      if (entityType == FileSystemEntityType.notFound) {
        errors.add('缺少必需文件: $file');
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }

  /// 准备构建环境
  Future<void> _prepareBuildEnvironment(String outputPath) async {
    final outputDir = Directory(outputPath);
    if (outputDir.existsSync()) {
      await outputDir.delete(recursive: true);
    }
    await outputDir.create(recursive: true);
  }

  /// 加载插件清单
  Future<Map<String, dynamic>> _loadPluginManifest(String pluginPath) async {
    final manifestPath = path.join(pluginPath, 'plugin.yaml');
    final manifestFile = File(manifestPath);

    if (!manifestFile.existsSync()) {
      throw Exception('plugin.yaml文件不存在');
    }

    final manifestContent = await manifestFile.readAsString();
    final manifest = loadYaml(manifestContent) as Map;

    return Map<String, dynamic>.from(manifest);
  }

  /// 构建Dart代码
  Future<Map<String, dynamic>> _buildDartCode(
    String pluginPath,
    bool isRelease,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];
    final files = <String>[];

    try {
      // 运行dart analyze
      final analyzeResult = await Process.run(
        'dart',
        ['analyze', '--no-fatal-infos'],
        workingDirectory: pluginPath,
      );

      if (analyzeResult.exitCode != 0) {
        warnings.add('代码分析发现问题: ${analyzeResult.stderr}');
      }

      // 运行dart compile (如果是发布版本)
      if (isRelease) {
        // TODO: 实现Dart代码编译
        warnings.add('发布版本编译功能正在开发中');
      }

      files.add('lib/');
    } catch (e) {
      errors.add('Dart代码构建失败: $e');
    }

    return {
      'success': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'files': files,
    };
  }

  /// 复制资源文件
  Future<Map<String, dynamic>> _copyAssets(
    String pluginPath,
    String outputPath,
  ) async {
    final files = <String>[];

    // 复制必需文件
    final filesToCopy = [
      'pubspec.yaml',
      'plugin.yaml',
      'README.md',
      'CHANGELOG.md',
      'LICENSE',
    ];

    for (final fileName in filesToCopy) {
      final sourcePath = path.join(pluginPath, fileName);
      final sourceFile = File(sourcePath);

      if (sourceFile.existsSync()) {
        final targetPath = path.join(outputPath, fileName);
        await sourceFile.copy(targetPath);
        files.add(fileName);
      }
    }

    // 复制lib目录
    final libDir = Directory(path.join(pluginPath, 'lib'));
    if (libDir.existsSync()) {
      final targetLibDir = Directory(path.join(outputPath, 'lib'));
      await _copyDirectory(libDir, targetLibDir);
      files.add('lib/');
    }

    // 复制assets目录（如果存在）
    final assetsDir = Directory(path.join(pluginPath, 'assets'));
    if (assetsDir.existsSync()) {
      final targetAssetsDir = Directory(path.join(outputPath, 'assets'));
      await _copyDirectory(assetsDir, targetAssetsDir);
      files.add('assets/');
    }

    return {
      'files': files,
    };
  }

  /// 创建插件包
  Future<String> _createPluginPackage(
    String pluginPath,
    String outputPath,
    Map<String, dynamic> manifest,
    bool isRelease,
  ) async {
    final pluginName = (manifest['plugin']?['id'] ??
        manifest['id'] ??
        path.basename(pluginPath)) as String;
    final version = (manifest['plugin']?['version'] ??
        manifest['version'] ??
        '1.0.0') as String;

    final packageName = '$pluginName-$version.zip';
    final packagePath = path.join(outputPath, packageName);

    // 创建ZIP包
    final archive = Archive();
    final outputDir = Directory(outputPath);

    await for (final entity in outputDir.list(recursive: true)) {
      if (entity is File && entity.path != packagePath) {
        final relativePath = path.relative(entity.path, from: outputPath);
        final fileBytes = await entity.readAsBytes();
        final archiveFile =
            ArchiveFile(relativePath, fileBytes.length, fileBytes);
        archive.addFile(archiveFile);
      }
    }

    // 写入ZIP文件
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    final packageFile = File(packagePath);
    await packageFile.writeAsBytes(zipBytes);

    return packagePath;
  }

  /// 生成构建报告
  Future<void> _generateBuildReport(
    String outputPath,
    Map<String, dynamic> details,
  ) async {
    final reportPath = path.join(outputPath, 'build_report.json');
    final reportFile = File(reportPath);

    final report = {
      'buildTime': DateTime.now().toIso8601String(),
      'details': details,
    };

    await reportFile.writeAsString(jsonEncode(report));
  }

  /// 复制目录
  Future<void> _copyDirectory(Directory source, Directory target) async {
    if (!target.existsSync()) {
      await target.create(recursive: true);
    }

    await for (final entity in source.list(recursive: false)) {
      if (entity is File) {
        final targetFile =
            File(path.join(target.path, path.basename(entity.path)));
        await entity.copy(targetFile.path);
      } else if (entity is Directory) {
        final targetDir =
            Directory(path.join(target.path, path.basename(entity.path)));
        await _copyDirectory(entity, targetDir);
      }
    }
  }
}
