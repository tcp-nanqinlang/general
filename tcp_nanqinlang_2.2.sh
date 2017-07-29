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
# Version: 2.2
# Author: nanqinlang
# Blog:   https://www.nanqinlang.com
# Github: https://github.com/nanqinlang
#======================================${Font_suffix}"

#check system
check_system(){
	cat /etc/issue | grep -q -E -i "debian" && release="debian" 
	cat /etc/issue | grep -q -E -i "ubuntu" && release="ubuntu"
    if [[ "${release}" = "debian" || "${release}" != "ubuntu" ]]; then 
	echo -e "${Info} system is ${release}"
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
	[[ "`virt-what`" = "" ]] && apt-get -y install virt-what
	virt=`virt-what`
	if [[ "${virt}" = "openvz" ]]; then 
	echo -e "${Error} OpenVZ is not support!" && exit 1
	else echo -e "${Info} virt is ${virt}"
	fi
}

#determine workplace directory
directory(){
    [[ ! -d /home/tcp_nanqinlang ]] && mkdir -p /home/tcp_nanqinlang
	cd /home/tcp_nanqinlang
}

#determine kernel version
get_version(){
    echo -e "${Info} input required kernel version(eg. 4.12.2):"
	stty erase '^H' && read -p "(defaultly use 4.12.2):" determine_version
	[[ -z "${determine_version}" ]] && determine_version=4.12.2
}
get_url(){
    get_version
    headers_all_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${determine_version}/ | grep "linux-headers" | awk -F'\">' '/all.deb/{print $2}' | cut -d'<' -f1 | head -1`
    headers_all_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${determine_version}/${headers_all_name}"
	bit=`uname -m`
	if [[ "${bit}" = "x86_64" ]]; then
		image_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${determine_version}/ | grep "linux-image" | grep "lowlatency" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1`
		image_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${determine_version}/${image_name}"
		headers_bit_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${determine_version}/ | grep "linux-headers" | grep "lowlatency" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1`
		headers_bit_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${determine_version}/${headers_bit_name}"
	elif [[ "${bit}" = "i386" ]]; then
		image_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${determine_version}/ | grep "linux-image" | grep "lowlatency" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1`
		image_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${determine_version}/${image_name}"
		headers_bit_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${determine_version}/ | grep "linux-headers" | grep "lowlatency" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1`
		headers_bit_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${determine_version}/${headers_bit_name}"
	else echo -e "${Error} not support bit !" && exit 1
	fi
}

#delete surplus image
delete_surplus_image(){
        if [[ "${surplus_total_image}" != "0" ]]; then
		for((integer = 1; integer <= ${surplus_total_image}; integer++))
		do
			 surplus_sort_image=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${determine_version}" | head -${integer}`
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
			 surplus_sort_headers=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${determine_version}" | head -${integer}`
			 apt-get purge ${surplus_sort_headers} -y
		done
	    apt-get autoremove -y
		if [[ "${surplus_total_headers}" = "0" ]]; then
			 echo -e "${Info} uninstall all surplus headers successfully, continuing"
		fi
}

install_image(){
	if [[ -e "${image_name}" ]]; then
		 echo -e "${Info} image exists"
		 else echo -e "${Info} downloading image" && wget ${image_url}
	fi
    if [[ -e "${image_name}" ]]; then
         echo -e "${Info} installing image" && dpkg -i ${image_name}
		 else echo -e "${Error} image download failed, please check!" && exit 1
    fi
}
install_headers(){
	if [[ -e ${headers_all_name} ]]; then
		 echo -e "${Info} headers_all exists"
		 else echo -e "${Info} downloading headers_all" && wget ${headers_all_url}
	fi
    if [[ -e ${headers_all_name} ]]; then
         echo -e "${Info} installing headers_all" && dpkg -i ${headers_all_name}
		 else echo -e "${Error} headers_all download failed, please check!" && exit 1
    fi
	if [[ -e ${headers_bit_name} ]]; then
		 echo -e "${Info} headers_bit exists"
		 else echo -e "${Info} downloading headers_bit" && wget ${headers_bit_url}
	fi
    if [[ -e ${headers_bit_name} ]]; then
         echo -e "${Info} installing headers_bit" && dpkg -i ${headers_bit_name}
		 else echo -e "${Error} headers_bit download failed, please check!" && exit 1
    fi
}

#check/install determine version and remove surplus kernel
check_kernel(){
    get_url
	#when kernel version = determine version, response determine version digital number.
	digit_ver_image=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${determine_version}"`
	digit_ver_headers=`dpkg -l | grep linux-headers | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${determine_version}"`
	#total digit of kernel without determine version
	surplus_total_image=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${determine_version}" | wc -l`
	surplus_total_headers=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${determine_version}" | wc -l`
	if [[ "${surplus_total_image}" != "0" ]]; then
		echo -e "${Info} removing surplus image" && delete_surplus_image
		else echo -e "${Info} no surplus image need to remove"
	fi
	if [[ "${surplus_total_headers}" != "0" ]]; then
		echo -e "${Info} removing surplus headers" && delete_surplus_headers
		else echo -e "${Info} no surplus headers need to remove"
	fi
	if [[ -z "${digit_ver_image}" ]]; then
	    echo -e "${Info} installing determine image" && install_image
        else echo -e "${Info} image already have a determine version"
	fi
	#determine 4.12.2 and reboot part
	if [[ "${determine_version}" != "4.12.2" ]]; then
	    if [[ -z "${digit_ver_headers}" ]]; then
		    echo -e "${Info} installing determine headers" && install_headers && update-grub && echo -e "after ${reboot}, please run 'start' command"
		    else echo -e "${Info} headers already have a determine version"
		fi
	else update-grub && ver_4.12.2 && boot_start && echo -e "${Info} your version is 4.12.2, just need a ${reboot} command"
	fi
	
}

#(1)while kernel is 4.12.2
ver_4.12.2(){
	if [[ ! -e tcp_nanqinlang.ko ]]; then
	#directly download .ko pattern
	echo -e "${Info} downloading mod_for_4.12.2" && wget -O tcp_nanqinlang.ko "https://raw.githubusercontent.com/nanqinlang/tcp_nanqinlang/master/tcp_nanqinlang_for_4.12.2.ko"
	fi
	#check download or not and apply
	if [[ ! -e tcp_nanqinlang.ko ]]; then
	echo -e "${Error} download mod_for_4.12.2 failed,please check!" && exit 1
	else echo -e "${Info} download mod_for_4.12.2 successfully"
	fi
}

#(2)while kernel isn't 4.12.2
ver_current(){
	if [[ ! -e tcp_nanqinlang.ko ]]; then
	#need to compile .ko mod
	echo -e "${Info} will compile mod_for_current" && apt-get update && apt-get install build-essential -y && apt-get update && apt-get install git python make gcc-4.9 -y && apt-get update && wget https://raw.githubusercontent.com/nanqinlang/tcp_nanqinlang/master/tcp_nanqinlang.c && echo "obj-m:=tcp_nanqinlang.o" > Makefile && make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc-4.9
	fi
	#check compile or not and apply
	if [[ ! -e tcp_nanqinlang.ko ]]; then
	echo -e "${Error} compiling mod_for_current failed, please check!" && exit 1
    else echo -e "${Info} mod_for_current is compiled, loading now" && chmod +x /home/tcp_nanqinlang/tcp_nanqinlang.ko && insmod /home/tcp_nanqinlang/tcp_nanqinlang.ko && sysctl -p
	fi
}

#self-start
boot_start(){
    echo "chmod +x /home/tcp_nanqinlang/tcp_nanqinlang.ko && insmod /home/tcp_nanqinlang/tcp_nanqinlang.ko && sysctl -p" > /home/tcp_nanqinlang/bootstart.sh
    sed -i 's/exit 0/ /ig' /etc/rc.local
    echo "/home/tcp_nanqinlang/bootstart.sh" >> /etc/rc.local && chmod +x /home/tcp_nanqinlang/bootstart.sh
}

#check status
check_status(){
	status_sysctl=`sysctl net.ipv4.tcp_available_congestion_control | awk '{print $3}'`
	status_lsmod=`lsmod | grep nanqinlang`
	if [[ "${status_sysctl}" = "nanqinlang" ]]; then
	echo -e "${Info} tcp_nanqinlang is installed!"
	     if [[ "${status_lsmod}" = "" ]]; then
		      echo -e "${Info} tcp_nanqinlang is installed but not running" && exit 0
	     else echo -e "${Info} tcp_nanqinlang is running!" && exit 0
	     fi
	else echo -e "${Error} tcp_nanqinlang not installed" && exit 0
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
	echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf
    echo "net.core.default_qdisc=fq_codel" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=nanqinlang" >> /etc/sysctl.conf
    check_kernel
    exit 0
}

#start
start(){
    check_system
	check_root
	check_ovz
	directory
	current_version=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "4.12.2"`
	[[ "${current_version}" = "4.12.2" ]] && echo -e "${Info} your version is 4.12.2, no need to run 'start' command" && exit 1
	ver_current && boot_start
    check_status
}

#status
status(){
	check_status
}

#upgrade
upgrade(){
    check_system
	check_root
	check_ovz
	directory
	check_kernel
	exit 0
}

#stop
stop(){
	sed -i '/net\.ipv4\.tcp_congestion_control=nanqinlang/d' /etc/sysctl.conf
	sysctl -p
	rm -rf /home/tcp_nanqinlang
	sed -i '/home/tcp_nanqinlang/bootstart.sh' /etc/rc.local
	echo -e "${Info} please remember ${reboot} to stop tcp_nanqinlang"
	exit 0
}

#${command}
command=$1
if [[ "${command}" = "" ]]; then
    echo -e "${Info}command not found, usage: ${Green_font}{ install | start | status | upgrade | stop }${Font_suffix}" && exit 0
else
    command=$1
fi
case "${command}" in
	 install)
     install 2>&1 | tee -i /home/tcp_nanqinlang_install.log
	 ;;
	 start)
     start 2>&1 | tee -i /home/tcp_nanqinlang_start.log
	 ;;
	 status)
     status 2>&1 | tee -i /home/tcp_nanqinlang_status.log
	 ;;
	 upgrade)
     upgrade 2>&1 | tee -i /home/tcp_nanqinlang_upgrade.log
	 ;;
	 stop)
     stop 2>&1 | tee -i /home/tcp_nanqinlang_stop.log
	 ;;
esac