#!/bin/bash

USER_DB="/etc/zivpn/users.db.json"
CONFIG_FILE="/etc/zivpn/config.json"

# Fungsi bantuan untuk menyinkronkan kata sandi dari user.db.json ke config.json
sync_config() {
    passwords=$(jq -r '.[].password' "$USER_DB")
    jq --argjson passwords "$(echo "$passwords" | jq -R . | jq -s .)" '.config = $passwords' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    sudo systemctl restart zivpn.service
}

# Fungsi untuk menambahkan akun
add_account() {
    clear
    echo "--- Add Account ---"
    read -p "Enter username: " username
    # Periksa apakah pengguna sudah ada
    if jq -e --arg user "$username" '.[] | select(.username == $user)' "$USER_DB" > /dev/null; then
        echo "Error: Username '$username' already exists."
        sleep 2
        return
    fi

    read -p "Enter password: " password
    read -p "Enter duration (in days): " duration

    expiry_date=$(date -d "+$duration days" +%Y-%m-%d)

    new_user=$(jq -n --arg user "$username" --arg pass "$password" --arg expiry "$expiry_date" \
        '{username: $user, password: $pass, expiry_date: $expiry}')

    jq ". += [$new_user]" "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"

    echo "Account '$username' created successfully. Expires on $expiry_date."
    sync_config
    sleep 2
}

# Fungsi untuk menampilkan daftar akun
list_accounts() {
    clear
    echo "--- Account Details ---"
    printf "%-20s | %-20s | %-15s\n" "Username" "Password" "Expiry Date"
    echo "------------------------------------------------------------"
    jq -r '.[] | "\(.username) | \(.password) | \(.expiry_date)"' "$USER_DB" | while IFS="|" read -r user pass expiry; do
        printf "%-20s | %-20s | %-15s\n" "$user" "$pass" "$expiry"
    done
    echo "------------------------------------------------------------"
    read -p "Press [Enter] to continue..."
}

# Fungsi untuk menghapus akun
delete_account() {
    clear
    echo "--- Delete Account ---"
    read -p "Enter username to delete: " username

    if ! jq -e --arg user "$username" '.[] | select(.username == $user)' "$USER_DB" > /dev/null; then
        echo "Error: Username '$username' not found."
        sleep 2
        return
    fi

    jq 'del(.[] | select(.username == $user))' "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"
    echo "Account '$username' deleted successfully."
    sync_config
    sleep 2
}

# Fungsi untuk mengedit tanggal kedaluwarsa
edit_expiry() {
    clear
    echo "--- Edit Account Expiry Date ---"
    read -p "Enter username to edit: " username

    if ! jq -e --arg user "$username" '.[] | select(.username == $user)' "$USER_DB" > /dev/null; then
        echo "Error: Username '$username' not found."
        sleep 2
        return
    fi

    read -p "Enter new duration (in days from today): " duration
    new_expiry_date=$(date -d "+$duration days" +%Y-%m-%d)

    jq '(.[] | select(.username == $user) | .expiry_date) |= $new_expiry' --arg user "$username" --arg new_expiry "$new_expiry_date" "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"

    echo "Expiry date for '$username' updated to $new_expiry_date."
    sleep 2
}

# Fungsi untuk mengedit kata sandi
edit_password() {
    clear
    echo "--- Edit Account Password ---"
    read -p "Enter username to edit: " username

    if ! jq -e --arg user "$username" '.[] | select(.username == $user)' "$USER_DB" > /dev/null; then
        echo "Error: Username '$username' not found."
        sleep 2
        return
    fi

    read -p "Enter new password: " new_password

    jq '(.[] | select(.username == $user) | .password) |= $new_pass' --arg user "$username" --arg new_pass "$new_password" "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"

    echo "Password for '$username' has been updated."
    sync_config
    sleep 2
}

# Fungsi untuk menghapus akun yang sudah kedaluwarsa
remove_expired() {
    clear
    echo "--- Remove Expired Accounts ---"
    today=$(date +%Y-%m-%d)

    # Buat daftar pengguna yang kedaluwarsa sebelum menghapus untuk ditampilkan kepada pengguna
    expired_users=$(jq -r --arg today "$today" '.[] | select(.expiry_date < $today) | .username' "$USER_DB" | tr '\n' ' ')

    if [ -z "$expired_users" ]; then
        echo "No expired accounts found."
    else
        jq 'map(select(.expiry_date >= $today))' --arg today "$today" "$USER_DB" > "$USER_DB.tmp" && mv "$USER_DB.tmp" "$USER_DB"
        echo "Removed expired users: $expired_users"
        sync_config
    fi
    read -p "Press [Enter] to continue..."
}


# Fungsi untuk mencadangkan dan memulihkan
backup_restore() {
    clear
    echo "--- Full Backup/Restore ---"
    echo "1. Create Backup"
    echo "2. Restore from Backup"
    read -p "Choose an option: " choice

    case $choice in
        1)
            backup_file="/root/zivpn_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
            tar -czf "$backup_file" -C /etc/zivpn .
            echo "Backup created successfully at $backup_file"
            ;;
        2)
            read -p "Enter the full path to the backup file: " backup_file
            if [ -f "$backup_file" ]; then
                tar -xzf "$backup_file" -C /etc/zivpn
                echo "Restore successful. Restarting service..."
                sync_config
            else
                echo "Error: Backup file not found."
            fi
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
    read -p "Press [Enter] to continue..."
}

# Fungsi untuk info VPS
vps_info() {
    clear
    echo "--- VPS Info ---"
    echo "Hostname: $(hostname)"
    echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'=' -f2 | tr -d '\"')"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "Public IP: $(curl -s ifconfig.me || hostname -I | awk '{print $1}')"
    echo "CPU: $(lscpu | grep 'Model name' | awk -F: '{print $2}' | sed 's/^[ \t]*//')"
    echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
    echo "Disk: $(df -h / | tail -n 1 | awk '{print $2}')"
    read -p "Press [Enter] to continue..."
}

# Fungsi untuk panduan uninstall
uninstall_guide() {
    clear
    echo "--- Uninstall Guide ---"
    echo "To uninstall ZIVPN and the management panel, please run the following command:"
    echo ""
    echo "wget -O uninstall.sh https://raw.githubusercontent.com/Nizwarax/udp-zivpn/main/uninstall.sh && chmod +x uninstall.sh && ./uninstall.sh"
    echo ""
    read -p "Press [Enter] to continue..."
}


# Fungsi untuk menampilkan menu
show_menu() {
    clear
    echo "    __   ____ ___   _   __   __"
    echo "    \\ \\ / / _ \\__ \\ / |  \\ \\ / /"
    echo "     \\ V / | | | ) | |   \\ V /"
    echo "      | || |_| |/ /| |    | |"
    echo "      |_| \\___//____|_|    |_|"
    echo ""
    echo "    ZIVPN MANAGER - v1.5 for @lstunnels"
    echo "    by: @deviyke, @Kwadeous & @voltsshx"
    echo "=========================================="
    echo "||          ACCOUNT MANAGEMENT PANEL </>         ||"
    echo "=========================================="
    IP_ADDRESS=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    echo "🌍 Public IP Address: < $IP_ADDRESS >"
    echo "<<< === === === === === === === >>>"
    echo "[1] 📖 Add Account"
    echo "[2] 📄 List Account Details"
    echo "[3] 🗑️ Delete Account"
    echo "[4] 📅 Edit Account Expiry Date"
    echo "[5] 🔄 Full Backup/Restore Acc."
    echo "[6] 🔑 Edit Account Password"
    echo "[7] 🧹 Remove Expired Accounts"
    echo "[8] 🖥️ VPS Info"
    echo "<<< ... ... ... >>>"
    echo "[9] ❓ Uninstall Guide"
    echo "[0] 🚪 Exit"
    echo ""
    echo -n "//_-> Choose an option: "
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
            echo "Opsi tidak valid, silakan coba lagi."
            sleep 2
            ;;
    esac
done
