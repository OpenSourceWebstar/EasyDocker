#!/bin/bash

installDockerRooted()
{
    # Check if Docker is already installed
    if [[ "$OS" == [1234567] ]]; then
        echo ""
        echo "##########################################"
        echo "###     Rooted Docker Installation     ###"
        echo "##########################################"
        echo ""
        if command -v docker &> /dev/null; then
            isSuccessful "Docker is already installed."
        else
            local result=$(sudo curl -fsSL https://get.docker.com | sh )
            checkSuccess "Downloading & Installing Docker"

            dockerServiceStart;

            while true; do
                echo ""
                isNotice "It's recommended to restart your system after installing Docker."
                echo ""
                isQuestion "Would you like to restart your system as recommended? (y/n): "
                read -p "" restart_after_docker_install
                if [[ -n "$restart_after_docker_install" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
            if [[ "$restart_after_docker_install" == [yY] ]]; then
                sudo reboot
            fi
            if [[ "$restart_after_docker_install" == [nN] ]]; then
                isNotice "Skipping reboot..."
            fi
        fi

        isSuccessful "Docker has been installed and configured."
    fi
}