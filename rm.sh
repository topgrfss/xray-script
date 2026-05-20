#!/bin/bash
#path='/usr/local/etc/xray/config.json'
path='/root/conf.json'
emails=($(jq -r '.inbounds[0].settings.clients[].email' $path))

if [[ ${#emails[@]} -eq 0 ]]; then
    echo "Нет клиентов для удаления."
    exit 1
fi

echo "Список клиентов:"
for i in "${!emails[@]}"; do
    echo "$((i+1)). ${emails[$i]}"
done

read -p "Введите номер клиента для удаления: " choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#emails[@]} )); then
    echo "Ошибка: номер должен быть от 1 до ${#emails[@]}"
    exit 1
fi

selected_email="${emails[$((choice - 1))]}"

jq --arg email "$selected_email" \
   '(.inbounds[0].settings.clients) |= map(select(.email != $email))' \
   $path > .tmp && mv .tmp $path

systemctl restart xray

echo "Клиент $selected_email удалён."

