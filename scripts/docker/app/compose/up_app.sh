#!/bin/bash

dockerComposeUp()
{
    local app_name="$1"
    local custom_compose="$2"
    local type="$3"

    if [[ "$app_name" == "" ]]; then
        isError "Something went wrong...No app name provided..."
        return
    fi

    echo ""
    echo "##########################################"
    echo "###     Docker Compose Up $app_name"
    echo "##########################################"
    echo ""

    # Make sure we are able to get the compose file
    if [[ $compose_setup == "" ]]; then
        setupBasicScanVariables "$app_name"
    fi
    
    # Compose file public variable for restarting etc
    if [[ $compose_setup == "default" ]]; then
        local setup_compose="-f docker-compose.yml"
        local compose_file="docker-compose.yml"
    elif [[ $compose_setup == "app" ]]; then
        local setup_compose="-f docker-compose.yml -f docker-compose.$app_name.yml"
        local compose_file="docker-compose.$app_name.yml"
    fi
    if [[ $custom_compose != "" ]]; then
        local setup_compose="-f docker-compose.yml -f $custom_compose"
        local compose_file="$custom_compose"
    fi

    if [[ "$OS_TYPE" == "Ubuntu" || "$OS_TYPE" == "Debian" ]]; then
        if [ -f "$containers_dir$app_name/$compose_file" ]; then
            # Used for the standard EasyDocker app
            if [[ "$type" == "" ]]; then
                if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                    isNotice "Starting container for $app_name, this may take a while..."
                    local result=$(dockerCommandRunInstallUser "cd $containers_dir$app_name && docker-compose $setup_compose up -d")
                    checkSuccess "Started container for $app_name"
                elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
                    isNotice "Starting container for $app_name, this may take a while..."
                    local result=$(cd "$containers_dir$app_name" && sudo docker-compose $setup_compose up -d)
                    checkSuccess "Started container for $app_name"
                fi
            # Used for the CLI dockertype switcher.
            else
                if [[ $type == "rootless" ]]; then
                    local result=$(dockerCommandRunInstallUser "cd $containers_dir$app_name && docker-compose $setup_compose down")
                    checkSuccess "Shutting down container for $app_name"
                elif [[ $type == "rooted" ]]; then
                    local result=$(cd "$containers_dir$app_name" && sudo docker-compose $setup_compose down)
                    checkSuccess "Shutting down container for $app_name"
                fi
            fi
        else
            isNotice "Unable to find the compose file to docker-compose up this application."
        fi
    fi
}
