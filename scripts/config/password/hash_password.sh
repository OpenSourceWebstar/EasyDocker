#!/bin/bash

# Function to hash a password using bcrypt
hashPassword() 
{
    local password="$1"
    local bcrypt_hash=""

    # Try wg-easy first
    if command -v docker &>/dev/null && sudo docker run --rm ghcr.io/wg-easy/wg-easy wgpw "test" &>/dev/null; then
        bcrypt_hash=$(sudo docker run --rm ghcr.io/wg-easy/wg-easy wgpw "$password")
    elif command -v htpasswd &>/dev/null; then
        # Fallback: Use htpasswd
        bcrypt_hash=$(htpasswd -bnBC 10 "" "$password" | tr -d ':\n')
    else
        isError "No valid bcrypt hashing method found."
        return 1
    fi

    # Escape $ to $$ for Docker Compose compatibility
    echo "$bcrypt_hash" | sed 's/\$/\$\$/g'
}
