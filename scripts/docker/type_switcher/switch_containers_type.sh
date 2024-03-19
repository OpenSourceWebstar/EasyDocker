#!/bin/bash

dockerSwitcherUpdateContainersToDockerType()
{
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        # Scannning the containers folder
        local subdirectories=($(find "$containers_dir" -maxdepth 1 -type d))
        for dir in "${subdirectories[@]}"; do
            dockerSwitcherScanContainersForSocket "$dir"
            if [[ $docker_socket_file_updated == "true" ]]; then
                dockerRestartAppViaInstall $(basename $dir);
            fi
            docker_socket_file_updated="false"
        done
    fi

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        # Scannning the containers folder
        local subdirectories=($(find "$containers_dir" -maxdepth 1 -type d))
        for dir in "${subdirectories[@]}"; do
            dockerSwitcherScanContainersForSocket "$dir"
            if [[ $docker_socket_file_updated == "true" ]]; then
                dockerRestartAppViaInstall $(basename $dir);
            fi
            docker_socket_file_updated="false"
        done
    fi
}
