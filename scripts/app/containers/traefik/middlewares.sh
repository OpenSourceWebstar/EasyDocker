#!/bin/bash

traefikSetupLabelsMiddlewares() 
{
    local app_name="$1"
    local temp_file="$2"
    local middlewares_line=$(grep -m 1 ".middlewares:" "$temp_file")
    local middleware_entries=()

    # List of app names to exclude from default middleware
    local exclude_apps=("onlyoffice" "owncloud")
    # Check if app_name is not in the list of excluded apps
    if [[ ! " ${exclude_apps[@]} " =~ " $app_name " ]]; then
        middleware_entries+=("default@file")
    fi

    # App Specific middlewears
    if [[ "$login_required" == "true" ]]; then
        middleware_entries+=("protectionAuth@file")
    fi

    if [[ "$app_name" == "onlyoffice" ]]; then
        middleware_entries+=("onlyoffice-headers")
    fi

    if [[ "$authelia_setup" == "true" && "$whitelist" == "true" ]]; then
        middleware_entries+=("global-ipwhitelist@file")
        if [[ $(dockerCheckAppInstalled "authelia" "docker") == "installed" ]]; then
            middleware_entries+=("authelia@docker")
        fi
    elif [[ "$authelia_setup" == "true" && "$whitelist" == "false" ]]; then
        if [[ $(dockerCheckAppInstalled "authelia" "docker") == "installed" ]]; then
            middleware_entries+=("authelia@docker")
        fi
    elif [[ "$authelia_setup" == "false" && "$whitelist" == "true" ]]; then
        middleware_entries+=("global-ipwhitelist@file")
    fi

    local middlewares_string="$(IFS=,; echo "${middleware_entries[*]}")"

    sed -i "s/.middlewares:.*/.middlewares: $middlewares_string/" "$temp_file"
}
