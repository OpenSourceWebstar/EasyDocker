#!/bin/bash

# Function to check if a port and type combination already exists in the database
portExistsInDatabase()
{
    local app_name="$1"
    local port="$2"
    local type="$3"

    if [ -f "$base_dir/$db_file" ] && [ -n "$app_name" ]; then
        table_name=ports
        existing_portdata=$(sudo sqlite3 "$base_dir/$db_file" "SELECT port FROM $table_name WHERE port = '$port' AND type = '$type';")
        if [ -n "$existing_portdata" ]; then
            return 0  # Port exists in the database
        fi
    fi
    return 1  # Port does not exist in the database
}

openPort()
{
    local app_name="$1" # $app_name if ufw-docker, number if ufw
    local portdata="$2" # port/type if ufw-docker, empty if ufw

    IFS='/' read -r port type <<< "$portdata"

    # Check if the port already exists in the database
    if portExistsInDatabase "$app_name" "$port" "$type"; then
        isNotice "Port $port and type $type already opened."
        return
    fi

    # If the port doesn't exist in the database, continue with inserting and configuring
    databasePortInsert "$app_name" "$portdata"

    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        result=$(sudo ufw allow "$port")
        checkSuccess "Opening port $port for $app_name in the UFW Firewall"
    elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        result=$(sudo ufw-docker allow "$app_name" "$port")
        checkSuccess "Opening port $port for $$app_name in the UFW-Docker Firewall"
    fi
}