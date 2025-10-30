# Skrip Manajemen Zivpn UDP

Selamat datang di Skrip Manajemen Zivpn UDP! Alat ini dirancang untuk menyederhanakan instalasi, konfigurasi, dan pengelolaan layanan Zivpn UDP di server Debian atau Ubuntu Anda.

## ✨ Fitur Utama

- **Instalasi Otomatis & Aman**: Skrip instalasi dilindungi dan memerlukan lisensi IP untuk berjalan.
- **Menu Interaktif**: Antarmuka berbasis menu yang mudah digunakan untuk mengelola pengguna, melihat informasi, dan lainnya.
- **Manajemen Pengguna Lengkap**: Tambah, hapus, dan lihat pengguna reguler dan percobaan langsung dari menu.
- **Pembersihan Otomatis**: Pengguna yang kedaluwarsa secara otomatis dihapus.
- **Penghapusan "Instan"**: Akun yang kedaluwarsa (baik reguler maupun trial) akan dihapus secara otomatis dalam satu menit setelah waktunya habis.
- **Uninstaller Lengkap**: Satu perintah untuk menghapus Zivpn dan semua komponennya dari sistem Anda.
- **Dukungan Multi-Arsitektur**: Bekerja pada server AMD64 (x86_64) dan ARM64.

## 🔒 Sistem Lisensi

**Penting:** Skrip instalasi ini sekarang dilindungi oleh sistem lisensi berbasis IP. Agar instalasi berhasil, IP publik dari server target **harus** didaftarkan terlebih dahulu di dalam file `izin_ips.txt` yang Anda hosting di `http://zivpn.nizwara.biz.id/izin_ips.txt`.

Jika IP server tidak terdaftar, proses instalasi akan gagal.

## 🚀 Instalasi

Untuk menginstal, pastikan IP server sudah terdaftar, lalu salin dan jalankan perintah yang sesuai dengan arsitektur server Anda.

### AMD64 (x86_64)
```bash
wget -q -O zi.sh http://zivpn.nizwara.biz.id/zi.sh && chmod +x zi.sh && ./zi.sh
```

### ARM64
```bash
wget -q -O zi2.sh http://zivpn.nizwara.biz.id/zi2.sh && chmod +x zi2.sh && ./zi2.sh
```

## 🛠️ Penggunaan

Setelah instalasi selesai, Anda dapat mengakses menu manajemen kapan saja dengan menjalankan perintah berikut:

```bash
zivpn
```

Dari menu ini, Anda dapat mengelola semua aspek layanan Zivpn Anda.

## 🗑️ Uninstall

Jika Anda ingin menghapus Zivpn dari server Anda, Anda dapat melakukannya melalui menu atau dengan menjalankan perintah berikut secara langsung:

```bash
uninstall.sh
```

Skrip uninstal akan meminta konfirmasi sebelum menghapus semua file, layanan, dan aturan firewall yang terkait dengan Zivpn.
