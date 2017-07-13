#! /bin/bash

Green_font="\033[32m" && Yellow_font="\033[33m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Success="${Green_font}[Success]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
Failed="${Red_font}[Failed]${Font_suffix}"
Careful="${Green_font}[Be Careful]${Font_suffix}"
reboot="${Yellow_font}reboot${Font_suffix}"
Install="${Yellow_font}bash tcp_nanqinlang.sh install${Font_suffix}"
Start="${Yellow_font}bash tcp_nanqinlang.sh start${Font_suffix}"

echo -e "${Yellow_font}
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

#delete image
del_image(){
	total_image=`dpkg -l | grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | wc -l`
	if [ "${total_image}" > "1" ]; then
		echo -e "${Info} find ${total_image} other kernel, uninstalling"
		for((integer = 1; integer <= ${total_image}; integer++))
		do
			surplus_image=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | head -${integer}`
			echo -e "${Info} uninstalling ${surplus_image}"
			apt-get purge -y ${surplus_image}
			echo -e "${Success} uninstall ${surplus_image} successfully, continuing"
		done
		if [ "${total_image}" = "0" ]; then
			echo -e "${Success} uninstall successfully, continuing"
		else
			echo -e "${Failed} uninstall failed, please check!" && exit 1
		fi
	else
	echo -e "${Error} check kernel failed, please check!" && exit 1
	fi
}


#delete headers
del_headers(){
	total_headers=`dpkg -l | grep linux-headers | awk '{print $2}' | grep -v "${latest_version}" | wc -l`
	if [ "${total_headers}" > "1" ]; then
		echo -e "${Info} find ${total_headers} other kernel, uninstalling"
		for((integer = 1; integer <= ${total_headers}; integer++))
		do
			surplus_headers=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${latest_version}" | head -${integer}`
			echo -e "${Info} uninstalling ${surplus_headers}"
			apt-get purge -y ${surplus_headers}
			echo -e "${Success} uninstall ${surplus_headers} successfully, continuing"
		done
		if [ "${total_headers}" = "0" ]; then
			echo -e "${Success} uninstall successfully, continuing"
		else
			echo -e "${Failed} uninstall failed, please check!" && exit 1
		fi
	else
	echo -e "${Error} check kernel failed, please check!" && exit 1
	fi
}

#get latest address
get_latest_version(){
	echo -e "${Info} getting latest version"
	latest_version=$(wget -qO- "http://kernel.ubuntu.com/~kernel-ppa/mainline/" | awk -F'\"v' '/v[4-9].[0-9]*.[0-9]/{print $2}' |grep -v '\-rc'| cut -d/ -f1 | sort -V | tail -1)
	[[ -z ${latest_version} ]] && echo -e "${error} fail to get latest version !" && exit 1
	echo -e "${Info} latest version is : ${Green_font}${latest_version}${Font_suffix}"
}
get_latest_kernel(){
	bit=`uname -m`
	if [[ ${bit} == "x86_64" ]]; then
		image_name=$(wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-image" | grep "lowlatency" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1)
		image_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${image_name}"
		headers_name_1=$(wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-headers" | grep "lowlatency" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1)
		headers_url_1="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${headers_name_1}"
		headers_name_2=$(wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-headers" | awk -F'\">' '/all.deb/{print $2}' | cut -d'<' -f1 | head -1)
		headers_url_2="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${headers_name_2}"
	elif [ ${bit} == "i386" ]; then
		image_name=$(wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-image" | grep "lowlatency" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1)
		image_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${image_name}"
		headers_name_1=$(wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-headers" | grep "lowlatency" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1)
		headers_url_1="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${headers_name_1}"
		headers_name_2=$(wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-headers" | awk -F'\">' '/all.deb/{print $2}' | cut -d'<' -f1 | head -1)
		headers_url_2="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${headers_name_2}"
	else
		echo -e "${Error} not support ${bit} !" && exit 1
	fi
}

install_image(){
    mkdir /root/tcp_nanqinlang
    cd /root/tcp_nanqinlang
	wget ${image_url}
	if [ -s ${image_name} ]; then
		echo -e "${Success} image download successfully, installing"
		dpkg -i ${image_name}
	else
	echo -e "${Failed} image download failed, please check!" && exit 1
    fi
}
install_headers(){
	mkdir /root/tcp_nanqinlang
    cd /root/tcp_nanqinlang
	wget ${headers_url_1}
	if [ -s ${headers_name_1} ]; then
		echo -e "${Success} headers_bit download successfully, installing"
		dpkg -i ${headers_name_1}
	else
	echo -e "${Failed} headers_bit download failed, please check!" && exit 1
    fi
	
	wget ${headers_url_2}
	if [ -s ${headers_name_2} ]; then
		echo -e "${Success} headers_all download successfully, installing"
		dpkg -i ${headers_name_2}
	else
	echo -e "${Failed} headers_all download failed, please check!" && exit 1
    fi
}

#check kernel
check_kernel(){
	get_latest_version
	image=`dpkg -l|grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep '[4-9].[0-9]*.'`
	if [[ "${image}" != "" ]]; then
		if [[ "${image}" == "${latest_version}" ]]; then
			echo -e "${Info} image is already latest" && exit 0
		else
			echo -e "image is not latest, will ugrade your image" && install_image
		fi
	else
	echo -e "${Error} check image failed, please check again!" && exit 1
	fi
	headers=`dpkg -l|grep linux-headers | awk '{print $2}' | awk -F '-' '{print $3}' | grep '[4-9].[0-9]*.'`
	if [[ "${headers}" != "" ]]; then
		if [[ "${headers}" == "${latest_version}" ]]; then
			echo -e "${Info} headers is already latest" && exit 0
		else
			echo -e "headers is not latest, will ugrade your headers" && install_headers
		fi
	else
	echo -e "${Error} check headers failed, please check again!" && exit 1
	fi
}

#check status
check_status(){
	status_sysctl=`sysctl net.ipv4.tcp_available_congestion_control | awk '{print $3}'`
	if [ "${status_sysctl}" = "nanqinlang" ]; then
	echo -e "${Info} tcp_nanqinlang is installed!"
	    status_lsmod=`lsmod | grep nanqinlang`
	    if [ "${status_lsmod}" = "" ]; then
		    echo -e "${Info} tcp_nanqinlang is installed but not running, please ${reboot} and run ${Start}"
	    else
		    echo -e "${Success} tcp_nanqinlang is running!" && exit 0
	    fi
	else
	echo -e "${Error} tcp_nanqinlang not installed, please ${Install} and try start anain" && exit 1
	fi
}

#install
install_tcp_nanqinlang(){
	
	#run check system and determine it's bebian/ubuntu or not
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
	
    #determine it is ${latest_version} or not and remove surplus kernel
	get_latest_version
    get_latest_kernel
	#kernel version = ${latest_version}
	surplus_ver_image="`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${latest_version}"`"
	surplus_ver_headers="`dpkg -l | grep linux-headers | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${latest_version}"`"
	#total digit of kernel without ${latest_version}
	surplus_total_image="`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | wc -l`"
	surplus_total_headers="`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${latest_version}" | wc -l`"
	
	if [ ${surplus_ver_image} == "${latest_version}" ]; then
	echo -e "${Info} image already have a latest version"
		   if [ ${surplus_total_image} != "0" ]; then
		   echo -e "${Info} removing surplus image" && del_image
		          if [ ${surplus_ver_headers} == "${latest_version}" ]; then
				  echo -e "${Info} headers already have a latest version"
				         if [ ${surplus_total_headers} != "0" ]; then
						 echo -e "${Info} removing surplus headers" && del_headers
						 else echo -e "${Info} no surplus headers need to remove"
						 fi
				  else echo -e "${Info} installing latest headers" && install_headers
				  fi
		   else echo -e "${Info} no surplus image need to remove"
		   fi
	else echo -e "${Info} installing latest image" && install_image
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
	echo -e "${Careful} please remember after ${reboot}, run ${Start}"
  exit 0
}

#start
start_tcp_nanqinlang(){
	cd /root/tcp_nanqinlang
	wget https://raw.githubusercontent.com/nanqinlang/tcp_nanqinlang/master/tcp_nanqinlang.c
    echo -e "${Info} code is downloaded, making now"
	apt-get update && apt-get install build-essential -y && apt-get update && apt-get install gcc-4.9 make git python -y && apt-get update
	echo "obj-m:=tcp_nanqinlang.o" > Makefile
    make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc-4.9
	if [ -s tcp_nanqinlang.ko ]; then
         echo -e "${Info} mod is made, loading now"
	     chmod +x ./tcp_nanqinlang.ko
		 insmod tcp_nanqinlang.ko
         sysctl -p
	else echo -e "${Failed} mod made failed, please check!" && exit 1
	fi
    check_status
	exit 0
}

#status
status_tcp_nanqinlang(){
	check_status
	exit 0
}

#upgrade
upgrade_tcp_nanqinlang(){
    get_latest_version
    get_latest_kernel
	check_kernel
	exit 0
}

#stop
stop_tcp_nanqinlang(){
	sed -i '/net\.ipv4\.tcp_congestion_control=nanqinlang/d' /etc/sysctl.conf
	sysctl -p
	rm -rf /root/tcp_nanqinlang
	echo -e "${Info} please remember ${reboot} to stop tcp_nanqinlang"
	exit 0
}

action=$1
[ -z $1 ] && action=install
case "$action" in
	install|start|status|upgrade|stop)
	${action}_tcp_nanqinlang
    ${action}_tcp_nanqinlang 2>&1 | tee /root/tcp_nanqinlang.log
	;;
esac
