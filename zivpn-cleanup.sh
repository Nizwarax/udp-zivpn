#!/bin/bash

USER_DB="/etc/zivpn/users.db.json"
CONFIG_FILE="/etc/zivpn/config.json"

# Keluar jika basis data tidak ada
if [ ! -f "$USER_DB" ]; then
    exit 0
fi

# Fungsi untuk menyinkronkan kata sandi dari user.db.json ke config.json
sync_config() {
    # Karena skrip ini dijalankan oleh root cron, sudo tidak diperlukan
    passwords=$(jq -r '.[].password' "$USER_DB")
    jq --argjson passwords "$(echo "$passwords" | jq -R . | jq -s .)" '.auth.config = $passwords | .config = $passwords' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    systemctl daemon-reload
    systemctl restart zivpn.service > /dev/null 2>&1
}

# Dapatkan tanggal hari ini
today=$(date +%Y-%m-%d)

# Periksa pengguna yang kedaluwarsa sebelum modifikasi
expired_count=$(jq --arg today "$today" 'map(select(.expiry_date < $today)) | length' "$USER_DB")

# Jika ada pengguna yang kedaluwarsa, hapus mereka
if [ "$expired_count" -gt 0 ]; then
    # Hapus pengguna yang kedaluwarsa
    jq --arg today "$today" 'map(select(.expiry_date >= $today))' "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"
    # Sinkronkan konfigurasi baru
    sync_config
fi
