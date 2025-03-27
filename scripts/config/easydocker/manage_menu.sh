#!/bin/bash

viewEasyDockerConfigs()
{
    local specific_config="$1"  # Get the optional argument
    local config_files=("$configs_dir"*)  # List all files in the /configs/ folder

    echo ""
    echo "#################################"
    echo "###    Manage Config Files    ###"
    echo "#################################"
    echo ""

    if [ ${#config_files[@]} -eq 0 ]; then
        isNotice "No files found in /configs/ folder."
        return
    fi

    declare -A config_timestamps  # Associative array to store config names and their modified timestamps

    # If a specific config name is provided, attempt to edit it directly
    if [[ -n "$specific_config" ]]; then
        for file in "${config_files[@]}"; do
            local file_name=$(basename "$file")
            local file_name_without_prefix=${file_name#config_}
            local config_name=${file_name_without_prefix,,}

            if [[ "$file_name" == config_apps_* ]]; then
                config_name=${config_name#apps_}
            fi

            if [[ "$config_name" == "$specific_config" ]]; then
                sudo $CFG_TEXT_EDITOR "$file"
                createTouch "$file" $sudo_user_name
                echo ""
                isNotice "Configuration file '$config_name' has been updated."
                echo ""
                return
            fi
        done

        isNotice "No config found with the name '$specific_config'."
        return
    fi

    PS3="Select a config to edit (Type the first letter of the config, or x to exit): "
    while true; do
        for ((i = 0; i < ${#config_files[@]}; i++)); do
            local file_name=$(basename "${config_files[i]}")
            local file_name_without_prefix=${file_name#config_}
            local config_name=${file_name_without_prefix,,}

            if [[ "$file_name" == config_apps_* ]]; then
                config_name=${config_name#apps_}
            fi

            local first_letter=${config_name:0:1}

            if [ "${config_timestamps[$config_name]}" ]; then
                local last_modified="${config_timestamps[$config_name]}"
            else
                local last_modified=$(stat -c "%y" "${config_files[i]}")
                config_timestamps["$config_name"]=$last_modified
            fi

            local formatted_last_modified=$(date -d "$last_modified" +"%m/%d %H:%M")

            isOption "$first_letter. ${config_name,,} (Last modified: $formatted_last_modified)"
        done

        echo ""
        isOption "x. Exit"
        echo ""
        isQuestion "Enter the first letter of the config (or x to exit): "
        read -p "" selected_letter

        if [[ "$selected_letter" == "x" ]]; then
            if [[ $config_edited == "true" ]]; then
                echo ""
                isNotice "Reloading configuration file(s) for EasyDocker."
                echo ""
                sourceScanFiles "easydocker_configs";
            else
                isNotice "Exiting..."
                echo ""
                checkConfigFilesMissingVariables true;
                databaseCycleThroughListAppsCrontab true;
                return
            fi
        elif [[ "$selected_letter" =~ [A-Za-z] ]]; then
            local selected_file=""
            for ((i = 0; i < ${#config_files[@]}; i++)); do
                local file_name=$(basename "${config_files[i]}")
                local file_name_without_prefix=${file_name#config_}
                local config_name=${file_name_without_prefix,,}

                if [[ "$file_name" == config_apps_* ]]; then
                    config_name=${config_name#apps_}
                fi

                local first_letter=${config_name:0:1}
                if [[ "$selected_letter" == "$first_letter" ]]; then
                    selected_file="${config_files[i]}"
                    break
                fi
            done

            if [ -z "$selected_file" ]; then
                isNotice "No config found with the selected letter. Please try again."
                read -p "Press Enter to continue."
            else
                sudo $CFG_TEXT_EDITOR "$selected_file"
                createTouch "$selected_file" $sudo_user_name
                local config_name=$(basename "${selected_file}" | sed 's/config_//')
                config_timestamps["$config_name"]=$(stat -c "%y" "$selected_file")

                echo ""
                isNotice "Configuration file '$config_name' has been updated."
                echo ""
            fi
        else
            isNotice "Invalid input. Please enter a valid letter or 'x' to exit."
            echo ""
            read -p "Press Enter to continue."
        fi
    done
}
