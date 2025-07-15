/*
---------------------------------------------------------------
File name:          analysis_options_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        analysis_options.yaml配置文件生成器 
                      (Analysis Options Configuration Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/config/config_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// analysis_options.yaml配置文件生成器
///
/// 负责生成Dart/Flutter项目的代码分析配置文件
class AnalysisOptionsGenerator extends ConfigGeneratorBase {
  /// 创建analysis_options.yaml生成器实例
  const AnalysisOptionsGenerator();

  @override
  String getFileName() => 'analysis_options.yaml';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer()
      ..writeln('# Analysis Options配置')
      ..writeln('# 更多信息: https://dart.dev/guides/language/analysis-options')
      ..writeln()
      ..writeln('include: package:very_good_analysis/analysis_options.yaml')
      ..writeln();

    // 分析器配置
    buffer
      ..writeln('analyzer:')
      ..writeln('  # 排除的文件和目录')
      ..writeln('  exclude:')
      ..writeln('    - "**/*.g.dart"')
      ..writeln('    - "**/*.freezed.dart"')
      ..writeln('    - "**/*.gr.dart"')
      ..writeln('    - "**/*.config.dart"')
      ..writeln('    - "**/*.mocks.dart"')
      ..writeln('    - "lib/generated/**"')
      ..writeln('    - "build/**"')
      ..writeln('    - ".dart_tool/**"');

    if (config.framework == TemplateFramework.flutter) {
      buffer
        ..writeln('    - "android/**"')
        ..writeln('    - "ios/**"')
        ..writeln('    - "web/**"')
        ..writeln('    - "windows/**"')
        ..writeln('    - "macos/**"')
        ..writeln('    - "linux/**"');
    }

    buffer
      ..writeln()
      ..writeln('  # 语言配置')
      ..writeln('  language:')
      ..writeln('    strict-casts: true')
      ..writeln('    strict-inference: true')
      ..writeln('    strict-raw-types: true')
      ..writeln()
      ..writeln('  # 错误配置')
      ..writeln('  errors:')
      ..writeln('    # 将警告提升为错误')
      ..writeln('    invalid_annotation_target: error')
      ..writeln('    missing_required_param: error')
      ..writeln('    missing_return: error')
      ..writeln('    must_be_immutable: error')
      ..writeln('    prefer_const_constructors: error')
      ..writeln('    prefer_const_declarations: error')
      ..writeln('    prefer_final_fields: error')
      ..writeln('    unnecessary_null_aware_assignments: error')
      ..writeln(
          '    unnecessary_nullable_for_final_variable_declarations: error')
      ..writeln()
      ..writeln('    # 忽略的规则')
      ..writeln('    todo: ignore')
      ..writeln('    fixme: ignore')
      ..writeln('    avoid_print: ignore  # 开发阶段允许print')
      ..writeln();

    // 企业级项目的额外配置
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer
        ..writeln('  # 企业级配置')
        ..writeln('  plugins:')
        ..writeln('    - dart_code_metrics')
        ..writeln()
        ..writeln('  strong-mode:')
        ..writeln('    implicit-casts: false')
        ..writeln('    implicit-dynamic: false')
        ..writeln();
    }

    // Linter规则配置
    buffer
      ..writeln('linter:')
      ..writeln('  rules:')
      ..writeln('    # === 错误预防 ===')
      ..writeln('    - always_use_package_imports')
      ..writeln('    - avoid_dynamic_calls')
      ..writeln('    - avoid_empty_else')
      ..writeln('    - avoid_print')
      ..writeln('    - avoid_relative_lib_imports')
      ..writeln('    - avoid_slow_async_io')
      ..writeln('    - avoid_type_to_string')
      ..writeln('    - avoid_types_as_parameter_names')
      ..writeln('    - avoid_web_libraries_in_flutter')
      ..writeln('    - cancel_subscriptions')
      ..writeln('    - close_sinks')
      ..writeln('    - comment_references')
      ..writeln('    - control_flow_in_finally')
      ..writeln('    - diagnostic_describe_all_properties')
      ..writeln('    - empty_catches')
      ..writeln('    - hash_and_equals')
      ..writeln('    - invariant_booleans')
      ..writeln('    # - iterable_contains_unrelated_type  # 已在Dart 3.3.0+中移除')
      ..writeln('    # - list_remove_unrelated_type       # 已在Dart 3.3.0+中移除')
      ..writeln('    - literal_only_boolean_expressions')
      ..writeln('    - no_adjacent_strings_in_list')
      ..writeln('    - no_duplicate_case_values')
      ..writeln('    - no_logic_in_create_state')
      ..writeln('    - prefer_void_to_null')
      ..writeln('    - test_types_in_equals')
      ..writeln('    - throw_in_finally')
      ..writeln('    - unnecessary_statements')
      ..writeln('    - unrelated_type_equality_checks')
      ..writeln('    - use_build_context_synchronously')
      ..writeln('    - use_key_in_widget_constructors')
      ..writeln('    - valid_regexps')
      ..writeln()
      ..writeln('    # === 代码风格 ===')
      ..writeln('    - always_declare_return_types')
      ..writeln('    - always_put_control_body_on_new_line')
      ..writeln('    - always_put_required_named_parameters_first')
      ..writeln('    - always_specify_types')
      ..writeln('    - annotate_overrides')
      ..writeln('    - avoid_annotating_with_dynamic')
      ..writeln('    - avoid_bool_literals_in_conditional_expressions')
      ..writeln('    - avoid_catches_without_on_clauses')
      ..writeln('    - avoid_catching_errors')
      ..writeln('    - avoid_double_and_int_checks')
      ..writeln('    - avoid_equals_and_hash_code_on_mutable_classes')
      ..writeln('    - avoid_escaping_inner_quotes')
      ..writeln('    - avoid_field_initializers_in_const_classes')
      ..writeln('    - avoid_function_literals_in_foreach_calls')
      ..writeln('    - avoid_implementing_value_types')
      ..writeln('    - avoid_init_to_null')
      ..writeln('    - avoid_null_checks_in_equality_operators')
      ..writeln('    - avoid_positional_boolean_parameters')
      ..writeln('    - avoid_private_typedef_functions')
      ..writeln('    - avoid_redundant_argument_values')
      ..writeln('    - avoid_renaming_method_parameters')
      ..writeln('    - avoid_return_types_on_setters')
      ..writeln('    - avoid_returning_null_for_void')
      ..writeln('    - avoid_setters_without_getters')
      ..writeln('    - avoid_shadowing_type_parameters')
      ..writeln('    - avoid_single_cascade_in_expression_statements')
      ..writeln('    - avoid_unnecessary_containers')
      ..writeln('    - avoid_unused_constructor_parameters')
      ..writeln('    - avoid_void_async')
      ..writeln('    - await_only_futures')
      ..writeln('    - camel_case_extensions')
      ..writeln('    - camel_case_types')
      ..writeln('    - cascade_invocations')
      ..writeln('    - cast_nullable_to_non_nullable')
      ..writeln('    - conditional_uri_does_not_exist')
      ..writeln('    - constant_identifier_names')
      ..writeln('    - curly_braces_in_flow_control_structures')
      ..writeln('    - deprecated_consistency')
      ..writeln('    - directives_ordering')
      ..writeln('    - empty_constructor_bodies')
      ..writeln('    - empty_statements')
      ..writeln('    - eol_at_end_of_file')
      ..writeln('    - exhaustive_cases')
      ..writeln('    - file_names')
      ..writeln('    - flutter_style_todos')
      ..writeln('    - implementation_imports')
      ..writeln('    - join_return_with_assignment')
      ..writeln('    - leading_newlines_in_multiline_strings')
      ..writeln('    - library_names')
      ..writeln('    - library_prefixes')
      ..writeln('    - lines_longer_than_80_chars')
      ..writeln('    - missing_whitespace_between_adjacent_strings')
      ..writeln('    - no_default_cases')
      ..writeln('    - non_constant_identifier_names')
      ..writeln('    - null_check_on_nullable_type_parameter')
      ..writeln('    - null_closures')
      ..writeln(
          '    # - omit_local_variable_types         # 与always_specify_types冲突')
      ..writeln('    - one_member_abstracts')
      ..writeln('    - only_throw_errors')
      ..writeln('    - overridden_fields')
      ..writeln('    # - package_api_docs                 # 已在Dart 3.7.0+中移除')
      ..writeln('    - package_prefixed_library_names')
      ..writeln('    - parameter_assignments')
      ..writeln('    - prefer_adjacent_string_concatenation')
      ..writeln('    - prefer_asserts_in_initializer_lists')
      ..writeln('    - prefer_asserts_with_message')
      ..writeln('    - prefer_collection_literals')
      ..writeln('    - prefer_conditional_assignment')
      ..writeln('    - prefer_const_constructors')
      ..writeln('    - prefer_const_constructors_in_immutables')
      ..writeln('    - prefer_const_declarations')
      ..writeln('    - prefer_const_literals_to_create_immutables')
      ..writeln('    - prefer_constructors_over_static_methods')
      ..writeln('    - prefer_contains')
      ..writeln('    - prefer_equal_for_default_values')
      ..writeln('    - prefer_expression_function_bodies')
      ..writeln('    - prefer_final_fields')
      ..writeln('    - prefer_final_in_for_each')
      ..writeln('    - prefer_final_locals')
      ..writeln('    - prefer_for_elements_to_map_fromIterable')
      ..writeln('    - prefer_foreach')
      ..writeln('    - prefer_function_declarations_over_variables')
      ..writeln('    - prefer_generic_function_type_aliases')
      ..writeln('    - prefer_if_elements_to_conditional_expressions')
      ..writeln('    - prefer_if_null_operators')
      ..writeln('    - prefer_initializing_formals')
      ..writeln('    - prefer_inlined_adds')
      ..writeln('    - prefer_interpolation_to_compose_strings')
      ..writeln('    - prefer_is_empty')
      ..writeln('    - prefer_is_not_empty')
      ..writeln('    - prefer_is_not_operator')
      ..writeln('    - prefer_iterable_whereType')
      ..writeln('    - prefer_null_aware_operators')
      ..writeln('    - prefer_single_quotes')
      ..writeln('    - prefer_spread_collections')
      ..writeln('    - prefer_typing_uninitialized_variables')
      ..writeln('    - provide_deprecation_message')
      ..writeln('    - public_member_api_docs')
      ..writeln('    - recursive_getters')
      ..writeln('    - require_trailing_commas')
      ..writeln('    - sized_box_for_whitespace')
      ..writeln('    - slash_for_doc_comments')
      ..writeln('    - sort_child_properties_last')
      ..writeln('    - sort_constructors_first')
      ..writeln('    - sort_unnamed_constructors_first')
      ..writeln('    - tighten_type_of_initializing_formals')
      ..writeln('    - type_annotate_public_apis')
      ..writeln('    - type_init_formals')
      ..writeln('    - unawaited_futures')
      ..writeln('    - unnecessary_await_in_return')
      ..writeln('    - unnecessary_brace_in_string_interps')
      ..writeln('    - unnecessary_const')
      ..writeln('    - unnecessary_constructor_name')
      ..writeln('    - unnecessary_getters_setters')
      ..writeln('    - unnecessary_lambdas')
      ..writeln('    - unnecessary_new')
      ..writeln('    - unnecessary_null_aware_assignments')
      ..writeln('    - unnecessary_null_checks')
      ..writeln('    - unnecessary_null_in_if_null_operators')
      ..writeln('    - unnecessary_nullable_for_final_variable_declarations')
      ..writeln('    - unnecessary_overrides')
      ..writeln('    - unnecessary_parenthesis')
      ..writeln('    - unnecessary_raw_strings')
      ..writeln('    - unnecessary_string_escapes')
      ..writeln('    - unnecessary_string_interpolations')
      ..writeln('    - unnecessary_this')
      ..writeln('    - use_colored_box')
      ..writeln('    - use_decorated_box')
      ..writeln('    - use_full_hex_values_for_flutter_colors')
      ..writeln('    - use_function_type_syntax_for_parameters')
      ..writeln('    - use_if_null_to_convert_nulls_to_bools')
      ..writeln('    - use_is_even_rather_than_modulo')
      ..writeln('    - use_late_for_private_fields_and_variables')
      ..writeln('    - use_named_constants')
      ..writeln('    - use_raw_strings')
      ..writeln('    - use_rethrow_when_possible')
      ..writeln('    - use_setters_to_change_properties')
      ..writeln('    - use_string_buffers')
      ..writeln('    - use_super_parameters')
      ..writeln('    - use_test_throws_matchers')
      ..writeln('    - use_to_and_as_if_applicable')
      ..writeln('    - void_checks');

    return buffer.toString();
  }
}
