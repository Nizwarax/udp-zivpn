<?php
// File untuk menyimpan lisensi
$license_file = 'licenses.txt';
// Keamanan dasar: Pastikan request adalah POST dan berisi parameter yang dibutuhkan
if ($_SERVER['REQUEST_METHOD'] !== 'POST' || !isset($_POST['key']) || !isset($_POST['ip'])) {
    header('HTTP/1.1 400 Bad Request');
    die("FAILED|Invalid request");
}
// Ambil dan bersihkan data dari installer
$auth_key = trim($_POST['key']);
$server_ip = trim($_POST['ip']);
if (empty($auth_key) || empty($server_ip)) {
    header('HTTP/1.1 400 Bad Request');
    die("FAILED|Key or IP is missing");
}
// Buka file lisensi dengan mode "read and write" (r+)
$handle = fopen($license_file, 'r+');
if (!$handle) {
    header('HTTP/1.1 500 Internal Server Error');
    die("FAILED|Server-side license file error");
}
// Kunci file untuk mencegah penulisan ganda secara bersamaan
if (flock($handle, LOCK_EX)) {
    $updated_content = '';
    $key_found = false;
    $valid_key = false;
    // Baca file baris per baris
    while (($line = fgets($handle)) !== false) {
        if (trim($line) === '' || $line[0] === '#') {
            $updated_content .= $line;
            continue;
        }
        $parts = explode('|', trim($line));

        // Cek jika ini adalah kunci yang kita cari
        if (count($parts) === 5 && $parts[0] === $auth_key) {
            $key_found = true;
            // Cek jika kunci masih UNUSED
            if ($parts[3] === 'UNUSED') {
                $valid_key = true;
                $client_name = $parts[1];
                $expiry_date = $parts[2];
                // Update baris ini: ubah status jadi USED dan catat IP-nya
                $parts[3] = 'USED';
                $parts[4] = $server_ip;
                $updated_content .= implode('|', $parts) . "\n";
            } else {
                $updated_content .= $line; // Kunci sudah digunakan, jangan ubah barisnya
            }
        } else {
            $updated_content .= $line; // Bukan kunci yang dicari, tulis kembali baris aslinya
        }
    }
    // Jika kunci valid, tulis ulang seluruh file dengan konten yang sudah diupdate
    if ($valid_key) {
        ftruncate($handle, 0);
        rewind($handle);
        fwrite($handle, $updated_content);
        echo "SUCCESS|$client_name|$expiry_date";
    }
    flock($handle, LOCK_UN); // Lepas kunci file
}
fclose($handle);
// Jika kunci tidak valid atau tidak ditemukan setelah selesai membaca file
if (!$valid_key) {
    if ($key_found) {
        echo "FAILED|Key has already been used";
    } else {
        echo "FAILED|Invalid activation key";
    }
}
?>
