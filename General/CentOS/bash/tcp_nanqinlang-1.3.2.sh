#!/bin/bash
Green_font="\033[32m" && Yellow_font="\033[33m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
echo -e "${Green_font}
#======================================================
# Project:  tcp_nanqinlang general
# Platform: --CentOS_6/7_64bit --KVM
# Version:  1.3.2
# Author:   nanqinlang
# Blog:     https://sometimesnaive.org
# Github:   https://github.com/nanqinlang
#======================================================${Font_suffix}"

check_system(){
	#sort
	[[ -z "`cat /etc/redhat-release | grep -iE "CentOS"`" ]] && echo -e "${Error} only support CentOS !" && exit 1
	#number
	[[ ! -z "`cat /etc/redhat-release | grep -iE " 7."`" ]] && bit=7
	[[ ! -z "`cat /etc/redhat-release | grep -iE " 6."`" ]] && bit=6
	#bit
	[[ "`uname -m`" != "x86_64" ]] && echo -e "${Error} only support 64bit !" && exit 1
}

check_root(){
	[[ "`id -u`" != "0" ]] && echo -e "${Error} must be root user !" && exit 1
}

check_kvm(){
	yum update
	yum install -y virt-what
	[[ "`virt-what`" != "kvm" ]] && echo -e "${Error} only support KVM !" && exit 1
}

directory(){
	[[ ! -d /home/tcp_nanqinlang ]] && mkdir -p /home/tcp_nanqinlang
	cd /home/tcp_nanqinlang
}

check_kernel(){
	# check 4.12.10 already installed or not
	already_image=`rpm -qa | grep kernel-4.12.10`
	already_devel=`rpm -qa | grep kernel-devel-4.12.10`
	already_headers=`rpm -qa | grep kernel-headers-4.12.10`

	delete_surplus_1

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

	update-grub

}

delete_surplus_1(){
	#surplus_image=`rpm -qa | grep kernel | awk '{print $2}' | grep -v "4.12.10" | wc -l`
	#surplus_devel=`rpm -qa | grep kernel-devel | awk '{print $2}' | grep -v "4.12.10" | wc -l`
	#surplus_headers=`rpm -qa | grep kernel-headers | awk '{print $2}' | grep -v "4.12.10" | wc -l`

	surplus_count=`rpm -qa | grep kernel | grep -v "4.12.10" | wc -l`
	surplus_sort_1=`rpm -qa | grep kernel | grep -v "4.12.10"`

	while [[ "${surplus_count}" > "1" ]]
	do
		yum remove -y ${surplus_sort_1}
		surplus_count=`rpm -qa | grep kernel | grep -v "4.12.10" | wc -l`
		surplus_sort_1=`rpm -qa | grep kernel | grep -v "4.12.10"`
	done
}

delete_surplus_2(){
	current=`uname -r | grep -v "4.12.10"`
	if [[ -z "${current}" ]]; then
		surplus_sort_2=`rpm -qa | grep kernel | grep -v "4.12.10" | grep -v "dracut-kernel-004-409.el6_8.2.noarch"`
		while [[ ! -z "${surplus_sort_2}" ]]
		do
			 yum remove -y ${surplus_sort_2}
			 surplus_sort_2=`rpm -qa | grep kernel | grep -v "4.12.10" | grep -v "dracut-kernel-004-409.el6_8.2.noarch"`
		done
	else
		echo -e "${Error} current running kernel is not v4.12.10, please check !"
	fi
}

# achieve
# http://elrepo.mirror.angkasa.id/elrepo/archive/kernel/el6/x86_64/RPMS/
# http://elrepo.mirror.angkasa.id/elrepo/archive/kernel/el7/x86_64/RPMS/
# my backup: https://github.com/nanqinlang/CentOS-kernel
install_image(){
	#[[ ! -f kernel-ml-4.12.10-1.el${bit}.elrepo.x86_64.rpm ]] && wget http://elrepo.mirror.angkasa.id/elrepo/archive/kernel/el${bit}/x86_64/RPMS/kernel-ml-4.12.10-1.el${bit}.elrepo.x86_64.rpm
	[[ ! -f kernel-ml-4.12.10-1.el${bit}.elrepo.x86_64.rpm ]] && wget https://raw.githubusercontent.com/tcp-nanqinlang/CentOS-kernel/master/kernel-ml-4.12.10-1.el${bit}.elrepo.x86_64.rpm
	[[ ! -f kernel-ml-4.12.10-1.el${bit}.elrepo.x86_64.rpm ]] && echo -e "${Error} ==image download failed, please check !" && exit 1
	yum  install -y kernel-ml-4.12.10-1.el${bit}.elrepo.x86_64.rpm
}
install_devel(){
	#[[ ! -f kernel-ml-devel-4.12.10-1.el${bit}.elrepo.x86_64.rpm ]] && wget http://elrepo.mirror.angkasa.id/elrepo/archive/kernel/el${bit}/x86_64/RPMS/kernel-ml-devel-4.12.10-1.el${bit}.elrepo.x86_64.rpm
	[[ ! -f kernel-ml-devel-4.12.10-1.el${bit}.elrepo.x86_64.rpm ]] && wget https://raw.githubusercontent.com/tcp-nanqinlang/CentOS-kernel/master/kernel-ml-devel-4.12.10-1.el${bit}.elrepo.x86_64.rpm
	[[ ! -f kernel-ml-devel-4.12.10-1.el${bit}.elrepo.x86_64.rpm ]] && echo -e "${Error} devel download failed, please check !" && exit 1
	yum  install -y kernel-ml-devel-4.12.10-1.el${bit}.elrepo.x86_64.rpm
}
install_headers(){
	#[[ ! -f kernel-ml-headers-4.12.10-1.el${bit}.elrepo.x86_64.rpm ]] && wget http://elrepo.mirror.angkasa.id/elrepo/archive/kernel/el${bit}/x86_64/RPMS/kernel-ml-headers-4.12.10-1.el${bit}.elrepo.x86_64.rpm
	[[ ! -f kernel-ml-headers-4.12.10-1.el${bit}.elrepo.x86_64.rpm ]] && wget https://raw.githubusercontent.com/tcp-nanqinlang/CentOS-kernel/master/kernel-ml-headers-4.12.10-1.el${bit}.elrepo.x86_64.rpm
	[[ ! -f kernel-ml-headers-4.12.10-1.el${bit}.elrepo.x86_64.rpm ]] && echo -e "${Error} headers download failed, please check !" && exit 1
	yum  install -y kernel-ml-headers-4.12.10-1.el${bit}.elrepo.x86_64.rpm
}

update-grub(){
	[[ "${bit}" = "7" ]] && grub2-mkconfig -o /boot/grub2/grub.cfg && grub2-set-default 0
	[[ "${bit}" = "6" ]] && sed -i '/default=/d' /boot/grub/grub.conf && echo -e "\ndefault=0\c" >> /boot/grub/grub.conf
}

rpm_list(){
	rpm -qa | grep kernel
}

maker(){
	yum groupinstall -y "Development Tools" && yum update
	[[ ! -e /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && compile
	[[ ! -e /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && echo -e "${Error} load mod failed, please check!" && exit 1
}

compile(){
	wget https://raw.githubusercontent.com/tcp-nanqinlang/general/master/General/CentOS/source/tcp_nanqinlang.c
	wget -O Makefile https://raw.githubusercontent.com/tcp-nanqinlang/general/master/Makefile/Makefile-CentOS
	make && make install
}

check_status(){
	#status_sysctl=`sysctl net.ipv4.tcp_available_congestion_control | awk '{print $3}'`
	#status_lsmod=`lsmod | grep nanqinlang`
	if [[ "`lsmod | grep nanqinlang`" != "" ]]; then
		echo -e "${Info} tcp_nanqinlang is installed !"
			if [[ "`sysctl net.ipv4.tcp_available_congestion_control | awk '{print $3}'`" = "nanqinlang" ]]; then
				 echo -e "${Info} tcp_nanqinlang is running !"
			else echo -e "${Error} tcp_nanqinlang is installed but not running !"
			fi
	else
		echo -e "${Error} tcp_nanqinlang not installed !"
	fi
}



###################################################################################################
install(){
	check_system
	check_root
	check_kvm
	directory
	check_kernel
	rpm_list
	echo -e "${Info} 请确认此行上面的列表显示的内核版本后，重启以应用新内核"
}

start(){
	check_system
	check_root
	check_kvm
	directory
	delete_surplus_2 && update-grub
	maker
	sed  -i '/net\.core\.default_qdisc/d' /etc/sysctl.conf
	sed  -i '/net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf
	echo -e "\nnet.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo -e "net.ipv4.tcp_congestion_control=nanqinlang\c" >> /etc/sysctl.conf
	sysctl -p
	check_status
	rm -rf /home/tcp_nanqinlang
}

status(){
	check_status
}

uninstall(){
	check_root
	sed -i '/net\.core\.default_qdisc=/d'          /etc/sysctl.conf
	sed -i '/net\.ipv4\.tcp_congestion_control=/d' /etc/sysctl.conf
	sysctl -p
	rm  /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko
	echo -e "${Info} please remember ${reboot} to stop tcp_nanqinlang !"
}

echo -e "${Info} 选择你要使用的功能: "
echo -e "1.安装内核\n2.开启算法\n3.检查算法运行状态\n4.卸载算法"
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