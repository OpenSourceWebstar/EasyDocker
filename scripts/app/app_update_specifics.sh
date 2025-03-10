#!/bin/bash

appUpdateSpecifics()
{
    local app_name="$1"

    # Initialize setup.
    setupInstallVariables $app_name;

    if [[ $app_name == "adguard" ]] || [[ $app_name == "pihole" ]]; then
    	if [[ $CFG_REQUIREMENT_DNS_UPDATER == "true" ]]; then
            updateDNS $app_name install;
        fi
    fi

    if [[ $shouldrestart == "true" ]]; then
        dockerComposeRestart $app_name;
    fi

    isSuccessful "All application specific updates have been completed."
}
