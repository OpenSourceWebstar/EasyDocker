#!/bin/bash

scanFileForRandomPassword()
{
    local file="$1"
    
    # Declare an array to hold passwords for placeholders 1 to 9
    local passwords=()
    
    if [ -f "$file" ]; then
        # First, handle placeholders RANDOMIZEDPASSWORD1 to RANDOMIZEDPASSWORD9
        for i in {1..9}; do
            local placeholder="RANDOMIZEDPASSWORD${i}"
            
            # Check if the file contains the current placeholder
            if sudo grep -q "$placeholder" "$file"; then
                # Generate a unique random password if it has not been generated yet
                if [ -z "${passwords[$i]}" ]; then
                    passwords[$i]=$(generate_random_password)
                fi
                
                # Update all occurrences of the current placeholder with the new password
                sudo sed -i "s/${placeholder}/${passwords[$i]}/g" "$file"
                
                # Display the update message
                isSuccessful "Updated ${placeholder} in $(basename "$file") with a new password."
            fi
        done

        # Next, handle the generic placeholder RANDOMIZEDPASSWORD
        local placeholder="RANDOMIZEDPASSWORD"
        
        # Check if the file contains the placeholder
        if sudo grep -q "$placeholder" "$file"; then
            # Generate a unique random password
            local random_password=$(generate_random_password)
            
            # Update all occurrences of the placeholder with the new password
            sudo sed -i "s/${placeholder}/${random_password}/g" "$file"
            
            # Display the update message
            isSuccessful "Updated ${placeholder} in $(basename "$file") with a new password."
        fi
    fi
}
