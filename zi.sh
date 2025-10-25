#!/bin/bash
# Zivpn UDP Module installer
# Creator Zahid Islam

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

sudo systemctl stop zivpn.service > /dev/null 2>&1

echo -e "Downloading UDP Service"
sudo wget https://github.com/Nizwarax/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn
sudo chmod +x /usr/local/bin/zivpn
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
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
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

# Sinkronkan config.json dengan pengguna awal
passwords=$(sudo jq -r '.[].password' "/etc/zivpn/users.db.json")
sudo bash -c "jq --argjson passwords '$(echo "$passwords" | jq -R . | jq -s .)' '.config = \$passwords' /etc/zivpn/config.json > /etc/zivpn/config.json.tmp && mv /etc/zivpn/config.json.tmp /etc/zivpn/config.json"

sudo systemctl daemon-reload
sudo systemctl enable zivpn.service
sudo systemctl start zivpn.service
sudo iptables -t nat -A PREROUTING -i $(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1) -p udp --dport 6000:19999 -j DNAT --to-destination :5667
sudo ufw allow 6000:19999/udp > /dev/null
sudo ufw allow 5667/udp > /dev/null

sudo wget -O /usr/local/bin/zivpn-menu https://raw.githubusercontent.com/Nizwarax/udp-zivpn/main/zivpn-menu.sh
sudo chmod +x /usr/local/bin/zivpn-menu

rm zi.sh* > /dev/null 2>&1
echo -e "ZIVPN UDP Installed"
echo -e "Run 'zivpn-menu' to access the management panel."
