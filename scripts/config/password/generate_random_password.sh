#!/bin/bash

generateRandomPassword() 
{
    local password=""
    while true; do
        password=$(openssl rand -base64 16 | tr -d '+/=' | tr -cd '[:alpha:]')
        # Ensure the password does not contain any numbers or spaces
        if [[ "$password" =~ ^[a-zA-Z]+$ ]]; then
            echo "$password"
            return 0
        fi
    done
}