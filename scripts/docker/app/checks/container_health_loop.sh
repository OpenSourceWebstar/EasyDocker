#!/bin/bash

dockerCheckContainerHealthLoop() 
{
    local container_name="$1"
    local timeout="$2"
    local wait_time="$3"

    isNotice "This container health check will timeout after $timeout seconds"

    local counter=0
    while true; do
        if dockerCheckContainerHealth "$container_name"; then
            isSuccessful "Container is healthy!"
            break
        fi

        if [ "$counter" -ge "$timeout" ]; then
            isNotice "Container health check timed out after $timeout seconds. Exiting..."
            break
        fi

        isNotice "Waiting $wait_time seconds for container to turn healthy..."
        sleep "$wait_time"
        counter=$((counter + wait_time))
    done
}
