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

# Fungsi bantuan untuk menyinkronkan kata sandi dari user.db.json ke config.json
sync_config() {
    passwords=$(jq -r '.[].password' "$USER_DB")
    jq --argjson passwords "$(echo "$passwords" | jq -R . | jq -s .)" '.config = $passwords' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    sudo systemctl restart zivpn.service
}

# Fungsi untuk menambahkan akun
add_account() {
    clear
    echo -e "${YELLOW}--- Add Account ---${NC}"
    read -p "Enter username: " username
    # Periksa apakah pengguna sudah ada
    if jq -e --arg user "$username" '.[] | select(.username == $user)' "$USER_DB" > /dev/null; then
        echo -e "${RED}Error: Username '$username' already exists.${NC}"
        sleep 2
        return
    fi

    read -p "Enter password: " password
    read -p "Enter duration (in days): " duration

    expiry_date=$(date -d "+$duration days" +%Y-%m-%d)

    new_user=$(jq -n --arg user "$username" --arg pass "$password" --arg expiry "$expiry_date" \
        '{username: $user, password: $pass, expiry_date: $expiry}')

    jq ". += [$new_user]" "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"

    echo -e "${GREEN}Account '$username' created successfully. Expires on $expiry_date.${NC}"
    sync_config
    sleep 2
}

# Fungsi untuk menampilkan daftar akun
list_accounts() {
    clear
    echo -e "${YELLOW}--- Account Details ---${NC}"
    printf "${BLUE}%-20s | %-20s | %-15s${NC}\n" "Username" "Password" "Expiry Date"
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    jq -r '.[] | "\(.username) | \(.password) | \(.expiry_date)"' "$USER_DB" | while IFS="|" read -r user pass expiry; do
        printf "${WHITE}%-20s | %-20s | %-15s${NC}\n" "$user" "$pass" "$expiry"
    done
    echo -e "${BLUE}------------------------------------------------------------${NC}"
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

    jq 'del(.[] | select(.username == $user))' "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"
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
    new_expiry_date=$(date -d "+$duration days" +%Y-%m-%d)

    jq '(.[] | select(.username == $user) | .expiry_date) |= $new_expiry' --arg user "$username" --arg new_expiry "$new_expiry_date" "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"

    echo -e "${GREEN}Expiry date for '$username' updated to $new_expiry_date.${NC}"
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

    jq '(.[] | select(.username == $user) | .password) |= $new_pass' --arg user "$username" --arg new_pass "$new_password" "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"

    echo -e "${GREEN}Password for '$username' has been updated.${NC}"
    sync_config
    sleep 2
}

# Fungsi untuk menghapus akun yang sudah kedaluwarsa
remove_expired() {
    clear
    echo -e "${YELLOW}--- Remove Expired Accounts ---${NC}"
    today=$(date +%Y-%m-%d)

    expired_users=$(jq -r --arg today "$today" '.[] | select(.expiry_date < $today) | .username' "$USER_DB" | tr '\n' ' ')

    if [ -z "$expired_users" ]; then
        echo -e "${WHITE}No expired accounts found.${NC}"
    else
        jq 'map(select(.expiry_date >= $today))' --arg today "$today" "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"
        echo -e "${GREEN}Removed expired users: $expired_users${NC}"
        sync_config
    fi
    read -p "Press [Enter] to continue..."
}


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

# Fungsi untuk panduan uninstall
uninstall_guide() {
    clear
    echo -e "${YELLOW}--- Uninstall Guide ---${NC}"
    echo -e "${WHITE}To uninstall ZIVPN and the management panel, please run the following command:${NC}"
    echo ""
    echo -e "${YELLOW}wget -O uninstall.sh https://raw.githubusercontent.com/Nizwarax/udp-zivpn/main/uninstall.sh && chmod +x uninstall.sh && ./uninstall.sh${NC}"
    echo ""
    read -p "Press [Enter] to continue..."
}


# Fungsi untuk menampilkan menu
show_menu() {
    clear
    echo -e "${BLUE}__/\__   /()\\  //\\   /\\ \\\\/\\${NC}"
    echo -e "${BLUE}\\    //\\\\//\\\\//  \\\\//\\\\ \\/${NC}"
    echo -e "${BLUE}/ \\ //\\\\ \\/ / \\ //\\\\ /_ \\${NC}"
    echo -e "${BLUE}\\/___-II_\\/ |-| |-|_\/ \\/${NC}"
    echo ""
    echo -e "${WHITE}    ZIVPN MANAGER - v1.5 for @lstunnels${NC}"
    echo -e "${WHITE}    by: @deviyke, @Kwadeous & @voltsshx${NC}"
    echo -e "${YELLOW}==========================================${NC}"
    echo -e "${YELLOW}||${WHITE}          ACCOUNT MANAGEMENT PANEL </>         ${YELLOW}||${NC}"
    echo -e "${YELLOW}==========================================${NC}"
    IP_ADDRESS=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    echo -e "${WHITE}🌍 Public IP Address: < ${YELLOW}$IP_ADDRESS${WHITE} >${NC}"
    echo -e "${BLUE}<<< === === === === === === === >>>${NC}"
    echo -e "${WHITE}[1] 📖 Add Account${NC}"
    echo -e "${WHITE}[2] 📄 List Account Details${NC}"
    echo -e "${WHITE}[3] 🗑️ Delete Account${NC}"
    echo -e "${WHITE}[4] 📅 Edit Account Expiry Date${NC}"
    echo -e "${WHITE}[5] 🔄 Full Backup/Restore Acc.${NC}"
    echo -e "${WHITE}[6] 🔑 Edit Account Password${NC}"
    echo -e "${WHITE}[7] 🧹 Remove Expired Accounts${NC}"
    echo -e "${WHITE}[8] 🖥️ VPS Info${NC}"
    echo -e "${BLUE}<<< ... ... ... >>>${NC}"
    echo -e "${WHITE}[9] ❓ Uninstall Guide${NC}"
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
        2) list_accounts ;;
        3) delete_account ;;
        4) edit_expiry ;;
        5) backup_restore ;;
        6) edit_password ;;
        7) remove_expired ;;
        8) vps_info ;;
        9) uninstall_guide ;;
        0) exit 0 ;;
        *)
            echo -e "${RED}Opsi tidak valid, silakan coba lagi.${NC}"
            sleep 2
            ;;
    esac
done
