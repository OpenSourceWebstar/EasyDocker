#!/bin/bash

viewAppCategoryConfigs() 
{
    local category="$1"

    if [[ -z "$category" ]]; then
        echo "Usage: viewAppCategoryConfigs <category>"
        return 1
    fi

    local installed_apps=()
    local other_apps=()

    # Collect all app_name folders and categorize them into installed and others
    for app_dir in "$containers_dir"/*/; do
        if [ -d "$app_dir" ]; then
            local app_name=$(basename "$app_dir")
            local app_config_file="$install_containers_dir$app_name/$app_name.sh"
            if [ -f "$app_config_file" ]; then
                local category_info=$(grep -Po '(?<=# Category : ).*' "$app_config_file")
                if [ "$category_info" == "$category" ]; then
                    # Check if the app_name is installed based on the database query
                    results=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 1 AND name = '$app_name';")
                    if [[ -n "$results" ]]; then
                    	local app_description="\e[32m*INSTALLED*\e[0m - $app_name"
                        installed_apps+=("$app_description")
                    else
                        other_apps+=("$app_name")
                    fi
                fi
            fi
        fi
    done

    if [[ ${#installed_apps[@]} -eq 0 && ${#other_apps[@]} -eq 0 ]]; then
        echo ""
        isNotice "No application folders found in category '$category'."
        return 1
    fi

    local category_name="$category"
    local category_name_ucfirst="$(tr '[:lower:]' '[:upper:]' <<< ${category_name:0:1})${category_name:1}"

    echo ""
    echo "#################################"
    echo "###    $category_name_ucfirst Applications"
    echo "#################################"

    PS3="Select an application: "

    selectRemoteApppp=""

    while [[ -z "$selectRemoteApppp" ]]; do
        echo ""
        # Display *INSTALLED* apps first and then others
        for ((i = 0; i < ${#installed_apps[@]}; i++)); do
            local app_option="${installed_apps[i]}"
            isOption "$((i + 1)). $app_option"
        done

        for ((i = 0; i < ${#other_apps[@]}; i++)); do
            local app_option="${other_apps[i]}"
            isOption "$((i + 1 + ${#installed_apps[@]})). $app_option"
        done
        
        echo ""
        isQuestion "Enter the number of the app to edit or 'b' to go back or 'x' to exit: "
        read -p "" selected_number
        
        if [[ "$selected_number" == "b" ]]; then
            return
        elif [[ "$selected_number" == "x" ]]; then
            if [[ $config_edited == "true" ]]; then
                echo ""
                isNotice "Reloading configuration file(s) for all Applications."
                echo ""
                sourceScanFiles "app_configs";
                resetToMenu;
            else
                resetToMenu;
            fi
        elif [[ "$selected_number" =~ ^[0-9]+$ ]]; then
            if ((selected_number >= 1 && selected_number <= (${#installed_apps[@]} + ${#other_apps[@]}))); then
                if ((selected_number <= ${#installed_apps[@]})); then
                    # Selected an *INSTALLED* app
                    local selected_index=$((selected_number - 1))
                    local app_option="${installed_apps[selected_index]}"
                else
                    # Selected an app from the other category
                    local selected_index=$((selected_number - ${#installed_apps[@]} - 1))
                    local app_option="${other_apps[selected_index]}"
                fi

                # Remove the "*INSTALLED" suffix if it's present
                local app_name="${app_option//\\e[32m*INSTALLED*\\e[0m - /}"
                editAppConfig "$app_name"
                local selectRemoteApppp="$app_name"
            else
                isNotice "Invalid number. Please select a valid number or 'x' to exit."
                echo ""
                read -p "Press Enter to continue."
            fi
        else
            isNotice "Invalid input. Please enter a valid number or 'x' to exit."
            echo ""
            read -p "Press Enter to continue."
        fi
    done
}