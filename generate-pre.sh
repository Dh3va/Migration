#! /bin/bash
# Version 2.0
# Last review 02/02/2022
# Author Alessandro PRANZO aka Dh3va

# Define variables
RED='\033[0;31m'
NC='\033[0m' # No Color
NCC="\e[0m"
CYAN='\e[96m'
USER='custuser'
CWD=$(pwd)

# Checks if the IP exists after the script name
if [ -z "$1" ]; then echo -e "${RED}Where is the IP? Canard!${NC}" && exit 1; fi

echo -e "${CYAN}Starting script...${NCC}"

# Stores output of 'script' in $RAW_INPUT, also, if hostname contains *end* and Symbolic link S95endeca exists removes Symbolic link
# then prints Hostname GW and all NICs, tests RH6/7 commands to extract IP SUB per NIC
RAW_INPUT=$(
    ssh -o StrictHostKeyChecking=no $USER@"$1" <<'SCRIPT'

PATH_ENDECA='/etc/rc3.d'

HOSTNAMEVM=$(hostname -s)

ENDECA=$(if [[ "${HOSTNAMEVM}" == *end* ]] && [ -L "${PATH_ENDECA}"/S95endeca ]; then
        sudo rm "${PATH_ENDECA}"/S95endeca;
        echo "The Symbolic Link S95endeca has been removed."
fi)

GW=$(/sbin/ip route | awk '/default/ { print $3 }')

NETWORK_INFO=$(ip link | awk -F: ' $0 !~"lo|vir|wl|^[^0-9]" {print $2;getline}')

for i in $NETWORK_INFO; do
    NET=$(ip link | grep "${i}"| awk -F: ' $0 !~"lo|vir|wl|^[^0-9]" {print $2;getline}' | awk '{ gsub (" ", "", $0); print}')
        
    RH6_IPADDR=$(ifconfig "${i}" 2>/dev/null|awk '/inet addr:/ {print $2}' | sed 's/addr://' | wc -c)
    RH6_SUB=$(ifconfig "${i}" | grep Mask | cut -d":" -f4 | wc -c)

    if [[ "${RH6_IPADDR}" -ne 0 ]]; then
	    IP=$(ifconfig "${i}" 2>/dev/null | awk '/inet addr:/ {print $2}' | sed 's/addr://')
    else
	    IP=$(ip addr show "${i}" | grep inet | grep -v inet6 | awk '{print $2}' | awk '{split($0,a,"/"); print a[1]}')
    fi
    if [[ "${RH6_SUB}" -ne 0 ]]; then
	    SUB=$(ifconfig "${i}" | grep Mask | cut -d":" -f4)
    else
	    SUB=$(ifconfig "${i}" | grep -w netmask | awk '{print $4}' | sed 's/^.*netmask* //p')
    fi
	echo "Net: ${NET} ${IP} ${SUB}"
done

echo "Hostname:${HOSTNAMEVM}"
echo "ENDECA:${ENDECA}"
echo "GW:${GW}"
SCRIPT
)

# Generate variables for pre_failover_script parsing $RAW_INPUT
VM_NAME=$(echo "${RAW_INPUT}" | awk -F"Hostname:" '/Hostname:/{print $2}')

IP_GATEWAY=$(echo "${RAW_INPUT}" | awk -F"GW:" '/GW:/{print $2}')

# Checks if a job exists for vm name
if [ -z "${JOB_ID}" ]; then
    echo -e "${RED}The job ID for${NC} ${VM_NAME} ${RED}doesn't exist.${NC}"
    exit 1
fi

# If Job exist it uses the script ./list_jobs.sh to get the job id
JOB_ID=$("${CWD}"/list_jobs.sh | grep "${VM_NAME}" | awk -F"mnt/" '/mnt/{print $2}')

# Verifies if executed pre failover script already exists for vm name
if [ -f "${CWD}"/executed_pre_"${VM_NAME}".sh ]; then echo -e "${RED}WARNING${NC}:The pre failover script for${NC} ${CYAN}${VM_NAME}${NC} has been already executed!" && exit 1; fi

# Removing existing pre_failover_script for vm name in CWD
rm -rf "${CWD}"/pre_failover_script_"${VM_NAME}".sh

# Define pre_failover_script location and name
PRE_FAILOVER_SCRIPT_LOCATION="${CWD}"/pre_failover_script_"${VM_NAME}".sh

# Export the value of both variables into input.sh
export PRE_FAILOVER_SCRIPT_LOCATION
export VM_NAME
./input.sh

# Generate ifcfg-eth* file based on information gathered above
echo "#! /bin/bash

PATH_TO_JOB_ID=/opt/dbtk/mnt/${JOB_ID}
PATH_TO_UDEV_NET_RULES_FILES=/etc/udev/rules.d
PATH_TO_GATEWAY_FILE=/etc/sysconfig/network
CLOUD_INIT_LOCAL_STARTUP_SCRIPT=/etc/rc3.d/S50cloud-init-local
CLOUD_INIT_STARTUP_SCRIPT=/etc/rc3.d/S51cloud-init
CLOUD_CONFIG_STARTUP_SCRIPT=/etc/rc3.d/S52cloud-config
CLOUD_FINAL_STARTUP_SCRIPT=/etc/rc3.d/S53cloud-final
PATH_TO_IFCFG_FILES=/etc/sysconfig/network-scripts
rm -f \$PATH_TO_JOB_ID\$PATH_TO_UDEV_NET_RULES_FILES/70-persistent-net.rules*
echo \"GATEWAY=${IP_GATEWAY}\" >> \$PATH_TO_JOB_ID\$PATH_TO_GATEWAY_FILE
rm -f \$PATH_TO_JOB_ID\$CLOUD_INIT_LOCAL_STARTUP_SCRIPT
rm -f \$PATH_TO_JOB_ID\$CLOUD_INIT_STARTUP_SCRIPT
rm -f \$PATH_TO_JOB_ID\$CLOUD_CONFIG_STARTUP_SCRIPT
rm -f \$PATH_TO_JOB_ID\$CLOUD_FINAL_STARTUP_SCRIPT" >"${PRE_FAILOVER_SCRIPT_LOCATION}"

echo "${RAW_INPUT}" | grep -e '^Net:' | sed "s/Net: //g" | xargs -l ./input.sh

# Prints ENDECA only if not empty
if [ -n "${ENDECA}" ]; then echo -e "${CYAN}${ENDECA}${NC}"; fi

chmod 755 "${CWD}"/pre_failover_script_"${VM_NAME}".sh

echo -e "${CYAN}done.${NCC}"

echo -e "${CYAN}The Pre Failover Script has been generated for ${VM_NAME}${NCC}."

# # Runs the script locally
# ./pre_failover_script_"${VM_NAME}".sh

# echo -e "The script ${CYAN}/pre_failover_script_${VM_NAME}.sh${NCC} has been \e[32mexecuted${NCC} and renamed."

# # Renames the script from pre_failover to executed
# mv "${CWD}"/pre_failover_script_"${VM_NAME}".sh "${CWD}"/executed_pre_"${VM_NAME}".sh

# # Removes execute permission for security reasons
# chmod -x "${CWD}"/executed_pre_"${VM_NAME}".sh