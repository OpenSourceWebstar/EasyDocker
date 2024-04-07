#!/bin/bash

dockerPruneAppNetworks() 
{
    if [[ $CFG_REQUIREMENT_DOCKER_NETWORK_PRUNE == "true" ]]; then
        local app_name="$1"
        if [ ! -z "$app_name" ]; then
            # Prune all networks except those containing the specified app_name
            for network_id in $(docker network ls --quiet); do
                network_name=$(docker network inspect --format '{{.Name}}' "$network_id")
                if [[ "$network_name" == *"$app_name"* ]]; then
                    local result=$(dockerCommandRun "docker network rm "$network_id"")
                    checkSuccess "Removing the unused docker network - $network_name"
                fi
            done
        fi
    fi
}
