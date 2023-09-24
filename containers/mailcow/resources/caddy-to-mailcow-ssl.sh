#!/bin/bash
MD5SUM_CURRENT_CERT=($(md5sum /docker/mailcow/data/assets/ssl/cert.pem))
MD5SUM_NEW_CERT=($(md5sum /docker/caddy/caddy_data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/DOMAINNAMEHERE/DOMAINNAMEHERE.crt))

if [ $MD5SUM_CURRENT_CERT != $MD5SUM_NEW_CERT ]; then
        cp /docker/caddy/caddy_data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/DOMAINNAMEHERE/DOMAINNAMEHERE.crt /docker/mailcow/data/assets/ssl/cert.pem
        cp /docker/caddy/caddy_data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/DOMAINNAMEHERE/DOMAINNAMEHERE.key /docker/mailcow/data/assets/ssl/key.pem
        postfix_c=$(docker ps -qaf name=postfix-mailcow)
        dovecot_c=$(docker ps -qaf name=dovecot-mailcow)
        nginx_c=$(docker ps -qaf name=nginx-mailcow)
        docker restart ${postfix_c} ${dovecot_c} ${nginx_c}

else
        echo "Certs not copied from Caddy (Not needed)"
fi