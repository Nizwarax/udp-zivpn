#!/usr/bin/env bash
# vpn-manager.sh - Menu utama untuk mengelola VLESS dan Zivpn

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

# --- Variabel Lokasi Skrip ---
VLESS_SCRIPT="./vless-manager.sh"
ZIVPN_SCRIPT="/usr/local/bin/zivpn" # Lokasi instalasi standar dari memori

# --- Tampilan Menu Utama ---
show_main_menu() {
    while true; do
        clear
        echo -e "${C_BLUE}=============================================${C_RESET}"
        echo -e "  ${C_GREEN}🚀 MANAJER VPN TERPADU 🚀${C_RESET}"
        echo -e "${C_BLUE}=============================================${C_RESET}"
        echo "  Pilih layanan yang ingin Anda kelola:"
        echo

        local options=()
        local commands=()

        # Cek keberadaan skrip dan bangun menu secara dinamis
        if [[ -f "$VLESS_SCRIPT" && -x "$VLESS_SCRIPT" ]]; then
            options+=("🌐 Kelola VLESS")
            commands+=("bash $VLESS_SCRIPT")
        fi

        if command -v zivpn &> /dev/null; then
            options+=("🛡️  Kelola Zivpn")
            commands+=("zivpn") # Jika ada di PATH, panggil langsung
        elif [[ -f "$ZIVPN_SCRIPT" ]]; then
             options+=("🛡️  Kelola Zivpn")
            commands+=("$ZIVPN_SCRIPT") # Fallback ke path absolut
        fi

        if [ ${#options[@]} -eq 0 ]; then
            error "Tidak ada skrip manajer (VLESS/Zivpn) yang ditemukan atau dapat dieksekusi."
        fi

        # Tampilkan opsi menu
        for i in "${!options[@]}"; do
            echo "  $((i+1))) ${options[$i]}"
        done
        local exit_option=$((${#options[@]} + 1))
        echo "  $exit_option) ❌ Keluar"
        echo
        echo -e "${C_BLUE}---------------------------------------------${C_RESET}"
        read -rp "Pilih opsi (1-$exit_option): " choice

        # Validasi input
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            warn "Input harus berupa angka."
            sleep 1
            continue
        fi

        # Proses pilihan
        if [[ "$choice" -eq "$exit_option" ]]; then
            exit 0
        elif [[ "$choice" -gt 0 && "$choice" -le "${#commands[@]}" ]]; then
            clear
            eval "${commands[$((choice-1))]}"
            info "Kembali ke menu utama..."
            read -rp "Tekan Enter untuk melanjutkan..."
        else
            warn "Pilihan tidak valid."
            sleep 1
        fi
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
