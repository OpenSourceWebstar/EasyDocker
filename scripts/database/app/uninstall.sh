#!/bin/bash

databaseUninstallApp() 
{
    local app_name="$1"
    
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

    if [ -z "$app_name" ]; then
        isNotice "App name not provided. Will not continue..."
        return 1
    fi

    # Check if the app exists in the database
    results=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE name = '$app_name'")

    if [ -z "$results" ]; then
        # App not found in the database
        isNotice "$app_name is not installed or not found in the database."
        return 1
    else
        # App found in the database, update status to 0 and set uninstall_date
        isNotice "Uninstalling $app_name..."
        if ! sudo sqlite3 "$docker_dir/$db_file" "UPDATE apps SET status = 0, uninstall_date = '$current_date', uninstall_time = '$current_time' WHERE name = '$app_name';"; then
            isError "Failed to update the database for $app_name."
            return 1
        fi
        isSuccessful "$app_name successfully uninstalled."
    fi
}
