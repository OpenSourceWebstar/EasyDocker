#!/bin/bash

runUpdate()
{
    cd $script_dir
    local result=$(sudo chmod 0755 update.sh)
    checkSuccess "Updating Update Script Permissions"
    
    local result=$(sudo ./update.sh)
    checkSuccess "Running Update Script"
}
