#!/bin/sh
# 假设待处理数据存放在 data.yml 中
# 本脚本通过匹配非注释的 “- name:” 和 “link:” 行，提取 name 和 link

awk '
  /^[[:space:]]*#/ { next }   # 跳过以 # 开头的注释行
  /^[[:space:]]*-[[:space:]]*name:/ {
      # 提取 name 字段，去掉前面的“- name:”及空白
      sub(/^[[:space:]]*-?[[:space:]]*name:[[:space:]]*/, "");
      name = $0;
      next;
  }
  /^[[:space:]]*link:/ {
      # 提取 link 字段
      sub(/^[[:space:]]*link:[[:space:]]*/, "");
      link = $0;
      # 输出“name=link”
      print name"="link;
  }
' data.yml > urls2.cfg
