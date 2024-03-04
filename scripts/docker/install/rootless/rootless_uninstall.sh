#!/bin/bash

# Currently unused
uninstallDockerRootless()
{
    echo ""
    echo "##########################################"
    echo "###     Uninstall Docker Rootless      ###"
    echo "##########################################"
    echo ""
    
    local result=$(dockerCommandRunInstallUser "dockerd-rootless-setuptool.sh uninstall")
    checkSuccess "Uninstalling Rootless docker."
}