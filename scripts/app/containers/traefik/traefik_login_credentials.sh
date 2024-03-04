#!/bin/bash

traefikSetupLoginCredentials()
{
	local protectionauth_file="$containers_dir/traefik/etc/dynamic/middlewears/protectionauth.yml"
    if [ -f "$protectionauth_file" ]; then
		# Setup BasicAuth credentials
		local login_credentials=$(htpasswd -Bbn "$CFG_LOGIN_USER" "$CFG_LOGIN_PASS")

        local result=$(sudo sed -i '/#protection credentials/d' "$protectionauth_file")
        checkSuccess "Delete the line containing protection credentials"
        local result=$(sudo sed -i "/users:/a\\          - '$login_credentials' #protection credentials" "$protectionauth_file")
        checkSuccess "Add the new line with new protection credentials"
	fi
}