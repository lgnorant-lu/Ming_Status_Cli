@echo off
REM Git提交信息格式检查脚本 (Windows版本)
REM 基于DEC-001决策的约定式提交规范

setlocal enabledelayedexpansion

if "%~1"=="" (
    echo 用法: %0 "commit-message"
    echo 示例: %0 "feat(core): 添加新的验证功能"
    exit /b 1
)

set "commit_msg=%~1"

REM 提取第一行
for /f "tokens=1 delims=" %%a in ("%commit_msg%") do set "title_line=%%a"

echo 🔍 检查提交信息格式...
echo 提交信息: %title_line%

REM 简单的格式检查 (Windows批处理的正则表达式支持有限)
echo %title_line% | findstr /r "^feat\|^fix\|^docs\|^style\|^refactor\|^perf\|^test\|^build\|^ci\|^chore\|^revert" >nul

if %errorlevel% equ 0 (
    echo ✅ 提交信息格式正确
    exit /b 0
) else (
    echo ❌ 提交信息格式错误
    echo.
    echo 正确格式: ^<type^>^(^<scope^>^): ^<description^>
    echo 示例: feat^(core^): 添加新的验证功能
    echo.
    echo 支持的类型:
    echo   feat     - 新功能
    echo   fix      - Bug修复
    echo   docs     - 文档更新
    echo   style    - 代码格式
    echo   refactor - 代码重构
    echo   perf     - 性能优化
    echo   test     - 测试相关
    echo   build    - 构建相关
    echo   ci       - CI/CD相关
    echo   chore    - 其他杂项
    echo   revert   - 撤销提交
    echo.
    echo 常用范围:
    echo   core       - 核心系统
    echo   cli        - 命令行接口
    echo   validators - 验证器
    echo   templates  - 模板系统
    echo   config     - 配置管理
    echo   test       - 测试相关
    echo   docs       - 文档相关
    exit /b 1
)
