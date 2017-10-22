#!/bin/bash
Green_font="\033[32m" && Yellow_font="\033[33m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
reboot="${Yellow_font}reboot${Font_suffix}"
echo -e "${Green_font}
#======================================
# Project: tcp_nanqinlang
# Description: tcp bbr enhancement
# Version: 3.0
# Author: nanqinlang
# Blog:   https://sometimesnaive.org
# Github: https://github.com/nanqinlang
#======================================${Font_suffix}"

check_system(){
	cat /etc/issue | grep -q -E -i "debian" && release="debian"
	[[ "${release}" = "debian" ]] && echo -e "${Error} only support Debian !" && exit 1
}

check_root(){
	[[ "`id -u`" = "0" ]] && echo -e "${Error} must be root user" && exit 1
}

#check ovz
check_ovz(){
	apt-get update && apt-get install -y virt-what
	virt=`virt-what`
	[[ "${virt}" = "openvz" ]] && echo -e "${Error} OpenVZ not support!" && exit 1
}

directory(){
	[[ ! -d /home/tcp_nanqinlang ]] && mkdir -p /home/tcp_nanqinlang
	cd /home/tcp_nanqinlang
}

get_version(){
	echo -e "${Info} 输入你想要的内核版本号(默认安装 v4.10.10):"
	read -p "(输入版本号，例如: 4.10.10):" required_version
	[[ -z "${required_version}" ]] && required_version=4.10.10
}

get_url(){
	get_version
	headers_all_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/ | grep "linux-headers" | awk -F'\">' '/all.deb/{print $2}' | cut -d'<' -f1 | head -1`
	headers_all_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/${headers_all_name}"
	bit=`uname -m`
	if [[ "${bit}" = "x86_64" ]]; then
		image_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/ | grep "linux-image" | grep "lowlatency" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1`
		image_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/${image_name}"
		headers_bit_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/ | grep "linux-headers" | grep "lowlatency" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1`
		headers_bit_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/${headers_bit_name}"
	elif [[ "${bit}" = "i386" ]]; then
		image_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/ | grep "linux-image" | grep "lowlatency" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1`
		image_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/${image_name}"
		headers_bit_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/ | grep "linux-headers" | grep "lowlatency" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1`
		headers_bit_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/${headers_bit_name}"
	else echo -e "${Error} not support bit !" && exit 1
	fi
}

libssl1.0.0(){
		apt-get update
		echo -e "\ndeb http://ftp.de.debian.org/debian jessie main\c" >> /etc/apt/sources.list
		apt-get update && apt-get install -y libssl1.0.0 && apt-get update
		##delete the same line
		##may mistakely delete lines that is the same and already exist
		##sed -i '/deb http:\/\/ftp\.de\.debian\.org\/debian jessie main/d' /etc/apt/sources.list
		#delete the latest line
		sed -i '$d' /etc/apt/sources.list
}

gcc4.9(){
	if [[ "${sys_ver}" = "7" ]]; then
		apt-get update && mv /etc/apt/sources.list /etc/sources.list
		wget -P /home/tcp_nanqinlang https://raw.githubusercontent.com/nanqinlang/sources.list/master/us.sources.list && mv /home/tcp_nanqinlang/us.sources.list /etc/apt/sources.list
		apt-get update && apt-get install -y build-essential
		rm /etc/apt/sources.list && mv /etc/sources.list /etc/apt/sources.list && apt-get update
	else
		apt-get update && apt-get install -y build-essential && apt-get update
	fi
}

#delete surplus image
delete_surplus_image(){
		for((integer = 1; integer <= ${surplus_total_image}; integer++))
		do
			 surplus_sort_image=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${required_version}" | head -${integer}`
			 apt-get purge -y ${surplus_sort_image}
		done
		apt-get autoremove -y
		if [[ "${surplus_total_image}" = "0" ]]; then
			echo -e "${Info} uninstall all surplus images successfully, continuing"
		fi
}

#delete surplus headers
delete_surplus_headers(){
		for((integer = 1; integer <= ${surplus_total_headers}; integer++))
		do
			 surplus_sort_headers=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${required_version}" | head -${integer}`
			 apt-get purge -y ${surplus_sort_headers}
		done
		apt-get autoremove -y
		if [[ "${surplus_total_headers}" = "0" ]]; then
			 echo -e "${Info} uninstall all surplus headers successfully, continuing"
		fi
}

install_image(){
	if [[ -e "${image_name}" ]]; then
		 echo -e "${Info} deb file exist"
		 else echo -e "${Info} downloading image" && wget ${image_url}
	fi
	if [[ -e "${image_name}" ]]; then
		 echo -e "${Info} installing image" && dpkg -i ${image_name}
		 else echo -e "${Error} image download failed, please check!" && exit 1
	fi
}

install_headers(){
	if [[ -e ${headers_all_name} ]]; then
		 echo -e "${Info} deb file exist"
		 else echo -e "${Info} downloading headers_all" && wget ${headers_all_url}
	fi
	if [[ -e ${headers_all_name} ]]; then
		 echo -e "${Info} installing headers_all" && dpkg -i ${headers_all_name}
		 else echo -e "${Error} headers_all download failed, please check!" && exit 1
	fi
	if [[ -e ${headers_bit_name} ]]; then
		 echo -e "${Info} deb file exist"
		 else echo -e "${Info} downloading headers_bit" && wget ${headers_bit_url}
	fi
	if [[ -e ${headers_bit_name} ]]; then
		 echo -e "${Info} installing headers_bit" && dpkg -i ${headers_bit_name}
		 else echo -e "${Error} headers_bit download failed, please check!" && exit 1
	fi
}

#check/install required version and remove surplus kernel
check_kernel(){
	get_url
	#when kernel version = required version, response required version digital number.
	digit_ver_image=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${required_version}"`
	digit_ver_headers=`dpkg -l | grep linux-headers | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${required_version}"`
	#total digit of kernel without required version
	surplus_total_image=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${required_version}" | wc -l`
	surplus_total_headers=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${required_version}" | wc -l`

	if [[ -z "${digit_ver_image}" ]]; then
		 echo -e "${Info} installing required image" && install_image
	else echo -e "${Info} image already installed a required version"
	fi

	if [[ "${surplus_total_image}" != "0" ]]; then
		 echo -e "${Info} removing surplus image" && delete_surplus_image
	else echo -e "${Info} no surplus image need to remove"
	fi

	if [[ "${surplus_total_headers}" != "0" ]]; then
		 echo -e "${Info} removing surplus headers" && delete_surplus_headers
	else echo -e "${Info} no surplus headers need to remove"
	fi

	if [[ -z "${digit_ver_headers}" ]]; then
		 echo -e "${Info} installing required headers" && install_headers
	else echo -e "${Info} headers already installed a required version"
	fi

	update-grub
}

dpkg_list(){
    dpkg -l|grep linux-image | awk '{print $2}'
    dpkg -l|grep linux-headers | awk '{print $2}'
	echo -e "${Info} 请确认此行上下的列表显示的内核版本完全一致:\nlinux-image-${required_version}-lowlatency\nlinux-headers-${required_version}\nlinux-headers-${required_version}-lowlatency"
}

# while kernel isn't 4.10.2
ver_current(){
	[[ ! -e /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && compiler
	[[ ! -e /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && echo -e "${Error} load mod failed, please check!" && exit 1
}

compiler(){
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

	# kernel source code：https://www.kernel.org/pub/linux/kernel #
	ver_4_13=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "4.13"`

	[[ "${mode}" = "1" ]] && [[   -z "${ver_4_13}" ]] && wget -O tcp_nanqinlang.c https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/Debian/general/tcp_nanqinlang-gentle.c
	[[ "${mode}" = "2" ]] && [[   -z "${ver_4_13}" ]] && wget -O tcp_nanqinlang.c https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/Debian/general/tcp_nanqinlang-violent.c
	[[ "${mode}" = "1" ]] && [[ ! -z "${ver_4_13}" ]] && wget -O tcp_nanqinlang.c https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/Debian/kernel-v4.13/tcp_nanqinlang-gentle.c
	[[ "${mode}" = "2" ]] && [[ ! -z "${ver_4_13}" ]] && wget -O tcp_nanqinlang.c https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/Debian/kernel-v4.13/tcp_nanqinlang-violent.c

	sys_ver=`grep -oE  "[0-9.]+" /etc/issue`
	if [[ "${sys_ver}" = "9" ]]; then
		wget -O Makefile https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/Makefile/Makefile-Debian9
	else
		wget -O Makefile https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/Makefile/Makefile-Debian7or8
	fi

	make && make install
	cd .. && rm -rf make
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

install(){
	check_system
	check_root
	check_ovz
	directory
	sys_ver=`grep -oE  "[0-9.]+" /etc/issue` && libssl1.0.0 && gcc4.9
	check_kernel
	dpkg_list
	echo -e "${Info} please check kernel version and ${reboot}, then run 'start' command to enable tcp_nanqinlang"
}

start(){
	check_system
	check_root
	check_ovz
	directory
	current_version=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}'`
	ver_current
	echo -e "\nnet.ipv4.tcp_congestion_control=nanqinlang\c" >> /etc/sysctl.conf && sysctl -p
	check_status
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
