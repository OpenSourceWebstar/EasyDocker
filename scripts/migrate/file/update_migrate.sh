#!/bin/bash

migrateUpdateFiles()
{            
    local app_name="$1"

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        local result=$(sudo chown -R $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$containers_dir$app_name")
        checkSuccess "Updating ownership on migrated folder $app_name to $CFG_DOCKER_INSTALL_USER"

        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        if [[ $compose_setup == "default" ]]; then
            local compose_file="docker-compose.yml";
        elif [[ $compose_setup == "app" ]]; then
            local compose_file="docker-compose.$app_name.yml";
        fi

        local result=$(sudo sed -i \
            -e "s|- /var/run/docker.sock|- /run/user/${docker_install_user_id}/docker.sock|g" \
            "$compose_file")
        checkSuccess "Updating Compose file for $app_name"
    fi

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        local result=$(sudo sed -i \
            -e "s|- /run/user/${docker_install_user_id}/docker.sock|- /var/run/docker.sock|g" \
            "$compose_file")
        checkSuccess "Updating Compose file for $app_name"
    fi

    fixPermissionsBeforeStart $app_name;
}