#!/bin/bash
Green_font="\033[32m" && Yellow_font="\033[33m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
echo -e "
${Green_font}
#================================================
# Project: tcp_nanqinlang-lkl
# Description: bbr enhancement -openvz -centos
# Version: 1.1.1
# Author: nanqinlang
# Blog:   https://sometimesnaive.org
# Github: https://github.com/nanqinlang
#================================================
${Font_suffix}"

check_system(){
	[[ -z "`cat /etc/redhat-release | grep -iE "CentOS"`" ]] && echo -e "${Error} only support CentOS !" && exit 1
	[[ "`uname -m`" != "x86_64" ]] && echo -e "${Error} only support 64 bit !" && exit 1
}

check_root(){
	[[ "`id -u`" != "0" ]] && echo -e "${Error} must be root user !" && exit 1
}

check_ovz(){
	yum update && yum install -y virt-what
	[[ "`virt-what`" != "openvz" ]] && echo -e "${Error} only support OpenVZ !" && exit 1
}

check_ldd(){
    #ldd=`ldd --version | grep ldd | awk '{print $NF}'`
	[[ "`ldd --version | grep ldd | awk '{print $NF}'`" < "2.14" ]] && echo -e "${Error} ldd version < 2.14, not support !" && exit 1
}

check_tuntap(){
	echo -e "\n"

	cat /dev/net/tun

	echo -e "${Info} 请确认上一行的返回值是否为 'File descriptor in bad state' ？"
	echo -e "1.是\n2.否"
	read -p "输入数字以选择:" tuntap

	while [[ ! "${tuntap}" =~ ^[1-2]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" tuntap
	done

	[[ -z "${tuntap}" || "${tuntap}" == "2" ]] && echo -e "${Error} 未开启 tun/tap，请开启后再尝试该脚本 !" && exit 1

	#以下为失败，grep 无效
	#echo -n "`cat /dev/net/tun`" | grep "device"
	#[[ -z "${enable}" ]] && echo -e "${Error} not enable tun/tap !" && exit 1
}

directory(){
	[[ ! -d /home/tcp_nanqinlang ]] && mkdir -p /home/tcp_nanqinlang
	cd /home/tcp_nanqinlang
}

config(){
	# choose one or many port
	echo -e "${Info} 你想加速单个端口（例如 443）还是端口段(例如 8080-9090) ？\n1.单个端口\n2.端口段"
	read -p "(输入数字以选择):" choose
	while [[ ! "${choose}" =~ ^[1-2]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" choose
	done

	# download unfully-config-redirect
	[[ ! -f redirect.sh ]] && wget https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/LKL/requirement/redirect.sh

	# config: haproxy && redirect
	if [[ "${choose}" == "1" ]]; then
		 echo -e "${Info} 输入你想加速的端口"
		 read -p "(输入单个端口号，例如：443，默认使用 443):" port1
		 [[ -z "${port1}" ]] && port1=443
		 config-haproxy-1
		 config-redirect-1
	else
		 echo -e "${Info} 输入端口段的第一个端口号"
		 read -p "(例如端口段为 8080-9090，则此处输入 8080，默认使用 8080):" port1
		 [[ -z "${port1}" ]] && port1=8080
		 echo -e "${Info} 输入端口段的第二个端口号"
		 read -p "(例如端口段为 8080-9090，则此处输入 9090，默认使用 9090):" port2
		 [[ -z "${port2}" ]] && port2=9090
		 config-haproxy-2
		 config-redirect-2
	fi
}

config-haproxy-1(){
echo -e "global

defaults
log global
mode tcp
option dontlognull
timeout connect 5000
timeout client 10000
timeout server 10000

frontend proxy-in
bind *:${port1}
default_backend proxy-out

backend proxy-out
server server1 10.0.0.1 maxconn 20480\c" > haproxy.cfg
}

config-haproxy-2(){
echo -e "global

defaults
log global
mode tcp
option dontlognull
timeout connect 5000
timeout client 10000
timeout server 10000

frontend proxy-in
bind *:${port1}-${port2}
default_backend proxy-out

backend proxy-out
server server1 10.0.0.1 maxconn 20480\c" > haproxy.cfg
}

config-redirect-1(){
echo "iptables -t nat -A PREROUTING -i venet0 -p tcp --dport ${port1} -j DNAT --to-destination 10.0.0.2" >> redirect.sh
}

config-redirect-2(){
echo "iptables -t nat -A PREROUTING -i venet0 -p tcp --dport ${port1}:${port2} -j DNAT --to-destination 10.0.0.2" >> redirect.sh
}

check-all(){
	# check config
	[[ ! -f haproxy.cfg ]] && echo -e "${Error} not found haproxy config, please check !" && exit 1
	[[ ! -f redirect.sh ]] && echo -e "${Error} not found redirect config, please check !" && exit 1

	# check lkl-mod
	[[ ! -f tcp_nanqinlang.so ]] && wget https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/LKL/mod/tcp_nanqinlang.so
	[[ ! -f tcp_nanqinlang.so ]] && echo -e "${Error} download lkl.mod failed, please check !" && exit 1

	# check lkl-load
	[[ ! -f load.sh ]] && wget https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/LKL/requirement/load.sh
	[[ ! -f load.sh ]] && echo -e "${Error} download load.sh failed, please check !" && exit 1

	# check haproxy
	yum install -y iptables bc haproxy

	# check selfstart
	[[ ! -f start.sh ]] && wget https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/LKL/requirement/start.sh
	[[ ! -f start.sh ]] && echo -e "${Error} download start config failed, please check !" && exit 1

	# give privilege
	chmod -R 4777 /home/tcp_nanqinlang
}

# start immediately
run-it-now(){
	./start.sh
}

# start with reboot
self-start(){
	sed -i "s/exit 0/ /ig" /etc/rc.d/rc.local
	echo -e "\nbash /home/tcp_nanqinlang/start.sh" >> /etc/rc.d/rc.local
	chmod +x /etc/rc.d/rc.local
}


install(){
	check_system
	check_root
	check_ovz
	check_ldd
	check_tuntap
	directory
	config
	check-all
	run-it-now
	self-start
	#status
	echo -e "${Info} 已完成，请稍后使用此脚本第二项判断 lkl 是否成功。"
}

status(){
	pingstatus=`ping 10.0.0.2 -c 3 | grep ttl`
	if [[ ! -z "${pingstatus}" ]]; then
		echo -e "${Info} tcp_nanqinlang is running !"
		else echo -e "${Error} tcp_nanqinlang not running, please check !"
	fi
}

uninstall(){
	check_system
	check_root
	yum remove -y haproxy
	rm -rf /home/tcp_nanqinlang
	#iptables -F
	sed -i '/bash \/home\/tcp_nanqinlang\/start.sh/d' /etc/rc.d/rc.local
	echo -e "${Info} please remember 重启 to stop tcp_nanqinlang"
}




echo -e "${Info} 选择你要使用的功能: "
echo -e "1.安装 lkl 魔改\n2.检查 lkl 魔改运行状态\n3.卸载 lkl 魔改"
read -p "输入数字以选择:" function

while [[ ! "${function}" =~ ^[1-3]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" function
	done

if [[ "${function}" == "1" ]]; then
	install
elif [[ "${function}" == "2" ]]; then
	status
else
	uninstall
fi
