#!/bin/bash

migrateUpdateFiles()
{            
    local app_name="$1"
    local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")

    if [[ $compose_setup == "default" ]]; then
        local compose_file="docker-compose.yml";
    elif [[ $compose_setup == "app" ]]; then
        local compose_file="docker-compose.$app_name.yml";
    fi

    local result=$(sudo chown -R $docker_install_user:$docker_install_user "$containers_dir$app_name")
    checkSuccess "Updating ownership on migrated folder $app_name to $docker_install_user"
    
    # Socket updater
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        local result=$(sudo sed -i \
            -e "/#SOCKETHERE/s|.*|      - /run/user/${docker_install_user_id}/docker.sock:/run/user/${docker_install_user_id}/docker.sock:ro #SOCKETHERE|" \
        "$compose_file")
        checkSuccess "Updating docker socket for $app_name"
    elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        local result=$(sudo sed -i \
            -e "/#SOCKETHERE/s|.*|      - /var/run/docker.sock:/var/run/docker.sock:ro #SOCKETHERE|" \
        "$compose_file")
        checkSuccess "Updating docker socket for $app_name"
    fi

    fixPermissionsBeforeStart $app_name;
}