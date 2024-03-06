#!/bin/bash

setupHeadscaleLocal()
{
    local app_name="$1"

    setupHeadscaleGetHostname;

    tailscaleInstallToContainer $app_name;

    setupHeadscaleGenerateAuthKey;
    dockerCommandRun "docker exec $app_name tailscale up --login-server $headscale_host_setup --authkey $headscale_preauthkey --force-reauth"
    checkSuccess "Connecting $app_name to Headscale Server"

    result=$(rm -rf $headscale_preauthkey_file)
    checkSuccess "Clearing the temp key file."

    # Showing Nodelist after install
    headscaleclientlocal=n
    headscalenodeslist=y
    headscaleCommands;
    headscalenodeslist=n
}
