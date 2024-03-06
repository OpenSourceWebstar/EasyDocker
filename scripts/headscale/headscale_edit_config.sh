#!/bin/bash

headscaleEditConfig() 
{
    local config_file="${containers_dir}headscale/config/config.yaml"
    local previous_md5=$(md5sum "$config_file" | awk '{print $1}')
    $CFG_TEXT_EDITOR "$config_file"
    local current_md5=$(md5sum "$config_file" | awk '{print $1}')

    if [ "$previous_md5" != "$current_md5" ]; then
        while true; do
            echo ""
            isNotice "Changes have been made to the Headscale configuration."
            echo ""
            isQuestion "Would you like to restart Headscale? (y/n): "
            echo ""
            read -p "" restart_headscale
            if [[ -n "$restart_headscale" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$restart_choice" == [yY] ]]; then
            dockerComposeRestart "headscale";
        fi
    fi
}
