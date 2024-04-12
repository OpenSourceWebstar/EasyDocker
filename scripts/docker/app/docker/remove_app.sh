#!/bin/bash

dockerRemoveApp() 
{
    local app_name="$1"

    if [[ "$app_name" != "" ]]; then
        local container_count=$(docker ps -a | awk -v name="$app_name" '$0 ~ name {count++} END {print count}')

        if [ "$container_count" -gt 0 ]; then
            isNotice "Additional containers found, Please wait for docker containers to stop and be removed"

            local result=$(dockerCommandRun "docker ps -a --format '{{.Names}}' | grep '$app_name' | awk '{print \"docker stop \" \$1}' | sh")
            checkSuccess "Stopping all docker containers with the name $app_name"

            local result=$(dockerCommandRun "docker ps -a --format '{{.Names}}' | grep '$app_name' | awk '{print \"docker rm \" \$1}' | sh")
            checkSuccess "Removing all docker containers with the name $app_name"
        else
            isNotice "No containers found with the name $app_name"
        fi
    else
        isNotice "No app name provided, unable to stop app."
    fi
}

