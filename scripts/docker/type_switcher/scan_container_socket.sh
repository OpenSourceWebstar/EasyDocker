#!/bin/bash

dockerSwitcherScanContainersForSocket() 
{
    local directory="$1"
    local type="$2"
    local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
    local header_sent="false"

    for file in "$directory"/*; do
        if [ -f "$file" ]; then
            if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                if grep -q "/var/run/docker.sock" "$file"; then
                    if [[ $header_sent == "false" ]]; then
                        echo ""
                        echo "##########################################"
                        echo "###      Docker App Type Switcher      ###"
                        echo "##########################################"
                        echo ""
                        local header_sent="true"
                    fi
                    isSuccessful "Found Docker socket to change in file: $file"
                    result=$(sudo sed -i -e "s|/var/run/docker.sock|/run/user/${docker_install_user_id}/docker.sock|g" "$file")
                    checkSuccess "Updated socket in file: $file"
                    docker_socket_file_updated="true"
                fi
            elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
                if grep -q "/run/user/${docker_install_user_id}/docker.sock" "$file"; then
                    if [[ $header_sent == "false" ]]; then
                        echo ""
                        echo "##########################################"
                        echo "###      Docker App Type Switcher      ###"
                        echo "##########################################"
                        echo ""
                        local header_sent="true"
                    fi
                    isSuccessful "Found Docker socket to change in file: $file"
                    result=$(sudo sed -i -e "s|/run/user/${docker_install_user_id}/docker.sock|/var/run/docker.sock|g" "$file")
                    checkSuccess "Updated file: $file"
                    docker_socket_file_updated="true"
                fi
            fi
        fi
    done
}
