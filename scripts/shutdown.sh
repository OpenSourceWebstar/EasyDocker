#!/bin/bash

shutdownApp()
{
    local app_name="$1"
    local type="$2"

    echo ""
    echo "##########################################"
    echo "###      Shutting down $app_name"
    echo "##########################################"
    echo ""

    dockerDownShutdown $app_name $type;

    if [[ "$type" == "" ]]; then
        sleep 3s
    fi

    cd
}

dockerDownShutdown()
{
    local app_name="$1"
    local type="$2"

    if [[ "$OS" == [1234567] ]]; then
        if [[ "$type" == "" ]]; then
            # Used for standard app shutdown
            if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose down")
                isSuccessful "Shutting down container for $app_name"
                dockerDownShutdownSuccessMessage $app_name;
            elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
                local result=$(cd $containers_dir$app_name && sudo docker-compose down)
                isSuccessful "Shutting down container for $app_name"
                dockerDownShutdownSuccessMessage $app_name;
            fi
        else
            # Used for Shutting down Rooted type switcher
            if [[ $type == "rootless" ]]; then
                local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose down")
                isSuccessful "Shutting down container for $app_name"
                dockerDownShutdownSuccessMessage $app_name;
            elif [[ $type == "rooted" ]]; then
                local result=$(cd $containers_dir$app_name && sudo docker-compose down)
                isSuccessful "Shutting down container for $app_name"
                dockerDownShutdownSuccessMessage $app_name;
            fi
        fi
    fi
}

dockerDownShutdownSuccessMessage()
{
    local app_name="$1"
    echo ""
    isSuccessful "$app_name has been shutdown!"
    echo ""
}

dockerDownShutdownFailureMessage()
{
    local app_name="$1"
    echo ""
    isError "$app_name has not been found, unable to shutdown!"
    echo ""
}