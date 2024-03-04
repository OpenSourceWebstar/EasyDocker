#!/bin/bash

dockerCheckAppInstalled() 
{
    local app_name="$1"
    local flag="$2"
    local check_active="$3"
    local package_status=""

    if [ "$flag" = "linux" ]; then
        if dpkg -l | grep -q "$app_name"; then
            package_status="installed"
            if [ "$check_active" = "check_active" ]; then
                if systemctl is-active --quiet "$app_name"; then
                    package_status="running"
                fi
            fi
        else
            package_status="not_installed"
        fi
    elif [ "$flag" = "docker" ]; then
        if [ -f "$docker_dir/$db_file" ]; then
            results=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 1 AND name = '$app_name';")
        fi 
        if [ -n "$results" ]; then
            package_status="installed"
        else
            package_status="not_installed"
        fi
    else
        package_status="invalid_flag"
    fi

    echo "$package_status"
}
