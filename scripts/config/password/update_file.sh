#!/bin/bash

scanFileForRandomPassword()
{
    local file="$1"
    
    # Declare arrays to hold passwords
    local passwords=()
    local bcrypt_passwords=()
    
    if [ -f "$file" ]; then
        # Handle RANDOMIZEDPASSWORD1 to RANDOMIZEDPASSWORD9
        for i in {1..9}; do
            local placeholder="RANDOMIZEDPASSWORD${i}"
            
            if sudo grep -q "$placeholder" "$file"; then
                if [ -z "${passwords[$i]}" ]; then
                    passwords[$i]=$(generateRandomPassword)
                fi
                
                sudo sed -i "s/${placeholder}/${passwords[$i]}/g" "$file"
                isSuccessful "Updated ${placeholder} in $(basename "$file") with a new password."
            fi
        done

        # Handle generic RANDOMIZEDPASSWORD
        local placeholder="RANDOMIZEDPASSWORD"
        if sudo grep -q "$placeholder" "$file"; then
            local random_password=$(generateRandomPassword)
            sudo sed -i "s/${placeholder}/${random_password}/g" "$file"
            isSuccessful "Updated ${placeholder} in $(basename "$file") with a new password."
        fi

        # Handle RANDOMIZEDBCRYPTPASSWORD1 to RANDOMIZEDBCRYPTPASSWORD9
        for i in {1..9}; do
            local placeholder="RANDOMIZEDBCRYPTPASSWORD${i}"
            
            if sudo grep -q "$placeholder" "$file"; then
                if [ -z "${bcrypt_passwords[$i]}" ]; then
                    bcrypt_passwords[$i]=$(generateRandomPassword | hashPassword)
                fi
                
                escaped_bcrypt_password=$(echo "${bcrypt_passwords[$i]}" | sed 's/[\/&]/\\&/g')
                sudo sed -i -E "s/${placeholder}/'${escaped_bcrypt_password}'/g" "$file"
                isSuccessful "Updated ${placeholder} with Bcrypt in $(basename "$file")."
            fi
        done

        # Handle generic RANDOMIZEDBCRYPTPASSWORD
        local placeholder="RANDOMIZEDBCRYPTPASSWORD"
        if sudo grep -q "$placeholder" "$file"; then
            local bcrypt_password=$(generateRandomPassword | hashPassword)
            escaped_bcrypt_password=$(echo "${bcrypt_password}" | sed 's/[\/&]/\\&/g')
            sudo sed -i -E "s/${placeholder}/'${escaped_bcrypt_password}'/g" "$file"
            isSuccessful "Updated ${placeholder} with Bcrypt in $(basename "$file")."
        fi
    fi
}
