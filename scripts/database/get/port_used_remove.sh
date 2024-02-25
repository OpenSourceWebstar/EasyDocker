#!/bin/bash

databaseRemoveUsedPort()
{
    local app_name="$1"
    local port="$2"
    local result=$(sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM ports WHERE name = '$app_name' AND port = '$port';")
    checkSuccess "Removing used port entry for $port of $app_name from the database."
}
