#!/bin/bash

menuContinue()
{
	if [[ "$public" == "CFG_REQUIREMENT_CONTINUE_PROMPT" ]]; then
		while true; do
			isQuestion "Press Enter to continue or press (d) to disable being asked to continue after an app installs."
			read -p "" app_installed_continue
			if [[ -n "$app_installed_continue" ]]; then
				break
			fi
			isNotice "Please provide a valid input."
		done
		if [[ "$app_installed_continue" == [dD] ]]; then
			local config_file="$configs_dir$config_file_requirements"
			result=$(sudo sed -i 's/CFG_REQUIREMENT_CONTINUE_PROMPT=true/CFG_REQUIREMENT_CONTINUE_PROMPT=false/' $config_file)
			checkSuccess "Disabled CFG_REQUIREMENT_CONTINUE_PROMPT in the $config_file_requirements config."
			source $config_file
		fi
	fi
}
