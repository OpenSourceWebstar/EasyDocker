#!/bin/bash

dockerStartApp() 
{
    local app_name="$1"

    if [[ "$app_name" != "" ]]; then
        isNotice "Please wait for docker container to start"
        local result=$(dockerCommandRun "docker ps -a --format '{{.Names}}' | grep '$app_name' | awk '{print \"docker start \" \$1}' | sh")
        checkSuccess "Starting all docker containers with the name $app_name"
    else
        isNotice "No app name provided, unable to start app."
    fi
}

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
