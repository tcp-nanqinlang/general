#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
Green_font="\033[32m" && Yellow_font="\033[33m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
reboot="${Yellow_font}reboot${Font_suffix}"
echo -e "${Green_font}
#======================================
# Project: tcp_nanqinlang
# Version: 2.9
# Author: nanqinlang
# Blog:   https://www.nanqinlang.com
# Github: https://github.com/nanqinlang
#======================================${Font_suffix}"

#check system
check_system(){
	cat /etc/issue | grep -q -E -i "debian" && release="debian"

	if [[ "${release}" = "debian" ]]; then
		echo -e "${Info} system is debian "
		else echo -e "${Error} not support!" && exit 1
	fi
}

#check root
check_root(){
	if [[ "`id -u`" = "0" ]]; then
	echo -e "${Info} user is root"
	else echo -e "${Error} must be root user" && exit 1
	fi
}

#check ovz
check_ovz(){
	apt-get update && apt-get install virt-what -y
	virt=`virt-what`
	if [[ "${virt}" = "openvz" ]]; then
	echo -e "${Error} OpenVZ is not support!" && exit 1
	else echo -e "${Info} virt is ${virt}"
	fi
}

#required workplace directory
directory(){
	[[ ! -d /home/tcp_nanqinlang ]] && mkdir -p /home/tcp_nanqinlang
	cd /home/tcp_nanqinlang
}

#required kernel version
get_version(){
	echo -e "${Info} input required kernel version (defaultly use 4.10.2):"
	read -p "(eg. 4.10.2):" required_version
	[[ -z "${required_version}" ]] && required_version=4.10.2
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

#delete surplus image
delete_surplus_image(){
		if [[ "${surplus_total_image}" != "0" ]]; then
		for((integer = 1; integer <= ${surplus_total_image}; integer++))
		do
			 surplus_sort_image=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${required_version}" | head -${integer}`
			 apt-get purge ${surplus_sort_image} -y
		done
		apt-get autoremove -y
		if [[ "${surplus_total_image}" = "0" ]]; then
			 echo -e "${Info} uninstall all surplus images successfully, continuing"
		fi
	else echo -e "${Error} check image failed, please check!" && exit 1
	fi
}

#delete surplus headers
delete_surplus_headers(){
		for((integer = 1; integer <= ${surplus_total_headers}; integer++))
		do
			 surplus_sort_headers=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${required_version}" | head -${integer}`
			 apt-get purge ${surplus_sort_headers} -y
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
	else
		echo -e "${Info} image already have a required version"
	fi

	if [[ "${surplus_total_image}" != "0" ]]; then
		echo -e "${Info} removing surplus image" && delete_surplus_image
	else
		echo -e "${Info} no surplus image need to remove"
	fi

	if [[ "${surplus_total_headers}" != "0" ]]; then
		echo -e "${Info} removing surplus headers" && delete_surplus_headers
	else
		echo -e "${Info} no surplus headers need to remove"
	fi

	if [[ "${required_version}" != "4.10.2" ]]; then
		if [[ -z "${digit_ver_headers}" ]]; then
			echo -e "${Info} installing required headers" && install_headers
		else
			echo -e "${Info} headers already have a required version"
		fi
	else
	echo -e "${Info} required is 4.10.2, noneed to install headers"
	fi

	update-grub
}

dpkg_list(){
    dpkg -l|grep linux-image | awk '{print $2}'
    dpkg -l|grep linux-headers | awk '{print $2}'
	echo -e "${Info} please ensure above kernel list is the same as the following:\nlinux-image-${required_version}-lowlatency\nlinux-headers-${required_version}\nlinux-headers-${required_version}-lowlatency"
}

#(1)while kernel is 4.10.2
ver_4.10.2(){
	[[ ! -e /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && echo -e "${Info} loading mod" && cd /lib/modules/`uname -r`/kernel/net/ipv4 && wget -O tcp_nanqinlang.ko "https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/mod/tcp_nanqinlang_for_4.10.2.ko" && insmod tcp_nanqinlang.ko && depmod -a
	[[ ! -e /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && echo -e "${Error} download mod failed,please check!" && exit 1
}

#(2)while kernel isn't 4.10.2
ver_current(){
	[[ ! -e /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && compiler
	[[ ! -e /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && echo -e "${Error} load mod failed, please check!" && exit 1
}

gcc-4.9(){
	if [[ "${sys_ver}" = "7" ]]; then
		apt-get update && mv /etc/apt/sources.list /etc/sources.list
		wget -P /home/tcp_nanqinlang https://raw.githubusercontent.com/nanqinlang/sources.list/master/us.sources.list && mv /home/tcp_nanqinlang/us.sources.list /etc/apt/sources.list
		apt-get update && apt-get install build-essential -y && apt-get update
		rm /etc/apt/sources.list && mv /etc/sources.list /etc/apt/sources.list && apt-get update
	else
		apt-get update && apt-get install build-essential -y && apt-get update
	fi
}

libssl1.0.0(){
	if [[ "${sys_ver}" = "9" ]]; then
		echo "deb http://ftp.de.debian.org/debian jessie main" >> /etc/apt/sources.list
		apt-get update && apt-get install libssl1.0.0 -y
		sed -i '/deb http://ftp\.de\.debian\.org/debian jessie main/d' /etc/apt/sources.list
	fi
}

compiler(){
	mkdir make && cd make

	# kernel source code：https://www.kernel.org/pub/linux/kernel #
	ver_4_13=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "4.13"`
	if [[ -z "${ver_4_13}" ]]; then
		wget https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/general/tcp_nanqinlang.c
	else
		wget https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/kernel-v4.13/tcp_nanqinlang.c
	fi

	sys_ver=`grep -oE  "[0-9.]+" /etc/issue`
	if [[ "${sys_ver}" = "9" ]]; then
		wget -O Makefile https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/make/Makefile-debian9
	else
		wget -O Makefile https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/make/Makefile-debian7or8
	fi

	make && make install
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
	sys_ver=`grep -oE  "[0-9.]+" /etc/issue` && gcc-4.9 && libssl1.0.0
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
	if [[ "${current_version}" = "4.10.2" ]]; then
		ver_4.10.2
	else
		ver_current
	fi
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
