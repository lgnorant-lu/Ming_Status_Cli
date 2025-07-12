/*
---------------------------------------------------------------
File name:          index.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        模板配置管理系统 (Template Configuration Management System)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 模板配置管理系统;
---------------------------------------------------------------
*/

// 核心组件
export 'version_resolver.dart';
export 'update_strategy.dart';
export 'compatibility_matrix.dart';
export 'configuration_tester.dart';
export 'smart_prefilter.dart';
export 'parallel_tester.dart';
export 'incremental_updater.dart';
export 'ml_models.dart';

// 数据模型
export 'models/version_info.dart';
export 'models/configuration_set.dart';
export 'models/test_result.dart';
