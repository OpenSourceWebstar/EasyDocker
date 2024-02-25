#!/bin/bash

databasePathInsert()
{
    local initial_path_save="$1"
    if [ -f "$docker_dir/$db_file" ] && [ -n "$initial_path_save" ]; then
        local table_name=path
        # Check if the path already exists in the database
        local existing_path=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT path FROM $table_name WHERE path = '$initial_path_save';")
        if [ -z "$existing_path" ]; then
            # Path doesn't exist, clear old data and insert
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM $table_name;")
            checkSuccess "Clearing old path data"
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (path) VALUES ('$initial_path_save');")
            checkSuccess "Adding $initial_path_save to the $table_name table."
        fi
    fi
}
