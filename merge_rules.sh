#!/bin/bash
# 定义分类数组（对应规则源文件名和输出文件名）
categories=("normal" "other" "region" "security")
# 创建输出目录（存放最终分类规则）和临时目录
mkdir -p output temp custom
# 循环处理每个分类
for cate in "${categories[@]}"; do
  # 清空当前分类临时文件和输出文件
  > temp/${cate}_temp.txt
  > output/${cate}_rules.txt
  # 检查当前分类规则源文件是否存在
  if [ ! -f "rules/${cate}.txt" ]; then
    echo "${cate}类规则源文件不存在，跳过"
    continue
  fi
  # 读取当前分类所有规则源链接，拉取规则
  while IFS= read -r url; do
    # 跳过注释、空行
    if [[ "$url" =~ ^#.*$ || -z "$url" ]]; then
      continue
    fi
    # 处理本地自定义规则
    if [[ "$url" == ../custom/* ]]; then
      if [ -f "$url" ]; then
        cat "$url" >> temp/${cate}_temp.txt
        echo -e "\n" >> temp/${cate}_temp.txt
      fi
      continue
    fi
    # 拉取远程规则（超时10秒，失败跳过）
    curl -s --connect-timeout 10 -m 20 "$url" >> temp/${cate}_temp.txt
    echo -e "\n" >> temp/${cate}_temp.txt
  done < "rules/${cate}.txt"
  # 去重+过滤无效内容（保留有效规则，剔除注释/空行/无关标记）
  cat temp/${cate}_temp.txt | \
    grep -vE '^#|^$|^!|^\/|^\[|^@' | \  # 剔除注释、空行、AGH无关标记
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \  # 去首尾空格
    sort -u >> output/${cate}_rules.txt  # 排序去重
  # 输出统计信息
  rule_count=$(wc -l < output/${cate}_rules.txt)
  echo "${cate}类规则合并完成，共${rule_count}条有效规则"
done
# 清理临时目录
rm -rf temp
echo "所有分类规则合并去重完成，输出至output文件夹"