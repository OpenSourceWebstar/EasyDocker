#!/bin/bash

docker_scripts=(
    "docker/app/checks/allowed_install.sh"
    "docker/app/checks/app_installed.sh"
    "docker/app/checks/container_health_loop.sh"
    "docker/app/checks/container_health.sh"

    "docker/app/compose/down_all.sh"
    "docker/app/compose/down_app.sh"
    "docker/app/compose/restart_app.sh"
    "docker/app/compose/up_all.sh"
    "docker/app/compose/up_app.sh"

    "docker/app/docker/start_all.sh"
    "docker/app/docker/start_app.sh"
    "docker/app/docker/stop_all.sh"
    "docker/app/docker/stop_app.sh"

    "docker/app/functions/function_install_app.sh"
    "docker/app/functions/function_restart_app.sh"

    "docker/app/uninstall/delete_data.sh"
    "docker/app/uninstall/down_remove_app.sh"
    "docker/app/uninstall/uninstall_app.sh"

    "docker/checks/running_for_user.sh"

    "docker/compose/restart_after_update.sh"
    "docker/compose/restart_compose_yml.sh"
    "docker/compose/update_and_start.sh"
    "docker/compose/update_compose_yml.sh"

    "docker/install/setup_network.sh"
    "docker/install/setup_rooted.sh"
    "docker/install/setup_rootless.sh"

    "docker/service/start_docker.sh"
    "docker/service/stop_docker.sh"

    "docker/prune_networks.sh"
    "docker/setup_env.sh"
    "docker/switch_docker_type.sh"
    "docker/whitelist_port_updater.sh"

)
