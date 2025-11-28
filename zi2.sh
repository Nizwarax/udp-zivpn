#!/bin/bash
# Zivpn UDP Module installer - Fixed
# Creator Deki_niswara

# --- Colors ---
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RED='\033[1;31m'
NC='\033[0m'

# --- Validasi Lisensi Baru dengan Kunci Aktivasi ---
API_URL="http://zivpn.nizwara.biz.id/claim_key.php"

clear
echo ""
echo -e "${YELLOW}┌──────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│   Silakan masukkan Kunci Aktivasi Anda   │${NC}"
echo -e "${YELLOW}└──────────────────────────────────────────┘${NC}"
echo -n -e "${WHITE}└──> ${NC}"
read AUTH_KEY

if [ -z "$AUTH_KEY" ]; then
    echo -e "\n${RED}Kunci Aktivasi tidak boleh kosong. Instalasi dibatalkan.${NC}"
    exit 1
fi

# Dapatkan IP server
SERVER_IP=$(curl -s ifconfig.me)
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
fi

if [ -z "$SERVER_IP" ]; then
    echo -e "\n${RED}Gagal mendapatkan IP server. Periksa koneksi internet Anda.${NC}"
    exit 1
fi

echo -e "\n${WHITE}Mengecek Kunci Aktivasi...${NC}"

# Kirim permintaan ke API
API_RESPONSE=$(curl -s -X POST "$API_URL" --data-urlencode "key=$AUTH_KEY" --data-urlencode "ip=$SERVER_IP")

# Proses respons dari API
RESPONSE_STATUS=$(echo "$API_RESPONSE" | cut -d'|' -f1)
RESPONSE_MESSAGE=$(echo "$API_RESPONSE" | cut -d'|' -f2-)

if [ "$RESPONSE_STATUS" == "SUCCESS" ]; then
    CLIENT_NAME=$(echo "$RESPONSE_MESSAGE" | cut -d'|' -f1)
    EXPIRY_DATE=$(echo "$RESPONSE_MESSAGE" | cut -d'|' -f2)

    # Simpan informasi lisensi
    sudo mkdir -p /etc/zivpn
    echo "CLIENT_NAME=\"$CLIENT_NAME\"" > /etc/zivpn/license.conf
    echo "EXPIRY_DATE=$EXPIRY_DATE" >> /etc/zivpn/license.conf

    echo ""
    echo -e "${YELLOW}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│         LISENSI BERHASIL DIAKTIVASI          │${NC}"
    echo -e "${YELLOW}├──────────────────────────────────────────────┤${NC}"
    printf "${YELLOW}│ ${WHITE}%-12s: ${YELLOW}%-29s ${YELLOW}│${NC}\n" "Klien" "$CLIENT_NAME"
    printf "${YELLOW}│ ${WHITE}%-12s: ${YELLOW}%-29s ${YELLOW}│${NC}\n" "Kedaluwarsa" "$EXPIRY_DATE"
    echo -e "${YELLOW}└──────────────────────────────────────────────┘${NC}"
    echo ""
    sleep 3
else
    ERROR_REASON=$(echo "$RESPONSE_MESSAGE" | cut -d'|' -f1)
    echo -e "\n${RED}Aktivasi Gagal! ${NC}$ERROR_REASON.${NC}"
    echo -e "${RED}Instalasi dibatalkan. Silakan hubungi developer.${NC}"
    exit 1
fi
# --- Akhir Validasi Lisensi ---

# Fix for sudo: unable to resolve host
HOSTNAME=$(hostname)
if ! grep -q "127.0.0.1 $HOSTNAME" /etc/hosts; then
    echo "Adding $HOSTNAME to /etc/hosts"
    sudo bash -c "echo '127.0.0.1 $HOSTNAME' >> /etc/hosts"
fi

echo -e "Updating server"
sudo apt-get update && sudo apt-get upgrade -y
if ! command -v ufw &> /dev/null
then
    echo "ufw could not be found, installing it now..."
    sudo apt-get install ufw -y
fi
if ! command -v jq &> /dev/null
then
    echo "jq could not be found, installing it now..."
    sudo apt-get install jq -y
fi
if ! command -v curl &> /dev/null
then
    echo "curl could not be found, installing it now..."
    sudo apt-get install curl -y
fi

# Meminta domain dari pengguna
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RED='\033[1;31m'
NC='\033[0m'
echo -e "${YELLOW}┌──────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│   Silakan masukkan nama domain Anda      │${NC}"
echo -e "${YELLOW}└──────────────────────────────────────────┘${NC}"
echo -n -e "${WHITE}└──> ${NC}"
read user_domain
if [ -z "$user_domain" ]; then
    echo -e "${RED}Nama domain tidak boleh kosong. Menggunakan hostname sebagai fallback.${NC}"
    user_domain=$(hostname)
fi
echo "Domain Anda akan disimpan sebagai: $user_domain"
sleep 2

if ! command -v figlet &> /dev/null; then
    echo "figlet not found, installing..."
    sudo apt-get install -y figlet
fi

if ! command -v lolcat &> /dev/null; then
    echo "lolcat not found, installing..."
    sudo apt-get install -y ruby-full
    sudo gem install lolcat
fi


# Stop service kalau ada
sudo systemctl stop zivpn.service > /dev/null 2>&1

echo -e "Downloading UDP Service"
sudo wget https://github.com/Nizwarax/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64 -O /usr/local/bin/zivpn-bin
sudo chmod +x /usr/local/bin/zivpn-bin
sudo mkdir -p /etc/zivpn
sudo wget https://raw.githubusercontent.com/Nizwarax/udp-zivpn/main/config.json -O /etc/zivpn/config.json

echo "Generating cert files:"
sudo openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt"
sudo sysctl -w net.core.rmem_max=16777216 > /dev/null
sudo sysctl -w net.core.wmem_max=16777216 > /dev/null

sudo tee /etc/systemd/system/zivpn.service > /dev/null <<EOF
[Unit]
Description=zivpn VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn-bin server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# Buat file database pengguna awal, file tema, dan file domain
sudo bash -c 'echo "[]" > /etc/zivpn/users.db.json'
sudo bash -c 'echo "rainbow" > /etc/zivpn/theme.conf'
sudo bash -c "echo \"$user_domain\" > /etc/zivpn/domain.conf"

# Bersihin iptables rules yang lama
INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
while sudo iptables -t nat -D PREROUTING -i $INTERFACE -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null; do :; done
sudo iptables -t nat -A PREROUTING -i $INTERFACE -p udp --dport 6000:19999 -j DNAT --to-destination :5667
sudo iptables -A FORWARD -p udp -d 127.0.0.1 --dport 5667 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 127.0.0.1/32 -o $INTERFACE -j MASQUERADE
sudo apt install iptables-persistent -y -qq
sudo netfilter-persistent save > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable zivpn.service
sudo systemctl start zivpn.service
sudo ufw allow 6000:19999/udp > /dev/null
sudo ufw allow 5667/udp > /dev/null

sudo wget -O /usr/local/bin/zivpn https://raw.githubusercontent.com/Nizwarax/udp-zivpn/main/zivpn-menu.sh
sudo chmod +x /usr/local/bin/zivpn

# Unduh skrip uninstall dan letakkan di path yang dapat diakses
sudo wget -O /usr/local/bin/uninstall.sh https://raw.githubusercontent.com/Nizwarax/udp-zivpn/main/uninstall.sh
sudo chmod +x /usr/local/bin/uninstall.sh

# Pasang skrip pembersihan otomatis dan jadwalkan
sudo wget -O /usr/local/bin/zivpn-cleanup.sh https://raw.githubusercontent.com/Nizwarax/udp-zivpn/main/zivpn-cleanup.sh
sudo chmod +x /usr/local/bin/zivpn-cleanup.sh
sudo wget -O /usr/local/bin/zivpn-autobackup.sh https://raw.githubusercontent.com/Nizwarax/zivpn-udp/main/zivpn-autobackup.sh
sudo chmod +x /usr/local/bin/zivpn-autobackup.sh
# Pasang skrip pemantauan server
sudo wget -O /usr/local/bin/zivpn-monitor.sh https://raw.githubusercontent.com/Nizwarax/udp-zivpn/main/zivpn-monitor.sh
sudo chmod +x /usr/local/bin/zivpn-monitor.sh

# Jalankan setiap menit untuk penghapusan yang mendekati real-time
sudo bash -c 'echo "* * * * * root /usr/local/bin/zivpn-cleanup.sh" > /etc/cron.d/zivpn-cleanup'
# Jalankan pemantauan server setiap 5 menit
sudo bash -c 'echo "*/5 * * * * root /usr/local/bin/zivpn-monitor.sh" > /etc/cron.d/zivpn-monitor'

# Pasang skrip MOTD (Message of the Day)
sudo wget -O /etc/profile.d/zivpn-motd.sh https://raw.githubusercontent.com/Nizwarax/udp-zivpn/main/zivpn-motd.sh
sudo chmod +x /etc/profile.d/zivpn-motd.sh

# Pesan Selesai Instalasi
clear
echo -e "\n${GREEN}============================================${NC}"
echo -e "      ✅ ${WHITE}Instalasi ZIVPN Selesai!${NC} ✅"
echo -e "${GREEN}============================================${NC}"
echo -e "${WHITE}Untuk membuka menu, ketik:${NC} ${YELLOW}zivpn${NC}"
echo -e "${WHITE}Pesan selamat datang akan muncul setiap kali Anda login.${NC}\n"

# Cleanup
rm -f zi2.sh* zi-fixed.sh* > /dev/null 2>&1
