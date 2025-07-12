/*
---------------------------------------------------------------
File name:          build_config_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        build.yaml配置文件生成器 (Build Configuration Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加更多代码生成器支持 (drift, injectable等)
    - [ ] 优化性能配置选项
    - [ ] 添加企业级验证规则
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/config/config_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// build.yaml配置文件生成器
///
/// 负责生成build_runner代码生成配置文件
class BuildConfigGenerator extends ConfigGeneratorBase {
  /// 创建build.yaml生成器实例
  const BuildConfigGenerator();

  @override
  String getFileName() => 'build.yaml';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer()
      ..writeln('# Build Runner配置 - 基本完整可用版本')
      ..writeln('# 更多信息: https://pub.dev/packages/build_runner')
      ..writeln()
      ..writeln('targets:')
      ..writeln(r'  $default:')
      ..writeln('    builders:');

    // 根据复杂度添加不同的构建器
    if (config.complexity == TemplateComplexity.simple) {
      _addSimpleBuilders(buffer);
    } else if (config.complexity == TemplateComplexity.medium ||
        config.complexity == TemplateComplexity.complex) {
      _addMediumBuilders(buffer);
    } else {
      _addEnterpriseBuilders(buffer);
    }

    return buffer.toString();
  }

  /// 添加简单复杂度的构建器
  void _addSimpleBuilders(StringBuffer buffer) {
    buffer
      ..writeln('      # JSON序列化')
      ..writeln('      json_serializable:')
      ..writeln('        enabled: true')
      ..writeln('        options:')
      ..writeln('          explicit_to_json: true')
      ..writeln('          include_if_null: false')
      ..writeln()
      ..writeln('      # Riverpod状态管理')
      ..writeln('      riverpod_generator:')
      ..writeln('        enabled: true');
  }

  /// 添加中等复杂度的构建器
  void _addMediumBuilders(StringBuffer buffer) {
    buffer
      ..writeln('      # JSON序列化')
      ..writeln('      json_serializable:')
      ..writeln('        enabled: true')
      ..writeln('        options:')
      ..writeln('          explicit_to_json: true')
      ..writeln('          field_rename: snake')
      ..writeln('          include_if_null: false')
      ..writeln('          create_factory: true')
      ..writeln('          create_to_json: true')
      ..writeln()
      ..writeln('      # Freezed数据类')
      ..writeln('      freezed:')
      ..writeln('        enabled: true')
      ..writeln()
      ..writeln('      # Riverpod状态管理')
      ..writeln('      riverpod_generator:')
      ..writeln('        enabled: true')
      ..writeln()
      ..writeln('      # Retrofit API客户端')
      ..writeln('      retrofit_generator:')
      ..writeln('        enabled: true');
  }

  /// 添加企业级构建器
  void _addEnterpriseBuilders(StringBuffer buffer) {
    buffer
      ..writeln('      # JSON序列化')
      ..writeln('      json_serializable:')
      ..writeln('        enabled: true')
      ..writeln('        options:')
      ..writeln('          explicit_to_json: true')
      ..writeln('          field_rename: snake')
      ..writeln('          include_if_null: false')
      ..writeln('          create_factory: true')
      ..writeln('          create_to_json: true')
      ..writeln('          checked: true')
      ..writeln()
      ..writeln('      # Freezed数据类')
      ..writeln('      freezed:')
      ..writeln('        enabled: true')
      ..writeln()
      ..writeln('      # Riverpod状态管理')
      ..writeln('      riverpod_generator:')
      ..writeln('        enabled: true')
      ..writeln()
      ..writeln('      # Retrofit API客户端')
      ..writeln('      retrofit_generator:')
      ..writeln('        enabled: true')
      ..writeln()
      ..writeln('      # Mockito测试Mock')
      ..writeln('      mockito|mockBuilder:')
      ..writeln('        enabled: true')
      ..writeln('        generate_for:')
      ..writeln('          - test/**')
      ..writeln('          - test_driver/**');
  }
}
