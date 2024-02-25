#!/bin/bash

cliListDockertypeCommands() 
{
    # Select preexisting docker_type
    if [ -f "$docker_dir/$db_file" ]; then
        local docker_type_cli=$(sudo sqlite3 "$docker_dir/$db_file" 'SELECT content FROM options WHERE option = "docker_type";')
        # Insert into DB if something doesnt exist
        if [[ $docker_type_cli == "" ]]; then
            databaseOptionInsert "docker_type" $CFG_DOCKER_INSTALL_TYPE;
            local docker_type_cli=$(sudo sqlite3 "$docker_dir/$db_file" 'SELECT content FROM options WHERE option = "docker_type";')
        fi
    fi
    echo ""
    isNotice "The current Docker Setup Type is currently : ${RED}$docker_type_cli${NC}" 
    echo ""
    echo "Available Dockertype Commands:"
    echo ""
    echo "  easydocker dockertype rooted          - Set Docker to use rooted privileges"
    echo "  easydocker dockertype rootless        - Set Docker to run in rootless mode"
    echo ""
}
