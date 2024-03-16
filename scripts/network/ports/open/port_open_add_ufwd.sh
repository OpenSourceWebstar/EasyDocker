#!/bin/bash

portOpenUfwd()
{
    local app_name="$1"
    local port="$2"
    local type="$3"
    
    ufwd_port_array+=("$app_name:$port/$type")
}