#!/bin/bash

dockerServiceStart()
{
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        local result=$(sudo systemctl start docker)
        checkSuccess "Starting Docker Service"

        local result=$(sudo systemctl enable docker)
        checkSuccess "Enabling Docker Service"

        local result=$(sudo usermod -aG docker $sudo_user_name)
        checkSuccess "Adding user to 'docker' group"

        local result=$(sudo newgrp docker)
        checkSuccess "Reloading docker group for $sudo_user_name"
    elif [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        installDockerRootless;
    fi
}
