#!/bin/bash
# Zivpn UDP Module installer - Fixed for x86_64 and password sync
# Creator Deki_niswara

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

# Stop service kalau ada
sudo systemctl stop zivpn.service > /dev/null 2>&1

echo -e "Downloading UDP Service"
sudo wget https://github.com/Nizwarax/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn-bin
sudo chmod +x /usr/local/bin/zivpn-bin
sudo mkdir -p /etc/zivpn
sudo wget https://raw.githubusercontent.com/Nizwarax/udp-zivpn/main/config.json -O /etc/zivpn/config.json

echo "Generating cert files:"
sudo openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt"
sudo sysctl -w net.core.rmem_max=16777216 > /dev/null
sudo sysctl -w net.core.wmem_max=16777216 > /dev/null

sudo bash -c 'cat <<EOF > /etc/systemd/system/zivpn.service
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
EOF'

# Buat file database pengguna awal
sudo bash -c 'echo "[]" > /etc/zivpn/users.db.json'

echo -e "ZIVPN UDP Initial User"
read -p "Enter username for the first account: " initial_username
read -p "Enter password for the first account: " initial_password
read -p "Enter duration (in days) for the first account [Default: 30]: " initial_duration
initial_duration=${initial_duration:-30}

# Tambahkan pengguna awal ke database
expiry_date=$(date -d "+$initial_duration days" +%Y-%m-%d)
first_user=$(jq -n --arg user "$initial_username" --arg pass "$initial_password" --arg expiry "$expiry_date" \
    '{username: $user, password: $pass, expiry_date: $expiry}')
sudo bash -c "jq '. += [$first_user]' /etc/zivpn/users.db.json > /etc/zivpn/users.db.json.tmp && mv /etc/zivpn/users.db.json.tmp /etc/zivpn/users.db.json"

# Sinkronkan password ke auth.config DAN config di config.json
passwords=$(sudo jq -r '.[].password' "/etc/zivpn/users.db.json")
sudo bash -c "jq --argjson passwords '$(echo "$passwords" | jq -R . | jq -s .)' '.auth.config = \$passwords | .config = \$passwords' /etc/zivpn/config.json > /etc/zivpn/config.json.tmp && mv /etc/zivpn/config.json.tmp /etc/zivpn/config.json"

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

# Get Public IP
IP_ADDRESS=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

# Define Colors
BLUE='\033[1;34m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Clear the screen for a clean output
clear

# Display Welcome Message
echo -e "${BLUE}__/\__   /()\\  //\\   /\\ \\\\/\\${NC}"
echo -e "${BLUE}\\    //\\\\//\\\\//  \\\\//\\\\ \\/${NC}"
echo -e "${BLUE}/ \\ //\\\\ \\/ / \\ //\\\\ /_ \\${NC}"
echo -e "${BLUE}\\/___-II_\\/ |-| |-|_\/ \\/${NC}"
echo ""
echo -e "${WHITE}ZIVPN MANAGER - v1.5${NC}"
echo -e "${WHITE}Server IP Address: ${IP_ADDRESS}${NC}"
echo -e "${WHITE}Run the command 'zivpn' to access the panel.${NC}"
echo -e "${YELLOW}Contact us on Telegram (@Deki_niswara) for support.${NC}"
echo ""

# Cleanup
rm zi-fixed.sh* > /dev/null 2>&1
