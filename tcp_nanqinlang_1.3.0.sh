#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#Green_font="\033[32m" && Yellow_font="\033[33m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="\033[32m [Info] \033[0m"
Error="\033[31m [Error] \033[0m"
reboot="\033[33m reboot \033[0m"
echo -e "\033[32m
#======================================
# Project: tcp_nanqinlang
# Version: 1.3.0
# Author: nanqinlang
# Blog:   https://www.nanqinlang.com
# Github: https://github.com/nanqinlang
#====================================== \033[0m"

#check system
check_system(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	if [[ "${release}" != "debian" ]]; then
		if [[ "${release}" != "ubuntu" ]]; then
			echo -e "${Error} not support!" && exit 1
			else echo -e "${Info} system is ubuntu"
		fi
	else echo -e "${Info} system is debian"
	fi
}

#check root
check_root(){
    if [[ "$(id -u)" != "0" ]]; then
    echo -e "${Error} must be root user" && exit 1
	else echo -e "${Info} user is root"
    fi
}

#check ovz
check_ovz(){
	virt=`virt-what`
	if [[ "${virt}" = "" ]]; then
		apt-get install virt-what -y
		virt=`virt-what`
	fi
	if [[ "${virt}" = "openvz" ]]; then
		echo -e "${Error} OpenVZ is not support!" && exit 1
		else echo -e "${Info} virt is ${virt}"
    fi
}

#determine workplace directory
directory(){
    if [[ ! -d /root/tcp_nanqinlang ]]; then
	    mkdir /root/tcp_nanqinlang
	fi
	cd /root/tcp_nanqinlang
}

#get latest address
get_latest_version(){
	latest_version=`wget -qO- "http://kernel.ubuntu.com/~kernel-ppa/mainline/" | awk -F'\"v' '/v[0-9].[0-9]*.[0-9]/{print $2}' |grep -v '\-rc'| cut -d/ -f1 | sort -V | tail -1`
	echo -e "${Info} latest version : ${latest_version}"
}
get_latest_url(){
    headers_all_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-headers" | awk -F'\">' '/all.deb/{print $2}' | cut -d'<' -f1 | head -1`
    headers_all_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${headers_all_name}"
	bit=`uname -m`
	if [[ "${bit}" = "x86_64" ]]; then
		image_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-image" | grep "lowlatency" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1`
		image_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${image_name}"
		headers_bit_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-headers" | grep "lowlatency" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1`
		headers_bit_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${headers_bit_name}"
	elif [[ "${bit}" = "i386" ]]; then
		image_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-image" | grep "lowlatency" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1`
		image_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${image_name}"
		headers_bit_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-headers" | grep "lowlatency" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1`
		headers_bit_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${headers_bit_name}"
	else
	echo -e "${Error} not support bit !" && exit 1
	fi
}

#delete surplus image
delete_surplus_image(){
	if [[ "${surplus_total_image}" != "0" ]]; then
		for((integer = 1; integer <= ${surplus_total_image}; integer++))
		do
			 surplus_sort_image=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | head -${integer}`
			 apt-get purge ${surplus_sort_image} -y
		done
	    apt-get autoremove -y
		if [[ "${surplus_ver_image}" = "" ]]; then
			 echo -e "${Info} uninstall all surplus images successfully, continuing"
		else echo -e "${Error} uninstall all surplus images failed, please check!" && exit 1
		fi
	else echo -e "${Error} check image failed, please check!" && exit 1
	fi
}
#delete surplus headers
delete_surplus_headers(){
	if [[ "${surplus_total_headers}" != "0" ]]; then
		for((integer = 1; integer <= ${surplus_total_headers}; integer++))
		do
			 surplus_sort_headers=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${latest_version}" | head -${integer}`
			 apt-get purge ${surplus_sort_headers} -y
		done
	    apt-get autoremove -y
		if [[ "${surplus_ver_headers}" = "" ]]; then
			 echo -e "${Info} uninstall all surplus headers successfully, continuing"
		else echo -e "${Error} uninstall all surplus headers failed, please check!" && exit 1
		fi
	else echo -e "${Error} check headers failed, please check!" && exit 1
	fi
}

install_latest_image(){
	if [[ -f "${image_name}" ]]; then
		 echo -e "${Info} image exists"
		 else echo -e "${Info} downloading image" && wget ${image_url}
	fi
    if [[ -f "${image_name}" ]]; then
         echo -e "${Info} installing image" && dpkg -i ${image_name}
		 else echo -e "${Error} image download failed, please check!" && exit 1
    fi
}
install_latest_headers(){
	if [[ -f ${headers_all_name} ]]; then
		 echo -e "${Info} headers_all exists"
		 else echo -e "${Info} downloading headers_all" && wget ${headers_all_url}
	fi
    if [[ -f ${headers_all_name} ]]; then
         echo -e "${Info} installing headers_all" && dpkg -i ${headers_all_name}
		 else echo -e "${Error} headers_all download failed, please check!" && exit 1
    fi
	if [[ -f ${headers_bit_name} ]]; then
		 echo -e "${Info} headers_bit exists"
		 else echo -e "${Info} downloading headers_bit" && wget ${headers_bit_url}
	fi
    if [[ -f ${headers_bit_name} ]]; then
         echo -e "${Info} installing headers_bit" && dpkg -i ${headers_bit_name}
		 else echo -e "${Error} headers_bit download failed, please check!" && exit 1
    fi
}

#check/install latest version and remove surplus kernel
check_kernel(){
    get_latest_version && get_latest_url
	#kernel version = latest version
	surplus_ver_image=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${latest_version}"`
	surplus_ver_headers=`dpkg -l | grep linux-headers | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${latest_version}"`
	#total digit of kernel without latest version
	surplus_total_image=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | wc -l`
	surplus_total_headers=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${latest_version}" | wc -l`
	if [[ "${surplus_ver_image}" = "${latest_version}" ]]; then
	    echo -e "${Info} image already have a latest version"
        else echo -e "${Info} installing latest image" && install_latest_image
		fi
    if [[ "${surplus_total_image}" != "0" ]]; then
		echo -e "${Info} removing surplus image" && delete_surplus_image
		else echo -e "${Info} no surplus image need to remove"
		fi
	if [[ "${surplus_ver_headers}" = "${latest_version}" ]]; then
		echo -e "${Info} headers already have a latest version"
		else echo -e "${Info} installing latest headers" && install_latest_headers
		fi
	if [[ "${surplus_total_headers}" != "0" ]]; then
		echo -e "${Info} removing surplus headers" && delete_surplus_headers
		else echo -e "${Info} no surplus headers need to remove"
	fi
	update-grub
}

#dpkg -l
dpkg_list(){
    dpkg -l|grep linux-image | awk '{print $2}'
    dpkg -l|grep linux-headers | awk '{print $2}'
	echo -e "\033[32m please ensure above kernel list is the same as: \033[0m"
	echo -e "\033[33m linux-image-${latest_version}-lowlatency \033[0m"
	echo -e "\033[33m linux-headers-${latest_version} \033[0m"
	echo -e "\033[33m linux-headers-${latest_version}-lowlatency \033[0m"
}

#(1)while kernel is 4.12.2
ver_4.12.2(){
	echo -e "${Info} kernel version is 4.12.2"
	if [[ ! -f tcp_nanqinlang.ko ]]; then
	#directly download .ko pattern
	echo -e "${Info} downloading mod_for_4.12.2" && wget -O tcp_nanqinlang.ko "https://raw.githubusercontent.com/nanqinlang/tcp_nanqinlang/master/tcp_nanqinlang_for_4.12.2.ko"
	fi
	#check download or not and apply
	if [[ ! -f tcp_nanqinlang.ko ]]; then
	echo -e "${Error} download mod_for_4.12.2 failed,please check!" && exit 1
	else echo "${Info} loading mod_for_4.12.2 now" && chmod +x ./tcp_nanqinlang.ko && insmod tcp_nanqinlang.ko && sysctl -p
	fi
}

#(2)while kernel isn't 4.12.2
ver_current(){
	if [[ ! -f tcp_nanqinlang.ko ]]; then
	#need to compile .ko mod
	echo -e "${Info} will compile mod_for_current" && apt-get update && apt-get install build-essential -y && apt-get update && apt-get install git python make gcc-4.9 -y && apt-get update && wget https://raw.githubusercontent.com/nanqinlang/tcp_nanqinlang/master/tcp_nanqinlang.c && echo "obj-m:=tcp_nanqinlang.o" > Makefile && make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc-4.9
	fi
	#check compile or not and apply
	if [[ ! -f tcp_nanqinlang.ko ]]; then
	echo -e "${Error} compiling mod_for_current failed, please check!" && exit 1
    else echo -e "${Info} mod_for_current is compiled, loading now" && chmod +x ./tcp_nanqinlang.ko && insmod tcp_nanqinlang.ko && sysctl -p
	fi
}

#check status
check_status(){
	status_sysctl=`sysctl net.ipv4.tcp_available_congestion_control | awk '{print $3}'`
	status_lsmod=`lsmod | grep nanqinlang`
	if [[ "${status_sysctl}" = "nanqinlang" ]]; then
	echo -e "${Info} tcp_nanqinlang is installed!"
	     if [[ "${status_lsmod}" = "" ]]; then
		      echo -e "${Info} tcp_nanqinlang is installed but not running, please ${reboot} then run \033[33m Start \033[0m" && exit 0
	     else echo -e "${Info} tcp_nanqinlang is running!" && exit 0
	     fi
	else echo -e "${Error} tcp_nanqinlang not installed, please \033[33m install \033[0m then try start anain" && exit 1
	fi
}

#install
install(){
	#environment
	check_system
	check_root
    apt-get update && apt-get install debian-keyring debian-archive-keyring -y && apt-key update && apt-get update
	check_ovz
    #replace and apply
	directory
    check_kernel
    echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf
    echo "net.core.default_qdisc=fq_codel" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=nanqinlang" >> /etc/sysctl.conf
	sysctl -p
	#reboot part
	dpkg_list
	echo -e "then remember after ${reboot}, run \033[33m start \033[0m"
    exit 0
}

#start
start(){
    check_system
	check_root
	check_ovz
	#determine kernel is 4.12.2 or not
	ver=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "4.12.2"`
	if [[ "${ver}" = "4.12.2" ]]; then
	    ver_4.12.2
	else
	    ver_current
	fi
    check_status
}

#status
status(){
    check_system
	check_root
	check_ovz
	check_status
}

#upgrade
upgrade(){
    check_system
	check_root
	check_ovz
	check_kernel
	exit 0
}

#stop
stop(){
    check_system
	check_root
	check_ovz
	sed -i '/net\.ipv4\.tcp_congestion_control=nanqinlang/d' /etc/sysctl.conf
	sysctl -p
	echo -e "${Info} please remember ${reboot} to stop tcp_nanqinlang"
	exit 0
}

#${command}
command=$1
if [[ "${command}" = "" ]]; then
    echo -e "${Info}command not found, usage: \033[32m { install | start | status | upgrade | stop } \033[0m" && exit 0
else
    command=$1
fi
case "${command}" in
	 install)
     install 2>&1 | tee -i /root/tcp_nanqinlang_install.log
	 ;;
	 start)
     start 2>&1 | tee -i /root/tcp_nanqinlang_start.log
	 ;;
	 status)
     status 2>&1 | tee -i /root/tcp_nanqinlang_status.log
	 ;;
	 upgrade)
     upgrade 2>&1 | tee -i /root/tcp_nanqinlang_upgrade.log
	 ;;
	 stop)
     stop 2>&1 | tee -i /root/tcp_nanqinlang_stop.log
	 ;;
esac