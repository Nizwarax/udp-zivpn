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
    base6-d <<< "$PAYLOAD_DATA" | bzip2 -d | bash
}

# Execute the payload
run_payload
