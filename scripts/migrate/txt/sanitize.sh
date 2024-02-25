#!/bin/bash

migrateSanitizeTXT()
{
    local app_name="$1"
    local migrate_file_path="$containers_dir/$app_name/$migrate_file"

    # Remove trailing non-text, non-number, non-special characters for lines starting with CFG_
    #sudo sed -i '/^CFG_/ s/[^[:alnum:]_]/ /g' "$migrate_file_path"
    #sudo dos2unix "$migrate_file_path" > /dev/null 2>&1
    #sudo sed -i 's/\r$//' "$migrate_file_path"
}
