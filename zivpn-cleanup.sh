#!/bin/bash
# zivpn-cleanup.sh - Menghapus pengguna Zivpn yang kedaluwarsa menggunakan timestamp

USER_DB="/etc/zivpn/users.db.json"
CONFIG_FILE="/etc/zivpn/config.json"
LOG_FILE="/var/log/zivpn/cleanup.log"

log_message() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

if [ ! -f "$USER_DB" ]; then exit 0; fi

sync_config() {
    passwords=$(jq -r '.[].password' "$USER_DB")
    if jq --argjson passwords "$(echo "$passwords" | jq -R . | jq -s .)" '.auth.config = $passwords | .config = $passwords' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"; then
        mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        systemctl daemon-reload
        systemctl restart zivpn.service > /dev/null 2>&1
    else
        log_message "ERROR: Gagal memperbarui file config Zivpn."
        rm -f "$CONFIG_FILE.tmp"
    fi
}

current_time=$(date +%s)

if jq -e '.[] | select(has("expiry_date"))' "$USER_DB" > /dev/null; then
    log_message "Entri 'expiry_date' Zivpn lama ditemukan. Mengonversi..."
    jq 'map(if has("expiry_date") and .expiry_date != null then .expiry_timestamp = (.expiry_date | fromdate) | del(.expiry_date) else . end)' "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"
fi

if ! jq -e --argjson now "$current_time" '.[] | select(has("expiry_timestamp") and .expiry_timestamp < $now)' "$USER_DB" > /dev/null; then
    exit 0
fi

log_message "Pengguna Zivpn kedaluwarsa terdeteksi. Memulai pembersihan..."

jq --argjson now "$current_time" 'map(select(.expiry_timestamp >= $now))' "$USER_DB" > "$USER_DB.tmp"

if [ $? -eq 0 ]; then
    mv "$USER_DB.tmp" "$USER_DB"
    log_message "Pengguna berhasil dihapus. Menyinkronkan config Zivpn..."
    sync_config
    log_message "Pembersihan Zivpn selesai."
else
    log_message "ERROR: Gagal memproses database pengguna Zivpn."
    rm -f "$USER_DB.tmp"
    exit 1
fi
