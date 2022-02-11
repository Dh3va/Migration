#! /bin/bash
# Version 2.1
# Last review 09/02/2022
# Author Sam and Alessandro

# Define variables
RED='\033[0;31m'
NC='\033[0m' # No Color
USER='custuser'

# Checks if the IP exists after the script name
if [ -z "$1" ]; then echo -e "${RED}Where is the IP? Canard!${NC}" && exit 1; fi

ssh -o StrictHostKeyChecking=no "$USER"@"$1" <<'SCRIPT'
PATH_SL='/etc/rc3.d'
HOSTNAME="$(hostname -s)"
NC="\e[0m"
CYAN='\e[96m'

if [[ "${HOSTNAME}" == *end* ]] && [ ! -L "${PATH_SL}"/S95nginx ]; then
        sudo ln -s /etc/init.d/endeca /etc/rc3.d/S95endeca
        echo -e "${CYAN}The Symbolic Link S95endeca has been re-created.${NC}"
fi

# Install VMWare Tools on the target instance
sudo yum install open-vm-tools -y

# Remove Cloud Init package
CLOUD_INIT_RPM=$(sudo rpm -aq | grep cloud-init)
if [ -n "${CLOUD_INIT_RPM}" ]; then
        sudo rpm -e "$CLOUD_INIT_RPM"
fi

# Remove DoubleTake (Carbonite) package
DOUBLETAKE_RPM=$(sudo rpm -aq | grep DoubleTake)
if [ -n "${DOUBLETAKE_RPM}" ]; then 
        sudo rpm -e "$DOUBLETAKE_RPM"
fi

# Reboot the target instance to check network service is working properly
sudo reboot
SCRIPT