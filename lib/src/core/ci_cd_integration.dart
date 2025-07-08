/*
---------------------------------------------------------------
File name:          ci_cd_integration.dart
Author:             lgnorant-lu
Date created:       2025/07/08
Last modified:      2025/07/08
Dart Version:       3.2+
Description:        CI/CD流水线集成支持
---------------------------------------------------------------
Change History:
    2025/07/08: Initial creation - CI/CD集成功能;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// CI/CD集成管理器
///
/// 提供与各种CI/CD平台的集成支持，包括：
/// - GitHub Actions
/// - GitLab CI
/// - Jenkins
/// - Azure DevOps
/// - 通用CI/CD平台
class CiCdIntegration {
  /// 创建CI/CD集成管理器
  const CiCdIntegration();

  /// 检测当前CI/CD环境
  CiCdEnvironment detectEnvironment() {
    // GitHub Actions
    if (Platform.environment.containsKey('GITHUB_ACTIONS')) {
      return CiCdEnvironment.githubActions;
    }

    // GitLab CI
    if (Platform.environment.containsKey('GITLAB_CI')) {
      return CiCdEnvironment.gitlabCi;
    }

    // Jenkins
    if (Platform.environment.containsKey('JENKINS_URL')) {
      return CiCdEnvironment.jenkins;
    }

    // Azure DevOps
    if (Platform.environment.containsKey('AZURE_HTTP_USER_AGENT')) {
      return CiCdEnvironment.azureDevOps;
    }

    // Travis CI
    if (Platform.environment.containsKey('TRAVIS')) {
      return CiCdEnvironment.travisCi;
    }

    // CircleCI
    if (Platform.environment.containsKey('CIRCLECI')) {
      return CiCdEnvironment.circleCi;
    }

    // 通用CI环境检测
    if (Platform.environment.containsKey('CI')) {
      return CiCdEnvironment.generic;
    }

    return CiCdEnvironment.local;
  }

  /// 为CI/CD环境配置验证参数
  Map<String, dynamic> configureForCiCd(CiCdEnvironment environment) {
    final config = <String, dynamic>{
      'non_interactive': true,
      'output_format': 'json',
      'exit_on_error': true,
      'parallel_execution': true,
      'timeout_seconds': 600, // 10分钟超时
    };

    switch (environment) {
      case CiCdEnvironment.githubActions:
        config.addAll({
          'output_file': 'validation-report.json',
          'junit_output': 'test-results.xml',
          'enable_annotations': true,
        });

      case CiCdEnvironment.gitlabCi:
        config.addAll({
          'output_file': 'validation-report.json',
          'junit_output': 'junit.xml',
          'artifacts_path': 'reports/',
        });

      case CiCdEnvironment.jenkins:
        config.addAll({
          'output_file': 'validation-report.json',
          'junit_output': 'TEST-validation.xml',
          'workspace_relative': true,
        });

      case CiCdEnvironment.azureDevOps:
        config.addAll({
          'output_file': 'validation-report.json',
          'junit_output': 'test-results.xml',
          'azure_artifacts': true,
        });

      default:
        config.addAll({
          'output_file': 'validation-report.json',
          'junit_output': 'test-results.xml',
        });
    }

    return config;
  }

  /// 生成CI/CD配置文件
  Future<void> generateCiCdConfig(
    CiCdEnvironment environment,
    String projectPath,
  ) async {
    switch (environment) {
      case CiCdEnvironment.githubActions:
        await _generateGitHubActionsConfig(projectPath);

      case CiCdEnvironment.gitlabCi:
        await _generateGitLabCiConfig(projectPath);

      case CiCdEnvironment.jenkins:
        await _generateJenkinsConfig(projectPath);

      case CiCdEnvironment.azureDevOps:
        await _generateAzureDevOpsConfig(projectPath);

      default:
        Logger.warning('不支持为 $environment 生成配置文件');
    }
  }

  /// 生成GitHub Actions配置
  Future<void> _generateGitHubActionsConfig(String projectPath) async {
    const config = r'''
name: Ming Status CLI Validation

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Setup Dart
      uses: dart-lang/setup-dart@v1
      with:
        sdk: stable

    - name: Install dependencies
      run: dart pub get

    - name: Install Ming Status CLI
      run: dart pub global activate --source path .

    - name: Run validation
      run: |
        ming validate . \
          --output=json \
          --output-file=validation-report.json \
          --junit-output=test-results.xml \
          --strict \
          --parallel

    - name: Upload validation report
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: validation-report
        path: |
          validation-report.json
          test-results.xml

    - name: Publish test results
      uses: dorny/test-reporter@v1
      if: always()
      with:
        name: Validation Results
        path: test-results.xml
        reporter: java-junit
''';

    final configPath =
        path.join(projectPath, '.github', 'workflows', 'validation.yml');
    await Directory(path.dirname(configPath)).create(recursive: true);
    await File(configPath).writeAsString(config);

    Logger.info('✅ GitHub Actions配置已生成: $configPath');
  }

  /// 生成GitLab CI配置
  Future<void> _generateGitLabCiConfig(String projectPath) async {
    const config = r'''
stages:
  - validate

variables:
  DART_SDK: "stable"

validate:
  stage: validate
  image: dart:stable
  
  before_script:
    - dart pub get
    - dart pub global activate --source path .
  
  script:
    - |
      ming validate . \
        --output=json \
        --output-file=validation-report.json \
        --junit-output=junit.xml \
        --strict \
        --parallel
  
  artifacts:
    when: always
    paths:
      - validation-report.json
      - junit.xml
    reports:
      junit: junit.xml
    expire_in: 1 week
  
  only:
    - main
    - develop
    - merge_requests
''';

    final configPath = path.join(projectPath, '.gitlab-ci.yml');
    await File(configPath).writeAsString(config);

    Logger.info('✅ GitLab CI配置已生成: $configPath');
  }

  /// 生成Jenkins配置
  Future<void> _generateJenkinsConfig(String projectPath) async {
    const config = '''
pipeline {
    agent any

    environment {
        DART_SDK = 'stable'
    }

    stages {
        stage('Setup') {
            steps {
                sh 'dart pub get'
                sh 'dart pub global activate --source path .'
            }
        }

        stage('Validate') {
            steps {
                sh \'\'\'
                    ming validate . \\\\
                      --output=json \\\\
                      --output-file=validation-report.json \\\\
                      --junit-output=TEST-validation.xml \\\\
                      --strict \\\\
                      --parallel
                \'\'\'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'validation-report.json, TEST-validation.xml', allowEmptyArchive: true
                    publishTestResults testResultsPattern: 'TEST-validation.xml'
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
''';

    final configPath = path.join(projectPath, 'Jenkinsfile');
    await File(configPath).writeAsString(config);

    Logger.info('✅ Jenkins配置已生成: $configPath');
  }

  /// 生成Azure DevOps配置
  Future<void> _generateAzureDevOpsConfig(String projectPath) async {
    const config = r'''
trigger:
  branches:
    include:
      - main
      - develop

pr:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  dartSdkVersion: 'stable'

steps:
- task: UseNode@1
  displayName: 'Setup Dart SDK'
  inputs:
    version: '\$(dartSdkVersion)'

- script: |
    dart pub get
    dart pub global activate --source path .
  displayName: 'Install dependencies'

- script: |
    ming validate . \
      --output=json \
      --output-file=validation-report.json \
      --junit-output=test-results.xml \
      --strict \
      --parallel
  displayName: 'Run validation'

- task: PublishTestResults@2
  condition: always()
  inputs:
    testResultsFormat: 'JUnit'
    testResultsFiles: 'test-results.xml'
    testRunTitle: 'Ming Status CLI Validation'

- task: PublishBuildArtifacts@1
  condition: always()
  inputs:
    pathToPublish: 'validation-report.json'
    artifactName: 'validation-report'
''';

    final configPath = path.join(projectPath, 'azure-pipelines.yml');
    await File(configPath).writeAsString(config);

    Logger.info('✅ Azure DevOps配置已生成: $configPath');
  }

  /// 设置CI/CD环境变量
  void setCiCdEnvironmentVariables(Map<String, String> variables) {
    for (final entry in variables.entries) {
      Platform.environment[entry.key] = entry.value;
    }
  }

  /// 检查是否在CI/CD环境中运行
  bool get isRunningInCiCd => detectEnvironment() != CiCdEnvironment.local;

  /// 获取CI/CD环境信息
  Map<String, String> getCiCdInfo() {
    final environment = detectEnvironment();
    final info = <String, String>{
      'environment': environment.toString(),
      'is_ci': isRunningInCiCd.toString(),
    };

    // 添加特定环境的信息
    switch (environment) {
      case CiCdEnvironment.githubActions:
        info.addAll({
          'github_repository': Platform.environment['GITHUB_REPOSITORY'] ?? '',
          'github_ref': Platform.environment['GITHUB_REF'] ?? '',
          'github_sha': Platform.environment['GITHUB_SHA'] ?? '',
        });

      case CiCdEnvironment.gitlabCi:
        info.addAll({
          'gitlab_project_path': Platform.environment['CI_PROJECT_PATH'] ?? '',
          'gitlab_commit_sha': Platform.environment['CI_COMMIT_SHA'] ?? '',
          'gitlab_pipeline_id': Platform.environment['CI_PIPELINE_ID'] ?? '',
        });

      case CiCdEnvironment.jenkins:
        info.addAll({
          'jenkins_job_name': Platform.environment['JOB_NAME'] ?? '',
          'jenkins_build_number': Platform.environment['BUILD_NUMBER'] ?? '',
          'jenkins_build_url': Platform.environment['BUILD_URL'] ?? '',
        });

      default:
        break;
    }

    return info;
  }
}

/// CI/CD环境类型
enum CiCdEnvironment {
  /// 本地开发环境
  local,

  /// GitHub Actions
  githubActions,

  /// GitLab CI
  gitlabCi,

  /// Jenkins
  jenkins,

  /// Azure DevOps
  azureDevOps,

  /// Travis CI
  travisCi,

  /// CircleCI
  circleCi,

  /// 通用CI环境
  generic,
}
