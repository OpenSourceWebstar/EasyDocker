#!/bin/bash

databaseCycleThroughListAppsCrontab() 
{
    local show_header=$1
    local ISCRON=$( (sudo -u $sudo_user_name crontab -l) 2>&1 )

    # Check to see if installed
    if [[ "$ISCRON" == *"command not found"* ]]; then
        isNotice "Crontab is not found. Unable to set up backups."
        return 1
    fi

    # Check to see if crontab is not installed
    if ! sudo -u $sudo_user_name crontab -l | grep -q "cron is set up for $sudo_user_name" > /dev/null 2>&1; then
        isNotice "Crontab is not set up, skipping until it's found."
        return 1
    fi

    # Check if the database file exists
    if [ ! -f "$docker_dir/$db_file" ]; then
        isNotice "Database file not found: $docker_dir/$db_file"
        return 1
    fi

    if [[ $show_header != "false" ]]; then
        echo ""
        echo "############################################"
        echo "######     Backup Crontab Install     ######"
        echo "############################################"
    fi

    local app_names=("full")  # To Inject full to set up crontab also
    while IFS= read -r name; do
        local app_names+=("$name")
    done < <(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 1;")

    # Check if sqlite3 is available
    if ! command -v sudo sqlite3 &> /dev/null; then
        isNotice "sqlite3 command not found. Make sure it's installed."
        return 1
    fi

    # Remove crontab entries for applications with status = 0 (uninstalled)
    while IFS= read -r name; do
        local uninstalled_apps+=("$name")
    done < <(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 0;")

    for name in "${uninstalled_apps[@]}"; do
        removeBackupCrontabAppFolderRemoved $name
    done

    # Setup crontab entries for installed applications
    for name in "${app_names[@]}"; do
        checkBackupCrontabApp $name
    done

    echo ""
    crontabClean;
    isSuccessful "Setting up Crontab backups for application(s) completed."
}

