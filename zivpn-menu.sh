#!/bin/bash

USER_DB="/etc/zivpn/users.db.json"
CONFIG_FILE="/etc/zivpn/config.json"

# --- Colors ---
BLUE='\033[1;34m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# --- Functions from original script that were removed ---

# Fungsi untuk mencadangkan dan memulihkan
backup_restore() {
    clear
    echo -e "${YELLOW}--- Full Backup/Restore ---${NC}"
    echo -e "${WHITE}1. Create Backup${NC}"
    echo -e "${WHITE}2. Restore from Backup${NC}"
    read -p "Choose an option: " choice

    case $choice in
        1)
            backup_file="/root/zivpn_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
            tar -czf "$backup_file" -C /etc/zivpn .
            echo -e "${GREEN}Backup created successfully at $backup_file${NC}"
            ;;
        2)
            read -p "Enter the full path to the backup file: " backup_file
            if [ -f "$backup_file" ]; then
                tar -xzf "$backup_file" -C /etc/zivpn
                echo -e "${GREEN}Restore successful. Restarting service...${NC}"
                sync_config
            else
                echo -e "${RED}Error: Backup file not found.${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
    read -p "Press [Enter] to continue..."
}

# Fungsi untuk info VPS
vps_info() {
    clear
    echo -e "${YELLOW}--- VPS Info ---${NC}"
    echo -e "${WHITE}Hostname: $(hostname)${NC}"
    echo -e "${WHITE}OS: $(grep PRETTY_NAME /etc/os-release | cut -d'=' -f2 | tr -d '\"')${NC}"
    echo -e "${WHITE}Kernel: $(uname -r)${NC}"
    echo -e "${WHITE}Uptime: $(uptime -p)${NC}"
    echo -e "${WHITE}Public IP: $(curl -s ifconfig.me || hostname -I | awk '{print $1}')${NC}"
    echo -e "${WHITE}CPU: $(lscpu | grep 'Model name' | awk -F: '{print $2}' | sed 's/^[ \t]*//')${NC}"
    echo -e "${WHITE}RAM: $(free -h | grep Mem | awk '{print $2}')${NC}"
    echo -e "${WHITE}Disk: $(df -h / | tail -n 1 | awk '{print $2}')${NC}"
    read -p "Press [Enter] to continue..."
}

# Fungsi untuk uninstall interaktif
interactive_uninstall() {
    clear
    echo -e "${YELLOW}--- Uninstall ZIVPN ---${NC}"

    # Periksa apakah skrip uninstall ada di lokasi yang diharapkan
    UNINSTALL_SCRIPT="/usr/local/bin/uninstall.sh"
    if [ ! -f "$UNINSTALL_SCRIPT" ]; then
        echo -e "${RED}Gagal menemukan skrip uninstall di $UNINSTALL_SCRIPT.${NC}"
        echo -e "${WHITE}Pastikan Zivpn diinstal dengan benar.${NC}"
        sleep 3
        return
    fi

    read -p "Anda yakin ingin uninstall ZIVPN? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${WHITE}Memulai proses uninstall...${NC}"
        # Jalankan skrip dari path absolutnya
        sudo bash "$UNINSTALL_SCRIPT"
        # Jika uninstall berhasil, keluar dari menu karena layanan sudah tidak ada
        echo -e "${GREEN}Kembali ke terminal...${NC}"
        exit 0
    else
        echo -e "${GREEN}Proses uninstall dibatalkan.${NC}"
        sleep 2
    fi
}

# --- END of restored functions ---

# Fungsi untuk mengonfigurasi pengaturan bot Telegram
configure_bot_settings() {
    clear
    BOT_CONFIG="/etc/zivpn/bot_config.sh"

    # Muat konfigurasi yang ada jika file ada
    if [ -f "$BOT_CONFIG" ]; then
        source "$BOT_CONFIG"
    fi

    echo -e "${YELLOW}--- Konfigurasi Notifikasi Bot Telegram ---${NC}"
    echo -e "${WHITE}Masukkan detail bot Anda. Biarkan kosong untuk tidak mengubah nilai saat ini.${NC}"

    # Minta Bot Token
    read -p "Masukkan Bot Token Anda [saat ini: ${BOT_TOKEN:-'tidak diatur'}]: " new_token
    if [ -n "$new_token" ]; then
        BOT_TOKEN="$new_token"
    fi

    # Minta Chat ID
    read -p "Masukkan Chat ID Anda [saat ini: ${CHAT_ID:-'tidak diatur'}]: " new_chat_id
    if [ -n "$new_chat_id" ]; then
        CHAT_ID="$new_chat_id"
    fi

    # Simpan konfigurasi ke file
    echo "#!/bin/bash" > "$BOT_CONFIG"
    echo "BOT_TOKEN='${BOT_TOKEN}'" >> "$BOT_CONFIG"
    echo "CHAT_ID='${CHAT_ID}'" >> "$BOT_CONFIG"

    echo -e "${GREEN}Pengaturan bot berhasil disimpan di $BOT_CONFIG${NC}"
    sleep 2
}

# Fungsi untuk mengirim notifikasi ke Telegram
send_notification() {
    local message="$1"
    BOT_CONFIG="/etc/zivpn/bot_config.sh"

    # Periksa apakah file konfigurasi ada dan dapat dibaca
    if [ -f "$BOT_CONFIG" ]; then
        source "$BOT_CONFIG"
    else
        # Jangan tampilkan error jika bot tidak dikonfigurasi
        return
    fi

    # Periksa apakah token dan ID ada isinya
    if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
        return
    fi

    # Kirim pesan menggunakan curl dalam mode senyap
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
         -d "chat_id=${CHAT_ID}" \
         -d "text=${message}" \
         -d "parse_mode=HTML" > /dev/null
}


# Fungsi bantuan untuk menyinkronkan kata sandi dari user.db.json ke config.json
sync_config() {
    # Ekstrak semua kata sandi ke dalam array JSON menggunakan map
    passwords_json=$(jq '[.[].password]' "$USER_DB")

    # Perbarui file konfigurasi utama dengan array kata sandi yang baru
    # Gunakan --argjson untuk memasukkan array JSON dengan aman
    jq --argjson passwords "$passwords_json" '.auth.config = $passwords | .config = $passwords' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

    # Muat ulang dan restart layanan untuk menerapkan perubahan
    sudo systemctl daemon-reload
    sudo systemctl restart zivpn.service > /dev/null 2>&1
}

# Fungsi untuk menambahkan akun reguler
add_account() {
    clear
    echo -e "${YELLOW}--- Add Regular Account ---${NC}"
    read -p "Enter username: " username
    if jq -e --arg user "$username" '.[] | select(.username == $user)' "$USER_DB" > /dev/null; then
        echo -e "${RED}Error: Username '$username' already exists.${NC}"
        sleep 2
        return
    fi

    read -p "Enter password: " password
    read -p "Enter duration (in days, default: 30): " duration
    [[ -z "$duration" ]] && duration=30

    expiry_timestamp=$(date -d "+$duration days" +%s)
    expiry_readable=$(date -d "@$expiry_timestamp" '+%Y-%m-%d %H:%M:%S')

    new_user_json=$(jq -n --arg user "$username" --arg pass "$password" --argjson expiry "$expiry_timestamp" \
        '{username: $user, password: $pass, expiry_timestamp: $expiry}')

    jq --argjson new_user "$new_user_json" '. += [$new_user]' "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"

    # Tampilkan detail di terminal dan kirim notifikasi
    IP_ADDRESS=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

    # Format untuk terminal
    expiry_date_only=$(date -d "@$expiry_timestamp" '+%d-%m-%Y')
    echo -e "${YELLOW}────────────────────${NC}"
    echo -e "${GREEN}    ☘ NEW ACCOUNT DETAIL ☘${NC}"
    echo -e "${YELLOW}────────────────────${NC}"
    echo -e "${WHITE}User      : $username${NC}"
    echo -e "${WHITE}Password  : $password${NC}"
    echo -e "${WHITE}IP VPS    : $IP_ADDRESS${NC}"
    echo -e "${WHITE}EXP       : $expiry_date_only / $duration HARI${NC}"
    echo -e "${YELLOW}────────────────────${NC}"

    # Format untuk Telegram (menggunakan tag HTML untuk tebal)
    message="────────────────────%0A"
    message+="    ☘ <b>NEW ACCOUNT DETAIL</b> ☘%0A"
    message+="────────────────────%0A"
    message+="<b>User</b>      : <code>${username}</code>%0A"
    message+="<b>Password</b>  : <code>${password}</code>%0A"
    message+="<b>IP VPS</b>    : <code>${IP_ADDRESS}</code>%0A"
    message+="<b>EXP</b>       : <code>${expiry_date_only} / ${duration} HARI</code>%0A"
    message+="────────────────────%0A"
    message+="Note: Auto notif from your script..."

    send_notification "$message"

    sync_config
    read -p "Press [Enter] to continue..."
}

# Fungsi untuk menambahkan akun trial
add_trial_account() {
    clear
    echo -e "${YELLOW}--- Add Trial Account ---${NC}"
    read -p "Enter username (e.g., trial-user): " username
    if jq -e --arg user "$username" '.[] | select(.username == $user)' "$USER_DB" > /dev/null; then
        echo -e "${RED}Error: Username '$username' already exists.${NC}"
        sleep 2
        return
    fi
    [[ -z "$username" ]] && username="trial-$(date +%s)"


    read -p "Enter password (or leave empty for random): " password
    [[ -z "$password" ]] && password=$(head -c 8 /dev/urandom | base64)

    read -p "Enter duration (in minutes, default: 60): " duration
    [[ -z "$duration" ]] && duration=60

    expiry_timestamp=$(date -d "+$duration minutes" +%s)
    expiry_readable=$(date -d "@$expiry_timestamp" '+%Y-%m-%d %H:%M:%S')

    new_user_json=$(jq -n --arg user "$username" --arg pass "$password" --argjson expiry "$expiry_timestamp" \
        '{username: $user, password: $pass, expiry_timestamp: $expiry}')

    jq --argjson new_user "$new_user_json" '. += [$new_user]' "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"

    # Tampilkan detail di terminal dan kirim notifikasi
    IP_ADDRESS=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

    # Format untuk terminal
    expiry_date_only=$(date -d "@$expiry_timestamp" '+%d-%m-%Y %H:%M')
    echo -e "${YELLOW}────────────────────${NC}"
    echo -e "${GREEN}    ☘ NEW TRIAL ACCOUNT ☘${NC}"
    echo -e "${YELLOW}────────────────────${NC}"
    echo -e "${WHITE}User      : $username${NC}"
    echo -e "${WHITE}Password  : $password${NC}"
    echo -e "${WHITE}IP VPS    : $IP_ADDRESS${NC}"
    echo -e "${WHITE}EXP       : $expiry_date_only / $duration MENIT${NC}"
    echo -e "${YELLOW}────────────────────${NC}"

    # Format untuk Telegram
    message="────────────────────%0A"
    message+="    ☘ <b>NEW TRIAL ACCOUNT</b> ☘%0A"
    message+="────────────────────%0A"
    message+="<b>User</b>      : <code>${username}</code>%0A"
    message+="<b>Password</b>  : <code>${password}</code>%0A"
    message+="<b>IP VPS</b>    : <code>${IP_ADDRESS}</code>%0A"
    message+="<b>EXP</b>       : <code>${expiry_date_only} / ${duration} MENIT</code>%0A"
    message+="────────────────────%0A"
    message+="Note: Auto notif from your script..."

    send_notification "$message"

    sync_config
    read -p "Press [Enter] to continue..."
}


# Fungsi untuk menampilkan daftar akun
list_accounts() {
    clear
    echo -e "${YELLOW}--- Account Details ---${NC}"
    printf "${BLUE}%-20s | %-20s | %-25s${NC}\n" "Username" "Password" "Status"
    echo -e "${BLUE}-------------------------------------------------------------------${NC}"

    # Proses seluruh logika di dalam satu panggilan jq untuk efisiensi
    jq -r --argjson now "$(date +%s)" '
        .[] |
        . as $user |
        (
            ($user.expiry_timestamp // ($user.expiry_date | fromdate)) as $expiry_ts |
            ($expiry_ts - $now) as $remaining_seconds |
            if $remaining_seconds <= 0 then
                "\u001b[1;31mKedaluwarsa\u001b[0m"
            else
                ($remaining_seconds / 86400 | floor) as $days |
                (($remaining_seconds % 86400) / 3600 | floor) as $hours |
                (($remaining_seconds % 3600) / 60 | floor) as $minutes |
                if $days > 0 then
                    "\u001b[1;32mSisa \($days) hari, \($hours) jam\u001b[0m"
                elif $hours > 0 then
                    "\u001b[1;33mSisa \($hours) jam, \($minutes) mnt\u001b[0m"
                else
                    "\u001b[1;33mSisa \($minutes) menit\u001b[0m"
                end
            end
        ) as $status |
        [$user.username, $user.password, $status] |
        @tsv' "$USER_DB" |
    while IFS=$'\t' read -r user pass status; do
        printf "${WHITE}%-20s | %-20s | %b${NC}\n" "$user" "$pass" "$status"
    done

    echo -e "${BLUE}-------------------------------------------------------------------${NC}"
    read -p "Press [Enter] to continue..."
}

# Fungsi untuk menghapus akun
delete_account() {
    clear
    echo -e "${YELLOW}--- Delete Account ---${NC}"
    read -p "Enter username to delete: " username

    if ! jq -e --arg user "$username" '.[] | select(.username == $user)' "$USER_DB" > /dev/null; then
        echo -e "${RED}Error: Username '$username' not found.${NC}"
        sleep 2
        return
    fi

    jq --arg user "$username" 'del(.[] | select(.username == $user))' "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"
    echo -e "${GREEN}Account '$username' deleted successfully.${NC}"
    sync_config
    sleep 2
}

# Fungsi untuk mengedit tanggal kedaluwarsa
edit_expiry() {
    clear
    echo -e "${YELLOW}--- Edit Account Expiry Date ---${NC}"
    read -p "Enter username to edit: " username

    if ! jq -e --arg user "$username" '.[] | select(.username == $user)' "$USER_DB" > /dev/null; then
        echo -e "${RED}Error: Username '$username' not found.${NC}"
        sleep 2
        return
    fi

    read -p "Enter new duration (in days from today): " duration
    new_expiry_timestamp=$(date -d "+$duration days" +%s)

    # Hapus field lama jika ada
    jq --arg user "$username" --argjson new_expiry "$new_expiry_timestamp" \
       '(.[] | select(.username == $user) | .expiry_timestamp) = $new_expiry | del(.[] | select(.username == $user) | .expiry_date)' \
       "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"

    echo -e "${GREEN}Expiry date for '$username' updated.${NC}"
    sleep 2
}

# Fungsi untuk mengedit kata sandi
edit_password() {
    clear
    echo -e "${YELLOW}--- Edit Account Password ---${NC}"
    read -p "Enter username to edit: " username

    if ! jq -e --arg user "$username" '.[] | select(.username == $user)' "$USER_DB" > /dev/null; then
        echo -e "${RED}Error: Username '$username' not found.${NC}"
        sleep 2
        return
    fi

    read -p "Enter new password: " new_password

    jq --arg user "$username" --arg new_pass "$new_password" '(.[] | select(.username == $user) | .password) |= $new_pass' "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"

    echo -e "${GREEN}Password for '$username' has been updated.${NC}"
    sync_config
    sleep 2
}

# --- Tampilan Menu Utama ---
show_menu() {
    clear
    printf "${BLUE}      __________     ______  _   _      ${NC}\n"
    printf "${BLUE}__/\\_|__  /_ _\\ \\   / /  _ \\| \\ | |_/\\__${NC}\n"
    printf "${BLUE}\\\    / / / | | \\ \\ / /| |_) |  \\| \\    /${NC}\n"
    printf "${BLUE}/_  _\\/ /_ | |  \\ V / |  __/| |\\  /_  _\\\\${NC}\n"
    printf "${BLUE}  \\/ /____|___|  \\_/  |_|   |_| \\_| \\/  ${NC}\n"
    printf "${BLUE}                                        ${NC}\n"
    echo -e "${WHITE}    ZIVPN MANAGER - v2.0 (Advanced)${NC}"
    echo -e "${YELLOW}==========================================${NC}"
    IP_ADDRESS=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    echo -e "${WHITE}🌍 Public IP Address: < ${YELLOW}$IP_ADDRESS${WHITE} >${NC}"
    echo -e "${BLUE}<<< === === === === === === === >>>${NC}"
    echo -e "${WHITE}[1] ➕ Add Regular Account${NC}"
    echo -e "${WHITE}[2] ⏳ Add Trial Account${NC}"
    echo -e "${WHITE}[3] 📄 List Accounts${NC}"
    echo -e "${WHITE}[4] 🗑️ Delete Account${NC}"
    echo -e "${WHITE}[5] 📅 Edit Expiry Date${NC}"
    echo -e "${WHITE}[6] 🔑 Edit Password${NC}"
    echo -e "${WHITE}[7] 🔄 Full Backup/Restore${NC}"
    echo -e "${WHITE}[8] 🖥️ VPS Info${NC}"
    echo -e "${BLUE}<<< ... ... ... >>>${NC}"
    echo -e "${WHITE}[9] ⚙️ Atur Notifikasi Bot${NC}"
    echo -e "${WHITE}[10] ❌ Uninstall ZIVPN${NC}"
    echo -e "${WHITE}[0] 🚪 Exit${NC}"
    echo ""
    echo -n -e "${WHITE}//_-> Choose an option: ${NC}"
}


# Loop utama
while true; do
    show_menu
    read -r choice
    case $choice in
        1) add_account ;;
        2) add_trial_account ;;
        3) list_accounts ;;
        4) delete_account ;;
        5) edit_expiry ;;
        6) edit_password ;;
        7) backup_restore ;;
        8) vps_info ;;
        9) configure_bot_settings ;;
        10) interactive_uninstall ;;
        0) exit 0 ;;
        *)
            echo -e "${RED}Invalid option, please try again.${NC}"
            sleep 2
            ;;
    esac
done
