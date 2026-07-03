# 1. 恢复防火墙默认策略（允许所有流量）
sudo iptables -P INPUT ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -P FORWARD ACCEPT

# 2. 清空所有断网限制规则
sudo iptables -F

# 3. 停止服务并清空 vnstat 对应网卡的数据库，重置流量统计
sudo systemctl stop vnstat
sudo vnstat --remove -i eth0
sudo apt purge vnstat
rm -rf /etc/[XXX].sh