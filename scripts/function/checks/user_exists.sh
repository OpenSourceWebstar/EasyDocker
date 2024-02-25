#!/bin/bash

function userExists() 
{
    if id "$1" &>/dev/null; then
        return 0 # User exists
    else
        return 1 # User does not exist
    fi
}
