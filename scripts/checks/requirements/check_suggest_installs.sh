#!/bin/bash

checkSuggestInstallsRequirement()
{  
	if [[ $CFG_REQUIREMENT_SUGGEST_INSTALLS == "true" ]]; then
		local traefik_status=$(dockerCheckAppInstalled "traefik" "docker")
		local wireguard_status=$(dockerCheckAppInstalled "wireguard" "docker")
		if [[ "$traefik_status" == "installed" && "$wireguard_status" == "installed" ]]; then
			isSuccessful "All suggested applications are successfully set up."
		else
			isNotice "Traefik or Wireguard not installed. Setup will start soon."
			((preinstallneeded++))
		fi
	fi
} 