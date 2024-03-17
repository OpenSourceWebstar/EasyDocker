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

    "docker/app/docker/restart_app.sh"
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

    "docker/install/rooted/rooted_docker_check.sh"
    "docker/install/rooted/rooted_docker_compose.sh"
    "docker/install/rooted/rooted_docker.sh"
    "docker/install/rootless/rootless_docker.sh"
    "docker/install/rootless/rootless_start_setup.sh"
    "docker/install/rootless/rootless_uninstall.sh"
    "docker/install/rootless/rootless_user.sh"

    "docker/network/setup_network.sh"
    "docker/network/prune_networks.sh"

    "docker/service/start_docker.sh"
    "docker/service/stop_docker.sh"

    "docker/type_switcher/scan_container_socket.sh"
    "docker/type_switcher/set_socket_permissions.sh"
    "docker/type_switcher/swap_docker_type.sh"
    "docker/type_switcher/switch_containers_type.sh"

    "docker/setup_env.sh"
    "docker/update_docker_user_pass.sh"
    "docker/whitelist_port_updater.sh"

)
