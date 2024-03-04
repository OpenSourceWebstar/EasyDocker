#!/bin/bash

portUnuse()
{
    local app_name="$1"
    local port="$2"
    local flag="$3"

    if [[ $port != "" ]]; then
        if [[ $flag == "stale" ]]; then
            isNotice "Old stale port $port found for $app_name and is being removed from the database."
        fi
        if portUsedExistsInDatabase "$app_name" "$port" "$flag"; then
            if [[ $disallow_used_port == "false" ]]; then
                databasePortUsedDelete "$app_name" "$port";
            fi
        fi
    fi
}
