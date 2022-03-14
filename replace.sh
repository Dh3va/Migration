#! /bin/bash

USER='custuser'
RED='\033[0;31m'
NC='\033[0m' # No Color

if [ -z "$1" ]; then echo -e "${RED}Where is the IP? Canard!${NC}" && exit 1; fi

ssh -o StrictHostKeyChecking=no "$USER"@"$1" <<'SCRIPT'

PATH_SRO=/usr/share/DT
PATH_DT=/etc/init.d/DT
CYAN='\e[96m'
NC='\e[0m'

[ -f ${PATH_SRO}/SRO.repset ] || exit 1

echo -e "${CYAN}SRO.repset is present.${NC}"

cd "${PATH_SRO}"

sudo mv SRO.repset SRO.repset.bak

echo -e "${CYAN}SRO.repset has been backed up and changed as follows:${NC}"

echo "# SRO Repset Rule specifications
# INCLUDES must precede EXCLUDES
# Usage:
# INCLUDE <path>
# INCLUDE_RECURSIVE <path>
# INCLUDE_CLASS <MOUNTS>
# INCLUDE_CLASS_RECURSIVE <MOUNTS>
# EXCLUDE <path>
# EXCLUDE_RECURSIVE <path>
# EXCLUDE_CLASS <REMOTE|INCOMPATIBLE|DT_FILES>
# EXCLUDE_CLASS_RECURSIVE <REMOTE|INCOMPATIBLE|DT_FILES>
INCLUDE_CLASS_RECURSIVE MOUNTS
INCLUDE_RECURSIVE /var/log
INCLUDE_RECURSIVE /var/cache
INCLUDE_RECURSIVE /var/run
INCLUDE_RECURSIVE /run
EXCLUDE /etc/mtab
EXCLUDE_RECURSIVE /dev
EXCLUDE_RECURSIVE /tmp
#EXCLUDE_RECURSIVE /var/log
EXCLUDE_RECURSIVE /var/lock
#EXCLUDE_RECURSIVE /var/run
#EXCLUDE_RECURSIVE /var/cache
EXCLUDE_RECURSIVE /var/tmp
EXCLUDE_RECURSIVE /var/crash
EXCLUDE_RECURSIVE /media
EXCLUDE_CLASS_RECURSIVE REMOTE
EXCLUDE_CLASS_RECURSIVE INCOMPATIBLE
EXCLUDE_CLASS_RECURSIVE DT_FILES" > /tmp/SRO-config

sudo mv /tmp/SRO-config "${PATH_SRO}/SRO.repset"

sudo cat SRO.repset

echo -e "${CYAN}Restarting DT...${NC}"

sudo ${PATH_DT} restart

echo -e "${CYAN}done.${NC}"
SCRIPT