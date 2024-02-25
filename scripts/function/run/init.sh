#!/bin/bash

runInit()
{
    cd $script_dir
    local result=$(sudo chmod 0755 init.sh)
    checkSuccess "Updating Init Script Permissions"
    
    local result=$(sudo ./init.sh run)
    checkSuccess "Running Init Script"
}
