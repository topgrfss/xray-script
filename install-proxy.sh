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

read -p "ip adress to your endpoint" server_ip
echo "now uuid will be generated via ssh to your server"
read -p "do you have xray on server (y/n)" is_xray_on_different_server
server_uuid=$(ssh root@$server_ip xray uuid)

#touch /usr/local/etc/xray/config.json
cat <<EOF > config.json
{
  "log": {
    "loglevel": "warning"
  },

  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$(xray uuid)",
            "email": "init"
          }
        ],
        "decryption": "none"
      },

      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "yandex:443",
          "serverNames": ["yandex.ru"],
          "privateKey": "$(cat /usr/local/etc/xray/.keys | awk -F': ' '/Password/ {print $2}')",
          "shortIds": ["$(cat /usr/local/etc/xray/.keys | awk -F': ' '/shortsid/ {print $2}')"]
        }
      }
    }
  ],

  "outbounds": [
    {
      "protocol": "vless",
      "tag": "to_us_exit",
      "settings": {
        "vnext": [
          {
            "address": "$server_ip",
            "port": 443,
            "users": [
              {
                "id": "$server_uuid"
              }
            ]
          }
        ]
      },

      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    },

    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ],

  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "outboundTag": "to_us_exit"
      }
    ]
  }
}
EOF
