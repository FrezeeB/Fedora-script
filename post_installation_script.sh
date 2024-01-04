#!/bin/bash

# Specify flag files and directories
echo "Starting script..."
mkdir /tmp/post_installation_script
destination_directory="/tmp/post_installation_script"
flag_file="/tmp/post_installation_script/resume_script_after_reboot"
script_path="/tmp/post_installation_script/post_installation_script.sh"
service_file="/etc/systemd/system/resume_post_installation_script.service"

# Specify URLs and variables for packages
zoom_url="https://zoom.us/client/latest/zoom_x86_64.rpm"
libreoffice_url="https://www.libreoffice.org/donate/dl/rpm-x86_64/7.6.4/es/LibreOffice_7.6.4_Linux_x86-64_rpm.tar.gz"
libreoffice_langpack_url="https://download.documentfoundation.org/libreoffice/stable/7.6.4/rpm/x86_64/LibreOffice_7.6.4_Linux_x86-64_rpm_langpack_es.tar.gz"
bluetooth_firmware_url="https://github.com/FrezeeB/Fedora-script/raw/bc43c58dabc3dde74adb040134f805c257b6f048/BCM43142A0-0a5c-216d.hcd"

# Start
if [ -e "$flag_file" ]; then
    echo "Resuming script after reboot..."

    #Install broadcom driver
    echo "Installing wifi driver..."
    sudo dnf install broadcom-wl

    #Compiling kernel modules and updating boot image
    echo "Loading kernel modules"
    sudo akmods --force
    sudo dracut --force
    
    #Download additional user packages
    echo "Downloading Zoom RPM package..."
    wget -O "$destination_directory/zoom_x86_64.rpm" "$zoom_url"
    echo "Downloading LIbreOffice RPM packages..."
    wget -O "$destination_directory/LibreOffice_7.6.4_Linux_x86-64_rpm.tar.gz" "$libreoffice_url"
    wget -O "$destination_directory/LibreOffice_7.6.4_Linux_x86-64_rpm_langpack_es.tar.gz" "$libreoffice_langpack_url"

    #Install additional user packages
    echo "Installing user packages..."
    tar -xzf /tmp/post_installation_script/LibreOffice_7.6.4_Linux_x86-64_rpm.tar.gz -C /tmp/post_installation_script
    tar -xzf /tmp/post_installation_script/LibreOffice_7.6.4_Linux_x86-64_rpm_langpack_es.tar.gz -C /tmp/post_installation_script
    sudo dnf localinstall /tmp/post_installation_script/*rpm
    sudo dnf localinstall /tmp/post_installation_script/LibreOffice_7.6.4.1_Linux_x86-64_rpm/RPMS/*rpm
    sudo dnf localinstall /tmp/post_installation_script/LibreOffice_7.6.4.1_Linux_x86-64_rpm_langpack_es/RPMS/*rpm

    #Remove unused bluetooth firmware
    echo "Deleting unused bluetooth firmware files..."
    sudo rm -f /lib/firmware/brcm/*xz

    #Install bluetooth firmware
    echo "Setting up broadcom bluetooth firmware..."
    wget -O "$destination_directory/BCM43142A0-0a5c-216d.hcd" "$bluetooth_firmware_url"
    sudo cp "$destination_directory/BCM43142A0-0a5c-216d.hcd" /lib/firmware/brcm

    #Remove script leftovers and system cleanup
    echo "Running system cleanup..."
    sudo systemctl disable resume_post_installation_script.service
    sudo rm -f "$service_file"
    sudo systemctl daemon-reload
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
    sudo dnf remove -y *pinyin*
    sudo dnf remove -y *zhuyin*
    sudo dnf remove -y gnome-connections
    sudo dnf remove -y gnome-boxes
    sudo dnf remove -y *iwl* # Do not remove if you have an intel wireless card
    sudo dnf remove -y *nvidia* # Do not remove if you have nvidia gpu
    sudo dnf remove -y *amd*gpu* # Do not remove if you have amd gpu
    sudo dnf remove -y *libreoffice*

    # Make dnf faster
    echo "Tweaking dnf config..."
    echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
    echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf

    # Enable RPM Fusion repos
    echo "Enabling RPM Fusion in your system..."
    sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    # Make RPM Fusion repos available for GUIs
    echo "Installing Appstream metadata"
    sudo dnf groupupdate core

    # System update
    echo "Updating the system..."
    sudo dnf update

    # Install user packages
    echo "Installing user packages..."
    sudo flatpak install telegram-desktop
    sudo dnf install rstudio
    sudo dnf install pycharm-community

    # Configure Gnome
    echo "Configuring Gnome settings..."
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    gsettings set org.gnome.desktop.interface enable-hot-corners false
    gsettings set org.gnome.settings-daemon.plugins.power power-button-action "interactive"

    # Install proprietary stuff and additional packages
    echo "Installing additional packages..."
    sudo dnf swap ffmpeg-free ffmpeg --allowerasing
    sudo dnf install kmodtool akmods mokutil openssl

    # Create sign key and password to enroll in mokutil
    echo "Setting up signing key for drivers..."
    sudo kmodgenca -a
    sudo mokutil --import /etc/pki/akmods/certs/public_key.der

    # Create a flag file to resume script after reboot
    echo "Setting up script..."
    touch "$flag_file"

    # Create systemd service
    echo "Setting up systemd service..."
    echo "[Unit]
    Description=Resume script after reboot

    [Service]
    Type=oneshot
    ExecStart=$script_path
    User=root

    [Install]
    WantedBy=default.target" | sudo tee "$service_file" > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable resume_post_installation_script.service

    #Reboot system
    echo "Rebooting system..."
    sudo reboot
