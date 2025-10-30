#!/bin/bash
# Script Enkripsi Zivpn
# Dibuat oleh Deki_niswara & Jules

export DEBIAN_FRONTEND=noninteractive

# --- Konfigurasi Lisensi ---
IZIN_URL="https://zivpn.nizwara.biz.id/izin_ips.txt"

# --- Warna ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Fungsi Pemeriksaan IP ---
check_ip() {
    echo -e "${YELLOW}Memverifikasi lisensi IP...${NC}"
    # Use a reliable and fast IP service
    MY_IP=$(curl -s "https://ipinfo.io/ip")
    if [ -z "$MY_IP" ]; then
        # Fallback IP service
        MY_IP=$(curl -s "https://api.ipify.org")
    fi

    # Final check if IP was retrieved
    if [ -z "$MY_IP" ]; then
        echo -e "${RED}Gagal mendapatkan alamat IP publik server ini. Instalasi dibatalkan.${NC}"
        exit 1
    fi

    # Fetch the list of allowed IPs
    IZIN_IPS=$(curl -s "$IZIN_URL")
    if [ -z "$IZIN_IPS" ]; then
        echo -e "${RED}Gagal mengambil daftar IP yang diizinkan dari server lisensi. Instalasi dibatalkan.${NC}"
        exit 1
    fi

    # Check if the current IP is in the list
    if grep -q -w "$MY_IP" <<< "$IZIN_IPS"; then
        echo -e "${GREEN}IP terverifikasi. Melanjutkan instalasi...${NC}"
    else
        echo -e "${RED}=============================================${NC}"
        echo -e "${RED}            AKSES DITOLAK!                 ${NC}"
        echo -e "${RED}=============================================${NC}"
        echo -e " IP Anda: ${YELLOW}$MY_IP${NC}"
        echo -e " IP Anda tidak terdaftar untuk menggunakan skrip ini."
        echo -e " Silakan hubungi administrator untuk pendaftaran."
        echo -e "${RED}=============================================${NC}"
        exit 1
    fi
}

# --- Panggil Fungsi Pemeriksaan ---
check_ip

# --- Dekompresi dan Jalankan Payload ---
run_payload() {
    PAYLOAD_DATA="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"
    base64 -d <<< "$PAYLOAD_DATA" | bzip2 -d | bash
}

# Execute the payload
run_payload
