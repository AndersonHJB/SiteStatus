# Server Version - health-check-server.sh
#!/usr/bin/env bash

# ========== 配置区域 ==========
# 时区设置 (例如: Asia/Shanghai)
export TZ="Asia/Shanghai"

# 存储配置
MAX_RECORDS=2000          # 每个URL保留的最大记录数
RETRY_ATTEMPTS=4          # 失败重试次数
RETRY_DELAY=5            # 重试间隔(秒)
CURL_TIMEOUT=30          # curl超时时间(秒)

# 成功的HTTP状态码
SUCCESS_CODES=(200 201 202 301 302 307)

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 文件路径配置
urlsConfig="../urls.cfg"
logsDir="../logs"
reportFile="${logsDir}/report.json"

# Check required commands
for cmd in curl jq; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is required but not installed."
        exit 1
    fi
done

# Create arrays for storing URLs and keys
KEYSARRAY=()
URLSARRAY=()

# Ensure logs directory exists
mkdir -p "$logsDir"

# Initialize report.json if it doesn't exist
if [ ! -f "$reportFile" ]; then
    echo "{}" > "$reportFile"
fi

# Ensure urls.cfg ends with newline
if [[ -f "$urlsConfig" && -n $(tail -c1 "$urlsConfig") ]]; then
    echo "" >> "$urlsConfig"
fi

# Read configuration
echo "Reading $urlsConfig"
while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Parse key-value pairs
    if [[ "$line" =~ ^([^=]+)=(.+)$ ]]; then
        key="${BASH_REMATCH[1]}"
        url="${BASH_REMATCH[2]}"
        KEYSARRAY+=("$key")
        URLSARRAY+=("$url")
        echo "Loaded: $key = $url"
    fi
done < "$urlsConfig"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs"

# Check each URL
for (( index=0; index < ${#KEYSARRAY[@]}; index++ )); do
    key="${KEYSARRAY[index]}"
    url="${URLSARRAY[index]}"
    echo "Checking $key = $url"

    # Initialize result as failed
    result="failed"
    
    # Multiple retry attempts
    for (( i=1; i<=RETRY_ATTEMPTS; i++ )); do
        echo "Attempt $i of $RETRY_ATTEMPTS"
        
        if response=$(curl --max-time $CURL_TIMEOUT --write-out '%{http_code}' --silent --output /dev/null "$url"); then
            for code in "${SUCCESS_CODES[@]}"; do
                if [ "$response" -eq "$code" ]; then
                    result="success"
                    break 2
                fi
            done
        fi
        
        [ $i -lt $RETRY_ATTEMPTS ] && sleep $RETRY_DELAY
    done

    dateTime=$(date +'%Y-%m-%d %H:%M')
    
    # Update JSON report
    if ! updatedJson=$(jq --arg k "$key" \
                        --arg dt "$dateTime" \
                        --arg r "$result" \
                        --arg u "$url" \
                        --argjson max "$MAX_RECORDS" '
        .[$k] |= ( . // {"url": $u, "records": []} ) |
        .[$k].url = $u |
        .[$k].records += [{"dateTime": $dt, "result": $r}] |
        .[$k].records |= ( if length > $max then .[-($max):] else . end )
        ' "$reportFile"); then
        echo "Error: JSON update failed for $key"
        continue
    fi
    
    echo "$updatedJson" > "$reportFile"
    echo "  $dateTime: $result"
done

echo "Health check completed successfully"