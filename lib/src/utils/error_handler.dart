/*
---------------------------------------------------------------
File name:          error_handler.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        错误处理器 (Error handler for CLI)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 统一错误处理和智能建议;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:args/command_runner.dart';

import 'package:ming_status_cli/src/utils/logger.dart';

/// 错误类型枚举
enum ErrorType {
  /// 用法错误
  usage,

  /// 文件系统错误
  fileSystem,

  /// 权限错误
  permission,

  /// 网络错误
  network,

  /// 验证错误
  validation,

  /// 配置错误
  configuration,

  /// 依赖错误
  dependency,

  /// 未知错误
  unknown,
}

/// 错误处理器
/// 提供统一的错误处理机制和智能建议
class ErrorHandler {
  /// 基础文档URL
  static const String baseDocUrl =
      'https://github.com/lgnorant-lu/Ming_Status_Cli/wiki';

  /// 问题反馈URL
  static const String issueUrl =
      'https://github.com/lgnorant-lu/Ming_Status_Cli/issues';

  /// 处理任意异常
  static void handleException(Object exception, {String? context}) {
    final errorType = _classifyError(exception);

    switch (errorType) {
      case ErrorType.usage:
        _handleUsageError(exception as UsageException, context: context);
      case ErrorType.fileSystem:
        _handleFileSystemError(exception, context: context);
      case ErrorType.permission:
        _handlePermissionError(exception, context: context);
      case ErrorType.network:
        _handleNetworkError(exception, context: context);
      case ErrorType.validation:
        _handleValidationError(exception, context: context);
      case ErrorType.configuration:
        _handleConfigurationError(exception, context: context);
      case ErrorType.dependency:
        _handleDependencyError(exception, context: context);
      case ErrorType.unknown:
        _handleUnknownError(exception, context: context);
    }
  }

  /// 处理用法错误
  static void _handleUsageError(UsageException exception, {String? context}) {
    Logger.structuredError(
      title: '命令用法错误',
      description: exception.message,
      context: context,
      suggestions: [
        '检查命令参数是否正确',
        '使用 "ming help" 查看所有可用命令',
        '使用 "ming help <command>" 查看特定命令的用法',
        '确认参数选项名称的拼写是否正确',
      ],
      docLink: '$baseDocUrl/Command-Usage',
    );

    // 显示可用命令提示
    if (exception.usage.isNotEmpty) {
      Logger.newLine();
      Logger.info('用法信息:');
      Logger.info(exception.usage);
    }
  }

  /// 处理文件系统错误
  static void _handleFileSystemError(Object exception, {String? context}) {
    var title = '文件系统错误';
    var description = exception.toString();
    var suggestions = <String>[];

    if (exception is FileSystemException) {
      final path = exception.path ?? '未知路径';

      switch (exception.osError?.errorCode) {
        case 2: // 文件未找到
          title = '文件未找到';
          description = '无法找到文件或目录: $path';
          suggestions = [
            '检查文件路径是否正确',
            '确认文件是否存在',
            '检查当前工作目录是否正确',
            '使用绝对路径而不是相对路径',
          ];
        case 13: // 权限被拒绝
          title = '文件访问权限不足';
          description = '无法访问文件或目录: $path';
          suggestions = [
            '检查文件或目录的读写权限',
            '使用管理员权限运行命令',
            '确认当前用户有访问该路径的权限',
          ];
        default:
          suggestions = [
            '检查文件路径是否正确',
            '确认磁盘空间是否充足',
            '检查文件是否被其他程序占用',
            '尝试重新启动终端或系统',
          ];
      }
    } else {
      suggestions = [
        '检查文件路径和权限',
        '确认磁盘空间充足',
        '重试操作',
      ];
    }

    Logger.structuredError(
      title: title,
      description: description,
      context: context,
      suggestions: suggestions,
      docLink: '$baseDocUrl/File-System-Issues',
      technicalDetails: exception,
    );
  }

  /// 处理权限错误
  static void _handlePermissionError(Object exception, {String? context}) {
    Logger.structuredError(
      title: '权限错误',
      description: '操作被拒绝，权限不足',
      context: context ?? exception.toString(),
      suggestions: [
        '使用管理员权限运行命令',
        '检查当前用户是否有执行该操作的权限',
        '确认目标文件或目录的访问权限设置',
        '在Windows中，尝试"以管理员身份运行"',
        '在Linux/macOS中，考虑使用sudo（谨慎使用）',
      ],
      docLink: '$baseDocUrl/Permission-Issues',
      technicalDetails: exception,
    );
  }

  /// 处理网络错误
  static void _handleNetworkError(Object exception, {String? context}) {
    Logger.structuredError(
      title: '网络连接错误',
      description: '无法连接到远程服务器或下载资源',
      context: context ?? exception.toString(),
      suggestions: [
        '检查网络连接是否正常',
        '确认防火墙设置不会阻止连接',
        '尝试使用代理服务器（如果在企业网络中）',
        '稍后重试操作',
        '检查目标服务器是否可用',
      ],
      docLink: '$baseDocUrl/Network-Issues',
      technicalDetails: exception,
    );
  }

  /// 处理验证错误
  static void _handleValidationError(Object exception, {String? context}) {
    Logger.structuredError(
      title: '输入验证错误',
      description: '提供的数据或参数不符合要求',
      context: context ?? exception.toString(),
      suggestions: [
        '检查输入数据的格式是否正确',
        '确认所有必需字段都已提供',
        '验证数值是否在有效范围内',
        '检查文件格式是否受支持',
        '参考文档中的示例格式',
      ],
      docLink: '$baseDocUrl/Input-Validation',
      technicalDetails: exception,
    );
  }

  /// 处理配置错误
  static void _handleConfigurationError(Object exception, {String? context}) {
    Logger.structuredError(
      title: '配置错误',
      description: '配置文件无效或配置设置不正确',
      context: context ?? exception.toString(),
      suggestions: [
        '检查配置文件的语法和格式',
        '确认所有必需的配置项都已设置',
        '使用 "ming init" 重新初始化配置',
        '参考默认配置文件模板',
        '使用 "ming doctor" 检查配置状态',
      ],
      docLink: '$baseDocUrl/Configuration',
      technicalDetails: exception,
    );
  }

  /// 处理依赖错误
  static void _handleDependencyError(Object exception, {String? context}) {
    Logger.structuredError(
      title: '依赖错误',
      description: '缺少必需的依赖或依赖版本不兼容',
      context: context ?? exception.toString(),
      suggestions: [
        '运行 "dart pub get" 安装缺少的依赖',
        '检查 pubspec.yaml 中的依赖版本约束',
        '更新依赖到兼容版本',
        '清理并重新安装依赖：删除 .dart_tool 和 pubspec.lock',
        '使用 "ming doctor" 检查依赖状态',
      ],
      docLink: '$baseDocUrl/Dependencies',
      technicalDetails: exception,
    );
  }

  /// 处理未知错误
  static void _handleUnknownError(Object exception, {String? context}) {
    Logger.structuredError(
      title: '意外错误',
      description: '发生了预期之外的错误',
      context: context,
      suggestions: [
        '重试操作看是否能解决问题',
        '检查系统资源（内存、磁盘空间）是否充足',
        '使用 "ming doctor" 检查环境状态',
        '查看详细错误信息（使用 --verbose 选项）',
        '如果问题持续存在，请报告此问题',
      ],
      docLink: '$baseDocUrl/Troubleshooting',
      technicalDetails: exception,
    );

    // 鼓励用户报告问题
    Logger.newLine();
    Logger.info('如果问题持续存在，请访问以下链接报告问题：');
    Logger.info(issueUrl);
  }

  /// 错误分类
  static ErrorType _classifyError(Object exception) {
    if (exception is UsageException) {
      return ErrorType.usage;
    }

    if (exception is FileSystemException) {
      return ErrorType.fileSystem;
    }

    if (exception is ProcessException) {
      return ErrorType.permission;
    }

    if (exception is SocketException ||
        exception is HttpException ||
        exception.toString().toLowerCase().contains('network') ||
        exception.toString().toLowerCase().contains('connection')) {
      return ErrorType.network;
    }

    if (exception is FormatException ||
        exception.toString().toLowerCase().contains('validation') ||
        exception.toString().toLowerCase().contains('invalid')) {
      return ErrorType.validation;
    }

    if (exception.toString().toLowerCase().contains('config') ||
        exception.toString().toLowerCase().contains('yaml') ||
        exception.toString().toLowerCase().contains('setting')) {
      return ErrorType.configuration;
    }

    if (exception.toString().toLowerCase().contains('dependency') ||
        exception.toString().toLowerCase().contains('package') ||
        exception.toString().toLowerCase().contains('pubspec')) {
      return ErrorType.dependency;
    }

    return ErrorType.unknown;
  }

  /// 显示常用命令提示
  static void showCommonCommands() {
    Logger.newLine();
    Logger.info('常用命令:');
    Logger.usageTip('ming help', '显示所有可用命令', example: 'ming help');
    Logger.usageTip('ming doctor', '检查环境状态', example: 'ming doctor --detailed');
    Logger.usageTip('ming init', '初始化工作空间', example: 'ming init my-project');
    Logger.usageTip(
      'ming version',
      '显示版本信息',
      example: 'ming version --detailed',
    );
  }

  /// 显示快速修复建议
  static void showQuickFixes() {
    Logger.newLine();
    Logger.info('快速故障排除:');
    Logger.listItem('运行 "ming doctor" 检查环境');
    Logger.listItem('使用 --verbose 获取详细错误信息');
    Logger.listItem('检查文件权限和路径');
    Logger.listItem('确认网络连接正常');
    Logger.listItem('重启终端或IDE');
  }
}
