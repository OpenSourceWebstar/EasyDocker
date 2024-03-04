#!/bin/bash

databaseGetUsedPortsForApp() 
{
    local app_name="$1"
    local used_ports=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT port FROM ports WHERE name = '$app_name';")
    local db_ports=()
    IFS=$'\n' read -r -a db_ports <<< "$used_ports"
    echo "${db_ports[@]}"
}