#!/bin/bash

dockerRemoveApp() 
{
    local app_name="$1"

    if [[ -z "$app_name" ]]; then
        isNotice "No app name provided. Unable to stop and remove containers."
        return 1
    fi

    isNotice "Stopping and removing Docker containers for '$app_name'. Please wait..."

    # Stop and remove containers in one go
    dockerCommandRun "docker ps -aqf name=$app_name | xargs -r docker stop" >/dev/null 2>&1
    checkSuccess "Stopped Docker containers matching '$app_name'"

    dockerCommandRun "docker ps -aqf name=$app_name | xargs -r docker rm" >/dev/null 2>&1
    checkSuccess "Removed Docker containers matching '$app_name'"
}
