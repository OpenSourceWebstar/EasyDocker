#!/bin/bash

# Default install variable setups
setupInstallVariables()
{
    app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "Something went wrong...No app name provided..."
        resetToMenu;
    fi

    # Build variable names based on app_name
    host_name_var="CFG_${app_name^^}_HOST_NAME"
    compose_setup_var="CFG_${app_name^^}_COMPOSE_FILE"
    domain_number_var="CFG_${app_name^^}_DOMAIN_NUMBER"
    public_var="CFG_${app_name^^}_PUBLIC"
    whitelist_var="CFG_${app_name^^}_WHITELIST"
    login_required_var="CFG_${app_name^^}_LOGIN_REQUIRED"
    authelia_var="CFG_${app_name^^}_AUTHELIA"
    headscale_var="CFG_${app_name^^}_HEADSCALE"

    # Access the variables using variable indirection
    host_name="${!host_name_var}"
    compose_setup="${!compose_setup_var}"
    domain_number="${!domain_number_var}"
    public="${!public_var}"
    whitelist="${!whitelist_var}"
    login_required="${!login_required_var}"
    authelia_setup="${!authelia_var}"
    headscale_setup="${!authelia_var}"

    # Default Empty config options
    if [ "$authelia_setup" == "" ]; then
        authelia_setup=false
    fi
    if [ "$headscale_setup" == "" ]; then
        headscale_setup=false
    fi
    if [ "$whitelist" == "" ]; then
        whitelist=false
    fi
    if [ "$login_required" == "" ]; then
        login_required=false
    fi
    if [ "$public" == "" ]; then
        public=false
    fi

    # Check if no network needed
    if [ "$host_name" != "" ]; then
        setupIPsAndHostnames $app_name;
    fi

    # Docker Type username
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        docker_install_user="$sudo_user_name"
    elif [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        docker_install_user="$CFG_DOCKER_INSTALL_USER"
    fi
}
