#!/bin/bash

checkSSHRemoteRequirement()
{  
	if [[ $CFG_REQUIREMENT_SSHREMOTE == "true" ]]; then
		### Custom SSH Remote Install
		# Check if the hosts line is empty or not found in the config file
		ssh_hosts_line=$(sudo grep  '^CFG_IPS_SSH_SETUP=' $configs_dir$config_file_general)
		if [ -n "$ssh_hosts_line" ]; then
			ssh_hosts=${ssh_hosts_line#*=}
			ip_found=0
			# Split the comma-separated IP addresses into an array
			IFS=',' read -ra ip_addresses <<< "$ssh_hosts"
			# Loop through the IP addresses
			for ip in "${ip_addresses[@]}"; do
				ip_found=1
			done

			if [ "$ip_found" -eq 0 ]; then
				isSuccessful "No for Remote SSH Install IP has been found to setup"
			else
				isSuccessful "Remote SSH Install IP(s) have been found to setup"
				setupSSHRemoteKeys=true
				((preinstallneeded++)) 
			fi
		else
			isSuccessful "No hosts found in the config file."
		fi
	fi
} 