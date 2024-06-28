#!/bin/bash

echo "USAGE : This is for generating new container installation scripts for EasyDocker"

while true; do
    read -p "Please enter the name of the application you would like to create a script for: " app_name

    if [[ -d "./$app_name" ]]
    then
        echo "Error: A folder with that name already exists. Please choose another name."
    else
        echo "Success: Valid application name given."
        break # exit the loop if the condition is met
    fi
done

while true; do
    read -p "Please enter the hostname (e.g a hostname 'test' would be setup the domain : test.yourdomain.com)" host_name
    if [[ $? -eq 0 ]]; then
        break
    fi
    isNotice "Please provide a valid hostname"
done

if [[ ! -d "./$app_name" ]]
    echo "Creating a new folder named $app_name..."
    mkdir "$app_name" || { echo "Error creating folder '$app_name', exiting."; exit 1; }

    echo "Copying template files to the new folder and renaming them..."
    cp -r ./template/* "./$app_name/" || { echo "Error copying files, exiting."; exit 1; }

    find "$app_name" -type f -exec bash -c 'mv "$0" "${0/%template/\$1}"' _ {} ${app_name} \; || { echo "Error renaming files, exiting."; exit 1; }

    echo "Renaming of files completed successfully."

    # Replace text in the $app_name.sh file
    sed -i '' -e 's/Template/$app_name/g' "${app_name}/$app_name.sh" || { echo "Error replacing text in the '$app_name.sh' file, exiting."; exit 1; }
    sed -i '' -e 's/template/$app_name/g' "${app_name}/$app_name.sh" || { echo "Error replacing text in the '$app_name.sh' file, exiting."; exit 1; }
    sed -i '' -e 's/TEMPLATE/\${APP_NAME}/g' "${app_name}/$app_name.sh" || { echo "Error replacing text in the '$app_name.sh' file, exiting."; exit 1; }

    # Replace text in the $app_name.config file
    sed -i '' -e 's/template/$app_name/g' "${app_name}/$app_name.config" || { echo "Error replacing text in the '$app_name.sh' file, exiting."; exit 1; }
    sed -i '' -e 's/CFG_TEMPLATE_HOST_NAME=test/CFG_TEMPLATE_HOST_NAME=$host_name/g' "${app_name}/$app_name.config" || { echo "Error replacing text in the '$app_name.sh' file, exiting."; exit 1; }

    echo "Text replacement in $app_name.sh completed successfully."

    echo "You can now add the contents of the docker-compose.yml file."
fi