#!/bin/bash

checkDockerNetworkRequirement()
{  
	if [[ $CFG_REQUIREMENT_DOCKER_NETWORK == "true" ]]; then
		if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
			if dockerCommandRun "docker network inspect $CFG_NETWORK_NAME > /dev/null 2>&1"; then
				isSuccessful "Docker Network $CFG_NETWORK_NAME appears to be installed."
			else
				isNotice "Docker Network $CFG_NETWORK_NAME not found. Setup will start soon."
				DOCKER_NETWORK_SETUP_NEEDED="true"
				((preinstallneeded++)) 
			fi
		elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
			if docker network inspect $CFG_NETWORK_NAME > /dev/null 2>&1; then
				isSuccessful "Docker Network $CFG_NETWORK_NAME appears to be installed."
			else
				isNotice "Docker Network $CFG_NETWORK_NAME not found. Setup will start soon."
				DOCKER_NETWORK_SETUP_NEEDED="true"
				((preinstallneeded++)) 
			fi
		fi
	fi
}
