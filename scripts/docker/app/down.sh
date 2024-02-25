#!/bin/bash

dockerComposeDown()
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
    echo "###     Docker Compose down $app_name"
    echo "##########################################"
    echo ""

    # Make sure we are able to get the compose file
    if [[ $compose_setup == "" ]]; then
        setupScanVariables $app_name;
    fi

    # Compose file public variable for restarting etc
    if [[ $compose_setup == "default" ]]; then
        local setup_compose="-f docker-compose.yml"
    elif [[ $compose_setup == "app" ]]; then
        local setup_compose="-f docker-compose.yml -f docker-compose.$app_name.yml"
    fi
    if [[ $custom_compose != "" ]]; then
        local setup_compose="-f docker-compose.yml -f $custom_compose"
    fi

    if [[ "$OS" == [1234567] ]]; then
        if [ -f "$containers_dir$app_name/$setup_compose" ]; then
            # Used for the standard EasyDocker app
            if [[ "$type" == "" ]]; then
                if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                    local result=$(dockerCommandRunInstallUser "cd $containers_dir$app_name && docker-compose $setup_compose down")
                    checkSuccess "Shutting down container for $app_name"
                elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
                    local result=$(cd $containers_dir$app_name && sudo docker-compose $setup_compose down)
                    checkSuccess "Shutting down container for $app_name"
                fi
            # Used for the CLI dockertype switcher.
            else
                if [[ $type == "rootless" ]]; then
                    local result=$(dockerCommandRunInstallUser "cd $containers_dir$app_name && docker-compose $setup_compose down")
                    checkSuccess "Shutting down container for $app_name"
                elif [[ $type == "rooted" ]]; then
                    local result=$(cd $containers_dir$app_name && sudo docker-compose $setup_compose down)
                    checkSuccess "Shutting down container for $app_name"
                fi
            fi
        else
        isNotice "Unable to find the compose file to docker-compose down this application."
    fi
}

dockerComposeDownAllApps()
{
    local type="$1"
    local subdirectories=($(find "$containers_dir" -mindepth 1 -maxdepth 1 -type d))

    for dir in "${subdirectories[@]}"; do
        local app_name=$(basename $dir)
        dockerComposeDown $app_name "" $type;
    done
}
