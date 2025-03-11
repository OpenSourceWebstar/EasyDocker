#!/bin/bash

getStoredPassword() 
{
    local app_name="$1"
    local variable_name="$2"
    local log_file="$containers_dir/bcrypt.txt"

    if [ -f "$log_file" ]; then
        grep "^$app_name $variable_name " "$log_file" | awk '{print $3}' | tail -n 1
    else
        echo ""
    fi
}