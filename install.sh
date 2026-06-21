#!/bin/bash

# netrecon.sh - this is in online Recon tool which is use to know more about a server 
# i have made this for learning purposes and authorized pentesting only
# only scan systems that you own or have permission for


# colors
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
CYAN='\e[0;36m'
BLUE='\e[0;34m'
BOLD='\e[1m'
RESET='\e[0m'


# ASCII banner
print_banner() {
    echo -e "${CYAN}"
    echo "  _   _      _   ____                      "
    echo " | \ | | ___| |_|  _ \ ___  ___ ___  _ __  "
    echo " |  \| |/ _ \ __| |_) / _ \/ __/ _ \| '_ \ "
    echo " | |\  |  __/ |_|  _ <  __/ (_| (_) | | | |"
    echo " |_| \_|\___|\__|_| \_\___|\___\___/|_| |_|"
    echo ""
    echo -e "       Network Reconnaissance Tool v1.0${RESET}"
    echo ""
}


# Section header
print_section() {
    echo ""
    echo -e "${BLUE}${BOLD}========================================${RESET}"
    echo -e "${BLUE}${BOLD}  $1${RESET}"
    echo -e "${BLUE}${BOLD}========================================${RESET}"
}


print_banner
PACKAGES=("curl" "whois" "dig" "nmap")
echo "Detecting package manager......."

if which apt-get &> /dev/null; then
    print_section "Installing dependencies"
    echo "Detected Debian/Ubuntu-based system (apt)."
    sudo apt-get update -y
    sudo apt-get install -y "${PACKAGES[@]}"

elif which dnf &> /dev/null; then
    print_section "Installing dependencies"
    echo "Detected RedHat/Fedora-based system (dnf)."
    sudo dnf install -y "${PACKAGES[@]}"

elif which pacman &> /dev/null; then
    print_section "Installing dependencies"
    echo "Detected Arch-based system (pacman)."
    sudo pacman -Sy --noconfirm "${PACKAGES[@]}"

else 
    print_section "Error"
    echo -e "${RED}[!]we cant install the dependencies "
    echo "install these manualy${RESET}"
    echo "${PACKAGES[@]}"
fi

echo -e "${GREEN}[!] ${RESET}"

rm install.sh
