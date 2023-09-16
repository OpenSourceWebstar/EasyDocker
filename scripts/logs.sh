#!/bin/bash

viewLogsAppMenu()
{
    local app_name="$1"
    echo ""
    isNotice "Viewing logs for $app_name:"
    echo ""
    isOption "1. Show last 20 lines"
    isOption "2. Show last 50 lines"
    isOption "3. Show last 100 lines"
    isOption "4. Show last 200 lines"
    isOption "5. Show full log"
    isOption "x. Back to main menu"
    echo ""
    isQuestion "Enter your choice (1-5, x): "
    read -p "" app_log_choice
    case "$app_log_choice" in
        1)
            runCommandForDockerInstallUser "docker logs $app_name --tail 20"
            isQuestion "Press Enter to continue..."
            read -p "" continueafterlogs
            viewLogsAppMenu "$app_name"
        ;;
        2)
            runCommandForDockerInstallUser "docker logs $app_name --tail 50"
            isQuestion "Press Enter to continue..."
            read -p "" continueafterlogs
            viewLogsAppMenu "$app_name"
        ;;
        3)
            runCommandForDockerInstallUser "docker logs $app_name --tail 100"
            isQuestion "Press Enter to continue..."
            read -p "" continueafterlogs
            viewLogsAppMenu "$app_name"
        ;;
        4)
            runCommandForDockerInstallUser "docker logs $app_name --tail 200"
            isQuestion "Press Enter to continue..."
            read -p "" continueafterlogs
            viewLogsAppMenu "$app_name"
        ;;
        5)
            runCommandForDockerInstallUser "docker logs $app_name"
            isQuestion "Press Enter to continue..."
            read -p "" continueafterlogs
            viewLogsAppMenu "$app_name"
        ;;
        x)
            viewLogs;  # Return to the viewLogs submenu
        ;;
        *)
            isNotice "Invalid choice. Please select a valid option (1-5, x)."
            viewLogsAppMenu "$app_name"
        ;;
    esac
}

viewLogs()
{
    echo ""
    echo "##########################################"
    echo "###    View Logs for Installed Apps    ###"
    echo "##########################################"
    echo ""
    
    # List installed apps and add them as numbered options
    local app_list=($(sqlite3 "$base_dir/$db_file" "SELECT name FROM apps WHERE status = 1;"))
    for ((i = 0; i < ${#app_list[@]}; i++)); do
        isOption "$((i + 1)). View logs for ${app_list[i]}"
    done
    
    isOption "e. View easydocker.log"
    isOption "x. Exit"
    echo ""
    
    isQuestion "Enter your choice (1-${#app_list[@]}, e, x): "
    read -p "" log_choice
    
    case "$log_choice" in
        [1-9]|[1-9][0-9]|10)
            index=$((log_choice - 1))
            if [ "$index" -ge 0 ] && [ "$index" -lt "${#app_list[@]}" ]; then
                app_name="${app_list[index]}"
                viewLogsAppMenu "$app_name"  # Call the app-specific menu
            else
                echo ""
                isNotice "Invalid app selection. Please select a valid app."
                viewLogs;
            fi
        ;;
        e)
            isNotice "Viewing easydocker.log:"
            nano "$logs_dir/easydocker.log"
            viewLogs;
        ;;
        x)
            isNotice "Exiting"
            return
        ;;
        *)
            isNotice "Invalid choice. Please select a valid option (1-${#app_list[@]}, e, x)."
            viewLogs;
        ;;
    esac
}
