#!/bin/bash

checkSwapfileRequirement()
{  
	if [[ $CFG_REQUIREMENT_SWAPFILE == "true" ]]; then
		### Swap file
		if [ -f "$swap_file" ]; then
			isSuccessful "Swapfile appears to be installed."
		else
			isNotice "Swapfile does not appears to be installed."
			((preinstallneeded++)) 
		fi
	fi
} 