#!/bin/bash

dockerInstallApp()
{
    local app_name="$1"
    local app_name_ucfirst="$(tr '[:lower:]' '[:upper:]' <<< ${app_name:0:1})${app_name:1}"
    local installFuncName="install${app_name_ucfirst}"

    # Create a variable with the name of $app_name and set its value to "i"
    declare "${app_name}=i"

    # Call the installation function
    ${installFuncName}
}
