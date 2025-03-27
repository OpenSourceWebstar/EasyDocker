#!/bin/bash

# Function to display available applications
displayLocalApps() 
{
    echo ""
    echo "##########################################"
    echo "###       Single App Restore List"
    echo "##########################################"
    echo ""
    echo "Available applications:"
    for ((i = 0; i < ${#app_list[@]}; i++)); do
        echo "$((i + 1)). ${app_list[$i]}"
    done
    echo ""
}