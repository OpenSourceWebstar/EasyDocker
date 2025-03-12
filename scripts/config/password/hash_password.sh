#!/bin/bash

hashPassword() 
{
    local password="$1"
    local bcrypt_hash=""

    echo "DEBUG: Attempting to generate bcrypt hash for password: '$password'"

    # Try wg-easy first
    if command -v docker &>/dev/null; then
        echo "DEBUG: Using wg-easy for bcrypt hashing."
        bcrypt_hash=$(sudo docker run --rm ghcr.io/wg-easy/wg-easy wgpw "$password" 2>/dev/null | tr -d '\n')

        if [[ -n "$bcrypt_hash" ]]; then
            echo "DEBUG: Raw bcrypt hash from wg-easy: $bcrypt_hash"

            # Escape $ to $$ for Docker Compose compatibility
            local escaped_hash
            escaped_hash=$(echo "$bcrypt_hash" | awk '{gsub(/\$/, "\\$"); print}')

            echo "DEBUG: Escaped bcrypt hash (for Docker Compose): $escaped_hash"

            echo "$escaped_hash"
            return 0
        else
            echo "DEBUG: wg-easy hash generation failed."
        fi
    fi

    # Fallback: Use htpasswd
    if command -v htpasswd &>/dev/null; then
        echo "DEBUG: Using htpasswd for bcrypt hashing."
        bcrypt_hash=$(sudo htpasswd -bnBC 10 "" "$password" | tr -d ':\n')

        if [[ -n "$bcrypt_hash" ]]; then
            echo "DEBUG: Raw bcrypt hash from htpasswd: $bcrypt_hash"

            # Escape $ to $$ for Docker Compose compatibility
            local escaped_hash
            escaped_hash=$(echo "$bcrypt_hash" | awk '{gsub(/\$/, "\\$"); print}')

            echo "DEBUG: Escaped bcrypt hash (for Docker Compose): $escaped_hash"

            echo "$escaped_hash"
            return 0
        else
            echo "DEBUG: htpasswd hash generation failed."
        fi
    fi

    isError "Failed to generate bcrypt hash for password: '$password'"
    return 1
}
