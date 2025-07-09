/*
---------------------------------------------------------------
File name:          documentation_system_test.dart
Author:             lgnorant-lu
Date created:       2025-07-08
Last modified:      2025-07-08
Dart Version:       3.2+
Description:        Task 50.2 - 文档体系完整性测试
                    验证文档的完整性、链接有效性和内容质量
---------------------------------------------------------------
Change History:
    2025-07-08: Initial creation - 文档体系测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Task 50.2: 文档体系完整性测试', () {
    late Directory docsDir;
    late List<File> documentFiles;

    setUpAll(() async {
      // 获取文档目录
      docsDir = Directory('docs');

      if (!docsDir.existsSync()) {
        throw Exception('文档目录不存在: ${docsDir.path}');
      }

      // 获取所有Markdown文档
      documentFiles = docsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.md'))
          .toList();

      print('📚 找到 ${documentFiles.length} 个文档文件');
    });

    group('文档文件完整性测试', () {
      test('应该包含所有必需的文档文件', () {
        final requiredDocs = [
          'README.md',
          'user_manual.md',
          'api_documentation.md',
          'developer_guide.md',
          'cross_platform_compatibility.md',
          'performance_benchmark_report.md',
          'user_experience_optimization_report.md',
        ];

        for (final docName in requiredDocs) {
          final docPath = path.join(docsDir.path, docName);
          final docFile = File(docPath);

          expect(docFile.existsSync(), isTrue, reason: '必需文档 $docName 不存在');

          // 检查文件不为空
          final content = docFile.readAsStringSync();
          expect(content.trim(), isNotEmpty, reason: '文档 $docName 内容为空');

          print('✅ 验证文档: $docName');
        }
      });

      test('所有文档文件应该可读且格式正确', () {
        for (final file in documentFiles) {
          try {
            final content = file.readAsStringSync();

            // 检查文件不为空
            expect(content.trim(), isNotEmpty, reason: '文档文件 ${file.path} 为空');

            // 检查是否包含标题
            expect(content, contains('#'), reason: '文档文件 ${file.path} 缺少标题');

            print('✅ 验证文档格式: ${path.basename(file.path)}');
          } catch (e) {
            fail('无法读取文档文件 ${file.path}: $e');
          }
        }
      });
    });

    group('文档内容质量测试', () {
      test('用户手册应该包含完整的章节', () {
        final userManualFile = File(path.join(docsDir.path, 'user_manual.md'));
        expect(userManualFile.existsSync(), isTrue);

        final content = userManualFile.readAsStringSync();

        final requiredSections = [
          '快速开始',
          '安装指南',
          '基础概念',
          '命令参考',
          '工作流程',
          '配置管理',
          '模板系统',
          '故障排除',
          '最佳实践',
          '常见问题',
        ];

        for (final section in requiredSections) {
          expect(content, contains(section), reason: '用户手册缺少章节: $section');
        }

        print('✅ 用户手册章节完整性验证通过');
      });

      test('API文档应该包含完整的API参考', () {
        final apiDocFile =
            File(path.join(docsDir.path, 'api_documentation.md'));
        expect(apiDocFile.existsSync(), isTrue);

        final content = apiDocFile.readAsStringSync();

        final requiredSections = [
          '核心架构',
          '公共API',
          '服务接口',
          '数据模型',
          '扩展接口',
          '错误处理',
          '示例代码',
        ];

        for (final section in requiredSections) {
          expect(content, contains(section), reason: 'API文档缺少章节: $section');
        }

        // 检查代码示例
        expect(content, contains('```dart'), reason: 'API文档应该包含Dart代码示例');

        print('✅ API文档内容完整性验证通过');
      });

      test('开发者指南应该包含开发相关信息', () {
        final devGuideFile =
            File(path.join(docsDir.path, 'developer_guide.md'));
        expect(devGuideFile.existsSync(), isTrue);

        final content = devGuideFile.readAsStringSync();

        final requiredSections = [
          '开发环境设置',
          '项目结构',
          '开发工作流',
          '代码规范',
          '测试指南',
          '调试技巧',
          '性能优化',
          '发布流程',
        ];

        for (final section in requiredSections) {
          expect(content, contains(section), reason: '开发者指南缺少章节: $section');
        }

        print('✅ 开发者指南内容完整性验证通过');
      });
    });

    group('文档链接有效性测试', () {
      test('应该验证内部链接的有效性', () {
        for (final file in documentFiles) {
          final content = file.readAsStringSync();
          final fileName = path.basename(file.path);

          // 查找Markdown链接
          final linkRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
          final matches = linkRegex.allMatches(content);

          for (final match in matches) {
            final linkText = match.group(1)!;
            final linkUrl = match.group(2)!;

            // 检查内部链接（相对路径）
            if (!linkUrl.startsWith('http') && !linkUrl.startsWith('#')) {
              final targetPath = path.join(docsDir.path, linkUrl.split('#')[0]);
              final targetFile = File(targetPath);

              expect(targetFile.existsSync(), isTrue,
                  reason: '在 $fileName 中发现无效链接: $linkText -> $linkUrl',);
            }
          }

          print('✅ 验证链接: $fileName');
        }
      });

      test('应该验证锚点链接的有效性', () {
        for (final file in documentFiles) {
          final content = file.readAsStringSync();
          final fileName = path.basename(file.path);

          // 查找锚点链接
          final anchorLinkRegex = RegExp(r'\[([^\]]+)\]\(#([^)]+)\)');
          final anchorMatches = anchorLinkRegex.allMatches(content);

          // 查找标题（潜在的锚点）
          final headerRegex = RegExp(r'^#+\s+(.+)$', multiLine: true);
          final headers = headerRegex
              .allMatches(content)
              .map((match) => match.group(1)!)
              .map((header) => header
                  .toLowerCase()
                  .replaceAll(' ', '-')
                  .replaceAll(RegExp(r'[^\w\-]'), ''),)
              .toSet();

          for (final match in anchorMatches) {
            final linkText = match.group(1)!;
            final anchor = match.group(2)!;

            // 简单的锚点验证（可能需要更复杂的逻辑）
            final hasMatchingHeader = headers.any((header) =>
                header.contains(anchor.toLowerCase()) ||
                anchor.toLowerCase().contains(header),);

            if (!hasMatchingHeader) {
              print('⚠️  可能的无效锚点链接在 $fileName: $linkText -> #$anchor');
            }
          }

          print('✅ 验证锚点: $fileName');
        }
      });
    });

    group('文档结构一致性测试', () {
      test('所有文档应该有一致的标题结构', () {
        for (final file in documentFiles) {
          final content = file.readAsStringSync();
          final fileName = path.basename(file.path);

          // 检查是否有主标题（# 标题）
          expect(content, matches(RegExp(r'^#\s+.+', multiLine: true)),
              reason: '文档 $fileName 缺少主标题',);

          // 检查标题层级是否合理（不应该跳级）
          final headerRegex = RegExp(r'^(#+)\s+(.+)$', multiLine: true);
          final headers = headerRegex.allMatches(content).toList();

          for (var i = 1; i < headers.length; i++) {
            final prevLevel = headers[i - 1].group(1)!.length;
            final currLevel = headers[i].group(1)!.length;

            // 标题级别不应该跳跃超过1级
            if (currLevel > prevLevel + 1) {
              print('⚠️  标题级别跳跃在 $fileName: ${headers[i].group(2)}');
            }
          }

          print('✅ 验证标题结构: $fileName');
        }
      });

      test('文档应该包含版本信息和更新日期', () {
        final importantDocs = [
          'user_manual.md',
          'api_documentation.md',
          'developer_guide.md',
        ];

        for (final docName in importantDocs) {
          final docFile = File(path.join(docsDir.path, docName));
          if (docFile.existsSync()) {
            final content = docFile.readAsStringSync();

            // 检查是否包含版本信息
            final hasVersion = content.contains('版本') ||
                content.contains('version') ||
                content.contains('Version');

            // 检查是否包含日期信息
            final hasDate = content.contains('2025-07-08') ||
                content.contains('最后更新') ||
                content.contains('Last updated');

            expect(hasVersion || hasDate, isTrue,
                reason: '文档 $docName 缺少版本或日期信息',);

            print('✅ 验证版本信息: $docName');
          }
        }
      });
    });

    group('文档可读性测试', () {
      test('文档应该有适当的长度', () {
        for (final file in documentFiles) {
          final content = file.readAsStringSync();
          final fileName = path.basename(file.path);

          // 检查文档长度（行数）
          final lines = content.split('\n');
          expect(lines.length, greaterThan(10), reason: '文档 $fileName 内容过短');

          // 检查是否有足够的内容（字符数）
          expect(content.length, greaterThan(500), reason: '文档 $fileName 内容不足');

          print('✅ 验证文档长度: $fileName (${lines.length} 行)');
        }
      });

      test('文档应该有清晰的段落结构', () {
        for (final file in documentFiles) {
          final content = file.readAsStringSync();
          final fileName = path.basename(file.path);

          // 检查是否有适当的空行分隔
          final hasEmptyLines = content.contains('\n\n') ||
              content.contains('\r\n\r\n') ||
              content.split('\n').any((line) => line.trim().isEmpty);
          expect(hasEmptyLines, isTrue, reason: '文档 $fileName 缺少段落分隔');

          // 检查是否有列表结构
          final hasLists = content.contains('- ') ||
              content.contains('1. ') ||
              content.contains('* ');

          if (fileName != 'README.md') {
            expect(hasLists, isTrue, reason: '文档 $fileName 建议包含列表结构以提高可读性');
          }

          print('✅ 验证段落结构: $fileName');
        }
      });
    });

    group('文档完整性统计', () {
      test('应该生成文档统计报告', () {
        var totalLines = 0;
        var totalChars = 0;
        var totalWords = 0;

        print('\n📊 文档统计报告:');
        print('=' * 50);

        for (final file in documentFiles) {
          final content = file.readAsStringSync();
          final fileName = path.basename(file.path);

          final lines = content.split('\n').length;
          final chars = content.length;
          final words = content.split(RegExp(r'\s+')).length;

          totalLines += lines;
          totalChars += chars;
          totalWords += words;

          print('📄 $fileName:');
          print('   行数: $lines');
          print('   字符数: $chars');
          print('   单词数: $words');
          print('');
        }

        print('📊 总计:');
        print('   文档数量: ${documentFiles.length}');
        print('   总行数: $totalLines');
        print('   总字符数: $totalChars');
        print('   总单词数: $totalWords');
        print('=' * 50);

        // 验证文档规模合理
        expect(documentFiles.length, greaterThanOrEqualTo(7),
            reason: '文档数量应该至少有7个',);
        expect(totalLines, greaterThan(1000), reason: '文档总行数应该超过1000行');
        expect(totalChars, greaterThan(50000), reason: '文档总字符数应该超过50000字符');

        print('✅ 文档统计验证通过');
      });
    });
  });
}
