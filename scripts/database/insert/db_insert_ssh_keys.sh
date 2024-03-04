#!/bin/bash

databaseSSHKeysInsert()
{
    local key_filename="$1"
    local key_file=$(basename "$key_filename")
    local table_name=ssh_keys
    local key_in_db=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT COUNT(*) FROM $table_name WHERE name = '$key_file';")

    if [ "$key_in_db" -eq 0 ]; then
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$key_file', '$current_date', '$current_time');")
        checkSuccess "Adding $key_file to the $table_name table."
    else
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "UPDATE $table_name SET name = '$key_file', date = '$current_date', time = '$current_time' WHERE name = '$key_file';")
        checkSuccess "$key_file already added to the $table_name table. Updating date/time."
    fi
}
