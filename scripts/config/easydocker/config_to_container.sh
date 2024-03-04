#!/bin/bash

dockerConfigSetupToContainer()
{
    local silent_flag="$1"
    local app_name="$2"
    local flags="$3"

    local target_path="$containers_dir$app_name"
    local source_file="$install_containers_dir$app_name/$app_name.config"
    local config_file="$app_name.config"

    if [ "$app_name" == "" ]; then
        isError "The app_name is empty."
        return 1
    fi

    if [ -d "$target_path" ]; then
        if [ "$silent_flag" == "loud" ]; then
            isNotice "The directory '$target_path' already exists."
        fi
    else
        createFolders "$silent_flag" "$CFG_DOCKER_INSTALL_USER" "$target_path"
    fi

    if [ ! -f "$source_file" ]; then
        isError "The config file '$source_file' does not exist."
        return 1
    fi

    if [ ! -f "$target_path/$config_file" ]; then
        if [ "$silent_flag" == "loud" ]; then
            isNotice "Copying config file to '$target_path/$config_file'..."
        fi
        copyFile "$silent_flag" "$source_file" "$target_path/$config_file" $sudo_user_name | sudo tee -a "$logs_dir/$docker_log_file" 2>&1
    fi

    fixConfigPermissions $silent_flag $app_name;

    # Check if the file exists
    if [ ! -e "$target_path/$config_file" ]; then
        isError "File $target_path/$config_file does not exist"
        return
    fi

    # Check if the user has read permission on target_path/config_file
    if [ ! -r "$target_path/$config_file" ]; then
        isError "Insufficient permissions to read $target_path/$config_file"
        return
    fi

    if [[ "$flags" == "install" ]]; then
        if [ -f "$target_path/$config_file" ]; then
            # Same content check
            if sudo cmp -s "$source_file" "$target_path/$config_file"; then
                echo ""
                isNotice "Config file for $app_name contains no edits."
                echo ""
                while true; do
                    isQuestion "Would you like to make edits to the config file? (y/n): "
                    read -rp "" editconfigaccept
                    echo ""
                    case $editconfigaccept in
                        [yY])
                            # Calculate the checksum of the original file
                            local original_checksum=$(sudo md5sum "$target_path/$config_file")

                            # Open the file with $CFG_TEXT_EDITOR for editing
                            sudo $CFG_TEXT_EDITOR "$target_path/$config_file"

                            # Calculate the checksum of the edited file
                            local edited_checksum=$(sudo md5sum "$target_path/$config_file")

                            # Compare the checksums to check if changes were made
                            if [[ "$original_checksum" != "$edited_checksum" ]]; then
                                source $target_path/$config_file
                                setupInstallVariables $app_name;
                                isSuccessful "Changes have been made to the $config_file."
                            fi
                            break
                            ;;
                        [nN])
                            break  # Exit the loop without updating
                            ;;
                        *)
                            isNotice "Please provide a valid input (y or n)."
                            ;;
                    esac
                done
            else
                echo ""
                isNotice "Config file for $app_name has been updated..."
                echo ""
                while true; do
                    isQuestion "Would you like to reset the config file? (y/n): "
                    read -rp "" resetconfigaccept
                    echo ""
                    case $resetconfigaccept in
                        [yY])
                            isNotice "Resetting $app_name config file."
                            copyFile "loud" "$source_file" "$target_path/$config_file" $CFG_DOCKER_INSTALL_USER | sudo tee -a "$logs_dir/$docker_log_file" 2>&1
                            source $target_path/$config_file
                            dockerConfigSetupToContainer "loud" $app_name;
                            break
                            ;;
                        [nN])
                            break  # Exit the loop without updating
                            ;;
                        *)
                            isNotice "Please provide a valid input (y or n)."
                            ;;
                    esac
                done
            fi
        else
            isNotice "Config file for $app_name does not exist. Creating it..."
            copyFile "loud" "$source_file" "$target_path/$config_file" $CFG_DOCKER_INSTALL_USER | sudo tee -a "$logs_dir/$docker_log_file" 2>&1
            echo ""
            isNotice "Config file for $app_name contains no edits."
            echo ""
            while true; do
                isQuestion "Would you like to make edits to the config file? (y/n): "
                read -rp "" editconfigaccept
                echo ""
                case $editconfigaccept in
                    [yY])
                        # Calculate the checksum of the original file
                        local original_checksum=$(sudo md5sum "$target_path/$config_file")

                        # Open the file with $CFG_TEXT_EDITOR for editing
                        sudo $CFG_TEXT_EDITOR "$target_path/$config_file"

                        # Calculate the checksum of the edited file
                        local edited_checksum=$(sudo md5sum "$target_path/$config_file")

                        # Compare the checksums to check if changes were made
                        if [[ "$original_checksum" != "$edited_checksum" ]]; then
                            source $target_path/$config_file
                            setupInstallVariables $app_name;
                            isSuccessful "Changes have been made to the $config_file."
                        fi
                        break
                        ;;
                    [nN])
                        break  # Exit the loop without updating
                        ;;
                    *)
                        isNotice "Please provide a valid input (y or n)."
                        ;;
                esac
            done
        fi
    fi

    scanFileForRandomPassword "$target_path/$config_file";
    sourceScanFiles "app_configs";
}
