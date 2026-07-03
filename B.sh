#!/bin/bash
INTERFACE="eth0" # "eth0"为你的云服务器网卡名，因人而异
LIMIT="190 GB"   # 限制流量额度

# 1. 检查是否已经处于锁死状态，防止 crontab 每分钟重复追加规则
if sudo /sbin/iptables -L INPUT -n | head -n 1 | grep -q "policy DROP"; then
    exit 0
fi

# 2. vnstat 检查月流量是否超过设定流量
vnstat -i $INTERFACE --alert 0 3 month total $LIMIT

# 如果返回状态码 1，说明超标，执行锁死
if [ $? -eq 1 ]; then
    # 写入日志
    echo "$(date): 流量已超标 ($LIMIT)，正在直接锁死所有连接并仅保留 22 端口..." >> /home/$USER/vnstat_alert.log
    
    # 清空可能存在的旧规则
    sudo /sbin/iptables -F
    
    # 1. 允许本地回环网卡（127.0.0.1）通信，保证系统内部组件不崩溃
    sudo /sbin/iptables -A INPUT -i lo -j ACCEPT
    sudo /sbin/iptables -A OUTPUT -o lo -j ACCEPT
    
    # 2. 允许 22 SSH 的出入站流量（确保你能连得上服务器）
    sudo /sbin/iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    sudo /sbin/iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT
    
    # 3. 直接将默认策略改为 DROP（切断所有未被上面放行的其他连接）
    sudo /sbin/iptables -P INPUT DROP
    sudo /sbin/iptables -P OUTPUT DROP
    sudo /sbin/iptables -P FORWARD DROP
fi