#!/usr/bin/env bash

# Exit on error
set -e

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Configuration
urlsConfig="${SCRIPT_DIR}/urls.cfg"
logsDir="${SCRIPT_DIR}/logs"
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
    
    # Try up to 4 times
    for attempt in {1..4}; do
        echo "Attempt $attempt of 4"
        
        # Use timeout to prevent hanging
        if response=$(curl --max-time 30 --write-out '%{http_code}' --silent --output /dev/null "$url"); then
            if [[ "$response" =~ ^(200|201|202|301|302|307)$ ]]; then
                result="success"
                break
            fi
        fi
        
        # Wait before retry
        [[ $attempt -lt 4 ]] && sleep 5
    done

    dateTime=$(date -u +'%Y-%m-%d %H:%M UTC')
    
    # Update JSON report
    if ! updatedJson=$(jq --arg k "$key" \
                        --arg dt "$dateTime" \
                        --arg r "$result" \
                        --arg u "$url" '
        .[$k] |= ( . // {"url": $u, "records": []} ) |
        .[$k].url = $u |
        .[$k].records += [{"dateTime": $dt, "result": $r}] |
        .[$k].records |= ( if length > 2000 then .[-2000:] else . end )
        ' "$reportFile"); then
        echo "Error: JSON update failed for $key"
        continue
    fi
    
    echo "$updatedJson" > "$reportFile"
    echo "  $dateTime: $result"
done

echo "Health check completed successfully"