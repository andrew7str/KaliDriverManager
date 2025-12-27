# KaliDriverManager

# Skrip Menu Perbaikan Driver & Firmware untuk Kali Linux

Skrip bash interaktif yang dirancang untuk mempermudah proses perbaikan driver dan instalasi firmware pada sistem operasi Kali Linux dan distro lain berbasis Debian. Skrip ini menyediakan menu yang mudah digunakan untuk mengatasi masalah umum terkait driver WLAN (Wi-Fi), kartu grafis, dan komponen lainnya.

## 🌟 Fitur

- **Antarmuka Berbasis Menu**: Navigasi yang mudah untuk memilih tindakan perbaikan yang spesifik.
- **Pembaruan Sistem Penuh**: Opsi terintegrasi untuk menjalankan `dist-upgrade` guna memastikan sistem dan kernel Anda mutakhir.
- **Perbaikan WLAN Cerdas**:
  - Mendeteksi semua kartu WLAN yang terpasang.
  - Menampilkan sub-menu untuk memilih kartu yang ingin diperbaiki.
  - Memberikan perbaikan spesifik untuk vendor populer: **Broadcom**, **Realtek**, dan **Intel**.
  - Memberi notifikasi jika driver atau firmware yang relevan sudah terpasang.
- **Perbaikan Driver Grafis**:
  - Mendeteksi tipe kartu grafis: **NVIDIA**, **AMD/ATI**, atau **Intel**.
  - Menampilkan vendor yang terdeteksi dengan warna untuk identifikasi cepat.
  - Menginstal driver proprietary atau firmware yang sesuai.
- **Perbaikan Driver Sound**: Menginstal firmware tambahan yang sering dibutuhkan untuk perangkat audio modern.
- **Instalasi Firmware Lengkap**: Opsi untuk menginstal koleksi firmware umum dari repositori Kali untuk dukungan perangkat keras yang maksimal.
- **Optimalisasi Baterai**: Menginstal dan mengaktifkan **TLP**, utilitas canggih untuk manajemen daya dan optimalisasi baterai laptop.
- **Jalankan Semua**: Opsi untuk menjalankan semua tugas perbaikan dan pembaruan secara berurutan, ideal untuk penyiapan awal.

## 📋 Persyaratan

- **Sistem Operasi**: Kali Linux atau distro lain berbasis Debian (misalnya Ubuntu, Mint).
- **Koneksi Internet**: Diperlukan untuk mengunduh paket driver dan pembaruan.
- **Hak Akses**: `sudo` atau root.

## 🚀 Cara Penggunaan

1.  **Clone Repositori atau Unduh Skrip**
    ```bash
    git clone [URL_GIT_ANDA]
    cd [NAMA_DIREKTORI_ANDA]
    ```
    Atau cukup simpan file `kali_driver_menu.sh` di direktori Anda.

2.  **Beri Izin Eksekusi**
    Jadikan skrip dapat dieksekusi dengan perintah berikut:
    ```bash
    chmod +x kali_driver_menu.sh
    ```

3.  **Jalankan Skrip**
    Eksekusi skrip dengan hak akses `sudo`:
    ```bash
    sudo ./kali_driver_menu.sh
    ```
    Anda akan disambut dengan menu utama untuk memilih tindakan selanjutnya.

## ⚠️ Alur Kerja yang Sangat Direkomendasikan

Untuk menghindari error dan memastikan keberhasilan instalasi driver, ikuti urutan langkah berikut:

1.  **Langkah 1: Lakukan Pembaruan Sistem**
    - Jalankan skrip dan pilih **Opsi 6: Pembaruan Sistem Penuh**.
    - Biarkan proses ini berjalan hingga selesai sepenuhnya. Proses ini mungkin memakan waktu lama.

2.  **Langkah 2: Restart Komputer Anda**
    - Setelah pembaruan selesai, **WAJIB** restart sistem Anda agar dapat boot dengan kernel yang baru.
    - `sudo reboot`

3.  **Langkah 3: Jalankan Perbaikan Spesifik**
    - Setelah komputer menyala kembali, jalankan lagi skrip `sudo ./kali_driver_menu.sh`.
    - Sekarang, pilih opsi perbaikan yang Anda butuhkan (misalnya, **Opsi 1** untuk WLAN atau **Opsi 2** untuk grafis). Anda juga bisa memilih **Opsi 7** untuk menjalankan semua perbaikan sekaligus.

Mengikuti alur kerja ini memastikan bahwa driver (terutama yang memerlukan DKMS seperti Broadcom) dibuat menggunakan *kernel headers* yang cocok dengan versi kernel terbaru Anda.

## 🔧 Pemecahan Masalah (Troubleshooting)

#### Error: `modprobe: FATAL: Module wl not found...`

- **Penyebab**: Error ini terjadi karena modul driver `wl` untuk Broadcom gagal dibuat. Penyebab utamanya adalah `kernel headers` yang tidak ada atau tidak cocok dengan versi kernel yang sedang berjalan.
- **Solusi**: Ikuti **"Alur Kerja yang Sangat Direkomendasikan"** di atas. Masalah ini akan terselesaikan dengan melakukan pembaruan sistem penuh, me-restart, dan kemudian menjalankan kembali perbaikan WLAN.

## ⚖️ Penafian (Disclaimer)

Skrip ini dibuat untuk membantu, tetapi gunakan dengan risiko Anda sendiri. Penulis tidak bertanggung jawab atas potensi kerusakan pada sistem Anda. Selalu pastikan Anda memiliki cadangan data penting sebelum melakukan perubahan besar pada sistem.
