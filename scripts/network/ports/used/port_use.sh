#!/bin/bash

portUse()
{
    local app_name="$1"
    local port="$2"
    local flag="$3"

    if [[ $port != "" ]]; then
        # Check if the port already exists in the database
        if ! portUsedExistsInDatabase "$app_name" "$port" "$flag"; then
            if [[ $disallow_used_port == "false" ]]; then
                databasePortUsedInsert "$app_name" "$port"
            fi
        fi
    fi
}
