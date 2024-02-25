#!/bin/bash

exitScript() 
{
	echo ""
	echo ""
	isNotice "Exiting script..."
	isNotice "Goodbye <3..."
	echo ""
    if [ -f "$docker_dir/$db_file" ]; then
        database_path=$(sqlite3 "$docker_dir/$db_file" "SELECT path FROM path LIMIT 1;")
		isNotice "Last working path :"
		isNotice "cd $database_path"
    fi
	echo ""
	stty echo
	exit 0
}
