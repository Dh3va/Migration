#! /bin/bash
# version 2.3.1
# last review 10/02/2022
# author Dh3va

# Define variables
RED='\033[0;31m'
NC='\033[0m' # No Color
NCC="\e[0m"
CYAN='\e[96m'
GREEN='\e[32m'
USER='custuser'
CWD=$(pwd)
INPUT='/input.sh'
LIST_JOBS='/list_jobs.sh'

# Checks if the IP exists after the script name
if [ -z "$1" ]; then echo -e "${RED}Where is the IP? Canard!${NC}" && exit 1; fi

# Check if input.sh exists in current working directory
if [ ! -e "${CWD}""${INPUT}" ]; then echo -e "${RED}WARNING:${NC} The script ${INPUT} is missing in ${CWD}." && exit 1; fi

# Check if list_jobs.sh exists in current working directory
if [ ! -e "${CWD}""${LIST_JOBS}" ]; then echo -e "${RED}WARNING:${NC} The script ${LIST_JOBS} is missing in ${CWD}." && exit 1; fi

echo -e "${CYAN}Starting script:${NCC}"

# Stores output of 'script' in $RAW_INPUT, also, if hostname contains *end* and Symbolic link S95endeca exist removes Symbolic link
# then prints Hostname GW and all NICs, tests RH6/7 commands to extract IP SUB per NIC
RAW_INPUT=$(
    ssh -o StrictHostKeyChecking=no "${USER}"@"${1}" <<'SCRIPT'

PATH_SL='/etc/rc3.d'

HOSTNAMEVM=$(hostname -s)

ENDECA=$(if [[ "${HOSTNAMEVM}" == *end* ]] && [ -L "${PATH_SL}"/S95endeca ]; then
        sudo rm "${PATH_SL}"/S95endeca;
        echo "The Symbolic Link S95endeca has been removed."
fi)

GW=$(/sbin/ip route | awk '/default/ { print $3 }')

NETWORK_INFO=$(ip link | awk -F: ' $0 !~"lo|vir|wl|^[^0-9]" {print $2;getline}')

for i in ${NETWORK_INFO}; do
    NET=$(ip link | grep "${i}" | awk -F: ' $0 !~"lo|vir|wl|^[^0-9]" {print $2;getline}' | awk '{ gsub (" ", "", $0); print}')
        
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

echo -ne "${CYAN}Collecting VM info: ${NCC}"

if [[ ! -z "${RAW_INPUT}" ]]; then
        sleep 0.5
        echo -e "                         [ ${GREEN}OK${NC} ]"
else
        sleep 0.5
        echo -e "                         [ ${RED}FAIL${NCC} ]"
        exit 1
fi

# Generate variables for pre_failover_script parsing $RAW_INPUT
VM_NAME=$(echo "${RAW_INPUT}" | awk -F"Hostname:" '/Hostname:/{print $2}')

# Prints the value of ENDECA in case the Symbolic Link has been removed
ENDECA=$(echo "${RAW_INPUT}" | awk -F"ENDECA:" '/ENDECA:/{print $2}')

IP_GATEWAY=$(echo "${RAW_INPUT}" | awk -F"GW:" '/GW:/{print $2}')

echo -ne "${CYAN}Check Job ID: ${NCC}"

# If Job exist it uses the script ./list_jobs.sh to get the job id
JOB_ID=$("${CWD}"/list_jobs.sh | grep "${VM_NAME}" | awk -F"mnt/" '/mnt/{print $2}')

# If it doesn't exist exit
if [ -z "${JOB_ID}" ]; then
    sleep 0.5
    echo -e "                               [ ${RED}FAIL${NCC} ]"
    echo -e "${RED}WARNING:${NC} The job ID for ${VM_NAME} doesn't exist."
    exit 1
else
    sleep 0.5
    echo -e "                               [ ${GREEN}OK${NC} ]"
fi

echo -ne "${CYAN}Check if already ran on VM: ${NCC}"

# Verifies if executed pre failover script already exists for vm name
if [ -f "${CWD}"/executed_pre_"${VM_NAME}".sh ]; then 
    sleep 0.5
    echo -e "                 [ ${RED}FAIL${NCC} ]"
    echo -e "${RED}WARNING${NC}:The pre failover script for ${VM_NAME} has been already executed!"
    exit 1 
else
    sleep 0.5
    echo -e "                 [ ${GREEN}OK${NC} ]"
fi

# Removing existing pre_failover_script for vm name in CWD
rm -rf "${CWD}"/pre_failover_script_"${VM_NAME}".sh

# Define pre_failover_script location and name
PRE_FAILOVER_SCRIPT_LOCATION="${CWD}"/pre_failover_script_"${VM_NAME}".sh

# Export the value of both variables into input.sh
export PRE_FAILOVER_SCRIPT_LOCATION
export VM_NAME
./input.sh

echo -ne "${CYAN}Generating ifcfg config: ${NCC}"

# Generate ifcfg-eth* file based on information gathered above
echo "#! /bin/bash
# Generated automatically by pre-failover-generator.sh

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

if [ ! -f ${PRE_FAILOVER_SCRIPT_LOCATION} ]; then 
    sleep 0.5
    echo -e "                    [ ${RED}FAIL${NCC} ]"
    echo -e "${RED}WARNING${NC}:The pre failover script for ${VM_NAME} has not been generated."
    exit 1 
else
    sleep 0.5
    echo -e "                    [ ${GREEN}OK${NC} ]"
fi

# Prints ENDECA only if not empty
if [ -n "${ENDECA}" ]; then echo -e "${CYAN}${ENDECA}${NC}"; fi

chmod 755 "${CWD}"/pre_failover_script_"${VM_NAME}".sh

echo -e "${CYAN}The Pre Failover Script has been generated for ${VM_NAME}${NCC}."

# Runs the script locally
./pre_failover_script_"${VM_NAME}".sh

echo -e "${CYAN}The script /pre_failover_script_${VM_NAME}.sh has been${NCC} ${GREEN}executed${NCC} ${CYAN}and renamed.${NCC}"

# Renames the script from pre_failover to executed
mv "${CWD}"/pre_failover_script_"${VM_NAME}".sh "${CWD}"/executed_pre_"${VM_NAME}".sh

# Removes execute permission for security reasons
chmod -x "${CWD}"/executed_pre_"${VM_NAME}".sh