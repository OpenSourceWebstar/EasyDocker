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
        fi

        isSuccessful "Docker has been installed and configured."
    fi
}