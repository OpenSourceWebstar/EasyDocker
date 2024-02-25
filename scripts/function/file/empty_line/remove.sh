#!/bin/bash

removeEmptyLineAtFileEnd()
{
    local file_path="$1"
    local last_line=$(tail -n 1 "$file_path")
    
    if [ -z "$last_line" ]; then
        local result=$(sudo sed -i '$d' "$file_path")
        checkSuccess "Removed the empty line at the end of $file_path"
    fi
}