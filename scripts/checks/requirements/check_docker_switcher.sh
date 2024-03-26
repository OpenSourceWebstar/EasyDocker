#!/bin/bash

checkDockerSwitcherRequirement()
{  
	if [[ $CFG_REQUIREMENT_DOCKER_SWITCHER == "true" ]]; then
		    # Check if docker install type is different
		if [[ $CFG_DOCKER_INSTALL_TYPE != $docker_type ]]; then
			isSuccessful "Docker install appears to be setup correctly."
		else
			isNotice "Docker type does not appears to be matching the config. Switching..."
			((preinstallneeded++)) 
		fi
	fi
} 