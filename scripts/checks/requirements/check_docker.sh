#!/bin/bash

checkDockerRequirement()
{  
	if [[ $CFG_REQUIREMENT_DOCKER_CE == "true" ]]; then
		### Docker CE
		if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
			if [[ "$ISACT" != "/usr/bin/docker" ]]; then
				isSuccessful "Docker appears to be installed and running."
			else
				isNotice "Docker does not appear to be installed. Setup will start soon."
				((preinstallneeded++)) 
			fi
		elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
			if [[ "$ISACT" == "active" ]]; then
				isSuccessful "Docker appears to be installed and running."
			else
				isNotice "Docker does not appear to be installed. Setup will start soon."
				((preinstallneeded++)) 
			fi
		fi
	fi
} 