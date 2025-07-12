/*
---------------------------------------------------------------
File name:          arb_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        ARB国际化文件生成器 (ARB Localization Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加更多语言支持
    - [ ] 支持复数形式和性别变化
    - [ ] 添加上下文信息和描述
---------------------------------------------------------------
*/

import 'dart:convert';
import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/template_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// ARB国际化文件生成器
///
/// 负责生成Flutter应用程序的ARB国际化文件
class ArbGenerator extends TemplateGeneratorBase {
  /// 创建ARB生成器实例
  const ArbGenerator({
    required this.languageCode,
    required this.countryCode,
  });

  /// 语言代码
  final String languageCode;

  /// 国家代码
  final String? countryCode;

  @override
  String getTemplateFileName() => 'app_${_getLocaleCode()}.arb.template';

  @override
  String getOutputFileName(ScaffoldConfig config) 
    => 'app_${_getLocaleCode()}.arb.template';

  @override
  String generateContent(ScaffoldConfig config) {
    final arbContent = <String, dynamic>{};

    // 添加元数据
    arbContent['@@locale'] = _getLocaleCode();
    arbContent['@@last_modified'] = DateTime.now().toIso8601String();
    arbContent['@@author'] = config.author;

    // 根据复杂度添加不同的翻译内容
    if (config.complexity == TemplateComplexity.simple) {
      _addSimpleTranslations(arbContent);
    } else if (config.complexity == TemplateComplexity.medium) {
      _addMediumTranslations(arbContent);
    } else {
      _addComplexTranslations(arbContent);
    }

    // 添加应用特定的翻译
    _addAppSpecificTranslations(arbContent, config);

    // 格式化为JSON
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(arbContent);
  }

  /// 添加简单翻译内容
  void _addSimpleTranslations(Map<String, dynamic> arb) {
    final translations = _getSimpleTranslations();
    arb.addAll(translations);

    // 添加元数据
    arb['@appTitle'] = {
      'description': 'The title of the application',
    };
    arb['@welcome'] = {
      'description': 'Welcome message',
    };
    arb['@hello'] = {
      'description': 'Greeting message',
      'placeholders': {
        'name': {
          'type': 'String',
          'example': 'John',
        },
      },
    };
  }

  /// 添加中等复杂度翻译内容
  void _addMediumTranslations(Map<String, dynamic> arb) {
    final translations = _getMediumTranslations();
    arb.addAll(translations);

    // 添加元数据
    arb['@appTitle'] = {
      'description': 'The title of the application',
    };
    arb['@welcome'] = {
      'description': 'Welcome message displayed on the home screen',
    };
    arb['@hello'] = {
      'description': 'Personalized greeting message',
      'placeholders': {
        'name': {
          'type': 'String',
          'example': 'John',
          'description': 'User name',
        },
      },
    };
    arb['@itemCount'] = {
      'description': 'Number of items with plural support',
      'placeholders': {
        'count': {
          'type': 'int',
          'format': 'compact',
        },
      },
    };
  }

  /// 添加复杂翻译内容
  void _addComplexTranslations(Map<String, dynamic> arb) {
    final translations = _getComplexTranslations();
    arb.addAll(translations);

    // 添加详细元数据
    arb['@appTitle'] = {
      'description': 'The title of the application displayed in the app bar',
      'context': 'app_bar',
    };
    arb['@welcome'] = {
      'description': 'Welcome message displayed on the home screen',
      'context': 'home_screen',
    };
    arb['@hello'] = {
      'description': 'Personalized greeting message with user name',
      'context': 'greeting',
      'placeholders': {
        'name': {
          'type': 'String',
          'example': 'John Doe',
          'description': 'Full name of the user',
        },
      },
    };
    arb['@itemCount'] = {
      'description': 'Number of items with plural support',
      'context': 'item_list',
      'placeholders': {
        'count': {
          'type': 'int',
          'format': 'compact',
          'description': 'Total number of items',
        },
      },
    };
    arb['@lastUpdated'] = {
      'description': 'Last updated timestamp',
      'context': 'status',
      'placeholders': {
        'date': {
          'type': 'DateTime',
          'format': 'yMd',
          'description': 'Date when content was last updated',
        },
      },
    };
  }

  /// 添加应用特定翻译
  void _addAppSpecificTranslations(Map<String, dynamic> arb, ScaffoldConfig config) {
    arb['appName'] = _getAppNameTranslation(config);
    arb['appDescription'] = _getAppDescriptionTranslation(config);
    
    arb['@appName'] = {
      'description': 'Application name',
      'context': 'app_info',
    };
    arb['@appDescription'] = {
      'description': 'Application description',
      'context': 'app_info',
    };
  }

  /// 获取简单翻译内容
  Map<String, String> _getSimpleTranslations() {
    switch (languageCode) {
      case 'zh':
        return {
          'appTitle': '我的应用',
          'welcome': '欢迎',
          'hello': '你好，{name}！',
          'settings': '设置',
          'about': '关于',
          'ok': '确定',
          'cancel': '取消',
        };
      case 'ja':
        return {
          'appTitle': 'マイアプリ',
          'welcome': 'ようこそ',
          'hello': 'こんにちは、{name}さん！',
          'settings': '設定',
          'about': 'について',
          'ok': 'OK',
          'cancel': 'キャンセル',
        };
      case 'ko':
        return {
          'appTitle': '내 앱',
          'welcome': '환영합니다',
          'hello': '안녕하세요, {name}님！',
          'settings': '설정',
          'about': '정보',
          'ok': '확인',
          'cancel': '취소',
        };
      default: // English
        return {
          'appTitle': 'My App',
          'welcome': 'Welcome',
          'hello': 'Hello, {name}!',
          'settings': 'Settings',
          'about': 'About',
          'ok': 'OK',
          'cancel': 'Cancel',
        };
    }
  }

  /// 获取中等复杂度翻译内容
  Map<String, String> _getMediumTranslations() {
    final base = _getSimpleTranslations();
    
    switch (languageCode) {
      case 'zh':
        base.addAll({
          'home': '首页',
          'profile': '个人资料',
          'notifications': '通知',
          'search': '搜索',
          'loading': '加载中...',
          'error': '错误',
          'retry': '重试',
          'save': '保存',
          'delete': '删除',
          'edit': '编辑',
          'itemCount': '{count, plural, =0{没有项目} =1{1个项目} other{{count}个项目}}',
        });
      case 'ja':
        base.addAll({
          'home': 'ホーム',
          'profile': 'プロフィール',
          'notifications': '通知',
          'search': '検索',
          'loading': '読み込み中...',
          'error': 'エラー',
          'retry': '再試行',
          'save': '保存',
          'delete': '削除',
          'edit': '編集',
          'itemCount': '{count, plural, =0{アイテムなし} =1{1つのアイテム} other{{count}つのアイテム}}',
        });
      case 'ko':
        base.addAll({
          'home': '홈',
          'profile': '프로필',
          'notifications': '알림',
          'search': '검색',
          'loading': '로딩 중...',
          'error': '오류',
          'retry': '다시 시도',
          'save': '저장',
          'delete': '삭제',
          'edit': '편집',
          'itemCount': '{count, plural, =0{항목 없음} =1{1개 항목} other{{count}개 항목}}',
        });
      default: // English
        base.addAll({
          'home': 'Home',
          'profile': 'Profile',
          'notifications': 'Notifications',
          'search': 'Search',
          'loading': 'Loading...',
          'error': 'Error',
          'retry': 'Retry',
          'save': 'Save',
          'delete': 'Delete',
          'edit': 'Edit',
          'itemCount': '{count, plural, =0{No items} =1{1 item} other{{count} items}}',
        });
    }
    
    return base;
  }

  /// 获取复杂翻译内容
  Map<String, String> _getComplexTranslations() {
    final base = _getMediumTranslations();
    
    switch (languageCode) {
      case 'zh':
        base.addAll({
          'login': '登录',
          'logout': '登出',
          'register': '注册',
          'forgotPassword': '忘记密码',
          'email': '邮箱',
          'password': '密码',
          'confirmPassword': '确认密码',
          'firstName': '名字',
          'lastName': '姓氏',
          'phoneNumber': '电话号码',
          'address': '地址',
          'city': '城市',
          'country': '国家',
          'language': '语言',
          'theme': '主题',
          'darkMode': '暗色模式',
          'lightMode': '亮色模式',
          'systemMode': '跟随系统',
          'lastUpdated': '最后更新：{date}',
          'version': '版本',
          'privacyPolicy': '隐私政策',
          'termsOfService': '服务条款',
          'contactUs': '联系我们',
          'feedback': '反馈',
          'rateApp': '评价应用',
          'shareApp': '分享应用',
        });
      case 'ja':
        base.addAll({
          'login': 'ログイン',
          'logout': 'ログアウト',
          'register': '登録',
          'forgotPassword': 'パスワードを忘れた',
          'email': 'メール',
          'password': 'パスワード',
          'confirmPassword': 'パスワード確認',
          'firstName': '名前',
          'lastName': '姓',
          'phoneNumber': '電話番号',
          'address': '住所',
          'city': '市',
          'country': '国',
          'language': '言語',
          'theme': 'テーマ',
          'darkMode': 'ダークモード',
          'lightMode': 'ライトモード',
          'systemMode': 'システム設定',
          'lastUpdated': '最終更新：{date}',
          'version': 'バージョン',
          'privacyPolicy': 'プライバシーポリシー',
          'termsOfService': '利用規約',
          'contactUs': 'お問い合わせ',
          'feedback': 'フィードバック',
          'rateApp': 'アプリを評価',
          'shareApp': 'アプリを共有',
        });
      case 'ko':
        base.addAll({
          'login': '로그인',
          'logout': '로그아웃',
          'register': '회원가입',
          'forgotPassword': '비밀번호 찾기',
          'email': '이메일',
          'password': '비밀번호',
          'confirmPassword': '비밀번호 확인',
          'firstName': '이름',
          'lastName': '성',
          'phoneNumber': '전화번호',
          'address': '주소',
          'city': '도시',
          'country': '국가',
          'language': '언어',
          'theme': '테마',
          'darkMode': '다크 모드',
          'lightMode': '라이트 모드',
          'systemMode': '시스템 설정',
          'lastUpdated': '마지막 업데이트: {date}',
          'version': '버전',
          'privacyPolicy': '개인정보 처리방침',
          'termsOfService': '서비스 약관',
          'contactUs': '문의하기',
          'feedback': '피드백',
          'rateApp': '앱 평가',
          'shareApp': '앱 공유',
        });
      default: // English
        base.addAll({
          'login': 'Login',
          'logout': 'Logout',
          'register': 'Register',
          'forgotPassword': 'Forgot Password',
          'email': 'Email',
          'password': 'Password',
          'confirmPassword': 'Confirm Password',
          'firstName': 'First Name',
          'lastName': 'Last Name',
          'phoneNumber': 'Phone Number',
          'address': 'Address',
          'city': 'City',
          'country': 'Country',
          'language': 'Language',
          'theme': 'Theme',
          'darkMode': 'Dark Mode',
          'lightMode': 'Light Mode',
          'systemMode': 'System Default',
          'lastUpdated': 'Last updated: {date}',
          'version': 'Version',
          'privacyPolicy': 'Privacy Policy',
          'termsOfService': 'Terms of Service',
          'contactUs': 'Contact Us',
          'feedback': 'Feedback',
          'rateApp': 'Rate App',
          'shareApp': 'Share App',
        });
    }
    
    return base;
  }

  /// 获取应用名称翻译
  String _getAppNameTranslation(ScaffoldConfig config) {
    // 这里可以根据语言返回不同的应用名称
    // 目前返回原始名称
    return config.templateName;
  }

  /// 获取应用描述翻译
  String _getAppDescriptionTranslation(ScaffoldConfig config) {
    switch (languageCode) {
      case 'zh':
        return '一个使用Flutter构建的现代化应用程序';
      case 'ja':
        return 'Flutterで構築されたモダンなアプリケーション';
      case 'ko':
        return 'Flutter로 구축된 현대적인 애플리케이션';
      default:
        return config.description;
    }
  }

  /// 获取语言环境代码
  String _getLocaleCode() {
    if (countryCode != null && countryCode!.isNotEmpty) {
      return '${languageCode}_$countryCode';
    }
    return languageCode;
  }

  @override
  Map<String, String> getTemplateVariables(ScaffoldConfig config) {
    final baseVariables = super.getTemplateVariables(config);
    
    // 添加特定于ARB的变量
    baseVariables.addAll({
      'languageCode': languageCode,
      'countryCode': countryCode ?? '',
      'localeCode': _getLocaleCode(),
      'translationCount': _getTranslationCount(config).toString(),
    });

    return baseVariables;
  }

  /// 获取翻译数量
  int _getTranslationCount(ScaffoldConfig config) {
    switch (config.complexity) {
      case TemplateComplexity.simple:
        return 7;
      case TemplateComplexity.medium:
        return 18;
      case TemplateComplexity.complex:
      case TemplateComplexity.enterprise:
        return 40;
    }
  }
}
