# Manajer VPN Terpadu (VLESS & Zivpn)

Selamat datang di Manajer VPN Terpadu, sebuah koleksi skrip yang dirancang untuk menyederhanakan instalasi dan manajemen layanan VLESS dan Zivpn di server Anda. Lupakan perintah yang rumit dan manajemen manual—semua yang Anda butuhkan kini terpusat dalam satu antarmuka yang mudah digunakan.

![](https://github.com/powermx/dl/blob/master/zivpn.png)

## ✨ Fitur Utama

- **Manajemen Terpusat:** Kontrol layanan VLESS dan Zivpn Anda dari satu menu utama.
- **Instalasi Otomatis:** Skrip secara cerdas mendeteksi layanan yang belum terinstal dan menawarkan untuk menginstalnya secara otomatis.
- **Dukungan Multi-Arsitektur:** Instalasi Zivpn secara otomatis mendeteksi arsitektur server (AMD64 atau ARM64) dan menjalankan installer yang benar.
- **Manajemen Pengguna Tingkat Lanjut:**
  - **Akun Reguler:** Buat akun dengan masa aktif yang dapat disesuaikan (misalnya, 30 hari).
  - **Akun Trial:** Buat akun uji coba dengan masa aktif singkat yang diukur dalam hitungan menit.
  - **Pembersihan Otomatis:** Sistem cron job yang berjalan **setiap menit** secara otomatis menghapus semua akun (reguler dan trial) yang telah kedaluwarsa, memastikan server Anda selalu bersih.

## 🚀 Memulai

Cukup jalankan perintah `vpn` untuk mengakses menu manajemen utama. Jika ini adalah pertama kalinya Anda, skrip akan memandu Anda melalui proses instalasi.

### Cara Menjalankan

Buka terminal Anda dan jalankan perintah berikut:

```bash
sudo vpn
```

Jika perintah `vpn` belum tersedia, Anda dapat mengaturnya dengan memindahkan skrip `vpn-manager.sh` ke `/usr/local/bin/vpn`.

## 🖥️ Tampilan Menu

Menu utama menyediakan akses mudah ke semua fitur:

```
=============================================
  🚀 MANAJER VPN TERPADU 🚀
=============================================
  Pilih layanan yang ingin Anda kelola:

  1) 🌐 Kelola VLESS
  2) 🛡️  Kelola Zivpn
  3) ❌ Keluar
```

Dari sini, Anda dapat masuk ke sub-menu untuk VLESS atau Zivpn, yang masing-masing memiliki fitur lengkap untuk mengelola pengguna.

## 📁 Struktur File

- `vpn-manager.sh`: Skrip menu utama. Diinstal sebagai `vpn`.
- `vless-manager.sh`: Manajer untuk layanan VLESS.
- `zivpn-menu.sh`: Manajer untuk layanan Zivpn.
- `zi.sh` / `zi2.sh`: Skrip instalasi untuk Zivpn (AMD64/ARM64).
- `vless-cleanup.sh`: Skrip pembersihan otomatis untuk VLESS.
- `zivpn-cleanup.sh`: Skrip pembersihan otomatis untuk Zivpn.

---
*Bash script by Global Tunneling Nusantara, ditingkatkan oleh Jules.*
