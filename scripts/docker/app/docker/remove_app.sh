#!/bin/bash

dockerRemoveApp() 
{
    local app_name="$1"

    if [[ -n "$app_name" ]]; then
        local container_ids=$(docker ps -aqf "name=$app_name")

        if [[ -n "$container_ids" ]]; then
            isNotice "Additional containers found. Please wait for docker containers to stop and be removed."

            # Loop through each container ID
            for container_id in $container_ids; do
                local result=$(docker stop $container_id 2>&1)
                checkSuccess "Stopping docker container $container_id"

                local result=$(docker rm $container_id 2>&1)
                checkSuccess "Removing docker container $container_id"
            done
        else
            isNotice "No containers found with the name $app_name"
        fi
    else
        isNotice "No app name provided, unable to stop app."
    fi
}
