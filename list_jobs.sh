#! /bin/bash
PATH_TO_JOBS=/opt/dbtk/mnt
PATH_TO_NETWORK_FILE=/etc/sysconfig/network
PATH_TO_HOSTNAME_FILE=/etc/hostname

for jobs in $PATH_TO_JOBS/.job-*
do
    if [ -z "$(ls -A $PATH_TO_JOBS)" ]; then
        echo "\e[96mNo job found in the directory $PATH_TO_JOBS !\e[0m"
        elif [ -f "$jobs$PATH_TO_HOSTNAME_FILE" ]; then
        VM_NAME=$( cat $jobs$PATH_TO_HOSTNAME_FILE | awk '{print $1}'  )
        echo "$VM_NAME $jobs"
        elif [ -f "$jobs$PATH_TO_NETWORK_FILE" ]; then
        VM_NAME=$( cat $jobs$PATH_TO_NETWORK_FILE | grep HOSTNAME | awk -F "=" '{print $2}'  )
        echo "$VM_NAME $jobs"
    fi
done