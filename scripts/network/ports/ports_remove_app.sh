#!/bin/bash

########################
#     Remove Ports     #
########################
portsRemoveApp()
{
    local app_name="$1"

    # Loop through the port variables and log each port
    for i in "${!openports[@]}"; do
        local open_variable_name="openport$((i+1))"
        local open_port_value="${!open_variable_name}"
        if [[ $open_port_value != "" ]]; then
            # Convert to lowercase to avoid bad port issues
            local open_port_value=$(tr '[:upper:]' '[:lower:]' <<< "$open_port_value")
            portClose "$app_name" "$open_port_value" remove
        fi
    done

    # Loop through the port variables and log each port
    for i in "${!usedports[@]}"; do
        local used_variable_name="usedport$((i+1))"
        local used_port_value="${!used_variable_name}"
        if [[ $used_port_value != "" ]]; then
            # Convert to lowercase to avoid bad port issues
            local used_port_value=$(tr '[:upper:]' '[:lower:]' <<< "$used_port_value")
            portUnuse "$app_name" "$used_port_value" remove
        fi
    done

    isNotice "All ports have been removed and closed (if required)."
}
