#!/bin/bash
Green_font="\033[32m" && Yellow_font="\033[33m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
reboot="${Yellow_font}reboot${Font_suffix}"
echo -e "${Green_font}
#======================================
# Project: tcp_nanqinlang
# Description: tcp bbr enhancement for CentOS 7
# Version: 1.0
# Author: nanqinlang
# Blog:   https://sometimesnaive.org
# Github: https://github.com/nanqinlang
#======================================${Font_suffix}"

check_system(){
	#sort
	[[ -z "`cat /etc/redhat-release | grep -E -i "CentOS"`" ]] && echo -e "${Error} only support CentOS !" && exit 1
	#number
	[[ -z "`cat /etc/redhat-release | grep -E -i " 7."`" ]] && echo -e "${Error} only support CentOS 7 !" && exit 1
	#bit
	[[ "`uname -m`" != "x86_64" ]] && echo -e "${Error} only support CentOS 7 64bit!" && exit 1
}

check_root(){
	[[ "`id -u`" != "0" ]] && echo -e "${Error} must be root user" && exit 1
}

check_ovz(){
	yum update && yum install -y virt-what
	virt=`virt-what`
	[[ "${virt}" = "openvz" ]] && echo -e "${Error} OpenVZ not support!" && exit 1
}

directory(){
	[[ ! -d /home/tcp_nanqinlang ]] && mkdir -p /home/tcp_nanqinlang
	cd /home/tcp_nanqinlang
}

check_kernel(){
	# check 4.13.8 already installed or not
	already_image=`rpm -qa | grep kernel-4.13.8`
	already_devel=`rpm -qa | grep kernel-devel-4.13.8`
	already_headers=`rpm -qa | grep kernel-headers-4.13.8`

	# surplus kernel count
	#surplus_image=`rpm -qa | grep kernel | awk '{print $2}' | grep -v "4.13.8" | wc -l`
	#surplus_devel=`rpm -qa | grep kernel-devel | awk '{print $2}' | grep -v "4.13.8" | wc -l`
	#surplus_headers=`rpm -qa | grep kernel-headers | awk '{print $2}' | grep -v "4.13.8" | wc -l`

	# surplus kernel sort
	surplus_count=`rpm -qa | grep kernel | grep -v "4.13.8" | wc -l`

	if [[ "${surplus_count}" = "0" ]]; then
		 echo -e "${Info} no surplus kernel need to remove"
	else echo -e "${Info} removing surplus kernels" && delete_surplus
	fi

	if [[ -z "${already_image}" ]]; then
		 echo -e "${Info} installing image" && install_image
	else echo -e "${Info} noneed install image"
	fi

	if [[ -z "${already_devel}" ]]; then
		 echo -e "${Info} installing devel" && install_devel
	else echo -e "${Info} noneed install devel"
	fi

	if [[ -z "${already_headers}" ]]; then
		 echo -e "${Info} installing headers" && install_headers
	else echo -e "${Info} noneed install headers"
	fi

	grub2-set-default 0
	grub2-mkconfig -o /boot/grub2/grub.cfg
}

delete_surplus(){
		for((integer = 1; integer <= ${surplus_count}; integer++))
		do
			 surplus_sort=`rpm -qa | grep kernel | grep -v "4.13.8"`
			 yum remove -y ${surplus_sort}
		done
		if [[ "${surplus_count}" = "0" ]]; then
			echo -e "${Info} uninstall all surplus images successfully, continuing"
		fi
}

# http://elrepo.org/linux/kernel/el7/i386/RPMS (32 bit) (empty)
# http://elrepo.org/linux/kernel/el7/x86_64/RPMS (64 bit)
install_image(){
	[[ ! -f kernel-ml-4.13.8-1.el7.elrepo.x86_64.rpm ]] && wget http://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-ml-4.13.8-1.el7.elrepo.x86_64.rpm
	yum  install -y kernel-ml-4.13.8-1.el7.elrepo.x86_64.rpm
}
install_devel(){
	[[ ! -f kernel-ml-devel-4.13.8-1.el7.elrepo.x86_64.rpm ]] && wget http://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-ml-devel-4.13.8-1.el7.elrepo.x86_64.rpm
	yum  install -y kernel-ml-devel-4.13.8-1.el7.elrepo.x86_64.rpm
}
install_headers(){
	[[ ! -f kernel-ml-headers-4.13.8-1.el7.elrepo.x86_64.rpm ]] && wget http://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-ml-headers-4.13.8-1.el7.elrepo.x86_64.rpm
	yum  install -y kernel-ml-headers-4.13.8-1.el7.elrepo.x86_64.rpm
}

rpm_list(){
	rpm -qa | grep kernel
}

install(){
	check_system
	check_root
	check_ovz
	directory
	check_kernel
	rpm_list
	echo -e "${Info} 请确认此行上面的列表显示的内核版本后，重启以应用新内核"
}

maker(){
	[[ ! -e /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && compile
	[[ ! -e /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && echo -e "${Error} load mod failed, please check!" && exit 1
}

compile(){
	mkdir make && cd make

	# choose gentle or violent
	echo -e "${Info} 请选择你想要的魔改方案(默认选择温和模式):\n1.温和模式\n2.暴力模式"
	read -p "(输入数字以选择):" mode
	[[ -z "${mode}" ]] && mode=1
	while [[ ! "${mode}" =~ ^[1-2]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" mode
	done

	[[ "${mode}" = "1" ]] && wget -O tcp_nanqinlang.c https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/CentOS/c/tcp_nanqinlang-gentle.c
	[[ "${mode}" = "2" ]] && wget -O tcp_nanqinlang.c https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/CentOS/c/tcp_nanqinlang-violent.c

	wget -O Makefile https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/Makefile/Makefile-CentOS

	make && make install
	cd .. && rm -rf make
}

start(){
	check_system
	check_root
	check_ovz
	directory
	delete_surplus && grub2-mkconfig -o /boot/grub2/grub.cfg
	yum update && yum groupinstall -y "Development Tools" && yum install -y perl-ExtUtils-Install libtool gcc gcc-c++
	maker
	echo -e "\nnet.ipv4.tcp_congestion_control=nanqinlang\c" >> /etc/sysctl.conf && sysctl -p
	check_status
}

check_status(){
	status_sysctl=`sysctl net.ipv4.tcp_available_congestion_control | awk '{print $3}'`
	status_lsmod=`lsmod | grep nanqinlang`
	if [[ "${status_lsmod}" != "" ]]; then
		echo -e "${Info} tcp_nanqinlang is installed!"
		 if [[ "${status_sysctl}" = "nanqinlang" ]]; then
			 echo -e "${Info} tcp_nanqinlang is running"
			 else echo -e "${Error} tcp_nanqinlang is installed not running!"
		 fi
	else echo -e "${Error} tcp_nanqinlang not installed"
	fi
}

status(){
	check_root
	check_status
}

uninstall(){
	check_root
	sed -i '/net\.ipv4\.tcp_congestion_control=nanqinlang/d' /etc/sysctl.conf
	sysctl -p
	rm -rf /home/tcp_nanqinlang
	rm /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko
	echo -e "${Info} please remember ${reboot} to stop tcp_nanqinlang"
}




echo -e "${Info} 选择你要使用的功能: "
echo -e "1.更换内核版本\n2.安装并开启 tcp_nanqinlang\n3.检查 tcp_nanqinlang 运行状态\n4.卸载 tcp_nanqinlang"
read -p "输入数字以选择:" function

while [[ ! "${function}" =~ ^[1-4]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" function
	done

if [[ "${function}" == "1" ]]; then
	install
elif [[ "${function}" == "2" ]]; then
	start
elif [[ "${function}" == "3" ]]; then
	status
else
	uninstall
fi
