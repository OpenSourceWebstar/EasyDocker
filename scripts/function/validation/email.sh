#!/bin/bash

containsElement() 
{
    local element="$1"
    shift
    local arr=("$@")

    for item in "${arr[@]}"; do
        if [[ "$item" == *"$element"* ]]; then
            return 0  # Substring found
        fi
    done
    return 1  # Substring not found
}
