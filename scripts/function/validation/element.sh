#!/bin/bash

emailValidation()
{
    local input_email=$1

    # Check email format using regex
    if [[ ! $input_email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        isError "Invalid email format. Please try again."
        return 1  # Return 1 to indicate validation failure
    fi

    return 0  # Return 0 to indicate validation success
}
