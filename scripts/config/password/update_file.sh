#!/bin/bash

scanFileForRandomPassword() 
{
    local file="$1"

    # Extract app name from the file path
    local app_name
    app_name=$(basename "$(dirname "$file")")

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
                
                local result=$(sudo sed -i "s/${placeholder}/${passwords[$i]}/g" "$file")
                checkSuccess "Updated ${placeholder} in $(basename "$file") with a new password."
            fi
        done

        # Handle generic RANDOMIZEDPASSWORD
        local placeholder="RANDOMIZEDPASSWORD"
        if sudo grep -q "$placeholder" "$file"; then
            local random_password=$(generateRandomPassword)
            local result=$(sudo sed -i "s/${placeholder}/${random_password}/g" "$file")
            checkSuccess "Updated ${placeholder} in $(basename "$file") with a new password."
        fi

        # Handle RANDOMIZEDBCRYPTPASSWORD1 to RANDOMIZEDBCRYPTPASSWORD9
        for i in {1..9}; do
            local placeholder="RANDOMIZEDBCRYPTPASSWORD${i}"
            
            if sudo grep -q "$placeholder" "$file"; then
                if [ -z "${bcrypt_passwords[$i]}" ]; then
                    local raw_password
                    raw_password=$(generateRandomPassword)  # Generate unencrypted password
                    bcrypt_passwords[$i]=$(echo "$raw_password" | hashPassword)  # Encrypt password

                    # Export unencrypted password before hashing
                    exportBcryptPassword "$app_name" "$placeholder" "$raw_password"
                fi
                
                escaped_bcrypt_password=$(echo "${bcrypt_passwords[$i]}" | sed 's/[\/&]/\\&/g')
                local result=$(sudo sed -i -E "s/${placeholder}/'${escaped_bcrypt_password}'/g" "$file")
                checkSuccess "Updated ${placeholder} with Bcrypt in $(basename "$file")."
            fi
        done

        # Handle generic RANDOMIZEDBCRYPTPASSWORD
        local placeholder="RANDOMIZEDBCRYPTPASSWORD"
        if sudo grep -q "$placeholder" "$file"; then
            local raw_password
            raw_password=$(generateRandomPassword)
            local bcrypt_password
            bcrypt_password=$(echo "$raw_password" | hashPassword)

            # Export unencrypted password before hashing
            exportBcryptPassword "$app_name" "$placeholder" "$raw_password"

            escaped_bcrypt_password=$(echo "${bcrypt_password}" | sed 's/[\/&]/\\&/g')
            local result=$(sudo sed -i -E "s/${placeholder}/'${escaped_bcrypt_password}'/g" "$file")
            checkSuccess "Updated ${placeholder} with Bcrypt in $(basename "$file")."
        fi
    fi
}
