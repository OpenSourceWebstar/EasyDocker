#!/bin/bash

databaseListAllApps()
{
	if [[ "$toollistallapps" == [yY] ]]; then
    
        # Check if sqlite3 is available
        if ! command -v sudo sqlite3 &> /dev/null; then
            isNotice "sqlite3 command not found. Make sure it's installed."
            return 1
        fi

        # Check if database file is available
        if [ ! -f "$docker_dir/$db_file" ] ; then
            isNotice "Database file not found. Make sure it's installed."
            return 1
        fi

        echo ""
        echo "##########################################"
        echo "###     Listing full apps database     ###"
        echo "##########################################"
        echo ""

        # Execute the SQLite query and store the output in a variable
        local output=$(sudo sqlite3 -header -column $docker_dir/$db_file "SELECT * FROM apps;")
        # Count the number of non-header lines (data rows) in the 'output'
        local num_data_rows=$(echo "$output" | grep -v '^name[[:space:]]|')

        # Check if results variable is not empty
        if [ -n "$num_data_rows" ]; then
            # Loop through each line of the output and print it as a list item
            echo "$output" | while IFS= read -r line; do
                echo "$line"
            done
            read -p "Press Enter to continue..."
            else
            isNotice "No applications found"
        fi
    fi
}
