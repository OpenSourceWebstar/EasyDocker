#!/bin/bash

databaseEmptyTable() 
{
  if [[ "$toolemptytable" == [yY] ]]; then
    echo ""
    echo "#######################################"
    echo "###      Empty Database Table       ###"
    echo "#######################################"
    echo ""

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
    local tables_list=$(sudo sqlite3 "$docker_dir/$db_file" ".tables")

    # Check if there are any tables in the database
    if [ -z "$tables_list" ]; then
      isNotice "No tables found in the database."
      return
    fi

    # Display the numbered list of tables
    echo "=== List of Tables ==="
    while IFS= read -r table_name; do
      echo "$table_name"
    done <<< "$tables_list"

    echo ""
    isQuestion "Enter the table name to empty (x to exit): "
    read -p "" table_name
    echo ""
    if [[ "$table_name" == "x" ]]; then
      isNotice "Exiting."
      return
    elif sudo sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$table_name\b"; then
      # Empty the selected table
      sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM \"$table_name\";"
      isSuccessful "Table '$table_name' has been emptied."
    else
      isNotice "Invalid table name. Please try again."
    fi
  fi
}
