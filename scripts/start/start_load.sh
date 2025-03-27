#!/bin/bash

# Used to load any functions after update
startLoad()
{
    if [ "$1" = "unattended" ]; then
        unattended_setup="true"
    fi

    checkRequirements $type;
    dockerSwitcherSwap;
}
