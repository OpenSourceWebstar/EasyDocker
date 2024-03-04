#!/bin/bash

installDockerRooted()
{
    # Check if Docker is already installed
    if [[ "$OS" == [1234567] ]]; then
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