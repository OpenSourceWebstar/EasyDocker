#!/bin/bash

menuPublic()
{
	local port="$1"

	if [[ "$public" == "true" ]]; then
		echo "    Public : https://$host_setup/"
	fi
	if [[ "$port" != "" ]]; then
		local finalport="$1"
	else
		local finalport="$usedport1"
	fi
	
	echo "    External : http://$public_ip_v4:$finalport/"
	echo "    Local : http://$ip_setup:$finalport/"
	echo ""
}
