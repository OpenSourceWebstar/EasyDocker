#!/bin/bash

dockerStartAllApps()
{
    isNotice "Please wait for docker containers to start"
    local result=$(dockerCommandRun "docker restart $(docker ps -a -q)")
    checkSuccess "Starting up all docker containers"
}
