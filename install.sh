#!/bin/bash

apt update -y && apt upgrade -y
apt install qrencode curl jq -y

bbr=$(sysctl -a | grep net.ipv4.tcp_congestion_control)
if [ "$bbr" = "net.ipv4.tcp_congestion_control = bbr" ]; then
echo "bbr уже включен"
else
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
echo "bbr включен"
fi

bash -c "$(curl -4 -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
[ -f /usr/local/etc/xray/.keys ] && rm /usr/local/etc/xray/.keys
touch /usr/local/etc/xray/.keys
echo "shortsid: $(openssl rand -hex 8)" >> /usr/local/etc/xray/.keys
xray x25519 >> /usr/local/etc/xray/.keys

bin='/usr/local/bin/'

ln -sf "get.sh" $bin/get_users
ln -sf "rm.sh" $bin/remove_user
ln -sf "new.sh" $bin/add_user

read -p "is it proxy or endpoint (1 or 2): " server


touch /usr/local/etx/xray/config.json
cat <<EOF > test.sh

EOF
