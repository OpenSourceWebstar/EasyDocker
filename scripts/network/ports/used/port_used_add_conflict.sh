#!/bin/bash

portUsedAddConflict() 
{
    local app_name="$1"
    local port="$2"
    local app_name_from_db="$3"

    portConflicts=()
    portConflicts+=("$app_name Port $port is already used by $app_name_from_db.")
}
