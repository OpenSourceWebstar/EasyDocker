#!/bin/bash

migrateGetAppName() 
{
    local selected_file=$(sudo echo "$1" | cut -d':' -f2- | sed 's/^ *//g')
    local selected_app_name=$(sudo echo "$selected_file" | sed 's/-backup.*//' | sed 's/.*-//')
    #echo "$selected_app_name"
}


