#!/bin/bash

portOpenAddConflict() 
{
    local app_name="$1"
    local port="$2"
    local type="$3"
    local app_name_from_db="$4"
    
    if [ -n "$app_name" ] && [ -n "$port" ] && [ -n "$type" ] && [ -n "$app_name_from_db" ]; then
        openPortConflicts=()
        openPortConflicts+=("Port $port and type $type are already open and used by $app_name_from_db for $app_name.")
    fi
}
