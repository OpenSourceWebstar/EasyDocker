#!/bin/bash

removeBackupCrontabApp()
{
    local name="$1"
    # Remove the crontab entry for the specified application
    sudo -u $sudo_user_name crontab -l | grep -v "$name" | sudo -u $sudo_user_name crontab -
    isSuccessful "Automatic backups for $name have been removed."
}
