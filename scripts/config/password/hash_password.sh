#!/bin/bash

# Function to hash a password using bcrypt
hashPassword() 
{
    local password="$1"
    local bcrypt_hash=""

    # Try wg-easy first
    if command -v docker &>/dev/null; then
        bcrypt_hash=$(sudo docker run --rm ghcr.io/wg-easy/wg-easy wgpw "$password" 2>/dev/null)

        if [[ -n "$bcrypt_hash" ]]; then
            echo "$bcrypt_hash" | sed 's/\$/\$\$/g'
            return 0
        fi
    fi

    # Fallback: Use htpasswd
    if command -v htpasswd &>/dev/null; then
        bcrypt_hash=$(htpasswd -bnBC 10 "" "$password" | tr -d ':\n')
        echo "$bcrypt_hash" | sed 's/\$/\$\$/g'
        return 0
    fi

    isError "Failed to generate bcrypt hash for $password. Ensure Docker and htpasswd are installed."
    return 1
}
