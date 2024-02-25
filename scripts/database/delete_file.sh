#!/bin/bash

databaseRemoveFile()
{
	if [[ "$tooldeletedb" == [yY] ]]; then
        local result=$(sudo rm $docker_dir/$db_file)
        checkSuccess "Removing $db_file file"
    fi
}