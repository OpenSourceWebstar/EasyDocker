#!/bin/bash

replaceBcryptPasswords() 
{
    local file="$1"
    local app_name
    app_name=$(basename "$(dirname "$file")")

    for i in {1..9}; do
        local placeholder="RANDOMIZEDBCRYPTPASSWORD${i}"
        
        if sudo grep -q "$placeholder" "$file"; then
            processBcryptPassword "$app_name" "$file" "$placeholder"
        fi
    done

    # Handle generic RANDOMIZEDBCRYPTPASSWORD
    local placeholder="RANDOMIZEDBCRYPTPASSWORD"
    if sudo grep -q "$placeholder" "$file"; then
        processBcryptPassword "$app_name" "$file" "$placeholder"
    fi
}
