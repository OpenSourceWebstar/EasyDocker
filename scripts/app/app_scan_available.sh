#!/bin/bash

appScanAvailable()
{
    if [ -d "$install_containers_dir" ]; then
        echo ""
        echo "Folders in $install_containers_dir:"
        echo ""
        for folder in "$install_containers_dir"/*/; do
            local folder_name=$(basename "$folder")
            local script_file="$folder/${folder_name}.sh"
            if [ -f "$script_file" ]; then
                local category=$(sed -n 's/^# Category : \(.*\) :$/\1/p' "$script_file")
                local description=$(sed -n 's/^# Description : \(.*\) (.*/\1/p' "$script_file")
                echo "$category - $description"
            else
                echo "No ${folder_name}.sh file found in $folder"
            fi
        done
    else
        isError "$folder_name is not a valid application."
    fi
}
