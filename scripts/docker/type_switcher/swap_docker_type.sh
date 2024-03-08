#!/bin/bash


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
                    dockerSwitcherUpdateContainersToDockerType;
                    dockerStartAllApps;
                    databaseOptionInsert "docker_type" $CFG_DOCKER_INSTALL_TYPE;
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
                dockerSwitcherUpdateContainersToDockerType;
                dockerStartAllApps;
                databaseOptionInsert "docker_type" $CFG_DOCKER_INSTALL_TYPE;
            fi
        fi
    elif [[ $flag == "cli" ]]; then
        isSuccessful "Docker type is already setup for "$CFG_DOCKER_INSTALL_TYPE" no changes needed..."
    fi
}
