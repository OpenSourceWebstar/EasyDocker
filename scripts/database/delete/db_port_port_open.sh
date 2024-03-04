#!/bin/bash

databaseGetOpenPort()
{
    local app_name="$1"
    local port="$2"
    local type="$3"
    local result=$(sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM ports_open WHERE name = '$app_name' AND port = '$port' AND type = '$type';")
    checkSuccess "Removing open port entry for $usedport1/$type of $app_name from the database."
}
