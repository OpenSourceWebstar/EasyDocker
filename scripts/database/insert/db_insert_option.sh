#!/bin/bash

databaseOptionInsert()
{
    local option="$1"
    local content="$2"
    local table_name=options
    local option_in_db=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT COUNT(*) FROM $table_name WHERE option = '$option';")

    if [ "$option_in_db" -eq 0 ]; then
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (option, content) VALUES ('$option', '$content');")
        checkSuccess "Adding $option to the $table_name table."
    else
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "UPDATE $table_name SET option = '$option', content = '$content';")
        checkSuccess "$option already added to the $table_name table. Updating content to $content."
    fi
}
