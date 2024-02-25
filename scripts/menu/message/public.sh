#!/bin/bash

menuPublic()
{
	if [[ "$public" == "true" ]]; then
		echo "    Public : https://$host_setup/"
	fi
	echo "    External : http://$public_ip_v4:$usedport1/"
	echo "    Local : http://$ip_setup:$usedport1/"
	echo ""
}
