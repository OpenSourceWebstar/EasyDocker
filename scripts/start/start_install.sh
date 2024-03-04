#!/bin/bash

startInstall() 
{
	# Disable Input
	stty -echo

    echo ""
    echo "#######################################################"
    echo "###                Starting Setup                   ###"
    echo "#######################################################"
    echo ""

    portClearAllData;

    #######################################################
    ###                    Install Apps                 ###
    #######################################################

    for install_app_name in "$install_containers_dir"/*/; do
        install_app_name=$(basename "$install_app_name")
        function_name_capitalized="$(tr '[:lower:]' '[:upper:]' <<< "${install_app_name:0:1}")${install_app_name:1}"

        if [ "$(type -t "install${function_name_capitalized}")" = "function" ]; then
            "install${function_name_capitalized}"
        fi
    done

	endStart;

}
