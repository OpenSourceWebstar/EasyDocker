#!/bin/bash

dockerCheckAppHealthDetails() 
{
    local app_name="$1"

    result=$(docker inspect --format "{{json .State.Health }}" $app_name | jq)
    checkSuccess "Getting $app_name health details."
}
