#!/bin/bash

dockerServiceStop()
{
    local type="$1"

    if [[ "$type" == "rooted" ]]; then
        if [[ "$docker_rooted_found" == "true" ]]; then
            isNotice "Stopping rooted Docker service...this may take a moment..."
        
            local result=$(sudo systemctl stop docker)
            checkSuccess "Stopping Rooted Docker Service"
            
            local result=$(sudo systemctl disable docker)
            checkSuccess "Disabling Rooted Docker Service"
        fi
    fi

    if [[ "$type" == "rootless" ]]; then
        if [[ "$docker_rootless_found" == "true" ]]; then
            isNotice "Uninstalling rootless Docker service...this may take a moment..."
            uninstallDockerRootless;
        fi
    fi

}