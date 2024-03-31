#!/bin/bash

setupBasicScanVariables()
{
    app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "Something went wrong...No app name provided..."
        resetToMenu;
    fi

    compose_setup_var="CFG_${app_name^^}_COMPOSE_FILE"
    compose_setup="${!compose_setup_var}"

    portClearAllData;
    
    # Generates port variables: usedport1, usedport2, etc.
    used_ports_var="CFG_${app_name^^}_PORTS"
    used_initial_ports="${!used_ports_var}"
    if [ -n "$used_initial_ports" ]; then
        IFS=',' read -ra usedports <<< "$used_initial_ports"
        for i in "${!usedports[@]}"; do
            used_variable_name="usedport$((i+1))"
            eval "$used_variable_name=${usedports[i]}"
        done
    fi

    # Generates port variables: openport1, openport2, etc.
    open_ports_var="CFG_${app_name^^}_OPEN_PORTS"
    open_initial_ports="${!open_ports_var}"
    if [ -n "$open_initial_ports" ]; then
        IFS=',' read -ra openports <<< "$open_initial_ports"
        for i in "${!openports[@]}"; do
            local open_variable_name="openport$((i+1))"
            eval "$open_variable_name=${openports[i]}"
        done
    fi

    # Docker Type username
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        docker_install_user="$sudo_user_name"
    elif [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        docker_install_user="$CFG_DOCKER_INSTALL_USER"
    fi
}
