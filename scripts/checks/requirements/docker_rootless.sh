#!/bin/bash

checkDockerRootlessRequirement()
{  
	if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
		### Docker Rootless
		if sudo grep -q "ROOTLESS" $sysctl; then
			isSuccessful "Docker Rootless appears to be installed."
		else
			isNotice "Docker Rootless does not appear to be installed. Setup will start soon."
			((preinstallneeded++)) 
		fi
	fi
} 