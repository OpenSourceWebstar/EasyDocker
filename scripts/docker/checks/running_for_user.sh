#!/bin/bash

dockerCheckIsRunningForUser() 
{
    local type="$1"

    # Check if Docker is running for the specified user
    if [[ $type == "rootless" ]]; then
        local docker_command='docker ps 2>&1'
        local result=$(dockerCommandRunInstallUser "$docker_command")
    elif [[ $type == "rooted" ]]; then
        local docker_command='sudo docker ps 2>&1'
        local result=$(eval "$docker_command")
    else
        echo "Invalid user type specified."
        return 1
    fi

    # Check the result
    if [[ $result =~ "Cannot connect to the Docker daemon" ]]; then
        #echo "Docker is not running for the specified user."
        return 1  # Docker is not running
    else
        #echo "Docker is running for the specified user."
        return 0  # Docker is running
    fi
}
