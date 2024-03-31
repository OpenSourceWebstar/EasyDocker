#!/bin/bash

copyResource()
{
    local app_name="$1"
    local file_name="$2"
    local save_path="$3"

    local app_dir=$install_containers_dir$app_name

    # Check if the app_name folder was found
    if [ -z "$app_dir" ]; then
        echo "App folder '$app_name' not found in '$install_containers_dir'."
        return
    fi

    local destination_dir="$containers_dir$app_name"

    if [ -n "$save_path" ]; then
        local destination_dir="$destination_dir/$save_path"
        if [ ! -d "$destination_dir" ]; then
            local result=$(createFolders "loud" $docker_install_user "$destination_dir")
            checkSuccess "Creating $save_path folder(s) for $app_name"
        fi
    fi

    local result=$(sudo cp "$app_dir/resources/$file_name" "$destination_dir/")
    checkSuccess "Copying $file_name to $destination_dir"

    local destination_path="$destination_dir/$file_name"

    local result=$(sudo chown $docker_install_user:$docker_install_user "$destination_path")
    checkSuccess "Updating $file_name with $docker_install_user ownership"
}
