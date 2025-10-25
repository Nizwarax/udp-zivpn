#!/bin/bash

# Fungsi untuk menampilkan menu
show_menu() {
    clear
    echo " __/\\__ /\\_ /\\    //\\  \\ \\ \\ \\__"
    echo " \\  // \\ \\ \\ \\  //__\\  \\ \\ \\ \\"
    echo " /_//_/\\ \\ \\_\\ \\//    \\  \\ \\ \\_\\"
    echo " \\/ __/\\_\\/ /_/ \\/      \\  \\ \\/ /"
    echo ""
    echo "ZIVPN MANAGER - v1.5"
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    echo "Server IP Address: $IP_ADDRESS"
    echo ""
    echo "-----------------------------------------------------"
    echo " [01] • Buat Kata Sandi AUTH [02] • Daftar Kata Sandi Auth"
    echo " [03] • Mulai Ulang Layanan ZIVPN [04] • Info Sistem"
    echo ""
    echo " [99] • Reboot Server [00] • Keluar"
    echo "-----------------------------------------------------"
    echo -n "Pilih menu : "
}

# Fungsi untuk opsi menu
create_auth() {
    echo "Masukkan kata sandi baru:"
    read -r new_password
    if [ -z "$new_password" ]; then
        echo "Kata sandi tidak boleh kosong."
        sleep 2
        return
    fi

    # Baca file konfigurasi, tambahkan kata sandi baru, dan tulis kembali
    jq ".config += [\"$new_password\"]" /etc/zivpn/config.json > /tmp/config.json.tmp && mv /tmp/config.json.tmp /etc/zivpn/config.json

    echo "Kata sandi '$new_password' berhasil ditambahkan."
    echo "Memulai ulang ZIVPN untuk menerapkan perubahan..."
    sudo systemctl restart zivpn.service
    sleep 2
}

list_auth() {
    echo "Daftar Kata Sandi AUTH yang Ada:"
    # Gunakan jq untuk mengekstrak dan menampilkan kata sandi
    jq -r '.config[]' /etc/zivpn/config.json
    read -p "Tekan [Enter] untuk melanjutkan..."
}

restart_service() {
    echo "Memulai ulang layanan ZIVPN..."
    sudo systemctl restart zivpn.service
    if [ $? -eq 0 ]; then
        echo "Layanan ZIVPN berhasil dimulai ulang."
    else
        echo "Gagal memulai ulang layanan ZIVPN."
    fi
    sleep 2
}

system_info() {
    clear
    echo "Informasi Sistem:"
    echo "-------------------"
    echo "Hostname: $(hostname)"
    echo "Distro: $(grep PRETTY_NAME /etc/os-release | cut -d'=' -f2 | tr -d '\"')"
    echo "Uptime: $(uptime -p)"
    echo "Kernel: $(uname -r)"
    echo "-------------------"
    read -p "Tekan [Enter] untuk melanjutkan..."
}

reboot_server() {
    read -p "Apakah Anda yakin ingin me-reboot server? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "Mem-boot ulang server..."
        sudo reboot
    else
        echo "Reboot dibatalkan."
        sleep 2
    fi
}

# Loop utama
while true; do
    show_menu
    read -r choice
    case $choice in
        1|01)
            create_auth
            ;;
        2|02)
            list_auth
            ;;
        3|03)
            restart_service
            ;;
        4|04)
            system_info
            ;;
        99)
            reboot_server
            ;;
        0|00)
            exit 0
            ;;
        *)
            echo "Opsi tidak valid, silakan coba lagi."
            sleep 2
            ;;
    esac
done
