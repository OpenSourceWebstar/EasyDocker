#!/bin/bash

checkDatabaseRequirement()
{  
	if [[ $CFG_REQUIREMENT_DATABASE == "true" ]]; then
		### Database file
		if [ -f "$docker_dir/$db_file" ] ; then
			isSuccessful "Installed Apps Database file found"
		else
			isNotice "Database file not found yet. Setup will start soon."
			((preinstallneeded++)) 
		fi
	fi
} 