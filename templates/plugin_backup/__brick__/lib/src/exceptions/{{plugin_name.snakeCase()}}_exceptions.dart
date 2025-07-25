/*
---------------------------------------------------------------
File name:          {{plugin_name.snakeCase()}}_exceptions.dart
Author:             {{author}}{{#author_email}}
Email:              {{author_email}}{{/author_email}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       {{dart_version}}
Description:        {{plugin_name.titleCase()}}插件异常定义
---------------------------------------------------------------
Change History:
    {{generated_date}}: Initial creation - 插件异常定义;
---------------------------------------------------------------
*/

import '../constants/{{plugin_name.snakeCase()}}_constants.dart';

/// {{plugin_name.titleCase()}}插件基础异常类
/// 
/// 所有插件相关异常的基类
class {{plugin_name.pascalCase()}}Exception implements Exception {
  /// 创建插件异常实例
  const {{plugin_name.pascalCase()}}Exception(
    this.message, {
    this.code,
    this.details,
    this.stackTrace,
    this.innerException,
  });

  /// 错误消息
  final String message;

  /// 错误代码
  final String? code;

  /// 错误详情
  final Map<String, dynamic>? details;

  /// 堆栈跟踪
  final StackTrace? stackTrace;

  /// 内部异常
  final Exception? innerException;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('{{plugin_name.pascalCase()}}Exception: $message');
    
    if (code != null) {
      buffer.write(' (Code: $code)');
    }
    
    if (details != null && details!.isNotEmpty) {
      buffer.write(' Details: $details');
    }
    
    if (innerException != null) {
      buffer.write(' Inner: $innerException');
    }
    
    return buffer.toString();
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'type': '{{plugin_name.pascalCase()}}Exception',
      'message': message,
      'code': code,
      'details': details,
      'innerException': innerException?.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// 插件初始化异常
class {{plugin_name.pascalCase()}}InitializationException extends {{plugin_name.pascalCase()}}Exception {
  /// 创建初始化异常实例
  const {{plugin_name.pascalCase()}}InitializationException(
    super.message, {
    super.code = {{plugin_name.pascalCase()}}Constants.errorCodeInitialization,
    super.details,
    super.stackTrace,
    super.innerException,
  });
}

/// 插件配置异常
class {{plugin_name.pascalCase()}}ConfigurationException extends {{plugin_name.pascalCase()}}Exception {
  /// 创建配置异常实例
  const {{plugin_name.pascalCase()}}ConfigurationException(
    super.message, {
    super.code = {{plugin_name.pascalCase()}}Constants.errorCodeConfiguration,
    super.details,
    super.stackTrace,
    super.innerException,
  });
}{{#need_network}}

/// 插件网络异常
class {{plugin_name.pascalCase()}}NetworkException extends {{plugin_name.pascalCase()}}Exception {
  /// 创建网络异常实例
  const {{plugin_name.pascalCase()}}NetworkException(
    super.message, {
    super.code = {{plugin_name.pascalCase()}}Constants.errorCodeNetwork,
    super.details,
    super.stackTrace,
    super.innerException,
    this.statusCode,
    this.url,
  });

  /// HTTP状态码
  final int? statusCode;

  /// 请求URL
  final String? url;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(super.toString());
    
    if (statusCode != null) {
      buffer.write(' Status: $statusCode');
    }
    
    if (url != null) {
      buffer.write(' URL: $url');
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['statusCode'] = statusCode;
    map['url'] = url;
    return map;
  }
}{{/need_network}}{{#need_file_system}}

/// 插件文件系统异常
class {{plugin_name.pascalCase()}}FileSystemException extends {{plugin_name.pascalCase()}}Exception {
  /// 创建文件系统异常实例
  const {{plugin_name.pascalCase()}}FileSystemException(
    super.message, {
    super.code = {{plugin_name.pascalCase()}}Constants.errorCodeFileSystem,
    super.details,
    super.stackTrace,
    super.innerException,
    this.filePath,
    this.operation,
  });

  /// 文件路径
  final String? filePath;

  /// 操作类型
  final String? operation;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(super.toString());
    
    if (operation != null) {
      buffer.write(' Operation: $operation');
    }
    
    if (filePath != null) {
      buffer.write(' Path: $filePath');
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['filePath'] = filePath;
    map['operation'] = operation;
    return map;
  }
}{{/need_file_system}}

/// 插件权限异常
class {{plugin_name.pascalCase()}}PermissionException extends {{plugin_name.pascalCase()}}Exception {
  /// 创建权限异常实例
  const {{plugin_name.pascalCase()}}PermissionException(
    super.message, {
    super.code = {{plugin_name.pascalCase()}}Constants.errorCodePermission,
    super.details,
    super.stackTrace,
    super.innerException,
    this.permission,
    this.requiredLevel,
  });

  /// 权限名称
  final String? permission;

  /// 所需权限级别
  final String? requiredLevel;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(super.toString());
    
    if (permission != null) {
      buffer.write(' Permission: $permission');
    }
    
    if (requiredLevel != null) {
      buffer.write(' Required: $requiredLevel');
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['permission'] = permission;
    map['requiredLevel'] = requiredLevel;
    return map;
  }
}

/// 插件超时异常
class {{plugin_name.pascalCase()}}TimeoutException extends {{plugin_name.pascalCase()}}Exception {
  /// 创建超时异常实例
  const {{plugin_name.pascalCase()}}TimeoutException(
    super.message, {
    super.code = {{plugin_name.pascalCase()}}Constants.errorCodeTimeout,
    super.details,
    super.stackTrace,
    super.innerException,
    this.timeoutDuration,
    this.operation,
  });

  /// 超时时长
  final Duration? timeoutDuration;

  /// 超时操作
  final String? operation;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(super.toString());
    
    if (operation != null) {
      buffer.write(' Operation: $operation');
    }
    
    if (timeoutDuration != null) {
      buffer.write(' Timeout: ${timeoutDuration!.inMilliseconds}ms');
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['timeoutDuration'] = timeoutDuration?.inMilliseconds;
    map['operation'] = operation;
    return map;
  }
}

/// 插件验证异常
class {{plugin_name.pascalCase()}}ValidationException extends {{plugin_name.pascalCase()}}Exception {
  /// 创建验证异常实例
  const {{plugin_name.pascalCase()}}ValidationException(
    super.message, {
    super.code = {{plugin_name.pascalCase()}}Constants.errorCodeValidation,
    super.details,
    super.stackTrace,
    super.innerException,
    this.field,
    this.value,
    this.validationRule,
  });

  /// 验证字段
  final String? field;

  /// 验证值
  final dynamic value;

  /// 验证规则
  final String? validationRule;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(super.toString());
    
    if (field != null) {
      buffer.write(' Field: $field');
    }
    
    if (value != null) {
      buffer.write(' Value: $value');
    }
    
    if (validationRule != null) {
      buffer.write(' Rule: $validationRule');
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['field'] = field;
    map['value'] = value?.toString();
    map['validationRule'] = validationRule;
    return map;
  }
}{{#include_services}}

/// 插件服务异常
class {{plugin_name.pascalCase()}}ServiceException extends {{plugin_name.pascalCase()}}Exception {
  /// 创建服务异常实例
  const {{plugin_name.pascalCase()}}ServiceException(
    super.message, {
    super.code,
    super.details,
    super.stackTrace,
    super.innerException,
    this.serviceName,
    this.serviceOperation,
  });

  /// 服务名称
  final String? serviceName;

  /// 服务操作
  final String? serviceOperation;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(super.toString());
    
    if (serviceName != null) {
      buffer.write(' Service: $serviceName');
    }
    
    if (serviceOperation != null) {
      buffer.write(' Operation: $serviceOperation');
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['serviceName'] = serviceName;
    map['serviceOperation'] = serviceOperation;
    return map;
  }
}{{/include_services}}{{#include_ui_components}}

/// 插件UI异常
class {{plugin_name.pascalCase()}}UIException extends {{plugin_name.pascalCase()}}Exception {
  /// 创建UI异常实例
  const {{plugin_name.pascalCase()}}UIException(
    super.message, {
    super.code,
    super.details,
    super.stackTrace,
    super.innerException,
    this.widgetName,
    this.uiOperation,
  });

  /// 组件名称
  final String? widgetName;

  /// UI操作
  final String? uiOperation;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(super.toString());
    
    if (widgetName != null) {
      buffer.write(' Widget: $widgetName');
    }
    
    if (uiOperation != null) {
      buffer.write(' Operation: $uiOperation');
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['widgetName'] = widgetName;
    map['uiOperation'] = uiOperation;
    return map;
  }
}{{/include_ui_components}}

/// 插件状态异常
class {{plugin_name.pascalCase()}}StateException extends {{plugin_name.pascalCase()}}Exception {
  /// 创建状态异常实例
  const {{plugin_name.pascalCase()}}StateException(
    super.message, {
    super.code,
    super.details,
    super.stackTrace,
    super.innerException,
    this.currentState,
    this.expectedState,
    this.operation,
  });

  /// 当前状态
  final String? currentState;

  /// 期望状态
  final String? expectedState;

  /// 操作名称
  final String? operation;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(super.toString());
    
    if (operation != null) {
      buffer.write(' Operation: $operation');
    }
    
    if (currentState != null) {
      buffer.write(' Current: $currentState');
    }
    
    if (expectedState != null) {
      buffer.write(' Expected: $expectedState');
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['currentState'] = currentState;
    map['expectedState'] = expectedState;
    map['operation'] = operation;
    return map;
  }
}
