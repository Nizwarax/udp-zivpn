<?php
// File untuk menyimpan lisensi
$license_file = 'licenses.txt';
// Keamanan dasar: Pastikan request adalah POST dan berisi IP
if ($_SERVER['REQUEST_METHOD'] !== 'POST' || !isset($_POST['ip'])) {
    header('HTTP/1.1 400 Bad Request');
    die("FAILED|Invalid request");
}
// Ambil dan bersihkan IP dari menu
$server_ip = trim($_POST['ip']);
if (empty($server_ip)) {
    header('HTTP/1.1 400 Bad Request');
    die("FAILED|IP is missing");
}
// Buka file lisensi dengan mode "read only" (r)
$handle = fopen($license_file, 'r');
if (!$handle) {
    header('HTTP/1.1 500 Internal Server Error');
    die("FAILED|Server-side license file error");
}
$license_valid = false;
$client_name = "Unknown";
$expiry_date = "Unknown";
// Baca file baris per baris
while (($line = fgets($handle)) !== false) {
    if (trim($line) === '' || $line[0] === '#') {
        continue;
    }
    $parts = explode('|', trim($line));

    // Cek jika IP di baris ini cocok dengan IP server
    if (count($parts) === 5 && $parts[4] === $server_ip) {
        $client_name = $parts[1];
        $expiry_date = $parts[2];

        // Periksa tanggal kedaluwarsa
        if ($expiry_date === 'lifetime') {
            $license_valid = true;
            break; // Lisensi valid, tidak perlu cek lagi
        }

        // Ubah tanggal kedaluwarsa ke format timestamp untuk perbandingan
        $expiry_timestamp = strtotime($expiry_date . ' 23:59:59');
        if ($expiry_timestamp !== false && time() <= $expiry_timestamp) {
            $license_valid = true;
            break; // Lisensi valid, tidak perlu cek lagi
        }
    }
}
fclose($handle);
// Kirim respons berdasarkan hasil pemeriksaan
if ($license_valid) {
    echo "SUCCESS|$client_name|$expiry_date";
} else {
    echo "FAILED|License not active or has expired for this IP";
}
?>
