#!/bin/bash

dockerStopAllApps()
{
    local type="$1"

    isNotice "Please wait for docker containers to stop"
    
    local result=$(dockerCommandRun "docker ps -q 2>/dev/null")
    if [[ -n "$result" ]]; then
        local result=$(dockerCommandRun "docker stop $(docker ps -a -q)")
        checkSuccess "Stopping all docker containers (Rootless if installed)"
    fi
}
