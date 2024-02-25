#!/bin/bash

checkConfigFilesMissingVariables()
{
    local showheader="$1"

    if [[ $showheader == "true" ]]; then
        echo ""
        echo "#################################"
        echo "###   Scanning Config Files   ###"
        echo "#################################"
        echo ""
    fi
    checkEasyDockerConfigFilesMissingVariables;
    checkEasyDockerGeneralUpdateHostIPToWhitelist;
    checkIpsHostnameFilesMissingEntries;
    checkApplicationsConfigFilesMissingVariables;
}
