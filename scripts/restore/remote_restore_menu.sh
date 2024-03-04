#!/bin/bash

restoreRemoteMenu()
{
    local backup_type="$1"

    selectRemoteLocation()
    {
        while true; do
            echo ""
            isNotice "Please select a remote backup location"
            isNotice "TIP: These are defined in the config_backup file."
            echo ""
            
            # Check if Remote 1 is enabled and display accordingly
            if [ "${CFG_BACKUP_REMOTE_1_ENABLED}" == true ]; then
                isOption "1. Backup Server 1 - '$CFG_BACKUP_REMOTE_1_USER'@'$CFG_BACKUP_REMOTE_1_IP' (Enabled)"
            else
                isOption "1. Backup Server 1 (Disabled)"
            fi
            
            # Check if Remote 2 is enabled and display accordingly
            if [ "${CFG_BACKUP_REMOTE_2_ENABLED}" == true ]; then
                isOption "2. Backup Server 2 - '$CFG_BACKUP_REMOTE_2_USER'@'$CFG_BACKUP_REMOTE_2_IP' (Enabled)"
            else
                isOption "2. Backup Server 2 (Disabled)"
            fi
            
            echo ""
            isOption "x. Exit"
            echo ""
            isQuestion "Enter your choice: "
            read -rp "" select_remote

            case "$select_remote" in
                1)
                    if [ "${CFG_BACKUP_REMOTE_1_ENABLED}" == false ]; then
                        echo ""
                        isNotice "Remote Backup Server 1 is disabled. Please select another option."
                        continue
                    fi

                    remote_user="${CFG_BACKUP_REMOTE_1_USER}"
                    remote_ip="${CFG_BACKUP_REMOTE_1_IP}"
                    remote_port="${CFG_BACKUP_REMOTE_1_PORT}"
                    remote_pass="${CFG_BACKUP_REMOTE_1_PASS}"
                    remote_directory="${CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY}"
                    remote_server=1
                    ;;
                2)
                    if [ "${CFG_BACKUP_REMOTE_2_ENABLED}" == false ]; then
                        echo ""
                        isNotice "Remote Backup Server 2 is disabled. Please select another option."
                        continue
                    fi

                    remote_user="${CFG_BACKUP_REMOTE_2_USER}"
                    remote_ip="${CFG_BACKUP_REMOTE_2_IP}"
                    remote_port="${CFG_BACKUP_REMOTE_2_PORT}"
                    remote_pass="${CFG_BACKUP_REMOTE_2_PASS}"
                    remote_directory="${CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY}"
                    remote_server=2
                    ;;
                x|X)
                    isNotice "Exiting..."
                    resetToMenu;
                    ;;
                *)
                    isNotice "Invalid option. Please select a valid option."
                    continue
                    ;;
            esac

            break  # Exit the loop when a valid selection is made
        done
    }

    # Function for the Install Name selection menu
    selectInstallName() {
        while true; do
            echo ""
            isNotice "Please select the Install Name : "
            echo ""
            isOption "1. Restore using local $CFG_INSTALL_NAME"
            isOption "2. Specify a different Install Name for restoration"
            echo ""
            isOption "x. Exit"
            echo ""
            isQuestion "Enter your choice: "
            read -rp "" select_option

            case "$select_option" in
                1)
                    restore_install_name="$CFG_INSTALL_NAME"
                    echo ""
                    isNotice "Restoring using Install Name : $restore_install_name"
                    echo ""
                    ;;
                2)
                    echo ""
                    isQuestion "Enter the Install Name you would like to restore from: "
                    read -rp "" restore_install_name
                    isNotice "Restoring using Install Name :  $restore_install_name"
                    echo ""
                    ;;
                x|X)
                    isNotice "Exiting..."
                    resetToMenu;
                    ;;
                *)
                    echo ""
                    isNotice "Invalid option. Please select a valid option."
                    continue
                    ;;
            esac

            break  # Exit the loop when a valid selection is made
        done
    }

    # Call the remote backup location menu function
    selectRemoteLocation

    # Call the Install Name selection menu function
    selectInstallName

    select_app() 
    {
        while true; do
            echo ""
            echo "##########################################"
            echo "###  $backup_type Restore List (Remote)"
            echo "##########################################"
            echo ""
            app_list=()
            seen_apps=()  # Use a regular indexed array to keep track of seen apps
            local count=1

            # Use SSH to list remote backups
            remote_backup_list=$(sshRemote "$remote_pass" "$remote_port" "${remote_user}@${remote_ip}" "ls -1 \"${remote_directory}/${restore_install_name}/$backup_type\"/*.zip 2>/dev/null")

            # Process the list of remote backup files
            while read -r zip_file; do
                # Extract the app_name from the filename using sed
                local app_name=$(basename "$zip_file" | sed -E 's/.*-([^-]+)-backup-.*/\1/')

                # Check if the app_name is already in the seen_apps array
                if ! [[ " ${seen_apps[@]} " =~ " $app_name " ]]; then
                    app_list+=("$app_name")
                    seen_apps+=("$app_name")  # Add the app_name to the seen_apps array
                    isOption "$count. $app_name"
                    ((count++))
                fi
            done <<< "$remote_backup_list"

            # Add the 'x' option to go to the main menu
            isOption "x. Go to the main menu"

            # Read the user's choice number or 'x' to go to the main menu
            echo ""
            isQuestion "Select an application (number) or 'x' to go to the main menu: "
            read -p "" chosen_app_option

            if [[ "$chosen_app_option" == "x" ]]; then
                resetToMenu;  # Go back to the main menu
            elif [[ "$chosen_app_option" =~ ^[0-9]+$ ]]; then
                selected_app_index=$((chosen_app_option - 1))

                if [ "$selected_app_index" -ge 0 ] && [ "$selected_app_index" -lt "${#app_list[@]}" ]; then
                    local selected_app_name="${app_list[selected_app_index]}"
                    select_backup_file "$selected_app_name"
                    return
                else
                    echo ""
                    isNotice "Invalid application selection."
                fi
            else
                echo "" 
                isNotice "Invalid input. Please select a valid option or 'x' to go to the main menu."
            fi
        done
    }

    select_backup_file() {
        selected_app=$1
        saved_selected_app=$selected_app
        echo ""
        echo "##########################################"
        echo "###    Available backups for $saved_selected_app:"
        echo "##########################################"
        echo ""
        backup_list=()
        local count=1

        # Use SSH to list remote backups for the selected app
        remote_backup_list=$(sshRemote "$remote_pass" "$remote_port" "${remote_user}@${remote_ip}" "ls -1 \"${remote_directory}/${restore_install_name}/$backup_type\"/*$saved_selected_app* 2>/dev/null")

        # Process the list of remote backup files
        while read -r zip_file; do
            backup_list+=("$zip_file")
            isOption "$count. $(basename "$zip_file")"
            ((count++))
        done <<< "$remote_backup_list"

        while true; do
            # Read the user's choice number or input
            echo ""
            isQuestion "Select a backup file (number) or 'b' to go back: "
            read -p "" chosen_backup_option

            if [[ "$chosen_backup_option" == "b" ]]; then
                select_app  # Go back to the application selection
                return
            elif [[ "$chosen_backup_option" =~ ^[0-9]+$ ]]; then
                selected_backup_index=$((chosen_backup_option - 1))

                if [ "$selected_backup_index" -ge 0 ] && [ "$selected_backup_index" -lt "${#backup_list[@]}" ]; then
                    chosen_backup_file=$(basename "${backup_list[selected_backup_index]}")
                    echo ""
                    isNotice "You selected: $chosen_backup_file"
                    restoreStart $saved_selected_app "$chosen_backup_file" "${remote_directory}/${restore_install_name}/$backup_type"
                    return  # Exit the loop once a valid selection is made
                else
                    echo ""
                    isNotice "Invalid backup file selection."
                fi
            else
                echo ""
                isNotice "Invalid input. Please select a valid option or 'b' to go back."
            fi
        done
    }

    select_app
}
