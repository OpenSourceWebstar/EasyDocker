#!/bin/bash

menuLoginRequired()
{
	local app_name="$1"
	local username="$2"
	local password="$3"
	
	if [[ "$login_required" == "true" ]]; then
		echo ""
		echo "    Website Authentication is setup for $app_name."
		echo ""
		echo "    Your login username is : $CFG_LOGIN_USER"
		echo "    Your password is : $CFG_LOGIN_PASS"
		echo ""
		echo "    (you always find them in the EasyDocker general config under CFG_LOGIN_USER/PASS)"
	fi
	if [[ "$username" != "" ]]; then
		echo ""
		echo "    Application login details are as follows for $app_name."
		echo ""
		echo "    Your login username is : $username"
		echo "    Your password is : $password"
		echo ""
		echo "    (you always find them in the docker-compose file for $app_name)"
	fi
	echo ""
}
