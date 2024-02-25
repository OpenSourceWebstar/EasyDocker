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
    isQuestion "Enter your choice (1-5, or 'x' to exit): "
    read -p "" app_log_choice
    case "$app_log_choice" in
        1)
            dockerCommandRun "docker logs $app_name --tail 20"
            isQuestion "Press Enter to continue..."
            read -p "" continueafterlogs
            viewLogsAppMenu "$app_name"
        ;;
        2)
            dockerCommandRun "docker logs $app_name --tail 50"
            isQuestion "Press Enter to continue..."
            read -p "" continueafterlogs
            viewLogsAppMenu "$app_name"
        ;;
        3)
            dockerCommandRun "docker logs $app_name --tail 100"
            isQuestion "Press Enter to continue..."
            read -p "" continueafterlogs
            viewLogsAppMenu "$app_name"
        ;;
        4)
            dockerCommandRun "docker logs $app_name --tail 200"
            isQuestion "Press Enter to continue..."
            read -p "" continueafterlogs
            viewLogsAppMenu "$app_name"
        ;;
        5)
            dockerCommandRun "docker logs $app_name"
            isQuestion "Press Enter to continue..."
            read -p "" continueafterlogs
            viewLogsAppMenu "$app_name"
        ;;
        x)
            viewLogs;  # Return to the viewLogs submenu
        ;;
        *)
            isNotice "Invalid choice. Please select a valid option (1-5, or 'x' to exit)."
            viewLogsAppMenu "$app_name"
        ;;
    esac
}
