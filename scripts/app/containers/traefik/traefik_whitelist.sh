#!/bin/bash

traefikUpdateWhitelist() 
{
    local whitelist_file="${containers_dir}traefik/etc/dynamic/whitelist.yml"
    if [ -f "$whitelist_file" ]; then
        # Split the CFG_IPS_WHITELIST into an array
        IFS=',' read -ra IP_ARRAY <<< "$CFG_IPS_WHITELIST"

        # Build the YAML content dynamically
        YAML_CONTENT="http:
  middlewares:
    global-ipwhitelist:
      ipWhiteList:
        sourceRange:"

        for IP in "${IP_ARRAY[@]}"; do
            YAML_CONTENT+="\n          - \"$IP\""
        done

        # Now update the YAML file with the new content using sudo
        echo -e "$YAML_CONTENT" | sudo tee "$whitelist_file" > /dev/null
        isSuccessful "Traefik has been updated with the latest whitelist IPs."
    fi
}