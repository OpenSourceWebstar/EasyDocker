#!/bin/bash

portOpenUfwd()
{
    local port="$1"
    local type="$2"
    
    # Check if ufwd_port_array is unset or null
    if [[ -z "${ufwd_port_array[@]}" ]]; then
        # If unset or null, declare the array
        declare -a ufwd_port_array=()
    fi
    
    ufwd_port_array+=("$port/$type")
}