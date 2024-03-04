#!/bin/bash

dockerCheckContainerHealth() 
{
    local container_name="$1"
    local health_status=$(dockerCommandRun "docker inspect --format='{{json .State.Health.Status}}' $container_name")

    if [ "$health_status" == "\"healthy\"" ]; then
        return 0  # Container is healthy
    else
        return 1  # Container is not healthy
    fi
}
