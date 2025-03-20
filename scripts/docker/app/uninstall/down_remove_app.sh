#!/bin/bash

dockerComposeDownRemove()
{
    local app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "No app_name provided, unable to continue..."
        return
    else
        if [[ "$OS_TYPE" == "Ubuntu" || "$OS_TYPE" == "Debian" ]]; then
            if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                local result=$(dockerCommandRunInstallUser "cd $containers_dir$app_name && docker-compose down -v --rmi all --remove-orphans")
                isNotice "Shutting down & Removing all $app_name container data"
                dockerRemoveApp $app_name;
            elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
                local result=$(cd $containers_dir$app_name && sudo docker-compose down -v --rmi all --remove-orphans)
                isNotice "Shutting down & Removing all $app_name container data"
                dockerRemoveApp $app_name;
            fi
        fi
    fi
}