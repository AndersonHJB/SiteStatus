#!/usr/bin/env bash
# In the original repository we'll just print the result of status checks,
# without committing. This avoids generating several commits that would make
# later upstream merges messy for anyone who forked us.
# 是否需要自动提交日志
commit=true
# origin=$(git remote get-url origin)
# if [[ $origin == *AndersonHJB/statuspage* ]]
# then
#   commit=false
# fi

# 存放配置文件中的键和值
KEYSARRAY=()
URLSARRAY=()

urlsConfig="./urls.cfg"
echo "Reading $urlsConfig"

# 逐行读取 urls.cfg
while IFS= read -r line; do
  # 去掉 Windows 回车符，防止行末有 ^M
  line=$(echo "$line" | tr -d '\r')

  # 跳过空行
  [[ -z "$line" ]] && continue

  # 如果该行没有 '=', 也跳过或者给个警告
  if [[ "$line" != *=* ]]; then
    echo "Warning: invalid line (no '='): $line"
    continue
  fi

  # 打印当前读取的行
  echo "  $line"

  # 以 '=' 为分隔符，把左边当作key，右边当作url
  IFS='=' read -r key url <<< "$line"

  # 用双引号，保证含有空格的key/url也能保留完整字符串
  KEYSARRAY+=("$key")
  URLSARRAY+=("$url")
done < "$urlsConfig"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

mkdir -p logs

# 遍历每个键值对，执行健康检查
for (( index=0; index < ${#KEYSARRAY[@]}; index++ ))
do
  key="${KEYSARRAY[index]}"
  url="${URLSARRAY[index]}"

  # 打印当前要检查的站点
  echo "  $key=$url"

  # 尝试最多 4 次
  for i in 1 2 3 4; do
    # -s 静默，--write-out '%{http_code}' 只打印状态码，--output /dev/null 不输出body
    response=$(curl --write-out '%{http_code}' --silent --output /dev/null "$url")

    if [[ "$response" -eq 200 ]] || [[ "$response" -eq 202 ]] || \
       [[ "$response" -eq 301 ]] || [[ "$response" -eq 302 ]] || [[ "$response" -eq 307 ]]; then
      result="success"
    else
      result="failed"
    fi

    # 如果成功，就不再重复检查
    if [[ "$result" == "success" ]]; then
      break
    fi

    sleep 5
  done

  dateTime=$(date +'%Y-%m-%d %H:%M')

  # 如果 commit = true，就将结果写入日志并提交
  if [[ $commit == true ]]; then
    echo "$dateTime, $result" >> "logs/${key}_report.log"
    # 保留最近 2000 行日志
    echo "$(tail -2000 "logs/${key}_report.log")" > "logs/${key}_report.log"
  else
    echo "    $dateTime, $result"
  fi
done

# 如需自动提交到 Git
if [[ $commit == true ]]; then
  # 设置Git提交信息
  git config --global user.name 'AndersonHJB'
  git config --global user.email 'bornforthis@bornforthis.cn'
  git add -A --force logs/
  git commit -am '[Automated] Update Health Check Logs'
  git push
fi