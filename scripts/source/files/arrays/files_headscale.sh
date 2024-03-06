#!/bin/bash

headscale_scripts=(
    "headscale/local/headscale_generate_auth.sh"
    "headscale/local/headscale_get_hostname.sh"
    "headscale/local/headscale_setup_local.sh"
    "headscale/local/headscale_setup_localhost.sh"

    "headscale/remote/headscale_check_remote.sh"
    "headscale/remote/headscale_setup_remote.sh"

    "headscale/tailscale/tailscale_install.sh"
    #"headscale/tailscale/tailscale.sh" Used for install on containers only

    "headscale/headscale_commands.sh"
    "headscale/headscale_edit_config.sh"
    "headscale/headscale_setup.sh"
    "headscale/headscale_user.sh"
)
