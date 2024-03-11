#!/bin/bash

appScanAvailable()
{
    local containers_dir="$1"
    if [ -d "$containers_dir" ]; then
        echo "Folders in $containers_dir:"
        for folder in "$containers_dir"/*/; do
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
        isError "$containers_dir is not a valid application."
    fi
}
