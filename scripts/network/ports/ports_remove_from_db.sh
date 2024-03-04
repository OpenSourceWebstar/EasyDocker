#!/bin/bash

########################
#      Clear Ports     #
########################
portsRemoveFromDatabase()
{
    local app_name="$1"

    local db_used_ports=$(databaseGetUsedPorts "$app_name")
    local db_open_ports=$(databaseGetOpenPorts "$app_name")

    for db_used_port in $db_used_ports; do
        databaseRemoveUsedPort "$app_name" "$db_used_port"
    done

    for db_open_port in $db_open_ports; do
        local port_info=($(echo "$db_open_port" | tr '/' ' ')) # Split port/type info
        local port="${port_info[0]}"
        local type="${port_info[1]}"

        if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
            local result=$(sudo ufw delete allow "$port")
            checkSuccess "Closing port $port for $app_name in the UFW Firewall"
        elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
            local result=$(sudo ufw-docker deny "$app_name" "$port")
            checkSuccess "Closing port $port for $app_name in the UFW-Docker Firewall"
        fi

        # Remove the open port entry from the database
        databaseGetOpenPort "$app_name" "$port" "$type"
    done
}
