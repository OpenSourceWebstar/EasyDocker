#!/bin/bash

databasePortOpenInsert()
{
    local app_name="$1"
    local portdata="$2"

    if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
        local table_name=ports_open
        # Split the portdata into port and type
        IFS='/' read -r port type <<< "$portdata"
        # Check if already exists in the database
        local existing_portdata=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT port FROM $table_name WHERE name = '$app_name' AND port = '$port' AND type = '$type';")
        if [ -z "$existing_portdata" ]; then
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (name, port, type) VALUES ('$app_name', '$port', '$type');")
            checkSuccess "Adding port $port and type $type for $app_name to the $table_name table."
        fi
    fi
}
