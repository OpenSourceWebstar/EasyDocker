#!/bin/bash

databasePortOpenRemove()
{
    local app_name="$1"
    local portdata="$2"

    # Split the portdata into port and type
    IFS='/' read -r port type <<< "$portdata"

    if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
        local table_name=ports_open
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM $table_name WHERE name = '$app_name' AND port = '$port' AND type = '$type';")
        checkSuccess "Deleting port $port and type $type for $app_name for the $table_name table."
    fi
}
