#!/bin/bash

checkInstallTypeRequirement()
{  
	if [[ "$OS" == [1234567] ]]; then
		ISCOMP=$( (docker-compose -v ) 2>&1 )
		ISUFW=$( (sudo ufw status ) 2>&1 )
		ISUFWD=$( (sudo ufw-docker) 2>&1 )

		if [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
			# Docker Type username
        	docker_install_user="$sudo_user_name"
			# Used for checking if rooted docket is active
			ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
		elif [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
			# Docker Type username
		    docker_install_user="$CFG_DOCKER_INSTALL_USER"
			# Used for checking the rootless user
			local ISUSER=$( (sudo id -u "$CFG_DOCKER_INSTALL_USER"))
			if [[ "$ISUSER" == *"no such user"* ]]; then
				ISACT=$(command -v docker &> /dev/null)
			fi
		fi
	fi
} 