#!/bin/bash

checkUFWRequirement()
{  
	if [[ $CFG_REQUIREMENT_UFW == "true" ]]; then
		### UFW Firewall
		if [[ "$ISUFW" != *"command not found"* ]]; then
			isSuccessful "UFW Firewall appears to be installed."
		else
			isNotice "UFW Firewall does not appear to be installed. Setup will start soon."
			((preinstallneeded++)) 
		fi
	fi
} 