#!/bin/bash

# Description : OwnCloud - File & Document Cloud (c/u/s/r/i):

installOwnCloud()
{
    app_name=$CFG_OWNCLOUD_APP_NAME
    host_name=$CFG_OWNCLOUD_HOST_NAME
    domain_number=$CFG_OWNCLOUD_DOMAIN_NUMBER
    public=$CFG_OWNCLOUD_PUBLIC
	port=$CFG_OWNCLOUD_PORT
	owncloud_version=$CFG_OWNCLOUD_VERSION

    if [[ "$owncloud" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$owncloud" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$owncloud" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$owncloud" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$owncloud" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Checking custom DNS entry and IP for setup"
        echo ""

		setupIPsAndHostnames;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
        echo ""

		setupComposeFileNoApp;
		editComposeFileDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setup .env file for $app_name"
        echo ""

if [[ "$public" == "true" ]]; then	

runCommandForDockerInstallUser "cd $install_dir$app_name && cat << EOF > $install_dir$app_name/.env
OWNCLOUD_VERSION=$owncloud_version
OWNCLOUD_DOMAIN=DOMAINSUBNAMEHERE:$port
OWNCLOUD_TRUSTED_DOMAINS=DOMAINSUBNAMEHERE
ADMIN_USERNAME=$CFG_OWNCLOUD_ADMIN_USERNAME
ADMIN_PASSWORD=$CFG_OWNCLOUD_ADMIN_PASSWORD
HTTP_PORT=$port
EOF"
fi

if [[ "$public" == "false" ]]; then	
runCommandForDockerInstallUser "cd $install_dir$app_name && cat << EOF > $install_dir$app_name/.env
OWNCLOUD_VERSION=$owncloud_version
OWNCLOUD_DOMAIN=IPADDRESSHERE:$port
OWNCLOUD_TRUSTED_DOMAINS=IPADDRESSHERE
ADMIN_USERNAME=$CFG_OWNCLOUD_ADMIN_USERNAME
ADMIN_PASSWORD=$CFG_OWNCLOUD_ADMIN_PASSWORD
HTTP_PORT=$port
EOF"
fi
		editEnvFileDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts $app_name;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_dir$app_name"
        echo ""
        echo "    You can now navigate to your new service using one of the options below : "
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$port/"
        echo "    Local : http://$ip_setup:$port/"
        echo ""
		    
		menu_number=0
        sleep 3s
        cd
	fi
	owncloud=n
}