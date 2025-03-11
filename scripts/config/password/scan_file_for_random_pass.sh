#!/bin/bash

scanFileForRandomPassword() 
{
    local file="$1"

    if [ -f "$file" ]; then
        replacePlainPasswords "$file"
        replaceBcryptPasswords "$file"
    fi
}
