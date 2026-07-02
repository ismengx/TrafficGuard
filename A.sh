#!/bin/bash
INTERFACE="eth0"
# vnstat 检查月流量是否超过 190 GB
vnstat -i $INTERFACE --alert 0 3 month total 190 GB
# 如果返回状态码 1，说明超标，执行断网
if [ $? -eq 1 ]; then
    # 记录日志
    echo "$(date): [方案A] 流量超标，正在禁用网卡 $INTERFACE..." >> /home/yushuai/vnstat_alert.log
    # 禁用网卡
    sudo /sbin/ip link set dev $INTERFACE down
fi
