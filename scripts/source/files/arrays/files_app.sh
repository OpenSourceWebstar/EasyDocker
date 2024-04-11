#!/bin/bash

app_scripts=(
    "app/containers/app_dashy.sh"
    "app/containers/app_invidious.sh"
    "app/containers/app_linkding.sh"
    "app/containers/app_mattermost.sh"
    "app/containers/app_owncloud.sh"
    "app/containers/traefik/traefik_labels.sh"
    "app/containers/traefik/traefik_login_credentials.sh"
    "app/containers/traefik/traefik_middlewares.sh"
    "app/containers/traefik/traefik_whitelist.sh"
    "app/app_get_key_data.sh"
    "app/app_scan_available.sh"
    "app/app_update_specifics.sh"
)
