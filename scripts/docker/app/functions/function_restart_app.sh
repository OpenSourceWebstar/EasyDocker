#!/bin/bash

dockerRestartAppViaInstall() 
{
    local app_name="$1"
    local app_name_ucfirst="$(tr '[:lower:]' '[:upper:]' <<< ${app_name:0:1})${app_name:1}"
    local installFuncName="install${app_name_ucfirst}"

    # Create a variable with the name of $app_name and set its value to "r"
    declare "${app_name}=r"

    # Check if the installation function exists before calling it
    if [ -n "$(type -t ${installFuncName})" ] && [ "$(type -t ${installFuncName})" = function ]; then
        ${installFuncName}
    else
        isNotice "Installation function ${installFuncName} not found."
    fi
}
