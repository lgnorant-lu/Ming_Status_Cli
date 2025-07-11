/*
---------------------------------------------------------------
File name:          index.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        核心模块总导出文件 (Core modules main exports)
---------------------------------------------------------------
*/

// 条件渲染模块
export 'conditional/index.dart';

// 配置管理模块
export 'config_management/index.dart';

// 模板创建模块 (隐藏与企业模块冲突的TemplateVersion)
export 'creation/index.dart' hide TemplateVersion;

// 独立文件 (隐藏与安全系统模块冲突的多个类型)
export 'dependency_security_checker.dart'
    hide
        DependencyInfo,
        DependencySecurityChecker,
        DependencySecurityLevel,
        DependencySecurityReport,
        DependencyVulnerability;

// 分发管理模块 (隐藏与继承模块冲突的DependencyResolver)
export 'distribution/index.dart' hide DependencyResolver;

// 企业功能模块
export 'enterprise/index.dart';

// 错误处理模块
export 'error_handling/index.dart';

// 扩展模块
export 'extensions/template_engine_extensions.dart';

// 继承系统模块 (隐藏与库管理模块冲突的RecommendationResult)
export 'inheritance/index.dart';

// 集成模块
export 'integration/index.dart';

// 库管理模块 (隐藏与条件模块冲突的RecommendationResult)
export 'library/index.dart' hide RecommendationResult;

// 管理器模块 (隐藏与注册表模块冲突的TemplateComplexity和与策略模块冲突的ErrorPattern)
export 'managers/index.dart' hide ErrorPattern, TemplateComplexity;

// 网络模块 (隐藏与分发模块冲突的CompressionType、与企业模块冲突的SyncStatus、与分发模块冲突的CacheEntry)
export 'network/index.dart' hide CacheEntry, CompressionType, SyncStatus;

// 参数系统模块 (隐藏与模板创建器模块冲突的ValidationRuleType和与继承模块冲突的ValidationSeverity)
export 'parameters/index.dart' hide ValidationRuleType, ValidationSeverity;

// 性能优化模块
export 'performance/index.dart';

// 注册表模块 (隐藏与分发模块冲突的CacheEntry、与库管理模块冲突的SearchResult和IndexEntry、与企业模块冲突的RegistryType和RegistryConfig)
export 'registry/index.dart'
    hide CacheEntry, IndexEntry, RegistryConfig, RegistryType, SearchResult;

// 安全模块 (隐藏与安全系统模块冲突的SecurityValidationResult)
export 'security/index.dart' hide SecurityValidationResult;

// 安全系统模块 (隐藏与库管理模块冲突的CompatibilityResult、与注册表模块冲突的DependencyInfo、与安全模块冲突的SecurityValidator)
export 'security_system/index.dart'
    hide CompatibilityResult, DependencyInfo, SecurityValidator;

// 策略模块 (隐藏与错误处理模块冲突的ErrorSeverity、与管理器模块冲突的ScriptHookConfig和ScriptExecutionHook)
export 'strategies/index.dart'
    hide ErrorSeverity, ScriptExecutionHook, ScriptHookConfig;

// 系统管理模块 (隐藏与分发模块冲突的CacheStrategy和CacheStats、与企业模块冲突的ResourceType)
export 'system_management/index.dart'
    hide CacheStats, CacheStrategy, ResourceType;

// 模板创建器模块 (隐藏与继承模块冲突的ValidationRuleType、ValidationSeverity、ValidationIssue和与管理器模块冲突的TemplateValidationResult)
export 'template_creator/index.dart'
    hide
        TemplateValidationResult,
        ValidationIssue,
        ValidationRuleType,
        ValidationSeverity;

// 模板引擎模块 (隐藏与模板系统模块冲突的GenerationResult)
export 'template_engine/index.dart' hide GenerationResult;

// 模板系统模块 (隐藏多个冲突的类型)
export 'template_system/index.dart'
    hide
        CompatibilityInfo,
        CompatibilityResult,
        DependencyType,
        LicenseInfo,
        PerformanceMetrics,
        SecurityInfo,
        SortOrder,
        SupportInfo,
        TemplateComplexity,
        TemplateMaturity,
        TemplateMetadata,
        TemplateRegistry,
        TemplateSortBy;

// 验证系统模块 (隐藏与模板创建器模块冲突的ValidationConfig)
export 'validation_system/index.dart' hide ValidationConfig;
