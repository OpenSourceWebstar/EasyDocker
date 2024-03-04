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
