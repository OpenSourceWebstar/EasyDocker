#!/bin/bash

setupHeadscaleLocalhost()
{
    local local_type="$1"
    if [[ "$local_type" == "local" ]]; then
        local status=$(dockerCheckAppInstalled "headscale" "docker")
        if [ "$status" == "installed" ]; then
            setupHeadscaleGetHostname;

            result=$(cd ~ && curl -fsSL https://tailscale.com/install.sh | sh)
            checkSuccess "Setting up Headscale for localhost"

            setupHeadscaleGenerateAuthKey;

            result=$(sudo tailscale up --login-server $headscale_live_hostname --authkey $headscale_preauthkey --force-reauth)
            checkSuccess "Connecting $app_name to Headscale Server"

            result=$(rm -rf $headscale_preauthkey_file)
            checkSuccess "Clearing the temp key file."

            # Showing Nodelist after install
            headscaleclientlocal=n
            headscalenodeslist=y
            headscaleCommands;
            headscalenodeslist=n
        else
            isSuccessful "Headscale is not installed, Unable to install."
        fi
    elif [[ "$local_type" == "remote" ]]; then
        if setupHeadscaleCheckRemote; then
            result=$(cd ~ && curl -fsSL https://tailscale.com/install.sh | sh)
            checkSuccess "Setting up Headscale"

            result=$(sudo tailscale up --login-server https://$CFG_HEADSCALE_HOST --authkey $CFG_HEADSCALE_KEY --force-reauth)
            checkSuccess "Connecting $app_name to $CFG_HEADSCALE_HOST Headscale Server"
        fi
    fi
}
