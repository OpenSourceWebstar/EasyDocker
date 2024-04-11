#!/bin/bash

scanFileForRandomPassword() 
{
    local file="$1"
    
    if [ -f "$file" ]; then
        # Check if the file contains the placeholder string "RANDOMIZEDPASSWORD"
        while sudo grep  -q "RANDOMIZEDPASSWORD" "$file"; do
            # Generate a unique random password
            local random_password=$(openssl rand -base64 12 | tr -d '+/=')
            
            # Find the line number of the first occurrence of "RANDOMIZEDPASSWORD"
            local line_number=$(sudo grep -n "RANDOMIZEDPASSWORD" "$file" | head -n 1 | cut -d ':' -f 1)
            
            # Capture the content before "RANDOMIZEDPASSWORD"
            local config_content=$(sudo sed -n "${line_number}s/^\([^=]*\).*/\1/p" "$file")

            # Update the first occurrence of "RANDOMIZEDPASSWORD" with the new password
            sudo sed -i "0,/\(RANDOMIZEDPASSWORD\)/s//${random_password}/" "$file"
            
            # Display the update message with the captured content and file name
            isSuccessful "Updated $config_content in $(basename "$file") with a new password."
        done
    fi
}

