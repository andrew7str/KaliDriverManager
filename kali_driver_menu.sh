#!/bin/bash

# ==============================================================================
# Skrip Menu Perbaikan Driver dan Firmware untuk Kali Linux (berbasis Debian)
# ==============================================================================

# Hentikan eksekusi jika terjadi error
set -e

# --- Fungsi Utilitas ---

# Fungsi untuk memeriksa hak akses root
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Skrip ini perlu dijalankan dengan hak akses root." >&2
    echo "Silakan jalankan dengan: sudo ./kali_driver_menu.sh" >&2
    exit 1
  fi
}

# Fungsi untuk menekan tombol Enter untuk melanjutkan
press_enter_to_continue() {
  echo
  read -p "Tekan [Enter] untuk kembali ke menu utama..."
}

# --- Fungsi Perbaikan ---

# 1. Update sistem penuh
update_system() {
  echo "### Memulai Pembaruan Sistem Penuh ###"
  echo "Langkah ini akan memperbarui daftar paket dan meng-upgrade semua paket sistem."
  echo "Proses ini bisa memakan waktu lama."
  
  read -p "Apakah Anda ingin melanjutkan? (y/n): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Pembaruan sistem dibatalkan."
      return
  fi

  echo "--> Menjalankan 'apt-get update'..."
  apt-get update
  
  echo "--> Menjalankan 'apt-get dist-upgrade -y'..."
  apt-get dist-upgrade -y
  
  echo "### Pembaruan Sistem Selesai ###"
  press_enter_to_continue
}

# 2. Perbaikan WLAN (Broadcom & Realtek)
fix_wlan() {
  echo "### Memulai Perbaikan Driver WLAN ###"
  
  # Cari semua kartu network controller
  local WLAN_DEVICES=()
  while IFS= read -r line; do
    WLAN_DEVICES+=("$line")
  done < <(lspci | grep -i "network controller")

  if [ ${#WLAN_DEVICES[@]} -eq 0 ]; then
    echo "--> Tidak ada kartu WLAN (network controller) yang terdeteksi oleh lspci."
    press_enter_to_continue
    return
  fi

  # Tambahkan opsi untuk keluar
  WLAN_DEVICES+=("Kembali ke Menu Utama")

  echo "Kartu WLAN berikut terdeteksi di sistem Anda:"
  local PS3=$'\nPilih kartu WLAN yang ingin diperbaiki: '
  
  select DEVICE in "${WLAN_DEVICES[@]}"; do
    if [[ "$DEVICE" == "Kembali ke Menu Utama" ]]; then
      echo "Kembali ke menu utama..."
      break
    elif [ -n "$DEVICE" ]; then
      echo "--> Anda memilih: $DEVICE"
      
      # Jalankan perbaikan berdasarkan vendor yang terdeteksi pada baris yang dipilih
      if echo "$DEVICE" | grep -iq "Broadcom"; then
        echo "--> Menjalankan perbaikan untuk Broadcom..."
        if dpkg -l | grep -q "broadcom-sta-dkms"; then
            echo "--> INFO: Driver Broadcom (broadcom-sta-dkms) sudah terpasang. Menjalankan rekonfigurasi."
            dpkg-reconfigure broadcom-sta-dkms
        else
            echo "--> Menginstal linux-headers dan driver broadcom-sta-dkms..."
            apt-get install -y linux-headers-$(uname -r) broadcom-sta-dkms
        fi
        echo "--> Memuat ulang modul driver 'wl'..."
        modprobe -r b44 b43 b43legacy ssb brcmsmac bcma wl &>/dev/null || true
        modprobe wl
        echo "--> Modul driver Broadcom (wl) telah dimuat."

      elif echo "$DEVICE" | grep -iq "Realtek"; then
        echo "--> Menjalankan perbaikan untuk Realtek..."
        if dpkg -l | grep -q "firmware-realtek"; then
            echo "--> INFO: Paket firmware Realtek (firmware-realtek) sudah terpasang."
        else
            echo "--> Menginstal paket firmware Realtek..."
            apt-get install -y firmware-realtek
            echo "--> Paket firmware Realtek berhasil diinstal."
        fi

      elif echo "$DEVICE" | grep -iq "Intel"; then
        echo "--> Menjalankan perbaikan untuk Intel..."
        if dpkg -l | grep -q "firmware-iwlwifi"; then
            echo "--> INFO: Paket firmware Intel (firmware-iwlwifi) sudah terpasang."
        else
            echo "--> Menginstal paket firmware Intel (firmware-iwlwifi)..."
            apt-get install -y firmware-iwlwifi
            echo "--> Paket firmware Intel berhasil diinstal."
        fi

      else
        echo "--> Tidak ada tindakan perbaikan otomatis yang diketahui untuk kartu ini."
        echo "--> Pastikan Anda sudah mencoba 'Instalasi Firmware Umum' (Opsi 4)."
      fi
      
      # Keluar dari sub-menu setelah tindakan selesai
      break
    else
      echo "Pilihan tidak valid. Silakan coba lagi."
    fi
  done

  press_enter_to_continue
}

# 3. Perbaikan Graphics
fix_graphics() {
  # Definisikan variabel warna ANSI
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  BLUE='\033[0;34m'
  YELLOW='\033[0;33m'
  NC='\033[0m' # No Color

  echo "### Memulai Perbaikan Driver Graphics ###"
  
  # Logika deteksi yang lebih akurat: cari baris "VGA compatible controller"
  VGA_LINE=$(lspci | grep -i "VGA compatible controller")

  # Jika tidak ditemukan, coba pencarian yang lebih luas sebagai fallback
  if [ -z "$VGA_LINE" ]; then
    echo "--> Tidak ditemukan 'VGA compatible controller', mencari perangkat Display lain..."
    VGA_LINE=$(lspci | grep -i 'VGA\|3D\|Display' | head -n 1) # Ambil baris pertama saja
  fi

  if [ -z "$VGA_LINE" ]; then
    echo -e "--> ${YELLOW}Tidak dapat mendeteksi perangkat grafis utama.${NC}"
    echo "--> Tidak ada tindakan yang dapat diambil."
  
  elif echo "$VGA_LINE" | grep -iq "Intel"; then
    echo -e "--> Tipe Kartu Grafis: ${BLUE}Intel${NC}"
    echo "--> Detail Perangkat: $VGA_LINE"
    echo "--> Menginstal firmware dan microcode untuk Intel..."
    apt-get install -y firmware-misc-nonfree intel-microcode
    echo "--> Firmware dan microcode Intel telah berhasil diinstal."

  elif echo "$VGA_LINE" | grep -iq "AMD\|ATI"; then
    echo -e "--> Tipe Kartu Grafis: ${RED}AMD/ATI${NC}"
    echo "--> Detail Perangkat: $VGA_LINE"
    echo "--> Menginstal firmware untuk AMD..."
    apt-get install -y firmware-amd-graphics
    echo "--> Firmware AMD telah berhasil diinstal."

  elif echo "$VGA_LINE" | grep -iq "NVIDIA"; then
    echo -e "--> Tipe Kartu Grafis: ${GREEN}NVIDIA${NC}"
    echo "--> Detail Perangkat: $VGA_LINE"
    echo "--> Menginstal driver NVIDIA proprietary..."
    apt-get install -y nvidia-driver nvidia-kernel-dkms
    echo "--> Driver NVIDIA telah berhasil diinstal."
  
  else
    echo -e "--> Tipe Kartu Grafis: ${YELLOW}Tidak Dikenali Secara Spesifik${NC}"
    echo "--> Detail Perangkat: $VGA_LINE"
    echo "--> Tidak ada tindakan instalasi driver spesifik yang diambil."
    echo "--> Pastikan Anda telah menjalankan 'Instalasi Firmware Umum' dari menu utama."
  fi

  echo "### Perbaikan Graphics Selesai ###"
  press_enter_to_continue
}

# 4. Perbaikan Sound
fix_sound() {
  echo "### Memulai Perbaikan Driver Sound ###"
  echo "--> Menginstal firmware tambahan untuk sound (firmware-sof-signed)..."
  apt-get install -y firmware-sof-signed
  echo "--> Menginstal ulang utilitas ALSA dan PulseAudio/PipeWire..."
  apt-get install -y --reinstall alsa-utils pipewire wireplumber pulseaudio
  echo "### Perbaikan Sound Selesai ###"
  press_enter_to_continue
}

# 5. Instalasi Firmware Umum
install_firmware_all() {
    echo "### Memulai Instalasi Firmware Umum ###"
    echo "--> Menginstal paket firmware lengkap dari Kali Linux..."
    apt-get install -y kali-linux-firmware firmware-linux firmware-linux-nonfree firmware-misc-nonfree
    echo "### Instalasi Firmware Umum Selesai ###"
    press_enter_to_continue
}

# 6. Instalasi Utilitas Baterai TLP
install_tlp() {
    echo "### Memulai Instalasi Utilitas Baterai TLP ###"
    echo "TLP adalah utilitas untuk mengoptimalkan penggunaan daya baterai."
    echo "Ini tidak memperbaiki baterai yang rusak, tetapi memperpanjang masa pakainya per pengisian daya."
    apt-get install -y tlp tlp-rdw
    echo "--> Mengaktifkan dan memulai layanan TLP..."
    systemctl enable tlp
    systemctl start tlp
    echo "### Instalasi TLP Selesai ###"
    press_enter_to_continue
}

# 7. Jalankan Semua
run_all_fixes() {
    echo "### Memulai Semua Proses Perbaikan dan Instalasi ###"
    echo "Proses ini akan menjalankan semua opsi perbaikan secara berurutan."
    
    read -p "Ini bisa memakan waktu yang sangat lama. Apakah Anda yakin ingin melanjutkan? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Proses dibatalkan."
        return
    fi

    echo "--- Menjalankan Pembaruan Sistem ---"
    apt-get update
    apt-get dist-upgrade -y
    
    echo "--- Menjalankan Instalasi Firmware Umum ---"
    install_firmware_all

    echo "--- Menjalankan Perbaikan WLAN ---"
    fix_wlan

    echo "--- Menjalankan Perbaikan Graphics ---"
    fix_graphics

    echo "--- Menjalankan Perbaikan Sound ---"
    fix_sound
    
    echo "--- Menjalankan Instalasi TLP ---"
    install_tlp
    
    echo
    echo "#####################################################"
    echo "### SEMUA PROSES PERBAIKAN TELAH SELESAI ###"
    echo "#####################################################"
    echo
    echo "Sangat disarankan untuk me-restart komputer Anda sekarang."
    press_enter_to_continue
}


# --- Menu Utama ---
show_menu() {
  clear
  echo "================================================="
  echo "      MENU PERBAIKAN DRIVER - KALI LINUX"
  echo "================================================="
  echo "Pilih tindakan yang ingin Anda lakukan:"
  echo
  echo "1.  Perbaikan Driver WLAN (Broadcom & Realtek)"
  echo "2.  Perbaikan Driver Graphics (NVIDIA/AMD/Intel)"
  echo "3.  Perbaikan Driver Sound"
  echo "4.  Instalasi Firmware Umum (Direkomendasikan)"
  echo "5.  Instalasi Utilitas Manajemen Baterai (TLP)"
  echo "-------------------------------------------------"
  echo "6.  Pembaruan Sistem Penuh (Wajib sebelum lainnya)"
  echo "7.  JALANKAN SEMUA PERBAIKAN (Paling Direkomendasikan)"
  echo "-------------------------------------------------"
  echo "8.  Keluar"
  echo
}

# --- Loop Utama ---
main() {
  check_root
  
  while true; do
    show_menu
    read -p "Masukkan pilihan Anda [1-8]: " choice
    
    case $choice in
      1) fix_wlan ;;
      2) fix_graphics ;;
      3) fix_sound ;;
      4) install_firmware_all ;;
      5) install_tlp ;;
      6) update_system ;;
      7) run_all_fixes ;;
      8)
        echo "Keluar dari skrip. Disarankan untuk me-restart jika Anda melakukan perubahan."
        break
        ;;
      *)
        echo "Pilihan tidak valid. Silakan coba lagi."
        press_enter_to_continue
        ;;
    esac
  done
}

# Panggil fungsi utama
main
