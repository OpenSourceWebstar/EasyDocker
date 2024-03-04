#!/bin/bash

checkPasswordsRequirement()
{  
	if [[ $CFG_REQUIREMENT_PASSWORDS == "true" ]]; then
		### Password randomizer
		pass_found=0
		files_with_password=()

		for config_file in "$configs_dir"/*; do
			if [ -f "$config_file" ] && grep -q "RANDOMIZEDPASSWORD" "$config_file"; then
				files_with_password+=("$(basename "$config_file")")  # Get only the filename
				pass_found=1
			fi
		done

		if [ "$pass_found" -eq 0 ]; then
			isSuccessful "No passwords found to change."
		else
			isSuccessful "Passwords found to change in the following files:"
			isNotice "${files_with_password[*]}"  # Join the array elements with spaces
			((preinstallneeded++))
		fi
	fi
} 