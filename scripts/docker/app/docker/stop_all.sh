#!/bin/bash

dockerStopAllApps() 
{
    isNotice "Stopping all running Docker containers. Please wait..."

    # Stop all running containers using a single pipeline
    dockerCommandRun "docker ps -q | xargs -r docker stop" >/dev/null 2>&1

    checkSuccess "Stopped all running Docker containers."
}
