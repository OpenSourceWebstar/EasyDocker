#!/bin/bash

hashPassword() 
{
    local password="$1"

    # Try wg-easy first
    if command -v docker &>/dev/null; then
        local bcrypt_hash
        bcrypt_hash=$(sudo docker run --rm ghcr.io/wg-easy/wg-easy wgpw "$password" 2>/dev/null | tr -d '\n')

        if [[ -n "$bcrypt_hash" ]]; then
            # Escape `$` to `$$` for Docker Compose
            local escaped_hash
            escaped_hash=$(echo "$bcrypt_hash" | sed 's/\$/\$\$/g')

            echo "$escaped_hash"
            return 0
        fi
    fi

    # Fallback: Use htpasswd
    if command -v htpasswd &>/dev/null; then
        local bcrypt_hash
        bcrypt_hash=$(sudo htpasswd -bnBC 10 "" "$password" | tr -d ':\n')

        if [[ -n "$bcrypt_hash" ]]; then
            # Escape `$` to `$$` for Docker Compose
            local escaped_hash
            escaped_hash=$(echo "$bcrypt_hash" | sed 's/\$/\$\$/g')

            echo "$escaped_hash"
            return 0
        fi
    fi

    echo "ERROR: Failed to generate bcrypt hash." >&2
    return 1
}
