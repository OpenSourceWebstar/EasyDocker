#!/bin/bash

dockerCheckAppHealthStatus() 
{
    local app_name="$1"

    result=$(docker inspect --format "{{json .State.Health.Status }}" $app_name)
    checkSuccess "Getting $app_name health status."
}
