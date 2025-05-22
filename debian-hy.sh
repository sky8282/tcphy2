#!/bin/bash

# 官方默认参数为基准参数
BASE_INIT_STREAM=26843545
BASE_MAX_STREAM=26843545
BASE_INIT_CONN=67108864
BASE_MAX_CONN=67108864

# 计算偏移量
FACTOR=1342177            # 26843545 / 20
FACTOR_CONN=$((FACTOR * 5 / 2)) # 避免浮点运算，先乘5再除2，结果是3355442

# 从现有的 config.yaml 中读取端口、密码、cert、key
if [ -f /etc/hysteria/config.yaml ]; then
    PORT=$(grep -E '^listen:' /etc/hysteria/config.yaml | awk '{print $2}' | sed 's/://g')
    PASSWORD=$(grep -E '^\s+password:' /etc/hysteria/config.yaml | awk '{print $2}')
    CERT_PATH=$(grep -E '^\s+cert:' /etc/hysteria/config.yaml | awk '{print $2}')
    KEY_PATH=$(grep -E '^\s+key:' /etc/hysteria/config.yaml | awk '{print $2}')
else
    echo "未找到 /etc/hysteria/config.yaml 文件，请检查是否安装了hy2"
    echo "适用 debian 的hy2脚本："
    echo "wget -N --no-check-certificate https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh && bash hysteria.sh"
    echo ""
    exit 1
fi

# 如果读取失败，提供默认值
PORT=${PORT:-12345}
PASSWORD=${PASSWORD:-"666666"}
CERT_PATH=${CERT_PATH:-/etc/hysteria/cert.crt}
KEY_PATH=${KEY_PATH:-/etc/hysteria/private.key}

# 定义参数映射
declare -A PARAMS
for i in $(seq -19 50); do
    initStream=$((BASE_INIT_STREAM + i * FACTOR))
    maxStream=$((BASE_MAX_STREAM + i * FACTOR))
    initConn=$((BASE_INIT_CONN + i * FACTOR_CONN))
    maxConn=$((BASE_MAX_CONN + i * FACTOR_CONN))
    PARAMS[$i]="$initStream $maxStream $initConn $maxConn"
done

# 颜色代码
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 显示菜单
echo -e "${GREEN}—————————————————————————————————————————————————————————————————${NC}"
echo -e "${GREEN}-- 默认参数上调配置,最高可选+50 --${NC}"
COUNT=0
for i in $(seq 1 10); do
    printf " %-12s" "参数 +$i"
    COUNT=$((COUNT + 1))
    if [ $((COUNT % 5)) -eq 0 ]; then
        echo ""
    fi
done

echo -e "${GREEN}—————————————————————————————————————————————————————————————————${NC}"
echo -e " ${GREEN}参数 0 (官方默认)${NC}                 "

echo -e "${GREEN}—————————————————————————————————————————————————————————————————${NC}"
echo -e "${GREEN}-- 默认参数下调配置,最高可选-19 --${NC}"
COUNT=0
for i in $(seq -1 -1 -10); do
    printf " %-12s" "参数 $i"
    COUNT=$((COUNT + 1))
    if [ $((COUNT % 5)) -eq 0 ]; then
        echo ""
    fi
done
echo -e "${GREEN}—————————————————————————————————————————————————————————————————${NC}"
echo -e "${GREEN} 适用 Debian 的hy脚本 ${NC}"
echo -e "${GREEN} wget -N --no-check-certificate https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh && bash hysteria.sh ${NC}"
echo -e "${GREEN} 以官方默认参数为基准进行2/5倍比例上下微调${NC}"
echo -e "${GREEN}—————————————————————————————————————————————————————————————————${NC}"

read -p " 请输入你的选择,例如 -1, 0, 1，(0为官方默认): " selection

if [[ ! ${PARAMS[$selection]+_} ]]; then
    echo -e "${RED}无效的选择，请重新运行脚本。${NC}"
    exit 1
fi

read initStream maxStream initConn maxConn <<< ${PARAMS[$selection]}

echo -e "${GREEN}您选择的quic参数配置为:${NC}"
echo -e "${GREEN}initStreamReceiveWindow: $initStream${NC}"
echo -e "${GREEN}maxStreamReceiveWindow: $maxStream${NC}"
echo -e "${GREEN}initConnReceiveWindow: $initConn${NC}"
echo -e "${GREEN}maxConnReceiveWindow: $maxConn${NC}"
#echo -e "${GREEN}端口: $PORT${NC}"
#echo -e "${GREEN}密码: $PASSWORD${NC}"
#echo -e "${GREEN}证书路径: $CERT_PATH${NC}"
#echo -e "${GREEN}密钥路径: $KEY_PATH${NC}"
echo -e ""


# 写入前备份原配置文件（覆盖 .bak）
if [ -f /etc/hysteria/config.yaml ]; then
    sudo cp /etc/hysteria/config.yaml /etc/hysteria/config.yaml.bak
    echo -e "原配置文件已备份为 /etc/hysteria/config.yaml.bak "
fi

# 写入配置
sudo tee /etc/hysteria/config.yaml > /dev/null <<EOF
listen: :$PORT

tls:
  cert: $CERT_PATH
  key: $KEY_PATH

quic:
  initStreamReceiveWindow: $initStream
  maxStreamReceiveWindow: $maxStream
  initConnReceiveWindow: $initConn
  maxConnReceiveWindow: $maxConn
  maxConnClient: 64
auth:
  type: password
  password: $PASSWORD

masquerade:
  type: proxy
  proxy:
    url: https://maimai.sega.jp
    rewriteHost: true
EOF

echo "配置已写入 /etc/hysteria/config.yaml"

echo "尝试重启 hysteria-server..."
if sudo systemctl restart hysteria-server; then
    echo -e "${GREEN}执行 sudo systemctl restart hysteria-server 已成功重启并运行。${NC}"
else
    echo -e "${RED}[错误] hysteria-server 重启失败，请检查日志。${NC}"
fi
