#!/bin/bash

databaseGetOpenPortsForApp() 
{
    local app_name="$1"
    local ports_open=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT port FROM ports_open WHERE name = '$app_name';")
    local db_ports_open=()
    IFS=$'\n' read -r -a db_ports_open <<< "$ports_open"
    echo "${db_ports_open[@]}"
}
