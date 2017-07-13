基于拥塞控制技术 Tcp_bbr (在此由衷感谢各位开发者大佬们)

清真 膜改BBR by 南琴浪

魔改源码 tcp_nanqinlang.c

魔改模块 tcp_nanqinlang.ko github这里的模块基于kernel v4.11.0编译 如果不是此版本内核更建议自行编译 且脚本里已自带编译

一键脚本v1.1.0 tcp_nanqinlang.sh

适用于Debian /Ubuntu

command: { install | start | status | upgrade | stop }

1.安装内核 bash tcp_nanqinlang.sh install

2.启用算法 bash tcp_nanqinlang.sh start

3.运行状态 bash tcp_nanqinlang.sh status

4.更新内核 bash tcp_nanqinlang.sh upgrade

5.停用算法 bash tcp_nanqinlang.sh stop

具体更新请参考releases: https://github.com/nanqinlang/tcp_nanqinlang/releases

explanation:

每次运行脚本后，会生成日志文件 /root/tcp_nanqinlang.log

运行 install 过程中 会创建 /root/tcp_nanqinlang 并下载 三个deb: image / headers.amd64或i386 / headers.all

运行 install 过程中 sysctl.conf 覆盖为 我在脚本内预置的 /etc/sysctl.conf

运行 start   过程中 会在 /root/tcp_nanqinlang 编译模块, 并自动接 status 判断是否编译成功并加载

运行 stop    过程后 并不会删除已安装的内核，仅 移除sysctl.conf里设置的tcp_nanqinlang + 删除/root/tcp_nanqinlang，reboot后模块停止运行

若有疑惑/Bug反馈等 请联系我或者issue

博客https://www.nanqinlang.com

邮箱administration@nanqinlang.com

Telegram@KotoriHusband

twitter@SinderyMinami

ps:汉纸,不欢迎撩(#阴险)
