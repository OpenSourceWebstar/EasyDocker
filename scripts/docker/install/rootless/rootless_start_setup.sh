#!/bin/bash

installDockerRootlessStartSetup()
{
    if sudo grep -q "ROOTLESS" $sysctl; then
        isSuccessful "Docker Rootless appears to be installed."
    else
        installDockerRootless;
    fi
}
