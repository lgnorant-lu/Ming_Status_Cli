/*
---------------------------------------------------------------
File name:          ming_status_cli.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        Ming Status CLI 主库文件 (Main library file)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 主库文件导出;
---------------------------------------------------------------
*/

/// Ming Status CLI - 模块化开发工具
/// 
/// 这是一个强大的CLI工具，用于创建、管理和验证模块化应用的代码结构。
/// 支持模板管理、代码生成、模块验证等功能。
library ming_status_cli;

// 导出核心服务
export 'src/core/config_manager.dart';
export 'src/core/template_engine.dart';
export 'src/core/module_validator.dart';

// 导出数据模型
export 'src/models/workspace_config.dart';
export 'src/models/module_config.dart';
export 'src/models/validation_result.dart';

// 导出工具类
export 'src/utils/file_utils.dart';
export 'src/utils/logger.dart';
export 'src/utils/string_utils.dart';

// 导出命令
export 'src/commands/base_command.dart';
export 'src/commands/init_command.dart';
export 'src/commands/help_command.dart';
export 'src/commands/version_command.dart';

// 导出CLI应用
export 'src/cli_app.dart';
