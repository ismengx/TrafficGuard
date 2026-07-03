# 流量超额阻断器 | TrafficGuard
<p align="center">
  <a href="#-english-version">English</a> •
  <a href="#-中文版本">中文</a>
</p>


[![Bilibili](https://zshuai.cc.cd/c19031ffb6bbb1675b8523f8f3e39eb9.png)](https://www.bilibili.com/video/BV12gTb6CEBD/)


## 中文版
本项目基于原版<a href="https://github.com/vergoh/vnstat">vnstat (2.9-1)</a>alert机制而开发，通过sh脚本与定时任务以监控云服务器的流量以免产生不必要的资费，感谢原作者的开源贡献！  
这是我第一次写project，大概算是个人自用及系统实践  : )  
⚠️ 注意：本项目不具备实时流量控制能力，存在短时间超额风险。  
附上个人汉化的[vnstat用户手册](https://github.com/ismengx/TrafficLimiter/blob/main/CN%20Translated%20manual.md)，也有Gemini的功劳。  


### 一、部署
0. **安装`vnstat`**  
```
sudo apt install vnstat
```
1. **修改配置文件**  
通过apt安装的vnstat配置文件位于`/etc/vnstat.conf`  
利用nano命令对此文件进行修改，记得删除开头的`;`
```bash
# 1. 设置默认监控网卡（改为你通过 ip link命令查到的真实网卡名，如 eth0）
Interface "eth0"

# 2. 修改单位进制为SI，按 1000 进制计算，留余地）
UnitMode 2

# 3. 守护进程刷新内存缓存的频率（单位：秒）
UpdateInterval 10

# 4. 内存数据强行刷入硬盘数据库的频率（单位：分钟）。
# 默认是 5 分钟。为了保护硬盘/闪存，vnstat 默认不会每秒都写硬盘。
# 调整 UpdateInterval 后，建议将此项也适当调小，例如改为 1 分钟。
SaveInterval 1
# 4. 【可选】修改月流量结算起始日
MonthRotate 1
```
  保存并退出，重启服务使配置生效
```shell
sudo systemctl restart vnstat
```
2. **创建断网时执行的脚本**  
  选择一个目录（如/etc）下创建脚本文件，本教程中以`1.sh`为例  
  也可以直接下载仓库中`A.sh`或`B.sh`
```shell
sudo nano /etc/1.sh
```
3. **编写脚本内容**  

**A情况：禁用对应网卡实现断网（适用于服务器在你手边时）**  
其中eth0是你通过`ip link`命令或`ifconfig`命令获取的目标网卡名  
直接用`A.sh`  

**B情况：通过`iptables`封锁所有流量，并保留22号SSH端口  
（适用于云服务器纯白嫖需求）**  
直接用`B.sh`  

**C情况：个人自定义脚本**

4. **赋予脚本可执行权限**
```
sudo chmod +x /etc/1.sh
```
5. **配置 vnstat 用户免密 sudo 权限**  
```
sudo visudo
```
在最后一行添加以下内容。  
（注：如果你下载的是仓库脚本，请将 1.sh 替换为 A.sh 或 B.sh）
```shell
%sudo ALL=(ALL) NOPASSWD: /etc/1.sh
```
6. **设置自动执行**  
打开当前用户的自动任务编辑器
```shell
crontab -e
```
在最后一行添加如下内容：
```shell
# 每一分钟执行一次1.sh脚本
* * * * * sudo /etc/1.sh
```

### 二、检验  
为防止因设置无效而导致流量超额，建议先设置小额限制并进行超额测试  
在终端中按照顺序运行即可 
```shell
# 1. 临时声明你的网卡变量
INTERFACE="eth0"
# 2. 尝试运行单次检测（假设你的月流量已超过 1 KB）
vnstat -i $INTERFACE --alert 0 3 month total 1 KB
# 3. 如果上一条命令因为超额返回了错误码，则会触发以下打印和日志
if [ $? -eq 1 ]; then
    echo "$(date): 流量已超额" >> /home/$USER/alert.log
    echo "测试成功！日志已自动写入当前用户目录：/home/$USER/alert.log"
fi
```
以本代码为例，在执行常规耗流任务如`sudo apt update`后，检查`/home/[你的用户名]/alert.log`中是否出现提示

### 三、恢复  
`A方案` 由于禁用了本地网卡防止联网，一般都需要在本地用shell命令自行恢复  
`[interface]`替换为你的网卡名
```
sudo ip link set [interface] up
```
或
```
sudo ifconfig [interface] up
```
`B方案`断网后由于还剩22端口供ssh连接，在重置流量额度后通过远程ssh运行如下命令，以**清空防火墙规则**
```bash
iptables -N TRAFFIC_LIMIT
iptables -A OUTPUT -j TRAFFIC_LIMIT
```
清空`vnstat`的数据库
```
sudo systemctl stop vnstat
sudo vnstat --remove -i eth0
sudo systemctl start vnstat
```

<p align="right">(<a href="#top">回到顶部</a>)</p>

---

##  English Version
To be continued...



<p align="right">(<a href="#top">back to top</a>)</p>

---
