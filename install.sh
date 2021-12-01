#!/bin/bash
# kapparch - by github.com/akappakappa

function f_config() {
    echo "+---------------------------------------------------------------------+"
    echo "|                                                                     |"
    echo "|   kapparch - a guided ArchLinux install by github.com/akappakappa   |"
    echo "|                                                                     |"
    echo "|    All the setup questions will be asked now, you will be warned    |"
    echo "|    when the actual installation starts :)                           |"
    echo "|                                                                     |"
    echo "+---------------------------------------------------------------------+"
    read -p "Choose keyboard layout: " u_layout
    loadkeys $u_layout
    fdisk -l && read -p "What disk do you want to install Arch to?: " u_rootdisk
    read -p "Select disk for /mnt/data partition, type \"no\" if you have a single disk: " u_datadisk
    read -p "Type list of countries for mirrorlist -> \"'Country1,Country2,'\" : " u_mirrors
    read -p "Insert time zone -> \"Region/City\" : " u_timezone
    read -p "Insert your CPU brand (Intel/Amd): " u_cpu
    read -p "Insert your GPU brand (Nvidia/Amd/Intel): " u_gpu
    read -p "Choose a username: " u_username
    read -p "Choose a hostname: " u_hostname
    echo "OK"
    sleep 2
    clear
}

function f_partition() {
    echo "Ensuring system clock is accurate.."
    timedatectl set-ntp true
    echo "Installing partitioning tools.."
    pacman -S gptfdisk --needed --noconfirm
    echo "FORMATTING SELECTED DISKS:"
    echo "root: ${u_rootdisk} | home: ${u_datadisk}"
    echo -n "5 " && sleep 1 && echo -n "4 " && sleep 1 && echo -n "3 " && sleep 1 && echo -n "2 " && sleep 1 && echo -n "1 " && sleep 1 && echo "0 " && sleep 1
    echo "Doing partitioning work.."
    sgdisk -Z $u_rootdisk # Zap (destroy) the GPT and MBR data structures and then exit.
    sgdisk -a 2048 -o $u_rootdisk # New GPT table with 2048 alignment
    sgdisk -n 1:0:+512M $u_rootdisk # partition 1, start left, size 512M
    sgdisk -n 2:0:0 $u_rootdisk # partition 2, start left, size remaining
    sgdisk -t 1:ef00 $u_rootdisk # partition 1 -> type: EFI system partition
    sgdisk -t 2:8304 $u_rootdisk # partition 2 -> type: Linux x86-64 root (/)
    # ROOT DISK
    if [[ ${u_rootdisk} =~ "nvme" ]]; then
        mkfs.fat -F32 "${u_rootdisk}p1"
        mkfs.ext4 "${u_rootdisk}p2" -F
        mount "${u_rootdisk}p2" /mnt
        mkdir /mnt/boot
        mount "${u_rootdisk}p1" /mnt/boot
    else
        mkfs.fat -F32 "${u_rootdisk}1"
        mkfs.ext4 "${u_rootdisk}2" -F
        mount "${u_rootdisk}2" /mnt
        mkdir /mnt/boot
        mount "${u_rootdisk}1" /mnt/boot
    fi
    # DATA DISK
    if [[ ${u_datadisk} != "no" ]]; then
        sgdisk -Z $u_datadisk # Zap (destroy) the GPT and MBR data structures and then exit.
        sgdisk -a 2048 -o $u_datadisk # New GPT table with 2048 alignment
        sgdisk -n 1:0:0 $u_datadisk # partition 1, start left, size remaining
        sgdisk -t 1:8300 $u_datadisk # partition 1 -> type: Linux filesystem
        if [[ ${u_datadisk} =~ "nvme" ]]; then
            mkfs.ext4 "${u_datadisk}p1" -F
            mkdir /mnt/mnt
            mkdir /mnt/mnt/data
            mount "${u_datadisk}p1" /mnt/mnt/data
        else
            mkfs.ext4 "${u_datadisk}1" -F
            mkdir /mnt/mnt
            mkdir /mnt/mnt/data
            mount "${u_datadisk}1" /mnt/mnt/data
        fi
    fi
    echo "OK"
    sleep 2
    clear
}

function f_install() {
    # Mirrors
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    echo "Setting up mirrors.."
    reflector -a 48 -c $u_mirrors -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
    echo "Installing base system : base, base-devel, efibootmgr, efivar, linux, linux-firmware, pacman-contrib"
    pacstrap /mnt base base-devel efibootmgr efivar linux linux-firmware pacman-contrib --noconfirm --needed
    echo "Generating fstab.."
    genfstab -U /mnt >> /mnt/etc/fstab
    echo "Copying mirrorlist to system.."
    cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
    echo "OK"
    sleep 2
    clear
}

function f_variables() {
    echo "u_timezone=${u_timezone}" > /root/kapparch/variables.conf
    echo "u_cpu=${u_cpu}" >> /root/kapparch/variables.conf
    echo "u_gpu=${u_gpu}" >> /root/kapparch/variables.conf
    echo "u_username=${u_username}" >> /root/kapparch/variables.conf
    echo "u_hostname=${u_hostname}" >> /root/kapparch/variables.conf
}

function main() {
    f_config
    f_partition
    f_install
    f_variables
    cp -R /root/kapparch /mnt/root
    arch-chroot /mnt bash /root/kapparch/chroot.sh
}

main
echo "Done!"