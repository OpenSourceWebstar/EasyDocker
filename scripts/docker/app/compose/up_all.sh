#!/bin/bash

dockerComposeUpAllApps()
{
    local type="$1"
    local subdirectories=($(find "$containers_dir" -mindepth 1 -maxdepth 1 -type d))

    for dir in "${subdirectories[@]}"; do
        local app_name=$(basename "$dir")
        dockerComposeUp "$app_name" "" "$type"
    done
}
