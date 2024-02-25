#!/bin/bash

dockerSwitcherSetSocketPermissions()
{
    local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
    local docker_rootless_socket="/run/user/${docker_install_user_id}/docker.sock"
    local docker_rooted_socket="/var/run/docker.sock"

    echo ""
    echo "##########################################"
    echo "###        Docker Socket Checker       ###"
    echo "##########################################"
    echo ""

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        # if File exists
        if sudo test -e "$docker_rootless_socket"; then
            local result=$(sudo chmod o-r "$docker_rootless_socket")
            checkSuccess "Removing read permissions from Rootless docker socket."
            docker_rootless_found="true"
        else
            #isSuccessful "Rootless socket not found, no need to do anything with rootless setup."
            docker_rootless_found="false"
        fi

        # if File exists
        if sudo test -e "$docker_rooted_socket"; then
            local result=$(sudo chmod +r "$docker_rooted_socket")
            checkSuccess "Adding read permissions to Rooted docker socket."
            docker_rooted_found="true"
        else
            isNotice "Rooted socket not found, installation needed..."
            docker_rooted_found="false"
        fi
    fi

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        # if File exists
        if sudo test -e "$docker_rooted_socket"; then
            local result=$(sudo chmod o-r "$docker_rooted_socket")
            checkSuccess "Removing read permissions from Rooted docker socket."
            docker_rooted_found="true"
        else
            #isSuccessful "Rooted socket not found, no need to do anything with rooted setup."
            docker_rooted_found="false"
        fi

        # if File exists
        if sudo test -e "$docker_rootless_socket"; then
            local result=$(sudo chmod +r "$docker_rootless_socket")
            checkSuccess "Adding read permissions to Rootless docker socket."
            docker_rootless_found="true"
        else
            isNotice "Rootless socket not found, installation needed..."
            docker_rootless_found="false"
        fi
    fi
}

dockerSwitcherSwap()
{
    local flag="$1"
    local run_switcher="false"
    local docker_install_done="false"
    local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
    local docker_rootless_socket="/run/user/${docker_install_user_id}/docker.sock"
    local docker_rooted_socket="/var/run/docker.sock"

    dockerSwitcherSetSocketPermissions;

    # Select preexisting docker_type
    if [ -f "$docker_dir/$db_file" ]; then
        local docker_type=$(sudo sqlite3 "$docker_dir/$db_file" 'SELECT content FROM options WHERE option = "docker_type";')
        # Insert into DB if something doesnt exist
        if [[ $docker_type == "" ]]; then
            databaseOptionInsert "docker_type" $CFG_DOCKER_INSTALL_TYPE;
            local docker_type=$(sudo sqlite3 "$docker_dir/$db_file" 'SELECT content FROM options WHERE option = "docker_type";')
        fi
    else
        return;
    fi

    # Check if docker install type is different
    if [[ $CFG_DOCKER_INSTALL_TYPE != $docker_type ]]; then
        echo ""
        echo "##########################################"
        echo "###   Docker Root/Rootless Switcher    ###"
        echo "##########################################"
        echo ""

        if [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
            if [[ $flag != "cli" ]]; then
                isNotice "The current Docker Setup Type is currently : ${RED}$docker_type${NC}"
                echo ""
                while true; do
                    isQuestion "Would you like to switch to Rooted Docker? (y/n): "
                    echo ""
                    read -p "" switch_rooted_choice
                    if [[ -n "$switch_rooted_choice" ]]; then
                        break
                    fi
                    isNotice "Please provide a valid input."
                done
            else 
                switch_rooted_choice="y"
            fi
            if [[ "$switch_rooted_choice" == [yY] ]]; then
                isNotice "Switching to the Rooted Docker now..."
                # Looking at the Rootless Install
                if [[ $docker_rootless_found == "true" ]]; then
                    dockerComposeDownAllApps rootless;
                    dockerServiceStop rootless;
                fi
                if [[ $rootless_docker_failed_stop != "true" ]]; then
                    # Looking for Root install
                    if [[ $docker_root_found == "false" ]]; then
                        installDocker;
                    fi
                    dockerServiceStart root;
                    dockerSwitcherUpdateAppsToDockerType;
                    dockerStartAllApps;
                    databaseOptionInsert "docker_type" $CFG_DOCKER_INSTALL_TYPE;

                    if [[ "$CFG_REQUIREMENT_RESTART_PROMPT" == "false" ]]; then
                        isNotice "Restarting server now..."
                        sudo reboot
                    elif [[ "$CFG_REQUIREMENT_RESTART_PROMPT" == "true" ]]; then
                        isNotice "*** A restart is highly recommended after changing the Docker type ***"
                        echo ""
                        while true; do
                            isQuestion "Would you like to restart the server? (y/n): "
                            echo ""
                            read -p "" switch_rooted_restart_choice
                            if [[ -n "$switch_rooted_restart_choice" ]]; then
                                break
                            fi
                            isNotice "Please provide a valid input."
                        done
                        if [[ "$switch_rooted_restart_choice" == [yY] ]]; then
                            isNotice "Restarting server now..."
                            sudo reboot
                        fi
                    fi
                fi
            fi
        fi

        if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
            if [[ $flag != "cli" ]]; then
                isNotice "The current Docker Setup Type is currently : ${RED}$docker_type${NC}"
                echo ""
                while true; do
                    isQuestion "Would you like to switch to Rootless Docker? (y/n): "
                    echo ""
                    read -p "" switch_rootless_choice
                    if [[ -n "$switch_rootless_choice" ]]; then
                        break
                    fi
                    isNotice "Please provide a valid input."
                done
            else 
                switch_rootless_choice="y"
            fi
            if [[ "$switch_rootless_choice" == [yY] ]]; then
                isNotice "Switching to the Rootless Docker now..."
                # Looking at the Rooted Install
                if [[ $docker_rooted_found == "true" ]]; then
                    dockerComposeDownAllApps root;
                    dockerServiceStop root;
                fi
                dockerServiceStart rootless;
                dockerSwitcherUpdateAppsToDockerType;
                dockerStartAllApps;
                databaseOptionInsert "docker_type" $CFG_DOCKER_INSTALL_TYPE;

                if [[ "$CFG_REQUIREMENT_RESTART_PROMPT" == "false" ]]; then
                    isNotice "Restarting server now..."
                    sudo reboot
                elif [[ "$CFG_REQUIREMENT_RESTART_PROMPT" == "true" ]]; then
                    isNotice "*** A restart is highly recommended after changing the Docker type ***"
                    echo ""
                    while true; do
                        isQuestion "Would you like to restart the server? (y/n): "
                        echo ""
                        read -p "" switch_rootless_restart_choice
                        if [[ -n "$switch_rootless_restart_choice" ]]; then
                            break
                        fi
                        isNotice "Please provide a valid input."
                    done
                    if [[ "$switch_rootless_restart_choice" == [yY] ]]; then
                        isNotice "Restarting server now..."
                        sudo reboot
                    fi
                fi
            fi
        fi
    elif [[ $flag == "cli" ]]; then
        isSuccessful "Docker type is already setup for "$CFG_DOCKER_INSTALL_TYPE" no changes needed..."
    fi
}

dockerSwitcherScanContainersForSocket() 
{
    local directory="$1"
    local type="$2"
    local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
    local header_sent="false"

    for file in "$directory"/*; do
        if [ -f "$file" ]; then
            if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                if grep -q "/var/run/docker.sock" "$file"; then
                    if [[ $header_sent == "false" ]]; then
                        echo ""
                        echo "##########################################"
                        echo "###      Docker App Type Switcher      ###"
                        echo "##########################################"
                        echo ""
                        local header_sent="true"
                    fi
                    isSuccessful "Found Docker socket to change in file: $file"
                    result=$(sudo sed -i -e "s|/var/run/docker.sock|/run/user/${docker_install_user_id}/docker.sock|g" "$file")
                    checkSuccess "Updated socket in file: $file"
                    docker_socket_file_updated="true"
                fi
            elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
                if grep -q "/run/user/${docker_install_user_id}/docker.sock" "$file"; then
                    if [[ $header_sent == "false" ]]; then
                        echo ""
                        echo "##########################################"
                        echo "###      Docker App Type Switcher      ###"
                        echo "##########################################"
                        echo ""
                        local header_sent="true"
                    fi
                    isSuccessful "Found Docker socket to change in file: $file"
                    result=$(sudo sed -i -e "s|/run/user/${docker_install_user_id}/docker.sock|/var/run/docker.sock|g" "$file")
                    checkSuccess "Updated file: $file"
                    docker_socket_file_updated="true"
                fi
            fi
        fi
    done
}

dockerSwitcherUpdateAppsToDockerType()
{
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        # Scannning the containers folder
        local subdirectories=($(find "$containers_dir" -maxdepth 1 -type d))
        for dir in "${subdirectories[@]}"; do
            dockerSwitcherScanContainersForSocket "$dir"
            if [[ $docker_socket_file_updated == "true" ]]; then
                dockerRestartApp $(basename $dir);
            fi
            docker_socket_file_updated="false"
        done
    fi

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        # Scannning the containers folder
        local subdirectories=($(find "$containers_dir" -maxdepth 1 -type d))
        for dir in "${subdirectories[@]}"; do
            dockerSwitcherScanContainersForSocket "$dir"
            if [[ $docker_socket_file_updated == "true" ]]; then
                dockerRestartApp $(basename $dir);
            fi
            docker_socket_file_updated="false"
        done
    fi
}
