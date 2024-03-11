#!/bin/bash

databaseCycleThroughListApps()
{
    local name=$1
    # Protection from running in start script
    if [[ "$backupsingle" == [yY] ]] || [[ "$backupfull" == [yY] ]] || [[ "$migratesingle" == [yY] ]] || [[ "$migratefull" == [yY] ]]; then

        # Full
        # Backup
        if [[ "$backupfull" == [yY] ]]; then
            local name=full
            isQuestion "Do you want to backup : $name? (y/n) "
            read -rp "" BACKUPACCEPT

            if [[ $BACKUPACCEPT == [yY] ]]; then
                isNotice "Starting a $name backup."
                backupStart $name;
            fi
        fi

        # Migrate
        if [[ "$migratefull" == [yY] ]]; then
            local name=full
            isQuestion "Do you want to migrate $name? (y/n)? "
            read -rp "" MIGRATEACCEPT

            if [[ $MIGRATEACCEPT == [yY] ]]; then
                isNotice "Starting a $name migrate."
                migrateStart $name;
            fi
        fi

        # This is for single apps ONLY    
        local app_names=()
        while IFS= read -r name; do
            local app_names+=("$name")
        done < <(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 1;")

        # Check if sqlite3 is available
        if ! command -v sudo sqlite3 &> /dev/null; then
            isNotice "sqlite3 command not found. Make sure it's installed."
            return 1
        fi

        # Check if the database file exists
        if [ ! -f "$docker_dir/$db_file" ]; then
            isNotice "Database file not found: $docker_dir/$db_file"
            return 1
        fi

        # Backup
        if [[ "$backupsingle" == [yY] ]]; then
            for name in "${app_names[@]}"; do
                isQuestion "Do you want to backup $name? (y/n) "
                read -rp "" BACKUPACCEPT

                if [[ $BACKUPACCEPT == [yY] ]]; then
                    isNotice "Starting a $name backup."
                    backupStart $name;
                fi
            done
        fi

        # Migrate
        if [[ "$migratesingle" == [yY] ]]; then
            for name in "${app_names[@]}"; do
                isQuestion "Do you want to migrate $name? (y/n)? "
                read -rp "" MIGRATEACCEPT


                if [[ $MIGRATEACCEPT == [yY] ]]; then
                    isNotice "Starting a $name migration."
                    migrateStart $name;
                fi
            done
        fi

	fi
}
