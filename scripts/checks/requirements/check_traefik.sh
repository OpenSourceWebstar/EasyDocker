#!/bin/bash

checkTraefikRequirement()
{  
    local traefik_status=$(dockerCheckAppInstalled "traefik" "docker")
    if [[ "$traefik_status" == "installed" ]]; then
        traefikSetupLoginCredentials;
    fi
} 