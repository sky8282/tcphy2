#!/bin/bash
RED="\\e[31m"
GREEN="\\e[32m"
BLUE="\\e[34m"
RESET="\\e[0m"

DEFAULT_PING_TARGET="667515.iask.in"
IPERF3_SERVERS=(
  "667515.iask.in"
  "iperf.he.net"
  "iperf.volia.net"
  "iperf.scottlinux.com"
  "bouygues.testdebit.info"
  "iperf3.par2.as49434.net"
  "iperf.worldstream.nl"
  "iperf.biznetnetworks.com"
)

divider() {
  echo -e "${BLUE}#######################################${RESET}"
}

# ========================
# 安装依赖
# ========================
install_dependencies() {
  for dep in jq iperf3 bc; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y "$dep"
    fi
  done
}

# ========================
# 目标服务器 Ping 测试
# ========================
prompt_ping_target() {
  echo -n "请输入需要测试 Ping 的目标服务器 [默认 $DEFAULT_PING_TARGET]: "
  read -r PING_TARGET
  PING_TARGET=${PING_TARGET:-$DEFAULT_PING_TARGET}
  echo -e "Ping ${GREEN}$PING_TARGET${RESET}"
}

test_ping() {
  RTT=$(ping -c 4 "$PING_TARGET" | tail -1 | awk -F '/' '{print $5}')
  if [[ -z "$RTT" ]]; then
    RTT=9999
    echo -e "${RED}Ping 测试失败，请检查网络连接。${RESET}"
  else
    printf "Ping 延迟 (RTT): ${GREEN}%.3f ms${RESET}\n" "$RTT"
  fi
}

# ========================
# 生成配置文件
# ========================
generate_config() {
  local profile="$1"
  case $profile in
    1)
      cat <<EOF
# 参数集 1
# 接收和发送缓冲区大小
# 1MB
net.core.rmem_max=1048576
# 512KB
net.core.rmem_default=524288
net.ipv4.tcp_rmem=4096 87380 1048576
# 1MB
net.core.wmem_max=1048576
# 512KB
net.core.wmem_default=524288
net.ipv4.tcp_wmem=4096 87380 1048576
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 减小网络队列，适应较低带宽
net.core.netdev_max_backlog=100000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    2)
      cat <<EOF
# 参数集 2
# 接收和发送缓冲区大小
# 2MB
net.core.rmem_max=2097152
# 1MB
net.core.rmem_default=1048576
net.ipv4.tcp_rmem=4096 87380 2097152
# 2MB
net.core.wmem_max=2097152
# 1MB
net.core.wmem_default=1048576
net.ipv4.tcp_wmem=4096 87380 2097152
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 减小网络队列，适应较低带宽
net.core.netdev_max_backlog=100000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    3)
      cat <<EOF
# 参数集 3
# 接收和发送缓冲区大小
# 3MB
net.core.rmem_max=3145728
# 2MB
net.core.rmem_default=2097152
net.ipv4.tcp_rmem=4096 87380 3145728
# 3MB
net.core.wmem_max=3145728
# 2MB
net.core.wmem_default=2097152
net.ipv4.tcp_wmem=4096 87380 3145728
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    4)
      cat <<EOF
# 参数集 4
# 接收和发送缓冲区大小
# 4MB
net.core.rmem_max=4194304
# 2MB
net.core.rmem_default=2097152
net.ipv4.tcp_rmem=4096 87380 4194304
# 4MB
net.core.wmem_max=4194304
# 2MB
net.core.wmem_default=2097152
net.ipv4.tcp_wmem=4096 87380 4194304
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    5)
      cat <<EOF
# 参数集 5
# 接收和发送缓冲区大小
# 5MB
net.core.rmem_max=5242880
# 3MB
net.core.rmem_default=3145728
net.ipv4.tcp_rmem=4096 87380 5242880
# 5MB
net.core.wmem_max=5242880
# 3MB
net.core.wmem_default=3145728
net.ipv4.tcp_wmem=4096 87380 5242880
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    6)
      cat <<EOF
# 参数集 6
# 接收和发送缓冲区大小
# 6MB
net.core.rmem_max=6291456
# 4MB
net.core.rmem_default=4194304
net.ipv4.tcp_rmem=4096 87380 6291456
# 6MB
net.core.wmem_max=6291456
# 4MB
net.core.wmem_default=4194304
net.ipv4.tcp_wmem=4096 87380 6291456
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    7)
      cat <<EOF
# 参数集 7
# 接收和发送缓冲区大小
# 7MB
net.core.rmem_max=7340032
# 5MB
net.core.rmem_default=5242880
net.ipv4.tcp_rmem=4096 87380 7340032
# 7MB
net.core.wmem_max=7340032
# 5MB
net.core.wmem_default=5242880
net.ipv4.tcp_wmem=4096 87380 7340032
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    8)
      cat <<EOF
# 参数集 8
# 接收和发送缓冲区大小
# 8MB
net.core.rmem_max=8388608
# 4MB
net.core.rmem_default=4194304
net.ipv4.tcp_rmem=4096 87380 8388608
# 8MB
net.core.wmem_max=8388608
# 4MB
net.core.wmem_default=4194304
net.ipv4.tcp_wmem=4096 87380 8388608
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    9)
      cat <<EOF
# 参数集 9
# 接收和发送缓冲区大小
# 9MB
net.core.rmem_max=9437184
# 5MB
net.core.rmem_default=5242880
net.ipv4.tcp_rmem=4096 87380 9437184
# 9MB
net.core.wmem_max=9437184
# 5MB
net.core.wmem_default=5242880
net.ipv4.tcp_wmem=4096 87380 9437184
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    10)
      cat <<EOF
# 参数集 10
# 接收和发送缓冲区大小
# 10MB
net.core.rmem_max=10485760
# 5MB
net.core.rmem_default=5242880
net.ipv4.tcp_rmem=4096 87380 10485760
# 10MB
net.core.wmem_max=10485760
# 5MB
net.core.wmem_default=5242880
net.ipv4.tcp_wmem=4096 87380 10485760
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    11)
      cat <<EOF
# 参数集 11
# 接收和发送缓冲区大小
# 11MB
net.core.rmem_max=11534336
# 6MB
net.core.rmem_default=6291456
net.ipv4.tcp_rmem=4096 87380 11534336
# 11MB
net.core.wmem_max=11534336
# 6MB
net.core.wmem_default=6291456
net.ipv4.tcp_wmem=4096 87380 11534336
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    12)
      cat <<EOF
# 参数集 12
# 接收和发送缓冲区大小
# 12MB
net.core.rmem_max=12582912
# 6MB
net.core.rmem_default=6291456
net.ipv4.tcp_rmem=4096 87380 12582912
# 12MB
net.core.wmem_max=12582912
# 6MB
net.core.wmem_default=6291456
net.ipv4.tcp_wmem=4096 87380 12582912
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    13)
      cat <<EOF
# 参数集 13
# 接收和发送缓冲区大小
# 13MB
net.core.rmem_max=13631488
# 7MB
net.core.rmem_default=7340032
net.ipv4.tcp_rmem=4096 87380 13631488
# 13MB
net.core.wmem_max=13631488
# 7MB
net.core.wmem_default=7340032
net.ipv4.tcp_wmem=4096 87380 13631488
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    14)
      cat <<EOF
# 参数集 14
# 接收和发送缓冲区大小
# 14MB
net.core.rmem_max=14680064
# 7MB
net.core.rmem_default=7340032
net.ipv4.tcp_rmem=4096 87380 14680064
# 14MB
net.core.wmem_max=14680064
# 7MB
net.core.wmem_default=7340032
net.ipv4.tcp_wmem=4096 87380 14680064
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    15)
      cat <<EOF
# 参数集 15
# 接收和发送缓冲区大小
# 15MB
net.core.rmem_max=15728640
# 8MB
net.core.rmem_default=8388608
net.ipv4.tcp_rmem=4096 87380 15728640
# 15MB
net.core.wmem_max=15728640
# 8MB
net.core.wmem_default=8388608
net.ipv4.tcp_wmem=4096 87380 15728640
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    16)
      cat <<EOF
# 参数集 16
# 接收和发送缓冲区大小
# 16MB
net.core.rmem_max=16777216
# 8MB
net.core.rmem_default=8388608
net.ipv4.tcp_rmem=4096 87380 16777216
# 16MB
net.core.wmem_max=16777216
# 8MB
net.core.wmem_default=8388608
net.ipv4.tcp_wmem=4096 87380 16777216
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    24)
      cat <<EOF
# 参数集 24
# 接收和发送缓冲区大小
# 24MB
net.core.rmem_max=25165824
# 12MB
net.core.rmem_default=12582912
net.ipv4.tcp_rmem=4096 87380 25165824
# 24MB
net.core.wmem_max=25165824
# 12MB
net.core.wmem_default=12582912
net.ipv4.tcp_wmem=4096 87380 25165824
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    32)
      cat <<EOF
# 参数集 32
# 接收和发送缓冲区大小
# 32MB
net.core.rmem_max=33554432
# 16MB
net.core.rmem_default=16777216
net.ipv4.tcp_rmem=4096 87380 33554432
# 32MB
net.core.wmem_max=33554432
# 16MB
net.core.wmem_default=16777216
net.ipv4.tcp_wmem=4096 87380 33554432
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    64)
      cat <<EOF
# 参数集 64
# 接收和发送缓冲区大小
# 64MB
net.core.rmem_max=67108864
# 32MB
net.core.rmem_default=33554432
net.ipv4.tcp_rmem=4096 87380 67108864
# 64MB
net.core.wmem_max=67108864
# 32MB
net.core.wmem_default=33554432
net.ipv4.tcp_wmem=4096 87380 67108864
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    128)
      cat <<EOF
# 参数集 128
# 接收和发送缓冲区大小
# 128MB
net.core.rmem_max=134217728
# 64MB
net.core.rmem_default=67108864
net.ipv4.tcp_rmem=4096 87380 134217728
# 128MB
net.core.wmem_max=134217728
# 64MB
net.core.wmem_default=67108864
net.ipv4.tcp_wmem=4096 87380 134217728
#udp内存管理
net.ipv4.udp_mem=2097152 3145728 4194304
# 增大网络队列，适应高带宽
net.core.netdev_max_backlog=500000
net.core.somaxconn=65535
# MTU探测和ECN
net.ipv4.tcp_mtu_probing=1
# 可选，如果需要缓解高丢包率 1开启，0关闭
net.ipv4.tcp_ecn=1
# 系统文件描述符和端口范围
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
# SYN队列和重试优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
# 增加重试次数，适应较高延迟环境
net.ipv4.tcp_retries2=8
# 拥塞控制算法 (可改为c換bic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=0
#TCP 快速打开 (TCP Fast Open)，减少连接握手延迟：
net.ipv4.tcp_fastopen=1
# 避免闲置连接进入慢启动
net.ipv4.tcp_slow_start_after_idle=0
EOF
      ;;
    129)
      cat <<EOF
# 参数集 129
# 接收和发送缓冲区大小
net.core.rmem_max=33554432
net.core.rmem_default=33554432
net.ipv4.tcp_rmem=4096 87380 33554432

net.core.wmem_max=33554432
net.core.wmem_default=33554432
net.ipv4.tcp_wmem=4096 87380 33554432

net.core.netdev_max_backlog=250000
net.core.somaxconn=65535

#net.core.netdev_max_backlog=100000
#net.core.somaxconn=4096  

# 拥塞控制算法 (可改为cubic测试)
net.ipv4.tcp_congestion_control=bbr
# 开启MTU探测以优化路径 1默认，2强制
net.ipv4.tcp_mtu_probing=1
# 开启ECN，缓解高丢包率
net.ipv4.tcp_ecn=1

# 系统文件描述符限制（为高并发做准备）
# 最大文件描述符数
fs.file-max=2097152
  # 本地端口范围
net.ipv4.ip_local_port_range=1024 65535

# SYN队列和重试优化
# 启用SYN Cookies防御SYN Flood攻击
net.ipv4.tcp_syncookies=1
# SYN队列长度
net.ipv4.tcp_max_syn_backlog=262144
# SYN重试次数
net.ipv4.tcp_syn_retries=2
# SYN+ACK重试次数
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_retries2=5
# sudo sysctl -p

EOF
      ;;
  esac
}

# ========================
# 应用配置
# ========================
apply_sysctl_config() {
  local config="$1"
  local profile="$2"
  echo "写入优化后的配置并生效..."
  echo "$config" | sudo tee /etc/sysctl.conf > /dev/null
  if sudo sysctl -p > /dev/null 2>&1; then
    echo -e "${GREEN}配置已生效！${RESET}"
    echo -e "${GREEN}TCP 参数集 $profile 优化完成${RESET}"
  else
    echo -e "${RED}配置应用失败，请检查权限或配置文件格式。${RESET}"
  fi
}

# ========================
# iPerf3 测速
# ========================
run_iperf3_test() {
  divider
  echo "可选服务器列表："
  for i in "${!IPERF3_SERVERS[@]}"; do
    echo "$i) ${IPERF3_SERVERS[$i]}"
  done
  echo -n "请输入对应的序号 [默认 0]: "
  read -r server_choice
  server_choice=${server_choice:-0}
  local server=${IPERF3_SERVERS[$server_choice]}
  echo "测速中，请稍候..."
  iperf3 -c "$server" -p 5201 -t 10
}

# ========================
# 自动选择优化方案
# ========================
select_rtt_and_optimize() {
  divider
  echo "请选择你的网络延迟范围："
  echo "0)   返回上一层菜单"
  echo "1)   ping ≤ 100ms   (参数集 1)"
  echo "2)   ping ≤ 150ms   (参数集 2)"
  echo "3)   ping ≤ 200ms   (参数集 3)"
  echo "4)   ping ≤ 250ms   (参数集 4)"
  echo "5)   ping ≤ 300ms   (参数集 5)"
  echo "6)   ping ≤ 350ms   (参数集 6)"
  echo "7)   ping ≤ 400ms   (参数集 7)"
  echo "8)   ping ≤ 450ms   (参数集 8)"
  echo "9)   ping ≤ 500ms   (参数集 9)"
  echo "10)  ping ≤ 550ms   (参数集 10)"
  echo "11)  ping ≤ 600ms   (参数集 11)"
  echo "12)  ping ≤ 650ms   (参数集 12)"
  echo "13)  ping ≤ 700ms   (参数集 13)"
  echo "14)  ping ≤ 750ms   (参数集 14)"
  echo "15)  ping ≤ 800ms   (参数集 15)"
  echo "16)  ping ≤ 850ms   (参数集 16)"
  echo "24)  ping ≤ 900ms   (参数集 24)"
  echo "32)  ping ≤ 950ms   (参数集 32)"
  echo "64)  ping ≤ 1000ms  (参数集 64)"
  echo "128) ping > 1000ms  (参数集 128)"
  echo "129) 大众化          (参数集 129)"
  echo -n "请输入选项 [0-129]: "
  read -r choice

  case $choice in
    1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|24|32|64|128|129) optimize_tcp $choice ;;
    0) main_menu ;;
    *) echo -e "${RED}错误：参数集 $choice 不存在！请从支持的选项中选择（1-16, 24, 32, 64, 128，129）。${RESET}" && main_menu ;;
  esac
}

# ========================
# 进行优化
# ========================
optimize_tcp() {
  local profile="$1"
  local conf
  conf=$(generate_config "$profile")
  if [[ -z "$conf" ]]; then
    echo -e "${RED}错误：无法生成参数集 $profile 的配置！${RESET}"
    main_menu
  fi
  apply_sysctl_config "$conf" "$profile"

  echo -n "是否要测速？[y/n, 默认n]: "
  read -r choice
  [[ "$choice" == "y" ]] && run_iperf3_test
}

# ========================
# 主菜单
# ========================
main_menu() {
  divider
  echo "选择优化方式："
  echo "0) 退出"
  echo "1) 根据Ping值选择参数集"
  echo "2) 手动选择参数集"
  divider
  echo -n "请输入选项 [0/1/2, 默认 2]: "
  read -r opt_mode
  opt_mode=${opt_mode:-2}

  case $opt_mode in
    0) exit 0 ;;
    1) prompt_ping_target; test_ping; select_rtt_and_optimize ;;
    2) divider
       echo "0) 返回上一层菜单"
       echo "1)   低延迟网络 (参数集 1, 1MB)"
       echo "2)   中延迟网络 (参数集 2, 2MB)"
       echo "3)   高延迟网络 (参数集 3, 3MB)"
       echo "4)   高延迟网络 (参数集 4, 4MB)"
       echo "5)   高延迟网络 (参数集 5, 5MB)"
       echo "6)   高延迟网络 (参数集 6, 6MB)"
       echo "7)   高延迟网络 (参数集 7, 7MB)"
       echo "8)   高延迟网络 (参数集 8, 8MB)"
       echo "9)   高延迟网络 (参数集 9, 9MB)"
       echo "10)  高延迟网络 (参数集 10, 10MB)"
       echo "11)  高延迟网络 (参数集 11, 11MB)"
       echo "12)  高延迟网络 (参数集 12, 12MB)"
       echo "13)  高延迟网络 (参数集 13, 13MB)"
       echo "14)  高延迟网络 (参数集 14, 14MB)"
       echo "15)  高延迟网络 (参数集 15, 15MB)"
       echo "16)  高延迟网络 (参数集 16, 16MB)"
       echo "24)  高延迟网络 (参数集 24, 24MB)"
       echo "32)  高延迟网络 (参数集 32, 32MB)"
       echo "64)  高延迟网络 (参数集 64, 64MB)"
       echo "128) 高延迟网络 (参数集 128, 128MB)"
       echo "129) 大众化选择 (参数集 129)"
       divider
       echo -n "请选择 [0-129]: "
       read -r choice
       [[ "$choice" == "0" ]] && main_menu
       case $choice in
         1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|24|32|64|128|129) optimize_tcp "$choice" ;;
         *) echo -e "${RED}错误：参数集 $choice 不存在！请从支持的选项中选择（1-16, 24, 32, 64, 128，129）。${RESET}" && main_menu ;;
       esac
       ;;
    *) echo -e "${RED}无效选择，返回主菜单。${RESET}" && main_menu ;;
  esac
}

install_dependencies
main_menu