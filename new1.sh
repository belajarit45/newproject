#!/bin/bash

# Inisialisasi variabel
github_repo="belajarit45/database1"
token="your_github_token_here"

# 1. Periksa keberadaan file uuidnew.txt di GitHub
file_exists=$(curl -s -o /dev/null -w "%{http_code}" https://raw.githubusercontent.com/$github_repo/main/uuidnew.txt)

if [ $file_exists -ne 200 ]; then
    echo "File uuidnew.txt tidak ditemukan di GitHub."
    exit 1
fi

echo "File uuidnew.txt ditemukan di GitHub."

# 2. Periksa UUID dalam uuidnew.txt di GitHub
uuid=""

while IFS= read -r line; do
    if [[ $line == sdk-android-* ]]; then
        uuid=$(echo $line | cut -d'-' -f3)
        break
    fi
done < <(curl -s https://raw.githubusercontent.com/$github_repo/main/uuidnew.txt)

if [ -z "$uuid" ]; then
    echo "UUID tidak ditemukan dalam uuidnew.txt di GitHub."
    exit 1
fi

echo "UUID $uuid ditemukan dalam uuidnew.txt di GitHub."

# 3. Buat file docker-compose.yaml
cat > docker-compose.yaml << EOF
version: '3'

services:
EOF

# Iterasi untuk setiap UUID yang ditemukan
i=1
while IFS= read -r line; do
    if [[ $line == sdk-android-* ]]; then
        uuid=$(echo $line | cut -d'-' -f3)
        cat >> docker-compose.yaml << EOF
  earnapp_$i:
    container_name: earnapp-container_$i
    image: fazalfarhan01/earnapp:lite
    restart: always
    volumes:
      - earnapp-data:/etc/earnapp
    environment:
      EARNAPP_UUID: $uuid

EOF
        ((i++))
    fi
done < <(curl -s https://raw.githubusercontent.com/$github_repo/main/uuidnew.txt)

cat >> docker-compose.yaml << EOF
volumes:
  earnapp-data:

EOF

# 4. Jalankan 5 container secara bersamaan dengan docker-compose up -d
docker-compose up -d --scale earnapp_$i=5

# 5. Buat URL dan kirim menggunakan token ke GitHub
earnapp_url="https://earnapp.com/r/$uuid"
curl -X POST -H "Authorization: token $token" -d '{"url": "'"$earnapp_url"'"}' https://api.github.com/repos/$github_repo/contents/earnapplinkupdate.txt

echo "Proses selesai."
