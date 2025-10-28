#!/usr/bin/env bash
# installer.sh - Skrip instalasi terpadu untuk Manajer VPN

set -euo pipefail

# --- Konfigurasi ---
REPO_URL="https://github.com/Nizwarax/udp-zivpn.git" # URL repositori Anda
INSTALL_DIR="/opt/vpn-manager"
CMD_NAME="vpn"
CMD_PATH="/usr/local/bin/$CMD_NAME"

# --- Warna dan Gaya ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_RED='\033[0;31m'

# --- Fungsi Bantuan ---
info() { echo -e "${C_BLUE}INFO:${C_RESET} $1"; }
success() { echo -e "${C_GREEN}✅ SUCCESS:${C_RESET} $1"; }
error() { echo -e "${C_RED}❌ ERROR:${C_RESET} $1"; exit 1; }

# --- Logika Utama ---
main() {
    # 1. Cek Root
    if [[ "$EUID" -ne 0 ]]; then
        error "Skrip ini harus dijalankan sebagai root. Coba jalankan dengan 'sudo'."
    fi

    # 2. Instal Dependensi
    info "Memperbarui daftar paket dan menginstal dependensi (git, curl)..."
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y git curl

    # 3. Clone atau Update Repositori
    if [ -d "$INSTALL_DIR" ]; then
        info "Direktori instalasi sudah ada. Memperbarui dari Git..."
        cd "$INSTALL_DIR"
        git pull
    else
        info "Mengunduh skrip manajer dari GitHub..."
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi

    cd "$INSTALL_DIR"

    # 4. Buat Perintah Global 'vpn'
    info "Membuat perintah global '$CMD_NAME'..."
    # Hapus link lama jika ada untuk memastikan path-nya benar
    if [ -L "$CMD_PATH" ]; then
        rm -f "$CMD_PATH"
    fi

    # Pastikan skrip manajer utama ada dan dapat dieksekusi
    if [ ! -f "vpn-manager.sh" ]; then
        error "'vpn-manager.sh' tidak ditemukan di dalam repositori. Instalasi gagal."
    fi
    chmod +x "vpn-manager.sh"

    # Buat symbolic link
    ln -s "$INSTALL_DIR/vpn-manager.sh" "$CMD_PATH"

    info "Menyiapkan sistem pembersihan otomatis..."

    # 5. Siapkan Skrip Pembersihan dan Cron Job
    # VLESS
    if [ -f "vless-cleanup.sh" ]; then
        cp "$INSTALL_DIR/vless-cleanup.sh" /usr/local/bin/
        chmod +x /usr/local/bin/vless-cleanup.sh
        echo "* * * * * root /usr/local/bin/vless-cleanup.sh >/dev/null 2>&1" > /etc/cron.d/vless_cleanup
        info "Pembersihan VLESS diatur untuk berjalan setiap menit."
    else
        warn "'vless-cleanup.sh' tidak ditemukan. Pembersihan otomatis VLESS tidak diatur."
    fi

    # Zivpn
    if [ -f "zivpn-cleanup.sh" ]; then
        cp "$INSTALL_DIR/zivpn-cleanup.sh" /usr/local/bin/
        chmod +x /usr/local/bin/zivpn-cleanup.sh
        echo "* * * * * root /usr/local/bin/zivpn-cleanup.sh >/dev/null 2>&1" > /etc/cron.d/zivpn_cleanup
        info "Pembersihan Zivpn diatur untuk berjalan setiap menit."
    else
        warn "'zivpn-cleanup.sh' tidak ditemukan. Pembersihan otomatis Zivpn tidak diatur."
    fi

    success "Instalasi selesai!"
    info "Anda sekarang dapat menjalankan manajer dari direktori mana pun dengan perintah: sudo $CMD_NAME"
    echo

    # 5. Jalankan Menu untuk Pertama Kali
    info "Membuka menu utama untuk pertama kalinya..."
    sleep 2

    # Menggunakan 'exec' agar proses shell saat ini digantikan oleh menu vpn
    exec "$CMD_PATH"
}

main
