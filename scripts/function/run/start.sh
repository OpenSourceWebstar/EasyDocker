#!/bin/bash

runStart()
{  
    local path="$3"
    cd $script_dir
    local result=$(sudo chmod 0755 start.sh)
    checkSuccess "Updating Start Script Permissions"
    
    local result=$(sudo ./start.sh "" "" "$path")
    checkSuccess "Running Start script"
}
