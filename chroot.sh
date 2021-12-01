#!/bin/bash

function f_setup() {
    # Mirrorlist
    echo "Installing mirrorlist tools.."
    pacman -Sy reflector rsync --needed --noconfirm
    echo "reflector.timer is enabled at startup"
    systemctl enable reflector.timer
    echo "Tweaking pacman.conf.."
    sed -i 's/^#Para/Para/' /etc/pacman.conf # ParallelDownloads
    sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf # [multilib]

    # Time and Language
    echo "Setting timezone.."
    ln -sf /usr/share/zoneinfo/$u_timezone /etc/localtime
    echo "Generating /etc/adjtime.."
    hwclock --systohc
    echo "Adding \"en_US.UTF-8 UTF-8\" to /etc/locale.gen.."
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    echo "Generating locale.."
    locale-gen
    echo "Adding \"LANG=en_US.UTF-8\" to /etc/locale.conf.."
    echo "LANG=en_US.UTF-8" >> /etc/locale.conf
    echo "Adding \"KEYMAP=${u_layout}\" to /etc/vconsole.conf.."
    echo "KEYMAP=${u_layout}" >> /etc/vconsole.conf
    echo "Setting up network manager.."

    # Network
    echo "Installing network tools.."
    pacman -S networkmanager dhclient --needed --noconfirm
    echo "NetworkManager is enabled at startup"
    systemctl enable NetworkManager

    # Bootloader
    echo "Configuring bootloader.."
    bootctl install

    # Makepkg tweaks
    echo "Tweaking makepkg.."
    nc=$(grep -c ^processor /proc/cpuinfo)
    TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
    if [[  $TOTALMEM -gt 8000000 ]]; then
        sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$nc"/g' /etc/makepkg.conf
        sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g' /etc/makepkg.conf
    fi
}

function f_hardware() {
    # CPU microcode
    case $u_cpu in
    [iI]|[iI][nN][tT][eE][lL])
        echo "Installing Intel microcode.."
        pacman -S intel-ucode --needed --noconfirm
    ;;
    [aA]|[aA][mM][dD])
        echo "Installing AMD microcode.."
        pacman -S amd-ucode --needed --noconfirm
    ;;
    esac

    # GPU drivers
    case $u_gpu in
    [nN]|[nN][vV][iI][dD][iI][aA])
        echo "Installing Nvidia drivers.."
        pacman -S nvidia nvidia-utils --needed --noconfirm 
    ;;
    aA]|[aA][mM][dD])
        echo "Installing AMD drivers.."
        pacman -S xf86-video-amdgpu --needed --noconfirm
    ;;
    [iI]|[iI][nN][tT][eE][lL])
        echo "Installing Intel drivers.."
        pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils --needed --noconfirm
    ;;
    esac
}

function f_packages() {
    echo "Installing packages.."
    PKGS=(
        # basic stuff
        "base-devel"
        "bash-completion"
        "bind"
        "cmatrix"
        "cronie"
        "curl"
        "dialog"
        "dosfstools"
        "exfat-utils"
        "fuse2"
        "fuse3"
        "fuseiso"
        "git"
        "gptfdisk"
        "grub-customizer"
        "htop"
        "libnewt"
        "linux-headers"
        "lsof"
        "make"
        "neofetch"
        "ntfs-3g"
        "ntp"
        "openssh"
        "p7zip"
        "powerline"
        "powerline-common"
        "powerline-fonts"
        "python-pip"
        "sudo"
        "traceroute"
        "ttf-hack"
        "ufw"
        "usbutils"
        "wget"
        "which"
        "xdg-user-dirs"
        "zeroconf-ioslave"
        "zsh"
        "zsh-syntax-highlighting"
        "zsh-autosuggestions"

        # dev
        "code"
        "gcc"
        "go"
        "jdk-openjdk"
        "python"

        # extra drivers/plugins
        "alsa-plugins"
        "alsa-utils"
        "bluez"
        "bluez-libs"
        "pulseaudio"
        "pulseaudio-alsa"
        "pulseaudio-bluetooth"
    )
    for PKG in "${PKGS[@]}"; do
        PKGlist="${PKGlist}${PKG} "
    done
    pacman -Sy ${PKGlist} --noconfirm --needed
}

function f_user() {
    sleep 2
    clear
    echo "> ROOT user setup"
    passwd
    echo "> ${u_username} user setup"
    useradd -m -G wheel -s /usr/bin/zsh ${u_username}
    passwd ${u_username}
    sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
    echo "Setting hostname.."
    echo "${u_hostname}" >> /etc/hostname
    echo "Installing Yay AUR helper.."
    cd /home/${u_username}
    git clone https://aur.archlinux.org/yay.git
    cd yay
    chown -R ${u_username} /home/${u_username}/yay
    sudo -u ${u_username} makepkg -si --noconfirm
    cd /
}

function main() {
    source /root/kapparch/variables.conf
    f_setup
    f_hardware
    f_packages
    f_user
}

main