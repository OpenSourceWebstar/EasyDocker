#!/bin/bash

databaseSSHInsert()
{
    local app_name="$1"
    local table_name=ssh
    local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (ip, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
    checkSuccess "Adding $app_name to the $table_name table." 
}
