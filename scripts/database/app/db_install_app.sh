#!/bin/bash

databaseInstallApp() 
{
    local app_name="$1"

    # Check if sqlite3 is available
    if ! command -v sqlite3 &> /dev/null; then
        isNotice "sqlite3 command not found. Make sure it's installed."
        return 1
    fi

    # Check if the database file exists
    if [ ! -f "$docker_dir/$db_file" ]; then
        isNotice "Database file not found: $docker_dir/$db_file"
        return 1
    fi

    # Check if the app_name is provided
    if [ -z "$app_name" ]; then
        isNotice "App name not provided. Will not continue..."
        return 1
    fi

    # Check if the app exists in the database
    app_exists=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT COUNT(*) FROM apps WHERE name = '$app_name';")

    if [ "$app_exists" -eq 0 ]; then
        isNotice "App does not exist in the database, setting up now."
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO apps (name, status, install_date, install_time) VALUES ('$app_name', '1', '$current_date', '$current_time');")
        checkSuccess "Adding $app_name to the apps database."
        echo ""
    else
        isNotice "App already exists in the database, updating now."
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "UPDATE apps SET status = '1', install_date = '$current_date', install_time = '$current_time', uninstall_date = NULL WHERE name = '$app_name';")
        checkSuccess "Updating apps database for $app_name to installed status."
        echo ""
    fi
}
