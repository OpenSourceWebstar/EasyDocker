#!/bin/bash

portOpenAllUfwdPorts() 
{
    for port_data in "${ufwd_port_array[@]}"; do
        local app_name=$(echo "$port_data" | cut -d ':' -f 1)
        local port_type=$(echo "$port_data" | cut -d ':' -f 2)
        local result=$(sudo ufw-docker allow "$app_name" "$port_type")
        checkSuccess "Opening port $port_type for $app_name in the UFW-Docker Firewall"
    done

    # Clear the array after processing
    ufwd_port_array=()
}
