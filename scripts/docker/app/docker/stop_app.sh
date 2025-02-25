#!/bin/bash

dockerStopApp() 
{
    local app_name="$1"

    if [[ -z "$app_name" ]]; then
        isNotice "No app name provided. Unable to stop containers."
        return 1
    fi

    isNotice "Stopping Docker containers for '$app_name'. Please wait..."

    # Stop containers in one go
    local result=$(dockerCommandRun "docker ps -aq --filter name=${app_name} | xargs -r docker stop" >/dev/null 2>&1)
    checkSuccess "Stopped Docker containers matching '$app_name'"

}
