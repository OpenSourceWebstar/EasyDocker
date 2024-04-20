#!/bin/bash

dockerStartApp()
{
    local app_name="$1"

    if [[ -n "$app_name" ]]; then
        local container_ids=$(dockerCommandRun "docker ps -aqf \"name=$app_name\"")

        if [[ -n "$container_ids" ]]; then
            isNotice "Please wait for docker containers to start"

            # Loop through each container ID to start
            for container_id in $container_ids; do
                local result=$(dockerCommandRun 'docker start $container_id 2>&1')
                checkSuccess "Starting docker container $container_id"
            done
        else
            isNotice "No containers found with the name $app_name"
        fi
    else
        isNotice "No app name provided, unable to start app."
    fi
}
