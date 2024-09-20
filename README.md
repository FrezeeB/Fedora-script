This is a script to tweak Fedora **after a fresh installation**. This script will:

1. Remove some preinstalled apps
2. Replace default Libreoffice with flatpak version
3. Import key to sign drivers for secure boot
4. Install aditional user packages

After running the script your device will reboot, make sure to run it **once again** to finish pending tasks. To execute this script, open a terminal and run:

**For Gnome:**

sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/FrezeeB/Fedora-script/main/post-installation-script-Gnome.sh)"

**For KDE Plasma:**

sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/FrezeeB/Fedora-script/main/post-installation-script-KDE-Plasma.sh)"
