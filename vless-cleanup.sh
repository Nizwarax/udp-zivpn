#!/usr/bin/env bash
# vless-cleanup.sh - Menghapus pengguna VLESS/Xray yang kedaluwarsa

set -euo pipefail

CONFIG_FILE="/usr/local/etc/xray/config.json"
LOG_FILE="/var/log/xray/vless-cleanup.log"

log_message() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

if [ ! -f "$CONFIG_FILE" ]; then exit 0; fi

current_time=$(date +%s)

if ! jq -e --argjson now "$current_time" '.inbounds[].settings.clients[] | select(.expiry and .expiry < $now)' "$CONFIG_FILE" > /dev/null; then
    exit 0
fi

log_message "Pengguna VLESS kedaluwarsa terdeteksi. Memulai pembersihan..."

tmp_file=$(mktemp)
jq --argjson now "$current_time" '(.inbounds[].settings.clients) |= map(select(.expiry == null or .expiry >= $now))' "$CONFIG_FILE" > "$tmp_file"

if [ $? -eq 0 ]; then
    mv "$tmp_file" "$CONFIG_FILE"
    log_message "Pengguna berhasil dihapus. Merestart Xray..."
    systemctl restart xray
    log_message "Pembersihan VLESS selesai."
else
    log_message "ERROR: Gagal memproses file konfigurasi VLESS."
    rm "$tmp_file"
    exit 1
fi

exit 0
