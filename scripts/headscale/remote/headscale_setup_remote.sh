#!/bin/bash

setupHeadscaleRemote()
{
    local app_name="$1"

    tailscaleInstallToContainer $app_name;

    dockerCommandRun "docker exec $app_name tailscale up --login-server https://$CFG_HEADSCALE_HOST --authkey $CFG_HEADSCALE_KEY --force-reauth"
    checkSuccess "Connecting $app_name to Headscale Server"
}
