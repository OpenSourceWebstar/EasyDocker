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
    bcrypt_password=$(hashPassword "$raw_password" | tr -d '\n')

    # Debugging output
    echo "DEBUG: Placeholder: $placeholder" >&2
    echo "DEBUG: Variable Name: $variable_name" >&2
    echo "DEBUG: Raw Password: $raw_password" >&2
    echo "DEBUG: Bcrypt Hash (before sed): $bcrypt_password" >&2

    # Verify the hash isn't empty
    if [ -z "$bcrypt_password" ]; then
        isError "Failed to generate bcrypt hash for $variable_name."
        return 1
    fi

    # Debug: Show `sed` command before running it
    echo "DEBUG: Running sed command: sudo sed -i -E 's#${placeholder}#${bcrypt_password}#g' \"$file\"" >&2

    # Replace the placeholder in the file
    sudo sed -i -E "s#${placeholder}#${bcrypt_password}#g" "$file"

    # Check if replacement was successful
    if sudo grep -q "$bcrypt_password" "$file"; then
        checkSuccess "Updated $variable_name with Bcrypt in $(basename "$file")."
    else
        isError "sed failed to replace $placeholder in $file. Check the syntax."
    fi
}
