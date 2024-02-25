#!/bin/bash

passwordValidation()
{
    # Password Setup for DB with complexity checking
    # Initialize valid password flag
    local valid_password=false
    # Loop until a valid password is entered
    while [ $valid_password = false ]
    do
        # Prompt the user for a password
        echo -n "Enter your password: "
        # Disable echoing of the password input, so that it is not displayed on the screen
        stty -echo
        # Read in the password input
        read password
        # Re-enable echoing of the input
        stty echo
        echo
        # Check the length of the password
        if [ ${#password} -lt 8 ]; then
            isError "Password is too short. Please enter a password with at least 8 characters."
            continue
        fi
        # Check the complexity of the password
        if ! [[ "$password" =~ [[:lower:]] ]] || ! [[ "$password" =~ [[:upper:]] ]] || ! [[ "$password" =~ [[:digit:]] ]]; then
            isError "Password is not complex enough. Please include at least one uppercase letter, one lowercase letter, and one numeric digit."
            continue
        fi
        # If we make it here, the password is valid
        local valid_password=true
    done
}
