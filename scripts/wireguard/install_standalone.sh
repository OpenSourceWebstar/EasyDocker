#!/bin/bash

# Secure WireGuard server installer
# Adapted from : https://github.com/angristan/wireguard-install

installStandaloneWireGuard() 
{
    if [[ $CFG_REQUIREMENT_WIREGUARD == "true" ]]; then
        # Check if WireGuard is already installed and load params
        if [[ ! -e /etc/wireguard/params ]]; then
            echo ""
            echo "############################################"
            echo "######       Wireguard Installer      ######"
            echo "############################################"
            echo ""
            echo "Based on : https://github.com/angristan/wireguard-install"
            echo ""

            local WG_CAN_INSTALL="true"
            local WG_CHECK_VIRTUALIZATION=$(systemd-detect-virt)

            if [ "$WG_CHECK_VIRTUALIZATION" == "openvz" ]; then
                echo "OpenVZ is not supported"
                local WG_CAN_INSTALL="false"
            fi

            if [ "$WG_CHECK_VIRTUALIZATION" == "lxc" ]; then
                echo "LXC is not supported (yet)."
                echo "WireGuard can technically run in an LXC container,"
                echo "but the kernel module has to be installed on the host,"
                echo "the container has to be run with some specific parameters"
                echo "and only the tools need to be installed in the container."
                local WG_CAN_INSTALL="false"
            fi

            if [[ $WG_CAN_INSTALL == 'true' ]]; then

                # Install WireGuard tools and module
                if [[ "$OS_TYPE" == "Ubuntu" || "$OS_TYPE" == "Debian" ]]; then
                    sudo apt-get install -y wireguard iptables resolvconf qrencode

                    # Update DNS after installing resolvconf
                    updateDNS "" standalonewireguard;

                    # Check if the directory exists; if not, create it
                    if [ ! -d "/etc/wireguard" ]; then
                        result=$(sudo mkdir /etc/wireguard)
                        checkSuccess "Created the WireGuard folder"
                    fi

                    result=$(sudo chmod 600 -R /etc/wireguard/)
                    checkSuccess "Updated permissions for /etc/wireguard"

                    local SERVER_PRIV_KEY=$(wg genkey)
                    local SERVER_PUB_KEY=$(echo "${SERVER_PRIV_KEY}" | wg pubkey)

                    # Save WireGuard settings
                    echo "SERVER_PUB_IP=${public_ip_v4}
SERVER_PUB_NIC=${server_nic}
SERVER_WG_NIC=${CFG_WG_SERVER_NIC}
SERVER_WG_IPV4=${CFG_WG_SERVER_IPV4}
SERVER_PORT=${CFG_WG_SERVER_PORT}
SERVER_PRIV_KEY=${SERVER_PRIV_KEY}
SERVER_PUB_KEY=${SERVER_PUB_KEY}
CLIENT_DNS_1=${CFG_DNS_SERVER_1}
CLIENT_DNS_2=${CFG_DNS_SERVER_2}
ALLOWED_IPS=${CFG_WG_ALLOWED_IPS}" | sudo tee /etc/wireguard/params >/dev/null

                    result=$(sudo chmod 644 /etc/wireguard/params)
                    checkSuccess "Updating permissions for /etc/wireguard/params"

                    # Add server interface
                    echo "[Interface]
Address = ${CFG_WG_SERVER_IPV4}/32
ListenPort = ${CFG_WG_SERVER_PORT}
PrivateKey = ${SERVER_PRIV_KEY}" | sudo tee "/etc/wireguard/${CFG_WG_SERVER_NIC}.conf" >/dev/null

                    echo "PostUp = iptables -I INPUT -p udp --dport ${CFG_WG_SERVER_PORT} -j ACCEPT
PostUp = iptables -I FORWARD -i ${server_nic} -o ${CFG_WG_SERVER_NIC} -j ACCEPT
PostUp = iptables -I FORWARD -i ${CFG_WG_SERVER_NIC} -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o ${server_nic} -j MASQUERADE
PostDown = iptables -D INPUT -p udp --dport ${CFG_WG_SERVER_PORT} -j ACCEPT
PostDown = iptables -D FORWARD -i ${server_nic} -o ${CFG_WG_SERVER_NIC} -j ACCEPT
PostDown = iptables -D FORWARD -i ${CFG_WG_SERVER_NIC} -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o ${server_nic} -j MASQUERADE" | sudo tee -a "/etc/wireguard/${CFG_WG_SERVER_NIC}.conf" >/dev/null

                    result=$(sudo chmod 644 /etc/wireguard/${CFG_WG_SERVER_NIC}.conf)
                    checkSuccess "Updating permissions for /etc/wireguard/${CFG_WG_SERVER_NIC}.conf"

                    result=$(sudo sed -i '/^net.ipv4.ip_forward/d' /etc/sysctl.conf)
                    checkSuccess "Removing all instances of net.ipv4.ip_forward from sysctl.conf"

                    local result=$(echo '# WIREGUARD START' | sudo tee -a "$sysctl" > /dev/null)
                    checkSuccess "Adding wireguard header to sysctl"

                    result=$(echo "net.ipv4.ip_forward = 1" | sudo tee -a $sysctl)
                    checkSuccess "Add the configuration for IPv4 IP forwarding"

                    local result=$(echo '# WIREGUARD END' | sudo tee -a "$sysctl" > /dev/null)
                    checkSuccess "Adding wireguard header to sysctl"

                    result=$(sudo systemctl start "wg-quick@${CFG_WG_SERVER_NIC}")
                    checkSuccess "Started wg-quick@${CFG_WG_SERVER_NIC} service."
                    result=$(sudo systemctl enable "wg-quick@${CFG_WG_SERVER_NIC}")
                    checkSuccess "Enabled wg-quick@${CFG_WG_SERVER_NIC} service."

                    result=$(sudo sysctl --system)
                    checkSuccess "Reloaded sysctl"

                    portUse wireguardstandalone $CFG_WG_SERVER_PORT install;
                    portOpenwireguardstandalone $CFG_WG_SERVER_PORT/udp install;

                    wireguardNewClient install;

                    # Check if WireGuard is running
                    systemctl is-active --quiet "wg-quick@${CFG_WG_SERVER_NIC}"
                    WIREGUARD_RUNNING=$?

                    # WireGuard might not work if we updated the kernel. Tell the user to reboot
                    if [[ ${WIREGUARD_RUNNING} -ne 0 ]]; then
                        isNotice "***WARNING*** WireGuard does not seem to be running."
                        isNotice "You can check if WireGuard is running with: systemctl status wg-quick@${CFG_WG_SERVER_NIC}${NC}"
                        isNotice "If you get something like 'Cannot find device ${CFG_WG_SERVER_NIC}', please reboot!"
                    else # WireGuard is running
                        isSuccessful "WireGuard is running."
                        isSuccessful "You can check the status of WireGuard with: systemctl status wg-quick@${CFG_WG_SERVER_NIC}"
                        isNotice "If you don't have internet connectivity from your client, try to reboot the server."
                    fi
                fi
            fi
        #else
            #isNotice "Wireguard is already installed, no need to install."
        fi
    fi
}

wireguardNewClient() 
{
    local type="$1"

    echo ""
    echo "#####################################"
    echo "###   Wireguard Client Creation   ###"
    echo "#####################################"
    echo ""
    isNotice "The client name must consist of alphanumeric character(s)."
    isNotice "It may also include underscores or dashes and can't exceed 15 chars."
    echo ""

    until [[ ${WIREGUARD_CLIENT_NAME} =~ ^[a-zA-Z0-9_-]+$ && ${WIREGUARD_CLIENT_EXISTS} == '0' && ${#WIREGUARD_CLIENT_NAME} -lt 16 ]]; do
        if [[ $type == "install" ]]; then
            WIREGUARD_CLIENT_NAME="$CFG_WG_DEFAULT_CLIENT"
        else
            read -rp "Client name: " -e WIREGUARD_CLIENT_NAME
        fi
        local WIREGUARD_CLIENT_EXISTS=$(sudo grep -c -E "^### Client ${WIREGUARD_CLIENT_NAME}\$" "/etc/wireguard/${CFG_WG_SERVER_NIC}.conf")

        if [[ ${WIREGUARD_CLIENT_EXISTS} != 0 ]]; then
            echo ""
            isNotice "A client with the specified name was already created, please choose another name."
            echo ""
        fi
    done

    for WIREGUARD_DOT_IP in {2..254}; do
        local WIREGUARD_DOT_EXISTS=$(sudo grep -c "${CFG_WG_SERVER_IPV4::-1}${WIREGUARD_DOT_IP}" "/etc/wireguard/${CFG_WG_SERVER_NIC}.conf")
        if [[ ${WIREGUARD_DOT_EXISTS} == '0' ]]; then
            break
        fi
    done

    if [[ ${WIREGUARD_DOT_EXISTS} == '1' ]]; then
        echo ""
        isNotice "The subnet configured supports only 253 clients."
        echo ""
    fi

    # Generate key pair for the client
    local WIREGUARD_CLIENT_PRIV_KEY=$(sudo wg genkey)
    local WIREGUARD_CLIENT_PUB_KEY=$(echo "${WIREGUARD_CLIENT_PRIV_KEY}" | sudo wg pubkey)
    local WIREGUARD_CLIENT_PRE_SHARED_KEY=$(sudo wg genpsk)
    local WIREGUARD_ENDPOINT="${public_ip_v4}:${CFG_WG_SERVER_PORT}"

    # Create client file
    createTouch "${CFG_WG_HOME_DIR}/${CFG_WG_SERVER_NIC}-client-${WIREGUARD_CLIENT_NAME}.conf" $sudo_user_name
    
    # Create client file and add the server as a peer
    echo "[Interface]
PrivateKey = ${WIREGUARD_CLIENT_PRIV_KEY}
Address = ${CFG_WG_SERVER_IPV4}/32
DNS = ${CFG_DNS_SERVER_1},${CFG_DNS_SERVER_2}

[Peer]
PublicKey = ${SERVER_PUB_KEY}
PresharedKey = ${WIREGUARD_CLIENT_PRE_SHARED_KEY}
Endpoint = ${WIREGUARD_ENDPOINT}
AllowedIPs = ${CFG_WG_ALLOWED_IPS}" | sudo tee "${CFG_WG_HOME_DIR}/${CFG_WG_SERVER_NIC}-client-${WIREGUARD_CLIENT_NAME}.conf" >/dev/null

    # Add the client as a peer to the server
    echo -e "\n### Client ${WIREGUARD_CLIENT_NAME}
[Peer]
PublicKey = ${WIREGUARD_CLIENT_PUB_KEY}
PresharedKey = ${WIREGUARD_CLIENT_PRE_SHARED_KEY}
AllowedIPs = ${CFG_WG_ALLOWED_IPS}" | sudo tee -a "/etc/wireguard/${CFG_WG_SERVER_NIC}.conf" >/dev/null

    #result=$(sudo wg syncconf ${CFG_WG_SERVER_NIC} /etc/wireguard/${CFG_WG_SERVER_NIC}.conf)
    #checkSuccess "Syncing config file for $CFG_WG_SERVER_NIC"

    #result=$(sudo systemctl stop "wg-quick@${CFG_WG_SERVER_NIC}")
    #checkSuccess "Stopped wg-quick@${CFG_WG_SERVER_NIC} service."
    #result=$(sudo systemctl start "wg-quick@${CFG_WG_SERVER_NIC}")
    #checkSuccess "Started wg-quick@${CFG_WG_SERVER_NIC} service."

    # Generate QR code if qrencode is installed
    if command -v qrencode &>/dev/null; then
        isNotice "Here is your client config file as a QR Code:"
        sudo qrencode -t ansiutf8 -l L <"${CFG_WG_HOME_DIR}/${CFG_WG_SERVER_NIC}-client-${WIREGUARD_CLIENT_NAME}.conf"
        echo ""
    fi

    isSuccessful "Your client config file is in ${CFG_WG_HOME_DIR}/${CFG_WG_SERVER_NIC}-client-${WIREGUARD_CLIENT_NAME}.conf"
}

wireguardListClients() 
{
    echo ""
    echo "#####################################"
    echo "###     Wireguard Client List     ###"
    echo "#####################################"
    echo ""

    wireguardCheckClients;

    sudo grep -E "^### Client" "/etc/wireguard/${CFG_WG_SERVER_NIC}.conf" | cut -d ' ' -f 3 | nl -s ') '
}

wireguardRevokeClient()
{
    echo ""
    echo "#####################################"
    echo "###   Wireguard Client Removal    ###"
    echo "#####################################"
    echo ""

    wireguardCheckClients;

    echo ""
    echo "Select the existing client you want to revoke"
    sudo grep -E "^### Client" "/etc/wireguard/${CFG_WG_SERVER_NIC}.conf" | cut -d ' ' -f 3 | nl -s ') '
    until [[ ${WIREGUARD_CLIENT_NUMBER} -ge 1 && ${WIREGUARD_CLIENT_NUMBER} -le ${WIREGUARD_NUMBER_OF_CLIENTS} ]]; do
        if [[ ${WIREGUARD_CLIENT_NUMBER} == '1' ]]; then
            read -rp "Select one client [1]: " WIREGUARD_CLIENT_NUMBER
        else
            read -rp "Select one client [1-${WIREGUARD_NUMBER_OF_CLIENTS}]: " WIREGUARD_CLIENT_NUMBER
        fi
    done

    # match the selected number to a client name
    local WIREGUARD_CLIENT_NAME=$(sudo grep -E "^### Client" "/etc/wireguard/${CFG_WG_SERVER_NIC}.conf" | cut -d ' ' -f 3 | sed -n "${WIREGUARD_CLIENT_NUMBER}"p)

    result=$(sudo sed -i "/^### Client ${WIREGUARD_CLIENT_NAME}\$/,/^$/d" "/etc/wireguard/${CFG_WG_SERVER_NIC}.conf")
    checkSuccess "Removed [Peer] block matching $WIREGUARD_CLIENT_NAME"

    result=$(sudo rm -f "${CFG_WG_HOME_DIR}/${CFG_WG_SERVER_NIC}-client-${WIREGUARD_CLIENT_NAME}.conf")
    checkSuccess "Removed generated client file for $WIREGUARD_CLIENT_NAME"

    result=$(sudo wg syncconf "${CFG_WG_SERVER_NIC}" <(sudo wg-quick strip "${CFG_WG_SERVER_NIC}"))
    checkSuccess "Restart wireguard to apply changes"
}

wireguardCheckClients() 
{
	local WIREGUARD_NUMBER_OF_CLIENTS=$(grep -c -E "^### Client" "/etc/wireguard/${CFG_WG_SERVER_NIC}.conf")
	if [[ ${WIREGUARD_NUMBER_OF_CLIENTS} == '0' ]]; then
		echo ""
		isError "You have no existing clients!"
        echo ""
		wireguardManageMenu;
	fi
}

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
        if [[ "$OS_TYPE" == "Ubuntu" || "$OS_TYPE" == "Debian" ]]; then
            result=$(sudo systemctl stop "wg-quick@${CFG_WG_SERVER_NIC}")
            checkSuccess "Stopped wg-quick@${CFG_WG_SERVER_NIC} service."

            result=$(sudo systemctl disable "wg-quick@${CFG_WG_SERVER_NIC}")
            checkSuccess "Disabled wg-quick@${CFG_WG_SERVER_NIC} service."

            if [[ "$OS_TYPE" == "Ubuntu" || "$OS_TYPE" == "Debian" ]]; then
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
