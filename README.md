# kapparch
A simple automated way to install Arch Linux.

## TODO
- Finish installation process. (WIP)
- Add option for customization files.

---

## Pre-installation
Boot into the live Arch install and [load](https://wiki.archlinux.org/title/Linux_console/Keyboard_configuration#Loadkeys) your preferred keyboard layout with:

    # loadkeys <keymap>

If you want to connect via Wi-Fi i suggest using *iwctl*. Follow the steps in [this guide](https://wiki.archlinux.org/title/Iwd#iwctl) to connect to Wi-Fi, then test your connection with:

    # ping archlinux.org

Now download and install *git*, run:

    # pacman -Sy git --noconfirm

## Installation
Simply run the following command to download the script:

    # git clone https://github.com/akappakappa/kapparch.git

Then run this to start the guided installation:

    # bash kapparch/install.sh
