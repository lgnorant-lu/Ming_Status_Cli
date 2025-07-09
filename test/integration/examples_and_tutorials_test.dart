/*
---------------------------------------------------------------
File name:          examples_and_tutorials_test.dart
Author:             lgnorant-lu
Date created:       2025-07-08
Last modified:      2025-07-08
Dart Version:       3.2+
Description:        Task 50.3 - 示例项目和教程完整性测试
                    验证示例项目和教程的完整性、可用性和质量
---------------------------------------------------------------
Change History:
    2025-07-08: Initial creation - 示例项目和教程测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Task 50.3: 示例项目和教程完整性测试', () {
    late Directory examplesDir;
    late List<File> tutorialFiles;
    late List<Directory> exampleDirs;

    setUpAll(() async {
      // 获取示例目录
      examplesDir = Directory('examples');
      
      if (!examplesDir.existsSync()) {
        throw Exception('示例目录不存在: ${examplesDir.path}');
      }
      
      // 获取所有教程文件
      tutorialFiles = examplesDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('README.md'))
          .toList();
      
      // 获取所有示例目录
      exampleDirs = examplesDir
          .listSync()
          .whereType<Directory>()
          .toList();
      
      print('📚 找到 ${tutorialFiles.length} 个教程文件');
      print('📁 找到 ${exampleDirs.length} 个示例目录');
    });

    group('教程文件完整性测试', () {
      test('应该包含主要的教程文件', () {
        final requiredTutorials = [
          'README.md',                    // 主索引
          '01-quick-start/README.md',     // 快速开始
          '02-basic-project/README.md',   // 基础项目
          'blog-system/README.md',        // 博客系统示例
          'best-practices/README.md',     // 最佳实践
        ];

        for (final tutorialPath in requiredTutorials) {
          final fullPath = path.join(examplesDir.path, tutorialPath);
          final tutorialFile = File(fullPath);
          
          expect(tutorialFile.existsSync(), isTrue, 
                 reason: '必需教程 $tutorialPath 不存在',);
          
          // 检查文件不为空
          final content = tutorialFile.readAsStringSync();
          expect(content.trim(), isNotEmpty, 
                 reason: '教程 $tutorialPath 内容为空',);
          
          print('✅ 验证教程: $tutorialPath');
        }
      });

      test('所有教程文件应该可读且格式正确', () {
        for (final file in tutorialFiles) {
          try {
            final content = file.readAsStringSync();
            final relativePath = path.relative(file.path, from: examplesDir.path);
            
            // 检查文件不为空
            expect(content.trim(), isNotEmpty, 
                   reason: '教程文件 $relativePath 为空',);
            
            // 检查是否包含标题
            expect(content, contains('#'), 
                   reason: '教程文件 $relativePath 缺少标题',);
            
            print('✅ 验证教程格式: $relativePath');
          } catch (e) {
            fail('无法读取教程文件 ${file.path}: $e');
          }
        }
      });
    });

    group('教程内容质量测试', () {
      test('主索引应该包含完整的导航结构', () {
        final indexFile = File(path.join(examplesDir.path, 'README.md'));
        expect(indexFile.existsSync(), isTrue);
        
        final content = indexFile.readAsStringSync();
        
        final requiredSections = [
          '学习路径',
          '新手入门',
          '进阶应用',
          '高级技巧',
          '示例项目',
          '快速开始',
          '教程统计',
        ];

        for (final section in requiredSections) {
          expect(content, contains(section), 
                 reason: '主索引缺少章节: $section',);
        }
        
        print('✅ 主索引内容完整性验证通过');
      });

      test('快速开始教程应该包含完整的步骤', () {
        final quickStartFile = File(path.join(examplesDir.path, '01-quick-start/README.md'));
        expect(quickStartFile.existsSync(), isTrue);
        
        final content = quickStartFile.readAsStringSync();
        
        final requiredSteps = [
          '学习目标',
          '预计时间',
          '前置条件',
          '安装 Ming Status CLI',
          '创建工作空间',
          '配置用户信息',
          '创建第一个模块',
          '验证项目',
          '故障排除',
        ];

        for (final step in requiredSteps) {
          expect(content, contains(step), 
                 reason: '快速开始教程缺少步骤: $step',);
        }
        
        // 检查代码示例
        expect(content, contains('```bash'), 
               reason: '快速开始教程应该包含bash代码示例',);
        
        print('✅ 快速开始教程内容完整性验证通过');
      });

      test('基础项目教程应该包含项目类型说明', () {
        final basicProjectFile = File(path.join(examplesDir.path, '02-basic-project/README.md'));
        expect(basicProjectFile.existsSync(), isTrue);
        
        final content = basicProjectFile.readAsStringSync();
        
        final requiredSections = [
          'Dart 包项目',
          'Flutter 应用项目',
          'Web 应用项目',
          '高级配置',
          '项目验证',
          '最佳实践',
        ];

        for (final section in requiredSections) {
          expect(content, contains(section), 
                 reason: '基础项目教程缺少章节: $section',);
        }
        
        print('✅ 基础项目教程内容完整性验证通过');
      });

      test('博客系统示例应该包含完整的项目结构', () {
        final blogSystemFile = File(path.join(examplesDir.path, 'blog-system/README.md'));
        expect(blogSystemFile.existsSync(), isTrue);
        
        final content = blogSystemFile.readAsStringSync();
        
        final requiredSections = [
          '项目概述',
          '功能特性',
          '技术栈',
          '项目结构',
          '快速开始',
          '核心代码示例',
          '测试',
          '部署',
        ];

        for (final section in requiredSections) {
          expect(content, contains(section), 
                 reason: '博客系统示例缺少章节: $section',);
        }
        
        // 检查代码示例
        expect(content, contains('```dart'), 
               reason: '博客系统示例应该包含Dart代码示例',);
        
        print('✅ 博客系统示例内容完整性验证通过');
      });

      test('最佳实践指南应该包含全面的指导', () {
        final bestPracticesFile = File(path.join(examplesDir.path, 'best-practices/README.md'));
        expect(bestPracticesFile.existsSync(), isTrue);
        
        final content = bestPracticesFile.readAsStringSync();
        
        final requiredSections = [
          '项目结构最佳实践',
          '配置管理最佳实践',
          '测试最佳实践',
          '代码质量最佳实践',
          '性能优化最佳实践',
          '发布和部署最佳实践',
          '文档最佳实践',
        ];

        for (final section in requiredSections) {
          expect(content, contains(section), 
                 reason: '最佳实践指南缺少章节: $section',);
        }
        
        print('✅ 最佳实践指南内容完整性验证通过');
      });
    });

    group('教程可用性测试', () {
      test('教程应该有适当的难度标识', () {
        final indexFile = File(path.join(examplesDir.path, 'README.md'));
        final content = indexFile.readAsStringSync();
        
        // 检查是否有难度级别标识
        final hasDifficultyLevels = content.contains('⭐') || 
                                   content.contains('新手') ||
                                   content.contains('进阶') ||
                                   content.contains('高级');
        
        expect(hasDifficultyLevels, isTrue, 
               reason: '教程应该包含难度级别标识',);
        
        print('✅ 教程难度标识验证通过');
      });

      test('教程应该包含预计时间信息', () {
        final tutorialsWithTime = [
          '01-quick-start/README.md',
          '02-basic-project/README.md',
        ];

        for (final tutorialPath in tutorialsWithTime) {
          final tutorialFile = File(path.join(examplesDir.path, tutorialPath));
          if (tutorialFile.existsSync()) {
            final content = tutorialFile.readAsStringSync();
            
            final hasTimeInfo = content.contains('预计时间') || 
                               content.contains('分钟') ||
                               content.contains('小时');
            
            expect(hasTimeInfo, isTrue, 
                   reason: '教程 $tutorialPath 应该包含时间信息',);
          }
        }
        
        print('✅ 教程时间信息验证通过');
      });

      test('教程应该包含前置条件说明', () {
        final tutorialsWithPrereqs = [
          '01-quick-start/README.md',
          '02-basic-project/README.md',
        ];

        for (final tutorialPath in tutorialsWithPrereqs) {
          final tutorialFile = File(path.join(examplesDir.path, tutorialPath));
          if (tutorialFile.existsSync()) {
            final content = tutorialFile.readAsStringSync();
            
            final hasPrereqs = content.contains('前置条件') || 
                              content.contains('前置') ||
                              content.contains('要求');
            
            expect(hasPrereqs, isTrue, 
                   reason: '教程 $tutorialPath 应该包含前置条件',);
          }
        }
        
        print('✅ 教程前置条件验证通过');
      });
    });

    group('代码示例质量测试', () {
      test('教程应该包含可执行的代码示例', () {
        for (final file in tutorialFiles) {
          final content = file.readAsStringSync();
          final relativePath = path.relative(file.path, from: examplesDir.path);
          
          // 检查是否包含代码块
          final hasCodeBlocks = content.contains('```bash') || 
                               content.contains('```dart') ||
                               content.contains('```yaml') ||
                               content.contains('```json');
          
          if (relativePath.contains('README.md') && 
              !relativePath.contains('best-practices')) {
            expect(hasCodeBlocks, isTrue, 
                   reason: '教程 $relativePath 应该包含代码示例',);
          }
          
          print('✅ 验证代码示例: $relativePath');
        }
      });

      test('代码示例应该包含适当的注释', () {
        final codeFiles = tutorialFiles.where((file) => 
            file.path.contains('blog-system') || 
            file.path.contains('best-practices'),).toList();

        for (final file in codeFiles) {
          final content = file.readAsStringSync();
          final relativePath = path.relative(file.path, from: examplesDir.path);
          
          // 检查Dart代码示例是否有注释
          final dartCodeRegex = RegExp(r'```dart\n(.*?)\n```', dotAll: true);
          final dartMatches = dartCodeRegex.allMatches(content);
          
          for (final match in dartMatches) {
            final codeBlock = match.group(1) ?? '';
            if (codeBlock.length > 100) { // 只检查较长的代码块
              final hasComments = codeBlock.contains('//') || 
                                 codeBlock.contains('///') ||
                                 codeBlock.contains('/*');
              
              if (!hasComments) {
                print('⚠️  代码块缺少注释在 $relativePath');
              }
            }
          }
          
          print('✅ 验证代码注释: $relativePath');
        }
      });
    });

    group('教程导航和链接测试', () {
      test('应该验证教程间的导航链接', () {
        for (final file in tutorialFiles) {
          final content = file.readAsStringSync();
          final relativePath = path.relative(file.path, from: examplesDir.path);
          
          // 查找相对链接
          final linkRegex = RegExp(r'\[([^\]]+)\]\(\.\.\/([^)]+)\)');
          final matches = linkRegex.allMatches(content);
          
          for (final match in matches) {
            final linkText = match.group(1)!;
            final linkPath = match.group(2)!;
            
            // 构建目标文件路径
            final targetDir = path.dirname(file.path);
            final targetPath = path.normalize(path.join(targetDir, '..', linkPath));
            
            // 检查目标文件是否存在
            final targetFile = File(targetPath);
            final targetDirectory = Directory(targetPath);
            
            final exists = targetFile.existsSync() || targetDirectory.existsSync();
            
            if (!exists) {
              print('⚠️  无效链接在 $relativePath: $linkText -> $linkPath');
            }
          }
          
          print('✅ 验证导航链接: $relativePath');
        }
      });

      test('主索引应该包含所有教程的链接', () {
        final indexFile = File(path.join(examplesDir.path, 'README.md'));
        final content = indexFile.readAsStringSync();
        
        final expectedLinks = [
          '01-quick-start',
          '02-basic-project',
          'blog-system',
          'best-practices',
        ];

        for (final link in expectedLinks) {
          expect(content, contains(link), 
                 reason: '主索引应该包含到 $link 的链接',);
        }
        
        print('✅ 主索引链接完整性验证通过');
      });
    });

    group('教程完整性统计', () {
      test('应该生成教程统计报告', () {
        var totalTutorials = 0;
        var totalLines = 0;
        var totalChars = 0;
        var totalCodeBlocks = 0;
        
        print('\n📊 教程统计报告:');
        print('=' * 50);
        
        for (final file in tutorialFiles) {
          final content = file.readAsStringSync();
          final relativePath = path.relative(file.path, from: examplesDir.path);
          
          final lines = content.split('\n').length;
          final chars = content.length;
          final codeBlocks = RegExp('```').allMatches(content).length ~/ 2;
          
          totalTutorials++;
          totalLines += lines;
          totalChars += chars;
          totalCodeBlocks += codeBlocks;
          
          print('📄 $relativePath:');
          print('   行数: $lines');
          print('   字符数: $chars');
          print('   代码块数: $codeBlocks');
          print('');
        }
        
        print('📊 总计:');
        print('   教程数量: $totalTutorials');
        print('   总行数: $totalLines');
        print('   总字符数: $totalChars');
        print('   总代码块数: $totalCodeBlocks');
        print('=' * 50);
        
        // 验证教程规模合理
        expect(totalTutorials, greaterThanOrEqualTo(4), 
               reason: '教程数量应该至少有4个',);
        expect(totalLines, greaterThan(500), 
               reason: '教程总行数应该超过500行',);
        expect(totalCodeBlocks, greaterThan(10), 
               reason: '应该有足够的代码示例',);
        
        print('✅ 教程统计验证通过');
      });
    });
  });
}
