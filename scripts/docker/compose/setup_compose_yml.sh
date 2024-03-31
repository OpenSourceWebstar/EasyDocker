#!/bin/bash

dockerComposeSetupFile()
{
    local app_name="$1"
    local custom_file="$2"
    local custom_path="$3"

    # Source Filenames
    if [[ $custom_file == "" ]]; then
        local source_compose_file="docker-compose.yml";
    elif [[ $custom_file != "" ]]; then
        local source_compose_file="$custom_file";
    fi

    if [[ $custom_path == "" ]]; then
        local source_path="$install_containers_dir$app_name"
    elif [[ $custom_path != "" ]]; then
        local source_path="$install_containers_dir$app_name/$custom_path/"
    fi

    local source_file="$source_path/$source_compose_file"

    # Target Filenames
    if [[ $compose_setup == "default" ]]; then
        local target_compose_file="docker-compose.yml";
    elif [[ $compose_setup == "app" ]]; then
        local target_compose_file="docker-compose.$app_name.yml";
    fi

    local target_path="$containers_dir$app_name"
    local target_file="$target_path/$target_compose_file"


    if [ "$app_name" == "" ]; then
        isError "The app_name is empty."
        return 1
    fi
    
    if [ ! -f "$source_file" ]; then
        isError "The source file '$source_file' does not exist."
        return 1
    fi
    
    copyFile "loud" "$source_file" "$target_file" $docker_install_user | sudo tee -a "$logs_dir/$docker_log_file" 2>&1
    
    if [ $? -ne 0 ]; then
        isError "Failed to copy the source file to '$target_path'. Check '$docker_log_file' for more details."
        return 1
    fi
}
