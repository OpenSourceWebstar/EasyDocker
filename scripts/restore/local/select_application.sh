#!/bin/bash

# Function to prompt user to select an app
selectLocalApplication() 
{
    local -n app_list_ref=$1
    local -n selected_app_ref=$2

    displayLocalApps

    local chosen_index
    read -p "Select an application (number): " chosen_index
    if [[ ! "$chosen_index" =~ ^[0-9]+$ || "$chosen_index" -lt 1 || "$chosen_index" -gt ${#app_list_ref[@]} ]]; then
        echo "Invalid application selection."
        return 1
    fi

    selected_app_ref="${app_list_ref[chosen_index - 1]}"
}
