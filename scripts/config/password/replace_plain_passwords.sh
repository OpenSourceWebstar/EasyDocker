#!/bin/bash

replacePlainPasswords() 
{
    local file="$1"

    for i in {1..9}; do
        local placeholder="RANDOMIZEDPASSWORD${i}"
        
        if sudo grep -q "$placeholder" "$file"; then
            local password
            password=$(generateRandomPassword)
            
            sudo sed -i "s/${placeholder}/${password}/g" "$file"
            checkSuccess "Updated ${placeholder} in $(basename "$file") with a new password."
        fi
    done

    # Handle generic RANDOMIZEDPASSWORD
    local placeholder="RANDOMIZEDPASSWORD"
    if sudo grep -q "$placeholder" "$file"; then
        local random_password=$(generateRandomPassword)
        sudo sed -i "s/${placeholder}/${random_password}/g" "$file"
        checkSuccess "Updated ${placeholder} in $(basename "$file") with a new password."
    fi
}
