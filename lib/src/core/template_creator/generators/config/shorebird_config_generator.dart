/*
---------------------------------------------------------------
File name:          shorebird_config_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        shorebird.yaml配置文件生成器 
                      (Shorebird Configuration Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加更多部署策略
    - [ ] 优化回滚机制
    - [ ] 添加A/B测试支持
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/config/config_generator_base.dart';

/// shorebird.yaml配置文件生成器
///
/// 负责生成Shorebird代码推送配置文件
class ShorebirdConfigGenerator extends ConfigGeneratorBase {
  /// 创建shorebird.yaml生成器实例
  const ShorebirdConfigGenerator();

  @override
  String getFileName() => 'shorebird.yaml';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer()
      ..writeln('# Shorebird代码推送配置')
      ..writeln('# 更多信息: https://shorebird.dev')
      ..writeln()
      ..writeln('# 应用配置')
      ..writeln('app_id: ${config.templateName.toLowerCase().replaceAll('_', '-')}')
      ..writeln('app_name: ${config.templateName}')
      ..writeln('app_display_name: "${config.description}"')
      ..writeln()
      ..writeln('# === 多环境配置 ===')
      ..writeln()
      ..writeln('# 开发环境')
      ..writeln('environments:')
      ..writeln('  development:')
      ..writeln('    app_id: ${config.templateName.toLowerCase()}-dev')
      ..writeln('    # 自动更新配置')
      ..writeln('    auto_update:')
      ..writeln('      enabled: true')
      ..writeln('      check_interval: 300  # 5分钟')
      ..writeln('      # 网络策略')
      ..writeln('      network_policy:')
      ..writeln('        wifi_only: false')
      ..writeln('        cellular_allowed: true')
      ..writeln('        roaming_allowed: false')
      ..writeln('      # 电池策略')
      ..writeln('      battery_policy:')
      ..writeln('        low_battery_threshold: 20')
      ..writeln('        charging_required: false')
      ..writeln('    # 用户体验')
      ..writeln('    user_experience:')
      ..writeln('      show_update_dialog: true')
      ..writeln('      force_update: false')
      ..writeln('      background_download: true')
      ..writeln()
      ..writeln('  # 预发布环境')
      ..writeln('  staging:')
      ..writeln('    app_id: ${config.templateName.toLowerCase()}-staging')
      ..writeln('    auto_update:')
      ..writeln('      enabled: true')
      ..writeln('      check_interval: 600  # 10分钟')
      ..writeln('      network_policy:')
      ..writeln('        wifi_only: false')
      ..writeln('        cellular_allowed: true')
      ..writeln('        roaming_allowed: true')
      ..writeln('      battery_policy:')
      ..writeln('        low_battery_threshold: 15')
      ..writeln('        charging_required: false')
      ..writeln('    user_experience:')
      ..writeln('      show_update_dialog: true')
      ..writeln('      force_update: false')
      ..writeln('      background_download: true')
      ..writeln()
      ..writeln('  # 生产环境')
      ..writeln('  production:')
      ..writeln('    app_id: ${config.templateName.toLowerCase()}-prod')
      ..writeln('    auto_update:')
      ..writeln('      enabled: true')
      ..writeln('      check_interval: 1800  # 30分钟')
      ..writeln('      network_policy:')
      ..writeln('        wifi_only: true')
      ..writeln('        cellular_allowed: false')
      ..writeln('        roaming_allowed: false')
      ..writeln('      battery_policy:')
      ..writeln('        low_battery_threshold: 30')
      ..writeln('        charging_required: true')
      ..writeln('    user_experience:')
      ..writeln('      show_update_dialog: false')
      ..writeln('      force_update: false')
      ..writeln('      background_download: true')
      ..writeln()
      ..writeln('# === 回滚配置 ===')
      ..writeln()
      ..writeln('rollback:')
      ..writeln('  # 自动回滚')
      ..writeln('  auto_rollback:')
      ..writeln('    enabled: true')
      ..writeln('    # 触发条件')
      ..writeln('    triggers:')
      ..writeln('      crash_rate_threshold: 5.0  # 崩溃率超过5%')
      ..writeln('      error_rate_threshold: 10.0  # 错误率超过10%')
      ..writeln('      performance_degradation: 20.0  # 性能下降超过20%')
      ..writeln('    # 检测窗口')
      ..writeln('    detection_window: 3600  # 1小时')
      ..writeln('    # 最小样本数')
      ..writeln('    min_sample_size: 100')
      ..writeln('  ')
      ..writeln('  # 手动回滚')
      ..writeln('  manual_rollback:')
      ..writeln('    enabled: true')
      ..writeln('    # 回滚历史保留')
      ..writeln('    history_retention: 30  # 30天')
      ..writeln('    # 快速回滚')
      ..writeln('    quick_rollback: true')
      ..writeln()
      ..writeln('# === 分阶段发布 ===')
      ..writeln()
      ..writeln('staged_rollout:')
      ..writeln('  # 启用分阶段发布')
      ..writeln('  enabled: true')
      ..writeln('  ')
      ..writeln('  # 发布阶段')
      ..writeln('  stages:')
      ..writeln('    - name: "canary"')
      ..writeln('      percentage: 1.0')
      ..writeln('      duration: 3600  # 1小时')
      ..writeln('      success_criteria:')
      ..writeln('        crash_rate: 1.0')
      ..writeln('        error_rate: 2.0')
      ..writeln('    ')
      ..writeln('    - name: "early_adopters"')
      ..writeln('      percentage: 5.0')
      ..writeln('      duration: 7200  # 2小时')
      ..writeln('      success_criteria:')
      ..writeln('        crash_rate: 2.0')
      ..writeln('        error_rate: 5.0')
      ..writeln('    ')
      ..writeln('    - name: "general"')
      ..writeln('      percentage: 25.0')
      ..writeln('      duration: 14400  # 4小时')
      ..writeln('      success_criteria:')
      ..writeln('        crash_rate: 3.0')
      ..writeln('        error_rate: 7.0')
      ..writeln('    ')
      ..writeln('    - name: "full"')
      ..writeln('      percentage: 100.0')
      ..writeln('      duration: 0  # 无限制')
      ..writeln('      success_criteria:')
      ..writeln('        crash_rate: 5.0')
      ..writeln('        error_rate: 10.0')
      ..writeln('  ')
      ..writeln('  # 暂停条件')
      ..writeln('  pause_conditions:')
      ..writeln('    high_crash_rate: 10.0')
      ..writeln('    high_error_rate: 15.0')
      ..writeln('    negative_feedback: 20.0')
      ..writeln()
      ..writeln('# === 监控和分析 ===')
      ..writeln()
      ..writeln('monitoring:')
      ..writeln('  # 性能监控')
      ..writeln('  performance:')
      ..writeln('    enabled: true')
      ..writeln('    metrics:')
      ..writeln('      - app_start_time')
      ..writeln('      - frame_rate')
      ..writeln('      - memory_usage')
      ..writeln('      - cpu_usage')
      ..writeln('      - network_latency')
      ..writeln('  ')
      ..writeln('  # 用户反馈')
      ..writeln('  user_feedback:')
      ..writeln('    enabled: true')
      ..writeln('    collection_methods:')
      ..writeln('      - in_app_rating')
      ..writeln('      - crash_reports')
      ..writeln('      - user_surveys')
      ..writeln('  ')
      ..writeln('  # 崩溃报告')
      ..writeln('  crash_reporting:')
      ..writeln('    enabled: true')
      ..writeln('    providers:')
      ..writeln('      - firebase_crashlytics')
      ..writeln('      - sentry')
      ..writeln()
      ..writeln('# === 安全配置 ===')
      ..writeln()
      ..writeln('security:')
      ..writeln('  # 代码签名')
      ..writeln('  code_signing:')
      ..writeln('    enabled: true')
      ..writeln('    certificate_validation: true')
      ..writeln('  ')
      ..writeln('  # 传输加密')
      ..writeln('  transport_encryption:')
      ..writeln('    enabled: true')
      ..writeln('    tls_version: "1.3"')
      ..writeln('  ')
      ..writeln('  # 访问控制')
      ..writeln('  access_control:')
      ..writeln('    api_key_required: true')
      ..writeln('    rate_limiting: true')
      ..writeln('    ip_whitelist: []')
      ..writeln()
      ..writeln('# === 高级配置 ===')
      ..writeln()
      ..writeln('advanced:')
      ..writeln('  # 缓存配置')
      ..writeln('  cache:')
      ..writeln('    max_size: "100MB"')
      ..writeln('    ttl: 86400  # 24小时')
      ..writeln('    cleanup_policy: "lru"')
      ..writeln('  ')
      ..writeln('  # 网络配置')
      ..writeln('  network:')
      ..writeln('    timeout: 30')
      ..writeln('    retry_attempts: 3')
      ..writeln('    retry_delay: 1000')
      ..writeln('  ')
      ..writeln('  # 日志配置')
      ..writeln('  logging:')
      ..writeln('    level: "info"')
      ..writeln('    max_file_size: "10MB"')
      ..writeln('    max_files: 5')
      ..writeln()
      ..writeln('# === 开发配置 ===')
      ..writeln()
      ..writeln('development:')
      ..writeln('  # 调试模式')
      ..writeln('  debug_mode: true')
      ..writeln('  ')
      ..writeln('  # 本地测试')
      ..writeln('  local_testing:')
      ..writeln('    enabled: true')
      ..writeln('    mock_server: false')
      ..writeln('  ')
      ..writeln('  # 开发者工具')
      ..writeln('  dev_tools:')
      ..writeln('    enabled: true')
      ..writeln('    show_overlay: false');

    return buffer.toString();
  }
}
