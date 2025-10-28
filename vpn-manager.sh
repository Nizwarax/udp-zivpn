#!/usr/bin/env bash
# vpn-manager.sh - Menu utama terpadu untuk VLESS dan Zivpn

# --- Warna dan Gaya ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'

# --- Fungsi Bantuan ---
info() { echo -e "${C_BLUE}INFO:${C_RESET} $1"; }
warn() { echo -e "${C_YELLOW}⚠️ WARNING:${C_RESET} $1"; }
error() { echo -e "${C_RED}❌ ERROR:${C_RESET} $1"; exit 1; }
press_enter() { read -rp "Tekan Enter untuk melanjutkan..."; }

# --- Variabel Skrip & Deteksi Path ---
# Menentukan direktori tempat skrip ini berada, untuk path yang andal
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

VLESS_SCRIPT_PATH="$SCRIPT_DIR/vless-manager.sh"
ZIVPN_COMMAND="zivpn"

# --- Fungsi Manajemen Layanan ---

handle_vless_management() {
    if [[ ! -f "$VLESS_SCRIPT_PATH" ]]; then
        error "'vless-manager.sh' tidak ditemukan. Pastikan file berada di direktori yang sama."
    fi
    # VLESS manager sudah memiliki logika instalasi sendiri
    clear
    bash "$VLESS_SCRIPT_PATH"
}

handle_zivpn_management() {
    if command -v "$ZIVPN_COMMAND" &> /dev/null; then
        clear
        "$ZIVPN_COMMAND"
    else
        warn "Zivpn belum terinstal."
        read -rp "Apakah Anda ingin menginstalnya sekarang? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            ARCH=$(uname -m)
            INSTALL_SCRIPT=""
            if [[ "$ARCH" == "x86_64" ]]; then
                INSTALL_SCRIPT="$SCRIPT_DIR/zi.sh"
            elif [[ "$ARCH" == "aarch64" ]]; then
                INSTALL_SCRIPT="$SCRIPT_DIR/zi2.sh"
            else
                error "Arsitektur '$ARCH' tidak didukung."
            fi

            if [[ ! -f "$INSTALL_SCRIPT" ]]; then
                error "Skrip instalasi '$INSTALL_SCRIPT' tidak ditemukan."
            fi

            info "Menjalankan instalasi Zivpn..."
            bash "$INSTALL_SCRIPT"

            if command -v "$ZIVPN_COMMAND" &> /dev/null; then
                info "Instalasi berhasil. Melanjutkan ke menu manajemen..."
                sleep 1
                clear
                "$ZIVPN_COMMAND"
            else
                error "Instalasi selesai, tetapi perintah '$ZIVPN_COMMAND' masih tidak ditemukan."
            fi
        else
            info "Instalasi dibatalkan."
        fi
    fi
}

# --- Tampilan Menu Utama ---
show_main_menu() {
    while true; do
        clear
        echo -e "${C_BLUE}=============================================${C_RESET}"
        echo -e "  ${C_GREEN}🚀 MANAJER VPN TERPADU 🚀${C_RESET}"
        echo -e "${C_BLUE}=============================================${C_RESET}"
        echo "  Pilih layanan yang ingin Anda kelola:"
        echo
        echo "  1) 🌐 Kelola VLESS"
        echo "  2) 🛡️  Kelola Zivpn"
        echo "  3) ❌ Keluar"
        echo
        echo -e "${C_BLUE}---------------------------------------------${C_RESET}"
        read -rp "Pilih opsi (1-3): " choice

        case $choice in
            1) handle_vless_management; press_enter ;;
            2) handle_zivpn_management; press_enter ;;
            3) exit 0 ;;
            *) warn "Pilihan tidak valid."; sleep 1 ;;
        esac
    done
}

# --- Logika Utama ---
main() {
    if [[ "$EUID" -ne 0 ]]; then
        error "Skrip ini harus dijalankan sebagai root."
    fi
    show_main_menu
}

main
