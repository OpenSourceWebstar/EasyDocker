#!/bin/bash

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
