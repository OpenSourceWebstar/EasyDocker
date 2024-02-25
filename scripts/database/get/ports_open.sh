#!/bin/bash

databaseGetOpenPorts()
{
    local app_name="$1"
    local ports_open=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT port || '/' || type FROM ports_open WHERE name = '$app_name';")
    echo "$ports_open"
}
