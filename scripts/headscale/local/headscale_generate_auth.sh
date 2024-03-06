#!/bin/bash

setupHeadscaleGenerateAuthKey()
{
    headscale_preauthkey=""
    local temp_key_file="/docker/key.txt"

    local CFG_INSTALL_NAME=$(echo "$CFG_INSTALL_NAME" | tr '[:upper:]' '[:lower:]')
    dockerCommandRun "docker exec headscale headscale preauthkeys create -e 1h -u $CFG_INSTALL_NAME" > "$temp_key_file" 2>&1
    checkSuccess "Generating Auth Key in Headscale for $app_name"

    headscale_preauthkey=$(tr -d '\n' < "$temp_key_file")
    headscale_preauthkey_file="$temp_key_file"
}
