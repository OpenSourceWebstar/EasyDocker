#!/bin/bash

checkCrontabRequirement()
{  
	if [[ $CFG_REQUIREMENT_CRONTAB == "true" ]]; then
		### Crontab
		if [[ "$ISCRON" != *"command not found"* ]] && sudo -u $sudo_user_name crontab -l 2>/dev/null | grep -q "cron is set up for $sudo_user_name"; then
			isSuccessful "Crontab is successfully set up."
			CRONTAB_SETUP="true"
		else
			isNotice "Crontab not installed. Setup will start soon."
			CRONTAB_SETUP="false"
			((preinstallneeded++))
		fi
	fi
} 