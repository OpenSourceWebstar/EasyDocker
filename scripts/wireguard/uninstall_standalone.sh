#!/bin/bash

wireguardUninstall() 
{
    echo ""
    echo "#####################################"
    echo "###     Wireguard Uninstaller     ###"
    echo "#####################################"
    echo ""
    isNotice "***WARNING*** This will uninstall WireGuard and remove all the configuration files!"
    isNotice "Please backup the /etc/wireguard directory if you want to keep your configuration files."
    echo ""
    isQuestion "Do you really want to remove WireGuard? (y/n): "
    read -p "" WIREGUARD_REMOVE
    
    if [[ $WIREGUARD_REMOVE == [yY] ]]; then
        if [[ "$OS" == [1234567] ]]; then
            result=$(sudo systemctl stop "wg-quick@${CFG_WG_SERVER_NIC}")
            checkSuccess "Stopped wg-quick@${CFG_WG_SERVER_NIC} service."

            result=$(sudo systemctl disable "wg-quick@${CFG_WG_SERVER_NIC}")
            checkSuccess "Disabled wg-quick@${CFG_WG_SERVER_NIC} service."

            if [[ "$OS" == [1234567] ]]; then
                result=$(sudo apt-get remove -y wireguard wireguard-tools qrencode)
                checkSuccess "Removed wireguard wireguard-tools qrencode"
            fi

            result=$(sudo rm -rf /etc/wireguard)
            checkSuccess "Deleted /etc/wireguard folder."
            result=$(sudo rm -f /etc/sysctl.d/wg.conf)
            checkSuccess "Delete /etc/sysctl.d/wg.conf file."

            result=$(sudo sysctl --system)
            checkSuccess "Reloaded sysctl"

            portUnuse wireguardstandalone $CFG_WG_SERVER_PORT install;
            portClose wireguardstandalone $CFG_WG_SERVER_PORT/udp install;

            # Check if WireGuard is running
            systemctl is-active --quiet "wg-quick@${CFG_WG_SERVER_NIC}"
            WIREGUARD_RUNNING=$?

            if [[ ${WIREGUARD_RUNNING} -eq 0 ]]; then
                isError "WireGuard failed to uninstall properly."
                wireguardManageMenu;
            else
                isSuccessful "WireGuard uninstalled successfully."
                wireguardManageMenu;
            fi
        fi
    else
        echo ""
        isNotice "Removal aborted!"
    fi
}
