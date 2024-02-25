#!/bin/bash

app_name="$1"
param2="$2"

source init.sh
source scripts/backup.sh
source scripts/functions.sh
source scripts/docker.sh
source scripts/database.sh
source scripts/permissions.sh
source scripts/variables.sh
source scripts/network.sh

sourceScanFiles() 
{
    local load_type="$1"
    local file_pattern

    if [ "$load_type" = "easydocker_configs" ]; then
        local file_pattern="config_*"
        local folder_dir="$configs_dir"
    else
        echo "Invalid load type: $load_type"
        return
    fi

    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            source "$(echo "$file" | sed 's|/docker/install//||')"
            #echo "$load_type FILE $(echo "$file" | sed 's|/docker/install//||')"
        fi
    done < <(sudo find "$folder_dir" -type d \( -name 'resources' \) -prune -o -type f -name "$file_pattern" -print0)
}

#Used for the backup script to call the function
crontabInitilize()
{
    if [[ "$app_name" == "" ]]; then
        return
    fi

    if [[ "$app_name" != "" ]]; then
        yes "y" | backupInitialize "$app_name" | tee $logs_dir/$backup_log_file
    fi

}

sourceScanFiles "easydocker_configs";
crontabInitilize;