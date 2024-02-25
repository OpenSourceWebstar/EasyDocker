#!/bin/bash

scanConfigsForRandomPassword()
{
    if [[ "$CFG_REQUIREMENT_PASSWORDS" == "true" ]]; then
        echo ""
        echo "##########################################"
        echo "###    Randomizing Config Passwords    ###"
        echo "##########################################"
        echo ""
        # Iterate through files in the folder
        for scanned_config_file in "$configs_dir"/*; do
            if [ -f "$scanned_config_file" ]; then
                # Check if the file contains the placeholder string "RANDOMIZEDPASSWORD"
                while sudo grep  -q "RANDOMIZEDPASSWORD" "$scanned_config_file"; do
                    # Generate a unique random password
                    local random_password=$(openssl rand -base64 12 | tr -d '+/=')
                    
                    # Capture the content before "RANDOMIZEDPASSWORD"
                    local config_content=$(sudo sed -n "s/RANDOMIZEDPASSWORD.*$/${random_password}/p" "$scanned_config_file")
                    
                    # Update the first occurrence of "RANDOMIZEDPASSWORD" with the new password
                    sudo sed -i "0,/\(RANDOMIZEDPASSWORD\)/s//${random_password}/" "$scanned_config_file"
                    
                    # Display the update message with the captured content and file name
                    #isSuccessful "Updated $config_content in $(basename "$scanned_config_file") with a new password: $random_password"
                done
            fi
        done
        isSuccessful "Random password generation and update completed successfully."
    fi
}
