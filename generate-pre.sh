#! /bin/bash
# Version 1.0
# Last review 27/01/2022
# Author Alessandro

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
RAW_INPUT=$(ssh -o StrictHostKeyChecking=no $USER@"$1" <<'SCRIPT' 

# Setting variables
PATH_ENDECA='/etc/rc3.d'

# Script
HOSTNAMEVM=$(hostname -s)

ENDECA=$(if [[ "${HOSTNAMEVM}" == *end* ]] && [ -L "${PATH_ENDECA}"/S95endeca ]; then
        sudo rm "${PATH_ENDECA}"/S95endeca;
        echo "The Symbolic Link S95endeca has been removed."
fi)

GW=$(/sbin/ip route | awk '/default/ { print $3 }')

INTERFACE1=$(ip link | awk -F: ' $0 !~"lo|vir|wl|^[^1-2]" {print $2;getline}' | awk '{ gsub (" ", "", $0); print}')

IP1=$(ifconfig "${INTERFACE1}" 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://')

SUBNET1=$(/sbin/ifconfig "${INTERFACE1}" | grep Mask | cut -d":" -f4)

INTERFACE2=$(ip link | awk -F: ' $0 !~"lo|vir|wl|^[^3-4]" {print $2;getline}' | awk '{ gsub (" ", "", $0); print}')

IP2=$(ifconfig "${INTERFACE2}" 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://')

SUBNET2=$(/sbin/ifconfig "${INTERFACE2}" | grep Mask | cut -d":" -f4)

echo "Hostname:${HOSTNAMEVM}"
echo "GW:${GW}"
echo "Network-card1:${INTERFACE1}"
echo "${INTERFACE1}_IP1:${IP1}"
echo "SUBNET_1:${SUBNET1}"
echo "Network-card2:${INTERFACE2}"
echo "${INTERFACE2}_IP2:${IP2}"
echo "SUBNET_2:${SUBNET2}"
echo "ENDECA:${ENDECA}"
SCRIPT
)

# Generate the variables for the pre_failover_script parsing the RAW_INPUT variable
VM_NAME=$( echo "${RAW_INPUT}" | awk -F"Hostname:" '/Hostname:/{print $2}')

# Verifies if the executed pre failover script already exists 
if [ -f "${CWD}"/executed_pre_"${VM_NAME}".sh ]; then echo -e "${RED}WARNING${NC}:The pre failover script for${NC} ${CYAN}${VM_NAME}${NC} has been already executed!" && exit 1; fi

JOB_ID=$("${CWD}"/list_jobs.sh | grep "${VM_NAME}" | awk -F"mnt/" '/mnt/{print $2}')

# Checks if a job exists for the vm name
if [ -z "${JOB_ID}" ]; then 
        echo -e "${RED}The job ID for${NC} ${VM_NAME} ${RED}doesn't exist.${NC}";
        exit 1; 
fi

IP_GATEWAY=$(echo "${RAW_INPUT}" | awk -F"GW:" '/GW:/{print $2}')

INTERFACE_1=$( echo "${RAW_INPUT}" | awk -F"card1:" '/card1:/{print $2}')

IP_1=$( echo "${RAW_INPUT}" | awk -F"IP1:" '/IP1:/{print $2}')

SUB_1=$( echo "${RAW_INPUT}" | awk -F"NET_1:" '/NET_1:/{print $2}')

INTERFACE_2=$( echo "${RAW_INPUT}" | awk -F"card2:" '/card2:/{print $2}')

IP_2=$( echo "${RAW_INPUT}" | awk -F"IP2:" '/IP2:/{print $2}')

SUB_2=$( echo "${RAW_INPUT}" | awk -F"NET_2:" '/NET_2:/{print $2}')

# Prints the value of ENDECA in case the Symbolic Link has been removed
ENDECA=$( echo "${RAW_INPUT}" | awk -F"ENDECA:" '/ENDECA:/{print $2}')

# Removing existing pre_failover_script file for the ECL2 instance in current directory
rm -rf "${CWD}"/pre_failover_script_"${VM_NAME}".sh

# Define pre_failover_script variable
PRE_FAILOVER_SCRIPT_LOCATION="${CWD}"/pre_failover_script_${VM_NAME}.sh

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
rm -f \$PATH_TO_JOB_ID\$CLOUD_FINAL_STARTUP_SCRIPT" > "${PRE_FAILOVER_SCRIPT_LOCATION}"
echo "sed '/^BOOTPROTO/d' \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_1} > \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_1}.new
{
        echo 'NAME=${INTERFACE_1}'
        echo 'IPADDR=${IP_1}'
        echo 'NETMASK=${SUB_1}'
        echo 'BOOTPROTO=static'
} >> \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_1}.new
cp \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_1} \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_1}.ori
mv \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_1}.new \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_1}
rm \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_1}.ori" >> "${PRE_FAILOVER_SCRIPT_LOCATION}"
echo "sed '/^BOOTPROTO/d' \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_2} > \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_2}.new
{
        echo 'NAME=${INTERFACE_2}'
        echo 'IPADDR=${IP_2}'
        echo 'NETMASK=${SUB_2}'
        echo 'BOOTPROTO=static'
} >> \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_2}.new
cp \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_2} \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_2}.ori
mv \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_2}.new \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_2}
rm \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE_2}.ori" >> "${PRE_FAILOVER_SCRIPT_LOCATION}"

# Prints ENDECA only if not empty
if [ -n "${ENDECA}" ]; then echo -e "${CYAN}${ENDECA}${NC}"; fi

chmod 755 "${CWD}"/pre_failover_script_"${VM_NAME}".sh

echo -e "${CYAN}done.${NCC}"

echo -e "${CYAN}The Pre Failover Script has been generated for ${VM_NAME}${NCC}."

# Runs the script locally
./pre_failover_script_"${VM_NAME}".sh

echo -e "The script ${CYAN}/pre_failover_script_${VM_NAME}.sh${NCC} has been \e[32mexecuted${NCC} and renamed."

# Renames the script from pre_failover to executed
mv "${CWD}"/pre_failover_script_"${VM_NAME}".sh "${CWD}"/executed_pre_"${VM_NAME}".sh

# Removes execute permission for security reasons
chmod -x "${CWD}"/executed_pre_"${VM_NAME}".sh