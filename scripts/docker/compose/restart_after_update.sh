#!/bin/bash

dockerComposeRestartAfterUpdate()
{
    local app_name="$1"
    local flags="$2"

    if [[ $flags == "install" ]] ; then
        dockerComposeRestart $app_name;
        did_not_restart=false
    elif [[ $flags == "" ]] || [[ $flags == "restart" ]]; then
        while true; do
            echo ""
            isNotice "Changes have been made to the $app_name configuration."
            echo ""
            isQuestion "Would you like to restart $app_name? (y/n): "
            echo ""
            read -p "" restart_choice
            if [[ -n "$restart_choice" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$restart_choice" == [yY] ]]; then
            dockerComposeRestart $app_name;
            did_not_restart=false
        fi
        if [[ "$restart_choice" == [nN] ]]; then
            did_not_restart=true
        fi
    fi
}