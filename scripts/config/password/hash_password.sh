#!/bin/bash

# Function to hash a password using bcrypt
hashPassword() {
    local password
    read -r password
    echo -n "$password" | openssl passwd -6 -stdin
}
