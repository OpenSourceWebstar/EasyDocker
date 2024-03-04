#!/bin/bash

databaseCronJobsInsert()
{
    local app_name="$1"
    local table_name=cron_jobs
    local key_in_db=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT COUNT(*) FROM $table_name WHERE name = '$app_name';")

    if [ "$key_in_db" != "" ]; then
        if [ "$key_in_db" -eq 0 ]; then
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
            checkSuccess "Adding $app_name to the $table_name table." 
        else
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "UPDATE $table_name SET name = '$app_name', date = '$current_date', time = '$current_time' WHERE name = '$app_name';")
            checkSuccess "$app_name already added to the $table_name table. Updating date/time." 
        fi
        #isNotice "app_name is empty, unable to insert"
    fi
}
