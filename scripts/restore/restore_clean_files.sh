#!/bin/bash

restoreCleanFiles()
{
    local result=$(sudo rm -rf $RESTORE_SAVE_DIRECTORY/*.zip)
    checkSuccess "Clearing unneeded restore data"
}
