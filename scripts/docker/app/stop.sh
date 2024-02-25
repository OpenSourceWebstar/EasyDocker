#!/bin/bash

dockerStopApp() 
{
    local app_name="$1"

    if [[ "$app_name" != "" ]]; then
        isNotice "Please wait for docker container to stop"
        local result=$(dockerCommandRun "docker ps -a --format '{{.Names}}' | grep '$app_name' | awk '{print \"docker stop \" \$1}' | sh")
        checkSuccess "Stopping all docker containers with the name $app_name"
    else
        isNotice "No app name provided, unable to stop app."
    fi
}

dockerStopAllApps()
{
    local type="$1"

    isNotice "Please wait for docker containers to stop"
    
    if [[ $type == "rootless" ]]; then
        local result=$(dockerCommandRunInstallUser 'docker ps -q 2>/dev/null')
        if [[ -n "$result" ]]; then
            local result=$(dockerCommandRunInstallUser 'docker stop $(docker ps -a -q)')
            checkSuccess "Stopping all docker containers (Rootless if installed)"
        fi
    fi

    if [[ $type == "rooted" ]]; then
        local result=$(sudo docker ps -q 2>/dev/null)
        if [[ -n "$result" ]]; then
            local result=$(sudo docker stop $(docker ps -a -q))
            checkSuccess "Stopping all docker containers (Rooted if installed)"
        fi
    fi
}
