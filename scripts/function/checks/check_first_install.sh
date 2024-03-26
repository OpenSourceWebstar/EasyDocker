#!/bin/bash

checkFirstInstall() 
{
    if sudo grep -q "Change-Me" "$configs_dir/$config_file_general" && sudo grep -q "change@me.com" "$configs_dir/$config_file_general" && sudo grep -q "changeme.co.uk" "$configs_dir/$config_file_general"; then
        first_time_install="true"
    else
        first_time_install="false"
    fi
}