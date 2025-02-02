#!/bin/sh
# Author: AndersonHJB and Bornforthis
# 该脚本使用 awk 处理 data.yml 文件，匹配非注释行的 “- name:” 和 “link:” 字段，并在提取 name 后调用 gsub 去掉其中的所有空白字符。
awk '
  /^[[:space:]]*#/ { next }   # 跳过注释行
  /^[[:space:]]*-[[:space:]]*name:/ {
      # 提取 name 字段，去除前缀及多余空白
      sub(/^[[:space:]]*-?[[:space:]]*name:[[:space:]]*/, "");
      name = $0;
      # 去掉 name 中的所有空白字符（包括空格）
      gsub(/[[:space:]]/, "", name);
      next;
  }
  /^[[:space:]]*link:/ {
      # 提取 link 字段
      sub(/^[[:space:]]*link:[[:space:]]*/, "");
      link = $0;
      # 输出 "name=link"
      print name"="link;
  }
' data.yml > ../urls.cfg