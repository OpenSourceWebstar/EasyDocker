#!/bin/bash

viewLogs()
{
    echo ""
    echo "##########################################"
    echo "###    View Logs for Installed Apps    ###"
    echo "##########################################"
    echo ""
    
    # List installed apps and add them as numbered options
    local app_list=($(sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 1;"))
    for ((i = 0; i < ${#app_list[@]}; i++)); do
        isOption "$((i + 1)). View logs for ${app_list[i]}"
    done
    
    isOption "e. View easydocker.log"
    isOption "x. Exit"
    echo ""
    
    isQuestion "Enter your choice (1-${#app_list[@]}, e or 'x' to exit): "
    read -p "" log_choice
    
    case "$log_choice" in
        [1-9]|[1-9][0-9]|10)
            index=$((log_choice - 1))
            if [ "$index" -ge 0 ] && [ "$index" -lt "${#app_list[@]}" ]; then
                local app_name="${app_list[index]}"
                viewLogsAppMenu "$app_name"  # Call the app-specific menu
            else
                echo ""
                isNotice "Invalid app selection. Please select a valid app."
                viewLogs;
            fi
        ;;
        e)
            isNotice "Viewing easydocker.log:"
            sudo $CFG_TEXT_EDITOR "$logs_dir/easydocker.log"
            viewLogs;
        ;;
        x)
            isNotice "Exiting"
            return
        ;;
        *)
            isNotice "Invalid choice. Please select a valid option (1-${#app_list[@]}, e or 'x' to exit)."
            viewLogs;
        ;;
    esac
}
