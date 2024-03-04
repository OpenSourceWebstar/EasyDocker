#!/bin/bash

dockerServiceStop()
{
    local type="$1"

    if [[ "$type" == "rooted" ]]; then
        if [[ "$docker_rooted_found" == "true" ]]; then
            isNotice "Stopping rooted Docker service...this may take a moment..."
        
            local result=$(sudo systemctl stop docker)
            checkSuccess "Stopping Rooted Docker Service"
            
            local result=$(sudo systemctl disable docker)
            checkSuccess "Disabling Rooted Docker Service"
        fi
    fi

    if [[ "$type" == "rootless" ]]; then
        if [[ "$docker_rootless_found" == "true" ]]; then
            isNotice "Stopping rootless Docker service...this may take a moment..."

            #local result=$(dockerCommandRunInstallUser "systemctl --user stop docker")
            #checkSuccess "Stop the systemd user Docker service"

            local result
            local retries=3
            while [ $retries -gt 0 ]; do
                # Check if Docker is running for the specified user
                if dockerCheckIsRunningForUser "$type"; then
                    # Docker is running, attempt to stop it
                    result=$(dockerCommandRunInstallUser "systemctl --user stop docker")
                    if [ $? -eq 0 ]; then
                        checkSuccess "Stop the systemd user Docker service"
                        break
                    else
                        ((retries--))
                        echo "Retrying to stop Docker service. Retries left: $retries"
                        sleep 5
                    fi
                else
                    isNotice "Docker is already stopped for the rootless user."
                    break
                fi
            done

            if [ $retries -eq 0 ]; then
                isError "Failed to stop Docker service after multiple attempts."
                rootless_docker_failed_stop="true"
            fi

        fi
    fi

}