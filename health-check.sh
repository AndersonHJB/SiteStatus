#!/bin/bash
# In the original repository we'll just print the result of status checks,
# without committing. This avoids generating several commits that would make
# later upstream merges messy for anyone who forked us.
commit=true
origin=$(git remote get-url origin)
if [[ $origin == *AndersonHJB/statuspage* ]]
then
  commit=false
fi

KEYSARRAY=()
URLSARRAY=()

urlsConfig="./urls.cfg"
echo "Reading $urlsConfig"
while IFS= read -r line || [[ -n "$line" ]]; do
  echo "  $line"
  # 通过正则表达式捕获键和值，确保处理空格和特殊字符
  if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
    key="${BASH_REMATCH[1]}"
    url="${BASH_REMATCH[2]}"
    KEYSARRAY+=("$key")
    URLSARRAY+=("$url")
  fi
done < "$urlsConfig"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

mkdir -p logs

for (( index=0; index < ${#KEYSARRAY[@]}; index++ )); do
  key="${KEYSARRAY[index]}"
  url="${URLSARRAY[index]}"
  echo "  $key=$url"

  # 防止 URL 为空导致 curl 报错
  if [[ -z "$url" ]]; then
    echo "    Skipping: URL is empty for key '$key'"
    continue
  fi

  for i in 1 2 3 4; do
    response=$(curl --write-out '%{http_code}' --silent --output /dev/null "$url")
    if [[ "$response" -eq 200 || "$response" -eq 202 || "$response" -eq 301 || "$response" -eq 302 || "$response" -eq 307 ]]; then
      result="success"
    else
      result="failed"
    fi
    if [[ "$result" == "success" ]]; then
      break
    fi
    sleep 5
  done
  dateTime=$(date +'%Y-%m-%d %H:%M')
  if [[ $commit == true ]]; then
    # 日志文件名中使用安全的键名
    safe_key=$(echo "$key" | tr ' ' '_' | tr -d '[:punct:]')
    echo "$dateTime, $result" >> "logs/${safe_key}_report.log"
    echo "$(tail -2000 logs/${safe_key}_report.log)" > "logs/${safe_key}_report.log"
  else
    echo "    $dateTime, $result"
  fi
done

if [[ $commit == true ]]
then
  # Let's make AndersonHJB the most productive person on GitHub.
  git config --global user.name 'AndersonHJB'
  git config --global user.email 'bornforthis@bornforthis.cn'
  git add -A --force logs/
  git commit -am '[Automated] Update Health Check Logs'
  git push
fi