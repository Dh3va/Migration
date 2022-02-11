#! /bin/bash
CWD=$(pwd)
PRE_FAILOVER_SCRIPT_LOCATION="${CWD}"/pre_failover_script_${VM_NAME}.sh
PATH_IFCFG="${JOB_ID}"/etc/sysconfig/network-scripts

INTERFACE=$1
IP=$2
SUB=$3

if [[ ! -f "${PATH_IFCFG}"/"${1}"]]; then
        echo "
                echo 'NAME=${INTERFACE}'
                echo 'IPADDR=${IP}'
                echo 'NETMASK=${SUB}'
                echo 'BOOTPROTO=static'
                echo 'DEVICE=${INTERFACE}'
        > \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}" >> ${PRE_FAILOVER_SCRIPT_LOCATION}
        echo "ifcfg-${INTERFACE} did not exist and has been created." 
else
        echo "sed '/^BOOTPROTO/d' \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE} > \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.new
        {
                echo 'NAME=${INTERFACE}'
                echo 'IPADDR=${IP}'
                echo 'NETMASK=${SUB}'
                echo 'BOOTPROTO=static'
        } >> \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.new
        cp \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE} \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.ori
        mv \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.new \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}
        rm \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.ori" >> "${PRE_FAILOVER_SCRIPT_LOCATION}"