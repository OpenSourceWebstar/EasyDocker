#!/bin/bash

checkWireguardRequirement()
{  
	if [[ $CFG_REQUIREMENT_WIREGUARD == "true" ]]; then
		# Check if WireGuard is already installed and load params
		if [[ -e /etc/wireguard/params ]]; then
			isSuccessful "Wireguard is installed."
		else
			isNotice "Wireguard is not installed. Setup will start soon."
			((preinstallneeded++)) 
		fi
	fi
} 