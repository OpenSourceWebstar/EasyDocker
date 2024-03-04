#!/bin/bash

databasePortUsedDelete()
{
    local app_name="$1"
    local port="$2"

    if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
        local table_name=ports
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM $table_name WHERE name = '$app_name' AND port = '$port';")
        checkSuccess "Deleting port $port for $app_name for the $table_name table."
    fi
}
