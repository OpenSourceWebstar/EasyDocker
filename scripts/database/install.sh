#!/bin/bash

installSQLiteDatabase()
{
	if [[ $CFG_REQUIREMENT_DATABASE == "true" ]]; then
        # Safeguard loading
        if [ ! -e "$docker_dir/$db_file" ]; then
            if command -v sqlite3 &> /dev/null; then
                echo ""
                echo "##########################################"
                echo "###     Setup SQLite Database"
                echo "##########################################"
                echo ""

                # Create SQLite database file
                if [ ! -e "$docker_dir/$db_file" ]; then
                    local result=$(sudo touch $docker_dir/$db_file)
                    checkSuccess "Creating SQLite $db_file file"

                    local result=$(sudo chmod 755 $docker_dir/$db_file && sudo chown $sudo_user_name $docker_dir/$db_file)
                    checkSuccess "Changing permissions for SQLite $db_file file"
                fi

                setup_table_name=path
                if ! sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                local result=$(sqlite3 $docker_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (path TEXT);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=options
                if ! sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                local result=$(sqlite3 $docker_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (option TEXT, content TEXT);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=ports
                if ! sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                local result=$(sqlite3 $docker_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (name TEXT, port INTEGER UNIQUE);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=ports_open
                if ! sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                local result=$(sqlite3 "$docker_dir/$db_file" "CREATE TABLE IF NOT EXISTS $setup_table_name (name TEXT, port INTEGER, type TEXT, UNIQUE (port, type));")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=sysupdate
                if ! sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                local result=$(sqlite3 $docker_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=apps
                if ! sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                # status = 1 = installed, 0 uninstalled
                local result=$(sqlite3 $docker_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (name TEXT UNIQUE, status DATE, install_date DATE, install_time TIME, uninstall_date DATE, uninstall_time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=backups
                if ! sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                local result=$(sqlite3 $docker_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=restores
                if ! sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                local result=$(sqlite3 $docker_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=migrations
                if ! sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                local result=$(sqlite3 $docker_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=ssh
                if ! sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                local result=$(sqlite3 $docker_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (id INTEGER PRIMARY KEY AUTOINCREMENT, ip TEXT, date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=ssh_keys
                if ! sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                local result=$(sqlite3 $docker_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (name TEXT UNIQUE, hash TEXT, date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=cron_jobs
                if ! sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                local result=$(sqlite3 $docker_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                # Get the list of table names from the database
                sql_table_names=$(sqlite3 "$docker_dir/$db_file" ".tables")

                # Loop through the table names and print the desired text
                for sql_table_name in $sql_table_names; do
                    isSuccessful "Table $sql_table_name found in database."
                done
            fi
        fi
    fi
}