#!/usr/bin/env python3
# Author: AndersonHJB and Bornforthis
# 利用 Python 的 PyYAML 模块解析 YAML 数据，并在遍历 link_list 时，对每个 entry 的 name 字段使用正则表达式去除所有空白字符。
import yaml

# 打开并加载 YAML 数据（文件名假设为 data.yml）
with open("data.yml", "r", encoding="utf-8") as f:
    data = yaml.safe_load(f)

# 打开输出文件 urls.cfg，写入提取结果
with open("../urls.cfg", "w", encoding="utf-8") as out:
    # data 是一个列表，每个元素对应一个分类块
    for section in data:
        # 如果存在 link_list 字段则遍历其列表项
        if "link_list" in section:
            for entry in section["link_list"]:
                # 确保 entry 为字典且同时包含 name 和 link 字段
                if isinstance(entry, dict) and "name" in entry and "link" in entry:
                    out.write(f"{entry['name']}={entry['link']}\n")
