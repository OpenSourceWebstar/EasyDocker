#!/bin/bash

processBcryptPassword()
{
    local app_name="$1"
    local file="$2"
    local placeholder="$3"

    local variable_name
    variable_name=$(sudo awk -F= '/'"$placeholder"'/ { gsub(/^[ \t-]+/, "", $1); print $1; exit }' "$file")

    if [ -z "$variable_name" ]; then
        isError "Could not extract variable name before $placeholder."
        return
    fi

    local raw_password
    raw_password=$(getStoredPassword "$app_name" "$variable_name")

    if [ -z "$raw_password" ]; then
        raw_password=$(generateRandomPassword)
        exportBcryptPassword "$app_name" "$variable_name" "$raw_password" "$file"
    fi

    # Generate bcrypt hash
    local bcrypt_password
    bcrypt_password=$(hashPassword "$raw_password")

    # Verify the hash isn't empty
    if [ -z "$bcrypt_password" ]; then
        isError "Failed to generate bcrypt hash for $variable_name."
        return 1
    fi

    # Replace the placeholder in the file
    sudo sed -i -E "s/${placeholder}/${bcrypt_password}/g" "$file"
    checkSuccess "Updated $variable_name with Bcrypt in $(basename "$file")."
}
