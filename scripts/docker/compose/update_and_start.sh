#!/bin/bash

dockerComposeUpdateAndStartApp()
{
    local app_name="$1"
    local flags="$2"
    local norestart="$3"

    # Starting variable for app
    portClearAllData;
    setupBasicScanVariables $app_name;

    # Always keep YML updated
    dockerComposeUpdate $app_name $flags $norestart;
}
