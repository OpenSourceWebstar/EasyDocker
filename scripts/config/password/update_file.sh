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
                local variable_name
                variable_name=$(sudo awk -F= '/'"$placeholder"'/ { gsub(/^[ \t-]+/, "", $1); print $1; exit }' "$file")

                if [ -n "$variable_name" ]; then
                    local raw_password
                    raw_password=$(getStoredPassword "$app_name" "$variable_name")

                    if [ -z "$raw_password" ]; then
                        raw_password=$(generateRandomPassword)
                        exportBcryptPassword "$app_name" "$variable_name" "$raw_password" "$file"
                    fi

                    # Generate bcrypt hash
                    local bcrypt_password
                    bcrypt_password=$(echo "$raw_password" | hashPassword)

                    # Verify the hash isn't empty
                    if [ -z "$bcrypt_password" ]; then
                        isError "Failed to generate bcrypt hash for $variable_name."
                        return 1
                    fi

                    # Use bcrypt_password directly (DO NOT escape again)
                    local result=$(sudo sed -i -E "s/${placeholder}/${bcrypt_password}/g" "$file")
                    checkSuccess "Updated $variable_name with Bcrypt in $(basename "$file")."
                else
                    isError "Could not extract variable name before $placeholder."
                fi
            fi
        done

        # Handle generic RANDOMIZEDBCRYPTPASSWORD
        local placeholder="RANDOMIZEDBCRYPTPASSWORD"
        if sudo grep -q "$placeholder" "$file"; then
            local variable_name
            variable_name=$(sudo awk -F= '/'"$placeholder"'/ { gsub(/^[ \t-]+/, "", $1); print $1; exit }' "$file")

            if [ -n "$variable_name" ]; then
                local raw_password
                raw_password=$(getStoredPassword "$app_name" "$variable_name")

                if [ -z "$raw_password" ]; then
                    raw_password=$(generateRandomPassword)
                    exportBcryptPassword "$app_name" "$variable_name" "$raw_password" "$file"
                fi

                # Generate bcrypt hash
                local bcrypt_password
                bcrypt_password=$(echo "$raw_password" | hashPassword)

                # Verify the hash isn't empty
                if [ -z "$bcrypt_password" ]; then
                    isError "Failed to generate bcrypt hash for $variable_name."
                    return 1
                fi

                # Use bcrypt_password directly (DO NOT escape again)
                local result=$(sudo sed -i -E "s/${placeholder}/${bcrypt_password}/g" "$file")
                checkSuccess "Updated $variable_name with Bcrypt in $(basename "$file")."
            else
                isError "Could not extract variable name before $placeholder."
            fi
        fi
    fi
}
