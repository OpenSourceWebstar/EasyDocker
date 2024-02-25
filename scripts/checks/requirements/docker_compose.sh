#!/bin/bash

checkDockerComposeRequirement()
{  
	if [[ $CFG_REQUIREMENT_DOCKER_COMPOSE == "true" ]]; then
		### Docker Compose
		if [[ "$ISCOMP" != *"command not found"* ]]; then
			isSuccessful "Docker-compose appears to be installed."
		else
			isNotice "Docker-compose does not appear to be installed. Setup will start soon."
			((preinstallneeded++)) 
		fi
	fi
} 