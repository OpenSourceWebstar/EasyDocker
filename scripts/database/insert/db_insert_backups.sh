#!/bin/bash

databaseBackupInsert()
{
    local app_name="$1"
    local table_name=backups
    local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
    checkSuccess "Adding $app_name to the $table_name table."    
}
