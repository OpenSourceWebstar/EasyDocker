#!/bin/bash

portOpenUfwd()
{
    local app_name="$1"
    local port="$2"
    local type="$3"
    
    # Check if ufwd_port_array is unset or null
    if [[ -z "${ufwd_port_array[@]}" ]]; then
        # If unset or null, declare the array
        declare -a ufwd_port_array=()
    fi
    
    ufwd_port_array+=("$port/$type")
}