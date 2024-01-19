#!/bin/bash

# Specify script directory, files and variables
echo "Starting script..."

if [ ! -d "/etc/post_installation_script" ]; then # Check if the directory exists
    mkdir /etc/post_installation_script
fi
destination_directory="/etc/post_installation_script"
flag_file="$destination_directory"/resume_script_after_reboot
username=$(who | head -n 1 | awk '{print $1}')
wget --timeout=60 --continue -O "$destination_directory" https://raw.githubusercontent.com/FrezeeB/Fedora-script/20d3108910476ac67d51d1004ce21e23b86e4a2e/post_installation_script.sh

# Specify URLs for packages
zoom_url="https://zoom.us/client/latest/zoom_x86_64.rpm"
libreoffice_url="https://download.documentfoundation.org/libreoffice/stable/7.6.4/rpm/x86_64/LibreOffice_7.6.4_Linux_x86-64_rpm.tar.gz"
libreoffice_langpack_url="https://download.documentfoundation.org/libreoffice/stable/7.6.4/rpm/x86_64/LibreOffice_7.6.4_Linux_x86-64_rpm_langpack_es.tar.gz" # This is Spanish langpack, replace accordingly to your needs
bluetooth_firmware_url="https://github.com/FrezeeB/Fedora-script/raw/bc43c58dabc3dde74adb040134f805c257b6f048/BCM43142A0-0a5c-216d.hcd"
# Insert other packages if you need

# Start
if [ -e "$flag_file" ]; then
    echo "Resuming script after reboot..."

    #Install broadcom driver
    echo "Installing wifi driver..."
    sudo dnf install broadcom-wl -y
    sudo dnf install broadcom-bt-firmware -y

    #Compiling kernel modules and updating boot image
    echo "Loading kernel modules..."
    sudo akmods --force
    sudo dracut --force

    #Remove unused bluetooth firmware
    echo "Deleting unused broadcom bluetooth firmware files..."
    sudo rm -f /lib/firmware/brcm/*xz

    #Install bluetooth firmware
    echo "Setting up broadcom bluetooth firmware..."
    wget -O "$destination_directory"/BCM43142A0-0a5c-216d.hcd "$bluetooth_firmware_url"
    sudo cp "$destination_directory"/BCM43142A0-0a5c-216d.hcd /lib/firmware/brcm

    #Remove script leftovers and system cleanup
    echo "Running system cleanup..."
    sudo dnf -y autoremove
    sudo dnf clean all
    sudo rm -rf "$destination_directory"
    sudo reboot

else
    # Remove gnome useless apps
    echo "Removing bloatware..."
    sudo dnf remove -y gnome-maps
    sudo dnf remove -y gnome-tour
    sudo dnf remove -y gnome-color-manager
    sudo dnf remove -y rhythmbox
    sudo dnf remove -y mediawriter
    sudo dnf remove -y simple-scan
    sudo dnf remove -y *pinyin*
    sudo dnf remove -y *zhuyin*
    sudo dnf remove -y gnome-connections
    sudo dnf remove -y gnome-boxes
    sudo dnf remove -y gnome-font-viewer
    sudo dnf remove -y *libreoffice*
    sudo dnf remove -y *iwl* # Do not remove if you have an intel wireless card
    sudo dnf remove -y *nvidia* # Do not remove if you have nvidia gpu
    sudo dnf remove -y *amd*gpu # Do not remove if you have amd gpu

    # Make dnf faster
    echo "Tweaking dnf config..."
    echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf > /dev/null
    echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf > /dev/null

    # Enable RPM Fusion repos
    echo "Enabling RPM Fusion in your system..."
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y rpmfusion-nonfree-release-tainted

    # Make RPM Fusion repos available for GUIs
    echo "Installing Appstream metadata..."
    sudo dnf groupupdate core -y

    # System update
    echo "Updating the system..."
    sudo dnf update -y

    # Install user packages
    echo "Installing user packages..."
    sudo flatpak install app/org.telegram.desktop
    sudo dnf install rstudio-desktop -y
    sudo dnf install pycharm-community -y

    #Download additional user packages
    echo "Downloading Zoom RPM package..."
    wget --timeout=60 --continue -O "$destination_directory"/zoom_x86_64.rpm "$zoom_url"
    echo "Downloading LIbreOffice RPM packages..."
    wget --timeout=60 --continue -O "$destination_directory"/LibreOffice_7.6.4_Linux_x86-64_rpm.tar.gz "$libreoffice_url"
    wget --timeout=60 --continue -O "$destination_directory"/LibreOffice_7.6.4_Linux_x86-64_rpm_langpack_es.tar.gz "$libreoffice_langpack_url"

    #Install additional user packages
    echo "Installing additional user packages..."
    tar -xzf "$destination_directory"/LibreOffice_7.6.4_Linux_x86-64_rpm.tar.gz -C "$destination_directory"
    tar -xzf "$destination_directory"/LibreOffice_7.6.4_Linux_x86-64_rpm_langpack_es.tar.gz -C "$destination_directory"
    cd "$destination_directory" # Change directory to install zoom
    sudo dnf localinstall *.rpm -y # Install zoom
    cd "$destination_directory"/LibreOffice_7.6.4.1_Linux_x86-64_rpm/RPMS # Change directory to install LibreOffice
    sudo dnf localinstall *.rpm -y # Install LibreOffice
    cd "$destination_directory"/LibreOffice_7.6.4.1_Linux_x86-64_rpm_langpack_es/RPMS # Change directory to install LibreOffice langpack
    sudo dnf localinstall *.rpm -y # Install LibreOffice langpack
    cd

    # Configure other Gnome settings
    sudo -u "$username" gsettings set org.gnome.desktop.interface show-battery-percentage true
    sudo -u "$username" gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true

    # Install proprietary stuff and additional packages
    echo "Installing additional packages..."
    sudo dnf swap ffmpeg-free ffmpeg --allowerasing
    sudo dnf install kmodtool akmods mokutil openssl -y

    # Create sign key and password to enroll in mokutil
    echo "Setting up signing key for drivers..."
    sudo kmodgenca -a
    sudo mokutil --import /etc/pki/akmods/certs/public_key.der

    # Create a flag file to resume script after reboot
    echo "Setting up script..."
    touch "$flag_file"

    #Reboot system
    echo "Rebooting system..."
    sudo reboot
    
fi
