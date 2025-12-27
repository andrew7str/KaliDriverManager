#!/bin/bash

# ==============================================================================
# Skrip Menu untuk Perbaikan dan Konfigurasi WLAN di sistem berbasis Debian
# Versi 2.0 - Dengan Deteksi Otomatis dan Warna
# ==============================================================================

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'
UNDERLINE='\033[4m'

# 1. Memastikan skrip dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}[ERROR]${NC} Skrip ini perlu dijalankan dengan hak akses root."
  echo -e "Coba: ${GREEN}sudo ./wifi_fix_menu.sh${NC}"
  exit 1
fi

# Fungsi untuk membersihkan layar dan menampilkan judul
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${BOLD}${WHITE}         Menu Perbaikan WLAN - Deteksi Otomatis           ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${BOLD}${WHITE}                    Create By : Mr.exe                    ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Fungsi untuk menampilkan pesan status
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fungsi untuk mendeteksi semua perangkat WiFi yang terpasang
detect_wifi_devices() {
    show_header
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${BOLD}${WHITE}           DETEKSI PERANGKAT WIFI YANG TERPASANG          ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    
    local wifi_devices=()
    local device_count=0
    
    # Analisis output lspci untuk perangkat jaringan
    while IFS= read -r line; do
        if echo "$line" | grep -qi "network controller\|wireless"; then
            wifi_devices+=("$line")
            ((device_count++))
        fi
    done < <(lspci -nn)
    
    if [ $device_count -eq 0 ]; then
        print_warning "Tidak ditemukan perangkat WiFi terpasang pada PCI/USB!"
        echo
        echo -e "${YELLOW}Periksa:${NC}"
        echo -e "  1. Apakah perangkat WiFi terpasang dengan benar?"
        echo -e "  2. Coba: ${GREEN}lspci | grep -i network${NC}"
        echo -e "  3. Coba: ${GREEN}lsusb | grep -i wireless${NC}"
        echo
        read -p "Tekan [Enter] untuk melanjutkan..."
        return
    fi
    
    echo -e "${GREEN}Ditemukan $device_count perangkat WiFi:${NC}"
    echo
    
    # Proses setiap perangkat
    for ((i=0; i<${#wifi_devices[@]}; i++)); do
        local device_info="${wifi_devices[$i]}"
        local device_id=$(echo "$device_info" | awk '{print $1}')
        
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}${WHITE}Perangkat $((i+1)):${NC} ${device_info}"
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        
        # Cari vendor dan device ID
        local vendor_id=$(echo "$device_info" | grep -o '\[....:....\]' | head -1 | tr -d '[]' | cut -d: -f1)
        local device_id_full=$(echo "$device_info" | grep -o '\[....:....\]' | head -1 | tr -d '[]')
        
        echo -e "${CYAN}Vendor/Device ID:${NC} $device_id_full"
        
        # Cek driver yang sedang digunakan
        local driver_info=$(lspci -k -s "$device_id" 2>/dev/null)
        local kernel_driver=$(echo "$driver_info" | grep "Kernel driver in use" | cut -d: -f2 | xargs)
        local kernel_modules=$(echo "$driver_info" | grep "Kernel modules" | cut -d: -f2 | xargs)
        
        if [ -n "$kernel_driver" ]; then
            echo -e "${GREEN}✓ Driver Aktif:${NC} $kernel_driver"
        else
            echo -e "${RED}✗ Driver Aktif:${NC} Tidak ada driver yang dimuat"
        fi
        
        if [ -n "$kernel_modules" ]; then
            echo -e "${CYAN}Modul Kernel:${NC} $kernel_modules"
        fi
        
        # Cek apakah interface jaringan sudah muncul
        local interface=$(ls /sys/class/net/ | grep -E '^wlan[0-9]+$' | sort | head -$((i+1)) | tail -1)
        if [ -n "$interface" ]; then
            echo -e "${GREEN}✓ Interface:${NC} $interface"
            
            # Cek status interface
            local iface_status=$(ip link show "$interface" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
            if [ "$iface_status" = "UP" ]; then
                echo -e "${GREEN}✓ Status:${NC} UP"
            else
                echo -e "${YELLOW}⚠ Status:${NC} $iface_status"
            fi
        else
            echo -e "${RED}✗ Interface:${NC} Tidak ditemukan"
        fi
        
        # Cek firmware
        check_firmware "$vendor_id" "$device_id_full"
        
        echo
    done
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${BOLD}${WHITE}                   REKOMENDASI TINDAKAN                   ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    
    # Berikan rekomendasi berdasarkan hardware
    for device_info in "${wifi_devices[@]}"; do
        if echo "$device_info" | grep -qi "ralink\|rt3290"; then
            echo -e "${YELLOW}Ralink RT3290 terdeteksi:${NC}"
            echo -e "  Gunakan opsi 2 untuk perbaikan khusus"
        elif echo "$device_info" | grep -qi "broadcom\|bcm43228"; then
            echo -e "${YELLOW}Broadcom BCM43228 terdeteksi:${NC}"
            echo -e "  Gunakan opsi 3 untuk perbaikan khusus"
        elif echo "$device_info" | grep -qi "intel"; then
            echo -e "${GREEN}Intel WiFi terdeteksi:${NC}"
            echo -e "  Driver biasanya sudah termasuk dalam kernel"
            echo -e "  Coba opsi 6 untuk instalasi firmware Intel"
        elif echo "$device_info" | grep -qi "atheros"; then
            echo -e "${YELLOW}Atheros terdeteksi:${NC}"
            echo -e "  Instal paket: ${GREEN}firmware-atheros${NC}"
        elif echo "$device_info" | grep -qi "realtek\|rtl"; then
            echo -e "${YELLOW}Realtek terdeteksi:${NC}"
            echo -e "  Instal paket: ${GREEN}firmware-realtek${NC}"
        fi
    done
    
    echo
    read -p "Tekan [Enter] untuk kembali ke menu..."
}

# Fungsi untuk mengecek firmware
check_firmware() {
    local vendor_id="$1"
    local device_id="$2"
    
    echo -e "${CYAN}Firmware Check:${NC}"
    
    # Cek direktori firmware
    local firmware_loaded=$(dmesg | grep -i "firmware" | grep -i "$vendor_id\|$device_id" | tail -3)
    
    if [ -n "$firmware_loaded" ]; then
        echo -e "${GREEN}✓ Firmware terdeteksi dalam log sistem${NC}"
        return 0
    fi
    
    # Vendor-specific checks
    case $vendor_id in
        168c) # Atheros
            if [ ! -f /lib/firmware/ath10k ]; then
                echo -e "${RED}✗ Firmware Atheros mungkin kurang${NC}"
                return 1
            fi
            ;;
        14e4) # Broadcom
            if ! ls /lib/firmware/b43/* 2>/dev/null | grep -q .; then
                echo -e "${RED}✗ Firmware Broadcom (b43) tidak ditemukan${NC}"
                return 1
            fi
            ;;
        8086) # Intel
            if ! find /lib/firmware -name "*iwlwifi*" 2>/dev/null | grep -q .; then
                echo -e "${RED}✗ Firmware Intel tidak ditemukan${NC}"
                return 1
            fi
            ;;
    esac
    
    echo -e "${GREEN}✓ Firmware terdeteksi untuk vendor $vendor_id${NC}"
    return 0
}

# Fungsi untuk perbaikan driver Ralink RT3290
fix_ralink() {
    show_header
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${BOLD}${WHITE}              PERBAIKAN DRIVER RALINK RT3290              ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    
    print_status "Memulai perbaikan untuk Ralink RT3290..."
    echo
    
    print_status "LANGKAH 1/3: Update repositori paket..."
    apt-get update 2>/dev/null | while read line; do 
        echo -e "${CYAN}[UPDATE]${NC} $line"; 
    done
    echo
    
    print_status "LANGKAH 2/3: Memastikan paket firmware terinstal..."
    local firmware_pkgs=("firmware-mediatek" "firmware-misc-nonfree")
    
    for pkg in "${firmware_pkgs[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            print_status "Menginstal '$pkg'..."
            if apt-get install -y "$pkg" 2>/dev/null; then
                print_success "'$pkg' berhasil diinstal"
            else
                print_error "Gagal menginstal '$pkg'"
            fi
        else
            print_status "'$pkg' sudah terinstal"
        fi
    done
    echo
    
    print_status "LANGKAH 3/3: Memuat ulang modul driver..."
    
    # Coba berbagai modul Ralink
    local ralink_modules=("rt2800pci" "rt2800usb" "rt2x00pci" "rt2x00usb")
    local loaded_module=""
    
    for module in "${ralink_modules[@]}"; do
        if lsmod | grep -q "^${module} "; then
            loaded_module="$module"
            break
        fi
    done
    
    if [ -n "$loaded_module" ]; then
        print_status "Melepas modul: $loaded_module"
        modprobe -r "$loaded_module"
        sleep 1
    fi
    
    print_status "Memuat modul rt2800pci..."
    if modprobe rt2800pci; then
        print_success "Modul rt2800pci berhasil dimuat"
    else
        print_error "Gagal memuat modul rt2800pci"
        print_status "Mencoba modul alternatif..."
        modprobe rt2x00pci
    fi
    
    sleep 2
    
    # Cek hasil
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${BOLD}${WHITE}                      HASIL PERBAIKAN                     ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Cek interface
    if ip link show | grep -q "wlan"; then
        local wlan_iface=$(ip link show | grep "wlan" | head -1 | awk -F': ' '{print $2}' | cut -d' ' -f1)
        print_success "Interface WiFi terdeteksi: $wlan_iface"
        
        # Aktifkan interface
        ip link set "$wlan_iface" up 2>/dev/null
        
        # Tampilkan info
        echo -e "${CYAN}Informasi Interface:${NC}"
        iwconfig "$wlan_iface" 2>/dev/null | grep -E "ESSID|Mode|Frequency"
    else
        print_warning "Interface WiFi belum muncul. Mungkin perlu reboot."
    fi
    
    echo
    print_status "Restarting NetworkManager..."
    systemctl restart NetworkManager 2>/dev/null
    
    echo
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}PERBAIKAN SELESAI${NC}"
    echo -e "${GREEN}==================================================${NC}"
    echo
    echo -e "${CYAN}Untuk menghubungkan ke jaringan:${NC}"
    echo -e "  ${GREEN}nmcli device wifi connect 'NAMA_JARINGAN' password 'PASSWORD'${NC}"
    echo -e "  ${GREEN}atau gunakan Wicd/network-manager GUI${NC}"
    echo
    
    read -p "Tekan [Enter] untuk kembali ke menu..."
}

# Fungsi untuk perbaikan driver Broadcom BCM43228
fix_broadcom() {
    show_header
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${BOLD}${WHITE}            PERBAIKAN DRIVER BROADCOM BCM43228            ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    
    print_status "Memulai perbaikan untuk Broadcom BCM43228..."
    echo
    
    print_status "LANGKAH 1/5: Update repositori paket..."
    apt-get update 2>/dev/null
    echo
    
    print_status "LANGKAH 2/5: Menghapus driver proprietary yang konflik..."
    
    local conflict_pkgs=("broadcom-sta-dkms" "broadcom-sta-common" "broadcom-sta-source")
    
    for pkg in "${conflict_pkgs[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            print_status "Menghapus '$pkg'..."
            apt-get remove --purge -y "$pkg" 2>/dev/null
            print_success "'$pkg' berhasil dihapus"
        fi
    done
    echo
    
    print_status "LANGKAH 3/5: Menginstal firmware dan driver open-source..."
    
    local install_pkgs=("firmware-b43-installer" "b43-fwcutter" "firmware-b43-lpphy-installer")
    
    for pkg in "${install_pkgs[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            print_status "Menginstal '$pkg'..."
            if apt-get install -y "$pkg" 2>/dev/null; then
                print_success "'$pkg' berhasil diinstal"
            else
                print_error "Gagal menginstal '$pkg'"
            fi
        else
            print_status "'$pkg' sudah terinstal"
        fi
    done
    echo
    
    print_status "LANGKAH 4/5: Memuat driver open-source..."
    
    # Unload modul yang mungkin konflik
    local conflict_modules=("wl" "b43" "ssb" "bcma" "brcmsmac")
    
    for module in "${conflict_modules[@]}"; do
        if lsmod | grep -q "^${module} "; then
            print_status "Melepas modul: $module"
            modprobe -r "$module" 2>/dev/null
        fi
    done
    
    # Blacklist driver proprietary
    echo "blacklist wl" > /etc/modprobe.d/blacklist-broadcom.conf
    echo "blacklist bcma" >> /etc/modprobe.d/blacklist-broadcom.conf
    echo "blacklist ssb" >> /etc/modprobe.d/blacklist-broadcom.conf
    
    print_status "Memuat modul b43..."
    if modprobe b43; then
        print_success "Modul b43 berhasil dimuat"
    else
        print_error "Gagal memuat modul b43"
    fi
    
    sleep 2
    echo
    
    print_status "LANGKAH 5/5: Restart layanan jaringan..."
    systemctl restart NetworkManager 2>/dev/null
    
    # Cek hasil
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${BOLD}${WHITE}                      HASIL PERBAIKAN                     ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Scan untuk interface WiFi
    if ip link show | grep -q "wlan"; then
        local wlan_count=$(ip link show | grep -c "wlan")
        print_success "Ditemukan $wlan_count interface WiFi"
        
        ip link show | grep "wlan" | while read line; do
            local iface=$(echo "$line" | awk -F': ' '{print $2}' | cut -d' ' -f1)
            echo -e "${CYAN}Interface:${NC} $iface"
            ip link set "$iface" up 2>/dev/null
        done
    else
        print_warning "Interface WiFi belum muncul. Coba reboot sistem."
    fi
    
    echo
    echo -e "${YELLOW}Catatan:${NC} Perangkat Broadcom mungkin muncul sebagai wlan0 atau wlan1"
    echo -e "Bergantung pada konfigurasi sistem Anda."
    echo
    read -p "Tekan [Enter] untuk kembali ke menu..."
}

# Fungsi untuk instalasi firmware otomatis berdasarkan deteksi
auto_fix_wifi() {
    show_header
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${BOLD}${WHITE}            PERBAIKAN WIFI OTOMATIS BERDASARKAN           ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${BOLD}${WHITE}                      DETEKSI HARDWARE                    ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    
    print_status "Mendeteksi perangkat WiFi..."
    echo
    
    # Deteksi vendor
    local wifi_info=$(lspci -nn | grep -i "network\|wireless")
    local needs_fix=0
    
    if echo "$wifi_info" | grep -qi "ralink\|rt3290"; then
        print_status "Ralink RT3290 terdeteksi, menjalankan perbaikan khusus..."
        echo
        read -p "Lanjutkan perbaikan? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            fix_ralink
            return
        fi
    elif echo "$wifi_info" | grep -qi "broadcom\|bcm43228\|14e4:"; then
        print_status "Broadcom terdeteksi, menjalankan perbaikan khusus..."
        echo
        read -p "Lanjutkan perbaikan? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            fix_broadcom
            return
        fi
    fi
    
    # Deteksi vendor untuk instalasi firmware umum
    print_status "Memeriksa kebutuhan firmware berdasarkan vendor..."
    echo
    
    declare -A vendor_packages
    vendor_packages["168c"]="firmware-atheros"        # Atheros
    vendor_packages["14e4"]="firmware-b43-installer"  # Broadcom
    vendor_packages["8086"]="firmware-iwlwifi"        # Intel
    vendor_packages["10ec"]="firmware-realtek"        # Realtek
    vendor_packages["1814"]="firmware-ralink"         # Ralink
    vendor_packages["02d0"]="firmware-mediatek"       # MediaTek
    
    # Update repositori
    print_status "Update repositori paket..."
    apt-get update 2>/dev/null
    
    # Instal firmware berdasarkan vendor
    while read -r line; do
        local vendor_id=$(echo "$line" | grep -o '\[....:....\]' | head -1 | tr -d '[]' | cut -d: -f1)
        
        if [ -n "${vendor_packages[$vendor_id]}" ]; then
            local pkg="${vendor_packages[$vendor_id]}"
            
            if ! dpkg -s "$pkg" &>/dev/null; then
                print_status "Menginstal firmware untuk vendor $vendor_id: $pkg"
                if apt-get install -y "$pkg" 2>/dev/null; then
                    print_success "$pkg berhasil diinstal"
                    needs_fix=1
                else
                    print_error "Gagal menginstal $pkg"
                fi
            else
                print_status "$pkg sudah terinstal"
            fi
        fi
    done <<< "$wifi_info"
    
    # Instal paket firmware umum
    print_status "Menginstal firmware umum..."
    local general_pkgs=("firmware-linux" "firmware-linux-nonfree" "firmware-misc-nonfree")
    
    for pkg in "${general_pkgs[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            if apt-get install -y "$pkg" 2>/dev/null; then
                print_success "$pkg berhasil diinstal"
                needs_fix=1
            fi
        fi
    done
    
    # Load ulang modul jaringan
    if [ $needs_fix -eq 1 ]; then
        print_status "Memuat ulang modul jaringan..."
        
        # Cari modul WiFi yang sedang digunakan
        local wifi_modules=$(lsmod | grep -E "^rtl|^ath|^iwl|^b43|^rt2|^rt[0-9]" | awk '{print $1}')
        
        for module in $wifi_modules; do
            print_status "Reloading module: $module"
            modprobe -r "$module" 2>/dev/null
            modprobe "$module" 2>/dev/null
        done
        
        print_status "Restarting NetworkManager..."
        systemctl restart NetworkManager 2>/dev/null
        
        print_success "Perbaikan otomatis selesai!"
    else
        print_status "Tidak ditemukan firmware yang perlu diinstal."
    fi
    
    echo
    echo -e "${CYAN}Status saat ini:${NC}"
    echo "========================================"
    ip link show | grep -A1 "wlan"
    echo
    
    read -p "Tekan [Enter] untuk kembali ke menu..."
}

# Fungsi untuk menampilkan status jaringan
view_status() {
    show_header
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${BOLD}${WHITE}                   STATUS JARINGAN LENGKAP                ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${GREEN}1. PERANGKAT JARINGAN (lspci):${NC}"
    echo "----------------------------------------------------"
    lspci -nn | grep -i "net" | while read line; do
        echo -e "  ${CYAN}•${NC} $line"
    done
    echo
    
    echo -e "${GREEN}2. STATUS RFKILL (BLOKIR PERANGKAT):${NC}"
    echo "----------------------------------------------------"
    rfkill list | while read line; do
        if [[ "$line" == *"Wireless LAN"* ]]; then
            echo -e "  ${CYAN}•${NC} $line"
        elif [[ "$line" == *"yes"* ]]; then
            echo -e "    ${RED}✗${NC} $line"
        elif [[ "$line" == *"no"* ]]; then
            echo -e "    ${GREEN}✓${NC} $line"
        else
            echo "    $line"
        fi
    done
    echo
    
    echo -e "${GREEN}3. INTERFACE JARINGAN (ip link):${NC}"
    echo "----------------------------------------------------"
    ip -c link show | while read line; do
        if [[ "$line" == *"UP"* ]]; then
            echo -e "  ${GREEN}✓${NC} $line"
        elif [[ "$line" == *"wlan"* ]] || [[ "$line" == *"wlp"* ]]; then
            echo -e "  ${CYAN}•${NC} $line"
        else
            echo "  $line"
        fi
    done
    echo
    
    echo -e "${GREEN}4. STATUS NETWORKMANAGER:${NC}"
    echo "----------------------------------------------------"
    nmcli -c no device status | while read line; do
        if [[ "$line" == *"connected"* ]]; then
            echo -e "  ${GREEN}✓${NC} $line"
        elif [[ "$line" == *"disconnected"* ]]; then
            echo -e "  ${YELLOW}⚠${NC} $line"
        else
            echo "  $line"
        fi
    done
    echo
    
    echo -e "${GREEN}5. MODUL KERNEL WIFI YANG DIMUAT:${NC}"
    echo "----------------------------------------------------"
    lsmod | grep -E "^rtl|^ath|^iwl|^b43|^rt2|^rt[0-9]|^wl|^brcm|^mac80211" | head -20 | while read line; do
        echo -e "  ${CYAN}•${NC} $line"
    done
    echo
    
    read -p "Tekan [Enter] untuk kembali ke menu..."
}

# Fungsi untuk menampilkan menu utama
main_menu() {
    show_header
    
    echo -e "${BOLD}${WHITE}PILIH OPSI PERBAIKAN:${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "  ${GREEN}1)${NC} ${BOLD}Deteksi Perangkat WiFi & Driver${NC}"
    echo -e "     ${WHITE}└─${NC} Tampilkan semua perangkat WiFi dan status driver"
    echo
    echo -e "  ${GREEN}2)${NC} ${BOLD}Perbaiki Ralink RT3290 (wlan0)${NC}"
    echo -e "     ${WHITE}└─${NC} Perbaikan khusus untuk chipset Ralink"
    echo
    echo -e "  ${GREEN}3)${NC} ${BOLD}Perbaiki Broadcom BCM43228 (wlan1)${NC}"
    echo -e "     ${WHITE}└─${NC} Perbaikan khusus untuk chipset Broadcom"
    echo
    echo -e "  ${GREEN}4)${NC} ${BOLD}Perbaikan WiFi Otomatis${NC}"
    echo -e "     ${WHITE}└─${NC} Deteksi hardware dan instal firmware otomatis"
    echo
    echo -e "  ${GREEN}5)${NC} ${BOLD}Status Jaringan Lengkap${NC}"
    echo -e "     ${WHITE}└─${NC} Tampilkan semua informasi jaringan"
    echo
    echo -e "  ${GREEN}6)${NC} ${BOLD}Instal Semua Firmware WiFi${NC}"
    echo -e "     ${WHITE}└─${NC} Instal semua firmware yang tersedia"
    echo
    echo -e "  ${RED}7)${NC} ${BOLD}Keluar${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo
    
    read -p "Masukkan pilihan Anda [1-7]: " choice
    
    case $choice in
        1)
            detect_wifi_devices
            ;;
        2)
            fix_ralink
            ;;
        3)
            fix_broadcom
            ;;
        4)
            auto_fix_wifi
            ;;
        5)
            view_status
            ;;
        6)
            install_all_firmware
            ;;
        7)
            echo -e "${GREEN}Keluar dari skrip. Semoga WiFi Anda berjalan lancar! 😊${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid. Silakan coba lagi.${NC}"
            sleep 2
            ;;
    esac
}

# Fungsi tambahan: Install semua firmware
install_all_firmware() {
    show_header
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${BOLD}${WHITE}               INSTALASI SEMUA FIRMWARE WIFI              ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    
    print_status "Menginstal semua firmware WiFi yang tersedia..."
    echo
    
    apt-get update
    
    local firmware_packages=(
        "firmware-linux"
        "firmware-linux-nonfree"
        "firmware-atheros"
        "firmware-ralink"
        "firmware-realtek"
        "firmware-iwlwifi"
        "firmware-b43-installer"
        "firmware-brcm80211"
        "firmware-mediatek"
        "firmware-misc-nonfree"
        "firmware-ti-connectivity"
        "firmware-zd1211"
    )
    
    for pkg in "${firmware_packages[@]}"; do
        print_status "Memeriksa: $pkg"
        if ! dpkg -s "$pkg" &>/dev/null; then
            print_status "Menginstal: $pkg"
            apt-get install -y "$pkg" 2>/dev/null
        else
            print_status "$pkg sudah terinstal"
        fi
    done
    
    print_success "Instalasi firmware selesai!"
    echo
    print_status "Saran: Restart sistem untuk perubahan diterapkan sepenuhnya."
    echo
    read -p "Tekan [Enter] untuk kembali ke menu..."
}

# Loop utama skrip
while true; do
    main_menu
done
