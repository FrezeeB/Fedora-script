#!/bin/bash

# Specify script directory, files and variables
echo "Starting script..."

if [ ! -d "/etc/post_installation_script" ]; then # Check if the directory exists
    mkdir /etc/post_installation_script
fi
destination_directory="/etc/post_installation_script"
flag_file="$destination_directory"/resume_script_after_reboot
username=$(who | head -n 1 | awk '{print $1}')

# Specify URLs for packages
zoom_url="https://zoom.us/client/latest/zoom_x86_64.rpm"
# Insert other packages if you need

# Start
if [ -e "$flag_file" ]; then
    echo "Resuming script after reboot..."

    #Install drivers
    echo "Installing drivers..."
    sudo dnf install -y libva-intel-driver
    #Add your kernel modules

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
    sudo dnf remove -y akregator
    sudo dnf remove -y elisa
    sudo dnf remove -y kmahjongg
    sudo dnf remove -y kmail
    sudo dnf remove -y kmines
    sudo dnf remove -y kmouth
    sudo dnf remove -y kolourpaint
    sudo dnf remove -y kpatience
    sudo dnf remove -y ktnef
    sudo dnf remove -y kwalletmanager
    sudo dnf remove -y neochat
    sudo dnf remove -y pim-sieve-editor
    sudo dnf remove -y *iwl* # Do not remove if you have an intel wireless card
    sudo dnf remove -y *nvidia* # Do not remove if you have nvidia gpu
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
    sudo -u "$username" flatpak install -y flathub app/org.telegram.desktop
    sudo -u "$username" flatpak install -y flathub app/org.libreoffice.LibreOffice/x86_64/stable
    sudo -u "$username" flatpak config languages --set "en;es" # This installs English and Spanish langpacks por flatpaks. Replace accordingly to your needs
    sudo -u "$username" flatpak update -y

    #Download additional user packages
    echo "Downloading Zoom RPM package..."
    wget --timeout=60 --continue -O "$destination_directory"/zoom_x86_64.rpm "$zoom_url"

    #Install additional user packages
    echo "Installing additional user packages..."
    cd "$destination_directory" # Change directory to install zoom
    sudo dnf localinstall -y *.rpm # Install zoom
    cd

    # Configure other settings
    systemctl start sshd
    systemctl enable sshd

    # Install proprietary stuff and additional packages
    echo "Setting multimedia and hardware acceleration..."
    sudo dnf config-manager --set-enabled fedora-cisco-openh264
    sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
    sudo dnf install -y --allowerasing ffmpeg ffmpeg-libs libva libva-utils
    sudo dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
    sudo dnf swap -y --allowerasing mesa-va-drivers mesa-va-drivers-freeworld
    sudo dnf swap -y --allowerasing mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
    
    # Create sign key and password to enroll in mokutil
    echo "Setting up signing key for drivers..."
    sudo dnf install -y kmodtool mokutil openssl akmods
    sudo kmodgenca -a
    sudo mokutil --import /etc/pki/akmods/certs/public_key.der

    # Create a flag file to resume script after reboot
    echo "Setting up script..."
    touch "$flag_file"

    #Reboot system
    echo "Rebooting system..."
    sudo reboot
    
fi
