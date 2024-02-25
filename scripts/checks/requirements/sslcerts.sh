#!/bin/bash

checkSSLCertsRequirement()
{  
	if [[ $CFG_REQUIREMENT_SSLCERTS == "true" ]]; then
		### SSL Certificates
		domains=()
		for domain_num in {1..9}; do
			domain="CFG_DOMAIN_$domain_num"
			domain_value=$(sudo grep  "^$domain=" $configs_dir$config_file_general | cut -d '=' -f 2 | tr -d '[:space:]')
			if [ -n "$domain_value" ]; then
				domains+=("$domain_value")
			fi
		done

		missing_ssl=()
		for domain_value in "${domains[@]}"; do
			key_file="$ssl_dir/${domain_value}.key"
			crt_file="$ssl_dir/${domain_value}.crt"

			if [ -f "$key_file" ] || [ -f "$crt_file" ]; then
				isSuccessful "Certificate for domain $domain_value installed."
			else
				missing_ssl+=("$domain_value")
				isNotice "Certificate for domain $domain_value not found. Setup will start soon."
			fi
		done

		if [ ${#missing_ssl[@]} -eq 0 ]; then
			isSuccessful "SSL certificates are setup for all domains."
			SkipSSLInstall=true
		else
			isNotice "An SSL certificate is missing for the following domain: ${missing_ssl[*]}"
			((preinstallneeded++)) 
		fi
	fi
} 