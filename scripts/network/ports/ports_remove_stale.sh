#!/bin/bash

portsRemoveStale()
{
    local app_name="$1"
    local db_used_ports=($(databaseGetUsedPortsForApp "$app_name"))
    local db_open_ports=($(databaseGetOpenPortsForApp "$app_name"))

    # Remove open ports that exist in the database but not in openports
    for db_open_port in "${db_open_ports[@]}"; do
        if ! containsElement "$db_open_port" "${openports[@]}"; then
            portClose "$app_name" "$db_open_port" stale
        fi
    done

    # Remove used ports that exist in the database but not in usedports
    for db_used_port in "${db_used_ports[@]}"; do
        if ! containsElement "$db_used_port" "${usedports[@]}"; then
            portUnuse "$app_name" "$db_used_port" stale
        fi
    done
}
