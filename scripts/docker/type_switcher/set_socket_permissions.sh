#!/bin/bash

dockerSwitcherSetSocketPermissions()
{
    # Check if rootless isnt needed
    if id "$CFG_DOCKER_INSTALL_USER" &>/dev/null; then
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        local docker_rootless_socket="/run/user/${docker_install_user_id}/docker.sock"
        local docker_rootless_exist="true"
    else
        local docker_rootless_exist="false"
    fi

    echo ""
    echo "##########################################"
    echo "###        Docker Socket Checker       ###"
    echo "##########################################"
    echo ""

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        if [[ $docker_rootless_exist == "false" ]]; then
            # if File exists
            if sudo test -e "$docker_rootless_socket"; then
                local result=$(sudo chmod o-r "$docker_rootless_socket")
                checkSuccess "Removing read permissions from Rootless docker socket."
                docker_rootless_found="true"
            else
                #isSuccessful "Rootless socket not found, no need to do anything with rootless setup."
                docker_rootless_found="false"
            fi
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
