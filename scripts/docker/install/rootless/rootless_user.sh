#!/bin/bash

installDockerRootlessUser()
{   
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        if id "$CFG_DOCKER_INSTALL_USER" &>/dev/null; then
            isSuccessful "User $CFG_DOCKER_INSTALL_USER already exists."
        else
            # If the user doesn't exist, create the user
            local result=$(sudo useradd -s /bin/bash -d "/home/$CFG_DOCKER_INSTALL_USER")
            checkSuccess "Creating $CFG_DOCKER_INSTALL_USER User."
            updateDockerInstallPassword;
        fi
    fi
}
