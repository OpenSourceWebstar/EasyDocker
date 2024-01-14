#!/bin/bash

shutdownApp()
{
    local app_name="$1"
    echo ""
    echo "##########################################"
    echo "###      Shutting down $app_name"
    echo "##########################################"
    echo ""

    dockerDownShutdown $app_name;
            
    sleep 3s
    cd
}

dockerDownShutdown()
{
    local app_name="$1"
    if [ -e $containers_dir$app_name/docker-compose.yml ]; then
        if [[ "$OS" == [1234567] ]]; then
            if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose down")
                isSuccessful "Shutting down container for $app_name"
            elif [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
                local result=$(cd $containers_dir$app_name && sudo docker-compose down)
                isSuccessful "Shutting down container for $app_name"
            fi
        fi
        dockerDownShutdownSuccessMessage $app_name;
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