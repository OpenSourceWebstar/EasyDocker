#!/bin/bash

selectRemoteApp() 
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
                selectRemoteBackupFile "$selected_app_name"
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
