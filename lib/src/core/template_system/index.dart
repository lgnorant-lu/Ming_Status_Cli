/*
---------------------------------------------------------------
File name:          index.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板系统模块导出文件 (Template system module exports)
---------------------------------------------------------------
*/

// 高级模板
export 'advanced_template.dart';

// 模板元数据
export 'template_metadata.dart';

// 模板注册表 (隐藏与模板元数据冲突的TemplateDependency、DependencyType和与高级模板冲突的PerformanceMetrics)
export 'template_registry.dart'
    hide DependencyType, PerformanceMetrics, TemplateDependency;

// 模板类型
export 'template_types.dart';
