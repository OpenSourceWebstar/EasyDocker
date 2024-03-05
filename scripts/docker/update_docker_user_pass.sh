#!/bin/bash

updateDockerInstallPassword()
{
    local result=$(echo -e "$CFG_DOCKER_INSTALL_PASS\n$CFG_DOCKER_INSTALL_PASS" | sudo passwd "$CFG_DOCKER_INSTALL_USER" > /dev/null 2>&1)
    checkSuccess "Updating the password for the $CFG_DOCKER_INSTALL_USER user"
}
