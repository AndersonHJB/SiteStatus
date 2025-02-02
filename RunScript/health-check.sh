#!/usr/bin/env bash
# GitHub Action Version - health-check-github.sh

# ========== 配置区域 ==========
# 时区设置 (例如: Asia/Shanghai)
export TZ="Asia/Shanghai"

# 存储配置
MAX_RECORDS=2000          # 每个URL保留的最大记录数
RETRY_ATTEMPTS=4          # 失败重试次数
RETRY_DELAY=5            # 重试间隔(秒)
CURL_TIMEOUT=30          # curl超时时间(秒)

# Git配置
GIT_USER_NAME='AndersonHJB'
GIT_USER_EMAIL='bornforthis@bornforthis.cn'

# 成功的HTTP状态码
SUCCESS_CODES=(200 201 202 301 302 307)
# In the original repository we'll just print the result of status checks,
# without committing. This avoids generating several commits that would make
# later upstream merges messy for anyone who forked us.
# 是否需要自动提交日志
commit=true
origin=$(git remote get-url origin)
if [[ $origin == *AndersonHJB/SiteStatus* ]]
then
  commit=false
fi

KEYSARRAY=()
URLSARRAY=()

urlsConfig="./urls.cfg"

# 确保 urls.cfg 末尾有换行符
if [[ -f "$urlsConfig" && -n $(tail -c1 "$urlsConfig") ]]; then
  echo "" >> "$urlsConfig"
fi

echo "Reading $urlsConfig"
while read -r line
do
  # 跳过空行或注释行
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  echo "Reading: $line" # 调试输出
  IFS='=' read -ra TOKENS <<< "$line"
  KEYSARRAY+=("${TOKENS[0]}")
  URLSARRAY+=("${TOKENS[1]}")
done < "$urlsConfig"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

mkdir -p logs

# 初始化 report.json
if [ ! -f "logs/report.json" ]; then
  echo "{}" > "logs/report.json"
fi

for (( index=0; index < ${#KEYSARRAY[@]}; index++ ))
do
  key="${KEYSARRAY[index]}"
  url="${URLSARRAY[index]}"
  echo "  $key=$url"

  # 多次重试
  for (( i=1; i<=RETRY_ATTEMPTS; i++ )); do
    echo "Attempt $i of $RETRY_ATTEMPTS"
    response=$(curl --max-time $CURL_TIMEOUT --write-out '%{http_code}' --silent --output /dev/null "$url")
    result="failed"
    for code in "${SUCCESS_CODES[@]}"; do
      if [ "$response" -eq "$code" ]; then
        result="success"
        break 2
      fi
    done
    if [ $i -lt $RETRY_ATTEMPTS ]; then
      sleep $RETRY_DELAY
    fi
  done

  dateTime=$(date +'%Y-%m-%d %H:%M')
  if [[ $commit == true ]]
  then
    updatedJson=$(jq --arg k "$key" \
                    --arg dt "$dateTime" \
                    --arg r "$result" \
                    --arg u "$url" \
                    --argjson max "$MAX_RECORDS" '
      .[$k] |= ( . // {"url": $u, "records": []} ) |
      .[$k].url = $u |
      .[$k].records += [{"dateTime": $dt, "result": $r}] |
      .[$k].records |= ( if length > $max then .[-($max):] else . end )
    ' logs/report.json)

    echo "$updatedJson" > logs/report.json
  else
    echo "    $dateTime, $result"
  fi
done

if [[ $commit == true ]]
then
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  git add -A --force logs/
  git commit -am '[Automated] Update Health Check Logs'
  git push
fi