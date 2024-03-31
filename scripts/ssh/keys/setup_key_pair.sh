#!/bin/bash

generateSSHSetupKeyPair() 
{
    local username="$1"
    local flag="$2"

    local private_key_file="${CFG_INSTALL_NAME}_sshkey_$username"
    local private_key_path="${ssh_dir}private"
    local private_key_full="$private_key_path/$private_key_file"

    local public_key_file="$private_key_file.pub"
    local public_key_path="${ssh_dir}public"
    local public_key_full="$public_key_path/$public_key_file"

    # Check if the directory exists; if not, create it
    if [ ! -d "$private_key_path" ]; then
        local result=$(createFolders "loud" $docker_install_user $private_key_path)
        checkSuccess "Creating $(basename "$private_key_path") folder"
    fi
    if [ ! -d "$public_key_path" ]; then
        local result=$(createFolders "loud" $docker_install_user $public_key_path)
        checkSuccess "Creating $(basename "$public_key_path") folder"
    fi

    # Check if the private key does not exist
    if [ ! -f "$private_key_full" ]; then
        generateSSHKeyPair "$username" "$private_key_path" "$private_key_full" "$public_key_full" install;
    fi

    # Check if the public key does not exist
    if [ ! -f "$public_key_full" ]; then
        generateSSHKeyPair "$username" "$private_key_path" "$private_key_full" "$public_key_full" install;
    fi
}
