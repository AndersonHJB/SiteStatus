#!/usr/bin/env bash
# In the original repository we'll just print the result of status checks,
# without committing. This avoids generating several commits that would make
# later upstream merges messy for anyone who forked us.
# 是否需要自动提交日志
commit=true
# origin=$(git remote get-url origin)
# if [[ $origin == *AndersonHJB/site_status* ]]
# then
#   commit=false
# fi

KEYSARRAY=()
URLSARRAY=()

urlsConfig="./urls.cfg"
echo "Reading $urlsConfig"
while read -r line
do
  # 跳过空行或无效行
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  echo "  $line"
  IFS='=' read -ra TOKENS <<< "$line"
  KEYSARRAY+=("${TOKENS[0]}")
  URLSARRAY+=("${TOKENS[1]}")
done < "$urlsConfig"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

mkdir -p logs

# 如果 report.json 不存在，则初始化一个空的 JSON 对象
if [ ! -f "logs/report.json" ]; then
  echo "{}" > "logs/report.json"
fi

for (( index=0; index < ${#KEYSARRAY[@]}; index++ ))
do
  key="${KEYSARRAY[index]}"
  url="${URLSARRAY[index]}"
  echo "  $key=$url"

  # 尝试多次请求，直到成功或次数用完
  for i in 1 2 3 4; do
    response=$(curl --write-out '%{http_code}' --silent --output /dev/null "$url")
    if [ "$response" -eq 200 ] || [ "$response" -eq 202 ] || [ "$response" -eq 301 ] || [ "$response" -eq 302 ] || [ "$response" -eq 307 ]; then
    # if [[ "$response" =~ ^(200|202|301|302|307)$ ]]; then
      result="success"
    else
      result="failed"
    fi
    if [ "$result" = "success" ]; then
      break
    fi
    sleep 5
  done

  dateTime=$(date +'%Y-%m-%d %H:%M')
  if [[ $commit == true ]]
  then
    # 利用 jq 往 report.json 里插入数据
    # 1. 将当前 JSON 读取到内存
    # 2. 往对应 key 的数组中添加 {dateTime, result}
    # 3. 只保留数组的最后 2000 条记录
    updatedJson=$(jq --arg k "$key" --arg u "$url" --arg dt "$dateTime" --arg r "$result" '
      # 如果不存在该 key，就先初始化为空数组
      .[$k] |= ( . // {"url": $u, "checks": []} ) |
      # 将新的记录加入
      .[$k].checks += [{"dateTime": $dt, "result": $r}] |
      # 只保留最后 2000 条
      .[$k].checks |= ( if length > 2000 then .[-2000:] else . end )
    ' logs/report.json)

    # 写回文件
    echo "$updatedJson" > logs/report.json
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