#!/bin/bash

dockerStartAllApps()
{
    isNotice "Please wait for docker containers to start"
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        local result=$(dockerCommandRunInstallUser 'docker restart $(docker ps -a -q)')
        checkSuccess "Starting up all docker containers"
    elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        local result=$(sudo docker restart $(docker ps -a -q))
        checkSuccess "Starting up all docker containers"
    fi
}
