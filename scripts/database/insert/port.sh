#!/bin/bash

databasePortInsert()
{
    local app_name="$1"
    local port="$2"

    if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
        local table_name=ports
        # Check if already exists in the database
        local existing_portdata=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT port FROM $table_name WHERE name = '$app_name' AND port = '$port';")
        if [ -z "$existing_portdata" ]; then
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (name, port) VALUES ('$app_name', '$port');")
            checkSuccess "Adding port $port for $app_name to the $table_name table."
        fi
    fi
}
