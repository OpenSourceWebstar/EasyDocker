#!/bin/bash

checkSSHSetupKeyPair() 
{
    local username="$1"

    local private_key_file="${CFG_INSTALL_NAME}_sshkey_$username"
    local private_key_path="${ssh_dir}private"
    local private_key_full="$private_key_path/$private_key_file"

    local public_key_file="$private_key_file.pub"
    local public_key_path="${ssh_dir}public"
    local public_key_full="$public_key_path/$public_key_file"

    # Check if both private and public key files exist
    if [ -f "$private_key_full" ] && [ -f "$public_key_full" ]; then
        return 0  # Key pair exists
    else
        return 1  # Key pair does not exist
    fi
}
