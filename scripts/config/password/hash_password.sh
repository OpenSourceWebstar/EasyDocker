#!/bin/bash

# Function to hash a password using bcrypt
hashPassword() 
{
    local password
    read -r password
    htpasswd -bnBC 10 "" "$password" | tr -d ':\n'
}