#!/bin/bash

dockerStopApp() 
{
    local app_name="$1"

    if [[ "$app_name" != "" ]]; then
        isNotice "Please wait for docker container(s) to stop"
        local result=$(dockerCommandRun "docker ps -a --format '{{.Names}}' | grep '$app_name' | awk '{print \"docker stop \" \$1}' | sh")
        checkSuccess "Stopping all docker containers with the name $app_name"
    else
        isNotice "No app name provided, unable to stop app."
    fi
}
