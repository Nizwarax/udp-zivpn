#!/usr/bin/env bash
# vless-manager.sh - Instalasi dan Manajemen VLESS dalam satu skrip

set -euo pipefail

# --- Konfigurasi dan Variabel Global ---
CONFIG_FILE="/usr/local/etc/xray/config.json"
NGINX_CONF_DIR="/etc/nginx/conf.d"
SSL_CERT_DIR="/etc/ssl/localcerts"
DOMAIN="" # Akan diisi saat instalasi atau dideteksi otomatis

# --- Warna dan Gaya ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'

# --- Fungsi Bantuan ---
info() { echo -e "${C_BLUE}INFO:${C_RESET} $1"; }
success() { echo -e "${C_GREEN}✅ SUCCESS:${C_RESET} $1"; }
warn() { echo -e "${C_YELLOW}⚠️ WARNING:${C_RESET} $1"; }
error() { echo -e "${C_RED}❌ ERROR:${C_RESET} $1"; exit 1; }
press_enter() { read -rp "Tekan Enter untuk melanjutkan..."; }

# --- Fungsi Instalasi ---
install_vless() {
    info "Memulai instalasi VLESS..."

    read -rp "🌐 Masukkan domain Anda: " DOMAIN
    [[ -z "$DOMAIN" ]] && error "Domain wajib diisi!"

    info "Memperbarui sistem dan menginstal dependensi..."
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx curl jq openssl socat uuid-runtime

    info "Menginstal Xray-core..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

    info "Membuat file konfigurasi Xray..."
    install -d /usr/local/etc/xray /var/log/xray /var/www/html
    cat > "$CONFIG_FILE" <
{
  "log": { "loglevel": "warning" },
  "inbounds": [{
    "listen": "127.0.0.1",
    "port": 10000,
    "protocol": "vless",
    "settings": { "clients": [], "decryption": "none" },
    "streamSettings": { "network": "ws", "wsSettings": { "path": "/xray" } }
  }],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

    info "Menyiapkan Nginx dan SSL (self-signed)..."
    mkdir -p "$SSL_CERT_DIR"
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 -keyout "$SSL_CERT_DIR/$DOMAIN.key" -out "$SSL_CERT_DIR/$DOMAIN.crt" -subj "/CN=$DOMAIN" >/dev/null 2>&1

    cat > "$NGINX_CONF_DIR/80-$DOMAIN.conf" <
server {
  listen 80;
  server_name $DOMAIN;
  location ^~ /.well-known/acme-challenge/ { root /var/www/html; default_type text/plain; }
  location / { return 301 https://\$host\$request_uri; }
}
EOF

    cat > "$NGINX_CONF_DIR/443-xray.conf" <
server {
  listen 443 ssl http2;
  server_name $DOMAIN;
  ssl_certificate $SSL_CERT_DIR/$DOMAIN.crt;
  ssl_certificate_key $SSL_CERT_DIR/$DOMAIN.key;

  location /xray {
    proxy_pass http://127.0.0.1:10000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
  }
}
EOF

    nginx -t && systemctl reload nginx

    info "Mencoba mendapatkan sertifikat Let's Encrypt..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y certbot python3-certbot-nginx
    certbot certonly --webroot -w /var/www/html -d "$DOMAIN" --agree-tos -m admin@"$DOMAIN" --no-eff-email -n && {
        success "Sertifikat Let's Encrypt berhasil didapatkan."
        sed -i "s|ssl_certificate.*|ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;|" "$NGINX_CONF_DIR/443-xray.conf"
        sed -i "s|ssl_certificate_key.*|ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;|" "$NGINX_CONF_DIR/443-xray.conf"
        nginx -t && systemctl reload nginx
    } || warn "Gagal mendapatkan sertifikat Let's Encrypt. Menggunakan self-signed certificate."

    systemctl enable xray
    systemctl restart xray

    success "Instalasi VLESS selesai!"
    info "Skrip akan melanjutkan ke menu manajemen."
    press_enter
}

# --- Fungsi Manajemen Akun ---
detect_domain() {
    DOMAIN=$(grep -h "server_name" $NGINX_CONF_DIR/*.conf 2>/dev/null | head -n1 | awk '{print $2}' | tr -d ';')
    [[ -z "$DOMAIN" ]] && error "Domain tidak dapat dideteksi. Pastikan Nginx terkonfigurasi dengan benar."
}

list_accounts() {
    echo -e "\n${C_YELLOW}📋 Daftar Akun VLESS:${C_RESET}"

    # Header tabel
    printf "%-37s | %-25s | %s\n" "UUID" "Email" "Masa Aktif"
    echo "--------------------------------------+---------------------------+-----------------------"

    local current_time
    current_time=$(date +%s)

    if ! jq -e '.inbounds[].settings.clients | length > 0' "$CONFIG_FILE" >/dev/null 2>&1; then
        echo "Belum ada akun."
        echo
        return
    fi

    # Loop via jq
    jq -c '.inbounds[].settings.clients[]' "$CONFIG_FILE" | while read -r user_json; do
        local uuid email expiry status
        uuid=$(jq -r '.id' <<< "$user_json")
        email=$(jq -r '.email // "-"' <<< "$user_json")
        expiry=$(jq -r '.expiry // 0' <<< "$user_json")

        if [[ "$expiry" -eq 0 ]]; then
            status="${C_YELLOW}Permanen${C_RESET}"
        elif [[ "$expiry" -lt "$current_time" ]]; then
            status="${C_RED}Kedaluwarsa${C_RESET}"
        else
            local remaining_seconds=$((expiry - current_time))
            local remaining_days=$((remaining_seconds / 86400))
            local remaining_hours=$(( (remaining_seconds % 86400) / 3600 ))

            if [[ "$remaining_days" -gt 0 ]]; then
                status="${C_GREEN}Sisa ${remaining_days} hari${C_RESET}"
            else
                status="${C_YELLOW}Sisa ${remaining_hours} jam${C_RESET}"
            fi
        fi
        printf "%-37s | %-25s | %b\n" "$uuid" "$email" "$status"
    done
    echo
}

create_account() {
    info "Membuat akun VLESS reguler..."
    read -rp "📧 Masukkan email/nama untuk akun ini: " email
    [[ -z "$email" ]] && email="user-$(date +%s)"

    read -rp "📅 Masa aktif akun (hari) [default: 30]: " days
    [[ -z "$days" ]] && days=30
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        warn "Input harus berupa angka. Menggunakan default 30 hari."
        days=30
    fi

    local expiry_timestamp
    expiry_timestamp=$(date -d "+$days days" +%s)
    uuid=$(/usr/local/bin/xray uuid 2>/dev/null || uuidgen)

    tmp_file=$(mktemp)
    # Gunakan --argjson untuk keamanan dan kebenaran tipe data
    jq --arg uuid "$uuid" \
       --arg email "$email" \
       --argjson expiry "$expiry_timestamp" \
       '.inbounds[].settings.clients += [{"id":$uuid, "email":$email, "level":0, "expiry":$expiry}]' \
       "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"

    systemctl restart xray
    success "Akun berhasil dibuat! Aktif selama $days hari."

    echo -e "${C_GREEN}🔗 Link Konfigurasi:${C_RESET}"
    echo "vless://${uuid}@${DOMAIN}:443?encryption=none&type=ws&security=tls&host=${DOMAIN}&sni=${DOMAIN}&path=%2Fxray#${email}"
    echo
}

delete_account() {
    list_accounts
    read -rp "🔍 Masukkan UUID atau email akun yang akan dihapus: " identifier
    [[ -z "$identifier" ]] && { warn "Tidak ada input, kembali ke menu."; return; }

    # Validasi jika akun ada
    found=$(jq --arg t "$identifier" '.inbounds[].settings.clients[] | select(.id == $t or .email == $t)' "$CONFIG_FILE")
    if [[ -z "$found" ]]; then
        warn "Akun dengan identifier '$identifier' tidak ditemukan."
        return
    fi

    info "Menghapus akun '$identifier'..."
    tmp_file=$(mktemp)
    jq --arg t "$identifier" 'del(.inbounds[].settings.clients[] | select(.id == $t or .email == $t))' "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"

    systemctl restart xray
    success "Akun '$identifier' berhasil dihapus."
}

create_trial_account() {
    info "Membuat akun VLESS trial..."
    read -rp "📧 Masukkan email/nama untuk akun trial ini: " email
    [[ -z "$email" ]] && email="trial-$(date +%s)"

    read -rp "⏳ Masa aktif akun (menit) [default: 60]: " minutes
    [[ -z "$minutes" ]] && minutes=60
    if ! [[ "$minutes" =~ ^[0-9]+$ ]]; then
        warn "Input harus berupa angka. Menggunakan default 60 menit."
        minutes=60
    fi

    local expiry_timestamp
    expiry_timestamp=$(date -d "+$minutes minutes" +%s)
    uuid=$(/usr/local/bin/xray uuid 2>/dev/null || uuidgen)

    tmp_file=$(mktemp)
    jq --arg uuid "$uuid" \
       --arg email "$email" \
       --argjson expiry "$expiry_timestamp" \
       '.inbounds[].settings.clients += [{"id":$uuid, "email":$email, "level":0, "expiry":$expiry}]' \
       "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"

    systemctl restart xray
    success "Akun trial berhasil dibuat! Aktif selama $minutes menit."

    echo -e "${C_GREEN}🔗 Link Konfigurasi:${C_RESET}"
    echo "vless://${uuid}@${DOMAIN}:443?encryption=none&type=ws&security=tls&host=${DOMAIN}&sni=${DOMAIN}&path=%2Fxray#${email}"
    echo
}

# --- Fungsi Uninstal ---
uninstall_vless() {
    warn "Anda akan menghapus VLESS, Xray, dan Nginx!"
    read -rp "Apakah Anda yakin? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        info "Memulai proses uninstal..."
        systemctl stop xray nginx
        systemctl disable xray nginx

        apt-get purge -y nginx curl jq openssl socat uuid-runtime certbot python3-certbot-nginx
        apt-get autoremove -y

        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge

        rm -rf /usr/local/etc/xray /var/log/xray "$NGINX_CONF_DIR"/*xray* "$NGINX_CONF_DIR"/*$DOMAIN* "$SSL_CERT_DIR"

        success "VLESS dan komponen terkait telah dihapus."
        exit 0
    else
        info "Proses uninstal dibatalkan."
    fi
}


# --- Tampilan Menu Utama ---
show_menu() {
    detect_domain
    while true; do
        clear
        echo -e "${C_BLUE}=============================================${C_RESET}"
        echo -e "  ${C_GREEN}🚀 MANAJEMEN VLESS-XRAY 🚀${C_RESET}"
        echo -e "${C_BLUE}=============================================${C_RESET}"
        echo -e "  ${C_YELLOW}Domain Aktif:${C_RESET} $DOMAIN"
        echo -e "${C_BLUE}---------------------------------------------${C_RESET}"
        echo "  1) ➕ Buat Akun Reguler"
        echo "  2) ⏳ Buat Akun Trial"
        echo "  3) 👀 Lihat Semua Akun"
        echo "  4) 🗑️ Hapus Akun"
        echo "  5) 🔄 Restart Layanan Xray"
        echo "  6) 🔥 Uninstal VLESS"
        echo "  7) ❌ Keluar"
        echo -e "${C_BLUE}---------------------------------------------${C_RESET}"
        read -rp "Pilih opsi (1-7): " choice

        case $choice in
            1) create_account; press_enter ;;
            2) create_trial_account; press_enter ;;
            3) list_accounts; press_enter ;;
            4) delete_account; press_enter ;;
            5) systemctl restart xray; success "Layanan Xray berhasil direstart."; press_enter ;;
            6) uninstall_vless; press_enter ;;
            7) exit 0 ;;
            *) warn "Pilihan tidak valid. Silakan pilih antara 1-7."; sleep 1 ;;
        esac
    done
}

# --- Logika Utama Skrip ---
main() {
    # Cek apakah dijalankan sebagai root
    if [[ "$EUID" -ne 0 ]]; then
        error "Skrip ini harus dijalankan sebagai root."
    fi

    # Cek apakah Xray sudah terinstal
    if [ ! -f "$CONFIG_FILE" ]; then
        install_vless
    fi

    # Setelah instalasi atau jika sudah ada, tampilkan menu
    show_menu
}

# Jalankan fungsi utama
main
