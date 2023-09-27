#!/bin/bash

local app_name="$1"
local param2="$2"

source scripts/sources.sh

#Used for the backup script to call the function
crontabInitilize()
{
    if [[ "$app_name" == "" ]]; then
        return
    fi

    if [[ "$app_name" == "sshscan" ]]; then
        yes "y" | databaseSSHScanForKeys | tee $logs_dir/$docker_log_file
    fi

    if [[ "$app_name" != "sshscan" ]]; then
        yes "y" | backupInitialize "$app_name" | tee $logs_dir/$backup_log_file
    fi

}

crontabInitilize