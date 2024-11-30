#!/bin/bash

checkBackupCrontabApp() 
{
    local name="$1"
    local config_variable

    # Determine the configuration variable based on the name
    if [[ "$name" == "full" ]]; then
        local config_variable="CFG_BACKUP_FULL"
    else
        local config_variable="CFG_${name^^}_BACKUP"
    fi

    # Check if the configuration variable is set to true
    if [[ -n "${!config_variable}" && "${!config_variable}" == "true" ]]; then
        if ! sudo -u $sudo_user_name crontab -l | grep -q "$name"; then
            echo ""
            echo "##########################################"
            echo "###     Auto Backup setup for $name"
            echo "##########################################"
            echo ""
            isNotice "Automatic Backups for $name are not set up."
            while true; do
                isQuestion "Do you want to set up automatic $name backups (y/n): "
                read -rp "" setupcrontab
                echo ""
                if [[ "$setupcrontab" =~ ^[yYnN]$ ]]; then
                    break
                fi
                isNotice "Please provide a valid input (y/n)."
            done
            if [[ "$setupcrontab" == [yY] ]]; then
                installSetupCrontab $name
                if [[ "$name" != "full" ]]; then
                    databaseCronJobsInsert $name
                    installSetupCrontabTiming $name
                fi
            fi
            if [[ "$setupcrontab" == [nN] ]]; then
                while true; do
                    isQuestion "Do you want to disable automatic $name backups (y/n): "
                    read -rp "" setupdisablecrontab
                    echo ""
                    if [[ "$setupdisablecrontab" =~ ^[yYnN]$ ]]; then
                        break
                    fi
                    isNotice "Please provide a valid input (y/n)."
                done
                if [[ "$setupdisablecrontab" == [yY] ]]; then
                    if [[ "$name" != "full" ]]; then
                        local config_file="$containers_dir$name/$name.config"
                        result=$(sudo sed -i 's/BACKUP=true/BACKUP=false/' $config_file)
                        checkSuccess "Disabled backups in the config for $name"
                        source $config_file
                    elif [[ "$name" == "full" ]]; then
                        result=$(sudo sed -i 's/CFG_BACKUP_FULL=true/CFG_BACKUP_FULL=false/' $configs_dir$config_file_backup)
                        checkSuccess "Disabled $name backups in $config_file_backup."
                        source $config_file
                    fi
                fi
            fi
        fi
    elif [[ -n "${!config_variable}" && "${!config_variable}" == "false" ]]; then
        if sudo -u $sudo_user_name crontab -l | grep -q "$name"; then
            echo ""
            isNotice "Automatic Backups for $name are set up but disabled in the configs."
            while true; do
                isQuestion "Do you want to remove the automatic $name backups (y/n): "
                read -rp "" disablecrontab
                if [[ "$disablecrontab" =~ ^[yYnN]$ ]]; then
                    break
                fi
                isNotice "Please provide a valid input (y/n)."
            done
            if [[ "$disablecrontab" =~ ^[yY]$ ]]; then
                removeBackupCrontabApp $name;
            fi
        fi
    fi

    result=$(crontab -l > ~/my_crontab_backup.txt)
    checkSuccess "Backup the current crontab."
    result=$(crontab -l | grep -v ' >> /docker/logs/backup.log 2>&1' > ~/new_crontab.txt)
    checkSuccess "Remove any lines containing old Crontab data"
    
    if ! cmp -s ~/my_crontab_backup.txt ~/new_crontab.txt; then
        result=$(crontab ~/new_crontab.txt)
        checkSuccess "Crontab entries has been updated."
    else
        isSuccessful "No crontab entries changs needed."
    fi

    result=$(rm ~/new_crontab.txt)
    checkSuccess "Clean up temporary crontab files."
}
