#!/bin/bash

dockerRestartApp() 
{
    local app_name="$1"

    if [[ "$app_name" != "" ]]; then
        isNotice "Please wait for docker container to restart"
        local result=$(dockerCommandRun "docker ps -a --format '{{.Names}}' | grep '$app_name' | awk '{print \"docker restart \" \$1}' | sh")
        checkSuccess "Restarting all docker containers with the name $app_name"
    else
        isNotice "No app name provided, unable to restart app."
    fi
}
