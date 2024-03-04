#!/bin/bash

restoreCleanFiles()
{
    if [[ "$restorefull" == [lLrRmM] ]]; then
        local result=$(sudo rm -rf $RESTORE_SAVE_DIRECTORY/*.zip)
        checkSuccess "Clearing unneeded restore data"
    elif [[ "$restoresingle" == [lLrRmM] ]]; then
        local result=$(sudo rm -rf $RESTORE_SAVE_DIRECTORY/*.zip)
        checkSuccess "Clearing unneeded restore data"
    fi
}
