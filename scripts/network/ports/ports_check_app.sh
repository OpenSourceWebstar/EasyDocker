#!/bin/bash

########################
#       Add Ports      #
########################
portsCheckApp()
{
    local app_name="$1"
    local flag="$2"

    for i in "${!usedports[@]}"; do
        local used_variable_name="usedport$((i+1))"
        local used_port_value="${!used_variable_name}"
        if [[ $used_port_value != "" ]]; then
            # Convert to lowercase to avoid bad port issues
            local used_port_value=$(tr '[:upper:]' '[:lower:]' <<< "$used_port_value")
            portUse "$app_name" "$used_port_value" "$flag"
        fi
    done

    for i in "${!openports[@]}"; do
        local open_variable_name="openport$((i+1))"
        local open_port_value="${!open_variable_name}"
        if [[ $open_port_value != "" ]]; then
            # Convert to lowercase to avoid bad port issues
            local open_port_value=$(tr '[:upper:]' '[:lower:]' <<< "$open_port_value")
            portOpen "$app_name" "$open_port_value" "$flag"
        fi
    done

    portsRemoveStale "$app_name";
}
