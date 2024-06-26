#!/bin/bash

checkSSHKeysRequirement()
{  
	# SSH Keys
	if [[ $CFG_REQUIREMENT_SSHKEY_ROOT == "true" ]]; then
		if checkSSHSetupKeyPair "root"; then
			isSuccessful "The SSH Key(s) for root appears to be setup."
		else
			isNotice "An SSH Key for root is not setup."
			SSHKEY_SETUP_NEEDED="true"
			((preinstallneeded++))
		fi
	fi
	if [[ $CFG_REQUIREMENT_SSHKEY_EASYDOCKER == "true" ]]; then
		if checkSSHSetupKeyPair "$sudo_user_name"; then
			isSuccessful "The SSH Key(s) for $sudo_user_name appears to be setup."
		else
			isNotice "An SSH Key for $sudo_user_name is not setup."
			SSHKEY_SETUP_NEEDED="true"
			((preinstallneeded++))
		fi
	fi
	if [[ $CFG_REQUIREMENT_SSHKEY_DOCKERINSTALL == "true" ]]; then
		if [[ "$CFG_DOCKER_INSTALL_TYPE" == "rootless" ]]; then
			if checkSSHSetupKeyPair "$CFG_DOCKER_INSTALL_USER"; then
				isSuccessful "The SSH Key(s) for $CFG_DOCKER_INSTALL_USER appears to be setup."
			else
				isNotice "An SSH Key for $CFG_DOCKER_INSTALL_USER is not setup."
				SSHKEY_SETUP_NEEDED="true"
				((preinstallneeded++))
			fi
		fi
	fi
} 