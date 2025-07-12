/*
---------------------------------------------------------------
File name:          firebase_config_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        firebase.json配置文件生成器 (Firebase Configuration Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Initial creation - Firebase配置文件生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/config/config_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// firebase.json配置文件生成器
///
/// 负责生成Firebase项目的配置文件
class FirebaseConfigGenerator extends ConfigGeneratorBase {
  /// 创建firebase.json生成器实例
  const FirebaseConfigGenerator();

  @override
  String getFileName() => 'firebase.json';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer()
      ..writeln('{')
      ..writeln('  "hosting": {')
      ..writeln('    "public": "build/web",')
      ..writeln('    "ignore": [')
      ..writeln('      "firebase.json",')
      ..writeln('      "**/.*",')
      ..writeln('      "**/node_modules/**"')
      ..writeln('    ],')
      ..writeln('    "rewrites": [')
      ..writeln('      {')
      ..writeln('        "source": "**",')
      ..writeln('        "destination": "/index.html"')
      ..writeln('      }')
      ..writeln('    ],')
      ..writeln('    "headers": [')
      ..writeln('      {')
      ..writeln(
        '        "source": "**/*.@(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)",',
      )
      ..writeln('        "headers": [')
      ..writeln('          {')
      ..writeln('            "key": "Cache-Control",')
      ..writeln('            "value": "max-age=31536000"')
      ..writeln('          }')
      ..writeln('        ]')
      ..writeln('      }')
      ..writeln('    ]')
      ..writeln('  },');

    // 根据复杂度添加不同的Firebase服务
    if (config.complexity == TemplateComplexity.enterprise) {
      _addEnterpriseServices(buffer, config);
    } else {
      _addBasicServices(buffer, config);
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  /// 添加基础Firebase服务
  void _addBasicServices(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  "firestore": {')
      ..writeln('    "rules": "firestore.rules",')
      ..writeln('    "indexes": "firestore.indexes.json"')
      ..writeln('  },')
      ..writeln('  "storage": {')
      ..writeln('    "rules": "storage.rules"')
      ..writeln('  }');
  }

  /// 添加企业级Firebase服务
  void _addEnterpriseServices(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln('  "firestore": {')
      ..writeln('    "rules": "firestore.rules",')
      ..writeln('    "indexes": "firestore.indexes.json"')
      ..writeln('  },')
      ..writeln('  "storage": {')
      ..writeln('    "rules": "storage.rules"')
      ..writeln('  },')
      ..writeln('  "functions": {')
      ..writeln('    "predeploy": [')
      ..writeln(r'      "npm --prefix \"$RESOURCE_DIR\" run lint",')
      ..writeln(r'      "npm --prefix \"$RESOURCE_DIR\" run build"')
      ..writeln('    ],')
      ..writeln('    "source": "functions"')
      ..writeln('  },')
      ..writeln('  "emulators": {')
      ..writeln('    "auth": {')
      ..writeln('      "port": 9099')
      ..writeln('    },')
      ..writeln('    "firestore": {')
      ..writeln('      "port": 8080')
      ..writeln('    },')
      ..writeln('    "storage": {')
      ..writeln('      "port": 9199')
      ..writeln('    },')
      ..writeln('    "functions": {')
      ..writeln('      "port": 5001')
      ..writeln('    },')
      ..writeln('    "hosting": {')
      ..writeln('      "port": 5000')
      ..writeln('    },')
      ..writeln('    "ui": {')
      ..writeln('      "enabled": true,')
      ..writeln('      "port": 4000')
      ..writeln('    }')
      ..writeln('  }');
  }
}
