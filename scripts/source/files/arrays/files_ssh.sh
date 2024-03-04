#!/bin/bash

ssh_scripts=(
    "ssh/disable_passwords/check_ssh_keys.sh"
    "ssh/disable_passwords/disable_ssh_auth.sh"
    "ssh/disable_passwords/update_ssh_html.sh"
    
    "ssh/keys/check_key_pair.sh"
    "ssh/keys/generate_key_pair.sh"
    "ssh/keys/install_key_pair.sh"
    "ssh/keys/regenerate_key_pair.sh"
    "ssh/keys/setup_auth_key.sh"
    "ssh/keys/setup_key_pair.sh"
)
