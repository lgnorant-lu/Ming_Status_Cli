/*
---------------------------------------------------------------
File name:          platform_compliance_validator_test.dart
Author:             Ignorant-lu
Date created:       2025/07/04
Last modified:      2025/07/04
Dart Version:       3.32.4
Description:        PlatformComplianceValidator单元测试套件 - Task 44.2
---------------------------------------------------------------
Change History:
    2025/07/04: Initial creation - 平台规范验证器测试套件实现;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:ming_status_cli/src/validators/platform_compliance_validator.dart';
import 'package:path/path.dart' as path; 
import 'package:test/test.dart';

void main() {
  group('PlatformComplianceValidator Tests', () {
    late PlatformComplianceValidator validator;
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('platform_test_');
    });

    setUp(() async {
      validator = PlatformComplianceValidator();
      // 确保每个测试都有清洁的环境
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
      tempDir = await Directory.systemTemp.createTemp('platform_test_');
    });

    tearDownAll(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Validator Basic Properties', () {
      test('should have correct validator name', () {
        expect(validator.validatorName, equals('platform'));
      });

      test('should support platform_compliance validation type', () {
        expect(validator.supportedTypes, contains(ValidationType.compliance));
      });

      test('should have correct priority', () {
        expect(validator.priority, equals(40));
      });

      test('should pass health check', () async {
        final result = await validator.healthCheck();
        expect(result, isTrue);
      });
    });

    group('Module Configuration Validation', () {
      test('should validate basic module configuration', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
dependencies:
  core_services: ^1.0.0
  ui_framework: ^1.0.0

permissions:
  - name: camera
    description: Camera access
  - name: storage
    description: Storage access
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(result.messages, isNotEmpty);
        expect(
          result.messages.any((m) => 
            m.severity == ValidationSeverity.success ||
            m.message.contains('依赖定义完整'),
          ), 
          isTrue,
        );
      });

      test('should detect missing module definition file', () async {
        await Directory('${tempDir.path}/lib').create();
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('缺少模块定义文件') ||
            m.message.contains('_module.dart'),
          ), 
          isTrue,
        );
      });

      test('should validate module interface implementation', () async {
        await Directory('${tempDir.path}/lib').create();
        
        // 创建不符合规范的模块文件
        await File('${tempDir.path}/lib/${path.basename(tempDir.path)}_module.dart').writeAsString('''
class TestModule {
  // Missing ModuleInterface implementation
  void someMethod() {}
}
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('ModuleInterface') ||
            m.message.contains('接口'),
          ), 
          isTrue,
        );
      });
    });

    group('Lifecycle Management Validation', () {
      test('should validate lifecycle methods implementation', () async {
        await Directory('${tempDir.path}/lib').create();
        
        // 创建实现了生命周期方法的模块文件
        await File('${tempDir.path}/lib/${path.basename(tempDir.path)}_module.dart').writeAsString('''
import 'package:core_services/module_interface.dart';

class TestModule implements ModuleInterface {
  @override
  Future<void> initialize() async {}
  
  @override
  void dispose() {}
  
  void onModuleLoad() {}
  void onModuleUnload() {}
}
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('生命周期方法') ||
            m.message.contains('onModuleLoad'),
          ), 
          isTrue,
        );
      });

      test('should validate missing core dependencies', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
dependencies:
  some_other_service: ^1.0.0
  # Missing core_services and ui_framework
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('缺少核心依赖') ||
            m.message.contains('core_services'),
          ), 
          isTrue,
        );
      });

      test('should validate platform configuration', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
dependencies:
  core_services: ^1.0.0

android:
  permissions:
    - android.permission.CAMERA

ios:
  permissions:
    - NSCameraUsageDescription
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('支持') &&
            (m.message.contains('android') || m.message.contains('ios')),
          ), 
          isTrue,
        );
      });
    });

    group('API Compatibility Validation', () {
      test('should validate module version compatibility', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 0.1.0  # Pre-release version
type: business_logic
description: A test module

api_compatibility:
  min_core_version: "1.0.0"
  max_core_version: "2.0.0"
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('版本') ||
            m.message.contains('兼容性'),
          ), 
          isTrue,
        );
      });

      test('should validate core service dependencies', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 1.0.0
type: business_logic
description: A test module

dependencies:
  core_services:
    - logging_service
    - config_service
    - unknown_service  # Invalid service
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('核心服务') ||
            m.message.contains('unknown_service'),
          ), 
          isTrue,
        );
      });

      test('should validate interface signatures', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 1.0.0
type: business_logic
description: A test module

exports:
  widgets:
    - TestWidget
  services:
    - TestService
  interfaces:
    - ITestInterface
''');
        
        // 创建模块文件
        await File('${tempDir.path}/lib/test_module.dart').writeAsString('''
export 'widgets/test_widget.dart';
export 'services/test_service.dart';
export 'interfaces/i_test_interface.dart';
''');
        
        await Directory('${tempDir.path}/lib/widgets').create();
        await File('${tempDir.path}/lib/widgets/test_widget.dart').writeAsString('''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('接口') ||
            m.message.contains('导出'),
          ), 
          isTrue,
        );
      });
    });

    group('Module Interface Validation', () {
      test('should validate public interface exports', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 1.0.0
type: ui_component
description: A test module

exports:
  widgets:
    - TestWidget
    - MissingWidget  # Should trigger warning
''');
        
        await File('${tempDir.path}/lib/test_module.dart').writeAsString('''
export 'widgets/test_widget.dart';
// Missing export for MissingWidget
''');
        
        await Directory('${tempDir.path}/lib/widgets').create();
        await File('${tempDir.path}/lib/widgets/test_widget.dart').writeAsString('''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Test');
  }
}
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('MissingWidget') ||
            m.message.contains('未找到') ||
            m.message.contains('导出'),
          ), 
          isTrue,
        );
      });

      test('should validate documentation coverage', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 1.0.0
type: business_logic
description: A test module

exports:
  services:
    - TestService
''');
        
        await File('${tempDir.path}/lib/test_module.dart').writeAsString('''
export 'services/test_service.dart';
''');
        
        await Directory('${tempDir.path}/lib/services').create();
        await File('${tempDir.path}/lib/services/test_service.dart').writeAsString('''
// Missing documentation
class TestService {
  void doSomething() {
    // No documentation
  }
}
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('文档') ||
            m.message.contains('覆盖率'),
          ), 
          isTrue,
        );
      });

      test('should validate JSON serialization support', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 1.0.0
type: data_layer
description: A test module

exports:
  models:
    - TestModel
''');
        
        await File('${tempDir.path}/lib/test_module.dart').writeAsString('''
export 'models/test_model.dart';
''');
        
        await Directory('${tempDir.path}/lib/models').create();
        await File('${tempDir.path}/lib/models/test_model.dart').writeAsString('''
class TestModel {
  final String name;
  final int value;
  
  TestModel({required this.name, required this.value});
  
  // Missing toJson/fromJson
}
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('JSON') ||
            m.message.contains('序列化'),
          ), 
          isTrue,
        );
      });

      test('should validate event system compatibility', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 1.0.0
type: business_logic
description: A test module

events:
  emits:
    - UserAction
    - DataChanged
  listens:
    - SystemEvent
''');
        
        await File('${tempDir.path}/lib/test_module.dart').writeAsString('''
import 'dart:async';

class TestModule {
  final StreamController<String> _controller = StreamController();
  Stream<String> get events => _controller.stream;
}
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('事件') ||
            m.message.contains('StreamController'),
          ), 
          isTrue,
        );
      });
    });

    group('Permission and Security Validation', () {
      test('should validate required permissions', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 1.0.0
type: system_integration
description: A test module

permissions:
  required:
    - camera
    - location
    - storage
  optional:
    - microphone
  dangerous:
    - contacts
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('权限') ||
            m.message.contains('permission'),
          ), 
          isTrue,
        );
      });

      test('should validate security constraints', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 1.0.0
type: security_critical
description: A test module

security:
  encryption_required: true
  audit_logging: true
  sensitive_data_access: true
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('安全') ||
            m.message.contains('加密') ||
            m.message.contains('审计'),
          ), 
          isTrue,
        );
      });
    });

    group('Data Model Compatibility', () {
      test('should validate data model structure', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 1.0.0
type: data_layer
description: A test module

data_models:
  - name: User
    fields:
      - id: String
      - name: String
      - email: String
    serialization: json
''');
        
        await File('${tempDir.path}/lib/test_module.dart').writeAsString('''
export 'models/user.dart';
''');
        
        await Directory('${tempDir.path}/lib/models').create();
        await File('${tempDir.path}/lib/models/user.dart').writeAsString('''
class User {
  final String id;
  final String name;
  final String email;
  
  User({required this.id, required this.name, required this.email});
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
  };
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    email: json['email'],
  );
}
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(
          result.messages.any((m) => 
            m.message.contains('数据模型') ||
            m.message.contains('User'),
          ), 
          isTrue,
        );
      });
    });

    group('Error Handling', () {
      test('should handle malformed module.yaml', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 1.0.0
invalid_yaml: {
  this is not valid yaml
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(result, isNotNull);
        expect(
          result.messages.any((m) => 
            m.message.contains('格式错误') ||
            m.message.contains('解析'),
          ), 
          isTrue,
        );
      });

      test('should handle missing lib directory', () async {
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 1.0.0
type: business_logic
description: A test module
''');
        
        final context = ValidationContext(projectPath: tempDir.path);
        final result = await validator.validate(tempDir.path, context);
        
        expect(result, isNotNull);
        expect(result.messages, isNotEmpty);
      });

      test('should handle permission errors gracefully', () async {
        const context = ValidationContext(projectPath: '/nonexistent/path');
        final result = await validator.validate('/nonexistent/path', context);
        
        expect(result, isNotNull);
        expect(result.messages, isNotEmpty);
      });
    });

    group('Strict Mode', () {
      test('should be more strict in strict mode', () async {
        await Directory('${tempDir.path}/lib').create();
        await File('${tempDir.path}/module.yaml').writeAsString('''
name: test_module
version: 1.0.0
type: business_logic
description: A test module

# Missing some recommended fields
lifecycle:
  init_priority: 100
''');
        
        final context = ValidationContext(
          projectPath: tempDir.path,
          strictMode: true,
        );
        final result = await validator.validate(tempDir.path, context);
        
        // 严格模式应该产生更多警告
        final warningCount = result.messages.where((m) => 
          m.severity == ValidationSeverity.warning ||
          m.severity == ValidationSeverity.error,
        ).length;
        expect(warningCount, greaterThan(0));
      });
    });
  });
} 
