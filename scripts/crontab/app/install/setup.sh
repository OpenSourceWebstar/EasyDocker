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

    # Check to see if already instealled
    if ! sudo -u $sudo_user_name crontab -l 2>/dev/null | grep -q "cron is set up for $sudo_user_name"; then
        isError "Crontab is not setup"
        return
    fi

    if [ "$entry_name" = "full" ]; then
        local crontab_entry="$CFG_BACKUP_CRONTAB_FULL cd /docker/install/ && ./start.sh app backup $entry_name"
    else
        local crontab_entry="$CFG_BACKUP_CRONTAB_APP cd /docker/install/ && ./start.sh app backup $entry_name"
    fi

    local apps_comment="# CRONTAB BACKUP APPS"
    local full_comment="# CRONTAB BACKUP FULL"
    local existing_crontab=$(sudo -u $sudo_user_name crontab -l 2>/dev/null)
    

    if ! echo "$existing_crontab" | grep -q "$full_comment"; then
        existing_crontab=$(echo -e "$existing_crontab\n$full_comment")
        checkSuccess "Check if the full comment exists in the crontab"
    fi

    if [ "$entry_name" = "full" ]; then
        existing_crontab=$(echo "$existing_crontab" | sed "/$full_comment/a\\
$crontab_entry")
        checkSuccess "Add the new backup entry to the existing crontab"
    else
        # Check if the apps comment exists in the crontab
        if ! echo "$existing_crontab" | grep -q "$apps_comment"; then
            existing_crontab=$(echo -e "$existing_crontab\n$apps_comment")
            checkSuccess "Insert the full entry after the full comment"
        fi
        existing_crontab=$(echo "$existing_crontab" | sed "/$apps_comment/a\\
$crontab_entry")
        checkSuccess "Insert the non-full entry after the apps comment"
    fi

    local result=$(echo "$existing_crontab" | sudo -u $sudo_user_name crontab -)
    checkSuccess "Set the updated crontab"
    
    crontab_full_value=$(echo "$CFG_BACKUP_CRONTAB_APP" | cut -d' ' -f2)
    if [ "$entry_name" = "full" ]; then
        isSuccessful "$entry_name will be backed up every day at $crontab_full_value:am"
    fi
}
