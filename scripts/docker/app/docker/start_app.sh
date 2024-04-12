#!/bin/bash

dockerStartApp()
{
    local app_name="$1"

    if [[ "$app_name" != "" ]]; then
        local container_count=$(docker ps -a | awk -v name="$app_name" '$0 ~ name {count++} END {print count}')

        if [ "$container_count" -gt 0 ]; then
            isNotice "Please wait for docker container(s) to start"

            local result=$(dockerCommandRun "docker ps -a --format '{{.Names}}' | grep '$app_name' | awk '{print \"docker start \" \$1}' | sh")
            checkSuccess "Starting all docker containers with the name $app_name"
        else
            isNotice "No containers found with the name $app_name"
        fi
    else
        isNotice "No app name provided, unable to start app."
    fi
}
