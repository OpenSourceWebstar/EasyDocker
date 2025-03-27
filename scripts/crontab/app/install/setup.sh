#!/bin/bash

# Function to set up the backup entry in crontab
installSetupCrontab() 
{
    local entry_name="$1"

    echo ""
    echo "#####################################"
    echo "###   Adding $entry_name to Crontab"
    echo "#####################################"
    echo ""

    # Check to see if already installed
    if ! sudo -u $sudo_user_name crontab -l 2>/dev/null | grep -q "cron is set up for $sudo_user_name"; then
        isError "Crontab is not setup"
        return
    fi

    local crontab_entry="$CFG_BACKUP_CRONTAB_APP cd /docker/install/ && ./start.sh app backup $entry_name"
    local apps_comment="# CRONTAB BACKUP APPS"
    local existing_crontab=$(sudo -u $sudo_user_name crontab -l 2>/dev/null)
    
    # Check if the apps comment exists in the crontab
    if ! echo "$existing_crontab" | grep -q "$apps_comment"; then
        existing_crontab=$(echo -e "$existing_crontab\n$apps_comment")
        checkSuccess "Insert the apps comment"
    fi
    existing_crontab=$(echo "$existing_crontab" | sed "/$apps_comment/a\\
$crontab_entry")
    checkSuccess "Insert the entry after the apps comment"

    local result=$(echo "$existing_crontab" | sudo -u $sudo_user_name crontab -)
    checkSuccess "Set the updated crontab"
    
    crontab_value=$(echo "$CFG_BACKUP_CRONTAB_APP" | cut -d' ' -f2)
    isSuccessful "$entry_name will be backed up every day at $crontab_value:am"
}
