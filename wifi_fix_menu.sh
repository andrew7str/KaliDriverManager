#!/bin/bash

# ==============================================================================
# Skrip Menu untuk Perbaikan dan Konfigurasi WLAN di sistem berbasis Debian
# ==============================================================================

# 1. Memastikan skrip dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
  echo "Skrip ini perlu dijalankan dengan hak akses root. Coba 'sudo ./wifi_fix_menu.sh'" >&2
  exit 1
fi

# Fungsi untuk membersihkan layar dan menampilkan judul
show_header() {
    clear
    echo "=========================================="
    echo "    Menu Perbaikan WLAN untuk Kali Linux    "
    echo "=========================================="
    echo
}

# Fungsi untuk menampilkan driver WLAN yang terpasang
view_drivers() {
    show_header
    echo "--- Menganalisis Driver WLAN yang Terpasang ---"
    echo

    # Menggunakan lspci -k untuk menemukan kontroler jaringan dan drivernya
    # AWK digunakan untuk memformat output agar lebih mudah dibaca
    lspci -k | awk \
    ' \
    BEGIN { \
        RS = "\n\n"; # Setiap perangkat dipisahkan oleh baris kosong
        FS = "\n";
    }
    /Network controller/ { \
        # Cetak nama perangkat
        print "Perangkat: " $1; \
        
        # Cari baris yang berisi "Kernel driver in use"
        driver_line = "";
        for (i = 2; i <= NF; i++) { \
            if ($i ~ /Kernel driver in use:/) { \
                driver_line = $i;
                break;
            }
        }
        
        # Cetak driver jika ditemukan, jika tidak, beri pesan
        if (driver_line != "") { \
            sub(/.*Kernel driver in use: /, "  -> Driver Aktif: ", driver_line);
            print driver_line;
        } else { \
            print "  -> Driver Aktif: (Tidak ada driver yang dimuat)";
        }
        print ""; # Tambahkan baris kosong untuk keterbacaan
    }'
    
    echo
    read -p "Tekan [Enter] untuk kembali ke menu..."
}


# Fungsi untuk perbaikan driver Ralink RT3290
fix_ralink() {
    show_header
    echo "[INFO] Memulai perbaikan untuk Ralink RT3290..."
    echo
    
    echo "[LANGKAH 1/2] Memastikan paket firmware terinstal (firmware-mediatek)..."
    if ! dpkg -s firmware-mediatek &>/dev/null; then
        echo "[INFO] Paket 'firmware-mediatek' tidak ditemukan. Menginstal..."
        apt-get update
        apt-get install -y firmware-mediatek
    else
        echo "[INFO] Paket 'firmware-mediatek' sudah terinstal."
    fi
    echo
    
    echo "[LANGKAH 2/2] Memuat ulang modul driver (rt2800pci)..."
    modprobe -r rt2800pci
    modprobe rt2800pci
    sleep 2 # Beri jeda agar antarmuka muncul
    
    echo "[SELESAI] Driver Ralink telah diperiksa dan dimuat ulang."
    echo "Perangkat ini biasanya muncul sebagai 'wlan0'."
    echo "Gunakan opsi 'Lihat Status Jaringan' dari menu utama untuk memeriksa."
    echo
    echo "Untuk menghubungkan ke jaringan, gunakan perintah:"
    echo "nmcli device wifi connect 'NAMA_JARINGAN' ifname wlan0 --ask"
    echo
    read -p "Tekan [Enter] untuk kembali ke menu..."
}

# Fungsi untuk perbaikan driver Broadcom BCM43228
fix_broadcom() {
    show_header
    echo "[INFO] Memulai perbaikan untuk Broadcom BCM43228..."
    echo
    
    echo "[LANGKAH 1/4] Menghapus driver proprietary yang konflik (broadcom-sta-dkms)..."
    if dpkg -s broadcom-sta-dkms &>/dev/null; then
        apt-get remove --purge -y broadcom-sta-dkms
        echo "[INFO] Paket 'broadcom-sta-dkms' telah dihapus."
    else
        echo "[INFO] Paket 'broadcom-sta-dkms' tidak terinstal."
    fi
    echo

    echo "[LANGKAH 2/4] Menginstal firmware untuk driver open-source (firmware-b43-installer)..."
    if ! dpkg -s firmware-b43-installer &>/dev/null; then
        echo "[INFO] Menginstal 'firmware-b43-installer'..."
        apt-get update
        apt-get install -y firmware-b43-installer
    else
        echo "[INFO] Paket 'firmware-b43-installer' sudah terinstal."
    fi
    echo
    
    echo "[LANGKAH 3/4] Memuat driver open-source (b43)..."
    modprobe -r b43 ssb bcma
    modprobe b43
    sleep 2 # Beri jeda
    echo "[INFO] Modul 'b43' telah dimuat."
    echo

    echo "[LANGKAH 4/4] Restart layanan NetworkManager..."
    systemctl restart NetworkManager
    
    echo "[SELESAI] Driver Broadcom telah dikonfigurasi ulang."
    echo "Perangkat ini biasanya muncul sebagai 'wlan1'."
    echo "Gunakan opsi 'Lihat Status Jaringan' dari menu utama untuk memeriksa."
    echo
    echo "Untuk menghubungkan ke jaringan, gunakan perintah:"
    echo "nmcli device wifi connect 'NAMA_JARINGAN' ifname wlan1 --ask"
    echo
    read -p "Tekan [Enter] untuk kembali ke menu..."
}

# Fungsi untuk menampilkan status jaringan
view_status() {
    show_header
    echo "--- Status Perangkat Keras Jaringan (lspci) ---"
    lspci -nn | grep -i "net"
    echo
    
    echo "--- Status rfkill (Pemeriksa Blokir Perangkat) ---"
    rfkill list
    echo
    
    echo "--- Status Antarmuka Jaringan (ip link) ---"
    ip link show
    echo
    
    echo "--- Status Perangkat NetworkManager (nmcli) ---"
    nmcli device status
    echo
    
    read -p "Tekan [Enter] untuk kembali ke menu..."
}

# Fungsi untuk menampilkan menu utama
main_menu() {
    show_header
    echo "Pilih opsi perbaikan:"
    echo "  1) Lihat Driver WLAN yang Terpasang"
    echo "  2) Perbaiki Ralink RT3290 (wlan0)"
    echo "  3) Perbaiki Broadcom BCM43228 (wlan1)"
    echo "  4) Lihat Status Jaringan Lengkap"
    echo "  5) Keluar"
    echo
    read -p "Masukkan pilihan Anda [1-5]: " choice
    
    case $choice in
        1)
            view_drivers
            ;;
        2)
            fix_ralink
            ;;
        3)
            fix_broadcom
            ;;
        4)
            view_status
            ;;
        5)
            echo "Keluar dari skrip."
            exit 0
            ;;
        *)
            echo "Pilihan tidak valid. Silakan coba lagi."
            sleep 2
            ;;
    esac
}

# Loop utama skrip
while true; do
    main_menu
done