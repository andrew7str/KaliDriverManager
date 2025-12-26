#!/bin/bash

# Warna untuk tampilan
HIJAU='\033[0;32m'
MERAH='\033[0;31m'
KUNING='\033[1;33m'
BIRU='\033[0;34m'
NC='\033[0m' # No Color

# Fungsi untuk cek status instalasi
cek_status() {
    if dpkg -l | grep -q "$1"; then
        echo -e "${HIJAU}[TERPASANG]${NC}"
    else
        echo -e "${MERAH}[BELUM TERPASANG]${NC}"
    fi
}

tampilkan_menu() {
    clear
    echo -e "${BIRU}===============================================${NC}"
    echo -e "${BIRU}       KALI LINUX DRIVER & FIRMWARE MANAGER    ${NC}"
    echo -e "${BIRU}===============================================${NC}"
    echo -e "Status Perangkat Saat Ini:"
    
    echo -n "1. Firmware Linux Non-Free    : "
    cek_status "firmware-linux-nonfree"
    
    echo -n "2. Driver WiFi (Realtek)      : "
    cek_status "firmware-realtek"
    
    echo -n "3. Driver WiFi (Atheros)      : "
    cek_status "firmware-atheros"
    
    echo -n "4. Driver WiFi (Intel/IWL)    : "
    cek_status "firmware-iwlwifi"
    
    echo -n "5. Kernel Headers             : "
    cek_status "linux-headers-$(uname -r)"
    
    echo -n "6. Driver NVIDIA (Proprietary): "
    cek_status "nvidia-driver"
    
    echo -e "${BIRU}-----------------------------------------------${NC}"
    echo "PILIH OPSI:"
    echo "a) Install Semua Firmware Dasar (Recommended)"
    echo "b) Install Kernel Headers saja"
    echo "c) Install Driver NVIDIA"
    echo "d) Cek Log Error Hardware (dmesg)"
    echo "q) Keluar"
    echo -n "Masukkan pilihan Anda: "
}

while true; do
    tampilkan_menu
    read pilihan
    case $pilihan in
        a)
            echo -e "${KUNING}Menginstall semua firmware dasar...${NC}"
            sudo apt update && sudo apt install -y firmware-linux firmware-linux-nonfree firmware-misc-nonfree firmware-realtek firmware-atheros firmware-iwlwifi firmware-brcm80211
            read -p "Selesai. Tekan Enter untuk kembali."
            ;;
        b)
            echo -e "${KUNING}Menginstall Kernel Headers...${NC}"
            sudo apt update && sudo apt install -y linux-headers-$(uname -r)
            read -p "Selesai. Tekan Enter untuk kembali."
            ;;
        c)
            echo -e "${KUNING}Mengecek kompatibilitas NVIDIA...${NC}"
            sudo apt update && sudo apt install -y nvidia-detect
            nvidia-detect
            echo -n "Lanjutkan install driver NVIDIA? (y/n): "
            read confirm
            if [ "$confirm" = "y" ]; then
                sudo apt install -y nvidia-driver
            fi
            read -p "Tekan Enter untuk kembali."
            ;;
        d)
            echo -e "${MERAH}Mencari error firmware di sistem...${NC}"
            sudo dmesg | grep -i "failed to load"
            if [ $? -ne 0 ]; then echo "Tidak ada error firmware yang ditemukan."; fi
            read -p "Tekan Enter untuk kembali."
            ;;
        q)
            echo "Keluar..."
            exit 0
            ;;
        *)
            echo -e "${MERAH}Pilihan tidak valid!${NC}"
            sleep 1
            ;;
    esac
done
