#!/bin/bash

app_scripts=(
    "app/containers/dashy.sh"
    "app/containers/invidious.sh"
    "app/containers/mattermost.sh"
    "app/containers/owncloud.sh"
    "app/containers/traefik/traefik_labels.sh"
    "app/containers/traefik/traefik_login_credentials.sh"
    "app/containers/traefik/traefik_middlewares.sh"
    "app/containers/traefik/traefik_whitelist.sh"
    "app/app_scan_available.sh"
    "app/app_update_specifics.sh"
)
