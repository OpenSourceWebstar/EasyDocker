#!/bin/bash

removeBackupCrontabAppFolderRemoved() 
{
    local name="$1"

    # Check if the crontab entry exists for the specified application
    if sudo -u $sudo_user_name crontab -l | grep -q "$name"; then
        echo ""
        isNotice "Application $name is no longer installed."
        while true; do
            isQuestion "Do you want to remove automatic backups for $name (y/n): "
            read -rp "" removecrontab
            if [[ "$removecrontab" =~ ^[yYnN]$ ]]; then
                break
            fi
            isNotice "Please provide a valid input (y/n)."
        done
        if [[ "$removecrontab" =~ ^[yY]$ ]]; then
            removeBackupCrontabApp $name;
        fi
    fi
}
