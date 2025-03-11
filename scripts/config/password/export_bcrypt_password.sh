#!/bin/bash

#!/bin/bash

exportBcryptPassword() 
{
    if [[ $CFG_REQUIREMENT_BCRYPT_SAVE == "true" ]]; then
        local app_name="$1"
        local placeholder="$2"
        local raw_password="$3"
        local file="$4"  # File where the placeholder was found
        local log_file="$containers_dir/bcrypt.txt"

        # Ensure log file exists
        if [ ! -f "$log_file" ]; then
            local result=$(sudo touch "$log_file")
            checkSuccess "Created bcrypt.txt file."

            local result=$(sudo chmod 600 "$log_file")
            checkSuccess "Adjusted bcrypt.txt file permissions."
        fi

        # Extract the correct variable name (e.g., PASSWORD_HASH) before the placeholder
        local variable_name
        variable_name=$(sudo awk -F= '/'"$placeholder"'/ { gsub(/^[ \t-]+/, "", $1); print $1; exit }' "$file")

        if [ -n "$variable_name" ]; then
            # Remove old password entries for this app & variable
            local result=$(sudo sed -i "/^$app_name $variable_name /d" "$log_file")
            checkSuccess "Removed existing entry for $app_name $variable_name from bcrypt.txt."

            # Log new password
            local result=$(echo "$app_name $variable_name $raw_password" | sudo tee -a "$log_file" > /dev/null)
            checkSuccess "Logged $app_name $variable_name in bcrypt.txt."
        else
            checkSuccess "Could not extract a variable name before $placeholder in $file."
        fi
    fi
}
