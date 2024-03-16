#!/bin/bash

portOpen()
{
    local app_name="$1" # $app_name if ufw-docker, number if ufw
    local portdata="$2" # port/type if ufw-docker, empty if ufw
    local flag="$3"

    if [[ $portdata != "" ]]; then
        IFS='/' read -r port type <<< "$portdata"

        # Check if the port already exists in the database
        if ! portOpenExistsInDatabase "$app_name" "$port" "$type" "$flag"; then
            if [[ $disallow_open_port == "false" ]]; then
                databasePortOpenInsert "$app_name" "$portdata"
                if [[ $app_name == "standalonewireguard" ]]; then
                    local result=$(sudo ufw allow "$port/$type")
                    checkSuccess "Opening port $port and type $type for $app_name in the UFW Firewall"
                elif [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                    local result=$(sudo ufw allow "$port/$type")
                    checkSuccess "Opening port $port and type $type for $app_name in the UFW Firewall"
                elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
                    isSuccessful "Adding port $port/$type to be opened in the UFW-Docker Firewall after install."
                    portOpenUfwd "$app_name" "$port" "$type"
                fi
            fi
        fi
    fi
}
