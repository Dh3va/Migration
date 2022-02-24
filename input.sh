#! /bin/bash
# version 3.1
# last review 21/02/2022

INTERFACE=$1
IP=$2
SUB=$3
RED='\033[0;31m'
NC='\033[0m' # No Color
NCC="\e[0m"
CYAN='\e[96m'
GREEN='\e[32m'

PATH_JOB_IFCFG=/opt/dbtk/mnt/"${JOB_ID}"/etc/sysconfig/network-scripts
INT_INFO="${PATH_JOB_IFCFG}"/ifcfg-"${INTERFACE}"

# Checks if the interface exists, if it doesn't, it creates the interface with the right informations
if [ ! -f "${INT_INFO}" ]; then
        echo -e "NAME=${INTERFACE}\nDEVICE=${INTERFACE}\nONBOOT=yes\nBOOTPROTO=static\nTYPE=Ethernet\nIPADDR=${IP}\nNETMASK=${SUB}\nUSERCTL=no\nPEERDNS=no\nIPV6INIT=no\nNM_CONTROLLED=no" >> "${PATH_JOB_IFCFG}"/ifcfg-"${INTERFACE}"
        echo -e "${CYAN}Creating ifcfg-${INTERFACE}${NCC}:                         [ ${GREEN}OK${NC} ]"
fi

# If the interface already exists, performs a grep to check if it contains "dhcp", if it does it will remove the old interface and replace it with the new one
if grep -q dhcp "${INT_INFO}"; then
        rm -f "${PATH_JOB_IFCFG}"/ifcfg-"${INTERFACE}"
        echo -e "NAME=${INTERFACE}\nDEVICE=${INTERFACE}\nONBOOT=yes\nBOOTPROTO=static\nTYPE=Ethernet\nIPADDR=${IP}\nNETMASK=${SUB}\nUSERCTL=no\nPEERDNS=no\nIPV6INIT=no\nNM_CONTROLLED=no" >> "${PATH_JOB_IFCFG}"/ifcfg-"${INTERFACE}"
        echo -e "${CYAN}Re-creating ifcfg-${INTERFACE}${NCC}:                      [ ${GREEN}OK${NC} ]"
fi