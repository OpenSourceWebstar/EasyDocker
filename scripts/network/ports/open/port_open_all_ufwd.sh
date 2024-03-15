#!/bin/bash

portOpenAllUfwdPorts()
{
    local app_name="$1"
    
    for port_data in "${ufwd_port_array[@]}"; do
        local result=$(sudo ufw-docker allow "$app_name" "$port_data")
        checkSuccess "Opening port $port_data for $app_name in the UFW-Docker Firewall"
    done

    # Clear the array after processing
    ufwd_port_array=()
}