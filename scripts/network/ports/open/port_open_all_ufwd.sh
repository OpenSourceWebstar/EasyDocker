#!/bin/bash

portOpenAllUfwdPorts() 
{
     if [[ $CFG_REQUIREMENT_UFWD == "true" ]]; then
        for port_data in "${ufwd_port_array[@]}"; do
            local app_name=$(echo "$port_data" | cut -d ':' -f 1)
            local port_type=$(echo "$port_data" | cut -d ':' -f 2)
            local result=$(sudo ufw-docker allow "$app_name" "$port_type" > /dev/null 2>&1)
            checkSuccess "Opening port $port_type for $app_name in the UFW-Docker Firewall"
        done
    else
        isNotice "UFWD is disabled, no need to open ports. Skipping..."
    fi

    # Clear the array after processing
    ufwd_port_array=()
}
