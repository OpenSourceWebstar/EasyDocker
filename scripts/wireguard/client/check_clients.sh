#!/bin/bash

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
