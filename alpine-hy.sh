#!/usr/bin/env bash

# 官方默认参数为基准参数
BASE_INIT_STREAM=26843545
BASE_MAX_STREAM=26843545
BASE_INIT_CONN=67108864
BASE_MAX_CONN=67108864

# 计算偏移量
FACTOR=1342177            # 26843545 / 20
FACTOR_CONN=$((FACTOR * 5 / 2)) # 3355442

# 从 config.yaml 中读取端口、密码、证书和密钥路径
if [ -f /etc/hysteria/config.yaml ]; then
    PORT=$(grep -E '^listen:' /etc/hysteria/config.yaml | awk '{print $2}' | sed 's/://g')
    PASSWORD=$(grep -E '^\s+password:' /etc/hysteria/config.yaml | awk '{print $2}')
    CERT=$(grep -E '^\s+cert:' /etc/hysteria/config.yaml | awk '{print $2}')
    KEY=$(grep -E '^\s+key:' /etc/hysteria/config.yaml | awk '{print $2}')
else
    echo "未找到 /etc/hysteria/config.yaml 文件，请检查是否安装了hy2"
    echo "适用 alpine 的hy2脚本："
    echo "wget -O hy2.sh https://raw.githubusercontent.com/zrlhk/alpine-hysteria2/main/hy2.sh  && sh hy2.sh"
    echo ""
    exit 1
fi

# 默认值
PORT=${PORT:-12345}
PASSWORD=${PASSWORD:-"666666"}
CERT=${CERT:-"/etc/hysteria/server.crt"}
KEY=${KEY:-"/etc/hysteria/server.key"}

# 构造 KEYS 和 VALUES 数组
KEYS=()
VALUES=()

for i in $(busybox seq 0 50); do
    offset=$((i - 0))  # 从 0 到 +50
    val=$((offset))
    KEYS+=("$val")
    VALUES+=("$((BASE_INIT_STREAM + val * FACTOR)) $((BASE_MAX_STREAM + val * FACTOR)) $((BASE_INIT_CONN + val * FACTOR_CONN)) $((BASE_MAX_CONN + val * FACTOR_CONN))")
done

for i in $(busybox seq 1 19); do
    offset=$((-1 * i))
    KEYS+=("$offset")
    VALUES+=("$((BASE_INIT_STREAM + offset * FACTOR)) $((BASE_MAX_STREAM + offset * FACTOR)) $((BASE_INIT_CONN + offset * FACTOR_CONN)) $((BASE_MAX_CONN + offset * FACTOR_CONN))")
done

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 菜单输出
echo -e "${GREEN}—————————————————————————————————————————————————————————————————${NC}"
echo -e "${GREEN}-- 默认参数上调配置,最高可选+50 --${NC}"
COUNT=0
for i in $(busybox seq 1 10); do
    printf " %-12s" "参数 +$i"
    COUNT=$((COUNT + 1))
    [ $((COUNT % 5)) -eq 0 ] && echo ""
done
echo ""
echo -e "${GREEN}—————————————————————————————————————————————————————————————————${NC}"
echo -e " ${GREEN}参数 0 (官方默认)${NC}                 "
echo -e "${GREEN}—————————————————————————————————————————————————————————————————${NC}"
echo -e "${GREEN}-- 默认参数下调配置,最高可选-19 --${NC}"
COUNT=0
for i in $(busybox seq 1 10); do
    val=$((-1 * i))
    printf " %-12s" "参数 $val"
    COUNT=$((COUNT + 1))
    [ $((COUNT % 5)) -eq 0 ] && echo ""
done
echo ""
echo -e "${GREEN}—————————————————————————————————————————————————————————————————${NC}"
echo -e "${GREEN} 适用 alpine 的hy脚本 ${NC}"
echo -e "${GREEN} wget -O hy2.sh https://raw.githubusercontent.com/zrlhk/alpine-hysteria2/main/hy2.sh  && sh hy2.sh ${NC}"
echo -e "${GREEN} 以官方默认参数为基准进行2/5倍比例上下微调${NC}"
echo -e "${GREEN}—————————————————————————————————————————————————————————————————${NC}"

# 获取用户输入
read -p " 请输入你的选择,例如 -1, 0, 1，(0为官方默认): " selection

# 查找选择
FOUND=0
for idx in "${!KEYS[@]}"; do
    if [ "${KEYS[$idx]}" = "$selection" ]; then
        read initStream maxStream initConn maxConn <<< "${VALUES[$idx]}"
        FOUND=1
        break
    fi
done

if [ $FOUND -eq 0 ]; then
    echo -e "${RED}无效的选择，请重新运行脚本。${NC}"
    exit 1
fi

# 显示选择结果
echo -e "${GREEN}您选择的quic参数配置为:${NC}"
echo -e "${GREEN}initStreamReceiveWindow: $initStream${NC}"
echo -e "${GREEN}maxStreamReceiveWindow: $maxStream${NC}"
echo -e "${GREEN}initConnReceiveWindow: $initConn${NC}"
echo -e "${GREEN}maxConnReceiveWindow: $maxConn${NC}"
#echo -e "${GREEN}端口: $PORT${NC}"
#echo -e "${GREEN}密码: $PASSWORD${NC}"
#echo -e "${GREEN}证书路径: $CERT${NC}"
#echo -e "${GREEN}私钥路径: $KEY${NC}"
echo -e ""

# 写入前备份原配置文件（覆盖 .bak）
if [ -f /etc/hysteria/config.yaml ]; then
    sudo cp /etc/hysteria/config.yaml /etc/hysteria/config.yaml.bak
    echo -e "原配置文件已备份为 /etc/hysteria/config.yaml.bak "
fi

# 写入配置文件
sudo tee /etc/hysteria/config.yaml > /dev/null <<EOF
listen: :$PORT

tls:
  cert: $CERT
  key: $KEY

quic:
  initStreamReceiveWindow: $initStream
  maxStreamReceiveWindow: $maxStream
  initConnReceiveWindow: $initConn
  maxConnReceiveWindow: $maxConn

auth:
  type: password
  password: $PASSWORD

masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true
EOF

echo "配置写入 /etc/hysteria/config.yaml"

# 重启服务
echo "尝试重启 hysteria-server..."
if service hysteria restart; then
    echo -e "${GREEN}执行 service hysteria restart 已成功重启并运行。${NC}"
else
    echo -e "${RED}[错误] service hysteria restart 重启失败，请检查日志。${NC}"
fi
