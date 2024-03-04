#!/bin/bash

portHandleAllConflicts() 
{
    for usedconflict in "${portConflicts[@]}"; do
        local app_name=$(echo "$usedconflict" | awk '{print $1}')
        portUsedConflictFound "$app_name"
    done

    for openconflict in "${openPortConflicts[@]}"; do
        local app_name=$(echo "$openconflict" | awk '{print $1}')
        portOpenConflictFound "$app_name"
    done
}
