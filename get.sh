#!/bin/bash

path='/root/conf.json'

emails=($(jq -r '.inbounds[0].settings.clients[].email' $path))

for i in "${!emails[@]}"; do
   echo "$((i + 1)). ${emails[$i]}"
done

read -p "Выберите клиента: " client

if ! [[ "$client" =~ ^[0-9]+$ ]] || (( client < 1 || client > ${#emails[@]} )); then
    echo "Ошибка: номер должен быть от 1 до ${#emails[@]}"
    exit 1
fi

selected_email="${emails[$((client - 1))]}"


index=$(jq --arg email "$selected_email" '.inbounds[0].settings.clients | to_entries[] | select(.value.email == $email) | .key'  $path)
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
