#!/bin/bash

# Specify script directory, files and variables
echo "Starting script..."

if [ ! -d "/etc/post_installation_script" ]; then # Check if the directory exists
    mkdir /etc/post_installation_script
fi
destination_directory="/etc/post_installation_script"
flag_file="$destination_directory"/resume_script_after_reboot
username=$(who | head -n 1 | awk '{print $1}')

# Start
if [ -e "$flag_file" ]; then
    echo "Resuming script after reboot..."

    #Install drivers
    echo "Installing drivers..."
    sudo dnf install -y intel-media-driver

    #Compiling kernel modules and updating boot image
    echo "Loading kernel modules..."
    sudo akmods --force
    sudo dracut --force

    #Remove script leftovers and system cleanup
    echo "Running system cleanup..."
    sudo dnf autoremove -y
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
    sudo dnf remove -y *libreoffice*
    sudo dnf remove -y malcontent-control
    sudo dnf remove -y *iwl* # Do not remove if you have an intel wireless card
    sudo dnf remove -y *nvidia* # Do not remove if you have nvidia gpu
    sudo dnf remove -y *amd*gpu # Do not remove if you have amd gpu
    sudo dnf remove -y *virtualbox*
    
    # Make dnf faster
    echo "Tweaking dnf config..."
    echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf > /dev/null
    echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf > /dev/null

    # Enable RPM Fusion repos
    echo "Enabling RPM Fusion in your system..."
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    # Make RPM Fusion repos available for GUIs
    echo "Installing Appstream metadata..."
    sudo dnf groupupdate -y core

    # System update
    echo "Updating the system..."
    sudo dnf update -y

    # Install user packages
    echo "Installing user packages..."
    sudo -u "$username" flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    sudo -u "$username" flatpak config languages --set "en;es" # This installs English and Spanish langpacks por flatpaks. Replace accordingly to your needs
    sudo -u "$username" flatpak install -y flathub app/org.telegram.desktop
    sudo -u "$username" flatpak install -y flathub app/org.libreoffice.LibreOffice/x86_64/stable
    sudo -u "$username" flatpak update -y

    # Configure other settings
    sudo -u "$username" gsettings set org.gnome.desktop.interface show-battery-percentage true
    sudo -u "$username" gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    sudo -u "$username" gsettings set org.gnome.settings-daemon.plugins.power power-button-action interactive
    systemctl start sshd
    systemctl enable sshd

    # Install proprietary stuff and additional packages
    echo "Installing additional packages..."
    sudo dnf install -y ffmpeg --allowerasing
    sudo dnf install -y kmodtool mokutil openssl akmods

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
