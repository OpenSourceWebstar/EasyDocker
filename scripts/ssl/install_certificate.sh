#!/bin/bash

installSSLCertificate()
{
	if [[ "$CFG_REQUIREMENT_SSLCERTS" == "true" ]]; then
        if [[ "$SkipSSLInstall" != "true" ]]; then
            echo ""
            echo "############################################"
            echo "######     Install SSL Certificate    ######"
            echo "############################################"
            echo ""

            # Read the config file and extract domain values
            domains=()
            for domain_num in {1..9}; do
                domain="CFG_DOMAIN_$domain_num"
                domain_value=$(grep "^$domain=" "$configs_dir$config_file_general" | cut -d '=' -f 2 | tr -d '[:space:]')
                
                if [ -n "$domain_value" ]; then
                    domains+=("$domain_value")
                fi
            done

            # Function to generate SSL certificate for a given domain
            generateSSLCertificate() {
                local domain_value="$1"
                local result=$(cd $ssl_dir && openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/CN=$domain_value" -keyout "$ssl_dir/$domain_value.key" -out "$ssl_dir/$domain_value.crt" > /dev/null 2>&1)
                checkSuccess "SSL Generation for $domain_value"
            }

            # Generate SSL certificates for each domain
            for domain_value in "${domains[@]}"; do
                isNotice "Creating SSL certificate for $domain_value..."
                generateSSLCertificate "$domain_value"
            done

            # Check if generated certificates match the ones in the SSL folder
            isNotice "Checking SSL certificates..."
            for domain_value in "${domains[@]}"; do
                if cmp -s "$ssl_dir/$domain_value.key" "$ssl_dir/$domain_value.crt"; then
                    isNotice "Certificate for $domain_value does not match in the SSL folder."

                    isQuestion "Do you want to regenerate the SSL certificate for $domain_value? (y/n): "
                    read -rp "" SSLRegenchoice

                    if [ "$SSLRegenchoice" == "y" ]; then
                        echo "Regenerating SSL certificate for $domain_value..."
                        generateSSLCertificate "$domain_value"
                    else
                        echo "Skipping regeneration for $domain_value."
                    fi  
                else
                    isSuccessful "Certificate for $domain_value matches in the SSL folder."
                fi
            done

            sslcertchoice=n
        fi
    fi
}
