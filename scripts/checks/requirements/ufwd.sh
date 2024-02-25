#!/bin/bash

checkUFWDRequirement()
{  
	if [[ $CFG_REQUIREMENT_UFWD == "true" ]]; then
		if [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
			### UFW Docker
			if [[ "$ISUFWD" != *"command not found"* ]]; then
				isSuccessful "UFW-Docker Fix appears to be installed."
			else
				isNotice "UFW-Docker Fix does not appear to be installed. Setup will start soon."
				((preinstallneeded++)) 
			fi
		fi
	fi
} 