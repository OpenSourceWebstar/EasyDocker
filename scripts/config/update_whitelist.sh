#!/bin/bash

checkEasyDockerGeneralUpdateHostIPToWhitelist()
{
    if grep -q "HOSTIPHERE" "$configs_dir$config_file_general"; then
        result=$(sed -i "s/HOSTIPHERE/$public_ip_v4/" "$configs_dir$config_file_general")
        checkSuccess "Updated EasyDocker Default whitelist IP to $public_ip_v4"
    fi
}