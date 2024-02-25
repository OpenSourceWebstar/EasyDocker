#!/bin/bash

appInvidiousResetUserPassword()
{
    while true; do
        isQuestion "Please enter the username or email which you would like to password reset (enter 'x' to exit): "
        read -p "" invidiousresetconfirm
        if [[ "$invidiousresetconfirm" == [xX] ]]; then
            isNotice "Exiting..."
            break
        fi
        if [[ "$invidiousresetconfirm" != [xX] ]]; then
            # The hash for 'password'
            local bcrypt_hash="$2b$10$xN4J3LJafAv91X29KJJREeg7RfDcoKmleNm2LIfF0j5IoKuHXVA4O"
            # Debugging output
            echo "Debugging: email=$email, database_name=$database_name, bcrypt_hash=$bcrypt_hash"

            # Construct and print the SQL query
            sql_query="UPDATE users SET password = E'$bcrypt_hash' WHERE email = E'$email';"
            echo "Debugging: SQL Query: $sql_query"

            # Execute the command
            if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
dockerCommandRunInstallUser "docker exec invidious-db /bin/bash -c \"psql -U kemal -d $database_name <<EOF
$sql_query
EOF\" && exit"
            elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
docker exec invidious-db /bin/bash -c "psql -U kemal -d $database_name <<EOF $sql_query EOF" && exit
            fi

            isSuccessful "If the user $invidiousresetconfirm exists, the new password will be 'password'"
            sleep 5;
            break
        fi
    done
}
