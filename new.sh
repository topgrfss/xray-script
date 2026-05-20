#!/bin/bash

#path='/usr/local/etc/xray/config.json.b'
path='/root/conf.json'

read -p "Введите имя пользователя (email): " email

    if [[ -z "$email" || "$email" == *" "* ]]; then
    echo "Имя пользователя не может быть пустым или содержать пробелы. Попробуйте снова."
    exit 1
    fi
user_json=$(jq --arg email "$email" '.inbounds[0].settings.clients[] | select(.email == $email)' $path)

if [[ -z "$user_json" ]]; then
uuid=$(xray uuid)
jq --arg email "$email" --arg uuid "$uuid" '.inbounds[0].settings.clients += [{"email": $email, "id": $uuid, "flow": ""}]' $path > tmp.json && mv tmp.json $path
systemctl restart xray
index=$(jq --arg email "$email" '.inbounds[0].settings.clients | to_entries[] | select(.value.email == $email) | .key'  $path)
protocol=$(jq -r '.inbounds[0].protocol' $path)
port=$(jq -r '.inbounds[0].port' $path)
uuid=$(jq --argjson index "$index" -r '.inbounds[0].settings.clients[$index].id' $path)
pbk=$(cat /usr/local/etc/xray/.keys | awk -F': ' '/Password/ {print $2}')
sid=$(cat /usr/local/etc/xray/.keys | awk -F': ' '/shortsid/ {print $2}')
username=$(jq --argjson index "$index" -r '.inbounds[0].settings.clients[$index].email' $path)
sni=$(jq -r '.inbounds[0].streamSettings.realitySettings.serverNames[0]' $path)
ip=$(curl -4 -s icanhazip.com)
link="$protocol://$uuid@$ip:$port?security=reality&path=%2F&host=&mode=auto&sni=$sni&fp=firefox&pbk=$pbk&sid=$sid&spx=%2F&type=xhttp&encryption=none#$username"
echo ""
echo "Ссылка для подключения":
echo "$link"
echo ""
echo "QR-код:"
echo ${link} | qrencode -t ansiutf8
else
echo "Пользователь с таким именем уже существует. Попробуйте снова." 
fi
