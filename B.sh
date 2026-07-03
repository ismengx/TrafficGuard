#!/bin/bash
INTERFACE="eth0" # "eth0"为你的云服务器网卡名，因人而异
# vnstat 检查月流量是否超过设定流量 这里以190GB为例
vnstat -i $INTERFACE --alert 0 3 month total 190 GB
# 如果返回状态码 1，说明超标，执行
if [ $? -eq 1 ]; then
    # 日志
    echo "$(date):流量超标，正在通过 iptables 锁死流量并保留 22 端口..." >> /home/$USER/vnstat_alert.log
    # 1. 允许本地回环网卡（127.0.0.1）通信，保证系统内部组件不崩溃
    sudo /sbin/iptables -A INPUT -i lo -j ACCEPT
    sudo /sbin/iptables -A OUTPUT -o lo -j ACCEPT
    # 2. 允许22 SSH的出入站流量
    sudo /sbin/iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    sudo /sbin/iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT
    # 3. 允许已经建立的、或者相关的连接继续通信（防止当前切断时你直接被踢出）
    sudo /sbin/iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    sudo /sbin/iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
    # 4. 将默认策略改为 DROP（拒绝所有未被上面规则放行的流量）
    sudo /sbin/iptables -P INPUT DROP
    sudo /sbin/iptables -P OUTPUT DROP
    sudo /sbin/iptables -P FORWARD DROP
fi