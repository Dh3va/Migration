#! /bin/bash
CWD=$(pwd)
PRE_FAILOVER_SCRIPT_LOCATION="${CWD}"/pre_failover_script_"${VM_NAME}".sh
PATH_JOB=/opt/dbtk/mnt/
PATH_IFCFG="${PATH_JOB}""${JOB_ID}"/etc/sysconfig/network-scripts

INTERFACE=$1
IP=$2
SUB=$3

if [[ ! -f "${PATH_IFCFG}"/ifcfg-"${INTERFACE}" ]]; then
        echo "BOOTPROTO" >> ${PATH_IFCFG}/ifcfg-${INTERFACE}
        echo "sed '/^BOOTPROTO/d' \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE} > \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.new
        {
                echo 'NAME=${INTERFACE}'
                echo 'DEVICE=${INTERFACE}'
                echo 'IPADDR=${IP}'
                echo 'NETMASK=${SUB}'
                echo 'BOOTPROTO=static'
                echo 'USERCTL=no'
                echo 'TYPE=Ethernet'
                echo 'PEERDNS=no'
                echo 'ONBOOT=yes'
                echo 'IPV6INIT=no'
                echo 'NM_CONTROLLED=no'
        } >> \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.new
        cp \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE} \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.ori
        mv \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.new \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}
        rm \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.ori" >> "${PRE_FAILOVER_SCRIPT_LOCATION}"
else
        echo "sed '/^BOOTPROTO/d' \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE} > \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.new
        {
                echo 'NAME=${INTERFACE}'
                echo 'DEVICE=${INTERFACE}'
                echo 'IPADDR=${IP}'
                echo 'NETMASK=${SUB}'
                echo 'BOOTPROTO=static'
                echo 'USERCTL=no'
                echo 'TYPE=Ethernet'
                echo 'PEERDNS=no'
                echo 'IPV6INIT=no'
                echo 'NM_CONTROLLED=no'
        } >> \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.new
        cp \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE} \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.ori
        mv \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.new \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}
        rm \$PATH_TO_JOB_ID\$PATH_TO_IFCFG_FILES/ifcfg-${INTERFACE}.ori" >> "${PRE_FAILOVER_SCRIPT_LOCATION}"
fi