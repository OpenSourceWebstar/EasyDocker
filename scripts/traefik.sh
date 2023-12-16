#!/bin/bash

setupTraefikLabelsSetupMiddlewares() 
{
    local app_name="$1"
    local temp_file="$2"

    local middlewares_line=$(grep -m 1 ".middlewares:" "$temp_file")

    local middleware_entries=()


    # Default Values non app specific
    middleware_entries+=("default@file")

    # App Specific middlewears
    if [[ "$login_required" == "true" ]]; then
        middleware_entries+=("protectionAuth@file")
    fi

    if [[ "$app_name" == "onlyoffice" ]]; then
        middleware_entries+=("onlyoffice-headers")
    fi

    if [[ "$authelia_setup" == "true" && "$whitelist" == "true" ]]; then
        middleware_entries+=("global-ipwhitelist@file")
        if [[ $(checkAppInstalled "authelia" "docker") == "installed" ]]; then
            middleware_entries+=("authelia@docker")
        fi
    elif [[ "$authelia_setup" == "true" && "$whitelist" == "false" ]]; then
        if [[ $(checkAppInstalled "authelia" "docker") == "installed" ]]; then
            middleware_entries+=("authelia@docker")
        fi
    elif [[ "$authelia_setup" == "false" && "$whitelist" == "true" ]]; then
        middleware_entries+=("global-ipwhitelist@file")
    fi

    local middlewares_string="$(IFS=,; echo "${middleware_entries[*]}")"

    sed -i "s/.middlewares:.*/.middlewares: $middlewares_string/" "$temp_file"
}

setupTraefikLabels() 
{
    local app_name="$1"
    local compose_file="$2"
    local temp_file="/tmp/temp_compose_file.yml"

    > "$temp_file"
    sudo cp "$compose_file" "$temp_file"

    setupTraefikLabelsSetupMiddlewares "$app_name" "$temp_file"

    # No Whitelist Data
    if [[ "$CFG_IPS_WHITELIST" == "" ]]; then
        sudo sed -i "s/#labels:/labels:/g" "$temp_file"
        sudo sed -i -e '/#traefik/ s/#//g' -e '/#whitelist/ s/#//g' "$temp_file"
    else
        if [[ "$whitelist" == "true" && "$authelia_setup" == "false" ]]; then
            sudo sed -i "s/#labels:/labels:/g" "$temp_file"
            sudo sed -i '/#traefik/ s/#//g' "$temp_file"
        fi
        if [[ "$whitelist" == "false" && "$authelia_setup" == "false" ]]; then
            sudo sed -i "s/#labels:/labels:/g" "$temp_file"
            sudo sed -i -e '/#traefik/ s/#//g' -e '/#whitelist/ s/#//g' "$temp_file"
        fi
        if [[ "$whitelist" == "false" && "$authelia_setup" == "true" ]]; then
            sudo sed -i "s/#labels:/labels:/g" "$temp_file"
            sudo sed -i -e '/#traefik/ s/#//g' -e '/#whitelist/ s/#//g' "$temp_file"
        fi
        if [[ "$whitelist" == "true" && "$authelia_setup" == "true" ]]; then
            sudo sed -i "s/#labels:/labels:/g" "$temp_file"
            sudo sed -i '/#traefik/ s/#//g' "$temp_file"
        fi
    fi

    copyFile "silent" "$temp_file" "$compose_file" $CFG_DOCKER_INSTALL_USER overwrite
    sudo rm "$temp_file"

    local indentation="      "
    if sudo grep -q '\.middlewares:' "$compose_file"; then
        sudo awk -v indentation="$indentation" '/\.middlewares:/ { if ($0 !~ "^" indentation) { $0 = indentation $0 } } 1' "$compose_file" | sudo tee "$compose_file.tmp" > /dev/null
        sudo mv "$compose_file.tmp" "$compose_file"
    fi
}

traefikSetupLoginCredentials()
{
	local protectionauth_file="$containers_dir/traefik/etc/dynamic/middlewears/protectionauth.yml"
    if [ -f "$protectionauth_file" ]; then
		# Setup BasicAuth credentials
		local password_hash=$(htpasswd -Bbn "$CFG_LOGIN_USER" "$CFG_LOGIN_PASS")

		# Update the YAML file in place
		local result=$(sudo sed -E -i "0,/^\s*- /{s|^\s*- .*|          - \"$password_hash\"|}" $protectionauth_file)
		checkSuccess "Configured Traefik config with Login user/pass data for login protection."
	fi
}
