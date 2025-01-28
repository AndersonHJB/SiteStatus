#!/bin/bash

# 定义本地保存日志的选项
commit=false

# 配置文件路径
urlsConfig="./urls.cfg"
echo "Reading $urlsConfig"

# 读取配置文件并解析URLs和Keys
KEYSARRAY=()
URLSARRAY=()

while read -r line; do
  echo "  $line"
  IFS='=' read -ra TOKENS <<< "$line"
  KEYSARRAY+=(${TOKENS[0]})
  URLSARRAY+=(${TOKENS[1]})
done < "$urlsConfig"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

# 确保日志文件夹存在
mkdir -p logs

# 循环进行健康检查
for (( index=0; index < ${#KEYSARRAY[@]}; index++ )); do
  key="${KEYSARRAY[index]}"
  url="${URLSARRAY[index]}"
  echo "  $key=$url"

  for i in 1 2 3 4; do
    response=$(curl --write-out '%{http_code}' --silent --output /dev/null $url)
    if [ "$response" -eq 200 ] || [ "$response" -eq 202 ] || [ "$response" -eq 301 ] || [ "$response" -eq 302 ] || [ "$response" -eq 307 ]; then
      result="success"
    else
      result="failed"
    fi
    if [ "$result" = "success" ]; then
      break
    fi
    sleep 5
  done

  # 获取当前时间
  dateTime=$(date +'%Y-%m-%d %H:%M')
  
  # 保存日志到本地
  echo "$dateTime, $result" >> "logs/${key}_report.log"
  
  # 保留最后2000条日志
  echo "$(tail -2000 logs/${key}_report.log)" > "logs/${key}_report.log"
done

echo "Health checks completed. Logs saved in 'logs' folder."
