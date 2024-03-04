#!/bin/bash

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
