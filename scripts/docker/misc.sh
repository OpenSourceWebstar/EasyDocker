#!/bin/bash

# Unused at the moment
dockerScanForShouldRestart()
{
    for i in "${appstorestart[@]}"; do
        if [ "$i" -eq 3 ]; then
            unset appstorestart[$i]
            appstorestart=("${appstorestart[@]}") # Re-index the array
            i=$((i-1)) # Decrement the loop counter
        fi
        dockerInstallApp "$i"
    done
}

dockerPruneNetworks()
{
    local result=$(dockerCommandRun "docker network prune -f --filter \"name!=vpn\"")
    checkSuccess "Pruning unused Docker networks (excluding vpn)"
}

dockerSetupEnvFile()
{
    local result=$(copyFile "loud" $containers_dir$app_name/env.example $containers_dir$app_name/.env $CFG_DOCKER_INSTALL_USER)
    checkSuccess "Setting up .env file to path"
}
