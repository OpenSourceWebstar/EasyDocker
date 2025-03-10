#!/bin/bash

# Function to hash a password using bcrypt
hashPassword() 
{
    local password
    read -r password
    local bcrypt_hash=$(htpasswd -bnBC 10 "" "$password" | tr -d ':\n')

    # Escape $ to $$ for Docker Compose compatibility
    echo "$bcrypt_hash" | sed 's/\$/\$\$/g'
}
