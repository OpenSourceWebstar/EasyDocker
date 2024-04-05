#!/bin/bash

dockerSwitcherScanContainersForSocket() 
{
    local directory="$1"
    local type="$2"
    local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
    local header_sent="false"

    for file in "$directory"/*; do
        if [ -f "$file" ]; then
            if grep -q "#SOCKETHERE" "$file"; then
                if [[ $header_sent == "false" ]]; then
                    echo ""
                    echo "##########################################"
                    echo "###      Docker App Type Switcher      ###"
                    echo "##########################################"
                    echo ""
                    local header_sent="true"
                fi
                isSuccessful "Found Docker socket to change in file: $file"
                if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                    local result=$(sudo sed -i \
                        -e "/#SOCKETHERE/s|.*|      - /run/user/${docker_install_user_id}/docker.sock:/run/user/${docker_install_user_id}/docker.sock:ro #SOCKETHERE|" \
                    "$file")
                    checkSuccess "Updating docker socket for $app_name"
                elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
                    local result=$(sudo sed -i \
                        -e "/#SOCKETHERE/s|.*|      - /var/run/docker.sock:/var/run/docker.sock:ro #SOCKETHERE|" \
                    "$file")
                    checkSuccess "Updating docker socket for $app_name"
                fi
                docker_socket_file_updated="true"
            fi
        fi
    done
}
