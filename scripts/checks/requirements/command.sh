#!/bin/bash

checkCommandRequirement()
{  
	if [[ $CFG_REQUIREMENT_COMMAND == "true" ]]; then
		# Custom command check
		if sudo grep -q "easydocker" ~/.bashrc; then
			isSuccessful "Custom command 'easydocker' installed."
		else
			checkSuccess "No custom command installed, did you run the init.sh first?"
			echo ""
			isNotice "Please run the following command:"
			isNotice "cd ~ && chmod 0755 init.sh && ./init.sh run && source ~/.bashrc && easydocker"
			echo ""
			isNotice "Exiting...."
			exit
		fi
	fi
} 