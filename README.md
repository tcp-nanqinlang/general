基于拥塞控制技术 Tcp_bbr (在此由衷感谢原作者等开发者大佬们)

稍微温和点的 魔改BBR by 南琴浪

魔改源码 tcp_nanqinlang.c

魔改模块 tcp_nanqinlang.ko

模块和脚本基于 Debian Kernel Version v4.11.0

tcp_nanqinlang.sh 一键脚本 1.0beta

适用于Debian 7+/Ubuntu 14+

请注意1.0版本目前install功能仅提供v4.11.0版本内核安装 请留意自己的系统是否支持该版本 后续更新会提供版本自定义

用法:

wget https://raw.githubusercontent.com/sinderyminami/tcp_nanqinlang/master/tcp_nanqinlang.sh && bash tcp_nanqinlang.sh ${command}

command: { install | start | stop | status }

1.安装内核 bash tcp_nanqinlang.sh install

2.启用算法 bash tcp_nanqinlang.sh start

3.运行状态 bash tcp_nanqinlang.sh status

4.停用算法 bash tcp_nanqinlang.sh stop

说明:

每次运行脚本后，会生成日志文件 /root/tcp_nanqinlang.log，每次运行会覆盖之前的log，日志主要作为调试参考

运行 install 过程中 会创建 /root/tcp_nanqinlang 并下载 三个内核包: image / headers.amd64或i386 / headers.all

运行 install 过程中 sysctl.conf会覆盖为我在脚本内预置的 /etc/sysctl.conf

运行 start   过程中 会将 tcp_nanqinlang.ko 放到 /root/tcp_nanqinlang 并加载该模块, 随后可使用 status 命令判断是否成功启用

运行 stop    过程后 并不会删除已安装的内核，只是移除了sysctl.conf里设置的tcp_nanqinlang

若有疑惑/Bug反馈等请联系我或者issue

博客https://www.nanqinlang.com

邮箱administration@nanqinlang.com

Telegram@KotoriHusband

twitter@SinderyMinami
