#!/usr/bin/env bash

# Configuration
LOG_DIR="logs"  # 修改为你的日志目录
CONFIG_FILE="urls.cfg"  # 修改为你的配置文件路径
MAX_LOG_ENTRIES=2000  # 每个日志文件保留的最大记录数

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 读取配置文件
KEYSARRAY=()
URLSARRAY=()

echo "Reading $CONFIG_FILE"
while read -r line
do
    # 跳过空行和注释行
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    echo "  $line"
    IFS='=' read -ra TOKENS <<< "$line"
    KEYSARRAY+=(${TOKENS[0]})
    URLSARRAY+=(${TOKENS[1]})
done < "$CONFIG_FILE"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

# 执行健康检查
for (( index=0; index < ${#KEYSARRAY[@]}; index++))
do
    key="${KEYSARRAY[index]}"
    url="${URLSARRAY[index]}"
    echo "Checking $key=$url"
    
    # 尝试4次
    for i in 1 2 3 4; 
    do
        response=$(curl --write-out '%{http_code}' --silent --output /dev/null "$url")
        if [ "$response" -eq 200 ] || [ "$response" -eq 202 ] || [ "$response" -eq 301 ] || [ "$response" -eq 302 ] || [ "$response" -eq 307 ]; then
            result="success"
            break
        else
            result="failed"
        fi
        # 如果失败则等待5秒后重试
        [ "$i" -lt 4 ] && sleep 5
    done
    
    # 记录结果
    dateTime=$(date +'%Y-%m-%d %H:%M')
    log_file="$LOG_DIR/${key}_report.log"
    
    # 写入新记录并保持日志文件在指定大小范围内
    echo "$dateTime, $result" >> "$log_file"
    if [ -f "$log_file" ]; then
        echo "$(tail -n $MAX_LOG_ENTRIES "$log_file")" > "$log_file"
    fi
    
    # 输出到控制台
    echo "  $dateTime - $key - $result"
done

# 记录脚本执行完成
echo "$dateTime - Health check completed" >> "$LOG_DIR/health_check.log"