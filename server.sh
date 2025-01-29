#!/usr/bin/env bash

# 1. 配置区
LOG_DIR="logs"           # 日志目录
CONFIG_FILE="urls.cfg"   # 配置文件
MAX_LOG_ENTRIES=2000     # 每个站点在 JSON 中最多保留多少条记录

# 2. 确保日志目录存在
mkdir -p "$LOG_DIR"

# 如果 report.json 不存在，就创建一个空的 JSON 对象“{}”
REPORT_FILE="$LOG_DIR/report.json"
if [ ! -f "$REPORT_FILE" ]; then
  echo "{}" > "$REPORT_FILE"
fi

# 3. 读取配置文件
KEYSARRAY=()
URLSARRAY=()

echo "Reading $CONFIG_FILE"
while read -r line
do
    # 跳过空行和注释行
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    echo "  $line"
    IFS='=' read -ra TOKENS <<< "$line"
    KEYSARRAY+=("${TOKENS[0]}")
    URLSARRAY+=("${TOKENS[1]}")
done < "$CONFIG_FILE"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

# 4. 执行健康检查并写入 JSON
for (( index=0; index < ${#KEYSARRAY[@]}; index++ ))
do
    key="${KEYSARRAY[index]}"
    url="${URLSARRAY[index]}"
    echo "Checking $key=$url"
    
    # 尝试4次
    result="failed"
    for i in 1 2 3 4; do
        response=$(curl --write-out '%{http_code}' --silent --output /dev/null "$url")
        if [[ "$response" =~ ^(200|202|301|302|307)$ ]]; then
            result="success"
            break
        fi
        # 如果失败则等待5秒后重试
        [ "$i" -lt 4 ] && sleep 5
    done
    
    # 记录结果
    dateTime=$(date +'%Y-%m-%d %H:%M')

    # 用 jq 往同一个 report.json 里追加记录
    #  - 如果 key 对应的数组不存在，则先初始化为空数组 []
    #  - 向数组中追加一条新纪录
    #  - 若数组长度超过 MAX_LOG_ENTRIES，则仅保留后 MAX_LOG_ENTRIES 条
    updatedJson=$(
      jq --arg k "$key" \
         --arg dt "$dateTime" \
         --arg r "$result" \
         --argjson max "$MAX_LOG_ENTRIES" \
         '
          .[$k] |= ( . // [] )            # 若不存在该key, 则初始化
          | .[$k] += [{"dateTime": $dt, "result": $r}]
          | .[$k] |= ( if length > $max then .[-$max:] else . end )
         ' "$REPORT_FILE"
    )
    echo "$updatedJson" > "$REPORT_FILE"
    
    # 输出到控制台
    echo "  $dateTime - $key - $result"
done

# 5. 可选：记录脚本执行完成（如果还需要此记录）
dateTimeEnd=$(date +'%Y-%m-%d %H:%M')
echo "$dateTimeEnd - Health check completed" >> "$LOG_DIR/health_check.log"