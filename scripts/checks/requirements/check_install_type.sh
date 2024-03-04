#!/bin/bash

checkInstallTypeRequirement()
{  
	if [[ "$OS" == [1234567] ]]; then
		ISCOMP=$( (docker-compose -v ) 2>&1 )
		ISUFW=$( (sudo ufw status ) 2>&1 )
		ISUFWD=$( (sudo ufw-docker) 2>&1 )


		if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
			local ISUSER=$( (sudo id -u "$CFG_DOCKER_INSTALL_USER"))
			if [[ "$ISUSER" == *"no such user"* ]]; then
				ISACT=$(command -v docker &> /dev/null)
			fi
		elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
			ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
		fi
	fi
} 