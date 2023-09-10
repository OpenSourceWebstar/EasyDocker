#!/bin/bash

app_name="$1"

shutdownApp()
{
    echo ""
    echo "##########################################"
    echo "###      Shutting down $app_name"
    echo "##########################################"
    echo ""

    dockerDownShutdown;
            
    sleep 3s
    cd
}

dockerDownShutdown()
{
    cd $install_path$app_name

    if [ -e $install_path$app_name/docker-compose.yml ]; then
        if [[ "$OS" == [123] ]]; then
            if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
                result=$(runCommandForDockerInstallUser "docker-compose down")
                isSuccessful "Shutting down container for $app_name"
            elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
                result=$(sudo docker-compose down)
                isSuccessful "Shutting down container for $app_name"
            fi
        fi
        dockerDownShutdownSuccessMessage;
    fi
}

dockerDownShutdownSuccessMessage()
{
        echo ""
        isSuccessful "$app_name has been shutdown!"
        echo ""
}

dockerDownShutdownFailureMessage()
{
        echo ""
        isError "$app_name has not been found, unable to shutdown!"
        echo ""
}