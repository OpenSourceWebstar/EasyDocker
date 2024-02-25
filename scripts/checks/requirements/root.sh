#!/bin/bash

checkRootRequirement()
{  
	if [[ $CFG_REQUIREMENT_ROOT == "true" ]]; then
		# Check if script is run as root
		if [[ $EUID -ne 0 ]]; then
			echo "This script must be run as root."
			exit 1
		else
			isSuccessful "Script ran under root user."
		fi
	fi
} 