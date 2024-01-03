#!/bin/bash

# Specify flag file
flag_file="/tmp/resume_script_after_reboot"
script_path="/tmp/post_installation_script.sh"
service_file="/etc/systemd/system/resume_post_installation_script.service"

# Start
if [ -e "$flag_file" ]; then
    echo "Resuming script after reboot..."

else
    # Remove gnome useless apps
    echo "Removing bloatware..."
    sudo dnf remove gnome-maps
    sudo dnf remove rhythmbox
    sudo dnf remove *pinyin*
    sudo dnf remove *zhuyin*
    sudo dnf remove gnome-connections
    sudo dnf remove gnome-boxes
    sudo dnf remove *iwl* #Do not remove if you have an intel wireless card
    sudo dnf remove *nvidia* #Do not remove if you have nvidia gpu
    sudo dnf remove *amd*gpu* #Do not remove if you have amd gpu
    sudo dnf remove *libreoffice*

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
