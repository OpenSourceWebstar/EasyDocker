#!/bin/bash

databaseDisplayTables() 
{
    if [[ "$toollistalltables" == [yY] ]]; then
        local table_number=0
        local selected_table=""
        local sorted_tables=()

        echo ""
        echo "##########################################"
        echo "###      View Database Table Data      ###"
        echo "##########################################"
        echo ""

        while true; do
            # Check if sqlite3 is available
            if ! command -v sudo sqlite3 &> /dev/null; then
                isNotice "sqlite3 command not found. Make sure it's installed."
                return 1
            fi

            # Ensure the database file exists
            if [ ! -f "$docker_dir/$db_file" ]; then
                isNotice "Database file not found: $docker_dir/$db_file"
                return
            fi

            # Get a list of existing tables in the database
            local tables_list=($(sudo sqlite3 "$docker_dir/$db_file" ".tables"))

            # Sort the tables alphabetically
            sorted_tables=($(printf "%s\n" "${tables_list[@]}" | sort))

            # Check if there are any tables in the database
            if [ "${#sorted_tables[@]}" -eq 0 ]; then
                isError "No tables found in the database."
                return
            fi

            table_number=0
            for table_name in "${sorted_tables[@]}"; do
                table_number=$((table_number+1))
                echo "$table_number. $table_name"
            done

            echo ""
            isQuestion "Enter the number of the table to view data (x to exit): "
            read -p "" selected_table

            if [[ "$selected_table" == "x" ]]; then
                echo ""
                echo "Exiting."
                return
            elif [[ "$selected_table" =~ ^[0-9]+$ ]] && ((selected_table >= 1)) && ((selected_table <= "${#sorted_tables[@]}")); then
                selected_table="${sorted_tables[$((selected_table-1))]}"
                # Display all data for the selected table with formatted output
                echo ""
                echo "##########################################"
                echo "###   Displaying $selected_table Table Data"
                echo "##########################################"
                echo ""
                sudo sqlite3 -column -header "$docker_dir/$db_file" "SELECT * FROM $selected_table;"
                echo ""
                isQuestion "Press Enter to continue..."
                read -p "" input
            else
                isNotice "Invalid table number. Please try again."
            fi
        done
    fi
}
