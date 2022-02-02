#! /bin/bash
# Define variables
RED='\033[0;31m'
NC='\033[0m' # No Color
NCC="\e[0m"
CYAN='\e[96m'
USER='custuser'
CWD=$(pwd)

# Checks if the IP exists after the script name
if [ -z "$1" ]; then echo -e "${RED}Where is the IP? Canard!${NC}" && exit 1; fi

echo -e "${CYAN}Starting...${NCC}"

# Stores the output of of 'script' in the variable $RAW_INPUT and if the hostname contains end and the file S95endeca exists removes the symbolic link
RAW_INPUT=$(ssh -o StrictHostKeyChecking=no $USER@"$1"<<'SCRIPT'

# Script
HOSTNAMEVM=$(hostname -s)

NETWORK_INFO=$(ip link | awk -F: ' $0 !~"lo|vir|wl|^[^0-9]" {print $2;getline}')

IP_INFO=$(for i in $NETWORK_INFO; do
    ip link | grep "${i}"| awk -F: ' $0 !~"lo|vir|wl|^[^0-9]" {print $2;getline}' | awk '{ gsub (" ", "", $0); print}'

    if [[ $(ifconfig "${i}" 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://' | wc -c) -ne 0 ]]; then
    ifconfig "${i}" 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://';
    else
    ip addr show "${i}" | grep inet | grep -v inet6 | awk '{print $2}' | awk '{split($0,a,"/"); print a[1]}';
    fi

    if [[ $(ifconfig "${i}" | grep ask | cut -d":" -f4 | wc -c) -ne 0 ]]; then
    ifconfig "${i}" | grep ask | cut -d":" -f4;
    else;
    ifconfig "${i}"| grep -w inet |grep -v 127.0.0.1| awk '{print $4}' | cut -d ":" -f 2;
    fi
done )



echo "${IP_INFO}"
SCRIPT
)

echo "$RAW_INPUT"