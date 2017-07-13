#! /bin/bash

Green_font="\033[32m" && Green_background="\033[42;37m" && Red_font="\033[31m" && Red_background="\033[41;37m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Success="${Green_font}[Success]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
Failed="${Red_font}[Failed]${Font_suffix}"
Careful="${Green_font}[Be Careful]${Font_suffix}"
Install="${Green_font}bash tcp_nanqinlang.sh install${Font_suffix}"
Start="${Green_font}bash tcp_nanqinlang.sh start${Font_suffix}"

echo -e "${Green_font}
#========================================================
# System Required: Debian/Ubuntu
# Description: tcp_nanqinlang
# Version: 1.0.1 beta
# Author: nanqinlang
# Blog:   https://www.nanqinlang.com
# Github: https://github.com/sinderyminami/tcp_nanqinlang
#========================================================${Font_suffix}"

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
}

#check kernel version is 4.11.0 or not
check_deb(){
	deb_ver=`dpkg -l|grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep '[4-9].[0-9]*.'`
	if [[ "${deb_ver}" != "" ]]; then
		if [[ "${deb_ver}" == "4.11.0" ]]; then
			echo -e "${Info} version is 4.11.0, continuing"
		else
			echo -e "${Error} kernel version is not 4.11.0, please use ${Install}"
		fi
	else
	echo -e "${Error} version is not support, please use ${Install}" && exit 1
	fi
}

#delete image
del_image(){
	image_total=`dpkg -l | grep linux-image | awk '{print $2}' | grep -v "4.11.0" | wc -l`
	if [ "${image_total}" > "1" ]; then
		echo -e "${Info} find ${image_total} other kernel, uninstalling"
		for((integer = 1; integer <= ${image_total}; integer++))
		do
			image_del=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "4.11.0" | head -${integer}`
			echo -e "${Info} uninstalling ${image_del}"
			apt-get purge -y ${image_del}
			echo -e "${Success} uninstalling ${image_del} successfully, continuing"
		done
		if [ "${image_total}" = "0" ]; then
			echo -e "${Success} uninstalling successfully, continuing"
		else
			echo -e "${Failed} uninstalling failed, please check!" && exit 1
		fi
	else
	echo -e "${Error} find a wrong kernel number, please check!" && exit 1
	fi
}

#delete headers
del_headers(){
	headers_total=`dpkg -l | grep linux-headers | awk '{print $2}' | grep -v "4.11.0" | wc -l`
	if [ "${headers_total}" > "1" ]; then
		echo -e "${Info} find ${headers_total} other kernel, uninstalling"
		for((integer = 1; integer <= ${headers_total}; integer++))
		do
			headers_del=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "4.11.0" | head -${integer}`
			echo -e "${Info} uninstalling ${headers_del}"
			apt-get purge -y ${headers_del}
			echo -e "${Success} uninstalling ${headers_del} successfully, continuing"
		done
		if [ "${headers_total}" = "0" ]; then
			echo -e "${Success} uninstalling successfully, continuing"
		else
			echo -e "${Failed} uninstalling failed, please check!" && exit 1
		fi
	else
	echo -e "${Error} find a wrong kernel number, please check!" && exit 1
	fi
}

install_image(){
    mkdir /root/tcp_nanqinlang
    cd /root/tcp_nanqinlang
	bit=`uname -m`
	if [[ ${bit} == "x86_64" ]]; then
         wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.11/linux-image-4.11.0-041100-lowlatency_4.11.0-041100.201705041534_amd64.deb	
         if [ -s linux-image-4.11.0-041100-lowlatency_4.11.0-041100.201705041534_amd64.deb ]; then
		     echo -e "${Success} download successfully, installing now"
		     dpkg -i linux-image-4.11.0-041100-lowlatency_4.11.0-041100.201705041534_amd64.deb
	     else
		     echo -e "${Failed} download failed, please check!" && exit 1
	     fi
	elif [ ${bit} == "i386" ]; then
    	 wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.11/linux-image-4.11.0-041100-lowlatency_4.11.0-041100.201705041534_i386.deb	
         if [ -s linux-image-4.11.0-041100-lowlatency_4.11.0-041100.201705041534_i386.deb ]; then
		     echo -e "${Success} download successfully, installing now"
		     dpkg -i linux-image-4.11.0-041100-lowlatency_4.11.0-041100.201705041534_i386.deb
	     else
		     echo -e "${Failed} download failed, please check!" && exit 1
	     fi
	else
	echo -e "${Error} not support ${bit} !" && exit 1
	fi
}

install_headers(){
    mkdir /root/tcp_nanqinlang
    cd /root/tcp_nanqinlang
	wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.11/linux-headers-4.11.0-041100_4.11.0-041100.201705041534_all.deb
	if [ -s linux-headers-4.11.0-041100_4.11.0-041100.201705041534_all.deb ]; then
		echo -e "${Success} download successfully, installing now"
		dpkg -i linux-headers-4.11.0-041100_4.11.0-041100.201705041534_all.deb
	else
		echo -e "${Failed} download failed, please check!" && exit 1
	fi
    bit=`uname -m`
	if [[ ${bit} == "x86_64" ]]; then
	     wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.11/linux-headers-4.11.0-041100-lowlatency_4.11.0-041100.201705041534_amd64.deb
	     if [ -s linux-headers-4.11.0-041100-lowlatency_4.11.0-041100.201705041534_amd64.deb ]; then
		     echo -e "${Success} download successfully, installing now"
		     dpkg -i linux-headers-4.11.0-041100-lowlatency_4.11.0-041100.201705041534_amd64.deb
	     else
		     echo -e "${Failed} download failed, please check!" && exit 1
	     fi
	elif [ ${bit} == "i386" ]; then
	     wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.11/linux-headers-4.11.0-041100-lowlatency_4.11.0-041100.201705041534_i386.deb
	     if [ -s linux-headers-4.11.0-041100-lowlatency_4.11.0-041100.201705041534_i386.deb ]; then
		     echo -e "${Success} download successfully, installing now"
		     dpkg -i linux-headers-4.11.0-041100-lowlatency_4.11.0-041100.201705041534_i386.deb
	     else
		     echo -e "${Failed} download failed, please check!" && exit 1
	     fi
	else
	echo -e "${Error} not support ${bit} !" && exit 1
	fi
}	

#install tcp_nanqinlang
install_tcp_nanqinlang(){
	
	#check system is bebian/ubuntu or not
	check_system
	if [[ ${release} != "debian" ]]; then
		if [[ ${release} != "ubuntu" ]]; then
			echo -e "${Error} not support!" && exit 1
		fi
	fi
	
	#there is no public key
    apt-get update
    apt-get install debian-keyring debian-archive-keyring -y
    apt-key update
    apt-get update
		
	#determine it's ovz or not
	virt=`virt-what`
	if [[ ${virt} = "" ]]; then
		apt-get install virt-what -y
		virt=`virt-what`
	fi
	if [[ ${virt} = "openvz" ]]; then
		echo -e "${Error} OpenVZ is not support!" && exit 1
    fi
	
    #determine it has 4.11.0 or not and remove surplus kernel
	#kernel version = 4.11.0
	image_ver_surplus=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "4.11.0"`
	headers_ver_surplus=`dpkg -l | grep linux-headers | awk '{print $2}' | awk -F '-' '{print $3}' | grep "4.11.0"`
	#total digit of kernel without 4.11.0
	image_total_surplus=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "4.11.0" | wc -l`
	headers_total_surplus=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "4.11.0" | wc -l`
	if [ ${image_ver_surplus} == "4.11.0" ]; then
	    echo -e "${Info} image 4.11.0 has been install"
		     if [ ${image_total_surplus} != "0" ]; then
			     echo -e "${Info} removing surplus image"
			     del_image
		     else 
		         echo -e "${Info} no surplus image need to remove"
		     fi
	    else 
	    echo -e "${Info} will install image 4.11.0"
     	install_image
	    fi

	if [ ${headers_ver_surplus} == "4.11.0" ]; then
		echo -e "${Info} headers 4.11.0 has been installed"
		     if [ ${headers_total_surplus} != "0" ]; then
			     echo -e "${Info} removing surplus headers"
			     del_headers
		     else 
		         echo -e "${Info} no surplus headers need to remove"
		     fi
	    else 
	    echo -e "${Info} will install headers 4.11.0"
     	install_headers
	    fi
	
	update-grub
	
	#enable tcp_nanqinlang via sysctl
	echo -e "fs.file-max=65535
net.core.wmem_default=34004432
net.core.wmem_max=67108864
net.core.rmem_default=34004432
net.core.rmem_max=67108864
net.core.netdev_max_backlog=250000
net.core.somaxconn=4096
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_tw_recycle=1
net.ipv4.tcp_max_tw_buckets=5000
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_syn_retries=1
net.ipv4.tcp_synack_retries=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_mem=25600 51200 102400
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.ipv4.tcp_keepalive_time=1200
net.ipv4.tcp_sack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_max_orphans=3276800
net.ipv4.tcp_timestamps=0
net.ipv4.ip_forward=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.default.accept_source_route=0
kernel.sysrq=0
kernel.core_uses_pid=1
kernel.msgmnb=65535
kernel.msgmax=65535
net.core.somaxconn=4096
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_fastopen=3
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control=nanqinlang\c" > /etc/sysctl.conf
	sysctl -p
	
	#reboot part
	echo -e "${Careful} after reboot, please running this command: ${Start}"
	stty erase '^H' && read -p "need to reboot, reboot now ? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
	echo -e "${Info} rebooting..."
	reboot
	fi

}

#check running tcp_nanqinlang or not
tcp_nanqinlang_status(){
	check_tcp_nanqinlang_status_on=`sysctl net.ipv4.tcp_available_congestion_control | awk '{print $3}'`
	if [ "${check_tcp_nanqinlang_status_on}" = "nanqinlang" ]; then
	echo -e "${Info} tcp_nanqinlang is installed!"
	    check_tcp_nanqinlang_status_off=`lsmod | grep nanqinlang`
	    if [ "${check_tcp_nanqinlang_status_off}" = "" ]; then
		    echo -e "${Failed} tcp_nanqinlang is installed but not running!"
	    else
		    echo -e "${Success} tcp_nanqinlang is running!"
	    fi
	fi
}

#start
start_tcp_nanqinlang(){
	check_deb
	cd /root/tcp_nanqinlang
	if [ -s tcp_nanqinlang.ko ]; then
		echo -e "${Info} mod has been saved, loading now"
		chmod +x ./tcp_nanqinlang.ko
	    insmod tcp_nanqinlang.ko
    else
	    wget https://raw.githubusercontent.com/sinderyminami/tcp_nanqinlang/master/tcp_nanqinlang.ko
		echo -e "${Info} mod is downloaded, loading now"
		chmod +x ./tcp_nanqinlang.ko
	    insmod tcp_nanqinlang.ko
	fi
    sysctl -p
	sleep 1s
	tcp_nanqinlang_status
}

#stop
stop_tcp_nanqinlang(){
	check_deb
	sed -i '/net\.ipv4\.tcp_congestion_control=nanqinlang/d' /etc/sysctl.conf
	rmmod tcp_nanqinlang.ko
	sysctl -p
	sleep 1s
	stty erase '^H' && read -p "need reboot to stop tcp_nanqinlang, reboot now? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
		if [[ $yn == [Yy] ]]; then
		echo -e "${Info} rebooting..."
		reboot
		fi
}

#status
status_tcp_nanqinlang(){
	check_deb
	tcp_nanqinlang_status
}

action=$1
[ -z $1 ] && action=install
case "$action" in
	install|start|stop|status)
	${action}_tcp_nanqinlang
	Dispaly_Selection
    ${action}_tcp_nanqinlang 2>&1 | tee /root/tcp_nanqinlang.log
	;;
esac
