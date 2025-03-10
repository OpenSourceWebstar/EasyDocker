#!/bin/bash

portClose()
{
    local app_name="$1" # $app_name if ufw-docker, number if ufw
    local portdata="$2" # port/type if ufw-docker, empty if ufw
    local flag="$3"

    if [[ $portdata != "" ]]; then
        if [[ $flag == "stale" ]]; then
            isNotice "Old stale port $port found for $app_name and is now being closed."
        fi
        IFS='/' read -r port type <<< "$portdata"
        # Check if the port already exists in the database
        if portOpenExistsInDatabase "$app_name" "$port" "$type" "$flag"; then
            if [[ $disallow_open_port == "false" ]]; then
                databasePortOpenDelete "$app_name" "$portdata"
                if [[ $app_name == "standalonewireguard" ]]; then
                    if [[ $CFG_REQUIREMENT_UFW == "true" ]]; then
                        local result=$(sudo ufw delete allow "$port/$type")
                        checkSuccess "Closing port $port and type $type for $app_name in the UFW Firewall"
                    else
                        isNotice "UFW is not enabled, skipping..."
                    fi
                elif [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                    if [[ $CFG_REQUIREMENT_UFW == "true" ]]; then
                        local result=$(sudo ufw delete allow "$port/$type")
                    else
                        isNotice "UFW is not enabled, skipping..."
                    fi
                    checkSuccess "Closing port $port and type $type for $app_name in the UFW Firewall"
                elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
                    if [[ $CFG_REQUIREMENT_UFWD == "true" ]]; then
                        local result=$(sudo ufw-docker delete allow "$app_name" "$port/$type" > /dev/null 2>&1)
                        checkSuccess "Closing port $port and type $type for $app_name in the UFW-Docker Firewall"
                    else
                        isNotice "UFW-Docker is not enabled, skipping..."
                    fi
                fi
            fi
        fi
    fi
}
