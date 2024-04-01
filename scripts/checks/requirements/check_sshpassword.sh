#!/bin/bash

checkSSHPasswordRequirement()
{  
	if [[ $CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS == "true" ]]; then
		if grep -q "PasswordAuthentication no" $sshd_config; then
			isSuccessful "SSH Password appears to be disabled."
		else
			isNotice "Password Authentication has not been disabled."
			SSHKEY_DISABLE_PASS_NEEDED="true"
			((preinstallneeded++))
		fi
	fi
} 