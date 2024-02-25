#!/bin/bash

checkManagerRequirement()
{  
	if [[ $CFG_REQUIREMENT_MANAGER == "true" ]]; then
		### Docker Manager User Creation
		if userExists "$CFG_DOCKER_MANAGER_USER"; then
			isSuccessful "The Docker Manager User appears to be setup."
		else
			isNotice "The Docker Manager User is not setup."
			((preinstallneeded++)) 
		fi
	fi
} 