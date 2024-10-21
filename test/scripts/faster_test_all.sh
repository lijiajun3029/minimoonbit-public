#!/bin/bash

# 定义颜色
RED='\033[0;31m'      # 红色
GREEN='\033[0;32m'    # 绿色
RESET='\033[0m'       # 重置颜色

run_tests() {
    local stage=$1
    local directory=$2
    local total_cases=0
    local correct_cases=0

    echo "$directory"
    for file in "$directory"/*; do
        filename=$(basename "$file")
        echo -n "$filename: "
        # 根据阶段决定命令
        if [[ "$stage" == "knf" ]]; then
            moon run ./src/bin/main.mbt -- --knf-interpreter "$file" >test/output/information.txt 2>test/output/error_log.txt
        else
            moon run ./src/bin/main.mbt -- --end-stage "$stage" "$file" >test/output/information.txt 2>test/output/error_log.txt
        fi
        
        if [ $? -eq 0 ]; then
            echo "AC"
            correct_cases=$((correct_cases + 1))
        else
            echo "RE"
            if [[ "$filename" == _neg* ]]; then
                correct_cases=$((correct_cases + 1))
            fi
        fi
        total_cases=$((total_cases + 1))
    done
    
    # Calculate accuracy
    if [ $total_cases -ne 0 ]; then
        accuracy=$(echo "scale=2; ($correct_cases / $total_cases) * 15" | bc)
    else
        accuracy=0
    fi
    echo -e "Score for stage '$stage': ${GREEN}$accuracy${RESET}"  # 使用绿色显示准确率
}

# 定义需要测试的阶段和路径
declare -A test_cases=(
    ["parse"]="test/test_cases/parsing"
    ["typecheck"]="test/test_cases/typing"
    ["knf"]="test/test_cases/knf"
)

stages=("parse" "typecheck" "knf")
# 使用for循环遍历阶段和对应的路径
for stage in "${stages[@]}"; do
    echo "$stage"
    path=${test_cases[$stage]}  # 获取路径
    run_tests "$stage" "$path"
    echo
done
