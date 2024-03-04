#!/bin/bash

dockerCommandRun() 
{
    local command="$1"
    local type="$2" # sudo

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        dockerCommandRunInstallUser "$command"
    elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        if [[ $type == "sudo" ]]; then
            sudo $command
        else
            $command
        fi
    fi
}
