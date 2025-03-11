#!/bin/bash

# Function to hash a password using bcrypt
hashPassword() 
{
    local password="$1"
    local bcrypt_hash=""

    # Try wg-easy first
    if command -v docker &>/dev/null && sudo docker run --rm ghcr.io/wg-easy/wg-easy wgpw "test" &>/dev/null; then
        bcrypt_hash=$(sudo docker run --rm ghcr.io/wg-easy/wg-easy wgpw "$password" | awk -F= '{print $2}' | tr -d "'")
    else
        # Fallback: Use htpasswd
        bcrypt_hash=$(htpasswd -bnBC 10 "" "$password" | tr -d ':\n')
    fi

    # Escape $ to $$ for Docker Compose compatibility
    echo "$bcrypt_hash" | sed 's/\$/\$\$/g'
}