#!/bin/bash

dockerDeleteData()
{
    local app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "No app_name provided, unable to continue..."
        return
    else
        local result=$(sudo rm -rf $containers_dir$app_name)
        checkSuccess "Deleting $app_name install folder"
    fi

}