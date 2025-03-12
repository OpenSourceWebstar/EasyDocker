#!/bin/bash

processBcryptPassword() 
{
    local app_name="$1"
    local file="$2"
    local placeholder="$3"

    # Extract the variable name before the placeholder
    local variable_name
    variable_name=$(sudo awk -F= '/'"$placeholder"'/ { gsub(/^[ \t-]+/, "", $1); print $1; exit }' "$file")

    if [ -z "$variable_name" ]; then
        echo "ERROR: Could not extract variable name before $placeholder." >&2
        return
    fi

    # Get or generate password
    local raw_password
    raw_password=$(getStoredPassword "$app_name" "$variable_name")

    if [ -z "$raw_password" ]; then
        raw_password=$(generateRandomPassword)
        exportBcryptPassword "$app_name" "$variable_name" "$raw_password" "$file"
    fi

    # Generate bcrypt hash (only return hash, no debug messages)
    local bcrypt_password
    bcrypt_password=$(hashPassword "$raw_password")

    # Validate hash
    if [ -z "$bcrypt_password" ]; then
        echo "ERROR: Failed to generate bcrypt hash for $variable_name." >&2
        return 1
    fi

    # Remove any single quotes from the bcrypt hash
    bcrypt_password=$(echo "$bcrypt_password" | tr -d "'")

    local result=$(sudo sed -i -E "s#$placeholder#$bcrypt_password#g" "$file")
    checkSuccess "Use sed to replace placeholder with bcrypt hash"

    # Verify replacement
    if sudo grep -q "$bcrypt_password" "$file"; then
        isSuccessful "Updated $variable_name in $(basename "$file")." >&2
    else
        isError "ERROR: sed failed to replace $placeholder in $file." >&2
    fi
}
