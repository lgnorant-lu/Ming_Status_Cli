#!/bin/bash

# Git提交信息格式检查脚本
# 基于DEC-001决策的约定式提交规范

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 约定式提交正则表达式
COMMIT_REGEX='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?: .{1,50}'

# 检查函数
check_commit_message() {
    local commit_msg="$1"
    
    echo -e "${BLUE}🔍 检查提交信息格式...${NC}"
    echo -e "提交信息: ${YELLOW}$commit_msg${NC}"
    
    if [[ $commit_msg =~ $COMMIT_REGEX ]]; then
        echo -e "${GREEN}✅ 提交信息格式正确${NC}"
        return 0
    else
        echo -e "${RED}❌ 提交信息格式错误${NC}"
        echo -e "${YELLOW}正确格式: <type>(<scope>): <description>${NC}"
        echo -e "${YELLOW}示例: feat(core): 添加新的验证功能${NC}"
        echo ""
        echo -e "${BLUE}支持的类型:${NC}"
        echo -e "  ${GREEN}feat${NC}     - 新功能"
        echo -e "  ${GREEN}fix${NC}      - Bug修复"
        echo -e "  ${GREEN}docs${NC}     - 文档更新"
        echo -e "  ${GREEN}style${NC}    - 代码格式"
        echo -e "  ${GREEN}refactor${NC} - 代码重构"
        echo -e "  ${GREEN}perf${NC}     - 性能优化"
        echo -e "  ${GREEN}test${NC}     - 测试相关"
        echo -e "  ${GREEN}build${NC}    - 构建相关"
        echo -e "  ${GREEN}ci${NC}       - CI/CD相关"
        echo -e "  ${GREEN}chore${NC}    - 其他杂项"
        echo -e "  ${GREEN}revert${NC}   - 撤销提交"
        echo ""
        echo -e "${BLUE}常用范围:${NC}"
        echo -e "  ${GREEN}core${NC}       - 核心系统"
        echo -e "  ${GREEN}cli${NC}        - 命令行接口"
        echo -e "  ${GREEN}validators${NC} - 验证器"
        echo -e "  ${GREEN}templates${NC}  - 模板系统"
        echo -e "  ${GREEN}config${NC}     - 配置管理"
        echo -e "  ${GREEN}test${NC}       - 测试相关"
        echo -e "  ${GREEN}docs${NC}       - 文档相关"
        return 1
    fi
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        echo -e "${YELLOW}用法: $0 <commit-message>${NC}"
        echo -e "${YELLOW}或者: echo 'commit message' | $0${NC}"
        exit 1
    fi
    
    # 从参数或标准输入读取提交信息
    if [ "$1" = "-" ]; then
        commit_msg=$(cat)
    else
        commit_msg="$*"
    fi
    
    # 提取第一行（标题行）
    title_line=$(echo "$commit_msg" | head -n1)
    
    check_commit_message "$title_line"
}

# 如果作为commit-msg hook运行
if [ "$(basename "$0")" = "commit-msg" ]; then
    commit_msg=$(cat "$1")
    title_line=$(echo "$commit_msg" | head -n1)
    check_commit_message "$title_line"
    exit $?
fi

# 正常运行
main "$@"
