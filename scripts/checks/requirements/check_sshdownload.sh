#!/bin/bash

checkSSHDownloadRequirement()
{  
    local sshdownload_status=$(dockerCheckAppInstalled "sshdownload" "docker")
    if [[ "$sshdownload_status" == "installed" ]]; then
        while true; do
            echo ""
            echo "##########################################"
            echo "###        SSH SECURITY WARNING        ###"
            echo "##########################################"
            echo ""
            isNotice "The SSH Download download service is currently online."
            isNotice "This is potentially DANGEROUS as it's accessable via anyone on the VPN"
            isNotice "We highly recommend uninstalling this service after downloading the SSH keys"
            isNotice "If you need to access this again, you can install it via the system install option"
            echo ""
            isQuestion "Would like to destroy the SSH Download service for security purposes? (y/n): "
            read -p "" ssh_download_uninstall
            if [[ -n "$ssh_download_uninstall" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$ssh_download_uninstall" == [yY] ]]; then
            dockerUninstallApp sshdownload;
        fi
    fi
} 