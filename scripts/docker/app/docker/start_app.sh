#!/bin/bash

dockerStartApp() 
{
    local app_name="$1"

    if [[ -z "$app_name" ]]; then
        isNotice "No app name provided. Unable to start containers."
        return 1
    fi

    isNotice "Starting Docker containers for '$app_name'. Please wait..."

    # Start containers in one go
    local result=$(dockerCommandRun "docker ps -aqf name=$app_name | xargs -r docker start" >/dev/null 2>&1)
    checkSuccess "Started Docker containers matching '$app_name'"
}
