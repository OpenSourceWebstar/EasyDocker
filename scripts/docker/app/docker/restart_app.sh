#!/bin/bash

dockerRestartApp() 
{
    local app_name="$1"

    if [[ -z "$app_name" ]]; then
        isNotice "No app name provided. Unable to restart containers."
        return 1
    fi

    isNotice "Restarting Docker containers for '$app_name'. Please wait..."

    # Restart containers in one go
    local result=$(dockerCommandRun "docker ps -aqf name=$app_name | xargs -r docker restart" >/dev/null 2>&1)
    checkSuccess "Restarted Docker containers matching '$app_name'"
}
