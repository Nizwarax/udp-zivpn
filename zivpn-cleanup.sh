#!/bin/bash

# Skrip ini menghapus pengguna yang sudah kedaluwarsa dari database Zivpn.

USER_DB="/etc/zivpn/users.db.json"
CONFIG_FILE="/etc/zivpn/config.json"

# Periksa apakah file database pengguna ada
if [ ! -f "$USER_DB" ]; then
    echo "Database pengguna tidak ditemukan. Keluar."
    exit 1
fi

# Dapatkan waktu saat ini sebagai Unix timestamp
current_time=$(date +%s)

# Gunakan jq untuk memfilter pengguna yang waktu kedaluwarsanya sudah lewat
updated_users=$(jq --argjson now "$current_time" '[.[] | select(.expiry_timestamp > $now)]' "$USER_DB")

# Periksa apakah database telah berubah
original_users=$(cat "$USER_DB")
if [ "$original_users" == "$updated_users" ]; then
    echo "Tidak ada pengguna kedaluwarsa yang perlu dihapus."
    exit 0
fi

# Timpa database lama dengan daftar yang baru dan sudah difilter
echo "$updated_users" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"
echo "Pengguna yang kedaluwarsa telah dihapus."

# Sinkronkan daftar pengguna yang diperbarui ke file konfigurasi utama
passwords=$(jq -r '.[].password' "$USER_DB")
if [ -z "$passwords" ]; then
    # Tangani kasus di mana tidak ada pengguna yang tersisa
    jq '.auth.config = [] | .config = []' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
else
    # Gunakan --argjson untuk meneruskan array kata sandi dengan aman
    jq --argjson passwords "$(echo "$passwords" | jq -R . | jq -s .)" '.auth.config = $passwords | .config = $passwords' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi

echo "Konfigurasi disinkronkan. Me-restart layanan Zivpn."
# Restart layanan untuk menerapkan perubahan
sudo systemctl daemon-reload
sudo systemctl restart zivpn.service > /dev/null 2>&1

echo "Proses pembersihan selesai."
