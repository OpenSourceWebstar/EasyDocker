#!/bin/bash

databaseGetUsedPorts()
{
    local app_name="$1"
    local used_ports=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT port FROM ports WHERE name = '$app_name';")
    echo "$used_ports"
}
