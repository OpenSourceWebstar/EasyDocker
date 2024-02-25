#!/bin/bash

########################
#          DNS         #
########################
setupDNSIP()
{
    local app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "Something went wrong...No app name provided..."
        resetToMenu;
    fi

    # Build variable names based on app_name
    dns_host_name_var="CFG_${app_name^^}_HOST_NAME"

    # Access the variables using variable indirection
    dns_host_name="${!dns_host_name_var}"

    # Check if no network needed
    if [ "$dns_host_name" != "" ]; then
        while read -r line; do
            local dns_hostname=$(echo "$line" | awk '{print $1}')
            local dns_ip=$(echo "$line" | awk '{print $2}')
            if [ "$dns_hostname" = "$dns_host_name" ]; then
                dns_ip_setup=$dns_ip
            fi
        done < "$configs_dir$ip_file"
    fi 
}

updateDNS() 
{
    local app_name="$1"
    local flag="$2"



	if [[ "$OS" == [1234567] ]]; then
        dnsRemoveNameservers()
        {
            result=$(sudo sed -i '/^nameserver/d' /etc/resolv.conf)
            checkSuccess "Removing all instances of Nameserver from Resolv.conf"
        }

	    if [[ "$flag" == "standalonewireguard" ]]; then
            dnsRemoveNameservers;
            echo "nameserver $CFG_DNS_SERVER_1" | sudo tee -a /etc/resolv.conf > /dev/null
            echo "nameserver $CFG_DNS_SERVER_2" | sudo tee -a /etc/resolv.conf > /dev/null
        else
            # Check if AdGuard is installed
            local status=$(dockerCheckAppInstalled "adguard" "docker")
            if [ "$status" == "installed" ]; then
                setupDNSIP adguard;
                local adguard_ip="$dns_ip_setup"
                # Testing Docker IP Address
                result=$(sudo ping -c 1 $adguard_ip)
                if [ $? -eq 0 ]; then
                    isSuccessful "Ping to $adguard_ip was successful."
                else
                    isNotice "Ping to $adguard_ip failed."
                    isNotice "Defaulting to DNS 1 Server $CFG_DNS_SERVER_1."
                    local adguard_ip="$CFG_DNS_SERVER_1"
                    # Fallback to Quad9 if DNS has issues
                    result=$(sudo ping -c 1 $adguard_ip)
                    if [ $? -eq 0 ]; then
                        isSuccessful "Ping to $adguard_ip was successful."
                    else
                        isNotice "Ping to $adguard_ip failed."
                        isNotice "Defaulting to DNS Server 1"
                        local adguard_ip="$CFG_DNS_SERVER_1"
                    fi
                fi
            else
                local adguard_ip="$CFG_DNS_SERVER_1"
                # Fallback to Quad9 if DNS has issues
                result=$(sudo ping -c 1 $adguard_ip)
                if [ $? -eq 0 ]; then
                    isSuccessful "Ping to $adguard_ip was successful."
                else
                    isNotice "Ping to $adguard_ip failed."
                    isNotice "Defaulting to DNS Server 1"
                    local adguard_ip="$CFG_DNS_SERVER_1"
                fi
            fi

            # Check if Pi-hole is installed
            local status=$(dockerCheckAppInstalled "pihole" "docker")
            if [ "$status" == "installed" ]; then
                setupDNSIP pihole;
                local pihole_ip="$dns_ip_setup"
                # Testing Docker IP Address
                result=$(sudo ping -c 1 $pihole_ip)
                if [ $? -eq 0 ]; then
                    isSuccessful "Ping to $pihole_ip was successful."
                else
                    isNotice "Ping to $pihole_ip failed."
                    isNotice "Defaulting to DNS 2 Server $CFG_DNS_SERVER_2."
                    local pihole_ip="$CFG_DNS_SERVER_2"
                    # Fallback to Quad9 if DNS has issues
                    result=$(sudo ping -c 1 $pihole_ip)
                    if [ $? -eq 0 ]; then
                        isSuccessful "Ping to $pihole_ip was successful."
                    else
                        isNotice "Ping to $pihole_ip failed."
                        isNotice "Defaulting to DNS Server 2"
                        local pihole_ip="$CFG_DNS_SERVER_2"
                    fi
                fi
            else
                local pihole_ip="$CFG_DNS_SERVER_2"
                if [ $? -eq 0 ]; then
                    isSuccessful "Ping to $pihole_ip was successful."
                else
                    isNotice "Ping to $pihole_ip failed."
                    isNotice "Defaulting to DNS Server 2"
                    local pihole_ip="$CFG_DNS_SERVER_2"
                fi
            fi

            # Add the custom DNS servers to /etc/resolv.conf
            if [[ "$adguard_ip" == *10.8.1* ]]; then
                # Wireguard update
                local status=$(dockerCheckAppInstalled "wireguard" "docker")
                if [ "$status" == "installed" ]; then
                    setupInstallVariables wireguard;
                    if [[ $compose_setup == "default" ]]; then
                        local compose_file="docker-compose.yml"
                    elif [[ $compose_setup == "app" ]]; then
                        local compose_file="docker-compose.$app_name.yml"
                    fi
                    result=$(sudo sed -i "s/\(WG_DEFAULT_DNS=\).*/\1$adguard_ip/" $containers_dir$app_name/$compose_file)
                    checkSuccess "Updated Wireguard default DNS to $adguard_ip"
                fi
                dnsRemoveNameservers;
                echo "nameserver $adguard_ip" | sudo tee -a /etc/resolv.conf > /dev/null
                echo "nameserver $pihole_ip" | sudo tee -a /etc/resolv.conf > /dev/null
            elif [[ "$pihole_ip" == *10.8.1* ]]; then
                # Wireguard update
                local status=$(dockerCheckAppInstalled "wireguard" "docker")
                if [ "$status" == "installed" ]; then
                    setupInstallVariables $app_name;
                    if [[ $compose_setup == "default" ]]; then
                        local compose_file="docker-compose.yml"
                    elif [[ $compose_setup == "app" ]]; then
                        local compose_file="docker-compose.$app_name.yml"
                    fi
                    result=$(sudo sed -i "s/\(WG_DEFAULT_DNS=\).*/\1$pihole_ip/" $containers_dir$app_name/$compose_file)
                    checkSuccess "Updated Wireguard default DNS to $pihole_ip"
                fi
                dnsRemoveNameservers;
                echo "nameserver $pihole_ip" | sudo tee -a /etc/resolv.conf > /dev/null
                echo "nameserver $adguard_ip" | sudo tee -a /etc/resolv.conf > /dev/null
            else
                # Wireguard update
                local status=$(dockerCheckAppInstalled "wireguard" "docker")
                if [ "$status" == "installed" ]; then
                    setupInstallVariables wireguard;
                    if [[ $compose_setup == "default" ]]; then
                        local compose_file="docker-compose.yml"
                    elif [[ $compose_setup == "app" ]]; then
                        local compose_file="docker-compose.$app_name.yml"
                    fi
                    result=$(sudo sed -i "s/\(WG_DEFAULT_DNS=\).*/\1$adguard_ip/" $containers_dir$app_name/$compose_file)
                    checkSuccess "Updated Wireguard default DNS to $adguard_ip"
                fi
                dnsRemoveNameservers;
                echo "nameserver $adguard_ip" | sudo tee -a /etc/resolv.conf > /dev/null
                echo "nameserver $pihole_ip" | sudo tee -a /etc/resolv.conf > /dev/null
            fi
            if [ "$flag" == "install" ]; then
                setupInstallVariables $app_name;
            fi
            isSuccessful "Resolv.conf has been updated with the latest DNS settings."
        fi
    fi
}
